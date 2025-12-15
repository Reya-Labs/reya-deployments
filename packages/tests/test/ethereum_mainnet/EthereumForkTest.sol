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
        sec.foundationMultisig = 0x8349021746B4db503c4DF51e5f24241EAf80E816;
        sec.foundationEoa = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // contracts
        sec.reya = 0x30b8BEF7a17FBfd8Ca749D1e7E722dE157306b49;
        sec.ico = 0x2bF73F23DcEFF3af24A333D809b4058bBca176FB;

        // create fork
        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.MAINNET_RPC);
        }
    }
}
