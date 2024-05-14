pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import { IPassivePoolProxy } from "../interfaces/IPassivePoolProxy.sol";
import { IERC20TokenModule } from "../interfaces/IERC20TokenModule.sol";
import { IRUSDProxy } from "../interfaces/IRUSDProxy.sol";

contract DistributeFunds is Script, Test {
  address multisigEOA = 0x01A8e78B7ba1313A482630837c3978c6259aC1eA;

  address payable pool = payable(0xB4B77d6180cc14472A9a7BDFF01cc2459368D413);
  address usdc = 0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2;
  address rusd = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;

  uint128 poolId = 1;

  struct PendingTx {
    uint256 amount;
    address wallet_address;
  }

  function parsePendingFundsJson() private view returns (PendingTx[] memory pendingTxs) {
    string memory root = vm.projectRoot();
    string memory path = string.concat(root, "/src/reya_network/pendingFunds.json");
    string memory json = vm.readFile(path);
    bytes memory parsed = vm.parseJson(json);

    pendingTxs = abi.decode(parsed, (PendingTx[]));
  }

  function distributeFunds() public {
    PendingTx[] memory pendingTxs = parsePendingFundsJson();
    uint256 sumDeposits = 0;
    for (uint i = 0; i < pendingTxs.length; i += 1) {
      sumDeposits += pendingTxs[i].amount;
    }

    vm.broadcast(multisigEOA);
    IERC20TokenModule(usdc).approve(rusd, sumDeposits);
    vm.broadcast(multisigEOA);
    IRUSDProxy(rusd).deposit(sumDeposits);
    vm.broadcast(multisigEOA);
    IRUSDProxy(rusd).approve(pool, sumDeposits);

    for (uint i = 0; i < pendingTxs.length; i += 1) {
      uint256 shareSupplyUserBefore = IPassivePoolProxy(pool).getAccountBalance(poolId, pendingTxs[i].wallet_address);

      vm.broadcast(multisigEOA);
      IPassivePoolProxy(pool).addLiquidity(poolId, pendingTxs[i].wallet_address, pendingTxs[i].amount, pendingTxs[i].amount * 99 / 100 * 1e24);

      uint256 shareSupplyUserAfter = IPassivePoolProxy(pool).getAccountBalance(poolId, pendingTxs[i].wallet_address);

      uint256 shareSupplyUserDelta = shareSupplyUserAfter - shareSupplyUserBefore;
      uint256 sharePrice = IPassivePoolProxy(pool).getSharePrice(poolId);

      assertApproxEqAbsDecimal(shareSupplyUserDelta * sharePrice / 1e18, pendingTxs[i].amount * 1e24, 0.1e30, 30);
    }
  }
}