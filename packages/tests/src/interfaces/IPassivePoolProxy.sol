// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

import { ActionMetadata, Action, AutoExchangeAmounts } from "./ICoreProxy.sol";

interface IPassivePoolProxy {
    function getRebalanceAmounts(
        uint128 poolId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (RebalanceAmounts memory amounts);

    function getTargetTokenAmount(uint128 poolId, address token)
        external
        view
        returns (uint256);

    function getTokenMarginBalance(uint128 poolId, address token)
        external
        view
        returns (uint256);

    function triggerAutoRebalance(
        uint128 poolId,
        AutoRebalanceInput memory input
    ) external returns (RebalanceAmounts memory amounts);

    error AmountZero();
    error FailedApproval(address spender, uint256 value);
    error FailedTransfer(address from, address to, uint256 value);
    error FeatureUnavailable(bytes32 which);
    error InsufficientAllowance(uint256 required, uint256 existing);
    error InvalidTargetRatiosPostQuote();
    error MarginBalanceNegative(address token, int256 marginBalance);
    error MinPriceNotMet(
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 executionPrice,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 minPrice
    );
    error OverflowInt256ToUint256();
    error OverflowUint256ToInt256();
    error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);
    error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);
    error PRBMath_SD59x18_Mul_InputTooSmall();
    error PRBMath_SD59x18_Mul_Overflow(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x,
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 y
    );
    error PoolInsolvent(uint128 id);
    error PoolNotFound(uint128 id);
    error PoolNotTokenized(uint128 poolId);
    error UnsafeApproval(address spender, uint256 value);
    error ZeroAddress();
    error ZeroAmount(uint256 amountIn, uint256 amountOut);

    function createPool(address quoteToken) external returns (uint128 poolId);

    function getAllocationConfiguration(uint128 poolId)
        external
        view
        returns (AllocationConfigurationData memory);

    function getGlobalConfiguration()
        external
        pure
        returns (GlobalConfiguration.Data memory);

    function getPoolAccountId(uint128 id)
        external
        view
        returns (uint128 accountId);

    function getPoolQuoteToken(uint128 id)
        external
        view
        returns (address quoteToken);

    function getQuoteSupportingCollaterals(uint128 poolId)
        external
        view
        returns (address[] memory);

    function getTargetRatio(uint128 poolId, address token)
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
            uint256
        );

    function getTargetRatioPostQuote(uint128 poolId, address token)
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
            uint256
        );

    function sendCallToCore(bytes memory data) external returns (bytes memory);

    function setAllocationConfiguration(
        uint128 poolId,
        AllocationConfigurationData memory config
    ) external;

    function setGlobalConfiguration(GlobalConfiguration.Data memory config)
        external;

    function setTargetRatioPostQuote(
        uint128 poolId,
        address token,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 targetRatioPostQuote
    ) external;

    error CoreCallReverted(bytes output);
    error InvalidQuoteTokenTargetRatio();
    error TargetRatioPostQuoteAboveOne(
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 targetRatioPostQuote
    );
    error TokenNotSupportingCollateral(address token);
    error Unauthorized(address addr);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external pure returns (bytes4);

    function addToFeatureFlagAllowlist(bytes32 feature, address account)
        external;

    function getAdmins(bytes32 feature)
        external
        view
        returns (address[] memory);

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

    function setAdmins(bytes32 feature, address[] memory admins) external;

    function setDeniers(bytes32 feature, address[] memory deniers) external;

    function setFeatureFlagAllowAll(bytes32 feature, bool allowAll) external;

    function setFeatureFlagDenyAll(bytes32 feature, bool denyAll) external;

    event FeatureFlagAdminsReset(bytes32 indexed feature, address[] admins);
    event FeatureFlagAllowAllSet(bytes32 indexed feature, bool allowAll);
    event FeatureFlagAllowlistAdded(bytes32 indexed feature, address account);
    event FeatureFlagAllowlistRemoved(bytes32 indexed feature, address account);
    event FeatureFlagDeniersReset(bytes32 indexed feature, address[] deniers);
    event FeatureFlagDenyAllSet(bytes32 indexed feature, bool denyAll);
    error AddressZero();
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

    function addLiquidity(
        uint128 poolId,
        address owner,
        uint256 amount,
        uint256 minShares,
        ActionMetadata memory actionMetadata
    ) external returns (uint256);

    function addLiquidityV2(
        uint128 poolId,
        AddLiquidityV2Input memory input,
        ActionMetadata memory actionMetadata
    ) external returns (uint256 mintAmount);

    function calculateSharesToMint(
        uint128 poolId,
        address token,
        uint256 tokenAmount
    ) external view returns (uint256 mintAmount, uint256 tokenAmountInQuote);

    function calculateTokenAmount(
        uint128 poolId,
        address token,
        uint256 sharesAmount
    ) external view returns (uint256 tokenAmount, uint256 tokenAmountInQuote);

    function getAccountBalance(uint128 poolId, address account)
        external
        view
        returns (uint256);

    function getAccountNonce(address account) external view returns (uint256);

    function getPoolMarginBalance(uint128 poolId)
        external
        view
        returns (uint256);

    function getSharePrice(uint128 poolId)
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
            uint256
        );

    function getShareSupply(uint128 poolId) external view returns (uint256);

    function removeLiquidity(
        uint128 poolId,
        uint256 sharesAmount,
        uint256 minOut,
        ActionMetadata memory actionMetadata
    ) external returns (uint256);

    function removeLiquidityBySig(
        address owner,
        uint128 poolId,
        uint256 sharesAmount,
        uint256 minOut,
        EIP712Signature memory sig,
        bytes memory extraSignatureData,
        ActionMetadata memory actionMetadata
    ) external returns (uint256);

    function removeLiquidityBySigV2(
        address owner,
        uint128 poolId,
        RemoveLiquidityV2Input memory input,
        EIP712Signature memory sig,
        bytes memory extraSignatureData,
        ActionMetadata memory actionMetadata
    ) external returns (uint256 tokenAmount);

    function removeLiquidityV2(
        uint128 poolId,
        RemoveLiquidityV2Input memory input,
        ActionMetadata memory actionMetadata
    ) external returns (uint256 tokenAmount);

    error InsufficientSharesOutput(uint256 minAmount, uint256 minShares);
    error InsufficientTokenOutput(uint256 tokenAmount, uint256 minOut);
    error NotEnoughBalance(
        address account,
        uint256 accountBalance,
        uint256 amount
    );
    error PoolMarginIsZero(uint128 id);
    error SignatureExpired();
    error SignatureInvalid();
    error TokenNotEligibleForShares(address token);
    error UnauthorizedV2Liquidity(uint128 poolId, address owner);
    error ZeroSharesSupply();
    error ZeroStakedSupply();

    function addLiquidityTokenized(
        uint128 poolId,
        address owner,
        uint256 amount,
        uint256 minShares,
        ActionMetadata memory actionMetadata
    ) external returns (uint256);

    function asset(uint128 poolId) external view returns (address);

    function removeLiquidityTokenized(
        uint128 poolId,
        uint256 sharesAmount,
        uint256 minOut,
        ActionMetadata memory actionMetadata
    ) external returns (uint256);

    function stakedAsset(uint128 poolId) external view returns (address);

    function tokenizePool(uint128 poolId, address stakedQuoteAddress) external;

    function triggerStakedAssetAutoExchange(uint128 poolId, uint128 accountId)
        external returns (AutoExchangeAmounts memory);

    error InvalidDecimals(uint8 decimals, uint8 expectedDecimals);
    error PoolAlreadyTokenized(address stakedQuoteAddress);
    error ZeroAutoExchangeAmount();
}

