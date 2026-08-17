pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import {
    CachedCollateralConfig,
    CollateralConfig,
    GlobalCachedCollateralConfig,
    GlobalCollateralConfig,
    ICoreProxy,
    ParentCollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";

contract UsdcRiskDenominatorForkTest is ReyaForkTest {
    function test_Devnet_UsdcIsRegisteredAsRiskDenominatorOnly() public view {
        (GlobalCollateralConfig memory globalConfig, GlobalCachedCollateralConfig memory globalCachedConfig) =
            ICoreProxy(sec.core).getGlobalCollateralConfig(sec.usdc);

        assertEq(globalConfig.collateralAdapter, address(0));
        assertEq(globalCachedConfig.collateralAddress, sec.usdc);
        assertEq(globalCachedConfig.collateralDecimals, 6);

        (
            CollateralConfig memory collateralConfig,
            ParentCollateralConfig memory parentConfig,
            CachedCollateralConfig memory cachedConfig
        ) = ICoreProxy(sec.core).getCollateralConfig(1, sec.usdc);

        assertFalse(collateralConfig.depositingEnabled);
        assertEq(collateralConfig.cap, 0);
        assertEq(parentConfig.collateralAddress, sec.rusd);
        assertEq(parentConfig.priceHaircut, 0);
        assertEq(parentConfig.oracleNodeId, sec.usdcUsdStorkNodeId);
        assertEq(cachedConfig.collateralPoolId, 1);
        assertEq(cachedConfig.collateralAddress, sec.usdc);
    }
}
