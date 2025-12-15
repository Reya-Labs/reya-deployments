pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { EthereumStorageReyaForkTest } from "../ethereum_common/EthereumStorageReyaForkTest.sol";
import "../ethereum_common/DataTypes.sol";

import { ICoreProxy } from "../../src/interfaces/ICoreProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../src/interfaces/IOracleManagerProxy.sol";

contract EthereumForkTest is EthereumStorageReyaForkTest {
    constructor() {
        // network
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/mainnet";

        // multisigs
        sec.foundationMultisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // contracts
        sec.reya = 0x17eaBC48B01704731bB24354220Fa904605bf968;
        sec.ico = 0x79Effe4F9EBc2B5fE46f46997455b55b5B2D8564;

        // create fork
        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.MAINNET_RPC);
        }
    }
}
