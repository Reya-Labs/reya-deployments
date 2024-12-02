pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import { IPassivePoolProxy, AutoRebalanceInput, RebalanceAmounts } from "../../src/interfaces/IPassivePoolProxy.sol";
import { IERC20TokenModule } from "../../src/interfaces/IERC20TokenModule.sol";
import { IRUSDProxy } from "../../src/interfaces/IRUSDProxy.sol";
import { IShareTokenProxy, SubscriptionInputs } from "../../src/interfaces/IShareTokenProxy.sol";

contract RebalanceLmToken is Script, Test {
    // TODO: adjust these addresses
    address private rebalancerEOA = 0xe8AaBC33a41d63FE4a0aD13ce815279391dD069E;
    address private multisigDestination = 0x01A8e78B7ba1313A482630837c3978c6259aC1eA;
    address private underlyingAssetToken = 0x01A8e78B7ba1313A482630837c3978c6259aC1eA;
    address private shareToken = 0x01A8e78B7ba1313A482630837c3978c6259aC1eA;

    address payable private pool = payable(0xB4B77d6180cc14472A9a7BDFF01cc2459368D413);
    uint128 private poolId = 1;

    uint256 tokenAmountOneStep = 1000e6;
    uint256 steps = 10;

    function rebalance() public {

        uint256 shareAmountOneStep = IShareTokenProxy(shareToken).calculateSharesOut(underlyingAssetToken, tokenAmountOneStep);
        assertGe(shareAmountOneStep, 1000e18);

        vm.broadcast(rebalancerEOA);
        IERC20TokenModule(underlyingAssetToken).approve(underlyingAssetToken, tokenAmountOneStep * steps);

        vm.broadcast(rebalancerEOA);
        IShareTokenProxy(shareToken).approve(pool, shareAmountOneStep * steps);

        for (uint256 i = 1; i <= steps; i += 1) {
            vm.broadcast(rebalancerEOA);
            uint256 actualSharesOut = IShareTokenProxy(shareToken).subscribe(SubscriptionInputs({
                recipient: rebalancerEOA,
                custodian: multisigDestination,
                tokenIn: underlyingAssetToken,
                amountIn: tokenAmountOneStep,
                minSharesOut: 0
            }));

            assertEq(actualSharesOut, shareAmountOneStep);

            vm.broadcast(rebalancerEOA);
            RebalanceAmounts memory actualRebalanceAmounts = IPassivePoolProxy(pool).triggerAutoRebalance(poolId, AutoRebalanceInput({
                tokenIn: shareToken,
                amountIn: shareAmountOneStep,
                tokenOut: underlyingAssetToken,
                minPrice: 0,
                receiverAddress: rebalancerEOA
            }));

            assertEq(actualRebalanceAmounts.amountOut, tokenAmountOneStep);
        }

        vm.broadcast(rebalancerEOA);
        IERC20TokenModule(underlyingAssetToken).approve(shareToken, 0);

        vm.broadcast(rebalancerEOA);
        IERC20TokenModule(shareToken).approve(pool, 0);
    }
}
