pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LeveragePerpOBForkCheck } from "../../reya_common/trade/LeveragePerpOB.fork.c.sol";

contract LeverageForkTest is ReyaForkTest, LeveragePerpOBForkCheck {
    function setUp() public override { }

    function test_RusdCollateralLeverage_ETH() public {
        check_trade_leverage_perpOB(1, 25e18, 3000e18, sec.rusd);
    }

    function test_RusdCollateralLeverage_BTC() public {
        check_trade_leverage_perpOB(2, 40e18, 100_000e18, sec.rusd);
    }

    function test_WethCollateralLeverage_ETH() public {
        check_trade_leverage_perpOB(1, 25e18, 3000e18, sec.weth);
    }
}
