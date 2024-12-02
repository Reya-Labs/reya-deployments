pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IShareTokenProxy, SubscriptionInputs, RedemptionInputs } from "../../../src/interfaces/IShareTokenProxy.sol";
import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

struct LocalState {
    uint256 lmTokenTotalSupply;
    uint256 lmTokenRecipientBalance1;
    uint256 rUsdSubscriberBalance;
    uint256 rUsdCustodianBalance;
    uint256 rUsdRecipientBalance2;
}

contract LmTokenCollateralForkCheck is BaseReyaForkTest {
    LocalState private s0;
    LocalState private s1;

    // TODO: check no one can mint or burn shares (fuzz test)

    function check_LmToken_RedemptionAndSubscription(
        address lmToken,
        address subscriber,
        address redeemer,
        address custodian
    )
        public
    {
        address recipient1 = vm.addr(123);
        address recipient2 = vm.addr(456);

        // mint 100 rusd for the subscriber
        deal(sec.rusd, address(subscriber), 100e6);

        // subscriber approve 100 rusd to LM token
        vm.prank(subscriber);
        IERC20TokenModule(sec.rusd).approve(lmToken, 100e6);

        s0.lmTokenTotalSupply = IShareTokenProxy(lmToken).totalSupply();
        s0.lmTokenRecipientBalance1 = IShareTokenProxy(lmToken).balanceOf(recipient1);
        s0.rUsdSubscriberBalance = IERC20TokenModule(sec.rusd).balanceOf(subscriber);
        s0.rUsdCustodianBalance = IERC20TokenModule(sec.rusd).balanceOf(custodian);
        s0.rUsdRecipientBalance2 = IERC20TokenModule(sec.rusd).balanceOf(recipient2);

        // subscriber subscribes 100 rusd to rSelini and sends shares to custom recipient
        vm.prank(subscriber);
        IShareTokenProxy(lmToken).subscribe(
            SubscriptionInputs({
                recipient: recipient1,
                custodian: custodian,
                tokenIn: sec.rusd,
                amountIn: 100e6,
                minSharesOut: 0
            })
        );

        // check balances after subscription
        s1.lmTokenTotalSupply = IShareTokenProxy(lmToken).totalSupply();
        s1.lmTokenRecipientBalance1 = IShareTokenProxy(lmToken).balanceOf(recipient1);
        s1.rUsdSubscriberBalance = IERC20TokenModule(sec.rusd).balanceOf(subscriber);
        s1.rUsdCustodianBalance = IERC20TokenModule(sec.rusd).balanceOf(custodian);
        s1.rUsdRecipientBalance2 = IERC20TokenModule(sec.rusd).balanceOf(recipient2);

        assertEq(s1.lmTokenTotalSupply, s0.lmTokenTotalSupply + 100e18);
        assertEq(s1.lmTokenRecipientBalance1, s0.lmTokenRecipientBalance1 + 100e18);
        assertEq(s1.rUsdSubscriberBalance, s0.rUsdSubscriberBalance - 100e6);
        assertEq(s1.rUsdCustodianBalance, s0.rUsdCustodianBalance + 100e6);
        assertEq(s1.rUsdRecipientBalance2, s0.rUsdRecipientBalance2);

        s0 = s1;

        // custodian sends 50 rusd back to LM token
        vm.prank(custodian);
        IERC20TokenModule(sec.rusd).transfer(lmToken, 50e6);

        // recipient sends 50 LM tokens to redeemer
        vm.prank(recipient1);
        IERC20TokenModule(lmToken).transfer(redeemer, 50e18);

        // redeemer redeems 50 shares from LM token
        vm.prank(redeemer);
        IShareTokenProxy(lmToken).redeem(
            RedemptionInputs({ recipient: recipient2, tokenOut: sec.rusd, sharesToRedeem: 50e18, minTokensOut: 0 })
        );

        // check balances after redemption
        s1.lmTokenTotalSupply = IShareTokenProxy(lmToken).totalSupply();
        s1.lmTokenRecipientBalance1 = IShareTokenProxy(lmToken).balanceOf(recipient1);
        s1.rUsdSubscriberBalance = IERC20TokenModule(sec.rusd).balanceOf(subscriber);
        s1.rUsdCustodianBalance = IERC20TokenModule(sec.rusd).balanceOf(custodian);
        s1.rUsdRecipientBalance2 = IERC20TokenModule(sec.rusd).balanceOf(recipient2);

        assertEq(s1.lmTokenTotalSupply, s0.lmTokenTotalSupply - 50e18);
        assertEq(s1.lmTokenRecipientBalance1, s0.lmTokenRecipientBalance1 - 50e18);
        assertEq(s1.rUsdSubscriberBalance, s0.rUsdSubscriberBalance);
        assertEq(s1.rUsdCustodianBalance, s0.rUsdCustodianBalance - 50e6);
        assertEq(s1.rUsdRecipientBalance2, s0.rUsdRecipientBalance2 + 50e6);
    }

    function check_rseliniRedemptionAndSubscription() public {
        check_LmToken_RedemptionAndSubscription(
            sec.rselini, sec.rseliniSubscriber, sec.rseliniRedeemer, sec.rseliniCustodian
        );
    }

    function check_ramberRedemptionAndSubscription() public {
        check_LmToken_RedemptionAndSubscription(
            sec.ramber, sec.ramberSubscriber, sec.ramberRedeemer, sec.ramberCustodian
        );
    }
}
