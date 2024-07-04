pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import "./DataTypes.sol";
import { StorageReyaForkTest } from "./StorageReyaForkTest.sol";

import { ICoreProxy, CommandType, Command as Command_Core, MarginInfo } from "../../src/interfaces/ICoreProxy.sol";

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

import { ud, UD60x18, ZERO as ZERO_ud } from "@prb/math/UD60x18.sol";
import { SD59x18, ZERO as ZERO_sd, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";

struct LocalState {
    MarketConfigurationData marketConfig;
    uint128[] counterpartyAccountIds;
    uint256 deadline;
    uint128 exchangeId;
    bytes[] outputs;
    bytes32 digest;
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 staticFees;
    uint256 socketMsgGasLimit;
    MarginInfo poolMarginInfo;
    UD60x18 sharePrice;
}

contract BaseReyaForkTest is StorageReyaForkTest {
    LocalState private s;

    function mockBridgedAmount(address executionHelper, uint256 amount) internal {
        vm.mockCall(
            executionHelper, abi.encodeWithSelector(ISocketExecutionHelper.bridgeAmount.selector), abi.encode(amount)
        );
    }

    function roundPrice(UD60x18 price, UD60x18 priceSpacing, bool roundUp) internal pure returns (UD60x18) {
        UD60x18 reminder = price.mod(priceSpacing);
        UD60x18 roundedDown = price.sub(reminder);

        if (reminder.eq(ZERO_ud) || !roundUp) {
            return roundedDown;
        }

        return roundedDown.add(priceSpacing);
    }

    function getMarketSpotPrice(uint128 marketId) internal view returns (UD60x18 marketSpotPrice) {
        MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        NodeOutput.Data memory marketNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(marketConfig.oracleNodeId);
        return ud(marketNodeOutput.price);
    }

    function getMarketSpotPrice(uint128 marketId, bool roundUp) internal view returns (UD60x18 marketSpotPrice) {
        MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        NodeOutput.Data memory marketNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(marketConfig.oracleNodeId);
        return roundPrice(ud(marketNodeOutput.price), ud(marketConfig.priceSpacing), roundUp);
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
        s.counterpartyAccountIds = new uint128[](1);
        s.counterpartyAccountIds[0] = sec.passivePoolAccountId;
        s.deadline = block.timestamp + 3600; // one hour

        s.exchangeId = 1;

        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: uint8(CommandType.MatchOrder),
            inputs: abi.encode(s.counterpartyAccountIds, abi.encode(base, priceLimit)),
            marketId: marketId,
            exchangeId: s.exchangeId
        });

        s.digest = mockCoreCalculateDigest(
            sec.core,
            hashExecuteBySigExtended(
                address(sec.periphery), accountId, commands, incrementedNonce, s.deadline, keccak256(abi.encode())
            )
        );

        (s.v, s.r, s.s) = vm.sign(userPrivateKey, s.digest);

        IPeripheryProxy(sec.periphery).execute(
            PeripheryExecutionInputs({
                accountId: accountId,
                commands: commands,
                sig: EIP712Signature({ v: s.v, r: s.r, s: s.s, deadline: s.deadline })
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
        s.counterpartyAccountIds = new uint128[](1);
        s.counterpartyAccountIds[0] = sec.passivePoolAccountId;
        s.exchangeId = 1; // passive pool

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = Command_Core({
            commandType: uint8(CommandType.MatchOrder),
            inputs: abi.encode(s.counterpartyAccountIds, abi.encode(base, priceLimit)),
            marketId: marketId,
            exchangeId: s.exchangeId
        });

        vm.prank(sender);

        (s.outputs,) = ICoreProxy(sec.core).execute(accountId, commands);

        orderPrice = UD60x18.wrap(abi.decode(s.outputs[0], (uint256)));
        pSlippage = orderPrice.div(getMarketSpotPrice(marketId, base.gt(ZERO_sd))).intoSD59x18().sub(UNIT_sd);
    }

    function exposureToBase(uint128 marketId, SD59x18 exposure) internal view returns (SD59x18) {
        return exposure.div(getMarketSpotPrice(marketId).intoSD59x18());
    }

    function baseToExposure(uint128 marketId, SD59x18 base) internal view returns (SD59x18) {
        return base.mul(getMarketSpotPrice(marketId).intoSD59x18());
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

        s.socketMsgGasLimit = 10_000_000;

        s.digest = mockCoreCalculateDigest(
            sec.core,
            hashExecuteBySigExtended(
                address(sec.periphery),
                accountId,
                commands,
                incrementedNonce,
                block.timestamp + 3600,
                keccak256(abi.encode(userAddress, chainId, s.socketMsgGasLimit))
            )
        );

        (s.v, s.r, s.s) = vm.sign(userPrivateKey, s.digest);

        s.staticFees =
            IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(token, dec.socketConnector[token][chainId]);

        vm.mockCall(
            dec.socketController[sec.weth],
            abi.encodeWithSelector(
                ISocketControllerWithPayload.bridge.selector,
                userAddress,
                tokenAmount - s.staticFees,
                s.socketMsgGasLimit,
                dec.socketConnector[token][chainId],
                abi.encode(),
                abi.encode()
            ),
            abi.encode()
        );

        IPeripheryProxy(sec.periphery).withdrawMA(
            WithdrawMAInputs({
                accountId: accountId,
                token: token,
                tokenAmount: tokenAmount,
                sig: EIP712Signature({ v: s.v, r: s.r, s: s.s, deadline: block.timestamp + 3600 }),
                socketMsgGasLimit: s.socketMsgGasLimit,
                chainId: chainId,
                receiver: userAddress
            })
        );
    }

    function checkPoolHealth() internal {
        s.poolMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(sec.passivePoolAccountId);
        assertGtDecimal(uint256(s.poolMarginInfo.liquidationDelta), 0, 18);
        assertGtDecimal(uint256(s.poolMarginInfo.initialDelta), 0, 18);

        s.sharePrice = ud(IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId));
        assertGtDecimal(s.sharePrice.unwrap(), 0.99e18, 18);
    }
}
