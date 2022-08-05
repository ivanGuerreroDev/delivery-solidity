// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the Transfer.
 */
interface ITransfer {
  function transferBySend(address to, uint amount) external returns (bool);
  function TransferByTransfer(address to, uint amount) external returns (bool);
  function TransferByCall(address to, uint amount) external returns (bool);
}