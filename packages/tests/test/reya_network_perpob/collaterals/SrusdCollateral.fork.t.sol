pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SrusdCollateralForkCheck } from "../../reya_common/collaterals/SrusdCollateral.fork.c.sol";
import { ICoreProxy, CollateralConfig } from "../../../src/interfaces/ICoreProxy.sol";

contract SrusdCollateralForkTest is ReyaForkTest, SrusdCollateralForkCheck {
    function testFuzz_SRUSDMintBurn(address attacker) public {
        vm.assume(attacker != sec.pool);
        checkFuzz_SRUSDMintBurn(attacker);
    }

    function test_srusd_view_functions() public {
        check_srusd_view_functions();
    }

    function test_srusd_cap_exceeded() public {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(1, 3000e18);
        pushFundingRate(1, 0);

        (CollateralConfig memory config,,) = ICoreProxy(sec.core).getCollateralConfig(1, sec.srusd);
        uint256 poolBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.srusd);
        uint256 amount = poolBalance >= config.cap ? 1 : config.cap - poolBalance + 1;
        assertGt(poolBalance + amount, config.cap, "fixture must exceed the configured sRUSD cap");

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.srusd, amount);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector, 1, sec.srusd, config.cap, poolBalance + amount
            )
        );
        this.executePerpFillExternal(buyerAccountId, sellerAccountId, 1, 0.1e18, 3000e18, 1, 1, 1);
    }

    function test_srusd_deposit_withdraw() public {
        check_srusd_deposit_withdraw();
    }

    function test_srusd_transfer() public {
        check_transfer_srusdCollateral();
    }
}
