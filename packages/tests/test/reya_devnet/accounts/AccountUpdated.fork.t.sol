pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { AccountUpdatedForkCheck } from "../../reya_common/accounts/AccountUpdated.fork.c.sol";

contract AccountUpdatedForkTest is ReyaForkTest, AccountUpdatedForkCheck {
    function test_Devnet_AccountUpdatedSequenceIncrements() public {
        check_AccountUpdatedSequenceIncrements();
    }
}
