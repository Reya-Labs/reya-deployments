pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { AutoExchangeForkCheck } from "../../reya_common/collaterals/AutoExchange.fork.c.sol";

contract AutoExchangeForkTest is ReyaForkTest, AutoExchangeForkCheck {
    function test_AutoExchangeWeth_WhenUserHasOnlyWeth() public {
        check_AutoExchangeWeth_WhenUserHasOnlyWeth();
    }

    function test_AutoExchangeWeth_WhenUserHasBothWethAndRusd() public {
        check_AutoExchangeWeth_WhenUserHasBothWethAndRusd();
    }
}
