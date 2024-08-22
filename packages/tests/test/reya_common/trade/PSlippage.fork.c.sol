pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { ICoreProxy, MarginInfo, RiskMultipliers } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy } from "../../../src/interfaces/IOracleManagerProxy.sol";

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

    function check_trade_slippage_sol_long() public {
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
        sPrime[2] = sd(0.019985e18);
        sPrime[3] = sd(0.029935e18);
        sPrime[4] = sd(0.03983e18);
        sPrime[5] = sd(0.04965e18);
        sPrime[6] = sd(0.059377e18);
        sPrime[7] = sd(0.068993e18);
        sPrime[8] = sd(0.078482e18);
        sPrime[9] = sd(0.087829e18);

        trade_slippage_helper({ marketId: 3, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_arb_long() public {
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
        sPrime[2] = sd(0.019985e18);
        sPrime[3] = sd(0.029934e18);
        sPrime[4] = sd(0.039827e18);
        sPrime[5] = sd(0.049644e18);
        sPrime[6] = sd(0.059366e18);
        sPrime[7] = sd(0.068975e18);
        sPrime[8] = sd(0.078455e18);
        sPrime[9] = sd(0.087791e18);

        trade_slippage_helper({ marketId: 4, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_op_long() public {
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
        sPrime[2] = sd(0.01992e18);
        sPrime[3] = sd(0.029966e18);
        sPrime[4] = sd(0.03991e18);
        sPrime[5] = sd(0.049815e18);
        sPrime[6] = sd(0.059669e18);
        sPrime[7] = sd(0.069464e18);
        sPrime[8] = sd(0.079189e18);
        sPrime[9] = sd(0.088836e18);

        trade_slippage_helper({ marketId: 5, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_avax_long() public {
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
        sPrime[2] = sd(0.019985e18);
        sPrime[3] = sd(0.029934e18);
        sPrime[4] = sd(0.039828e18);
        sPrime[5] = sd(0.049645e18);
        sPrime[6] = sd(0.059368e18);
        sPrime[7] = sd(0.068979e18);
        sPrime[8] = sd(0.078461e18);
        sPrime[9] = sd(0.087799e18);

        trade_slippage_helper({ marketId: 6, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    // function check_trade_slippage_mkr_long() public {
    //     SD59x18[] memory s = new SD59x18[](10);
    //     s[1] = sd(0.01e18);
    //     s[2] = sd(0.02e18);
    //     s[3] = sd(0.03e18);
    //     s[4] = sd(0.04e18);
    //     s[5] = sd(0.05e18);
    //     s[6] = sd(0.06e18);
    //     s[7] = sd(0.07e18);
    //     s[8] = sd(0.08e18);
    //     s[9] = sd(0.09e18);
    //     // s[10] = sd(0.99e18);

    //     SD59x18[] memory sPrime = new SD59x18[](10);
    //     sPrime[1] = sd();
    //     sPrime[2] = sd();
    //     sPrime[3] = sd();
    //     sPrime[4] = sd();
    //     sPrime[5] = sd();
    //     sPrime[6] = sd();
    //     sPrime[7] = sd();
    //     sPrime[8] = sd();
    //     sPrime[9] = sd();

    //     trade_slippage_helper({ marketId: 7, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    // }

    // function check_trade_slippage_link_long() public {
    //     SD59x18[] memory s = new SD59x18[](10);
    //     s[1] = sd(0.01e18);
    //     s[2] = sd(0.02e18);
    //     s[3] = sd(0.03e18);
    //     s[4] = sd(0.04e18);
    //     s[5] = sd(0.05e18);
    //     s[6] = sd(0.06e18);
    //     s[7] = sd(0.07e18);
    //     s[8] = sd(0.08e18);
    //     s[9] = sd(0.09e18);
    //     // s[10] = sd(0.99e18);

    //     SD59x18[] memory sPrime = new SD59x18[](10);
    //     sPrime[1] = sd();
    //     sPrime[2] = sd();
    //     sPrime[3] = sd();
    //     sPrime[4] = sd();
    //     sPrime[5] = sd();
    //     sPrime[6] = sd();
    //     sPrime[7] = sd();
    //     sPrime[8] = sd();
    //     sPrime[9] = sd();

    //     trade_slippage_helper({ marketId: 8, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    // }

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

    function check_trade_slippage_sol_short() public {
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
        sPrime[2] = sd(-0.019986e18);
        sPrime[3] = sd(-0.029936e18);
        sPrime[4] = sd(-0.039831e18);
        sPrime[5] = sd(-0.049648e18);
        sPrime[6] = sd(-0.059369e18);
        sPrime[7] = sd(-0.068974e18);
        sPrime[8] = sd(-0.078444e18);
        sPrime[9] = sd(-0.087763e18);

        trade_slippage_helper({ marketId: 3, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_arb_short() public {
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
        sPrime[2] = sd(-0.019985e18);
        sPrime[3] = sd(-0.029935e18);
        sPrime[4] = sd(-0.039828e18);
        sPrime[5] = sd(-0.049642e18);
        sPrime[6] = sd(-0.059358e18);
        sPrime[7] = sd(-0.068956e18);
        sPrime[8] = sd(-0.078418e18);
        sPrime[9] = sd(-0.087724e18);

        trade_slippage_helper({ marketId: 4, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_op_short() public {
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
        sPrime[2] = sd(-0.01992e18);
        sPrime[3] = sd(-0.029966e18);
        sPrime[4] = sd(-0.03991e18);
        sPrime[5] = sd(-0.049814e18);
        sPrime[6] = sd(-0.059665e18);
        sPrime[7] = sd(-0.069454e18);
        sPrime[8] = sd(-0.079169e18);
        sPrime[9] = sd(-0.0888e18);

        trade_slippage_helper({ marketId: 5, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    function check_trade_slippage_avax_short() public {
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
        sPrime[2] = sd(-0.019985e18);
        sPrime[3] = sd(-0.029935e18);
        sPrime[4] = sd(-0.039828e18);
        sPrime[5] = sd(-0.049643e18);
        sPrime[6] = sd(-0.059361e18);
        sPrime[7] = sd(-0.06896e18);
        sPrime[8] = sd(-0.078423e18);
        sPrime[9] = sd(-0.087732e18);

        trade_slippage_helper({ marketId: 6, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    }

    // function check_trade_slippage_mkr_short() public {
    //     SD59x18[] memory s = new SD59x18[](10);
    //     s[1] = sd(-0.01e18);
    //     s[2] = sd(-0.02e18);
    //     s[3] = sd(-0.03e18);
    //     s[4] = sd(-0.04e18);
    //     s[5] = sd(-0.05e18);
    //     s[6] = sd(-0.06e18);
    //     s[7] = sd(-0.07e18);
    //     s[8] = sd(-0.08e18);
    //     s[9] = sd(-0.09e18);
    //     // s[10] = sd(0.99e18);

    //     SD59x18[] memory sPrime = new SD59x18[](10);
    //     sPrime[1] = sd();
    //     sPrime[2] = sd();
    //     sPrime[3] = sd();
    //     sPrime[4] = sd();
    //     sPrime[5] = sd();
    //     sPrime[6] = sd();
    //     sPrime[7] = sd();
    //     sPrime[8] = sd();
    //     sPrime[9] = sd();

    //     trade_slippage_helper({ marketId: 7, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    // }

    // function check_trade_slippage_link_short() public {
    //     SD59x18[] memory s = new SD59x18[](10);
    //     s[1] = sd(-0.01e18);
    //     s[2] = sd(-0.02e18);
    //     s[3] = sd(-0.03e18);
    //     s[4] = sd(-0.04e18);
    //     s[5] = sd(-0.05e18);
    //     s[6] = sd(-0.06e18);
    //     s[7] = sd(-0.07e18);
    //     s[8] = sd(-0.08e18);
    //     s[9] = sd(-0.09e18);
    //     // s[10] = sd(0.99e18);

    //     SD59x18[] memory sPrime = new SD59x18[](10);
    //     sPrime[1] = sd();
    //     sPrime[2] = sd();
    //     sPrime[3] = sd();
    //     sPrime[4] = sd();
    //     sPrime[5] = sd();
    //     sPrime[6] = sd();
    //     sPrime[7] = sd();
    //     sPrime[8] = sd();
    //     sPrime[9] = sd();

    //     trade_slippage_helper({ marketId: 8, s: s, sPrime: sPrime, eps: ud(0.007e18) });
    // }
}
