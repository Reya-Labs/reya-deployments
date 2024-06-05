pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import {
    ICoreProxy,
    CommandType,
    Command as Command_Core,
    RiskMultipliers,
    MarginInfo
} from "../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy,
    PeripheryExecutionInputs,
    Command as Command_Periphery,
    EIP712Signature,
    WithdrawMAInputs
} from "../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../src/interfaces/IOracleManagerProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../src/interfaces/IPassivePerpProxy.sol";

import { IPassivePoolProxy } from "../../src/interfaces/IPassivePoolProxy.sol";

import {
    mockCoreCalculateDigest, hashExecuteBySigExtended, EIP712Signature
} from "../../src/utils/SignatureHelpers.sol";

import { ISocketExecutionHelper } from "../../src/interfaces/ISocketExecutionHelper.sol";
import { ISocketControllerWithPayload } from "../../src/interfaces/ISocketControllerWithPayload.sol";

import { ud, UD60x18 } from "@prb/math/UD60x18.sol";
import { SD59x18, ZERO as ZERO_sd, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";

// todo: move util function from this contract to util files
contract ReyaForkTest is Test {
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
    address wbtc = 0xa6Cf523f856f4a0aaB78848e251C1b042E6406d5;

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
        
        socketController[wbtc] = 0xBF839f4dfF854F7a363A033D57ec872dC8556693;
        socketExecutionHelper[wbtc] = 0xd947Dd2f18366F3FD1f2a707d3CA58F762D60519;
        socketConnector[wbtc][ethereumChainId] = 0xD71629697B71E2Df26B4194f43F6eaed3B367ac0;
        socketConnector[wbtc][arbitrumChainId] = 0x42229a5DDC5E32149311265F6F4BC016EaB778FC;
        socketConnector[wbtc][optimismChainId] = 0xA6BFB87A0db4693a4145df4F627c8FEe30aC7eDF;
        socketConnector[wbtc][polygonChainId] = 0xA30e479EbfD576EDd69afB636d16926a05214149;
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

    // TODO Alex: replace notional by base to be consistent with core
    function notionalToBase(uint128 marketId, SD59x18 notional) internal returns (SD59x18 base) {
        base = notional.div(getMarketSpotPrice(marketId).intoSD59x18());
    }

    function baseToNotional(uint128 marketId, SD59x18 base) internal returns (SD59x18 notional) {
        notional = base.mul(getMarketSpotPrice(marketId).intoSD59x18());
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
        internal
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

    function checkPoolHealth() internal view {
        MarginInfo memory poolMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(passivePoolAccountId);
        assertGtDecimal(uint256(poolMarginInfo.liquidationDelta), 0, 18);
        assertGtDecimal(uint256(poolMarginInfo.initialDelta), 0, 18);

        UD60x18 sharePrice = ud(IPassivePoolProxy(pool).getSharePrice(passivePoolId));
        assertGtDecimal(sharePrice.unwrap(), 0.99e18, 18);
    }
}
