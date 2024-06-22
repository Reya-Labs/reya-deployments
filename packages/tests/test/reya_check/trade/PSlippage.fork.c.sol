pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { ICoreProxy, MarginInfo, RiskMultipliers } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct State {
    address user;
    MarketConfigurationData marketConfig;
    SD59x18 poolBase;
    uint256 passivePoolImMultiplier;
    int64[][] marketRiskMatrix;
    SD59x18 pSlippage;
}

contract PSlippageForkCheck is BaseReyaForkTest {
    State private st;

    function trade_slippage_helper(
        uint128 marketId,
        SD59x18[] memory s,
        SD59x18[] memory sPrime,
        UD60x18 eps
    )
        internal
    {
        assertEq(s.length, sPrime.length);

        (st.user,) = makeAddrAndKey("user");

        // deposit new margin account
        uint256 depositAmount = 100_000_000e18;
        deal(sec.usdc, address(sec.periphery), depositAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], depositAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: st.user, token: address(sec.usdc) })
        );

        for (uint128 _marketId = 1; _marketId <= 2; _marketId += 1) {
            st.marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(_marketId);

            // Step 1: Unwind any exposure of the pool
            st.poolBase = SD59x18.wrap(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(_marketId, sec.passivePoolAccountId).base
            );

            if (st.poolBase.abs().gt(sd(int256(st.marketConfig.minimumOrderBase)))) {
                SD59x18 base = st.poolBase.sub(st.poolBase.mod(sd(int256(st.marketConfig.baseSpacing))));
                executeCoreMatchOrder({
                    marketId: _marketId,
                    sender: st.user,
                    base: base,
                    priceLimit: getPriceLimit(base),
                    accountId: accountId
                });

                st.poolBase = SD59x18.wrap(
                    IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(_marketId, sec.passivePoolAccountId).base
                );

                // assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base, 0);
            }
        }

        st.passivePoolImMultiplier = ICoreProxy(sec.core).getAccountImMultiplier(sec.passivePoolAccountId);
        st.marketRiskMatrix = ICoreProxy(sec.core).getRiskBlockMatrixByMarket(marketId);

        // increase max open base
        st.marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        st.marketConfig.maxOpenBase = 100_000_000e18;
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setMarketConfiguration(marketId, st.marketConfig);

        // Step 2: Get pool's TVL
        MarginInfo memory poolMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(sec.passivePoolAccountId);
        SD59x18 passivePoolTVL = sd(poolMarginInfo.marginBalance);

        // Step 3: Compute the grid
        SD59x18 prevNotionalsSum = sd(0);
        for (uint256 i = 1; i < s.length; i += 1) {
            SD59x18 notional = s[i].div(UNIT_sd.add(s[i])).mul(
                sd(int256(st.marketConfig.depthFactor)).mul(passivePoolTVL).div(
                    sd(int256(st.passivePoolImMultiplier)).mul(
                        sd(st.marketRiskMatrix[st.marketConfig.riskMatrixIndex][st.marketConfig.riskMatrixIndex]).sqrt()
                    )
                )
            ).sub(prevNotionalsSum);
            SD59x18 base = notionalToBase(marketId, notional);
            base = base.sub(base.mod(sd(int256(st.marketConfig.baseSpacing))));

            (, st.pSlippage) = executeCoreMatchOrder({
                marketId: marketId,
                sender: st.user,
                base: base,
                priceLimit: getPriceLimit(base),
                accountId: accountId
            });

            assertApproxEqAbsDecimal(st.pSlippage.unwrap(), sPrime[i].unwrap(), eps.unwrap(), 18);

            prevNotionalsSum = prevNotionalsSum.add(baseToNotional(marketId, base));
        }
    }

    function check_trade_slippage_eth_long() public {
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
        sPrime[2] = sd(0.01998e18);
        sPrime[3] = sd(0.02991e18);
        sPrime[4] = sd(0.039765e18);
        sPrime[5] = sd(0.049516e18);
        sPrime[6] = sd(0.059139e18);
        sPrime[7] = sd(0.068611e18);
        sPrime[8] = sd(0.077912e18);
        sPrime[9] = sd(0.087022e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_btc_long() public {
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
        sPrime[2] = sd(0.01998e18);
        sPrime[3] = sd(0.02991e18);
        sPrime[4] = sd(0.039765e18);
        sPrime[5] = sd(0.049516e18);
        sPrime[6] = sd(0.059139e18);
        sPrime[7] = sd(0.068611e18);
        sPrime[8] = sd(0.077912e18);
        sPrime[9] = sd(0.087022e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_eth_short() public {
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
        sPrime[2] = sd(-0.01998e18);
        sPrime[3] = sd(-0.029911e18);
        sPrime[4] = sd(-0.039765e18);
        sPrime[5] = sd(-0.049513e18);
        sPrime[6] = sd(-0.059129e18);
        sPrime[7] = sd(-0.068586e18);
        sPrime[8] = sd(-0.077862e18);
        sPrime[9] = sd(-0.086933e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_btc_short() public {
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
        sPrime[2] = sd(-0.01998e18);
        sPrime[3] = sd(-0.029911e18);
        sPrime[4] = sd(-0.039765e18);
        sPrime[5] = sd(-0.049513e18);
        sPrime[6] = sd(-0.059129e18);
        sPrime[7] = sd(-0.068586e18);
        sPrime[8] = sd(-0.077862e18);
        sPrime[9] = sd(-0.086933e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_wethCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18; // denominated in weth
        uint128 marketId = 2; // btc
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }
}
