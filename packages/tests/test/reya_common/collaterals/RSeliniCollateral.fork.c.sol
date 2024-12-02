pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IShareTokenProxy, SubscriptionInputs, RedemptionInputs } from "../../../src/interfaces/IShareTokenProxy.sol";
import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

struct LocalState {
    uint256 rseliniTotalSupply;
    uint256 rseliniRecipientBalance1;
    uint256 rUsdSubscriberBalance;
    uint256 rUsdCustodianBalance;
    uint256 rUsdRecipientBalance2;
}

contract RSeliniCollateralForkCheck is BaseReyaForkTest {
    LocalState private s0;
    LocalState private s1;

    // TODO: check no one can mint or burn shares (fuzz test)

    function check_rseliniRedemptionAndSubscription() public {
        address recipient1 = vm.addr(123);
        address recipient2 = vm.addr(456);

        // mint 100 rusd for the subscriber
        deal(sec.rusd, address(sec.rseliniSubscriber), 100e6);

        // subscriber approve 100 rusd to rSelini token
        vm.prank(sec.rseliniSubscriber);
        IERC20TokenModule(sec.rusd).approve(sec.rselini, 100e6);

        s0.rseliniTotalSupply = IShareTokenProxy(sec.rselini).totalSupply();
        s0.rseliniRecipientBalance1 = IShareTokenProxy(sec.rselini).balanceOf(recipient1);
        s0.rUsdSubscriberBalance = IERC20TokenModule(sec.rusd).balanceOf(sec.rseliniSubscriber);
        s0.rUsdCustodianBalance = IERC20TokenModule(sec.rusd).balanceOf(sec.rseliniCustodian);
        s0.rUsdRecipientBalance2 = IERC20TokenModule(sec.rusd).balanceOf(recipient2);

        // subscriber subscribes 100 rusd to rSelini and sends shares to custom recipient
        vm.prank(sec.rseliniSubscriber);
        IShareTokenProxy(sec.rselini).subscribe(
            SubscriptionInputs({
                recipient: recipient1,
                custodian: sec.rseliniCustodian,
                tokenIn: sec.rusd,
                amountIn: 100e6,
                minSharesOut: 0
            })
        );

        // check balances after subscription
        s1.rseliniTotalSupply = IShareTokenProxy(sec.rselini).totalSupply();
        s1.rseliniRecipientBalance1 = IShareTokenProxy(sec.rselini).balanceOf(recipient1);
        s1.rUsdSubscriberBalance = IERC20TokenModule(sec.rusd).balanceOf(sec.rseliniSubscriber);
        s1.rUsdCustodianBalance = IERC20TokenModule(sec.rusd).balanceOf(sec.rseliniCustodian);
        s1.rUsdRecipientBalance2 = IERC20TokenModule(sec.rusd).balanceOf(recipient2);

        assertEq(s1.rseliniTotalSupply, s0.rseliniTotalSupply + 100e18);
        assertEq(s1.rseliniRecipientBalance1, s0.rseliniRecipientBalance1 + 100e18);
        assertEq(s1.rUsdSubscriberBalance, s0.rUsdSubscriberBalance - 100e6);
        assertEq(s1.rUsdCustodianBalance, s0.rUsdCustodianBalance + 100e6);
        assertEq(s1.rUsdRecipientBalance2, s0.rUsdRecipientBalance2);

        s0 = s1;

        // custodian sends 50 rusd back to rSelini
        vm.prank(sec.rseliniCustodian);
        IERC20TokenModule(sec.rusd).transfer(sec.rselini, 50e6);

        // recipient sends 50 rSelini to redeemer
        vm.prank(recipient1);
        IERC20TokenModule(sec.rselini).transfer(sec.rseliniRedeemer, 50e18);

        // redeemer redeems 50 shares from rSelini
        vm.prank(sec.rseliniRedeemer);
        IShareTokenProxy(sec.rselini).redeem(
            RedemptionInputs({ recipient: recipient2, tokenOut: sec.rusd, sharesToRedeem: 50e18, minTokensOut: 0 })
        );

        // check balances after redemption
        s1.rseliniTotalSupply = IShareTokenProxy(sec.rselini).totalSupply();
        s1.rseliniRecipientBalance1 = IShareTokenProxy(sec.rselini).balanceOf(recipient1);
        s1.rUsdSubscriberBalance = IERC20TokenModule(sec.rusd).balanceOf(sec.rseliniSubscriber);
        s1.rUsdCustodianBalance = IERC20TokenModule(sec.rusd).balanceOf(sec.rseliniCustodian);
        s1.rUsdRecipientBalance2 = IERC20TokenModule(sec.rusd).balanceOf(recipient2);

        assertEq(s1.rseliniTotalSupply, s0.rseliniTotalSupply - 50e18);
        assertEq(s1.rseliniRecipientBalance1, s0.rseliniRecipientBalance1 - 50e18);
        assertEq(s1.rUsdSubscriberBalance, s0.rUsdSubscriberBalance);
        assertEq(s1.rUsdCustodianBalance, s0.rUsdCustodianBalance - 50e6);
        assertEq(s1.rUsdRecipientBalance2, s0.rUsdRecipientBalance2 + 50e6);
    }
}
