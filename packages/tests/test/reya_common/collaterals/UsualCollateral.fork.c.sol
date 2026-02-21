pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { ICoreProxy, ParentCollateralConfig, MarginInfo, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    uint256 coreTokenBalance0;
    uint256 coreTokenBalance1;
    uint256 peripheryTokenBalance0;
    uint256 peripheryTokenBalance1;
    uint256 multisigTokenBalance0;
    uint256 multisigTokenBalance1;
}

contract UsualCollateralForkCheck is BaseReyaForkTest {
    LocalState private s;

    function checkFuzz_UsualCollateral_MintBurn(address token, address attacker) private {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = ITokenProxy(token).totalSupply();

        // mint
        vm.prank(dec.socketController[token]);
        ITokenProxy(token).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(token).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(token).mint(user, amount);

        // burn
        vm.prank(dec.socketController[token]);
        ITokenProxy(token).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(token).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(token).burn(user, amount);

        uint256 totalSupplyAfter = ITokenProxy(token).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function check_UsualCollateral_ViewFunctions(address token, bytes32 tokenStorkNodeId) private {
        removeCollateralCap(token);
        (address user,) = makeAddrAndKey("user");

        uint256 tokenAmount = 1e18;

        // deposit new margin account
        deal(token, address(sec.periphery), tokenAmount);
        mockBridgedAmount(dec.socketExecutionHelper[token], tokenAmount);
        vm.prank(dec.socketExecutionHelper[token]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: token }));

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory tokenUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(tokenStorkNodeId);

        (, ParentCollateralConfig memory parentCollateralConfig,) = ICoreProxy(sec.core).getCollateralConfig(1, token);
        SD59x18 tokenAmountInUSD = sd(int256(tokenAmount)).mul(sd(int256(tokenUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, tokenAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountTokenCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, token);
        assertEq(accountTokenCollateralInfo.netDeposits, int256(tokenAmount));
        assertEq(accountTokenCollateralInfo.marginBalance, int256(tokenAmount));
        assertEq(accountTokenCollateralInfo.realBalance, int256(tokenAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, tokenAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountTokenCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, token);
        assertEq(accountTokenCollateralInfo.netDeposits, int256(tokenAmount));
        assertEq(accountTokenCollateralInfo.marginBalance, int256(tokenAmount));
        assertEq(accountTokenCollateralInfo.realBalance, int256(tokenAmount));
    }

    function check_UsualCollateral_CapExceeded(address token, uint256 tokenCap) private {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 50_000_001e18; // denominated in token
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolTokenBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, token);

        // deposit new margin account
        deal(token, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[token], amount);
        vm.prank(dec.socketExecutionHelper[token]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: token }));

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector, 1, token, tokenCap, collateralPoolTokenBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_UsualCollateral_DepositWithdraw(address token) private {
        removeCollateralWithdrawalLimit(token);

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1000e18; // denominated in token

        // deposit new margin account
        deal(token, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[token], amount);
        vm.prank(dec.socketExecutionHelper[token]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: token }));

        s.coreTokenBalance0 = ITokenProxy(token).balanceOf(sec.core);
        s.peripheryTokenBalance0 = ITokenProxy(token).balanceOf(sec.periphery);
        s.multisigTokenBalance0 = ITokenProxy(token).balanceOf(sec.multisig);

        amount = 100e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, token, amount, sec.destinationChainId);

        s.coreTokenBalance1 = ITokenProxy(token).balanceOf(sec.core);
        s.peripheryTokenBalance1 = ITokenProxy(token).balanceOf(sec.periphery);
        s.multisigTokenBalance1 = ITokenProxy(token).balanceOf(sec.multisig);
        uint256 withdrawStaticFees = IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(
            token, dec.socketConnector[token][sec.destinationChainId]
        );

        assertEq(s.coreTokenBalance0 - s.coreTokenBalance1, amount);
        assertEq(s.multisigTokenBalance1 - s.multisigTokenBalance0, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(s.peripheryTokenBalance1 - s.peripheryTokenBalance0, amount - withdrawStaticFees);
    }

    function check_trade_UsualCollateral_DepositWithdraw(address token) private {
        mockFreshPrices();
        removeCollateralWithdrawalLimit(token);
        removeCollateralCap(token);

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e18; // denominated in token
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(token, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[token], amount);
        vm.prank(dec.socketExecutionHelper[token]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: token }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        amount = 100e18;
        executePeripheryWithdrawMA(user, userPk, 2, accountId, token, amount, sec.destinationChainId);

        checkPoolHealth();
    }

    function checkFuzz_deusd_MintBurn(address attacker) public {
        checkFuzz_UsualCollateral_MintBurn(sec.deusd, attacker);
    }

    function check_deusd_ViewFunctions() public {
        check_UsualCollateral_ViewFunctions(sec.deusd, sec.deusdUsdcStorkNodeId);
    }

    function check_deusd_CapExceeded() public {
        // note: this test is not relevant as cap is not set for this token
        // check_UsualCollateral_CapExceeded(sec.deusd);
    }

    function check_deusd_DepositWithdraw() public {
        check_UsualCollateral_DepositWithdraw(sec.deusd);
    }

    function check_trade_deusd_DepositWithdraw() public {
        check_trade_UsualCollateral_DepositWithdraw(sec.deusd);
    }

    function checkFuzz_sdeusd_MintBurn(address attacker) public {
        checkFuzz_UsualCollateral_MintBurn(sec.sdeusd, attacker);
    }

    function check_sdeusd_ViewFunctions() public {
        check_UsualCollateral_ViewFunctions(sec.sdeusd, sec.sdeusdUsdcStorkNodeId);
    }

    function check_sdeusd_CapExceeded() public {
        // note: this test is not relevant as cap is not set for this token
        // check_UsualCollateral_CapExceeded(sec.sdeusd);
    }

    function check_sdeusd_DepositWithdraw() public {
        check_UsualCollateral_DepositWithdraw(sec.sdeusd);
    }

    function check_trade_sdeusd_DepositWithdraw() public {
        check_trade_UsualCollateral_DepositWithdraw(sec.sdeusd);
    }

    function checkFuzz_susde_MintBurn(address attacker) public {
        checkFuzz_UsualCollateral_MintBurn(sec.susde, attacker);
    }

    function check_susde_ViewFunctions() public {
        check_UsualCollateral_ViewFunctions(sec.susde, sec.susdeUsdcStorkNodeId);
    }

    function check_susde_CapExceeded() public {
        // TODO: update cap
        check_UsualCollateral_CapExceeded(sec.susde, 7_500_000e18);
    }

    function check_susde_DepositWithdraw() public {
        check_UsualCollateral_DepositWithdraw(sec.susde);
    }

    function check_trade_susde_DepositWithdraw() public {
        check_trade_UsualCollateral_DepositWithdraw(sec.susde);
    }

    function checkFuzz_usde_MintBurn(address attacker) public {
        checkFuzz_UsualCollateral_MintBurn(sec.usde, attacker);
    }

    function check_usde_ViewFunctions() public {
        check_UsualCollateral_ViewFunctions(sec.usde, sec.usdeUsdcStorkNodeId);
    }

    function check_usde_CapExceeded() public {
        check_UsualCollateral_CapExceeded(sec.usde, 1000e18);
    }

    function check_usde_DepositWithdraw() public {
        check_UsualCollateral_DepositWithdraw(sec.usde);
    }

    function check_trade_usde_DepositWithdraw() public {
        check_trade_UsualCollateral_DepositWithdraw(sec.usde);
    }

    function checkFuzz_wbtc_MintBurn(address attacker) public {
        checkFuzz_UsualCollateral_MintBurn(sec.wbtc, attacker);
    }

    function checkFuzz_weth_MintBurn(address attacker) public {
        checkFuzz_UsualCollateral_MintBurn(sec.weth, attacker);
    }

    function check_weth_ViewFunctions() public {
        check_UsualCollateral_ViewFunctions(sec.weth, sec.ethUsdcStorkNodeId);
    }

    function check_weth_CapExceeded() public {
        check_UsualCollateral_CapExceeded(sec.weth, 5e18);
    }

    function check_weth_DepositWithdraw() public {
        check_UsualCollateral_DepositWithdraw(sec.weth);
    }

    function check_trade_weth_DepositWithdraw() public {
        check_trade_UsualCollateral_DepositWithdraw(sec.weth);
    }

    function checkFuzz_wsteth_MintBurn(address attacker) public {
        checkFuzz_UsualCollateral_MintBurn(sec.wsteth, attacker);
    }

    function check_wsteth_ViewFunctions() public {
        check_UsualCollateral_ViewFunctions(sec.wsteth, sec.wstethUsdcStorkNodeId);
    }

    function check_wsteth_CapExceeded() public {
        check_UsualCollateral_CapExceeded(sec.wsteth, 225e18);
    }

    function check_wsteth_DepositWithdraw() public {
        check_UsualCollateral_DepositWithdraw(sec.wsteth);
    }

    function check_trade_wsteth_DepositWithdraw() public {
        check_trade_UsualCollateral_DepositWithdraw(sec.wsteth);
    }
}
