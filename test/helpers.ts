import { ethers, upgrades } from "hardhat";

import DAOCreatorABI from "@gooddollar/goodcontracts/build/contracts/DaoCreatorGoodDollar.json";
import IdentityABI from "@gooddollar/goodcontracts/build/contracts/Identity.json";
import FeeFormulaABI from "@gooddollar/goodcontracts/build/contracts/FeeFormula.json";
import AddFoundersABI from "@gooddollar/goodcontracts/build/contracts/AddFoundersGoodDollar.json";
import ContributionCalculation from "@gooddollar/goodcontracts/stakingModel/build/contracts/ContributionCalculation.json";
import FirstClaimPool from "@gooddollar/goodcontracts/stakingModel/build/contracts/FirstClaimPool.json";
import SchemeRegistrar from "@gooddollar/goodcontracts/build/contracts/SchemeRegistrar.json";
import AbsoluteVote from "@gooddollar/goodcontracts/build/contracts/AbsoluteVote.json";
import UpgradeScheme from "@gooddollar/goodcontracts/build/contracts/UpgradeScheme.json";

import { Controller, GoodMarketMaker, CompoundVotingMachine } from "../types";

export const createDAO = async () => {
  let [root, ...signers] = await ethers.getSigners();

  const cdaiFactory = await ethers.getContractFactory("cDAIMock");
  const daiFactory = await ethers.getContractFactory("DAIMock");

  let dai = await daiFactory.deploy();

  let cDAI = await cdaiFactory.deploy(dai.address);

  const DAOCreatorFactory = new ethers.ContractFactory(
    DAOCreatorABI.abi,
    DAOCreatorABI.bytecode,
    root
  );

  const IdentityFactory = new ethers.ContractFactory(
    IdentityABI.abi,
    IdentityABI.bytecode,
    root
  );
  const FeeFormulaFactory = new ethers.ContractFactory(
    FeeFormulaABI.abi,
    FeeFormulaABI.bytecode,
    root
  );
  const AddFoundersFactory = new ethers.ContractFactory(
    AddFoundersABI.abi,
    AddFoundersABI.bytecode,
    root
  );

  const BancorFormula = await (
    await ethers.getContractFactory("BancorFormula")
  ).deploy();
  const AddFounders = await AddFoundersFactory.deploy();
  const Identity = await IdentityFactory.deploy();
  const daoCreator = await DAOCreatorFactory.deploy(AddFounders.address);
  const FeeFormula = await FeeFormulaFactory.deploy(0);

  await Identity.setAuthenticationPeriod(365);
  await daoCreator.forgeOrg(
    "G$",
    "G$",
    0,
    FeeFormula.address,
    Identity.address,
    [root.address, signers[0].address, signers[1].address],
    1000,
    [100000, 100000, 100000]
  );

  const Avatar = new ethers.Contract(
    await daoCreator.avatar(),
    [
      "function owner() view returns (address)",
      "function nativeToken() view returns (address)"
    ],
    root
  );

  await Identity.setAvatar(Avatar.address);
  const controller = await Avatar.owner();

  const ccFactory = new ethers.ContractFactory(
    ContributionCalculation.abi,
    ContributionCalculation.bytecode,
    root
  );

  const contribution = await ccFactory.deploy(Avatar.address, 0, 1e15);

  console.log("deploying nameService", [
    controller,
    Avatar.address,
    Identity.address,
    await Avatar.nativeToken(),
    contribution.address,
    BancorFormula.address,
    dai.address,
    cDAI.address
  ]);
  const nameService = await upgrades.deployProxy(
    await ethers.getContractFactory("NameService"),
    [
      controller,
      [
        "CONTROLLER",
        "AVATAR",
        "IDENTITY",
        "GOODDOLLAR",
        "CONTRIBUTION_CALCULATION",
        "BANCOR_FORMULA",
        "DAI",
        "CDAI",
        "UBISCHEME",
        "BRIDGE_CONTRACT",
        "UBI_RECIPIENT"
      ].map(_ => ethers.utils.keccak256(ethers.utils.toUtf8Bytes(_))),
      [
        controller,
        Avatar.address,
        Identity.address,
        await Avatar.nativeToken(),
        contribution.address,
        BancorFormula.address,
        dai.address,
        cDAI.address,
        root.address,
        root.address,
        root.address
      ]
    ]
  );

  console.log("deploying reserve...");
  let goodReserve = await upgrades.deployProxy(
    await ethers.getContractFactory("GoodReserveCDai"),

    [
      nameService.address,
      //check sample merkle tree generated by gdxAirdropCalculation.ts script
      "0x26ef809f3f845395c0bc66ce1eea85146516cb99afd030e2085b13e79514e94c"
    ],
    {
      initializer: "initialize(address, bytes32)"
    }
  );
  console.log("deploying marketMaker...");

  const MM = await ethers.getContractFactory("GoodMarketMaker");

  let marketMaker = (await upgrades.deployProxy(MM, [
    nameService.address,
    999388834642296,
    1e15
  ])) as GoodMarketMaker;

  const GReputation = await ethers.getContractFactory("GReputation");
  let reputation = await upgrades.deployProxy(
    GReputation,
    [nameService.address, "", ethers.constants.HashZero, 0],
    {
      kind: "uups",
      initializer: "initialize(address, string, bytes32, uint256)"
    }
  );

  console.log("Done deploying DAO, setting up nameService...");
  //generic call permissions
  let schemeMock = signers[signers.length - 1];

  const ictrl = await ethers.getContractAt(
    "Controller",
    controller,
    schemeMock
  );

  const setSchemes = async (addrs, params = []) => {
    for (let i in addrs) {
      await ictrl.registerScheme(
        addrs[i],
        params[i] || ethers.constants.HashZero,
        "0x0000001F",
        Avatar.address
      );
    }
  };

  const setDAOAddress = async (name, addr) => {
    const encoded = nameService.interface.encodeFunctionData("setAddress", [
      name,
      addr
    ]);

    await ictrl.genericCall(nameService.address, encoded, Avatar.address, 0);
  };

  const setReserveToken = async (token, gdReserve, tokenReserve, RR) => {
    const encoded = marketMaker.interface.encodeFunctionData(
      "initializeToken",
      [token, gdReserve, tokenReserve, RR]
    );

    await ictrl.genericCall(marketMaker.address, encoded, Avatar.address, 0);
  };

  const genericCall = (target, encodedFunc) => {
    return ictrl.genericCall(target, encodedFunc, Avatar.address, 0);
  };

  const addWhitelisted = (addr, did, isContract = false) => {
    if (isContract) return Identity.addContract(addr);
    return Identity.addWhitelistedWithDID(addr, did);
  };
  await daoCreator.setSchemes(
    Avatar.address,
    [schemeMock.address, Identity.address],
    [ethers.constants.HashZero, ethers.constants.HashZero],
    ["0x0000001F", "0x0000001F"],
    ""
  );

  const gd = await Avatar.nativeToken();
  //make GoodCap minter
  const encoded = (
    await ethers.getContractAt("IGoodDollar", gd)
  ).interface.encodeFunctionData("addMinter", [goodReserve.address]);

  await ictrl.genericCall(gd, encoded, Avatar.address, 0);

  await setDAOAddress("RESERVE", goodReserve.address);
  await setDAOAddress("MARKET_MAKER", marketMaker.address);
  await setDAOAddress("REPUTATION", reputation.address);

  await setReserveToken(
    cDAI.address,
    "100", //1gd
    "10000", //0.0001 cDai
    "1000000" //100% rr
  );

  const votingMachine = (await upgrades.deployProxy(
    await ethers.getContractFactory("CompoundVotingMachine"),
    [nameService.address, 5760],
    { kind: "uups" }
  )) as CompoundVotingMachine;

  return {
    daoCreator,
    controller,
    reserve: goodReserve,
    avatar: await daoCreator.avatar(),
    gd: await Avatar.nativeToken(),
    identity: Identity.address,
    nameService,
    setDAOAddress,
    setSchemes,
    setReserveToken,
    genericCall,
    addWhitelisted,
    marketMaker,
    feeFormula: FeeFormula,
    daiAddress: dai.address,
    cdaiAddress: cDAI.address,
    reputation: reputation.address,
    votingMachine
  };
};

