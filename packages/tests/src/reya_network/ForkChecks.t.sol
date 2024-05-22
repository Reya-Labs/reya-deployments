pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { IERC20TokenModule } from "../interfaces/IERC20TokenModule.sol";
import { IOwnerUpgradeModule } from "../interfaces/IOwnerUpgradeModule.sol";
import {
    ICoreProxy,
    CommandType,
    Command as Command_Core,
    RiskMultipliers,
    MarginInfo,
    CollateralInfo,
    CollateralConfig,
    ParentCollateralConfig,
    CachedCollateralConfig
} from "../interfaces/ICoreProxy.sol";
import { ISocketExecutionHelper } from "../interfaces/ISocketExecutionHelper.sol";
import { ISocketControllerWithPayload } from "../interfaces/ISocketControllerWithPayload.sol";
import {
    IPeripheryProxy,
    DepositPassivePoolInputs,
    PeripheryExecutionInputs,
    DepositNewMAInputs,
    Command as Command_Periphery,
    EIP712Signature,
    GlobalConfiguration,
    WithdrawMAInputs,
    DepositExistingMAInputs
} from "../interfaces/IPeripheryProxy.sol";
import { IPassivePoolProxy } from "../interfaces/IPassivePoolProxy.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../interfaces/IPassivePerpProxy.sol";
import { IRUSDProxy } from "../interfaces/IRUSDProxy.sol";
import { IOracleManagerProxy, NodeOutput, NodeDefinition } from "../interfaces/IOracleManagerProxy.sol";

import { mockCoreCalculateDigest, hashExecuteBySigExtended, EIP712Signature } from "./../utils/SignatureHelpers.sol";

