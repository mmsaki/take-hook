// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import { Test, console } from "forge-std/Test.sol";
import { Currency } from "v4-core/PoolManager.sol";
import { IPoolManager } from "v4-core/PoolManager.sol";
import { IUnlockCallback } from "v4-core/PoolManager.sol";

/// @notice Takes amount of ether available in contract and pays back after transaction
/// @notice A FlashLoan example
contract TestTake is Test, IUnlockCallback {
  address poolmanager = 0x000000000004444c5dc75cB358380D2e3dE08A90;
  uint256 counter = 0;

  function setUp() public {
    vm.createSelectFork("mainnet");
  }

  function testTake() public {
    bytes memory data = "";
    IPoolManager(poolmanager).unlock(data);
  }

  function unlockCallback(bytes calldata data) external override returns (bytes memory) {
    // same as ETH
    Currency currency = Currency.wrap(address(0));
    address to = address(this);
    uint256 amount = address(poolmanager).balance / 2;

    // flashloan ETH from the contract
    console.log("1.0 Take first flashloan", amount);
    IPoolManager(poolmanager).take(currency, to, amount);

    // Payback flashloan at end of transaction
    console.log("2.0 Settle flashloans", amount * 2);
    IPoolManager(poolmanager).settle{ value: amount * 2 }();
    return data;
  }

  receive() external payable {
    // or can also pay back intial amount here
    // IPoolManager(poolmanager).settle{ value: msg.value }();

    // borrow another flashloan from contract balance
    if (counter == 0) {
      Currency currency = Currency.wrap(address(0));
      address to = address(this);
      uint256 amount = address(poolmanager).balance;
      counter++;

      // take contract remaining balance
      console.log("1.2 Take another flashloan", amount);
      IPoolManager(poolmanager).take(currency, to, amount);
    }
  }
}
