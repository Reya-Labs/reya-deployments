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

    function test_Devnet_OraclePushersFeatureFlagState() public view {
        check_OraclePushersFeatureFlagState();
    }

    function test_Devnet_MulticallFeatureFlagState() public view {
        check_MulticallFeatureFlagState();
    }

    /// @dev co_execution_bot2 — the live ws-exec relayer; must be on the
    /// conditional_orders allowlist or perp IOC reverts FeatureUnavailable (PRO-152).
    function test_Devnet_WsExecRelayerExecutionPermission() public view {
        check_ConditionalOrdersExecutionAllowlist(0x6623C4a8e54549d5dB1ACb666B13f9c046DFD5B2);
    }
}
