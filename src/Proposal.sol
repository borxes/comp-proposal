// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "openzeppelin/token/ERC20/IERC20.sol";
import {Constants} from "./Constants.sol";
import "./interfaces/Sablier.sol";
import "./interfaces/GovernorBravo.sol";

/*
The annual price is $2,000,000. $1,000,000 is paid in USDC. $1,000,000 is paid in COMP tokens.
An additional sum of $400,000 in COMP paying decentralized community rule writers.
 This sum will not be used for any other purpose and returned if not used or moved to the 
 following year if the contract is renewed. These tokens will be transferred to a special-purpose 
 multisig wallet controlled by Certora and elected members of the Compound ecosystem
 */

contract Proposal {

    struct ProposalData {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        string description;
    }

    uint256 public amountComp;
    uint256 public amountUsdc;
    uint256 public startTime;
    uint256 public endTime;
    address public recipient;

    ProposalData internal data;

    // cannot be declared as constant - solc limitation
    ISablier public sablier = ISablier(Constants.SABLIER);
    IGovernorBravo public governor = IGovernorBravo(Constants.GOVERNOR_BRAVO);

    string public constant description = "A proposal for significantly and continuously";
    // "improving the security of the Compound platform and the dApps built on top of it, by offering" 
    // "our formal verification and path coverage tooling service to the Compound Platform contributors" 
    // "and the Compound Protocol dApp developers. This is a follow-up to our recent work on the Comet "
    // "protocol with the Compound labs team. The idea is to provide access to the community and educate" 
    // "the community, write formal specifications, and review code changes. This proposal is orthogonal "
    // "to the Open Zeppelin proposal, which has already been suggested using the Certora prover. "
    // "This proposal also suggests writing formal correctness rules for the Compound Protocol which"
    // " will be reviewed by the community and OpenZeppelin. We have already written some formal "
    // "requirements for Comet and prevented huge security breaches."
    // "This is an update of an earlier unsubmitted proposal 2 discussed in November 2021.";

    constructor(uint256 _amountComp, uint256 _amountUsdc, uint256 _startTime, uint256 _endTime, 
    address _recipient) {
        require(_amountComp > 0 && _amountUsdc > 0);
        require (_endTime > _startTime);
        amountComp = _amountComp;
        amountUsdc = _amountUsdc;
        startTime = _startTime;
        endTime = _endTime;
        recipient = _recipient;
    }

    function _addApproveCompAction() internal {
        data.targets.push(Constants.COMP_TOKEN);
        data.values.push(0);
        data.signatures.push("approve(address,uint256)");
        data.calldatas.push(abi.encode(address(sablier), amountComp));
    }

    function _addApproveUsdcAction() internal {
        data.targets.push(Constants.USDC_TOKEN);
        data.values.push(0);
        data.signatures.push("approve(address,uint256)");
        data.calldatas.push(abi.encode(address(sablier), amountUsdc));
    }

    function _addCreateCompStreamAction() internal {
        data.targets.push(address(sablier));
        data.values.push(0);
        data.signatures.push("createStream(address,uint256,address,uint256,uint256)");
        data.calldatas.push(abi.encode(recipient, amountComp, Constants.COMP_TOKEN, startTime, endTime));
    }

    function _addCreateUsdcStreamAction() internal {
        data.targets.push(address(sablier));
        data.values.push(0);
        data.signatures.push("createStream(address,uint256,address,uint256,uint256)");
        data.calldatas.push(abi.encode(recipient, amountUsdc, Constants.COMP_TOKEN, startTime, endTime));
    }

    function buildProposalData() public {
        _addApproveCompAction();
        _addApproveUsdcAction();
        _addCreateCompStreamAction();
        _addCreateUsdcStreamAction();
        data.description = description;
    }

    function getProposalData() public view returns (bytes memory) {
        return abi.encode(data.targets, data.values, data.signatures, data.calldatas, data.description);
    }


    function run() public {
        buildProposalData();
        governor.propose(data.targets, data.values, data.signatures, data.calldatas, description);       
    }
}

