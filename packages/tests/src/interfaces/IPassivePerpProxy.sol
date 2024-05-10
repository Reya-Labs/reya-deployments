// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IPassivePerpProxy {
    function createMarket(string memory name, uint128 passivePoolId)
        external
        returns (uint128 id);

    function getMarketConfiguration(uint128 marketId)
        external
        view
        returns (MarketConfigurationData memory config);

    function setAccountTier(
        uint128 marketId,
        uint128 accountId,
        uint256 tierId
    ) external;

    function setExchangeRebate(
        uint128 exchangeId,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 rebate
    ) external;

    function setGlobalConfiguration(GlobalConfiguration.Data memory config)
        external;

    function setMarketConfiguration(
        uint128 marketId,
        MarketConfigurationData memory config
    ) external;

    function setPoolRebate(
        uint128 poolId,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 rebate
    ) external;

    function setRiskBlockId(
        uint128 marketId,
        uint128 riskBlockId,
        uint256 riskMatrixIndex
    ) external;

    function setTierFee(
        uint128 marketId,
        uint256 tierId,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 feeParameter
    ) external;

    error InvalidMarketConfiguration(
        uint128 marketId,
        MarketConfigurationData config
    );
    error MarketNotFound(uint128 marketId);
    error Unauthorized(address addr);

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

    function getFundingVelocity(uint128 marketId)
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
            int256
        );

    function getLatestFundingAndADLTrackers(uint128 marketId)
        external
        view
        returns (
            FundingAndADLTrackers memory shortTrackers,
            FundingAndADLTrackers memory longTrackers
        );

    function getLatestFundingRate(uint128 marketId)
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
            int256
        );

    function getLatestMTMData(uint128 marketId)
        external
        view
        returns (PriceData memory);

    function getOpenBaseInterest(uint128 marketId)
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
            uint256
        );

    function getPoolMaxExposures(uint128 marketId)
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
            uint256 maxExposureShort,
            /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
            uint256 maxExposureLong
        );

    function getUpdatedPositionInfo(uint128 marketId, uint128 accountId)
        external
        view
        returns (PerpPosition memory);

    error ComplexQuadraticRoots(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 a,
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 b,
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 c
    );
    error OverflowInt256ToUint256();
    error OverflowUint256ToInt256();
    error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);
    error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);
    error PRBMath_SD59x18_Div_InputTooSmall();
    error PRBMath_SD59x18_Div_Overflow(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x,
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 y
    );
    error PRBMath_SD59x18_IntoUD60x18_Underflow(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x
    );
    error PRBMath_SD59x18_Mul_InputTooSmall();
    error PRBMath_SD59x18_Mul_Overflow(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x,
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 y
    );
    error PRBMath_SD59x18_Sqrt_NegativeInput(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x
    );
    error PRBMath_SD59x18_Sqrt_Overflow(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x
    );
    error PRBMath_UD60x18_IntoSD59x18_Overflow(
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 x
    );
    error ZeroQuadraticCoefficient();

    function executeLiquidationOrder(
        uint128 liquidatableAccountId,
        uint128 liquidatorAccountId,
        uint128 marketId,
        uint8 liquidationType,
        bytes memory inputs
    ) external returns (bytes memory output);

    function executeMatchOrder(MatchOrderInputs memory matchOrderInputs)
        external
        returns (bytes memory output, MatchOrderFees memory matchOrderFees);

    function executePropagateCashflow(
        uint128 accountId,
        uint128 marketId,
        bytes memory inputs
    ) external returns (bytes memory output, int256 cashflowAmount);

    function getAccountFilledExposures(uint128 marketId, uint128 accountId)
        external
        view
        returns (FilledExposure[] memory filledExposures);

    function getAccountPnLComponents(uint128 marketId, uint128 accountId)
        external
        view
        returns (PnLComponents memory);

    function getNormalisedExposureAndPSlippage(
        uint128 marketId,
        uint128 accountId,
        bytes memory inputs
    )
        external
        view
        returns (
            /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
            int256 normalisedExposure,
            /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
            uint256 pSlippage
        );

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function validateLiquidationOrder(
        uint128 liquidatableAccountId,
        uint128 liquidatorAccountId,
        uint128 marketId,
        bytes memory inputs
    ) external view;

    error DustyOrderSize(
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 absOrderBase,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 absBasePostOrder,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 baseSpacing
    );
    error ExceededMaxExposure(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 netExposure,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 maxExposure
    );
    error ExchangeRebateParameterTooLarge();
    error FeatureUnavailable(bytes32 which);
    error FeeParameterTooLarge();
    error InvalidLiquidationType(uint8 liquidationType);
    error InvalidOrderCounterparties();
    error InvalidUnwindBase(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 currentBase,
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 unwindBase
    );
    error LiquidationAgainstPassivePool();
    error LiquidationIncreasesOpenInterest(
        LiquidationOrder order,
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 openInterestDelta
    );
    error LiquidationOrderSizeTooLarge(LiquidationOrder order);
    error MaxDutchLiquidationVolumeExceeded(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 requestedLiquidatedBase,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 maxVolume
    );
    error NegativeOpenInterest();
    error NegativePrice();
    error OnlyCoreProxy(address msgSender);
    error OpenInterestExceeded(uint128 marketId);
    error PRBMath_SD59x18_Abs_MinSD59x18();
    error PRBMath_SD59x18_Exp2_InputTooBig(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x
    );
    error PRBMath_SD59x18_Log_InputTooSmall(
        /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
        int256 x
    );
    error PRBMath_UD60x18_Sqrt_Overflow(
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 x
    );
    error PoolRebateParameterTooLarge();
    error SelfLiquidation(uint128 accountId);
    error SmallOrderSize(
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 absBasePostOrder,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 minimumOrderBase
    );
    error UnacceptableOrderPrice(
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 executedOrderPrice,
        /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
        uint256 orderPriceLimit
    );
    error WrongLiquidationDirection(LiquidationOrder order);
    error ZeroOrderSize();
}

