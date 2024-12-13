pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import { ICoreProxy } from "../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../../src/interfaces/IPassivePerpProxy.sol";

// cd packages/tests
// forge script SetAccountTier <account_id> <tier_id>  --rpc-url https://rpc.reya.network --sig
// "setAccountTier(uint128,uint256)" --private-key <private_key> --skip-simulation --broadcast
contract SetAccountTier is Script, Test {
    address private accountTierBot = 0x4abD94336349C300c0E1f6b5CB71438538FB5D61;

    address payable private core = payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80);
    address payable private perp = payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F);

    function setAccountTier(uint128 accountId, uint256 tierId) public {
        uint128 lastMarketId = ICoreProxy(core).getLastCreatedMarketId();
        for (uint128 marketId = 1; marketId <= lastMarketId; marketId += 1) {
            vm.broadcast(accountTierBot);
            IPassivePerpProxy(perp).setAccountTier(marketId, accountId, tierId);
        }
    }
}
