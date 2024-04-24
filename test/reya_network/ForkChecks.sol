pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { IERC20TokenModule } from "@voltz-protocol/token/src/interfaces/IERC20TokenModule.sol";
import { OwnerUpgradeModule } from "@voltz-protocol/util-modules/src/modules/OwnerUpgradeModule.sol";
import { ISocketExecutionHelper } from "@voltz-protocol/periphery/src/interfaces/external/ISocketExecutionHelper.sol";
import { DepositPassivePoolInputs } from "@voltz-protocol/periphery/src/libraries/DataTypes.sol";
import { PassivePoolProxy } from "./proxies/PassivePool.sol";
import { PeripheryRouter } from "./proxies/Periphery.sol";

contract ForkChecks is Test {
    string REYA_RPC = "https://rpc.reya.network";

    address multisig = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;

    address payable public core = payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80);
    address payable public pool = payable(0xB4B77d6180cc14472A9a7BDFF01cc2459368D413);
    address payable public perp = payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F);
    address public oracleManager = 0xC67316Ed17E0C793041CFE12F674af250a294aab;
    address payable public periphery = payable(0xCd2869d1eb1BC8991Bc55de9E9B779e912faF736);
    address public exchangePass = 0x76e3f2667aC55d502e26e59C5A6B46e7079217c7;
    address public accountNft = 0x0354e71e0444d08e0Ce5E49EB91531A1Cac61144;

    address public usd = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;
    address public usdc = 0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2;

    address public socketUsdcExecutionHelper = 0x9ca48cAF8AD2B081a0b633d6FCD803076F719fEa;
    address public socketUsdcController = 0x1d43076909Ca139BFaC4EbB7194518bE3638fc76;

    constructor() {
        try vm.activeFork() { }
        catch {
            vm.createSelectFork(REYA_RPC);
        }
    }

    function testFuzz_USDCMintBurn(address attacker) public {
        vm.assume(attacker != socketUsdcController);

        address user = vm.addr(1);
        uint256 amount = 10e6;

        // mint
        vm.prank(socketUsdcController);
        IERC20TokenModule(usdc).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(usdc).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(usdc).mint(user, amount);

        // burn
        vm.prank(socketUsdcController);
        IERC20TokenModule(usdc).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(usdc).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(usdc).burn(user, amount);
    }

    function testFuzz_ProxiesOwnerAndUpgrades(address attacker) public {
        vm.assume(attacker != multisig);

        address ownerUpgradeModule = 0x70230eE0CcA326A559410DCEd74F2972306D1e1e;

        address[] memory proxies = new address[](6);
        proxies[0] = core;
        proxies[1] = pool;
        proxies[2] = perp;
        proxies[3] = oracleManager;
        proxies[4] = periphery;
        proxies[5] = exchangePass;

        for (uint256 i = 0; i < proxies.length; i += 1) {
            address proxy = proxies[i];

            assertEq(OwnerUpgradeModule(proxy).owner(), multisig);

            vm.prank(attacker);
            vm.expectRevert();
            OwnerUpgradeModule(proxy).upgradeTo(ownerUpgradeModule);

            vm.prank(multisig);
            OwnerUpgradeModule(proxy).upgradeTo(ownerUpgradeModule);
        }

        assertEq(OwnerUpgradeModule(accountNft).owner(), core);
    }

    function testFuzz_PoolDepositWithdraw(address attacker) public {
        uint128 poolId = 1;

        uint256 attackerSharesAmount = PassivePoolProxy(pool).getAccountBalance(poolId, attacker);
        vm.assume(attackerSharesAmount == 0);

        address user = vm.addr(1);
        uint256 amount = 100e6;

        deal(usdc, periphery, amount);

        DepositPassivePoolInputs memory inputs = DepositPassivePoolInputs({ poolId: poolId, owner: user, minShares: 0 });
        vm.prank(socketUsdcExecutionHelper);
        vm.mockCall(
            socketUsdcExecutionHelper, abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()), abi.encode(amount)
        );
        PeripheryRouter(periphery).depositPassivePool(inputs);

        uint256 userSharesAmount = PassivePoolProxy(pool).getAccountBalance(poolId, user);
        assert(userSharesAmount > 0);

        vm.prank(attacker);
        vm.expectRevert();
        PassivePoolProxy(pool).removeLiquidity(poolId, userSharesAmount, 0);

        // withdrawals are blocked at the moment
        vm.prank(user);
        PassivePoolProxy(pool).removeLiquidity(poolId, userSharesAmount, 0);
    }
}
