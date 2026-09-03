pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PassivePoolForkCheck } from "../../reya_common/trade/PassivePool.fork.c.sol";

contract PassivePoolForkTest is ReyaForkTest, PassivePoolForkCheck {
    function setUp() public override(ReyaForkTest, PassivePoolForkCheck) {
        PassivePoolForkCheck.setUp();
        ReyaForkTest.setUp();
    }

    function test_DepositAndWithdrawalFeatureFlags_NotWhitelisted() public {
        check_DepositAndWithdrawalFeatureFlags(makeAddr("randomUser"), false);
    }

    function test_PassivePoolAutoRebalance_RevertWhenSenderIsNotRebalancer() public {
        check_autoRebalance_revertWhenSenderIsNotRebalancer();

        if (vm.envOr("REYA_REQUIRE_TERMINAL_MARKETS", false)) {
            // SYNTHETIC REHEARSAL branch at the pinned pre-RET-21 block. Once the disposable fork has been made
            // terminal, fresh ETH/BTC marks unlock the pool valuation paths which correctly fail closed otherwise.
            mockFreshPrices();
            mockFreshCollateralPrices();
            checkPoolHealth();
            checkFuzz_PoolDepositWithdraw(
                makeAddr("terminalPoolDepositor"), makeAddr("terminalPoolWithdrawalAttacker"), 10e6, 0
            );
            // PerpOB deliberately does not compose the legacy passive-perp pricing selectors, including
            // getPoolMaxExposures. Exercise the rebalance itself and its token/share-price invariants instead.
            autoRebalancePool(sec.rselini, sec.rusd, true, false);
            checkPoolHealth();
        }
    }
}
