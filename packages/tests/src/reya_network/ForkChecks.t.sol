pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { IERC20TokenModule } from "../interfaces/IERC20TokenModule.sol";
import { IOwnerUpgradeModule } from "../interfaces/IOwnerUpgradeModule.sol";
import {
    ICoreProxy, CommandType, Command as Command_Core, RiskMultipliers, MarginInfo
} from "../interfaces/ICoreProxy.sol";
import { ISocketExecutionHelper } from "../interfaces/ISocketExecutionHelper.sol";
import {
    IPeripheryProxy,
    DepositPassivePoolInputs,
    PeripheryExecutionInputs,
    DepositNewMAInputs,
    Command as Command_Periphery,
    EIP712Signature,
    GlobalConfiguration
} from "../interfaces/IPeripheryProxy.sol";
import { IPassivePoolProxy } from "../interfaces/IPassivePoolProxy.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../interfaces/IPassivePerpProxy.sol";
import { IRUSDProxy } from "../interfaces/IRUSDProxy.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../interfaces/IOracleManagerProxy.sol";

import { mockCoreCalculateDigest, hashExecuteBySigExtended, EIP712Signature } from "./../utils/SignatureHelpers.sol";

import { sd, SD59x18, UNIT as UNIT_sd, ZERO as ZERO_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { console2 } from "forge-std/Test.sol";

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
    address socketUsdcEthereumConnector = 0x807B2e8724cDf346c87EEFF4E309bbFCb8681eC1;
    address socketUsdcArbitrumConnector = 0x663dc7E91157c58079f55C1BF5ee1BdB6401Ca7a;
    address socketUsdcOptimismConnector = 0xe48AE3B68f0560d4aaA312E12fD687630C948561;
    address socketUsdcPolygonConnector = 0x54CAA0946dA179425e1abB169C020004284d64D3;
    address socketUsdcBaseConnector = 0x3694Ab37011764fA64A648C2d5d6aC0E9cD5F98e;

    uint256 ethereumChainId = 1;
    uint256 arbitrumChainId = 42_161;
    uint256 optimismChainId = 10;
    uint256 polygonChainId = 137;
    uint256 baseChainId = 8453;

    bytes32 ethUsdNodeId = 0x7bb5195bd6b7c7bd928da2b52cae900a5f6262eb32b992ac4d97b4f2c322422c;
    bytes32 btcUsdNodeId = 0x2973a5fc60ce7fd59c68e20eade5cbb56d3f22516f5dbd78d09654de5070df8e;
    bytes32 ethUsdcNodeId = 0xd47353c2b593083048dc9eb3f58c89553c5cafc5065d65774e5614daa8f37b47;
    bytes32 btcUsdcNodeId = 0x9a2f8b104c6d9f675d4f756a6d54c4cb9fbbfdb999c77cc6e69003bcbc561476;
    bytes32 rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
    bytes32 usdcUsdNodeId = 0x7c1a73684de34b95f492a9ee72c0d8e1589714eeba4a457f766b84bd1c2f240f;

    uint128 passivePoolId = 1;
    uint128 passivePoolAccountId = 2;

    uint256 ONE_MINUTE_IN_SECONDS = 60;

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

        uint256 totalSupplyBefore = IERC20TokenModule(usdc).totalSupply();

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

        uint256 totalSupplyAfter = IERC20TokenModule(usdc).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function testFuzz_rUSD() public {
        assertEq(IRUSDProxy(rusd).getUnderlyingAsset(), usdc);

        uint256 rusdTotalSupply = IRUSDProxy(rusd).totalSupply();
        uint256 usdcTotalSupply = IERC20TokenModule(rusd).totalSupply();
        assert(rusdTotalSupply <= usdcTotalSupply);

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        deal(usdc, user, amount);
        vm.prank(user);
        IERC20TokenModule(usdc).approve(rusd, amount);
        vm.prank(user);
        IRUSDProxy(rusd).deposit(amount);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply + amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), amount);
        assertEq(IRUSDProxy(usdc).balanceOf(user), 0);
        rusdTotalSupply += amount;

        deal(usdc, periphery, amount);
        vm.prank(periphery);
        IERC20TokenModule(usdc).approve(rusd, amount);
        vm.prank(periphery);
        IRUSDProxy(rusd).depositTo(amount, user);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply + amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), 2 * amount);
        assertEq(IRUSDProxy(usdc).balanceOf(user), 0);
        assertEq(IRUSDProxy(rusd).balanceOf(periphery), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(periphery), 0);
        rusdTotalSupply += amount;

        vm.prank(user);
        IRUSDProxy(rusd).withdraw(amount);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply - amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), amount);
        assertEq(IRUSDProxy(usdc).balanceOf(user), amount);
        assertEq(IRUSDProxy(rusd).balanceOf(periphery), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(periphery), 0);
        rusdTotalSupply -= amount;

        vm.prank(user);
        IRUSDProxy(rusd).withdrawTo(amount, periphery);
        assertEq(IRUSDProxy(rusd).totalSupply(), rusdTotalSupply - amount);
        assertEq(IRUSDProxy(rusd).balanceOf(user), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(user), amount);
        assertEq(IRUSDProxy(rusd).balanceOf(periphery), 0);
        assertEq(IRUSDProxy(usdc).balanceOf(periphery), amount);
        rusdTotalSupply -= amount;
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

    function test_Periphery() public view {
        GlobalConfiguration.Data memory globalConfig = IPeripheryProxy(periphery).getGlobalConfiguration();
        assertEq(globalConfig.coreProxy, core);
        assertEq(globalConfig.rUSDProxy, rusd);
        assertEq(globalConfig.passivePoolProxy, pool);

        assertEq(IPeripheryProxy(periphery).getTokenController(usdc), socketUsdcController);
        assertEq(IPeripheryProxy(periphery).getTokenExecutionHelper(usdc), socketUsdcExecutionHelper);
        assertEq(IPeripheryProxy(periphery).getTokenChainConnector(usdc, ethereumChainId), socketUsdcEthereumConnector);
        assertEq(IPeripheryProxy(periphery).getTokenChainConnector(usdc, arbitrumChainId), socketUsdcArbitrumConnector);
        assertEq(IPeripheryProxy(periphery).getTokenChainConnector(usdc, optimismChainId), socketUsdcOptimismConnector);
        assertEq(IPeripheryProxy(periphery).getTokenChainConnector(usdc, polygonChainId), socketUsdcPolygonConnector);
        assertEq(IPeripheryProxy(periphery).getTokenChainConnector(usdc, baseChainId), socketUsdcBaseConnector);
    }

    function test_OracleManager() public view {
        NodeOutput.Data memory ethUsdNodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdNodeId);
        NodeOutput.Data memory btcUsdNodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdNodeId);
        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdcNodeId);
        NodeOutput.Data memory btcUsdcNodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdcNodeId);
        NodeOutput.Data memory rusdUsdNodeOutput = IOracleManagerProxy(oracleManager).process(rusdUsdNodeId);
        NodeOutput.Data memory usdcUsdNodeOutput = IOracleManagerProxy(oracleManager).process(usdcUsdNodeId);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, ethUsdNodeOutput.timestamp);
        assertLe(ethUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(ethUsdNodeOutput.price, 3000e18, 1000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, btcUsdNodeOutput.timestamp);
        assertLe(btcUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdNodeOutput.price, 60_000e18, 10_000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, ethUsdcNodeOutput.timestamp);
        assertLe(ethUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(ethUsdcNodeOutput.price, 3000e18, 1000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, btcUsdcNodeOutput.timestamp);
        assertLe(btcUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdcNodeOutput.price, 60_000e18, 10_000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, rusdUsdNodeOutput.timestamp);
        assertLe(rusdUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(rusdUsdNodeOutput.price, 1e18, 0, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, usdcUsdNodeOutput.timestamp);
        assertLe(usdcUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(usdcUsdNodeOutput.price, 1e18, 0.01e18, 18);

        NodeDefinition.Data memory ethUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(ethUsdNodeId);
        NodeDefinition.Data memory btcUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(btcUsdNodeId);
        NodeDefinition.Data memory ethUsdcNodeDefinition = IOracleManagerProxy(oracleManager).getNode(ethUsdcNodeId);
        NodeDefinition.Data memory btcUsdcNodeDefinition = IOracleManagerProxy(oracleManager).getNode(btcUsdcNodeId);
        NodeDefinition.Data memory rusdUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(rusdUsdNodeId);
        NodeDefinition.Data memory usdcUsdNodeDefinition = IOracleManagerProxy(oracleManager).getNode(usdcUsdNodeId);

        assertEq(ethUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(btcUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(ethUsdcNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(btcUsdcNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(rusdUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
        assertEq(usdcUsdNodeDefinition.maxStaleDuration, ONE_MINUTE_IN_SECONDS);
    }

    function test_PoolHealth() public view {
        MarginInfo memory poolMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(passivePoolAccountId);
        assertGtDecimal(uint256(poolMarginInfo.liquidationDelta), 0, 18);
        assertGtDecimal(uint256(poolMarginInfo.initialDelta), 0, 18);

        UD60x18 sharePrice = ud(IPassivePoolProxy(pool).getSharePrice(passivePoolId));
        assertGtDecimal(sharePrice.unwrap(), 0.99e18, 18);
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
    RiskMultipliers riskMultipliers;
    UD60x18 liquidationMarginRequirement;
    UD60x18 imr;
    UD60x18 leverage;
    NodeOutput.Data nodeOutput;
    UD60x18 price;
    UD60x18 absBase;
    UD60x18 baseSpacing;

    function getMarketSpotPrice(uint128 marketId) private returns (UD60x18 marketSpotPrice) {
        MarketConfigurationData memory marketConfig = IPassivePerpProxy(perp).getMarketConfiguration(marketId);
        NodeOutput.Data memory marketNodeOutput = IOracleManagerProxy(oracleManager).process(marketConfig.oracleNodeId);
        return ud(marketNodeOutput.price);
    }

    function getPriceLimit(SD59x18 base) private returns (UD60x18 priceLimit) {
        if (base.gt(ZERO_sd)) {
            return ud(type(uint256).max);
        }

        return ud(0);
    }

    function executePeripheryMatchOrder(
        uint256 incrementedNonce,
        uint128 marketId,
        SD59x18 base,
        UD60x18 priceLimit,
        uint128 accountId
    )
        private
    {
        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = passivePoolAccountId;
        uint256 deadline = block.timestamp + 3600; // one hour

        exchangeId = 1; // passive pool

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
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

        IPeripheryProxy(periphery).execute(
            PeripheryExecutionInputs({
                accountId: accountId,
                commands: commands,
                sig: EIP712Signature({ v: v, r: r, s: s, deadline: deadline })
            })
        );
    }

    function executeCoreMatchOrder(
        address sender,
        SD59x18 base,
        UD60x18 priceLimit,
        uint128 accountId
    )
        private
        returns (UD60x18 orderPrice, SD59x18 pSlippage)
    {
        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = passivePoolAccountId;
        uint256 deadline = block.timestamp + 3600; // one hour

        exchangeId = 1; // passive pool

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = Command_Core({
            commandType: uint8(CommandType.MatchOrder),
            inputs: abi.encode(counterpartyAccountIds, abi.encode(base, priceLimit)),
            marketId: marketId,
            exchangeId: exchangeId
        });

        vm.prank(sender);

        bytes[] memory outputs;
        (outputs,) = ICoreProxy(core).execute(accountId, commands);

        orderPrice = UD60x18.wrap(abi.decode(outputs[0], (uint256)));
        pSlippage = orderPrice.div(getMarketSpotPrice(marketId)).intoSD59x18().sub(UNIT_sd);
    }

    function test_trade_eth() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e6; // denominated in rusd/usdc
        marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(usdc, address(periphery), amount);
        mockBridgedAmount(socketUsdcExecutionHelper, amount);
        vm.prank(socketUsdcExecutionHelper);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        executePeripheryMatchOrder(1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        test_PoolHealth();
    }

    function test_trade_btc() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 60_000e6; // denominated in rusd/usdc
        marketId = 2; // btc
        exchangeId = 1; // passive pool
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(usdc, address(periphery), amount);
        mockBridgedAmount(socketUsdcExecutionHelper, amount);
        vm.prank(socketUsdcExecutionHelper);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        executePeripheryMatchOrder(1, marketId, base, priceLimit, accountId);

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        test_PoolHealth();
    }

    function wadToString(UD60x18 x) private returns (string memory) {
        return vm.toString(x.unwrap());
        // string[] memory pythonCommand = new string[](3);
        // pythonCommand[0] = 'python3';
        // pythonCommand[1] = '-c';
        // pythonCommand[2] = string.concat('print("""{:.18f}""".format(', string.concat(vm.toString(x.unwrap()),
        // '/1e18))'));
        // return string(vm.ffi(pythonCommand));
    }

    function wadToString(SD59x18 x) private returns (string memory) {
        return vm.toString(x.unwrap());
        // string[] memory pythonCommand = new string[](3);
        // pythonCommand[0] = 'python3';
        // pythonCommand[1] = '-c';
        // pythonCommand[2] = string.concat('print("""{:.18f}""".format(', string.concat(vm.toString(x.unwrap()),
        // '/1e18))'));
        // return string(vm.ffi(pythonCommand));
    }

    function notionalToBase(uint128 marketId, SD59x18 notional) private returns (SD59x18 base) {
        base = notional.div(getMarketSpotPrice(marketId).intoSD59x18());
    }

    // function test_trade_slippage_eth() public {
    //     (user, userPk) = makeAddrAndKey("user");
    //     marketId = 1; // eth
    //     exchangeId = 1; // passive pool
    //     baseSpacing = ud(0.005e18);

    //     RiskMultipliers memory riskMultipliers = ICoreProxy(core).getRiskMultipliers();
    //     int64[][] memory marketRiskMatrix = IPassivePerpProxy(perp).getRiskBlockMatrixByMarket(marketId);

    //     // increase max open base
    //     MarketConfigurationData memory marketConfig = IPassivePerpProxy(perp).getMarketConfiguration(marketId);
    //     marketConfig.maxOpenBase = 1000000e18;
    //     vm.prank(multisig);
    //     IPassivePerpProxy(perp).setMarketConfiguration(marketId, marketConfig);

    //     // deposit new margin account
    //     uint256 depositAmount = 100_000_000e18;
    //     deal(usdc, address(periphery), depositAmount);
    //     mockBridgedAmount(socketUsdcExecutionHelper, depositAmount);
    //     vm.prank(socketUsdcExecutionHelper);
    //     uint128 accountId =
    //         IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc)
    // }));

    //     // step 1: Unwind any exposure of the pool
    //     {
    //         SD59x18 poolBase =
    //             SD59x18.wrap(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, passivePoolAccountId).base);

    //         executeCoreMatchOrder({
    //             sender: user,
    //             base: poolBase,
    //             priceLimit: getPriceLimit(poolBase),
    //             accountId: accountId
    //         });

    //         assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, passivePoolAccountId).base, 0);

    //         console2.log(string.concat("trader base post off-set trade (pool base is now 0) ",
    // wadToString(sd(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, accountId).base))));
    //     }

    //     // step 2: Get pool's TVL
    //     MarginInfo memory poolMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(passivePoolAccountId);
    //     SD59x18 passivePoolTVL = sd(poolMarginInfo.marginBalance);

    //     // Step 3: Compute the grid
    //     SD59x18 prevNotionalsSum = sd(0);
    //     for (uint i = 1; i < 10; i += 1) {
    //         SD59x18 notional = s[i].div(UNIT_sd.add(s[i])).mul(
    //             ud(marketConfig.depthFactor).mul(passivePoolTVL).div(sd(riskMultipliers.imMultiplier).mul(sd(marketRiskMatrix[marketConfig.riskMatrixIndex][marketConfig.riskMatrixIndex])))
    //         ).sub(prevNotionalsSum);
    //         SD59x18 base = notionalToBase(marketId, notional);

    //         UD60x18 orderPrice;
    //         SD59x18 pSlippage;
    //         (orderPrice, pSlippage) = executeCoreMatchOrder({
    //             sender: user,
    //             base: base,
    //             priceLimit: getPriceLimit(base),
    //             accountId: accountId
    //         });

    //         console2.log(string.concat("step ", vm.toString(i)), pSlippage);

    //         prevNotionalsSum = prevNotionalsSum.add(notional);
    //     }

    //     passivePoolTVL =
    // sd(0.01e18).div(UNIT_sd.add(sd(0.01e18))).mul(UNIT_sd.add(initialPSlippage).div(initialPSlippage));

    //     SD59x18[] memory s = new SD59x18[](11);
    //     s[0] = sd(e18);
    //     s[1] = sd(e18);
    //     s[2] = sd(e18);
    //     s[3] = sd(e18);
    //     s[4] = sd(e18);
    //     s[5] = sd(e18);
    //     s[6] = sd(e18);
    //     s[7] = sd(e18);
    //     s[8] = sd(e18);
    //     s[9] = sd(e18);
    //     s[10] = sd(e18);

    //     assertEq(notionalArray.length, pSlippageArray.length);

    //     for (uint256 i = 0; i < notionalArray.length; i += 1) {
    //         SD59x18 baseStep;
    //         if (i > 0) {
    //             baseStep = notionalArray[i].sub(notionalArray[i-1]).div(getMarketSpotPrice(marketId).intoSD59x18());
    //         } else {
    //             baseStep = notionalArray[i].div(getMarketSpotPrice(marketId).intoSD59x18());
    //         }
    //         baseStep = baseStep.sub(baseStep.mod(baseSpacing.intoSD59x18()));

    //         UD60x18 orderPrice;
    //         SD59x18 pSlippage;
    //         (orderPrice, pSlippage) = executeCoreMatchOrder({
    //             sender: user,
    //             base: baseStep,
    //             priceLimit: getPriceLimit(baseStep),
    //             accountId: accountId
    //         });

    //         string memory stepString = string.concat("step ", string.concat(vm.toString(i), " "));
    //         // console2.log(string.concat(string.concat(stepString, "order price "), wadToString(orderPrice)));
    //         // console2.log(string.concat(string.concat(stepString, "market spot price "),
    // wadToString(getMarketSpotPrice(marketId))));
    //         console2.log(string.concat(string.concat(stepString, "p slippage "), wadToString(pSlippage)));
    //         // console2.log(string.concat(string.concat(stepString, "base step "), wadToString(baseStep)));
    //         // console2.log(string.concat(string.concat(stepString, "pool base exposure "),
    // wadToString(sd(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, passivePoolAccountId).base))));
    //         // console2.log(string.concat(string.concat(stepString, "trader base exposure "),
    // wadToString(sd(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, accountId).base))));
    //         console2.log("");

    //         // executeCoreMatchOrder({
    //         //     sender: user,
    //         //     base: baseStep.mul(sd(-1e18)),
    //         //     priceLimit: getPriceLimit(baseStep.mul(sd(-1e18))),
    //         //     accountId: accountId
    //         // });

    //         assertApproxEqAbsDecimal(pSlippage.unwrap(), pSlippageArray[i].unwrap(), 0.0002e18, 18);
    //     }

    //     // SD59x18 baseStep = sd(22408439.25e18).div(getMarketSpotPrice(marketId).intoSD59x18());
    //     // baseStep = baseStep.sub(baseStep.mod(baseSpacing.intoSD59x18()));

    //     // // solhint-disable-next-line no-console
    //     // console2.log("base step", baseStep.unwrap());

    //     // UD60x18 orderPrice;
    //     // SD59x18 pSlippage;
    //     // vm.expectRevert();
    //     // (orderPrice, pSlippage) = executeCoreMatchOrder({
    //     //     sender: user,
    //     //     base: baseStep,
    //     //     priceLimit: getPriceLimit(baseStep),
    //     //     accountId: accountId
    //     // });
    // }
}
