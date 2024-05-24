pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { ICoreProxy, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract PSlippageForkTest is ReyaForkTest {
    function trade_slippage_helper(
        uint128 marketId,
        SD59x18[] memory s,
        SD59x18[] memory sPrime,
        UD60x18 eps
    )
        internal
    {
        assertEq(s.length, sPrime.length);

        (user, userPk) = makeAddrAndKey("user");
        collateralPoolId = 1;
        exchangeId = 1; // passive pool

        // deposit new margin account
        uint256 depositAmount = 100_000_000e18;
        deal(usdc, address(periphery), depositAmount);
        mockBridgedAmount(socketExecutionHelper[usdc], depositAmount);
        vm.prank(socketExecutionHelper[usdc]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        for (uint128 _marketId = 1; _marketId <= 2; _marketId += 1) {
            marketConfig = IPassivePerpProxy(perp).getMarketConfiguration(_marketId);

            // Step 1: Unwind any exposure of the pool
            SD59x18 poolBase =
                SD59x18.wrap(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base);

            if (poolBase.abs().gt(sd(int256(marketConfig.minimumOrderBase)))) {
                SD59x18 base = poolBase.sub(poolBase.mod(sd(int256(marketConfig.baseSpacing))));
                executeCoreMatchOrder({
                    marketId: _marketId,
                    sender: user,
                    base: base,
                    priceLimit: getPriceLimit(base),
                    accountId: accountId
                });

                poolBase =
                    SD59x18.wrap(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base);

                // assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base, 0);
            }
        }

        passivePoolImMultiplier = ICoreProxy(core).getAccountImMultiplier(passivePoolAccountId);
        marketRiskMatrix = ICoreProxy(core).getRiskBlockMatrixByMarket(marketId);

        // increase max open base
        marketConfig = IPassivePerpProxy(perp).getMarketConfiguration(marketId);
        marketConfig.maxOpenBase = 100_000_000e18;
        vm.prank(multisig);
        IPassivePerpProxy(perp).setMarketConfiguration(marketId, marketConfig);

        // Step 2: Get pool's TVL
        MarginInfo memory poolMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(passivePoolAccountId);
        SD59x18 passivePoolTVL = sd(poolMarginInfo.marginBalance);

        // Step 3: Compute the grid
        SD59x18 prevNotionalsSum = sd(0);
        for (uint256 i = 1; i < s.length; i += 1) {
            SD59x18 notional = s[i].div(UNIT_sd.add(s[i])).mul(
                sd(int256(marketConfig.depthFactor)).mul(passivePoolTVL).div(
                    sd(int256(passivePoolImMultiplier)).mul(
                        sd(marketRiskMatrix[marketConfig.riskMatrixIndex][marketConfig.riskMatrixIndex]).sqrt()
                    )
                )
            ).sub(prevNotionalsSum);
            SD59x18 base = notionalToBase(marketId, notional);
            base = base.sub(base.mod(sd(int256(marketConfig.baseSpacing))));

            UD60x18 orderPrice;
            SD59x18 pSlippage;
            (orderPrice, pSlippage) = executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: base,
                priceLimit: getPriceLimit(base),
                accountId: accountId
            });

            assertApproxEqAbsDecimal(pSlippage.unwrap(), sPrime[i].unwrap(), eps.unwrap(), 18);

            prevNotionalsSum = prevNotionalsSum.add(baseToNotional(marketId, base));
        }
    }

    function test_trade_slippage_eth_long() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(0.01e18);
        s[2] = sd(0.02e18);
        s[3] = sd(0.03e18);
        s[4] = sd(0.04e18);
        s[5] = sd(0.05e18);
        s[6] = sd(0.06e18);
        s[7] = sd(0.07e18);
        s[8] = sd(0.08e18);
        s[9] = sd(0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019938e18);
        sPrime[3] = sd(0.029726e18);
        sPrime[4] = sd(0.039287e18);
        sPrime[5] = sd(0.04855e18);
        sPrime[6] = sd(0.057455e18);
        sPrime[7] = sd(0.065957e18);
        sPrime[8] = sd(0.074025e18);
        sPrime[9] = sd(0.081639e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.00005e18) });
    }

    function test_trade_slippage_btc_long() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(0.01e18);
        s[2] = sd(0.02e18);
        s[3] = sd(0.03e18);
        s[4] = sd(0.04e18);
        s[5] = sd(0.05e18);
        s[6] = sd(0.06e18);
        s[7] = sd(0.07e18);
        s[8] = sd(0.08e18);
        s[9] = sd(0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019938e18);
        sPrime[3] = sd(0.029726e18);
        sPrime[4] = sd(0.039287e18);
        sPrime[5] = sd(0.04855e18);
        sPrime[6] = sd(0.057455e18);
        sPrime[7] = sd(0.065957e18);
        sPrime[8] = sd(0.074025e18);
        sPrime[9] = sd(0.081639e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.0007e18) });
    }

    function test_trade_slippage_eth_short() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        s[5] = sd(-0.05e18);
        s[6] = sd(-0.06e18);
        s[7] = sd(-0.07e18);
        s[8] = sd(-0.08e18);
        s[9] = sd(-0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019939e18);
        sPrime[3] = sd(-0.029729e18);
        sPrime[4] = sd(-0.039289e18);
        sPrime[5] = sd(-0.048542e18);
        sPrime[6] = sd(-0.057426e18);
        sPrime[7] = sd(-0.065889e18);
        sPrime[8] = sd(-0.073894e18);
        sPrime[9] = sd(-0.081417e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.00005e18) });
    }

    function test_trade_slippage_btc_short() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        s[5] = sd(-0.05e18);
        s[6] = sd(-0.06e18);
        s[7] = sd(-0.07e18);
        s[8] = sd(-0.08e18);
        s[9] = sd(-0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019939e18);
        sPrime[3] = sd(-0.029729e18);
        sPrime[4] = sd(-0.039289e18);
        sPrime[5] = sd(-0.048542e18);
        sPrime[6] = sd(-0.057426e18);
        sPrime[7] = sd(-0.065889e18);
        sPrime[8] = sd(-0.073894e18);
        sPrime[9] = sd(-0.081417e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.0007e18) });
    }

    function test_trade_wethCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 1e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function test_trade_wethCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18; // denominated in weth
        uint128 marketId = 2; // btc
        exchangeId = 1; // passive pool
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }
}
