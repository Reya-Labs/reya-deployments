pragma solidity >=0.8.19 <0.9.0;

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";
import { IOrdersGatewayProxy } from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { IOracleAdaptersProxy } from "../../../src/interfaces/IOracleAdaptersProxy.sol";
import { ReyaForkTest } from "../ReyaForkTest.sol";

contract PermissionsForkTest is ReyaForkTest {
    function test_PoolOperationalPermissionsSurviveUpgrade() public view {
        bytes32 autoRebalance = keccak256(abi.encode(keccak256(bytes("autoRebalance")), 1));
        assertEq(IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(autoRebalance).length, 3);
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(autoRebalance));
        assertFalse(IPassivePoolProxy(sec.pool).getFeatureFlagDenyAll(autoRebalance));

        bytes32 metadata = keccak256(bytes("actionMetadataOverwrite"));
        address[] memory metadataAllowlist = IPassivePoolProxy(sec.pool).getFeatureFlagAllowlist(metadata);
        assertEq(metadataAllowlist.length, 2);
        assertTrue(_contains(metadataAllowlist, sec.core));
        assertTrue(_contains(metadataAllowlist, sec.periphery));

        bytes32 deposit = keccak256(abi.encode(keccak256(bytes("deposit")), 1));
        bytes32 withdrawal = keccak256(abi.encode(keccak256(bytes("withdrawal")), 1));
        assertTrue(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(deposit));
        assertTrue(IPassivePoolProxy(sec.pool).getFeatureFlagAllowAll(withdrawal));
    }

    function test_CoreOperationalPermissionsSurviveUpgrade() public view {
        bytes32 customIm = keccak256(bytes("setCustomImMultiplier"));
        address[] memory customImAllowlist = ICoreProxy(sec.core).getFeatureFlagAllowlist(customIm);
        assertEq(customImAllowlist.length, 1);
        assertEq(customImAllowlist[0], sec.pool);

        bytes32 notifyTransfer = keccak256(bytes("notifyAccountTransfer"));
        assertFalse(ICoreProxy(sec.core).getFeatureFlagAllowAll(notifyTransfer));
        assertEq(ICoreProxy(sec.core).getFeatureFlagAllowlist(notifyTransfer).length, 0);
    }

    function test_PerpOBConfigurationPermissions() public view {
        bytes32 configureFees = keccak256(bytes("configureFees"));
        bytes32 configureMarket = keccak256(bytes("configureMarket"));
        address[] memory feeAllowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(configureFees);
        address[] memory marketAllowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(configureMarket);
        assertTrue(_contains(feeAllowlist, sec.multisig));
        assertTrue(_contains(marketAllowlist, sec.multisig));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(configureFees));
        assertFalse(IPassivePerpProxy(sec.perp).getFeatureFlagAllowAll(configureMarket));
    }

    function test_OrdersGatewayMatchingEnginePublisherPermission() public view {
        bytes32 flag = keccak256(bytes("matching_engine_publisher"));
        address[] memory allowlist = IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flag);
        assertTrue(_contains(allowlist, 0x47b3df006f9856c8a8d1B7c558e273B4C1562296));
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowAll(flag));
    }

    function test_OrdersGatewayDustPermissionRemainsClosedPendingReleaseConfiguration() public view {
        bytes32 flag = keccak256(bytes("settle_dust"));
        assertEq(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowlist(flag).length, 0);
        assertFalse(IOrdersGatewayProxy(sec.ordersGateway).getFeatureFlagAllowAll(flag));
    }

    function test_OracleAdapterPermissionsSurviveUpgrade() public view {
        bytes32 executors = keccak256(bytes("executors"));
        bytes32 subSecondExecutors = keccak256(bytes("subSecondExecutors"));
        bytes32 lmTokenPriceUpdaters = keccak256(bytes("lmTokenPriceUpdaters"));
        assertTrue(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(executors));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagDenyAll(executors));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(subSecondExecutors));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagDenyAll(subSecondExecutors));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowAll(lmTokenPriceUpdaters));
        assertFalse(IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagDenyAll(lmTokenPriceUpdaters));
    }

    function test_AccountPermissionsSurviveUpgrade() public view {
        assertTrue(
            ICoreProxy(sec.core).hasAccountPermission(
                109_372, keccak256(bytes("ADMIN")), 0x8836cf32426cb26353698B105ab89fb87f52Fc34
            )
        );
        assertTrue(
            ICoreProxy(sec.core).hasAccountPermission(
                109_371, keccak256(bytes("DUTCH_LIQUIDATION")), 0x84d17e2E153FE902Ac5b5d9c877F18DF3b9C6E56
            )
        );
    }

    function _contains(address[] memory values, address expected) internal pure returns (bool) {
        for (uint256 i = 0; i < values.length; i++) {
            if (values[i] == expected) {
                return true;
            }
        }
        return false;
    }
}
