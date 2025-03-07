pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import "./DataTypes.sol";
import { StorageReyaForkTest } from "./StorageReyaForkTest.sol";

import {
    ICoreProxy,
    CommandType,
    Command as Command_Core,
    MarginInfo,
    CollateralConfig,
    ParentCollateralConfig,
    GlobalCollateralConfig,
    ManagePoolStakeCommand
} from "../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy,
    PeripheryExecutionInputs,
    Command as Command_Periphery,
    EIP712Signature,
    WithdrawMAInputs,
    DepositNewMAInputs,
    DepositPassivePoolInputs,
    DepositLiquidityToAccountInputs,
    WithdrawLiquidityFromAccountInputs
} from "../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../src/interfaces/IOracleManagerProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../src/interfaces/IPassivePerpProxy.sol";

import { IPassivePoolProxy } from "../../src/interfaces/IPassivePoolProxy.sol";

import { CoreCommandHashing } from "../../src/utils/CoreCommandHashing.sol";
import { PoolHashing } from "../../src/utils/PoolHashing.sol";

import { ISocketExecutionHelper } from "../../src/interfaces/ISocketExecutionHelper.sol";
import { ISocketControllerWithPayload } from "../../src/interfaces/ISocketControllerWithPayload.sol";

import { ud, UD60x18, ZERO as ZERO_ud } from "@prb/math/UD60x18.sol";
import { SD59x18, ZERO as ZERO_sd, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";

import { ITokenProxy } from "../../src/interfaces/ITokenProxy.sol";

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
        return roundPrice(ud(marketNodeOutput.price), ud(marketConfig.priceSpacing), false);
    }

    function getPriceLimit(SD59x18 base) internal pure returns (UD60x18 priceLimit) {
        if (base.gt(ZERO_sd)) {
            return ud(type(uint256).max);
        }

        return ud(0);
    }

    function isLmToken(address collateral) internal view returns (bool) {
        return collateral == sec.rselini || collateral == sec.ramber;
    }

    function depositNewMA(address user, address collateral, uint256 amount) internal returns (uint128 accountId) {
        if (isLmToken(collateral) || collateral == sec.srusd) {
            deal(collateral, address(user), amount);
            vm.prank(user);
            accountId = ICoreProxy(sec.core).createAccount(user);
            vm.prank(user);
            ITokenProxy(collateral).approve(sec.core, amount);
            vm.prank(user);
            ICoreProxy(sec.core).deposit({ accountId: accountId, collateral: collateral, amount: amount });
        } else {
            deal(collateral, address(sec.periphery), amount);
            mockBridgedAmount(dec.socketExecutionHelper[collateral], amount);
            vm.prank(dec.socketExecutionHelper[collateral]);
            accountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(collateral) })
            );
        }
    }

    function withdrawMA(uint128 accountId, address collateral, uint256 amount) internal {
        address accountOwner = ICoreProxy(sec.core).getAccountOwner(accountId);

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = Command_Core({
            commandType: uint8(CommandType.Withdraw),
            inputs: abi.encode(collateral, amount),
            marketId: 0,
            exchangeId: 0
        });
        vm.prank(accountOwner);
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    function getMatchOrderPeripheryCommand(
        uint128 marketId,
        SD59x18 base,
        UD60x18 priceLimit
    )
        internal
        view
        returns (Command_Periphery memory command)
    {
        uint128[] memory counterpartyAccountIds = new uint128[](1);
        counterpartyAccountIds[0] = sec.passivePoolAccountId;

        return Command_Periphery({
            commandType: uint8(CommandType.MatchOrder),
            inputs: abi.encode(counterpartyAccountIds, abi.encode(base, priceLimit)),
            marketId: marketId,
            exchangeId: 1 // passive pool
         });
    }

    function getEIP712SignatureForPeripheryCommands(
        uint128 accountId,
        Command_Periphery[] memory commands,
        uint256 userPrivateKey,
        uint256 incrementedNonce,
        bytes memory extraData
    )
        internal
        view
        returns (EIP712Signature memory sig)
    {
        uint256 deadline = block.timestamp + 3600; // one hour
        bytes32 digest = CoreCommandHashing.mockCalculateDigest(
            address(sec.periphery), accountId, commands, incrementedNonce, deadline, keccak256(extraData), sec.core
        );
        (uint8 sv, bytes32 sr, bytes32 ss) = vm.sign(userPrivateKey, digest);
        sig = EIP712Signature({ v: sv, r: sr, s: ss, deadline: deadline });
    }

    function getEIP712SignatureForPool(
        address user,
        uint256 userPrivateKey,
        uint256 sharesAmount,
        uint256 minOut,
        uint256 incrementedNonce,
        bytes memory extraData
    )
        internal
        view
        returns (EIP712Signature memory sig)
    {
        uint256 deadline = block.timestamp + 3600; // one hour
        bytes32 digest = PoolHashing.mockCalculateDigest(
            address(sec.periphery),
            user,
            sec.passivePoolId,
            sharesAmount,
            minOut,
            incrementedNonce,
            deadline,
            extraData,
            sec.pool
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        sig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });
    }

    function executePeripheryCommands(
        uint128 accountId,
        Command_Periphery[] memory commands,
        uint256 userPrivateKey,
        uint256 incrementedNonce
    )
        internal
    {
        IPeripheryProxy(sec.periphery).execute(
            PeripheryExecutionInputs({
                accountId: accountId,
                commands: commands,
                sig: getEIP712SignatureForPeripheryCommands(
                    accountId, commands, userPrivateKey, incrementedNonce, abi.encode()
                )
            })
        );
    }

    function getNetDeposits(uint128 accountId, address collateral) internal view returns (int256) {
        return ICoreProxy(sec.core).getCollateralInfo(accountId, collateral).netDeposits;
    }

    function executePeripheryStakeAccount(
        uint256 userPrivateKey,
        uint256 incrementedNonce,
        uint128 poolId,
        uint256 amount,
        uint256 minShares,
        uint128 accountId
    )
        internal
    {
        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: uint8(CommandType.ManagePoolStake),
            inputs: abi.encode(ManagePoolStakeCommand.Stake, abi.encode(poolId, amount, minShares)),
            marketId: 0,
            exchangeId: 0
        });
        executePeripheryCommands(accountId, commands, userPrivateKey, incrementedNonce);
    }

    function executePeripheryUnstakeAccount(
        uint256 userPrivateKey,
        uint256 incrementedNonce,
        uint128 poolId,
        uint256 sharesAmount,
        uint256 minOut,
        uint128 accountId
    )
        internal
    {
        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: uint8(CommandType.ManagePoolStake),
            inputs: abi.encode(ManagePoolStakeCommand.Unstake, abi.encode(poolId, sharesAmount, minOut)),
            marketId: 0,
            exchangeId: 0
        });
        executePeripheryCommands(accountId, commands, userPrivateKey, incrementedNonce);
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
        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = getMatchOrderPeripheryCommand(marketId, base, priceLimit);
        executePeripheryCommands(accountId, commands, userPrivateKey, incrementedNonce);
    }

    function convertCoreCommandToPeripheryCommand(Command_Core memory command)
        internal
        pure
        returns (Command_Periphery memory)
    {
        return Command_Periphery({
            commandType: command.commandType,
            inputs: command.inputs,
            marketId: command.marketId,
            exchangeId: command.exchangeId
        });
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
        pSlippage = orderPrice.div(getMarketSpotPrice(marketId)).intoSD59x18().sub(UNIT_sd);
    }

    function executePeripheryAddLiquidity(address user, uint256 amount, uint256 minShares) internal {
        deal(sec.usdc, sec.periphery, amount);
        DepositPassivePoolInputs memory inputs =
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: minShares });
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(amount)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(inputs);
    }

    function executePeripheryDepositLiquidityToAccount(
        address user,
        uint256 userPrivateKey,
        uint256 incrementedNonce,
        uint256 sharesAmount,
        uint128 accountId
    )
        internal
    {
        IPeripheryProxy(sec.periphery).depositLiquidityToAccount(
            DepositLiquidityToAccountInputs({
                accountId: accountId,
                poolId: sec.passivePoolId,
                sharesAmount: sharesAmount,
                sig: getEIP712SignatureForPool(
                    user,
                    userPrivateKey,
                    sharesAmount,
                    0,
                    incrementedNonce,
                    abi.encode("DepositLiquidityToAccount", accountId, sec.passivePoolId, sharesAmount)
                )
            })
        );
    }

    function executePeripheryWithdrawLiquidityFromAccount(
        address user,
        uint256 userPrivateKey,
        uint256 incrementedNonce,
        uint256 sharesAmount,
        uint128 accountId
    )
        internal
    {
        Command_Periphery[] memory commands = new Command_Periphery[](1);
        commands[0] = Command_Periphery({
            commandType: uint8(CommandType.Withdraw),
            inputs: abi.encode(sec.srusd, sharesAmount),
            marketId: 0,
            exchangeId: 0
        });
        IPeripheryProxy(sec.periphery).withdrawLiquidityFromAccount(
            WithdrawLiquidityFromAccountInputs({
                accountId: accountId,
                poolId: sec.passivePoolId,
                sharesAmount: sharesAmount,
                sig: getEIP712SignatureForPeripheryCommands(
                    accountId,
                    commands,
                    userPrivateKey,
                    incrementedNonce,
                    abi.encode("WithdrawLiquidityFromAccount", accountId, sec.passivePoolId, sharesAmount)
                )
            })
        );
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

        s.digest = CoreCommandHashing.mockCalculateDigest(
            address(sec.periphery),
            accountId,
            commands,
            incrementedNonce,
            block.timestamp + 3600,
            keccak256(abi.encode(userAddress, chainId, s.socketMsgGasLimit)),
            sec.core
        );

        (s.v, s.r, s.s) = vm.sign(userPrivateKey, s.digest);

        s.staticFees =
            IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(token, dec.socketConnector[token][chainId]);

        vm.mockCall(
            dec.socketController[token],
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

    function mockFreshPrices() internal {
        for (uint128 i = 1; i <= lastMarketId(); i++) {
            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);
            bytes32 nodeId = marketConfig.oracleNodeId;

            NodeOutput.Data memory output = IOracleManagerProxy(sec.oracleManager).process(nodeId);

            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (nodeId)),
                abi.encode(NodeOutput.Data({ price: output.price, timestamp: block.timestamp }))
            );
        }
    }

    function removeCollateralCap(address collateral) internal {
        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, collateral);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, collateral, collateralConfig, parentCollateralConfig);
    }

    function removeCollateralWithdrawalLimit(address collateral) internal {
        (GlobalCollateralConfig memory globalCollateralConfig,) =
            ICoreProxy(sec.core).getGlobalCollateralConfig(collateral);

        vm.prank(sec.multisig);
        globalCollateralConfig.withdrawalWindowSize = 0;
        globalCollateralConfig.withdrawalTvlPercentageLimit = 1e18;
        ICoreProxy(sec.core).setGlobalCollateralConfig(collateral, globalCollateralConfig);
    }

    function removeMarketsOILimit() internal {
        for (uint128 i = 1; i <= lastMarketId(); i++) {
            MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(i);
            marketConfig.maxOpenBase = 1_000_000_000_000e18;
            vm.prank(sec.multisig);
            IPassivePerpProxy(sec.perp).setMarketConfiguration(i, marketConfig);
        }
    }

    function lastMarketId() internal view returns (uint128) {
        return ICoreProxy(sec.core).getLastCreatedMarketId();
    }
}
