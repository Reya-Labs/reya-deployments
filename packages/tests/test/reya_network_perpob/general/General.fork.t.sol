pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { GeneralForkCheck } from "../../reya_common/general/General.fork.c.sol";
import { IPeripheryProxy, GlobalConfiguration } from "../../../src/interfaces/IPeripheryProxy.sol";

contract GeneralForkTest is ReyaForkTest, GeneralForkCheck {
    function testFuzz_ProxiesOwnerAndUpgrades(address attacker) public {
        vm.assume(attacker != sec.multisig);
        checkFuzz_ProxiesOwnerAndUpgrades(attacker);
    }

    function test_PeripheryConfigurationSurvivesUpgrade() public view {
        GlobalConfiguration.Data memory config = IPeripheryProxy(sec.periphery).getGlobalConfiguration();
        assertEq(config.coreProxy, sec.core);
        assertEq(config.rUSDProxy, sec.rusd);
        assertEq(config.passivePoolProxy, sec.pool);
        assertEq(config.sREYAProxy, sec.sreya);
        assertEq(config.REYAProxy, sec.reya);
        assertEq(config.layerZeroEndpoint, sec.layerZeroEndpoint);
        assertEq(IPeripheryProxy(sec.periphery).getTokenController(sec.usdc), dec.socketController[sec.usdc]);
        assertEq(IPeripheryProxy(sec.periphery).getTokenExecutionHelper(sec.usdc), dec.socketExecutionHelper[sec.usdc]);
    }

    function test_SdeusdPrice() public view {
        check_sdeusd_price();
    }

    function test_SdeusdPriceAgainstMainnet() public {
        check_sdeusd_deusd_price();
    }

    function test_PeripherySrusdBalance() public view {
        check_periphery_srusd_balance();
    }
}
