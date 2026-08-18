pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { OracleConfigurationForkCheck } from "../../reya_common/oracle_manager/OracleConfiguration.fork.c.sol";

contract OracleConfigurationForkTest is ReyaForkTest, OracleConfigurationForkCheck {
    function test_Devnet_oracleStack_deployedAndOwned() public view {
        check_oracleStack_deployedAndOwned();
    }

    function test_Devnet_criticalNodes_registeredOnThisManager() public view {
        check_criticalNodes_registeredOnThisManager();
    }

    function test_Devnet_adaptersSharedConfig_applied() public view {
        check_adaptersSharedConfig_applied();
    }

    function test_Devnet_srusdPoolNode_producesPrice() public view {
        check_srusdPoolNode_producesPrice();
    }

    function test_Devnet_criticalNodes_priceThroughThisAdapters() public {
        check_criticalNodes_priceThroughThisAdapters();
    }

    function test_Devnet_oraclePushers_areAuthorizedExecutors() public {
        check_oraclePushers_areAuthorizedExecutors();
    }
}
