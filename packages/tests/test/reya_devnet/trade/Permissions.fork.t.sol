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

    /// @dev co_execution_bot3 — the Rust wallet-manager relayer; must be on the
    /// conditional_orders allowlist or its batchExecuteFill reverts FeatureUnavailable.
    function test_Devnet_WalletManagerRelayerExecutionPermission() public view {
        check_ConditionalOrdersExecutionAllowlist(0xB04ce54876A8017ae7785A3f4218308BC8fBb724);
    }

    /// @dev co_execution_bot4 — additional ws-exec relayer (pod ordinal 1) for the
    /// 4-replica scale (P16 launch-gate); must be on the conditional_orders allowlist.
    function test_Devnet_WsExecRelayer4ExecutionPermission() public view {
        check_ConditionalOrdersExecutionAllowlist(0xCD08Ed0e34C45D0d6a21919582AF0495385Fd37b);
    }

    /// @dev co_execution_bot5 — additional ws-exec relayer (pod ordinal 2).
    function test_Devnet_WsExecRelayer5ExecutionPermission() public view {
        check_ConditionalOrdersExecutionAllowlist(0xfBF7e64C435bE05a0Dac2ac69fB61D0a18832053);
    }

    /// @dev co_execution_bot6 — additional ws-exec relayer (pod ordinal 3).
    function test_Devnet_WsExecRelayer6ExecutionPermission() public view {
        check_ConditionalOrdersExecutionAllowlist(0x5683356F9Bb41261412c0b78231d93f7a48B7f8C);
    }
}
