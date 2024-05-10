// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IPeripheryProxy {
    function getGlobalConfiguration()
        external
        pure
        returns (GlobalConfiguration.Data memory);

    function getTokenChainConnector(address token, uint256 chainId)
        external
        view
        returns (address connector);

    function getTokenController(address token)
        external
        view
        returns (address controller);

    function getTokenExecutionHelper(address token)
        external
        view
        returns (address executionHelper);

    function getTokenStaticWithdrawFee(address token, address connector)
        external
        view
        returns (uint256 staticFee);

    function receiveEth() external payable;

    function rescueErc20(
        uint256 amount,
        address token,
        address receiver
    ) external;

    function rescueEth(uint256 amount, address receiver) external;

    function setGlobalConfiguration(GlobalConfiguration.Data memory config)
        external;

    function setTokenChainConnector(
        address token,
        uint256 chainId,
        address connector
    ) external;

    function setTokenController(address token, address controller) external;

    function setTokenExecutionHelper(address token, address executionHelper)
        external;

    function setTokenStaticWithdrawFee(
        address token,
        address connector,
        uint256 staticFee
    ) external;

    error ConnectorNotRegistered(address token, uint256 chainId);
    error ControllerNotRegistered(address token);
    error ExecutionHelperNotRegistered(address token);
    error FailedToRescueFunds();
    error FailedTransfer(address from, address to, uint256 value);
    error Unauthorized(address addr);

    function depositExistingMA(DepositExistingMAInputs memory inputs) external;

    function depositNewMA(DepositNewMAInputs memory inputs)
        external
        returns (uint128 accountId);

    function depositPassivePool(DepositPassivePoolInputs memory inputs)
        external;

    error CallerIsNotExecutionHelper(address caller, address token);
    error FailedApproval(address spender, uint256 value);
    error FeatureUnavailable(bytes32 which);
    error UnsafeApproval(address spender, uint256 value);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external pure returns (bytes4);

    function execute(PeripheryExecutionInputs memory inputs) external;

    function isCommandAllowed(uint8 command) external pure returns (bool);

    error InvalidPeripheryExecution();

    function addToFeatureFlagAllowlist(bytes32 feature, address account)
        external;

    function getDeniers(bytes32 feature)
        external
        view
        returns (address[] memory);

    function getFeatureFlagAllowAll(bytes32 feature)
        external
        view
        returns (bool);

    function getFeatureFlagAllowlist(bytes32 feature)
        external
        view
        returns (address[] memory);

    function getFeatureFlagDenyAll(bytes32 feature)
        external
        view
        returns (bool);

    function isFeatureAllowed(bytes32 feature, address account)
        external
        view
        returns (bool);

    function removeFromFeatureFlagAllowlist(bytes32 feature, address account)
        external;

    function setDeniers(bytes32 feature, address[] memory deniers) external;

    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external;

    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external;

    event FeatureFlagAllowAllSet(bytes32 indexed feature, bool allowAll);
    event FeatureFlagAllowlistAdded(bytes32 indexed feature, address account);
    event FeatureFlagAllowlistRemoved(bytes32 indexed feature, address account);
    event FeatureFlagDeniersReset(bytes32 indexed feature, address[] deniers);
    event FeatureFlagDenyAllSet(bytes32 indexed feature, bool denyAll);
    error ValueAlreadyInSet();
    error ValueNotInSet();

    function acceptOwnership() external;

    function getImplementation() external view returns (address);

    function nominateNewOwner(address newNominatedOwner) external;

    function nominatedOwner() external view returns (address);

    function owner() external view returns (address);

    function renounceNomination() external;

    function simulateUpgradeTo(address newImplementation) external;

    function upgradeTo(address newImplementation) external;

    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event Upgraded(address indexed self, address implementation);
    error ImplementationIsSterile(address implementation);
    error NoChange();
    error NotAContract(address contr);
    error NotNominated(address addr);
    error UpgradeSimulationFailed();
    error ZeroAddress();

    function transferFromMAToMA(TransferFromMAToMAInputs memory inputs)
        external;

    function transferFromMAToPool(TransferFromMAToPoolInputs memory inputs)
        external;

    function transferFromPoolToMA(TransferFromPoolToMAInputs memory inputs)
        external;

    function withdrawMA(WithdrawMAInputs memory inputs) external;

    function withdrawPassivePool(WithdrawPassivePoolInputs memory inputs)
        external;

    error NotEnoughFees(uint256 tokenAmount, uint256 tokenFees);
}

interface GlobalConfiguration {
    struct Data {
        address coreProxy;
        address rUSDProxy;
        address passivePoolProxy;
    }
}