import { sd, SD59x18, UNIT as UNIT_sd, ZERO as ZERO_sd } from "@prb/math/SD59x18.sol";
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
    address weth = 0x6B48C2e6A32077ec17e8Ba0d98fFc676dfab1A30;

    mapping(address token => address controller) socketController;
    mapping(address token => address executionHelper) socketExecutionHelper;
    mapping(address token => mapping(uint256 chainId => address connector)) socketConnector;

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

        socketController[usdc] = 0x1d43076909Ca139BFaC4EbB7194518bE3638fc76;
        socketExecutionHelper[usdc] = 0x9ca48cAF8AD2B081a0b633d6FCD803076F719fEa;
        socketConnector[usdc][ethereumChainId] = 0x807B2e8724cDf346c87EEFF4E309bbFCb8681eC1;
        socketConnector[usdc][arbitrumChainId] = 0x663dc7E91157c58079f55C1BF5ee1BdB6401Ca7a;
        socketConnector[usdc][optimismChainId] = 0xe48AE3B68f0560d4aaA312E12fD687630C948561;
        socketConnector[usdc][polygonChainId] = 0x54CAA0946dA179425e1abB169C020004284d64D3;
        socketConnector[usdc][baseChainId] = 0x3694Ab37011764fA64A648C2d5d6aC0E9cD5F98e;

        socketController[weth] = 0xF0E49Dafc687b5ccc8B31b67d97B5985D1cAC4CB;
        socketExecutionHelper[weth] = 0xBE35E24dde70aFc6e07DF7e7BD8Ce723e1712771;
        socketConnector[weth][ethereumChainId] = 0x7dE4937420935c7C8767b06eCd7F7dC54e2D7C9b;
        socketConnector[weth][arbitrumChainId] = 0xd95c5254Df051f378696100a7D7f29505e5cF5c9;
        socketConnector[weth][optimismChainId] = 0xDee306Cf6C908d5F4f2c4A92d6Dc19035fE552EC;
        socketConnector[weth][polygonChainId] = 0x530654F6e96198bC269074156b321d8B91d10366;
        socketConnector[weth][baseChainId] = 0x2b3A8ABa1E055e879594cB2767259e80441E0497;
    }

    function testFuzz_USDCMintBurn(address attacker) public {
        vm.assume(attacker != socketController[usdc]);

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e6;

        uint256 totalSupplyBefore = IERC20TokenModule(usdc).totalSupply();

        // mint
        vm.prank(socketController[usdc]);
        IERC20TokenModule(usdc).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(usdc).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(usdc).mint(user, amount);

        // burn
        vm.prank(socketController[usdc]);
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

    function testFuzz_WETHMintBurn(address attacker) public {
        vm.assume(attacker != socketController[weth]);

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(weth).totalSupply();

        // mint
        vm.prank(socketController[weth]);
        IERC20TokenModule(weth).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(weth).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(weth).mint(user, amount);

        // burn
        vm.prank(socketController[weth]);
        IERC20TokenModule(weth).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(weth).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(weth).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(weth).totalSupply();
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

        assertEq(IPeripheryProxy(periphery).getTokenController(usdc), socketController[usdc]);
        assertEq(IPeripheryProxy(periphery).getTokenExecutionHelper(usdc), socketExecutionHelper[usdc]);
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, ethereumChainId),
            socketConnector[usdc][ethereumChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, arbitrumChainId),
            socketConnector[usdc][arbitrumChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, optimismChainId),
            socketConnector[usdc][optimismChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, polygonChainId),
            socketConnector[usdc][polygonChainId]
        );
        assertEq(
            IPeripheryProxy(periphery).getTokenChainConnector(usdc, baseChainId), socketConnector[usdc][baseChainId]
        );
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
        assertApproxEqAbsDecimal(ethUsdNodeOutput.price, 3500e18, 1000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, btcUsdNodeOutput.timestamp);
        assertLe(btcUsdNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdNodeOutput.price, 65_000e18, 10_000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, ethUsdcNodeOutput.timestamp);
        assertLe(ethUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(ethUsdcNodeOutput.price, 3500e18, 1000e18, 18);

        assertLe(block.timestamp - ONE_MINUTE_IN_SECONDS, btcUsdcNodeOutput.timestamp);
        assertLe(btcUsdcNodeOutput.timestamp, block.timestamp);
        assertApproxEqAbsDecimal(btcUsdcNodeOutput.price, 65_000e18, 10_000e18, 18);

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
        vm.prank(socketExecutionHelper[usdc]);
        vm.mockCall(
            socketExecutionHelper[usdc], abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()), abi.encode(amount)
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

    function mockBridgedAmount(address executionHelper, uint256 amount) internal {
        vm.mockCall(
            executionHelper, abi.encodeWithSelector(ISocketExecutionHelper.bridgeAmount.selector), abi.encode(amount)
        );
    }

    // stack too deep
    address user;
    uint256 userPk;
    uint128 collateralPoolId;
    uint128 exchangeId;
    RiskMultipliers riskMultipliers;
    UD60x18 liquidationMarginRequirement;
    UD60x18 imr;
    UD60x18 leverage;
    NodeOutput.Data nodeOutput;
    UD60x18 price;
    UD60x18 absBase;
    MarketConfigurationData marketConfig;
    int64[][] marketRiskMatrix;
    uint256 passivePoolImMultiplier;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes32 digest;
    uint256 socketMsgGasLimit;

    function getMarketSpotPrice(uint128 marketId) internal returns (UD60x18 marketSpotPrice) {
        marketConfig = IPassivePerpProxy(perp).getMarketConfiguration(marketId);
        NodeOutput.Data memory marketNodeOutput = IOracleManagerProxy(oracleManager).process(marketConfig.oracleNodeId);
        return ud(marketNodeOutput.price);
    }

    function getPriceLimit(SD59x18 base) internal pure returns (UD60x18 priceLimit) {
        if (base.gt(ZERO_sd)) {
            return ud(type(uint256).max);
        }

        return ud(0);
    }

    function executePeripheryMatchOrder(
        uint256 userPrivateKey,
        uint256 incrementedNonce,
        uint128 marketId,
        SD59x18 base,
        UD60x18 priceLimit,
        uint128 accountId
    )
        internal
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

        digest = mockCoreCalculateDigest(
            core,
            hashExecuteBySigExtended(
                address(periphery), accountId, commands, incrementedNonce, deadline, keccak256(abi.encode())
            )
        );
        (v, r, s) = vm.sign(userPrivateKey, digest);

        IPeripheryProxy(periphery).execute(
            PeripheryExecutionInputs({
                accountId: accountId,
                commands: commands,
                sig: EIP712Signature({ v: v, r: r, s: s, deadline: deadline })
            })
        );
    }

    function executeCoreMatchOrder(
        uint128 marketId,
        address sender,
        SD59x18 base,
        UD60x18 priceLimit,
        uint128 accountId
    )
        internal
        returns (UD60x18 orderPrice, SD59x18 pSlippage)
    {
        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = passivePoolAccountId;
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

    function notionalToBase(uint128 marketId, SD59x18 notional) internal returns (SD59x18 base) {
        base = notional.div(getMarketSpotPrice(marketId).intoSD59x18());
    }

    function baseToNotional(uint128 marketId, SD59x18 base) private returns (SD59x18 notional) {
        notional = base.mul(getMarketSpotPrice(marketId).intoSD59x18());
    }

    function test_trade_rusdCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e6; // denominated in rusd/usdc
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(usdc, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[usdc], amount);
        vm.prank(socketExecutionHelper[usdc]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

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

    function test_trade_rusdCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 60_000e6; // denominated in rusd/usdc
        uint128 marketId = 2; // btc
        exchangeId = 1; // passive pool
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(usdc, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[usdc], amount);
        vm.prank(socketExecutionHelper[usdc]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

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

    function trade_slippage_helper(
        uint128 marketId,
        SD59x18[] memory s,
        SD59x18[] memory sPrime,
        UD60x18 eps
    )
        internal
    {
        assertEq(s.length, sPrime.length);

        (user, userPk) = makeAddrAndKey("user");
        collateralPoolId = 1;
        exchangeId = 1; // passive pool

        // deposit new margin account
        uint256 depositAmount = 100_000_000e18;
        deal(usdc, address(periphery), depositAmount);
        mockBridgedAmount(socketExecutionHelper[usdc], depositAmount);
        vm.prank(socketExecutionHelper[usdc]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        for (uint128 _marketId = 1; _marketId <= 2; _marketId += 1) {
            marketConfig = IPassivePerpProxy(perp).getMarketConfiguration(_marketId);

            // Step 1: Unwind any exposure of the pool
            SD59x18 poolBase =
                SD59x18.wrap(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base);

            if (poolBase.abs().gt(sd(int256(marketConfig.minimumOrderBase)))) {
                SD59x18 base = poolBase.sub(poolBase.mod(sd(int256(marketConfig.baseSpacing))));
                executeCoreMatchOrder({
                    marketId: _marketId,
                    sender: user,
                    base: base,
                    priceLimit: getPriceLimit(base),
                    accountId: accountId
                });

                poolBase =
                    SD59x18.wrap(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base);

                // assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base, 0);
            }
        }

        passivePoolImMultiplier = ICoreProxy(core).getAccountImMultiplier(passivePoolAccountId);
        marketRiskMatrix = ICoreProxy(core).getRiskBlockMatrixByMarket(marketId);

        // increase max open base
        marketConfig = IPassivePerpProxy(perp).getMarketConfiguration(marketId);
        marketConfig.maxOpenBase = 100_000_000e18;
        vm.prank(multisig);
        IPassivePerpProxy(perp).setMarketConfiguration(marketId, marketConfig);

        // Step 2: Get pool's TVL
        MarginInfo memory poolMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(passivePoolAccountId);
        SD59x18 passivePoolTVL = sd(poolMarginInfo.marginBalance);

        // Step 3: Compute the grid
        SD59x18 prevNotionalsSum = sd(0);
        for (uint256 i = 1; i < s.length; i += 1) {
            SD59x18 notional = s[i].div(UNIT_sd.add(s[i])).mul(
                sd(int256(marketConfig.depthFactor)).mul(passivePoolTVL).div(
                    sd(int256(passivePoolImMultiplier)).mul(
                        sd(marketRiskMatrix[marketConfig.riskMatrixIndex][marketConfig.riskMatrixIndex]).sqrt()
                    )
                )
            ).sub(prevNotionalsSum);
            SD59x18 base = notionalToBase(marketId, notional);
            base = base.sub(base.mod(sd(int256(marketConfig.baseSpacing))));

            UD60x18 orderPrice;
            SD59x18 pSlippage;
            (orderPrice, pSlippage) = executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: base,
                priceLimit: getPriceLimit(base),
                accountId: accountId
            });

            assertApproxEqAbsDecimal(pSlippage.unwrap(), sPrime[i].unwrap(), eps.unwrap(), 18);

            prevNotionalsSum = prevNotionalsSum.add(baseToNotional(marketId, base));
        }
    }

    function test_trade_slippage_eth_long() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(0.01e18);
        s[2] = sd(0.02e18);
        s[3] = sd(0.03e18);
        s[4] = sd(0.04e18);
        s[5] = sd(0.05e18);
        s[6] = sd(0.06e18);
        s[7] = sd(0.07e18);
        s[8] = sd(0.08e18);
        s[9] = sd(0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019938e18);
        sPrime[3] = sd(0.029726e18);
        sPrime[4] = sd(0.039287e18);
        sPrime[5] = sd(0.04855e18);
        sPrime[6] = sd(0.057455e18);
        sPrime[7] = sd(0.065957e18);
        sPrime[8] = sd(0.074025e18);
        sPrime[9] = sd(0.081639e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.00005e18) });
    }

    function test_trade_slippage_btc_long() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(0.01e18);
        s[2] = sd(0.02e18);
        s[3] = sd(0.03e18);
        s[4] = sd(0.04e18);
        s[5] = sd(0.05e18);
        s[6] = sd(0.06e18);
        s[7] = sd(0.07e18);
        s[8] = sd(0.08e18);
        s[9] = sd(0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(0.01e18);
        sPrime[2] = sd(0.019938e18);
        sPrime[3] = sd(0.029726e18);
        sPrime[4] = sd(0.039287e18);
        sPrime[5] = sd(0.04855e18);
        sPrime[6] = sd(0.057455e18);
        sPrime[7] = sd(0.065957e18);
        sPrime[8] = sd(0.074025e18);
        sPrime[9] = sd(0.081639e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.0007e18) });
    }

    function test_trade_slippage_eth_short() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        s[5] = sd(-0.05e18);
        s[6] = sd(-0.06e18);
        s[7] = sd(-0.07e18);
        s[8] = sd(-0.08e18);
        s[9] = sd(-0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019939e18);
        sPrime[3] = sd(-0.029729e18);
        sPrime[4] = sd(-0.039289e18);
        sPrime[5] = sd(-0.048542e18);
        sPrime[6] = sd(-0.057426e18);
        sPrime[7] = sd(-0.065889e18);
        sPrime[8] = sd(-0.073894e18);
        sPrime[9] = sd(-0.081417e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 1, s: s, sPrime: sPrime, eps: ud(0.00005e18) });
    }

    function test_trade_slippage_btc_short() public {
        SD59x18[] memory s = new SD59x18[](10);
        s[1] = sd(-0.01e18);
        s[2] = sd(-0.02e18);
        s[3] = sd(-0.03e18);
        s[4] = sd(-0.04e18);
        s[5] = sd(-0.05e18);
        s[6] = sd(-0.06e18);
        s[7] = sd(-0.07e18);
        s[8] = sd(-0.08e18);
        s[9] = sd(-0.09e18);
        // s[10] = sd(0.99e18);

        SD59x18[] memory sPrime = new SD59x18[](10);
        sPrime[1] = sd(-0.01e18);
        sPrime[2] = sd(-0.019939e18);
        sPrime[3] = sd(-0.029729e18);
        sPrime[4] = sd(-0.039289e18);
        sPrime[5] = sd(-0.048542e18);
        sPrime[6] = sd(-0.057426e18);
        sPrime[7] = sd(-0.065889e18);
        sPrime[8] = sd(-0.073894e18);
        sPrime[9] = sd(-0.081417e18);
        // sPrime[10] = sd(0.088702e18);

        trade_slippage_helper({ marketId: 2, s: s, sPrime: sPrime, eps: ud(0.0007e18) });
    }

    function test_weth_cap_exceeded() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 101e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.CollateralCapExceeded.selector, 1, weth, 100e18, amount));
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function executePeripheryWithdrawMA(
        address userAddress,
        uint256 userPrivateKey,
        uint256 incrementedNonce,
        uint128 accountId,
        address token,
        uint256 tokenAmount,
        uint256 chainId
    )
        private
    {
        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: uint8(CommandType.Withdraw),
            inputs: abi.encode(token, tokenAmount),
            marketId: 0,
            exchangeId: 0
        });

        socketMsgGasLimit = 10_000_000;

        digest = mockCoreCalculateDigest(
            core,
            hashExecuteBySigExtended(
                address(periphery),
                accountId,
                commands,
                incrementedNonce,
                block.timestamp + 3600,
                keccak256(abi.encode(userAddress, chainId, socketMsgGasLimit))
            )
        );
        (v, r, s) = vm.sign(userPrivateKey, digest);

        // vm.mockCall(
        //     periphery,
        //     abi.encodeWithSelector(
        //         ISocketControllerWithPayload.getMinFees.selector, socketConnector[token][chainId], socketMsgGasLimit,
        // 0
        //     ),
        //     abi.encode(0)
        // );

        uint256 staticFees =
            IPeripheryProxy(periphery).getTokenStaticWithdrawFee(token, socketConnector[token][chainId]);
        vm.mockCall(
            socketController[weth],
            abi.encodeWithSelector(
                ISocketControllerWithPayload.bridge.selector,
                userAddress,
                tokenAmount - staticFees,
                socketMsgGasLimit,
                socketConnector[token][chainId],
                abi.encode(),
                abi.encode()
            ),
            abi.encode()
        );

        IPeripheryProxy(periphery).withdrawMA(
            WithdrawMAInputs({
                accountId: accountId,
                token: token,
                tokenAmount: tokenAmount,
                sig: EIP712Signature({ v: v, r: r, s: s, deadline: block.timestamp + 3600 }),
                socketMsgGasLimit: socketMsgGasLimit,
                chainId: chainId,
                receiver: userAddress
            })
        );
    }

    function test_weth_deposit_withdraw() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 50e18; // denominated in weth

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        uint256 coreWethBalanceBefore = IERC20TokenModule(weth).balanceOf(core);
        uint256 peripheryWethBalanceBefore = IERC20TokenModule(weth).balanceOf(periphery);
        uint256 multisigWethBalanceBefore = IERC20TokenModule(weth).balanceOf(multisig);

        amount = 5e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, weth, amount, arbitrumChainId);

        uint256 coreWethBalanceAfter = IERC20TokenModule(weth).balanceOf(core);
        uint256 peripheryWethBalanceAfter = IERC20TokenModule(weth).balanceOf(periphery);
        uint256 multisigWethBalanceAfter = IERC20TokenModule(weth).balanceOf(multisig);
        uint256 withdrawStaticFees =
            IPeripheryProxy(periphery).getTokenStaticWithdrawFee(weth, socketConnector[weth][arbitrumChainId]);

        assertEq(coreWethBalanceBefore - coreWethBalanceAfter, amount);
        assertEq(multisigWethBalanceAfter - multisigWethBalanceBefore, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(peripheryWethBalanceAfter - peripheryWethBalanceBefore, amount - withdrawStaticFees);
    }

    function test_weth_view_functions() public {
        (user, userPk) = makeAddrAndKey("user");

        uint256 wethAmount = 1e18;

        // deposit new margin account
        deal(weth, address(periphery), wethAmount);
        mockBridgedAmount(socketExecutionHelper[weth], wethAmount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: weth }));

        vm.prank(user);
        ICoreProxy(core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdcNodeId);

        CollateralConfig memory collateralConfig;
        ParentCollateralConfig memory parentCollateralConfig;
        CachedCollateralConfig memory cacheCollateralConfig;

        (collateralConfig, parentCollateralConfig, cacheCollateralConfig) =
            ICoreProxy(core).getCollateralConfig(1, weth);
        SD59x18 wethAmountInUSD = sd(int256(wethAmount)).mul(sd(int256(ethUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, wethAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountWethCollateralInfo = ICoreProxy(core).getCollateralInfo(accountId, weth);
        assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
        assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
        assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));

        uint256 usdcAmount = 1000e6;
        deal(usdc, address(periphery), usdcAmount);
        mockBridgedAmount(socketExecutionHelper[usdc], usdcAmount);
        vm.prank(socketExecutionHelper[usdc]);
        IPeripheryProxy(periphery).depositExistingMA(DepositExistingMAInputs({ accountId: accountId, token: usdc }));

        accountUsdNodeMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, wethAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountWethCollateralInfo = ICoreProxy(core).getCollateralInfo(accountId, weth);
        assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
        assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
        assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));
    }

    function test_trade_wethCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 1e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

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

    function test_trade_wethCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18; // denominated in weth
        uint128 marketId = 2; // btc
        exchangeId = 1; // passive pool
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

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
}
