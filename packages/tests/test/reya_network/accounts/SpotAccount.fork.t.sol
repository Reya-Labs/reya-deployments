pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotAccountForkCheck } from "../../reya_common/accounts/SpotAccount.fork.c.sol";

contract SpotAccountForkTest is ReyaForkTest, SpotAccountForkCheck {
    function test_SpotAccount_Flows() public {
        check_SpotAccount_Flows();
    }

    function test_SpotAccount_CollateralLimits() public {
        check_SpotAccount_CollateralLimits();
    }

    function test_PerpTradingOnSpotAccount() public {
        check_PerpTradingOnSpotAccount();
    }
}