struct DepositExistingMAInputs {
    uint128 accountId;
    address token;
}

struct DepositNewMAInputs {
    address accountOwner;
    address token;
}

struct DepositPassivePoolInputs {
    uint128 poolId;
    address owner;
    uint256 minShares;
}

struct Command {
    uint8 commandType;
    bytes inputs;
    uint128 marketId;
    uint128 exchangeId;
}

struct EIP712Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 deadline;
}

struct PeripheryExecutionInputs {
    uint128 accountId;
    Command[] commands;
    EIP712Signature sig;
}

struct TransferInput {
    uint128 destAccountId;
    address collateral;
    uint256 collateralAmount;
}

struct TransferFromMAToMAInputs {
    uint128 accountId;
    TransferInput transfer;
    EIP712Signature sig;
}

struct TransferFromMAToPoolInputs {
    uint128 accountId;
    uint256 amount;
    EIP712Signature sig;
    uint128 poolId;
    uint256 minShares;
    address receiver;
}

struct TransferFromPoolToMAInputs {
    address owner;
    EIP712Signature sig;
    uint256 sharesAmount;
    uint128 poolId;
    uint256 minOut;
    uint128 accountId;
}

struct WithdrawMAInputs {
    uint128 accountId;
    address token;
    uint256 tokenAmount;
    EIP712Signature sig;
    uint256 socketMsgGasLimit;
    uint256 chainId;
    address receiver;
}