interface GlobalConfiguration {
    struct Data {
        address coreProxy;
        address exchangeProxy;
    }
}

struct DutchConfiguration {
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 lambda;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 minBase;
}

struct SlippageParams {
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 phi;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 beta;
}

struct MarketConfigurationData {
    uint256 riskMatrixIndex;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 maxOpenBase;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 velocityMultiplier;
    bytes32 oracleNodeId;
    uint256 mtmWindow;
    DutchConfiguration dutchConfig;
    SlippageParams slippageParams;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 minimumOrderBase;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 baseSpacing;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 priceSpacing;
}

struct FundingAndADLTrackers {
    /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
    int256 fundingValue;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 baseMultiplier;
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 adlUnwindPrice;
}

struct PriceData {
    /* warning: missing UDVT support in source Solidity version; parameter is `UD60x18`. */
    uint256 price;
    uint256 timestamp;
}

struct PerpPosition {
    /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
    int256 base;
    /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
    int256 realizedPnL;
    PriceData lastPriceData;
    FundingAndADLTrackers trackers;
}

struct MatchOrderInputs {
    address caller;
    uint128 accountId;
    uint128[] counterpartyAccountIds;
    uint128 marketId;
    uint128 exchangeId;
    bool creditExchangeFees;
    bytes inputs;
}

struct MatchOrderFees {
    uint256 protocolFeeCredit;
    uint256 exchangeFeeCredit;
    uint256 takerFeeDebit;
    int256[] makerPayments;
}

struct FilledExposure {
    uint256 riskMatrixIndex;
    int256 exposure;
}

struct PnLComponents {
    int256 realizedPnL;
    int256 unrealizedPnL;
}

