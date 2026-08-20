pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { OracleConfigurationForkCheck } from "../../reya_common/oracle_manager/OracleConfiguration.fork.c.sol";
import { IOracleAdaptersProxy } from "../../../src/interfaces/IOracleAdaptersProxy.sol";

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

    /// Devnet-specific EXACT-set assertion: subSecondExecutors is precisely
    /// the two oracle-update-onchain task keys. Everything else was verified
    /// not to push through the adapters (perp-ob pushers write to
    /// PassivePerp, the feat/perpOB orders gateway no longer pushes, ws-exec
    /// is keyless, autoexchange/liquidator/api submit without prepends), so
    /// any extra entry here is unexplained authority and any missing one
    /// breaks fresh-price pushes. Reads pristine deployment state: the
    /// fixture setUp seeds a publisher, never an executor.
    function test_Devnet_subSecondExecutors_exactSet() public view {
        address[] memory allowed = IOracleAdaptersProxy(sec.oracleAdaptersProxy).getFeatureFlagAllowlist(
            keccak256(bytes("subSecondExecutors"))
        );
        require(allowed.length == 2, "subSecondExecutors should hold exactly the two oracle updaters");
        require(
            IOracleAdaptersProxy(sec.oracleAdaptersProxy).isFeatureAllowed(
                keccak256(bytes("subSecondExecutors")), sec.oracleUpdater1
            )
                && IOracleAdaptersProxy(sec.oracleAdaptersProxy).isFeatureAllowed(
                    keccak256(bytes("subSecondExecutors")), sec.oracleUpdater2
                ),
            "oracle updater missing from subSecondExecutors"
        );
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