struct WithdrawPassivePoolInputs {
    address owner;
    uint128 poolId;
    uint256 sharesAmount;
    uint256 minOut;
    EIP712Signature sig;
    uint256 socketMsgGasLimit;
    uint256 chainId;
    address receiver;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"type":"function","name":"getGlobalConfiguration","inputs":[],"outputs":[{"name":"","type":"tuple","internalType":"struct GlobalConfiguration.Data","components":[{"name":"coreProxy","type":"address","internalType":"address"},{"name":"rUSDProxy","type":"address","internalType":"address"},{"name":"passivePoolProxy","type":"address","internalType":"address"}]}],"stateMutability":"pure"},{"type":"function","name":"getTokenChainConnector","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"chainId","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"connector","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"getTokenController","inputs":[{"name":"token","type":"address","internalType":"address"}],"outputs":[{"name":"controller","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"getTokenExecutionHelper","inputs":[{"name":"token","type":"address","internalType":"address"}],"outputs":[{"name":"executionHelper","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"getTokenStaticWithdrawFee","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"connector","type":"address","internalType":"address"}],"outputs":[{"name":"staticFee","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"receiveEth","inputs":[],"outputs":[],"stateMutability":"payable"},{"type":"function","name":"rescueErc20","inputs":[{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"token","type":"address","internalType":"address"},{"name":"receiver","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"rescueEth","inputs":[{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setGlobalConfiguration","inputs":[{"name":"config","type":"tuple","internalType":"struct GlobalConfiguration.Data","components":[{"name":"coreProxy","type":"address","internalType":"address"},{"name":"rUSDProxy","type":"address","internalType":"address"},{"name":"passivePoolProxy","type":"address","internalType":"address"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setTokenChainConnector","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"connector","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setTokenController","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"controller","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setTokenExecutionHelper","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"executionHelper","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setTokenStaticWithdrawFee","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"connector","type":"address","internalType":"address"},{"name":"staticFee","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"error","name":"ConnectorNotRegistered","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"chainId","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"ControllerNotRegistered","inputs":[{"name":"token","type":"address","internalType":"address"}]},{"type":"error","name":"ExecutionHelperNotRegistered","inputs":[{"name":"token","type":"address","internalType":"address"}]},{"type":"error","name":"FailedToRescueFunds","inputs":[]},{"type":"error","name":"FailedTransfer","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"Unauthorized","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"function","name":"depositExistingMA","inputs":[{"name":"inputs","type":"tuple","internalType":"struct DepositExistingMAInputs","components":[{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"depositNewMA","inputs":[{"name":"inputs","type":"tuple","internalType":"struct DepositNewMAInputs","components":[{"name":"accountOwner","type":"address","internalType":"address"},{"name":"token","type":"address","internalType":"address"}]}],"outputs":[{"name":"accountId","type":"uint128","internalType":"uint128"}],"stateMutability":"nonpayable"},{"type":"function","name":"depositPassivePool","inputs":[{"name":"inputs","type":"tuple","internalType":"struct DepositPassivePoolInputs","components":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"owner","type":"address","internalType":"address"},{"name":"minShares","type":"uint256","internalType":"uint256"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"error","name":"CallerIsNotExecutionHelper","inputs":[{"name":"caller","type":"address","internalType":"address"},{"name":"token","type":"address","internalType":"address"}]},{"type":"error","name":"FailedApproval","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"FeatureUnavailable","inputs":[{"name":"which","type":"bytes32","internalType":"bytes32"}]},{"type":"error","name":"UnsafeApproval","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"}]},{"type":"function","name":"onERC721Received","inputs":[{"name":"operator","type":"address","internalType":"address"},{"name":"from","type":"address","internalType":"address"},{"name":"tokenId","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"","type":"bytes4","internalType":"bytes4"}],"stateMutability":"pure"},{"type":"function","name":"execute","inputs":[{"name":"inputs","type":"tuple","internalType":"struct PeripheryExecutionInputs","components":[{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"commands","type":"tuple[]","internalType":"struct Command[]","components":[{"name":"commandType","type":"uint8","internalType":"enum CommandType"},{"name":"inputs","type":"bytes","internalType":"bytes"},{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"exchangeId","type":"uint128","internalType":"uint128"}]},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"isCommandAllowed","inputs":[{"name":"command","type":"uint8","internalType":"enum CommandType"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"pure"},{"type":"error","name":"InvalidPeripheryExecution","inputs":[]},{"type":"function","name":"addToFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"isFeatureAllowed","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"removeFromFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"deniers","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"allowAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"denyAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"FeatureFlagAllowAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"allowAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistAdded","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistRemoved","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagDeniersReset","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"deniers","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"FeatureFlagDenyAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"denyAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"error","name":"ValueAlreadyInSet","inputs":[]},{"type":"error","name":"ValueNotInSet","inputs":[]},{"type":"function","name":"acceptOwnership","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getImplementation","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"nominateNewOwner","inputs":[{"name":"newNominatedOwner","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"nominatedOwner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"owner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"renounceNomination","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"simulateUpgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"upgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"OwnerChanged","inputs":[{"name":"oldOwner","type":"address","indexed":false,"internalType":"address"},{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"OwnerNominated","inputs":[{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"Upgraded","inputs":[{"name":"self","type":"address","indexed":true,"internalType":"address"},{"name":"implementation","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"error","name":"ImplementationIsSterile","inputs":[{"name":"implementation","type":"address","internalType":"address"}]},{"type":"error","name":"NoChange","inputs":[]},{"type":"error","name":"NotAContract","inputs":[{"name":"contr","type":"address","internalType":"address"}]},{"type":"error","name":"NotNominated","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"error","name":"UpgradeSimulationFailed","inputs":[]},{"type":"error","name":"ZeroAddress","inputs":[]},{"type":"function","name":"transferFromMAToMA","inputs":[{"name":"inputs","type":"tuple","internalType":"struct TransferFromMAToMAInputs","components":[{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"transfer","type":"tuple","internalType":"struct TransferInput","components":[{"name":"destAccountId","type":"uint128","internalType":"uint128"},{"name":"collateral","type":"address","internalType":"address"},{"name":"collateralAmount","type":"uint256","internalType":"uint256"}]},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"transferFromMAToPool","inputs":[{"name":"inputs","type":"tuple","internalType":"struct TransferFromMAToPoolInputs","components":[{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"minShares","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"transferFromPoolToMA","inputs":[{"name":"inputs","type":"tuple","internalType":"struct TransferFromPoolToMAInputs","components":[{"name":"owner","type":"address","internalType":"address"},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"sharesAmount","type":"uint256","internalType":"uint256"},{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"minOut","type":"uint256","internalType":"uint256"},{"name":"accountId","type":"uint128","internalType":"uint128"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"withdrawMA","inputs":[{"name":"inputs","type":"tuple","internalType":"struct WithdrawMAInputs","components":[{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"},{"name":"tokenAmount","type":"uint256","internalType":"uint256"},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"socketMsgGasLimit","type":"uint256","internalType":"uint256"},{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"withdrawPassivePool","inputs":[{"name":"inputs","type":"tuple","internalType":"struct WithdrawPassivePoolInputs","components":[{"name":"owner","type":"address","internalType":"address"},{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"sharesAmount","type":"uint256","internalType":"uint256"},{"name":"minOut","type":"uint256","internalType":"uint256"},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"socketMsgGasLimit","type":"uint256","internalType":"uint256"},{"name":"chainId","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"error","name":"NotEnoughFees","inputs":[{"name":"tokenAmount","type":"uint256","internalType":"uint256"},{"name":"tokenFees","type":"uint256","internalType":"uint256"}]}]
*/