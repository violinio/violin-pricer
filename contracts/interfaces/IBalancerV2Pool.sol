// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalancerV2Pool is IERC20 {
  function getPoolId() external view returns (bytes32);
  function getVault() external view returns (address);
}
