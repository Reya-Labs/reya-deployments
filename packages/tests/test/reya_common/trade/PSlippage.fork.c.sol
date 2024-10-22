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

    function setUp() public {
        removeMarketsOILimit();
    }

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
        st.marketConfig.maxOpenBase = 100_000_000_000e18;
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
        sPrime[2] = sd(0.019764e18);
        sPrime[3] = sd(0.028981e18);
        sPrime[4] = sd(0.037436e18);
        sPrime[5] = sd(0.044991e18);
        // sPrime[6] = sd(0.051607e18);
        // sPrime[7] = sd(0.057320e18);
        // sPrime[8] = sd(0.062206e18);
        // sPrime[9] = sd(0.066363e18);

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

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019957e18);
        sPrime[3] = sd(0.029811e18);
        sPrime[4] = sd(0.039508e18);
        sPrime[5] = sd(0.048993e18);
        sPrime[6] = sd(0.058223e18);
        sPrime[7] = sd(0.067157e18);
        sPrime[8] = sd(0.075766e18);
        sPrime[9] = sd(0.084026e18);

        trade_slippage_helper({ marketId: 3, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019957e18);
        sPrime[3] = sd(0.029811e18);
        sPrime[4] = sd(0.039508e18);
        sPrime[5] = sd(0.048993e18);
        sPrime[6] = sd(0.058223e18);
        sPrime[7] = sd(0.067157e18);
        sPrime[8] = sd(0.075766e18);
        sPrime[9] = sd(0.084026e18);

        trade_slippage_helper({ marketId: 4, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019957e18);
        sPrime[3] = sd(0.029811e18);
        sPrime[4] = sd(0.039508e18);
        sPrime[5] = sd(0.048993e18);
        sPrime[6] = sd(0.058223e18);
        sPrime[7] = sd(0.067157e18);
        sPrime[8] = sd(0.075766e18);
        sPrime[9] = sd(0.084026e18);

        trade_slippage_helper({ marketId: 5, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019957e18);
        sPrime[3] = sd(0.029811e18);
        sPrime[4] = sd(0.039508e18);
        sPrime[5] = sd(0.048993e18);
        sPrime[6] = sd(0.058223e18);
        sPrime[7] = sd(0.067157e18);
        sPrime[8] = sd(0.075766e18);
        sPrime[9] = sd(0.084026e18);

        trade_slippage_helper({ marketId: 6, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019978e18);
        sPrime[3] = sd(0.029901e18);
        sPrime[4] = sd(0.039742e18);
        sPrime[5] = sd(0.049469e18);
        sPrime[6] = sd(0.059056e18);
        sPrime[7] = sd(0.068479e18);
        sPrime[8] = sd(0.077715e18);
        sPrime[9] = sd(0.086744e18);

        trade_slippage_helper({ marketId: 7, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019978e18);
        sPrime[3] = sd(0.029901e18);
        sPrime[4] = sd(0.039742e18);
        sPrime[5] = sd(0.049469e18);
        sPrime[6] = sd(0.059056e18);
        sPrime[7] = sd(0.068479e18);
        sPrime[8] = sd(0.077715e18);
        sPrime[9] = sd(0.086744e18);

        trade_slippage_helper({ marketId: 8, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019978e18);
        sPrime[3] = sd(0.029901e18);
        sPrime[4] = sd(0.039742e18);
        sPrime[5] = sd(0.049469e18);
        sPrime[6] = sd(0.059056e18);
        sPrime[7] = sd(0.068479e18);
        sPrime[8] = sd(0.077715e18);
        sPrime[9] = sd(0.086744e18);

        trade_slippage_helper({ marketId: 9, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019978e18);
        sPrime[3] = sd(0.029901e18);
        sPrime[4] = sd(0.039742e18);
        sPrime[5] = sd(0.049469e18);
        sPrime[6] = sd(0.059056e18);
        sPrime[7] = sd(0.068479e18);
        sPrime[8] = sd(0.077715e18);
        sPrime[9] = sd(0.086744e18);

        trade_slippage_helper({ marketId: 10, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(0.019982e18);
        sPrime[3] = sd(0.029921e18);
        sPrime[4] = sd(0.039793e18);
        sPrime[5] = sd(0.049574e18);
        sPrime[6] = sd(0.059241e18);
        sPrime[7] = sd(0.068775e18);
        sPrime[8] = sd(0.078157e18);
        sPrime[9] = sd(0.087368e18);

        trade_slippage_helper({ marketId: 11, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_sui_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019999e18);
        sPrime[3] = sd(0.029995e18);
        sPrime[4] = sd(0.039987e18);
        sPrime[5] = sd(0.049973e18);
        sPrime[6] = sd(0.059952e18);
        sPrime[7] = sd(0.069922e18);
        sPrime[8] = sd(0.079881e18);
        sPrime[9] = sd(0.089829e18);

        trade_slippage_helper({ marketId: 12, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_tia_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019999e18);
        sPrime[3] = sd(0.029997e18);
        sPrime[4] = sd(0.039991e18);
        sPrime[5] = sd(0.049982e18);
        sPrime[6] = sd(0.059968e18);
        sPrime[7] = sd(0.069948e18);
        sPrime[8] = sd(0.079921e18);
        sPrime[9] = sd(0.089886e18);

        trade_slippage_helper({ marketId: 13, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_sei_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019999e18);
        sPrime[3] = sd(0.029995e18);
        sPrime[4] = sd(0.039987e18);
        sPrime[5] = sd(0.049973e18);
        sPrime[6] = sd(0.059952e18);
        sPrime[7] = sd(0.069922e18);
        sPrime[8] = sd(0.079881e18);
        sPrime[9] = sd(0.089829e18);

        trade_slippage_helper({ marketId: 14, s: s, sPrime: sPrime, eps: ud(0.004e18) });
    }

    function check_trade_slippage_zro_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019999e18);
        sPrime[3] = sd(0.029997e18);
        sPrime[4] = sd(0.039991e18);
        sPrime[5] = sd(0.049982e18);
        sPrime[6] = sd(0.059968e18);
        sPrime[7] = sd(0.069948e18);
        sPrime[8] = sd(0.079921e18);
        sPrime[9] = sd(0.089886e18);

        trade_slippage_helper({ marketId: 15, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_xrp_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019998e18);
        sPrime[3] = sd(0.02999e18);
        sPrime[4] = sd(0.039974e18);
        sPrime[5] = sd(0.049946e18);
        sPrime[6] = sd(0.059904e18);
        sPrime[7] = sd(0.069844e18);
        sPrime[8] = sd(0.079763e18);
        sPrime[9] = sd(0.089659e18);

        trade_slippage_helper({ marketId: 16, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_wif_long() public {
        mockFreshPrices();

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

        SD59x18[] memory sPrime = new SD59x18[](6);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019942e18);
        sPrime[3] = sd(0.029745e18);
        sPrime[4] = sd(0.039337e18);
        sPrime[5] = sd(0.04865e18);
        // sPrime[6] = sd(0.057627e18);
        // sPrime[7] = sd(0.066226e18);
        // sPrime[8] = sd(0.074412e18);
        // sPrime[9] = sd(0.082166e18);

        trade_slippage_helper({ marketId: 17, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_pepe1k_long() public {
        mockFreshPrices();

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

        SD59x18[] memory sPrime = new SD59x18[](6);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019942e18);
        sPrime[3] = sd(0.029745e18);
        sPrime[4] = sd(0.039337e18);
        sPrime[5] = sd(0.04865e18);
        // sPrime[6] = sd(0.057627e18);
        // sPrime[7] = sd(0.066226e18);
        // sPrime[8] = sd(0.074412e18);
        // sPrime[9] = sd(0.082166e18);

        trade_slippage_helper({ marketId: 18, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_popcat_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019942e18);
        sPrime[3] = sd(0.029745e18);
        sPrime[4] = sd(0.039337e18);
        sPrime[5] = sd(0.04865e18);
        sPrime[6] = sd(0.057627e18);
        sPrime[7] = sd(0.066226e18);
        sPrime[8] = sd(0.074412e18);
        sPrime[9] = sd(0.082166e18);

        trade_slippage_helper({ marketId: 19, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_doge_long() public {
        mockFreshPrices();

        SD59x18[] memory s = new SD59x18[](5);
        s[1] = sd(0.01e18);
        s[2] = sd(0.02e18);
        s[3] = sd(0.03e18);
        s[4] = sd(0.04e18);
        // s[5] = sd(0.05e18);
        // s[6] = sd(0.06e18);
        // s[7] = sd(0.07e18);
        // s[8] = sd(0.08e18);
        // s[9] = sd(0.09e18);

        SD59x18[] memory sPrime = new SD59x18[](5);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019869e18);
        sPrime[3] = sd(0.029431e18);
        sPrime[4] = sd(0.038543e18);
        // sPrime[5] = sd(0.047088e18);
        // sPrime[6] = sd(0.054992e18);
        // sPrime[7] = sd(0.062219e18);
        // sPrime[8] = sd(0.068766e18);
        // sPrime[9] = sd(0.074656e18);

        trade_slippage_helper({ marketId: 20, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_kshib_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019942e18);
        sPrime[3] = sd(0.029745e18);
        sPrime[4] = sd(0.039337e18);
        sPrime[5] = sd(0.04865e18);
        sPrime[6] = sd(0.057627e18);
        sPrime[7] = sd(0.066226e18);
        sPrime[8] = sd(0.074412e18);
        sPrime[9] = sd(0.082166e18);

        trade_slippage_helper({ marketId: 21, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_kbonk_long() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019942e18);
        sPrime[3] = sd(0.029745e18);
        sPrime[4] = sd(0.039337e18);
        sPrime[5] = sd(0.04865e18);
        sPrime[6] = sd(0.057627e18);
        sPrime[7] = sd(0.066226e18);
        sPrime[8] = sd(0.074412e18);
        sPrime[9] = sd(0.082166e18);

        trade_slippage_helper({ marketId: 22, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019768e18);
        sPrime[3] = sd(-0.028994e18);
        sPrime[4] = sd(-0.037441e18);
        // sPrime[5] = sd(-0.044968e18);
        // sPrime[6] = sd(-0.051529e18);
        // sPrime[7] = sd(-0.057156e18);
        // sPrime[8] = sd(-0.061928e18);
        // sPrime[9] = sd(-0.062575e18);

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

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019958e18);
        sPrime[3] = sd(-0.029814e18);
        sPrime[4] = sd(-0.039509e18);
        sPrime[5] = sd(-0.048988e18);
        sPrime[6] = sd(-0.058202e18);
        sPrime[7] = sd(-0.067108e18);
        sPrime[8] = sd(-0.075669e18);
        sPrime[9] = sd(-0.083208e18);

        trade_slippage_helper({ marketId: 3, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019958e18);
        sPrime[3] = sd(-0.029814e18);
        sPrime[4] = sd(-0.039509e18);
        sPrime[5] = sd(-0.048988e18);
        sPrime[6] = sd(-0.058202e18);
        sPrime[7] = sd(-0.067108e18);
        sPrime[8] = sd(-0.075669e18);
        sPrime[9] = sd(-0.083208e18);

        trade_slippage_helper({ marketId: 4, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019958e18);
        sPrime[3] = sd(-0.029814e18);
        sPrime[4] = sd(-0.039509e18);
        sPrime[5] = sd(-0.048988e18);
        sPrime[6] = sd(-0.058202e18);
        sPrime[7] = sd(-0.067108e18);
        sPrime[8] = sd(-0.075669e18);
        sPrime[9] = sd(-0.083208e18);

        trade_slippage_helper({ marketId: 5, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019958e18);
        sPrime[3] = sd(-0.029814e18);
        sPrime[4] = sd(-0.039509e18);
        sPrime[5] = sd(-0.048988e18);
        sPrime[6] = sd(-0.058202e18);
        sPrime[7] = sd(-0.067108e18);
        sPrime[8] = sd(-0.075669e18);
        sPrime[9] = sd(-0.083208e18);

        trade_slippage_helper({ marketId: 6, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019978e18);
        sPrime[3] = sd(-0.029901e18);
        sPrime[4] = sd(-0.039742e18);
        sPrime[5] = sd(-0.049469e18);
        sPrime[6] = sd(-0.059056e18);
        sPrime[7] = sd(-0.068479e18);
        sPrime[8] = sd(-0.077715e18);
        sPrime[9] = sd(-0.086744e18);

        trade_slippage_helper({ marketId: 7, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019978e18);
        sPrime[3] = sd(-0.029901e18);
        sPrime[4] = sd(-0.039742e18);
        sPrime[5] = sd(-0.049469e18);
        sPrime[6] = sd(-0.059056e18);
        sPrime[7] = sd(-0.068479e18);
        sPrime[8] = sd(-0.077715e18);
        sPrime[9] = sd(-0.086744e18);

        trade_slippage_helper({ marketId: 8, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019978e18);
        sPrime[3] = sd(-0.029901e18);
        sPrime[4] = sd(-0.039742e18);
        sPrime[5] = sd(-0.049469e18);
        sPrime[6] = sd(-0.059056e18);
        sPrime[7] = sd(-0.068479e18);
        sPrime[8] = sd(-0.077715e18);
        sPrime[9] = sd(-0.086744e18);

        trade_slippage_helper({ marketId: 9, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019978e18);
        sPrime[3] = sd(-0.029901e18);
        sPrime[4] = sd(-0.039742e18);
        sPrime[5] = sd(-0.049469e18);
        sPrime[6] = sd(-0.059056e18);
        sPrime[7] = sd(-0.068479e18);
        sPrime[8] = sd(-0.077715e18);
        sPrime[9] = sd(-0.086744e18);

        trade_slippage_helper({ marketId: 10, s: s, sPrime: sPrime, eps: ud(0.002e18) });
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
        sPrime[2] = sd(-0.019982e18);
        sPrime[3] = sd(-0.029921e18);
        sPrime[4] = sd(-0.039793e18);
        sPrime[5] = sd(-0.049574e18);
        sPrime[6] = sd(-0.059241e18);
        sPrime[7] = sd(-0.068775e18);
        sPrime[8] = sd(-0.078157e18);
        sPrime[9] = sd(-0.087368e18);

        trade_slippage_helper({ marketId: 11, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_sui_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019999e18);
        sPrime[3] = sd(-0.029995e18);
        sPrime[4] = sd(-0.039987e18);
        sPrime[5] = sd(-0.049973e18);
        sPrime[6] = sd(-0.059951e18);
        sPrime[7] = sd(-0.06992e18);
        sPrime[8] = sd(-0.079878e18);
        sPrime[9] = sd(-0.089824e18);

        trade_slippage_helper({ marketId: 12, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_tia_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019999e18);
        sPrime[3] = sd(-0.029997e18);
        sPrime[4] = sd(-0.039991e18);
        sPrime[5] = sd(-0.049982e18);
        sPrime[6] = sd(-0.059967e18);
        sPrime[7] = sd(-0.069947e18);
        sPrime[8] = sd(-0.079919e18);
        sPrime[9] = sd(-0.089882e18);

        trade_slippage_helper({ marketId: 13, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_sei_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019999e18);
        sPrime[3] = sd(-0.029995e18);
        sPrime[4] = sd(-0.039987e18);
        sPrime[5] = sd(-0.049973e18);
        sPrime[6] = sd(-0.059951e18);
        sPrime[7] = sd(-0.06992e18);
        sPrime[8] = sd(-0.079878e18);
        sPrime[9] = sd(-0.089824e18);

        trade_slippage_helper({ marketId: 14, s: s, sPrime: sPrime, eps: ud(0.004e18) });
    }

    function check_trade_slippage_zro_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019999e18);
        sPrime[3] = sd(-0.029997e18);
        sPrime[4] = sd(-0.039991e18);
        sPrime[5] = sd(-0.049982e18);
        sPrime[6] = sd(-0.059967e18);
        sPrime[7] = sd(-0.069947e18);
        sPrime[8] = sd(-0.079919e18);
        sPrime[9] = sd(-0.089882e18);

        trade_slippage_helper({ marketId: 15, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_xrp_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019998e18);
        sPrime[3] = sd(-0.02999e18);
        sPrime[4] = sd(-0.039974e18);
        sPrime[5] = sd(-0.049946e18);
        sPrime[6] = sd(-0.059903e18);
        sPrime[7] = sd(-0.069841e18);
        sPrime[8] = sd(-0.079757e18);
        sPrime[9] = sd(-0.089648e18);

        trade_slippage_helper({ marketId: 16, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_wif_short() public {
        mockFreshPrices();

        SD59x18[] memory s = new SD59x18[](6);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        s[5] = sd(-0.05e18);
        // s[6] = sd(-0.06e18);
        // s[7] = sd(-0.07e18);
        // s[8] = sd(-0.08e18);
        // s[9] = sd(-0.09e18);

        SD59x18[] memory sPrime = new SD59x18[](6);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019943e18);
        sPrime[3] = sd(-0.029749e18);
        sPrime[4] = sd(-0.039338e18);
        sPrime[5] = sd(-0.048643e18);
        // sPrime[6] = sd(-0.0576e18);
        // sPrime[7] = sd(-0.066161e18);
        // sPrime[8] = sd(-0.074289e18);
        // sPrime[9] = sd(-0.080878e18);

        trade_slippage_helper({ marketId: 17, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_pepe1k_short() public {
        mockFreshPrices();

        SD59x18[] memory s = new SD59x18[](6);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        s[5] = sd(-0.05e18);
        // s[6] = sd(-0.06e18);
        // s[7] = sd(-0.07e18);
        // s[8] = sd(-0.08e18);
        // s[9] = sd(-0.09e18);

        SD59x18[] memory sPrime = new SD59x18[](6);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019943e18);
        sPrime[3] = sd(-0.029749e18);
        sPrime[4] = sd(-0.039338e18);
        sPrime[5] = sd(-0.048643e18);
        // sPrime[6] = sd(-0.0576e18);
        // sPrime[7] = sd(-0.066161e18);
        // sPrime[8] = sd(-0.074289e18);
        // sPrime[9] = sd(-0.080878e18);

        trade_slippage_helper({ marketId: 18, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_popcat_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019943e18);
        sPrime[3] = sd(-0.029749e18);
        sPrime[4] = sd(-0.039338e18);
        sPrime[5] = sd(-0.048643e18);
        sPrime[6] = sd(-0.0576e18);
        sPrime[7] = sd(-0.066161e18);
        sPrime[8] = sd(-0.074289e18);
        sPrime[9] = sd(-0.080878e18);

        trade_slippage_helper({ marketId: 19, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_doge_short() public {
        mockFreshPrices();

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

        SD59x18[] memory sPrime = new SD59x18[](5);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019872e18);
        sPrime[3] = sd(-0.029438e18);
        sPrime[4] = sd(-0.038544e18);
        // sPrime[5] = sd(-0.047068e18);
        // sPrime[6] = sd(-0.05493e18);
        // sPrime[7] = sd(-0.062088e18);
        // sPrime[8] = sd(-0.068536e18);
        // sPrime[9] = sd(-0.071852e18);

        trade_slippage_helper({ marketId: 20, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_kshib_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019943e18);
        sPrime[3] = sd(-0.029749e18);
        sPrime[4] = sd(-0.039338e18);
        sPrime[5] = sd(-0.048643e18);
        sPrime[6] = sd(-0.0576e18);
        sPrime[7] = sd(-0.066161e18);
        sPrime[8] = sd(-0.074289e18);
        sPrime[9] = sd(-0.080878e18);

        trade_slippage_helper({ marketId: 21, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }

    function check_trade_slippage_kbonk_short() public {
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

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019943e18);
        sPrime[3] = sd(-0.029749e18);
        sPrime[4] = sd(-0.039338e18);
        sPrime[5] = sd(-0.048643e18);
        sPrime[6] = sd(-0.0576e18);
        sPrime[7] = sd(-0.066161e18);
        sPrime[8] = sd(-0.074289e18);
        sPrime[9] = sd(-0.080878e18);

        trade_slippage_helper({ marketId: 22, s: s, sPrime: sPrime, eps: ud(0.002e18) });
    }
}
