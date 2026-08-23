pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { OracleAdapterForkCheck } from "../../reya_common/oracle_manager/OracleAdapter.fork.c.sol";

/// Mirrors the Cronos adapter check onto devnet's own adapters instance —
/// previously meaningless here because devnet borrowed Cronos's adapters.
contract OracleAdapterForkTest is ReyaForkTest, OracleAdapterForkCheck {
    function test_Devnet_fulfillOracleQuery_StorkOracleAdapter() public {
        check_fulfillOracleQuery_StorkOracleAdapter();
    }
}
