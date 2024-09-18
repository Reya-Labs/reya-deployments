pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { ICoreProxy, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    address user;
    MarketConfigurationData marketConfig;
    SD59x18 poolBase;
    uint256 passivePoolImMultiplier;
    int64[][] marketRiskMatrix;
    SD59x18 pSlippage;
}

contract PSlippageForkCheck is BaseReyaForkTest {
    LocalState private st;

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

        for (uint128 _marketId = 1; _marketId <= lastMarketId(); _marketId += 1) {
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
            SD59x18 base = exposureToBase(marketId, notional);
            base = base.sub(base.mod(sd(int256(st.marketConfig.baseSpacing))));

            (, st.pSlippage) = executeCoreMatchOrder({
                marketId: marketId,
                sender: st.user,
                base: base,
                priceLimit: getPriceLimit(base),
                accountId: accountId
            });

            assertApproxEqAbsDecimal(st.pSlippage.unwrap(), sPrime[i].unwrap(), eps.unwrap(), 18);

            prevNotionalsSum = prevNotionalsSum.add(baseToExposure(marketId, base));
        }
    }

    function check_trade_slippage_eth_long() public {
        mockFreshPrices();

        // less iterations due to max exposure being reached
        SD59x18[] memory s = new SD59x18[](6);
        s[1] = sd(0.01e18);
        s[2] = sd(0.02e18);
        s[3] = sd(0.03e18);
        s[4] = sd(0.04e18);
        s[5] = sd(0.05e18);
        // s[6] = sd(0.06e18);
        // s[7] = sd(0.07e18);
        // s[8] = sd(0.08e18);
        // s[9] = sd(0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](6);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.01959e18);
        sPrime[3] = sd(0.028271e18);
        sPrime[4] = sd(0.035776e18);
        sPrime[5] = sd(0.042024e18);
        // sPrime[6] = sd(0.047107e18);
        // sPrime[7] = sd(0.051191e18);
        // sPrime[8] = sd(0.054460e18);
        // sPrime[9] = sd(0.057082e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_btc_long() public {
        mockFreshPrices();

        // less iterations due to max exposure being reached
        SD59x18[] memory s = new SD59x18[](6);
        s[1] = sd(0.01e18);
        s[2] = sd(0.02e18);
        s[3] = sd(0.03e18);
        s[4] = sd(0.04e18);
        s[5] = sd(0.05e18);
        // s[6] = sd(0.06e18);
        // s[7] = sd(0.07e18);
        // s[8] = sd(0.08e18);
        // s[9] = sd(0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](6);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.01973e18);
        sPrime[3] = sd(0.028843e18);
        sPrime[4] = sd(0.037105e18);
        sPrime[5] = sd(0.044383e18);
        // sPrime[6] = sd(0.050660e18);
        // sPrime[7] = sd(0.055995e18);
        // sPrime[8] = sd(0.060492e18);
        // sPrime[9] = sd(0.064265e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_sol_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019996e18);
        sPrime[3] = sd(0.029984e18);
        sPrime[4] = sd(0.039958e18);
        sPrime[5] = sd(0.049914e18);
        sPrime[6] = sd(0.059846e18);
        sPrime[7] = sd(0.06975e18);
        sPrime[8] = sd(0.079622e18);
        sPrime[9] = sd(0.089456e18);

        trade_slippage_helper({ marketId: 3, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_arb_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019996e18);
        sPrime[3] = sd(0.029984e18);
        sPrime[4] = sd(0.039958e18);
        sPrime[5] = sd(0.049914e18);
        sPrime[6] = sd(0.059846e18);
        sPrime[7] = sd(0.06975e18);
        sPrime[8] = sd(0.079622e18);
        sPrime[9] = sd(0.089456e18);

        trade_slippage_helper({ marketId: 4, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_op_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019996e18);
        sPrime[3] = sd(0.029984e18);
        sPrime[4] = sd(0.039958e18);
        sPrime[5] = sd(0.049914e18);
        sPrime[6] = sd(0.059846e18);
        sPrime[7] = sd(0.06975e18);
        sPrime[8] = sd(0.079622e18);
        sPrime[9] = sd(0.089456e18);

        trade_slippage_helper({ marketId: 5, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_avax_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019996e18);
        sPrime[3] = sd(0.029984e18);
        sPrime[4] = sd(0.039958e18);
        sPrime[5] = sd(0.049914e18);
        sPrime[6] = sd(0.059846e18);
        sPrime[7] = sd(0.06975e18);
        sPrime[8] = sd(0.079622e18);
        sPrime[9] = sd(0.089456e18);

        trade_slippage_helper({ marketId: 6, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_mkr_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019998e18);
        sPrime[3] = sd(0.029992e18);
        sPrime[4] = sd(0.039978e18);
        sPrime[5] = sd(0.049955e18);
        sPrime[6] = sd(0.05992e18);
        sPrime[7] = sd(0.06987e18);
        sPrime[8] = sd(0.079802e18);
        sPrime[9] = sd(0.089715e18);

        trade_slippage_helper({ marketId: 7, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_link_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019998e18);
        sPrime[3] = sd(0.029992e18);
        sPrime[4] = sd(0.039978e18);
        sPrime[5] = sd(0.049955e18);
        sPrime[6] = sd(0.05992e18);
        sPrime[7] = sd(0.06987e18);
        sPrime[8] = sd(0.079802e18);
        sPrime[9] = sd(0.089715e18);

        trade_slippage_helper({ marketId: 8, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_aave_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019998e18);
        sPrime[3] = sd(0.029992e18);
        sPrime[4] = sd(0.039978e18);
        sPrime[5] = sd(0.049955e18);
        sPrime[6] = sd(0.05992e18);
        sPrime[7] = sd(0.06987e18);
        sPrime[8] = sd(0.079802e18);
        sPrime[9] = sd(0.089715e18);
        trade_slippage_helper({ marketId: 9, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_crv_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019998e18);
        sPrime[3] = sd(0.029992e18);
        sPrime[4] = sd(0.039978e18);
        sPrime[5] = sd(0.049955e18);
        sPrime[6] = sd(0.05992e18);
        sPrime[7] = sd(0.06987e18);
        sPrime[8] = sd(0.079802e18);
        sPrime[9] = sd(0.089715e18);

        trade_slippage_helper({ marketId: 10, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_uni_long() public {
        mockFreshPrices();

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
        sPrime[2] = sd(0.019999e18);
        sPrime[3] = sd(0.029994e18);
        sPrime[4] = sd(0.039984e18);
        sPrime[5] = sd(0.049967e18);
        sPrime[6] = sd(0.059942e18);
        sPrime[7] = sd(0.069905e18);
        sPrime[8] = sd(0.079856e18);
        sPrime[9] = sd(0.089793e18);

        trade_slippage_helper({ marketId: 11, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_eth_short() public {
        mockFreshPrices();

        // less iterations due to max exposure being reached
        SD59x18[] memory s = new SD59x18[](5);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        // s[5] = sd(-0.05e18);
        // s[6] = sd(-0.06e18);
        // s[7] = sd(-0.07e18);
        // s[8] = sd(-0.08e18);
        // s[9] = sd(-0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](5);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019598e18);
        sPrime[3] = sd(-0.028293e18);
        sPrime[4] = sd(-0.035783e18);
        // sPrime[5] = sd(-0.041992e18);
        // sPrime[6] = sd(-0.047006e18);
        // sPrime[7] = sd(-0.050997e18);
        // sPrime[8] = sd(-0.052813e18);
        // sPrime[9] = sd(-0.053079e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_btc_short() public {
        mockFreshPrices();

        // less iterations due to max exposure being reached
        SD59x18[] memory s = new SD59x18[](5);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        // s[5] = sd(-0.05e18);
        // s[6] = sd(-0.06e18);
        // s[7] = sd(-0.07e18);
        // s[8] = sd(-0.08e18);
        // s[9] = sd(-0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](5);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019736e18);
        sPrime[3] = sd(-0.028858e18);
        sPrime[4] = sd(-0.037111e18);
        // sPrime[5] = sd(-0.044358e18);
        // sPrime[6] = sd(-0.050576e18);
        // sPrime[7] = sd(-0.055823e18);
        // sPrime[8] = sd(-0.060203e18);
        // sPrime[9] = sd(-0.060314e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_sol_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019995e18);
        sPrime[3] = sd(-0.029978e18);
        sPrime[4] = sd(-0.039941e18);
        sPrime[5] = sd(-0.049877e18);
        sPrime[6] = sd(-0.059779e18);
        sPrime[7] = sd(-0.069639e18);
        sPrime[8] = sd(-0.079451e18);
        sPrime[9] = sd(-0.089206e18);

        trade_slippage_helper({ marketId: 3, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_arb_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019995e18);
        sPrime[3] = sd(-0.029978e18);
        sPrime[4] = sd(-0.039941e18);
        sPrime[5] = sd(-0.049877e18);
        sPrime[6] = sd(-0.059779e18);
        sPrime[7] = sd(-0.069639e18);
        sPrime[8] = sd(-0.079451e18);
        sPrime[9] = sd(-0.089206e18);

        trade_slippage_helper({ marketId: 4, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_op_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019995e18);
        sPrime[3] = sd(-0.029978e18);
        sPrime[4] = sd(-0.039941e18);
        sPrime[5] = sd(-0.049877e18);
        sPrime[6] = sd(-0.059779e18);
        sPrime[7] = sd(-0.069639e18);
        sPrime[8] = sd(-0.079451e18);
        sPrime[9] = sd(-0.089206e18);

        trade_slippage_helper({ marketId: 5, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_avax_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019995e18);
        sPrime[3] = sd(-0.029978e18);
        sPrime[4] = sd(-0.039941e18);
        sPrime[5] = sd(-0.049877e18);
        sPrime[6] = sd(-0.059779e18);
        sPrime[7] = sd(-0.069639e18);
        sPrime[8] = sd(-0.079451e18);
        sPrime[9] = sd(-0.089206e18);

        trade_slippage_helper({ marketId: 6, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_mkr_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019998e18);
        sPrime[3] = sd(-0.029992e18);
        sPrime[4] = sd(-0.039978e18);
        sPrime[5] = sd(-0.049955e18);
        sPrime[6] = sd(-0.059919e18);
        sPrime[7] = sd(-0.069867e18);
        sPrime[8] = sd(-0.079797e18);
        sPrime[9] = sd(-0.089706e18);

        trade_slippage_helper({ marketId: 7, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_link_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019998e18);
        sPrime[3] = sd(-0.029992e18);
        sPrime[4] = sd(-0.039978e18);
        sPrime[5] = sd(-0.049955e18);
        sPrime[6] = sd(-0.059919e18);
        sPrime[7] = sd(-0.069867e18);
        sPrime[8] = sd(-0.079797e18);
        sPrime[9] = sd(-0.089706e18);

        trade_slippage_helper({ marketId: 8, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_aave_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019998e18);
        sPrime[3] = sd(-0.029992e18);
        sPrime[4] = sd(-0.039978e18);
        sPrime[5] = sd(-0.049955e18);
        sPrime[6] = sd(-0.059919e18);
        sPrime[7] = sd(-0.069867e18);
        sPrime[8] = sd(-0.079797e18);
        sPrime[9] = sd(-0.089706e18);

        trade_slippage_helper({ marketId: 9, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_crv_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019998e18);
        sPrime[3] = sd(-0.029992e18);
        sPrime[4] = sd(-0.039978e18);
        sPrime[5] = sd(-0.049955e18);
        sPrime[6] = sd(-0.059919e18);
        sPrime[7] = sd(-0.069867e18);
        sPrime[8] = sd(-0.079797e18);
        sPrime[9] = sd(-0.089706e18);

        trade_slippage_helper({ marketId: 10, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }

    function check_trade_slippage_uni_short() public {
        mockFreshPrices();

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
        sPrime[2] = sd(-0.019998e18);
        sPrime[3] = sd(-0.029992e18);
        sPrime[4] = sd(-0.039978e18);
        sPrime[5] = sd(-0.049955e18);
        sPrime[6] = sd(-0.059919e18);
        sPrime[7] = sd(-0.069867e18);
        sPrime[8] = sd(-0.079797e18);
        sPrime[9] = sd(-0.089706e18);

        trade_slippage_helper({ marketId: 11, s: s, sPrime: sPrime, eps: ud(0.001e18) });
    }
}
