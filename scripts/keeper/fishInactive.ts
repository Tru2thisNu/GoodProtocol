import { get, range, chunk, flatten, mergeWith, sortBy, uniq } from "lodash";
import coreContracts from "../../releases/deployment.json";
import { ethers as Ethers } from "hardhat";
import fetch from "node-fetch";
import { request, gql } from "graphql-request";
import { Retrier } from "@jsier/retrier";
import PromisePool from "async-promise-pool";

const ONE_DAY = 24 * 60 * 60;

const main = async () => {
  const signer = (await Ethers.getSigners())[0];
  console.log("signer:", signer.address);
  const ubiScheme = new Ethers.Contract(
    "0xD7aC544F8A570C4d8764c3AAbCF6870CBD960D0D",
    ["function fishMulti(address[] tofish)"]
  ).connect(signer);
  const twoWeeksAgo =
    parseInt((Date.now() / 1000).toFixed(0)) - 24 * 60 * 60 * 14;

  const daysAgo: number[] = range(0, 180, 1);
  let curDay = twoWeeksAgo;
  for (let day of daysAgo) {
    const query = gql`
    {
      walletStats(first:1000, where: { lastClaimed_lt: ${curDay},lastClaimed_gt: ${
      curDay - 24 * 60 * 60
    } isActiveUser: true }) {
        id        
      }
    }
  `;

    console.log("fetching inactive users since:", { curDay, day });
    const { walletStats } = await request(
      "https://api.thegraph.com/subgraphs/name/gooddollar/gooddollarfuse",
      query
    );
    console.log("got inactive wallets:", walletStats.length);
    const accounts = walletStats.map(_ => _.id);
    for (let tofish of chunk(accounts, 50)) {
      const tx = await ubiScheme.fishMulti(tofish, { gasLimit: 2000000 });
      console.log("fishing tx:", tx, tofish);
      const res = await tx.wait();
      console.log("fishing tx result:", res);
    }

    curDay = curDay - ONE_DAY;
  }
};

main();
