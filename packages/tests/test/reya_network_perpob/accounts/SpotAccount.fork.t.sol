pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotAccountForkCheck } from "../../reya_common/accounts/SpotAccount.fork.c.sol";
import { ICoreProxy, CollateralInfo, Command, CommandType } from "../../../src/interfaces/ICoreProxy.sol";

contract SpotAccountForkTest is ReyaForkTest, SpotAccountForkCheck {
    function test_SpotAccount_DepositWithdrawFlows() public {
        (address user,) = makeAddrAndKey("user");
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);

        depositMA(spotAccountId, sec.rusd, 10_000e6);
        depositMA(spotAccountId, sec.weth, 1e18);
        withdrawMA(spotAccountId, sec.rusd, 5000e6);

        CollateralInfo memory rusd = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.rusd);
        CollateralInfo memory weth = ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.weth);
        assertEq(rusd.netDeposits, 5000e6);
        assertEq(weth.netDeposits, 1e18);
    }

    function test_SpotAccount_CollateralLimits() public {
        check_SpotAccount_CollateralLimits();
    }

    function test_TransferBetweenMarginAccounts() public {
        (address user,) = makeAddrAndKey("transferPolicyUser");
        uint128 spotAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);
        // Core 1.1.2 also drops getOwnerMainAccountId, so create a second
        // same-owner margin account to reach the transfer selector itself.
        uint128 mainAccountId = ICoreProxy(sec.core).createAccount(user);
        depositMA(spotAccountId, sec.rusd, 200e6);

        Command[] memory commands = new Command[](1);
        commands[0] = Command({
            commandType: uint8(CommandType.TransferBetweenMarginAccounts),
            inputs: abi.encode(mainAccountId, sec.rusd, 200e6),
            marketId: 0,
            exchangeId: 0
        });

        vm.prank(user);
        ICoreProxy(sec.core).execute(spotAccountId, commands);
        assertEq(ICoreProxy(sec.core).getCollateralInfo(spotAccountId, sec.rusd).netDeposits, 0);
        assertEq(ICoreProxy(sec.core).getCollateralInfo(mainAccountId, sec.rusd).netDeposits, 200e6);
    }
}