export const deployUBI = async deployedDAO => {
  let { nameService, setSchemes, genericCall, setDAOAddress } = deployedDAO;
  const fcFactory = new ethers.ContractFactory(
    FirstClaimPool.abi,
    FirstClaimPool.bytecode,
    (await ethers.getSigners())[0]
  );

  console.log("deploying first claim...", {
    avatar: await nameService.addresses(await nameService.AVATAR()),
    identity: await nameService.addresses(await nameService.IDENTITY())
  });
  const firstClaim = await fcFactory.deploy(
    await nameService.addresses(await nameService.AVATAR()),
    await nameService.addresses(await nameService.IDENTITY()),
    1000
  );

  console.log("deploying ubischeme and starting...", {
    input: [nameService.address, firstClaim.address, 14]
  });

  let ubiScheme = await upgrades.deployProxy(
    await ethers.getContractFactory("UBIScheme"),
    [nameService.address, firstClaim.address, 14]
  );

  const gd = await nameService.addresses(await nameService.GOODDOLLAR());

  let encoded = (
    await ethers.getContractAt("IGoodDollar", gd)
  ).interface.encodeFunctionData("mint", [firstClaim.address, 1000000]);

  await genericCall(gd, encoded);

  encoded = (
    await ethers.getContractAt("IGoodDollar", gd)
  ).interface.encodeFunctionData("mint", [ubiScheme.address, 1000000]);

  await genericCall(gd, encoded);

  console.log("set firstclaim,ubischeme as scheme and starting...");
  await setSchemes([firstClaim.address, ubiScheme.address]);
  await firstClaim.start();
  await ubiScheme.start();
  setDAOAddress("UBISCHEME", ubiScheme.address);
  return { firstClaim, ubiScheme };
};

