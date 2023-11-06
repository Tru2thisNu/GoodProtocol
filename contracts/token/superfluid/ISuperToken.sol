// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.4;

import { IERC20, IERC777, TokenInfo } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { ISuperfluidToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluidToken.sol";
import { IConstantOutflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantOutflowNFT.sol";
import { IConstantInflowNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IConstantInflowNFT.sol";
import { IPoolAdminNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IPoolAdminNFT.sol";
import { IPoolMemberNFT } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/IPoolMemberNFT.sol";

/**
 * @title Super token (Superfluid Token + ERC20 + ERC777) interface
 * @author Superfluid
 */
interface ISuperToken is ISuperfluidToken, TokenInfo, IERC20, IERC777 {
	/**************************************************************************
	 * Errors
	 *************************************************************************/
	error SUPER_TOKEN_CALLER_IS_NOT_OPERATOR_FOR_HOLDER(); // 0xf7f02227
	error SUPER_TOKEN_NOT_ERC777_TOKENS_RECIPIENT(); // 0xfe737d05
	error SUPER_TOKEN_INFLATIONARY_DEFLATIONARY_NOT_SUPPORTED(); // 0xe3e13698
	error SUPER_TOKEN_NO_UNDERLYING_TOKEN(); // 0xf79cf656
	error SUPER_TOKEN_ONLY_SELF(); // 0x7ffa6648
	error SUPER_TOKEN_ONLY_HOST(); // 0x98f73704
	error SUPER_TOKEN_ONLY_GOV_OWNER(); // 0xd9c7ed08
	error SUPER_TOKEN_APPROVE_FROM_ZERO_ADDRESS(); // 0x81638627
	error SUPER_TOKEN_APPROVE_TO_ZERO_ADDRESS(); // 0xdf070274
	error SUPER_TOKEN_BURN_FROM_ZERO_ADDRESS(); // 0xba2ab184
	error SUPER_TOKEN_MINT_TO_ZERO_ADDRESS(); // 0x0d243157
	error SUPER_TOKEN_TRANSFER_FROM_ZERO_ADDRESS(); // 0xeecd6c9b
	error SUPER_TOKEN_TRANSFER_TO_ZERO_ADDRESS(); // 0xe219bd39
	error SUPER_TOKEN_NFT_PROXY_ALREADY_SET(); // 0x6bef249d

	/**
	 * @dev Initialize the contract
	 */
	function initialize(
		IERC20 underlyingToken,
		uint8 underlyingDecimals,
		string calldata n,
		string calldata s
	) external;

	/**************************************************************************
	 * TokenInfo & ERC777
	 *************************************************************************/

	/**
	 * @dev Returns the name of the token.
	 */
	function name()
		external
		view
		override(IERC777, TokenInfo)
		returns (string memory);

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol()
		external
		view
		override(IERC777, TokenInfo)
		returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
	 * called.
	 *
	 * @custom:note SuperToken always uses 18 decimals.
	 *
	 * This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() external view override(TokenInfo) returns (uint8);

	/**************************************************************************
	 * ERC20 & ERC777
	 *************************************************************************/

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply()
		external
		view
		override(IERC777, IERC20)
		returns (uint256);

	/**
	 * @dev Returns the amount of tokens owned by an account (`owner`).
	 */
	function balanceOf(
		address account
	) external view override(IERC777, IERC20) returns (uint256 balance);

	/**************************************************************************
	 * ERC20
	 *************************************************************************/

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * @return Returns Success a boolean value indicating whether the operation succeeded.
	 *
	 * @custom:emits a {Transfer} event.
	 */
	function transfer(
		address recipient,
		uint256 amount
	) external override(IERC20) returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 *         allowed to spend on behalf of `owner` through {transferFrom}. This is
	 *         zero by default.
	 *
	 * @notice This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(
		address owner,
		address spender
	) external view override(IERC20) returns (uint256);

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * @return Returns Success a boolean value indicating whether the operation succeeded.
	 *
	 * @custom:note Beware that changing an allowance with this method brings the risk
	 * that someone may use both the old and the new allowance by unfortunate
	 * transaction ordering. One possible solution to mitigate this race
	 * condition is to first reduce the spender's allowance to 0 and set the
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * @custom:emits an {Approval} event.
	 */
	function approve(
		address spender,
		uint256 amount
	) external override(IERC20) returns (bool);

	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 *         allowance mechanism. `amount` is then deducted from the caller's
	 *         allowance.
	 *
	 * @return Returns Success a boolean value indicating whether the operation succeeded.
	 *
	 * @custom:emits a {Transfer} event.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external override(IERC20) returns (bool);

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * @custom:emits an {Approval} event indicating the updated allowance.
	 *
	 * @custom:requirements
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(
		address spender,
		uint256 addedValue
	) external returns (bool);

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * @custom:emits an {Approval} event indicating the updated allowance.
	 *
	 * @custom:requirements
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(
		address spender,
		uint256 subtractedValue
	) external returns (bool);

	/**************************************************************************
	 * ERC777
	 *************************************************************************/

	/**
	 * @dev Returns the smallest part of the token that is not divisible. This
	 *         means all token operations (creation, movement and destruction) must have
	 *         amounts that are a multiple of this number.
	 *
	 * @custom:note For super token contracts, this value is always 1
	 */
	function granularity() external view override(IERC777) returns (uint256);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * @dev If send or receive hooks are registered for the caller and `recipient`,
	 *      the corresponding functions will be called with `data` and empty
	 *      `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
	 *
	 * @custom:emits a {Sent} event.
	 *
	 * @custom:requirements
	 * - the caller must have at least `amount` tokens.
	 * - `recipient` cannot be the zero address.
	 * - if `recipient` is a contract, it must implement the {IERC777Recipient}
	 * interface.
	 */
	function send(
		address recipient,
		uint256 amount,
		bytes calldata data
	) external override(IERC777);

	/**
	 * @dev Destroys `amount` tokens from the caller's account, reducing the
	 * total supply and transfers the underlying token to the caller's account.
	 *
	 * If a send hook is registered for the caller, the corresponding function
	 * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
	 *
	 * @custom:emits a {Burned} event.
	 *
	 * @custom:requirements
	 * - the caller must have at least `amount` tokens.
	 */
	function burn(uint256 amount, bytes calldata data) external override(IERC777);

	/**
	 * @dev Returns true if an account is an operator of `tokenHolder`.
	 * Operators can send and burn tokens on behalf of their owners. All
	 * accounts are their own operator.
	 *
	 * See {operatorSend} and {operatorBurn}.
	 */
	function isOperatorFor(
		address operator,
		address tokenHolder
	) external view override(IERC777) returns (bool);

	/**
	 * @dev Make an account an operator of the caller.
	 *
	 * See {isOperatorFor}.
	 *
	 * @custom:emits an {AuthorizedOperator} event.
	 *
	 * @custom:requirements
	 * - `operator` cannot be calling address.
	 */
	function authorizeOperator(address operator) external override(IERC777);

	/**
	 * @dev Revoke an account's operator status for the caller.
	 *
	 * See {isOperatorFor} and {defaultOperators}.
	 *
	 * @custom:emits a {RevokedOperator} event.
	 *
	 * @custom:requirements
	 * - `operator` cannot be calling address.
	 */
	function revokeOperator(address operator) external override(IERC777);

	/**
	 * @dev Returns the list of default operators. These accounts are operators
	 * for all token holders, even if {authorizeOperator} was never called on
	 * them.
	 *
	 * This list is immutable, but individual holders may revoke these via
	 * {revokeOperator}, in which case {isOperatorFor} will return false.
	 */
	function defaultOperators()
		external
		view
		override(IERC777)
		returns (address[] memory);

	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
	 * be an operator of `sender`.
	 *
	 * If send or receive hooks are registered for `sender` and `recipient`,
	 * the corresponding functions will be called with `data` and
	 * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
	 *
	 * @custom:emits a {Sent} event.
	 *
	 * @custom:requirements
	 * - `sender` cannot be the zero address.
	 * - `sender` must have at least `amount` tokens.
	 * - the caller must be an operator for `sender`.
	 * - `recipient` cannot be the zero address.
	 * - if `recipient` is a contract, it must implement the {IERC777Recipient}
	 * interface.
	 */
	function operatorSend(
		address sender,
		address recipient,
		uint256 amount,
		bytes calldata data,
		bytes calldata operatorData
	) external override(IERC777);

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the total supply.
	 * The caller must be an operator of `account`.
	 *
	 * If a send hook is registered for `account`, the corresponding function
	 * will be called with `data` and `operatorData`. See {IERC777Sender}.
	 *
	 * @custom:emits a {Burned} event.
	 *
	 * @custom:requirements
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 * - the caller must be an operator for `account`.
	 */
	function operatorBurn(
		address account,
		uint256 amount,
		bytes calldata data,
		bytes calldata operatorData
	) external override(IERC777);

	/**************************************************************************
	 * SuperToken custom token functions
	 *************************************************************************/

	/**
	 * @dev Give `spender`, `amount` allowance to spend the tokens of
	 * `account`.
	 *
	 * @custom:modifiers
	 *  - onlySelf
	 */
	function selfApproveFor(
		address account,
		address spender,
		uint256 amount
	) external;

	/**************************************************************************
	 * Batch Operations
	 *************************************************************************/

	/**
	 * @dev Perform ERC20 approve by host contract.
	 * @param account The account owner to be approved.
	 * @param spender The spender of account owner's funds.
	 * @param amount Number of tokens to be approved.
	 *
	 * @custom:modifiers
	 *  - onlyHost
	 */
	function operationApprove(
		address account,
		address spender,
		uint256 amount
	) external;

	function operationIncreaseAllowance(
		address account,
		address spender,
		uint256 addedValue
	) external;

	function operationDecreaseAllowance(
		address account,
		address spender,
		uint256 subtractedValue
	) external;

	/**
	 * @dev Perform ERC20 transferFrom by host contract.
	 * @param account The account to spend sender's funds.
	 * @param spender The account where the funds is sent from.
	 * @param recipient The recipient of the funds.
	 * @param amount Number of tokens to be transferred.
	 *
	 * @custom:modifiers
	 *  - onlyHost
	 */
	function operationTransferFrom(
		address account,
		address spender,
		address recipient,
		uint256 amount
	) external;

	/**
	 * @dev Perform ERC777 send by host contract.
	 * @param spender The account where the funds is sent from.
	 * @param recipient The recipient of the funds.
	 * @param amount Number of tokens to be transferred.
	 * @param data Arbitrary user inputted data
	 *
	 * @custom:modifiers
	 *  - onlyHost
	 */
	function operationSend(
		address spender,
		address recipient,
		uint256 amount,
		bytes memory data
	) external;

	/**************************************************************************
	 * ERC20x-specific Functions
	 *************************************************************************/

	function CONSTANT_OUTFLOW_NFT() external view returns (IConstantOutflowNFT);

	function CONSTANT_INFLOW_NFT() external view returns (IConstantInflowNFT);

	function poolAdminNFT() external view returns (IPoolAdminNFT);

	function poolMemberNFT() external view returns (IPoolMemberNFT);

	/**
	 * @dev Constant Outflow NFT proxy created event
	 * @param constantOutflowNFT constant outflow nft address
	 */
	event ConstantOutflowNFTCreated(
		IConstantOutflowNFT indexed constantOutflowNFT
	);

	/**
	 * @dev Constant Inflow NFT proxy created event
	 * @param constantInflowNFT constant inflow nft address
	 */
	event ConstantInflowNFTCreated(IConstantInflowNFT indexed constantInflowNFT);

	/**************************************************************************
	 * Function modifiers for access control and parameter validations
	 *
	 * While they cannot be explicitly stated in function definitions, they are
	 * listed in function definition comments instead for clarity.
	 *
	 * NOTE: solidity-coverage not supporting it
	 *************************************************************************/

	/// @dev The msg.sender must be the contract it\
	//modifier onlySelf() virtual
}
