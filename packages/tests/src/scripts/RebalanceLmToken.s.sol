pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import { IPassivePoolProxy, AutoRebalanceInput, RebalanceAmounts } from "../../src/interfaces/IPassivePoolProxy.sol";
import { IERC20TokenModule } from "../../src/interfaces/IERC20TokenModule.sol";
import { IRUSDProxy } from "../../src/interfaces/IRUSDProxy.sol";
import { IShareTokenProxy, SubscriptionInputs } from "../../src/interfaces/IShareTokenProxy.sol";

contract RebalanceLmToken is Script, Test {
    // testnet setup
    address private rebalancerEOA = 0xaE173a960084903b1d278Ff9E3A81DeD82275556;
    address private multisigDestination = 0x45556408e543158f74403e882E3C8c23eCD9f732;
    address private underlyingAssetToken = 0x9DE724e7b3facF87Ce39465D3D712717182e3e55;

    // Selini LM token
    address private shareToken = 0xbA8ae4D2A147c54c3aBA123e8e01937AF505FC3c;

    address payable private pool = payable(0x9A3A664987b88790A6FDC1632e3b607813fd94fF);
    uint128 private poolId = 1;

    // amount of tokens to rebalance each step
    uint256 tokenAmountOneStep = 1_000e6;
    uint256 steps = 10;

    function rebalance() public {

        // check that conversion in LM token followed by conversion in passive pool results in the initial amount
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
