pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { IOrdersGatewayProxy } from "../../../src/interfaces/IOrdersGatewayProxy.sol";

/// @dev Verifies the ws-exec relayer is on the OrdersGateway execution allowlist.
/// `batchExecuteFill` (perp fill settlement) gates on the `conditional_orders`
/// feature flag via FeatureFlagSupport.ensureOrdersGatewayExecutionAccess; if the
/// submitting relayer isn't allowlisted, perp IOC reverts FeatureUnavailable (PRO-152).
contract WsExecAllowlistForkTest is ReyaForkTest {
    bytes32 internal constant CONDITIONAL_ORDERS_FLAG = keccak256("conditional_orders");
    // co_execution_bot1 — long-allowlisted on devnet; control to detect whether
    // this fork reflects the deployed/upgraded allowlist at all.
    address internal constant CO_EXECUTION_BOT_1 = 0xc9A01c03AEE926B89b83F7781b15B822807E1d33;
    // co_execution_bot2 — the live ws-exec relayer this PR points the allowlist at.
    address internal constant WS_EXEC_RELAYER = 0x6623C4a8e54549d5dB1ACb666B13f9c046DFD5B2;

    function test_Devnet_WsExecRelayer_OnExecutionAllowlist() public {
        IOrdersGatewayProxy og = IOrdersGatewayProxy(sec.ordersGateway);
        assertTrue(og.isFeatureAllowed(CONDITIONAL_ORDERS_FLAG, CO_EXECUTION_BOT_1), "control: bot1 allowlisted");
        assertTrue(og.isFeatureAllowed(CONDITIONAL_ORDERS_FLAG, WS_EXEC_RELAYER), "ws-exec relayer 0x6623 allowlisted");
    }
}
