pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { OracleAdapterForkCheck } from "../../reya_common/oracle_manager/OracleAdapter.fork.c.sol";

contract OracleAdapterForkTest is ReyaForkTest, OracleAdapterForkCheck {
    function test_Cronos_fulfillOracleQuery_StorkOracleAdapter() public {
        check_fulfillOracleQuery_StorkOracleAdapter({ isExecutionRestricted: false });
    }
}
