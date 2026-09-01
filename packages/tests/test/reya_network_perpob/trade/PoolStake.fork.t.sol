pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PoolStakeForkCheck } from "../../reya_common/trade/PoolStake.fork.c.sol";
import { IPassivePerpProxyV2 } from "../../../src/interfaces/IPassivePerpProxyV2.sol";

contract PoolStakeForkTest is ReyaForkTest, PoolStakeForkCheck {
    function setUp() public override(ReyaForkTest, PoolStakeForkCheck) {
        ReyaForkTest.setUp();
        PoolStakeForkCheck.setUp();
    }

    function test_StakeUnstakeCommand() public {
        if (!_requireTerminalMarkets()) {
            try this.stakeUnstakeExternal() {
                revert("expected stale retired-market mark to fail closed");
            } catch (bytes memory revertData) {
                assertEq(bytes4(revertData), IPassivePerpProxyV2.MarkPriceStale.selector, "unexpected stake failure");
            }
            return;
        }
        check_StakeUnstakeCommand({ amount: 10e6, minShares: 9e30 });
    }

    function test_MoveLiquidity() public {
        if (!_requireTerminalMarkets()) {
            try this.moveLiquidityExternal() {
                revert("expected stale retired-market mark to fail closed");
            } catch (bytes memory revertData) {
                assertEq(
                    bytes4(revertData), IPassivePerpProxyV2.MarkPriceStale.selector, "unexpected move-liquidity failure"
                );
            }
            return;
        }
        check_MoveLiquidity(10e6, 9e30);
    }

    function stakeUnstakeExternal() external {
        check_StakeUnstakeCommand({ amount: 10e6, minShares: 9e30 });
    }

    function moveLiquidityExternal() external {
        check_MoveLiquidity(10e6, 9e30);
    }

    function _requireTerminalMarkets() internal view returns (bool) {
        // The pinned pre-RET-21 block still has OI in retired markets, so pool
        // valuation and stake operations correctly fail closed on their stale
        // marks. The scheduled terminal run flips this into the happy path.
        return vm.envOr("REYA_REQUIRE_TERMINAL_MARKETS", false);
    }
}
