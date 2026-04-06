pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { BaseReyaForkTest } from "../reya_common/BaseReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

import { IOracleManagerProxy } from "../../src/interfaces/IOracleManagerProxy.sol";

/**
 * @title ReyaForkTest (Devnet)
 * @notice Devnet environment configuration for perpOB fork tests
 * @dev Shares the Cronos testnet chain (chainId 89346162) but uses fresh proxy deployments.
 *      Minimal setup: 1 perp market (ETH), 1 spot market (WETH), 2 collaterals (rUSD, wETH).
 *      No passive pool counterparty — uses dedicated backstop liquidator account.
 *
 *      IMPORTANT: Proxy addresses below are placeholders. Update them after cannon deploys
 *      the devnet omnibus to the Cronos testnet chain.
 */
contract ReyaForkTest is BaseReyaForkTest {
    constructor() {
        string memory rpcKey = vm.envString("RPC_KEY");
        // network (same chain as cronos testnet)
        sec.REYA_RPC = string.concat("https://rpc.reya-cronos.gelato.digital/", rpcKey);
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/sepolia";

        // other (external) chain id
        sec.destinationChainId = ethereumSepoliaChainId;

        // multisigs (devnet owner)
        // TODO: update after deployment
        sec.multisig = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

        // Reya contracts (placeholder addresses — update after cannon deployment)
        // TODO: replace with actual deployed proxy addresses
        sec.core = payable(address(0x1001));
        sec.pool = payable(address(0x1002));
        sec.perp = payable(address(0x1003));
        sec.oracleManager = address(0x1004);
        sec.periphery = payable(address(0x1005));
        sec.ordersGateway = payable(address(0x1006));
        sec.oracleAdaptersProxy = payable(address(0x1007));
        sec.exchangePass = address(0x1008);
        sec.accountNft = address(0x1009);

        // Reya tokens (reuse Cronos testnet token deployments)
        sec.rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;
        sec.usdc = 0xfA27c7c6051344263533cc365274d9569b0272A8;
        sec.weth = 0x2CF56315ACC7E791B1A0135c09d8D5C8dBCD2F14;

        // Reya variables
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 0; // no passive pool counterparty in devnet

        // Reya bots (placeholder — update after deployment)
        // TODO: replace with actual bot addresses
        sec.coExecutionBot = 0xB6EaF546b84E1f917579FC4FD3d7082DfE2ba212;

        // Spot oracle node ids (reuse Cronos Stork nodes for ETH spot price)
        sec.ethUsdStorkNodeId = 0x6f1442b15af1cde852d45cdd67336b330257c9df23834909159097b25b57936c;
        sec.ethUsdcStorkNodeId = 0xb19e4d8ea5f0a3752fbd19515075063f7486e6954b8aa2b3d462c61726c46619;
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdStorkNodeId = 0x28c79729ca502a5cd2565613c087a3bda098a1c78e3f3f45733d03c3482f099d;

        // Mark price node ids (ETH only — may differ from cronos after perpOB deploy)
        sec.ethUsdStorkMarkNodeId = 0x3f4c9f3d5efcbd98002f057a6c0acd0313aa63ab20334e611a30261b89acc1fa;
        sec.ethUsdcStorkMarkNodeId = 0x14dba23a7f8775bceefeedb4266fbe135b949ae40fe08e491f2a476d3448c66f;
    }
}
