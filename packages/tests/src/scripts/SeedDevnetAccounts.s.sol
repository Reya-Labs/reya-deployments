pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import { ICoreProxy } from "../../src/interfaces/ICoreProxy.sol";
import { ITokenProxy } from "../../src/interfaces/ITokenProxy.sol";

contract SeedDevnetAccounts is Script, Test {
    address private funderEOA = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;

    address payable private core = payable(0xC33D0A4FC05aF98447126f1680cA7316de29e5d4);
    address private rusd = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;

    uint256 private amountPerAccount = 10_000 * 1e6;

    function seed() public {
        address[4] memory targets = [
            0x692942979e3fcCC41bc03bA0750283AfCdc2106c,
            0x97D60d68f66a5466C642b95bA8A1925F2c2d20bD,
            0x6C51275FD01d5DbD2DA194E92f920f8598306dF2,
            0x186495A1D50777C7f126c2B2c6d4F0d9839888f2
        ];

        uint256 total = amountPerAccount * targets.length;

        vm.broadcast(funderEOA);
        ITokenProxy(rusd).approve(core, total);

        for (uint256 i = 0; i < targets.length; i += 1) {
            address target = targets[i];

            vm.broadcast(funderEOA);
            uint128 accountId = ICoreProxy(core).createAccount(target);

            vm.broadcast(funderEOA);
            ICoreProxy(core).deposit(accountId, rusd, amountPerAccount);

            assertEq(ICoreProxy(core).getAccountOwner(accountId), target, "owner mismatch");
            console2.log("seeded", target, "accountId:", uint256(accountId));
        }
    }
}