interface GlobalConfiguration {
    struct Data {
        address coreProxy;
    }
}

struct RebalanceAmounts {
    uint256 amountIn;
    uint256 amountOut;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 priceInToOut;
}

struct AutoRebalanceInput {
    address tokenIn;
    uint256 amountIn;
    address tokenOut;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 minPrice;
    address receiverAddress;
}

struct AllocationConfigurationData {
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 quoteTokenTargetRatio;
}

struct AddLiquidityV2Input {
    address token;
    uint256 amount;
    address owner;
    uint256 minShares;
}

struct EIP712Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 deadline;
}

struct RemoveLiquidityV2Input {
    address token;
    uint256 sharesAmount;
    address receiver;
    uint256 minOut;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"type":"function","name":"getRebalanceAmounts","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"tokenIn","type":"address","internalType":"address"},{"name":"tokenOut","type":"address","internalType":"address"},{"name":"amountIn","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"amounts","type":"tuple","internalType":"struct RebalanceAmounts","components":[{"name":"amountIn","type":"uint256","internalType":"uint256"},{"name":"amountOut","type":"uint256","internalType":"uint256"},{"name":"priceInToOut","type":"uint256","internalType":"UD60x18"}]}],"stateMutability":"view"},{"type":"function","name":"getTargetTokenAmount","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getTokenMarginBalance","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"triggerAutoRebalance","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"input","type":"tuple","internalType":"struct AutoRebalanceInput","components":[{"name":"tokenIn","type":"address","internalType":"address"},{"name":"amountIn","type":"uint256","internalType":"uint256"},{"name":"tokenOut","type":"address","internalType":"address"},{"name":"minPrice","type":"uint256","internalType":"UD60x18"},{"name":"receiverAddress","type":"address","internalType":"address"}]}],"outputs":[{"name":"amounts","type":"tuple","internalType":"struct RebalanceAmounts","components":[{"name":"amountIn","type":"uint256","internalType":"uint256"},{"name":"amountOut","type":"uint256","internalType":"uint256"},{"name":"priceInToOut","type":"uint256","internalType":"UD60x18"}]}],"stateMutability":"nonpayable"},{"type":"error","name":"AmountZero","inputs":[]},{"type":"error","name":"FailedApproval","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"FailedTransfer","inputs":[{"name":"from","type":"address","internalType":"address"},{"name":"to","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"FeatureUnavailable","inputs":[{"name":"which","type":"bytes32","internalType":"bytes32"}]},{"type":"error","name":"InsufficientAllowance","inputs":[{"name":"required","type":"uint256","internalType":"uint256"},{"name":"existing","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"InvalidTargetRatiosPostQuote","inputs":[]},{"type":"error","name":"MarginBalanceNegative","inputs":[{"name":"token","type":"address","internalType":"address"},{"name":"marginBalance","type":"int256","internalType":"int256"}]},{"type":"error","name":"MinPriceNotMet","inputs":[{"name":"executionPrice","type":"uint256","internalType":"UD60x18"},{"name":"minPrice","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"OverflowInt256ToUint256","inputs":[]},{"type":"error","name":"OverflowUint256ToInt256","inputs":[]},{"type":"error","name":"PRBMath_MulDiv18_Overflow","inputs":[{"name":"x","type":"uint256","internalType":"uint256"},{"name":"y","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"PRBMath_MulDiv_Overflow","inputs":[{"name":"x","type":"uint256","internalType":"uint256"},{"name":"y","type":"uint256","internalType":"uint256"},{"name":"denominator","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"PRBMath_SD59x18_Mul_InputTooSmall","inputs":[]},{"type":"error","name":"PRBMath_SD59x18_Mul_Overflow","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"},{"name":"y","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PoolInsolvent","inputs":[{"name":"id","type":"uint128","internalType":"uint128"}]},{"type":"error","name":"PoolNotFound","inputs":[{"name":"id","type":"uint128","internalType":"uint128"}]},{"type":"error","name":"PoolNotTokenized","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}]},{"type":"error","name":"UnsafeApproval","inputs":[{"name":"spender","type":"address","internalType":"address"},{"name":"value","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"ZeroAddress","inputs":[]},{"type":"error","name":"ZeroAmount","inputs":[{"name":"amountIn","type":"uint256","internalType":"uint256"},{"name":"amountOut","type":"uint256","internalType":"uint256"}]},{"type":"function","name":"createPool","inputs":[{"name":"quoteToken","type":"address","internalType":"address"}],"outputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"stateMutability":"nonpayable"},{"type":"function","name":"getAllocationConfiguration","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"tuple","internalType":"struct AllocationConfigurationData","components":[{"name":"quoteTokenTargetRatio","type":"uint256","internalType":"UD60x18"}]}],"stateMutability":"view"},{"type":"function","name":"getGlobalConfiguration","inputs":[],"outputs":[{"name":"","type":"tuple","internalType":"struct GlobalConfiguration.Data","components":[{"name":"coreProxy","type":"address","internalType":"address"}]}],"stateMutability":"pure"},{"type":"function","name":"getPoolAccountId","inputs":[{"name":"id","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"accountId","type":"uint128","internalType":"uint128"}],"stateMutability":"view"},{"type":"function","name":"getPoolQuoteToken","inputs":[{"name":"id","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"quoteToken","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"getQuoteSupportingCollaterals","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getTargetRatio","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"UD60x18"}],"stateMutability":"view"},{"type":"function","name":"getTargetRatioPostQuote","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"UD60x18"}],"stateMutability":"view"},{"type":"function","name":"sendCallToCore","inputs":[{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"","type":"bytes","internalType":"bytes"}],"stateMutability":"nonpayable"},{"type":"function","name":"setAllocationConfiguration","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"config","type":"tuple","internalType":"struct AllocationConfigurationData","components":[{"name":"quoteTokenTargetRatio","type":"uint256","internalType":"UD60x18"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setGlobalConfiguration","inputs":[{"name":"config","type":"tuple","internalType":"struct GlobalConfiguration.Data","components":[{"name":"coreProxy","type":"address","internalType":"address"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setTargetRatioPostQuote","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"},{"name":"targetRatioPostQuote","type":"uint256","internalType":"UD60x18"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"error","name":"CoreCallReverted","inputs":[{"name":"output","type":"bytes","internalType":"bytes"}]},{"type":"error","name":"InvalidQuoteTokenTargetRatio","inputs":[]},{"type":"error","name":"TargetRatioPostQuoteAboveOne","inputs":[{"name":"targetRatioPostQuote","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"TokenNotSupportingCollateral","inputs":[{"name":"token","type":"address","internalType":"address"}]},{"type":"error","name":"Unauthorized","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"function","name":"onERC721Received","inputs":[{"name":"operator","type":"address","internalType":"address"},{"name":"from","type":"address","internalType":"address"},{"name":"tokenId","type":"uint256","internalType":"uint256"},{"name":"data","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"","type":"bytes4","internalType":"bytes4"}],"stateMutability":"pure"},{"type":"function","name":"addToFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getAdmins","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"isFeatureAllowed","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"removeFromFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setAdmins","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"admins","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"deniers","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"allowAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"denyAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"FeatureFlagAdminsReset","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"admins","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"allowAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistAdded","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistRemoved","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagDeniersReset","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"deniers","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"FeatureFlagDenyAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"denyAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"error","name":"AddressZero","inputs":[]},{"type":"error","name":"ValueAlreadyInSet","inputs":[]},{"type":"error","name":"ValueNotInSet","inputs":[]},{"type":"function","name":"acceptOwnership","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getImplementation","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"nominateNewOwner","inputs":[{"name":"newNominatedOwner","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"nominatedOwner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"owner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"renounceNomination","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"simulateUpgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"upgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"OwnerChanged","inputs":[{"name":"oldOwner","type":"address","indexed":false,"internalType":"address"},{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"OwnerNominated","inputs":[{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"Upgraded","inputs":[{"name":"self","type":"address","indexed":true,"internalType":"address"},{"name":"implementation","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"error","name":"ImplementationIsSterile","inputs":[{"name":"implementation","type":"address","internalType":"address"}]},{"type":"error","name":"NoChange","inputs":[]},{"type":"error","name":"NotAContract","inputs":[{"name":"contr","type":"address","internalType":"address"}]},{"type":"error","name":"NotNominated","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"error","name":"UpgradeSimulationFailed","inputs":[]},{"type":"function","name":"addLiquidity","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"owner","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"minShares","type":"uint256","internalType":"uint256"},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"addLiquidityV2","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"input","type":"tuple","internalType":"struct AddLiquidityV2Input","components":[{"name":"token","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"owner","type":"address","internalType":"address"},{"name":"minShares","type":"uint256","internalType":"uint256"}]},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"mintAmount","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"calculateSharesToMint","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"},{"name":"tokenAmount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"mintAmount","type":"uint256","internalType":"uint256"},{"name":"tokenAmountInQuote","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"calculateTokenAmount","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"token","type":"address","internalType":"address"},{"name":"sharesAmount","type":"uint256","internalType":"uint256"}],"outputs":[{"name":"tokenAmount","type":"uint256","internalType":"uint256"},{"name":"tokenAmountInQuote","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getAccountBalance","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getAccountNonce","inputs":[{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getPoolMarginBalance","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"getSharePrice","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"uint256","internalType":"UD60x18"}],"stateMutability":"view"},{"type":"function","name":"getShareSupply","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"view"},{"type":"function","name":"removeLiquidity","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"sharesAmount","type":"uint256","internalType":"uint256"},{"name":"minOut","type":"uint256","internalType":"uint256"},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"removeLiquidityBySig","inputs":[{"name":"owner","type":"address","internalType":"address"},{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"sharesAmount","type":"uint256","internalType":"uint256"},{"name":"minOut","type":"uint256","internalType":"uint256"},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"extraSignatureData","type":"bytes","internalType":"bytes"},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"removeLiquidityBySigV2","inputs":[{"name":"owner","type":"address","internalType":"address"},{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"input","type":"tuple","internalType":"struct RemoveLiquidityV2Input","components":[{"name":"token","type":"address","internalType":"address"},{"name":"sharesAmount","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"},{"name":"minOut","type":"uint256","internalType":"uint256"}]},{"name":"sig","type":"tuple","internalType":"struct EIP712Signature","components":[{"name":"v","type":"uint8","internalType":"uint8"},{"name":"r","type":"bytes32","internalType":"bytes32"},{"name":"s","type":"bytes32","internalType":"bytes32"},{"name":"deadline","type":"uint256","internalType":"uint256"}]},{"name":"extraSignatureData","type":"bytes","internalType":"bytes"},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"tokenAmount","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"removeLiquidityV2","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"input","type":"tuple","internalType":"struct RemoveLiquidityV2Input","components":[{"name":"token","type":"address","internalType":"address"},{"name":"sharesAmount","type":"uint256","internalType":"uint256"},{"name":"receiver","type":"address","internalType":"address"},{"name":"minOut","type":"uint256","internalType":"uint256"}]},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"tokenAmount","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"error","name":"InsufficientSharesOutput","inputs":[{"name":"minAmount","type":"uint256","internalType":"uint256"},{"name":"minShares","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"InsufficientTokenOutput","inputs":[{"name":"tokenAmount","type":"uint256","internalType":"uint256"},{"name":"minOut","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"NotEnoughBalance","inputs":[{"name":"account","type":"address","internalType":"address"},{"name":"accountBalance","type":"uint256","internalType":"uint256"},{"name":"amount","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"PoolMarginIsZero","inputs":[{"name":"id","type":"uint128","internalType":"uint128"}]},{"type":"error","name":"SignatureExpired","inputs":[]},{"type":"error","name":"SignatureInvalid","inputs":[]},{"type":"error","name":"TokenNotEligibleForShares","inputs":[{"name":"token","type":"address","internalType":"address"}]},{"type":"error","name":"UnauthorizedV2Liquidity","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"owner","type":"address","internalType":"address"}]},{"type":"error","name":"ZeroSharesSupply","inputs":[]},{"type":"error","name":"ZeroStakedSupply","inputs":[]},{"type":"function","name":"addLiquidityTokenized","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"owner","type":"address","internalType":"address"},{"name":"amount","type":"uint256","internalType":"uint256"},{"name":"minShares","type":"uint256","internalType":"uint256"},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"asset","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"removeLiquidityTokenized","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"sharesAmount","type":"uint256","internalType":"uint256"},{"name":"minOut","type":"uint256","internalType":"uint256"},{"name":"actionMetadata","type":"tuple","internalType":"struct ActionMetadata","components":[{"name":"action","type":"uint8","internalType":"enum Action"},{"name":"onBehalfOf","type":"address","internalType":"address"}]}],"outputs":[{"name":"","type":"uint256","internalType":"uint256"}],"stateMutability":"nonpayable"},{"type":"function","name":"stakedAsset","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"tokenizePool","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"stakedQuoteAddress","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"triggerStakedAssetAutoExchange","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"accountId","type":"uint128","internalType":"uint128"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"error","name":"InvalidDecimals","inputs":[{"name":"decimals","type":"uint8","internalType":"uint8"},{"name":"expectedDecimals","type":"uint8","internalType":"uint8"}]},{"type":"error","name":"PoolAlreadyTokenized","inputs":[{"name":"stakedQuoteAddress","type":"address","internalType":"address"}]},{"type":"error","name":"ZeroAutoExchangeAmount","inputs":[]}]
*/