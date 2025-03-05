pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import { ICoreProxy, Command, CommandType } from "../../src/interfaces/ICoreProxy.sol";
import { ITokenProxy } from "../../src/interfaces/ITokenProxy.sol";
import { IRUSDProxy } from "../../src/interfaces/IRUSDProxy.sol";
import { TransferInput } from "../../src/interfaces/IPeripheryProxy.sol";

contract CompensateAccount is Script, Test {
    address private refundEOA = 0xc5c08b78E7811BDCcB0A960c6BF85e5aeA14BD4c;

    address payable private core = payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80);
    address private rusd = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;

    // Note, Goldksy does not pick up transfer between accounts, hence doing this by withdraw & deposit
    function compensateAccount() public {
        // Replace the account id you want to compensate
        uint128 toAccountId = 51;
        // Replace the amount you want to compensate
        uint256 rusdAmount = 1 * 1e6;

        vm.broadcast(refundEOA);
        ITokenProxy(rusd).approve(core, rusdAmount);

        vm.broadcast(refundEOA);
        ICoreProxy(core).deposit(toAccountId, rusd, rusdAmount);
    }
}
