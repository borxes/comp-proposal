// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IERC20.sol";
interface IDelegatable is IERC20 {

    function delegate(address delegatee) external;

    function delegates(address delegate) external view returns (address);

    function getCurrentVotes(address delegate) external view returns (uint96);

    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}