struct LiquidationOrder {
    uint128 liquidatableAccountId;
    uint128 liquidatorAccountId;
    /* warning: missing UDVT support in source Solidity version; parameter is `SD59x18`. */
    int256 deltaBase;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"type":"function","name":"createMarket","inputs":[{"name":"name","type":"string","internalType":"string"},{"name":"passivePoolId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"id","type":"uint128","internalType":"uint128"}],"stateMutability":"nonpayable"},{"type":"function","name":"getMarketConfiguration","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"config","type":"tuple","internalType":"struct MarketConfigurationData","components":[{"name":"riskMatrixIndex","type":"uint256","internalType":"uint256"},{"name":"maxOpenBase","type":"uint256","internalType":"UD60x18"},{"name":"velocityMultiplier","type":"uint256","internalType":"UD60x18"},{"name":"oracleNodeId","type":"bytes32","internalType":"bytes32"},{"name":"mtmWindow","type":"uint256","internalType":"uint256"},{"name":"dutchConfig","type":"tuple","internalType":"struct DutchConfiguration","components":[{"name":"lambda","type":"uint256","internalType":"UD60x18"},{"name":"minBase","type":"uint256","internalType":"UD60x18"}]},{"name":"slippageParams","type":"tuple","internalType":"struct SlippageParams","components":[{"name":"phi","type":"uint256","internalType":"UD60x18"},{"name":"beta","type":"uint256","internalType":"UD60x18"}]},{"name":"minimumOrderBase","type":"uint256","internalType":"UD60x18"},{"name":"baseSpacing","type":"uint256","internalType":"UD60x18"},{"name":"priceSpacing","type":"uint256","internalType":"UD60x18"}]}],"stateMutability":"view"},{"type":"function","name":"setAccountTier","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"tierId","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setExchangeRebate","inputs":[{"name":"exchangeId","type":"uint128","internalType":"uint128"},{"name":"rebate","type":"uint256","internalType":"UD60x18"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setGlobalConfiguration","inputs":[{"name":"config","type":"tuple","internalType":"struct GlobalConfiguration.Data","components":[{"name":"coreProxy","type":"address","internalType":"address"},{"name":"exchangeProxy","type":"address","internalType":"address"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setMarketConfiguration","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"config","type":"tuple","internalType":"struct MarketConfigurationData","components":[{"name":"riskMatrixIndex","type":"uint256","internalType":"uint256"},{"name":"maxOpenBase","type":"uint256","internalType":"UD60x18"},{"name":"velocityMultiplier","type":"uint256","internalType":"UD60x18"},{"name":"oracleNodeId","type":"bytes32","internalType":"bytes32"},{"name":"mtmWindow","type":"uint256","internalType":"uint256"},{"name":"dutchConfig","type":"tuple","internalType":"struct DutchConfiguration","components":[{"name":"lambda","type":"uint256","internalType":"UD60x18"},{"name":"minBase","type":"uint256","internalType":"UD60x18"}]},{"name":"slippageParams","type":"tuple","internalType":"struct SlippageParams","components":[{"name":"phi","type":"uint256","internalType":"UD60x18"},{"name":"beta","type":"uint256","internalType":"UD60x18"}]},{"name":"minimumOrderBase","type":"uint256","internalType":"UD60x18"},{"name":"baseSpacing","type":"uint256","internalType":"UD60x18"},{"name":"priceSpacing","type":"uint256","internalType":"UD60x18"}]}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setPoolRebate","inputs":[{"name":"poolId","type":"uint128","internalType":"uint128"},{"name":"rebate","type":"uint256","internalType":"UD60x18"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setRiskBlockId","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"riskBlockId","type":"uint128","internalType":"uint128"},{"name":"riskMatrixIndex","type":"uint256","internalType":"uint256"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setTierFee","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"tierId","type":"uint256","internalType":"uint256"},{"name":"feeParameter","type":"uint256","internalType":"UD60x18"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"error","name":"InvalidMarketConfiguration","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"config","type":"tuple","internalType":"struct MarketConfigurationData","components":[{"name":"riskMatrixIndex","type":"uint256","internalType":"uint256"},{"name":"maxOpenBase","type":"uint256","internalType":"UD60x18"},{"name":"velocityMultiplier","type":"uint256","internalType":"UD60x18"},{"name":"oracleNodeId","type":"bytes32","internalType":"bytes32"},{"name":"mtmWindow","type":"uint256","internalType":"uint256"},{"name":"dutchConfig","type":"tuple","internalType":"struct DutchConfiguration","components":[{"name":"lambda","type":"uint256","internalType":"UD60x18"},{"name":"minBase","type":"uint256","internalType":"UD60x18"}]},{"name":"slippageParams","type":"tuple","internalType":"struct SlippageParams","components":[{"name":"phi","type":"uint256","internalType":"UD60x18"},{"name":"beta","type":"uint256","internalType":"UD60x18"}]},{"name":"minimumOrderBase","type":"uint256","internalType":"UD60x18"},{"name":"baseSpacing","type":"uint256","internalType":"UD60x18"},{"name":"priceSpacing","type":"uint256","internalType":"UD60x18"}]}]},{"type":"error","name":"MarketNotFound","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}]},{"type":"error","name":"Unauthorized","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"function","name":"addToFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"address[]","internalType":"address[]"}],"stateMutability":"view"},{"type":"function","name":"getFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"isFeatureAllowed","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"view"},{"type":"function","name":"removeFromFeatureFlagAllowlist","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"account","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setDeniers","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"deniers","type":"address[]","internalType":"address[]"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagAllowAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"allowAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"setFeatureFlagDenyAll","inputs":[{"name":"feature","type":"bytes32","internalType":"bytes32"},{"name":"denyAll","type":"bool","internalType":"bool"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"FeatureFlagAllowAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"allowAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistAdded","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagAllowlistRemoved","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"account","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"FeatureFlagDeniersReset","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"deniers","type":"address[]","indexed":false,"internalType":"address[]"}],"anonymous":false},{"type":"event","name":"FeatureFlagDenyAllSet","inputs":[{"name":"feature","type":"bytes32","indexed":true,"internalType":"bytes32"},{"name":"denyAll","type":"bool","indexed":false,"internalType":"bool"}],"anonymous":false},{"type":"error","name":"ValueAlreadyInSet","inputs":[]},{"type":"error","name":"ValueNotInSet","inputs":[]},{"type":"function","name":"acceptOwnership","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"getImplementation","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"nominateNewOwner","inputs":[{"name":"newNominatedOwner","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"nominatedOwner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"owner","inputs":[],"outputs":[{"name":"","type":"address","internalType":"address"}],"stateMutability":"view"},{"type":"function","name":"renounceNomination","inputs":[],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"simulateUpgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"function","name":"upgradeTo","inputs":[{"name":"newImplementation","type":"address","internalType":"address"}],"outputs":[],"stateMutability":"nonpayable"},{"type":"event","name":"OwnerChanged","inputs":[{"name":"oldOwner","type":"address","indexed":false,"internalType":"address"},{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"OwnerNominated","inputs":[{"name":"newOwner","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"event","name":"Upgraded","inputs":[{"name":"self","type":"address","indexed":true,"internalType":"address"},{"name":"implementation","type":"address","indexed":false,"internalType":"address"}],"anonymous":false},{"type":"error","name":"ImplementationIsSterile","inputs":[{"name":"implementation","type":"address","internalType":"address"}]},{"type":"error","name":"NoChange","inputs":[]},{"type":"error","name":"NotAContract","inputs":[{"name":"contr","type":"address","internalType":"address"}]},{"type":"error","name":"NotNominated","inputs":[{"name":"addr","type":"address","internalType":"address"}]},{"type":"error","name":"UpgradeSimulationFailed","inputs":[]},{"type":"error","name":"ZeroAddress","inputs":[]},{"type":"function","name":"getFundingVelocity","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"int256","internalType":"SD59x18"}],"stateMutability":"view"},{"type":"function","name":"getLatestFundingAndADLTrackers","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"shortTrackers","type":"tuple","internalType":"struct FundingAndADLTrackers","components":[{"name":"fundingValue","type":"int256","internalType":"SD59x18"},{"name":"baseMultiplier","type":"uint256","internalType":"UD60x18"},{"name":"adlUnwindPrice","type":"uint256","internalType":"UD60x18"}]},{"name":"longTrackers","type":"tuple","internalType":"struct FundingAndADLTrackers","components":[{"name":"fundingValue","type":"int256","internalType":"SD59x18"},{"name":"baseMultiplier","type":"uint256","internalType":"UD60x18"},{"name":"adlUnwindPrice","type":"uint256","internalType":"UD60x18"}]}],"stateMutability":"view"},{"type":"function","name":"getLatestFundingRate","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"int256","internalType":"SD59x18"}],"stateMutability":"view"},{"type":"function","name":"getLatestMTMData","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"tuple","internalType":"struct PriceData","components":[{"name":"price","type":"uint256","internalType":"UD60x18"},{"name":"timestamp","type":"uint256","internalType":"uint256"}]}],"stateMutability":"view"},{"type":"function","name":"getOpenBaseInterest","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"uint256","internalType":"UD60x18"}],"stateMutability":"view"},{"type":"function","name":"getPoolMaxExposures","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"maxExposureShort","type":"uint256","internalType":"UD60x18"},{"name":"maxExposureLong","type":"uint256","internalType":"UD60x18"}],"stateMutability":"view"},{"type":"function","name":"getUpdatedPositionInfo","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"accountId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"tuple","internalType":"struct PerpPosition","components":[{"name":"base","type":"int256","internalType":"SD59x18"},{"name":"realizedPnL","type":"int256","internalType":"SD59x18"},{"name":"lastPriceData","type":"tuple","internalType":"struct PriceData","components":[{"name":"price","type":"uint256","internalType":"UD60x18"},{"name":"timestamp","type":"uint256","internalType":"uint256"}]},{"name":"trackers","type":"tuple","internalType":"struct FundingAndADLTrackers","components":[{"name":"fundingValue","type":"int256","internalType":"SD59x18"},{"name":"baseMultiplier","type":"uint256","internalType":"UD60x18"},{"name":"adlUnwindPrice","type":"uint256","internalType":"UD60x18"}]}]}],"stateMutability":"view"},{"type":"error","name":"ComplexQuadraticRoots","inputs":[{"name":"a","type":"int256","internalType":"SD59x18"},{"name":"b","type":"int256","internalType":"SD59x18"},{"name":"c","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"OverflowInt256ToUint256","inputs":[]},{"type":"error","name":"OverflowUint256ToInt256","inputs":[]},{"type":"error","name":"PRBMath_MulDiv18_Overflow","inputs":[{"name":"x","type":"uint256","internalType":"uint256"},{"name":"y","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"PRBMath_MulDiv_Overflow","inputs":[{"name":"x","type":"uint256","internalType":"uint256"},{"name":"y","type":"uint256","internalType":"uint256"},{"name":"denominator","type":"uint256","internalType":"uint256"}]},{"type":"error","name":"PRBMath_SD59x18_Div_InputTooSmall","inputs":[]},{"type":"error","name":"PRBMath_SD59x18_Div_Overflow","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"},{"name":"y","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PRBMath_SD59x18_IntoUD60x18_Underflow","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PRBMath_SD59x18_Mul_InputTooSmall","inputs":[]},{"type":"error","name":"PRBMath_SD59x18_Mul_Overflow","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"},{"name":"y","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PRBMath_SD59x18_Sqrt_NegativeInput","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PRBMath_SD59x18_Sqrt_Overflow","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PRBMath_UD60x18_IntoSD59x18_Overflow","inputs":[{"name":"x","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"ZeroQuadraticCoefficient","inputs":[]},{"type":"function","name":"executeLiquidationOrder","inputs":[{"name":"liquidatableAccountId","type":"uint128","internalType":"uint128"},{"name":"liquidatorAccountId","type":"uint128","internalType":"uint128"},{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"liquidationType","type":"uint8","internalType":"enum LiquidationType"},{"name":"inputs","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"output","type":"bytes","internalType":"bytes"}],"stateMutability":"nonpayable"},{"type":"function","name":"executeMatchOrder","inputs":[{"name":"matchOrderInputs","type":"tuple","internalType":"struct MatchOrderInputs","components":[{"name":"caller","type":"address","internalType":"address"},{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"counterpartyAccountIds","type":"uint128[]","internalType":"uint128[]"},{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"exchangeId","type":"uint128","internalType":"uint128"},{"name":"creditExchangeFees","type":"bool","internalType":"bool"},{"name":"inputs","type":"bytes","internalType":"bytes"}]}],"outputs":[{"name":"output","type":"bytes","internalType":"bytes"},{"name":"matchOrderFees","type":"tuple","internalType":"struct MatchOrderFees","components":[{"name":"protocolFeeCredit","type":"uint256","internalType":"uint256"},{"name":"exchangeFeeCredit","type":"uint256","internalType":"uint256"},{"name":"takerFeeDebit","type":"uint256","internalType":"uint256"},{"name":"makerPayments","type":"int256[]","internalType":"int256[]"}]}],"stateMutability":"nonpayable"},{"type":"function","name":"executePropagateCashflow","inputs":[{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"inputs","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"output","type":"bytes","internalType":"bytes"},{"name":"cashflowAmount","type":"int256","internalType":"int256"}],"stateMutability":"nonpayable"},{"type":"function","name":"getAccountFilledExposures","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"accountId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"filledExposures","type":"tuple[]","internalType":"struct FilledExposure[]","components":[{"name":"riskMatrixIndex","type":"uint256","internalType":"uint256"},{"name":"exposure","type":"int256","internalType":"int256"}]}],"stateMutability":"view"},{"type":"function","name":"getAccountPnLComponents","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"accountId","type":"uint128","internalType":"uint128"}],"outputs":[{"name":"","type":"tuple","internalType":"struct PnLComponents","components":[{"name":"realizedPnL","type":"int256","internalType":"int256"},{"name":"unrealizedPnL","type":"int256","internalType":"int256"}]}],"stateMutability":"view"},{"type":"function","name":"getNormalisedExposureAndPSlippage","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"accountId","type":"uint128","internalType":"uint128"},{"name":"inputs","type":"bytes","internalType":"bytes"}],"outputs":[{"name":"normalisedExposure","type":"int256","internalType":"SD59x18"},{"name":"pSlippage","type":"uint256","internalType":"UD60x18"}],"stateMutability":"view"},{"type":"function","name":"supportsInterface","inputs":[{"name":"interfaceId","type":"bytes4","internalType":"bytes4"}],"outputs":[{"name":"","type":"bool","internalType":"bool"}],"stateMutability":"pure"},{"type":"function","name":"validateLiquidationOrder","inputs":[{"name":"liquidatableAccountId","type":"uint128","internalType":"uint128"},{"name":"liquidatorAccountId","type":"uint128","internalType":"uint128"},{"name":"marketId","type":"uint128","internalType":"uint128"},{"name":"inputs","type":"bytes","internalType":"bytes"}],"outputs":[],"stateMutability":"view"},{"type":"error","name":"DustyOrderSize","inputs":[{"name":"absOrderBase","type":"uint256","internalType":"UD60x18"},{"name":"absBasePostOrder","type":"uint256","internalType":"UD60x18"},{"name":"baseSpacing","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"ExceededMaxExposure","inputs":[{"name":"netExposure","type":"int256","internalType":"SD59x18"},{"name":"maxExposure","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"ExchangeRebateParameterTooLarge","inputs":[]},{"type":"error","name":"FeatureUnavailable","inputs":[{"name":"which","type":"bytes32","internalType":"bytes32"}]},{"type":"error","name":"FeeParameterTooLarge","inputs":[]},{"type":"error","name":"InvalidLiquidationType","inputs":[{"name":"liquidationType","type":"uint8","internalType":"enum LiquidationType"}]},{"type":"error","name":"InvalidOrderCounterparties","inputs":[]},{"type":"error","name":"InvalidUnwindBase","inputs":[{"name":"currentBase","type":"int256","internalType":"SD59x18"},{"name":"unwindBase","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"LiquidationAgainstPassivePool","inputs":[]},{"type":"error","name":"LiquidationIncreasesOpenInterest","inputs":[{"name":"order","type":"tuple","internalType":"struct LiquidationOrder","components":[{"name":"liquidatableAccountId","type":"uint128","internalType":"uint128"},{"name":"liquidatorAccountId","type":"uint128","internalType":"uint128"},{"name":"deltaBase","type":"int256","internalType":"SD59x18"}]},{"name":"openInterestDelta","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"LiquidationOrderSizeTooLarge","inputs":[{"name":"order","type":"tuple","internalType":"struct LiquidationOrder","components":[{"name":"liquidatableAccountId","type":"uint128","internalType":"uint128"},{"name":"liquidatorAccountId","type":"uint128","internalType":"uint128"},{"name":"deltaBase","type":"int256","internalType":"SD59x18"}]}]},{"type":"error","name":"MaxDutchLiquidationVolumeExceeded","inputs":[{"name":"requestedLiquidatedBase","type":"int256","internalType":"SD59x18"},{"name":"maxVolume","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"NegativeOpenInterest","inputs":[]},{"type":"error","name":"NegativePrice","inputs":[]},{"type":"error","name":"OnlyCoreProxy","inputs":[{"name":"msgSender","type":"address","internalType":"address"}]},{"type":"error","name":"OpenInterestExceeded","inputs":[{"name":"marketId","type":"uint128","internalType":"uint128"}]},{"type":"error","name":"PRBMath_SD59x18_Abs_MinSD59x18","inputs":[]},{"type":"error","name":"PRBMath_SD59x18_Exp2_InputTooBig","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PRBMath_SD59x18_Log_InputTooSmall","inputs":[{"name":"x","type":"int256","internalType":"SD59x18"}]},{"type":"error","name":"PRBMath_UD60x18_Sqrt_Overflow","inputs":[{"name":"x","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"PoolRebateParameterTooLarge","inputs":[]},{"type":"error","name":"SelfLiquidation","inputs":[{"name":"accountId","type":"uint128","internalType":"uint128"}]},{"type":"error","name":"SmallOrderSize","inputs":[{"name":"absBasePostOrder","type":"uint256","internalType":"UD60x18"},{"name":"minimumOrderBase","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"UnacceptableOrderPrice","inputs":[{"name":"executedOrderPrice","type":"uint256","internalType":"UD60x18"},{"name":"orderPriceLimit","type":"uint256","internalType":"UD60x18"}]},{"type":"error","name":"WrongLiquidationDirection","inputs":[{"name":"order","type":"tuple","internalType":"struct LiquidationOrder","components":[{"name":"liquidatableAccountId","type":"uint128","internalType":"uint128"},{"name":"liquidatorAccountId","type":"uint128","internalType":"uint128"},{"name":"deltaBase","type":"int256","internalType":"SD59x18"}]}]},{"type":"error","name":"ZeroOrderSize","inputs":[]}]
*/