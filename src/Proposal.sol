// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {Constants} from "./Constants.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/Sablier.sol";
import "./interfaces/GovernorBravo.sol";
import "./interfaces/Oracle.sol";

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
    uint256 public compEndTime;
    uint256 public usdcEndTime;
    address public recipient;

    ProposalData internal data;

    // cannot be declared as constant - solc limitation
    ISablier public sablier = ISablier(Constants.SABLIER);
    IGovernorBravo public governor = IGovernorBravo(Constants.GOVERNOR_BRAVO);
    PriceOracle oracle = PriceOracle(Constants.COMP_USD_ORACLE);

    string public constant description = "A proposal for significantly and continuously"
    "improving the security of the Compound platform and the dApps built on top of it, by offering" 
    "our formal verification and path coverage tooling service to the Compound Platform contributors" 
    "and the Compound Protocol dApp developers. This is a follow-up to our recent work on the Comet "
    "protocol with the Compound labs team. The idea is to provide access to the community and educate" 
    "the community, write formal specifications, and review code changes. This proposal is orthogonal "
    "to the Open Zeppelin proposal, which has already been suggested using the Certora prover. "
    "This proposal also suggests writing formal correctness rules for the Compound Protocol which"
    " will be reviewed by the community and OpenZeppelin. We have already written some formal "
    "requirements for Comet and prevented huge security breaches."
    "This is an update of an earlier unsubmitted proposal 2 discussed in November 2021.";

    constructor() {
        // TODO these vars should be initialized when running propose, not in constructor

        // MAX_VOTING_PERIOD is designated in blocks so we multiple by 15
        startTime = block.timestamp + Constants.MAX_VOTING_PERIOD * 15;
        // 1 year from startTime
        endTime = startTime + 60 * 60 * 24 * 365;
        recipient = Constants.CERTORA;
    }


    function getProposalData() public view returns (bytes memory) {
        return abi.encode(data.targets, data.values, data.signatures, data.calldatas, data.description);
    }

    // returns the proposal id
    function run() public returns(uint256) {
        buildProposalData();
        return governor.propose(data.targets, data.values, data.signatures, data.calldatas, description);       
    }

    function getPriceOfCOMPinUSD() public view returns (uint256, uint8) {
        (, int256 compPrice, uint startedAt, , ) = oracle.latestRoundData();
        uint freshTime = 3 /* days */ * 24 /* hours */ * 60 /* minutes */ * 60 /* seconds */; // using "days" leads to "Expected primary expression" error
        require (startedAt > block.timestamp - freshTime, "price is not fresh");
        require (compPrice > 0, "comp price must be positive");

        return (uint256(compPrice), oracle.decimals());
    }

    function convertUSDAmountToCOMP(uint256 usdAmount) public view returns (uint256) {
        uint8 compDecimals = IERC20(Constants.COMP_TOKEN).decimals();
        (uint compPrice, uint8 priceDecimals) = getPriceOfCOMPinUSD();
        
        uint256 compAmount = usdAmount * 10**priceDecimals * 10**compDecimals / compPrice;
        return compAmount;
    }

    function convertUSDAmountToUSDC(uint256 usdAmount) public pure returns (uint256) {
        return usdAmount * 10 ** Constants.USDC_DECIMALS;
    }

    function buildProposalData() public {
        amountComp = convertUSDAmountToCOMP(Constants.COMP_VALUE);
        // make the amount divisible by duration
        amountComp -= amountComp % (endTime - startTime);
        amountUsdc = convertUSDAmountToUSDC(Constants.USDC_VALUE);
        amountUsdc -= amountUsdc % (endTime - startTime);

        _addApproveCompAction();
        _addApproveUsdcAction();
        _addCreateCompStreamAction();
        _addCreateUsdcStreamAction();
        data.description = description;
    }


    // Internal functions

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
        data.calldatas.push(abi.encode(recipient, amountUsdc, Constants.USDC_TOKEN, startTime, endTime));
    }

}

