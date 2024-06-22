pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IOwnerUpgradeModule } from "../../../src/interfaces/IOwnerUpgradeModule.sol";

contract GeneralForkCheck is BaseReyaForkTest {
    function checkFuzz_ProxiesOwnerAndUpgrades(address attacker) public {
        vm.assume(attacker != sec.multisig);

        address[] memory proxies = new address[](6);
        proxies[0] = sec.core;
        proxies[1] = sec.pool;
        proxies[2] = sec.perp;
        proxies[3] = sec.oracleManager;
        proxies[4] = sec.periphery;
        proxies[5] = sec.exchangePass;

        for (uint256 i = 0; i < proxies.length; i += 1) {
            address proxy = proxies[i];

            assertEq(IOwnerUpgradeModule(proxy).owner(), sec.multisig);

            vm.prank(attacker);
            vm.expectRevert();
            IOwnerUpgradeModule(proxy).upgradeTo(sec.ownerUpgradeModule);

            vm.prank(sec.multisig);
            IOwnerUpgradeModule(proxy).upgradeTo(sec.ownerUpgradeModule);
        }

        assertEq(IOwnerUpgradeModule(sec.accountNft).owner(), sec.core);
    }
}
