pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PermissionsPerpOBForkCheck } from "../../reya_common/trade/PermissionsPerpOB.fork.c.sol";

contract PermissionsForkTest is ReyaForkTest, PermissionsPerpOBForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    function test_Devnet_OraclePusherPermission_ETH() public {
        check_OraclePusherPermission(ETH_MARKET_ID);
    }

    function test_Devnet_AuthorizedOraclePusher_ETH() public {
        check_AuthorizedOraclePusher(ETH_MARKET_ID);
    }

    function test_Devnet_MatchingEnginePermission_ETH() public {
        check_MatchingEnginePermission(ETH_MARKET_ID);
    }

    function test_Devnet_RevokeOraclePusher_ETH() public {
        check_RevokeOraclePusher(ETH_MARKET_ID);
    }
}