export async function increaseTime(seconds) {
  await ethers.provider.send("evm_increaseTime", [seconds]);
  await advanceBlocks(1);
}

export const advanceBlocks = async (blocks: number) => {
  let ps = [];
  for (let i = 0; i < blocks; i++) {
    ps.push(ethers.provider.send("evm_mine", []));
    if (i % 5000 === 0) {
      await Promise.all(ps);
      ps = [];
    }
  }
};

export const deployOldVoting = async dao => {
  try {
    const SchemeRegistrarF = new ethers.ContractFactory(
      SchemeRegistrar.abi,
      SchemeRegistrar.bytecode,
      (await ethers.getSigners())[0]
    );
    const UpgradeSchemeF = new ethers.ContractFactory(
      UpgradeScheme.abi,
      UpgradeScheme.bytecode,
      (await ethers.getSigners())[0]
    );
    const AbsoluteVoteF = new ethers.ContractFactory(
      AbsoluteVote.abi,
      AbsoluteVote.bytecode,
      (await ethers.getSigners())[0]
    );

    const [absoluteVote, upgradeScheme, schemeRegistrar] = await Promise.all([
      AbsoluteVoteF.deploy(),
      UpgradeSchemeF.deploy(),
      SchemeRegistrarF.deploy()
    ]);
    console.log("setting parameters");
    const voteParametersHash = await absoluteVote.getParametersHash(
      50,
      ethers.constants.AddressZero
    );

    console.log("setting params for voting machine and schemes");

    await Promise.all([
      schemeRegistrar.setParameters(
        voteParametersHash,
        voteParametersHash,
        absoluteVote.address
      ),
      absoluteVote.setParameters(50, ethers.constants.AddressZero),
      upgradeScheme.setParameters(voteParametersHash, absoluteVote.address)
    ]);
    const upgradeParametersHash = await upgradeScheme.getParametersHash(
      voteParametersHash,
      absoluteVote.address
    );

    // Deploy SchemeRegistrar
    const schemeRegisterParams = await schemeRegistrar.getParametersHash(
      voteParametersHash,
      voteParametersHash,
      absoluteVote.address
    );

    let schemesArray;
    let paramsArray;
    let permissionArray;

    // Subscribe schemes
    schemesArray = [schemeRegistrar.address, upgradeScheme.address];
    paramsArray = [schemeRegisterParams, upgradeParametersHash];
    await dao.setSchemes(schemesArray, paramsArray);
    return {
      schemeRegistrar,
      upgradeScheme,
      absoluteVote
    };
  } catch (e) {
    console.log("deployVote failed", e);
  }
};
