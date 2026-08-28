pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { IPassivePerpProxyV2, MarketDataResponseV2 } from "../../../src/interfaces/IPassivePerpProxyV2.sol";

contract MarketCloseForkTest is ReyaForkTest {
    function setUp() public override { }

    function test_TerminalMarketsAreClosedAtApprovedForkBlock() public {
        if (!vm.envOr("REYA_REQUIRE_TERMINAL_MARKETS", false)) {
            vm.skip(true);
        }

        for (uint128 marketId = 3; marketId <= lastMarketId(); marketId++) {
            MarketDataResponseV2 memory data = IPassivePerpProxyV2(sec.perp).getMarketData(marketId);
            assertEq(data.marketData.openInterest, 0, "terminal market retains open interest");
            assertFalse(isMarketActive(marketId), "terminal market remains active");
        }
    }
}
