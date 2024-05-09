pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { IERC20TokenModule } from "../interfaces/IERC20TokenModule.sol";
import { IOwnerUpgradeModule } from "../interfaces/IOwnerUpgradeModule.sol";
import { CommandType } from "../interfaces/ICoreProxy.sol";
import { ISocketExecutionHelper } from "../interfaces/ISocketExecutionHelper.sol";
import {
    IPeripheryProxy,
    DepositPassivePoolInputs,
    PeripheryMatchOrderInputs,
    DepositNewMAInputs,
    Command,
    EIP712Signature
} from "../interfaces/IPeripheryProxy.sol";
import { IPassivePoolProxy } from "../interfaces/IPassivePoolProxy.sol";
import { IPassivePerpProxy } from "../interfaces/IPassivePerpProxy.sol";

import { mockCoreCalculateDigest, hashExecuteBySigExtended, EIP712Signature } from "./../utils/SignatureHelpers.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract ForkChecks is Test {
    string REYA_RPC = "https://rpc.reya.network";

    address multisig = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;

    address payable core = payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80);
    address payable pool = payable(0xB4B77d6180cc14472A9a7BDFF01cc2459368D413);
    address payable perp = payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F);
    address oracleManager = 0xC67316Ed17E0C793041CFE12F674af250a294aab;
    address payable periphery = payable(0xCd2869d1eb1BC8991Bc55de9E9B779e912faF736);
    address exchangePass = 0x76e3f2667aC55d502e26e59C5A6B46e7079217c7;
    address accountNft = 0x0354e71e0444d08e0Ce5E49EB91531A1Cac61144;

    address rusd = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;
    address usdc = 0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2;

    address socketUsdcExecutionHelper = 0x9ca48cAF8AD2B081a0b633d6FCD803076F719fEa;
    address socketUsdcController = 0x1d43076909Ca139BFaC4EbB7194518bE3638fc76;

    uint128 passivePoolAccountId = 2;

    constructor() {
        try vm.activeFork() { }
        catch {
            vm.createSelectFork(REYA_RPC);
        }
    }

    function testFuzz_USDCMintBurn(address attacker) public {
        vm.assume(attacker != socketUsdcController);

        (user, userPk) = makeAddrAndKey("user");
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

            assertEq(IOwnerUpgradeModule(proxy).owner(), multisig);

            vm.prank(attacker);
            vm.expectRevert();
            IOwnerUpgradeModule(proxy).upgradeTo(ownerUpgradeModule);

            vm.prank(multisig);
            IOwnerUpgradeModule(proxy).upgradeTo(ownerUpgradeModule);
        }

        assertEq(IOwnerUpgradeModule(accountNft).owner(), core);
    }

    function testFuzz_PoolDepositWithdraw(address attacker) public {
        (user, userPk) = makeAddrAndKey("user");
        vm.assume(attacker != user);

        uint128 poolId = 1;
        uint256 amount = 100e6;

        uint256 attackerSharesAmount = IPassivePoolProxy(pool).getAccountBalance(poolId, attacker);
        vm.assume(attackerSharesAmount == 0);

        deal(usdc, periphery, amount);

        DepositPassivePoolInputs memory inputs = DepositPassivePoolInputs({ poolId: poolId, owner: user, minShares: 0 });
        vm.prank(socketUsdcExecutionHelper);
        vm.mockCall(
            socketUsdcExecutionHelper, abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()), abi.encode(amount)
        );
        IPeripheryProxy(periphery).depositPassivePool(inputs);

        uint256 userSharesAmount = IPassivePoolProxy(pool).getAccountBalance(poolId, user);
        assert(userSharesAmount > 0);

        vm.prank(attacker);
        vm.expectRevert();
        IPassivePoolProxy(pool).removeLiquidity(poolId, userSharesAmount, 0);

        vm.prank(user);
        IPassivePoolProxy(pool).removeLiquidity(poolId, userSharesAmount, 0);
    }

    function mockBridgedAmount(address executionHelper, uint256 amount) private {
        vm.mockCall(
            executionHelper, abi.encodeWithSelector(ISocketExecutionHelper.bridgeAmount.selector), abi.encode(amount)
        );
    }

    // stack too deep
    address user;
    uint256 userPk;
    uint128 marketId;
    uint128 exchangeId;

    function test_trade() public {
        // general info
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 100e6; // denominated in rusd/usdc
        marketId = 1; // eth
        exchangeId = 1; // passive pool
        // SD59x18 base = sd(0.01e18);
        // UD60x18 priceLimit = ud(10_000e18);
        SD59x18 base = sd(-0.01e18);
        UD60x18 priceLimit = ud(0);

        // deposit new margin account
        deal(usdc, address(periphery), amount);
        mockBridgedAmount(socketUsdcExecutionHelper, amount);
        vm.prank(socketUsdcExecutionHelper);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        // match order
        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = passivePoolAccountId;
        uint256 deadline = block.timestamp + 3600; // one hour
        uint256 incrementedNonce = 1;
        Command[] memory commands = new Command[](1);
        commands[0] = Command({
            commandType: uint8(CommandType.MatchOrder),
            inputs: abi.encode(counterpartyAccountIds, abi.encode(base, priceLimit)),
            marketId: marketId,
            exchangeId: exchangeId
        });
        bytes32 digest = mockCoreCalculateDigest(
            core,
            hashExecuteBySigExtended(
                address(periphery), accountId, commands, incrementedNonce, deadline, keccak256(abi.encode())
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);
        IPeripheryProxy(periphery).executeMatchOrders(
            PeripheryMatchOrderInputs({
                accountId: accountId,
                commands: commands,
                sig: EIP712Signature({ v: v, r: r, s: s, deadline: deadline })
            })
        );
        assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());
    }
}
