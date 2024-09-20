import "forge-std/Test.sol";
import "../reya_common/DataTypes.sol";

import { ReyaForkTest } from "../reya_network/ReyaForkTest.sol";
import { IERC20TokenModule } from "../../src/interfaces/IERC20TokenModule.sol";
import { IPeripheryProxy, WithdrawInputs } from "../../src/interfaces/IPeripheryProxy.sol";
import { ISocketControllerWithPayload } from "../../src/interfaces/ISocketControllerWithPayload.sol";

contract SocketTest is ReyaForkTest {
  address user;
  uint256 amount;
  uint256 chainId;

  function setUp() public {
    (user, ) = makeAddrAndKey("user");
    amount = 100e6;
    chainId = optimismChainId;

    vm.deal(user, 1 ether);

    vm.prank(dec.socketController[sec.usdc]);
    IERC20TokenModule(sec.usdc).mint(user, amount);
  }

  function test_socket_periphery_withdraw() public {
    vm.prank(user);
    IERC20TokenModule(sec.usdc).approve(sec.periphery, amount);

    uint256 minFees = 
      ISocketControllerWithPayload(dec.socketController[sec.usdc]).getMinFees(
        dec.socketConnector[sec.usdc][chainId], 10_000_000, 160
      );

    vm.prank(user);
    WithdrawInputs memory withdrawInputs = WithdrawInputs({
      tokenAmount: amount,
      token: sec.usdc,
      socketMsgGasLimit: 10_000_000,
      chainId: chainId,
      receiver: user
    });
  
    IPeripheryProxy(sec.periphery).withdraw{value: minFees}(withdrawInputs);
  }
}