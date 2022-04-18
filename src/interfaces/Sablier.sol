// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface ISablier {
    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId);
    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);
    function nextStreamId() external view returns (uint256);
    
    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );
}

