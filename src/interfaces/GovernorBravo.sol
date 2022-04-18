// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/compatibility/IGovernorCompatibilityBravo.sol)

pragma solidity ^0.8.0;

interface IGovernorBravo {

    /**
     * @dev Part of the Governor Bravo's interface: _"Function used to propose a new proposal"_.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    /**
     * @dev Part of the Governor Bravo's interface: _"Queues a proposal of state succeeded"_.
     */
    function queue(uint256 proposalId) external;

    /**
     * @dev Part of the Governor Bravo's interface: _"Executes a queued proposal if eta has passed"_.
     */
    function execute(uint256 proposalId) external payable;

    /**
     * @dev Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold.
     */
    function cancel(uint256 proposalId) external;

      /**
      * @notice Cast a vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      */
    function castVote(uint proposalId, uint8 support) external;

    /**
     * @dev Part of the Governor Bravo's interface: _"Gets actions of a proposal"_.
     */
    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );
    
    function proposalThreshold() external view returns (uint256);
}
