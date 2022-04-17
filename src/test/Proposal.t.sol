// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "../Proposal.sol";
import {Constants} from "../Constants.sol";
import "../interfaces/Oracle.sol";

uint256 constant ERROR_MARGIN = 10 ** 12;

contract ContractTest is Test {
    Proposal proposal;

    address[] targets;
    uint256[] values;
    string[]  signatures;
    bytes[]   calldatas;
    string    description;

    function setUp() public {
        proposal = new Proposal();
    }

    function _testTargets() internal {
        assertEq(targets[0], Constants.COMP_TOKEN);
        assertEq(targets[1], Constants.USDC_TOKEN);
        assertEq(targets[2], Constants.SABLIER);
        assertEq(targets[3], Constants.SABLIER);
    }

    function _testValues() internal {
        for(uint8 i = 0; i < 4; i++){
            assertEq(values[i], 0);
        }
    }

    function _testSignatures() internal {
        assertEq(keccak256(abi.encode(signatures[0])), keccak256(abi.encode("approve(address,uint256)")));
        assertEq(keccak256(abi.encode(signatures[1])), keccak256(abi.encode("approve(address,uint256)")));
        assertEq(keccak256(abi.encode(signatures[2])), 
                keccak256(abi.encode("createStream(address,uint256,address,uint256,uint256)")));
        assertEq(keccak256(abi.encode(signatures[3])), 
                keccak256(abi.encode("createStream(address,uint256,address,uint256,uint256)")));
    }

    function _testCalldatas() internal {
        address target;
        uint256 amount;

        // action 1
        (target, amount) = abi.decode(calldatas[0], (address, uint256));
        assertEq(target, Constants.SABLIER, "target is not sablier");
        assertEq(amount, proposal.amountComp(), "amount of COMP is wrong");

        // action 2
        (target, amount) = abi.decode(calldatas[1], (address, uint256));
        assertEq(target, Constants.SABLIER, "target is not sablier");
        assertEq(amount, proposal.amountUsdc(), "amount of USDC is wrong");

        // action 3

        address recipient;
        address token;
        uint256 startTime;
        uint256 endTime;
        (recipient, amount, token, startTime, endTime) = abi.decode(calldatas[2], 
                                                        (address, uint256, address, uint256, uint256));

        assertEq(recipient, Constants.CERTORA, "wrong recipient");
        assertEq(amount, proposal.amountComp(), "wrong comp amount");
        assertEq(token, Constants.COMP_TOKEN, "wrong comp token address");

        assertEq(endTime - startTime, 60 * 60 * 24 * 365, "wrong comp stream duration");

        // amount and duration must be divisible without remainder
        assertEq(amount % (endTime - startTime), 0, "comp amount not divisible by duration");

        // startTime must be after current time + 2 weeks
        assertGt(startTime, block.timestamp +  Constants.MAX_VOTING_PERIOD * 15, "comp stream starts too soon");

        // action 4
        (recipient, amount, token, startTime, endTime) = abi.decode(calldatas[3], 
                                                        (address, uint256, address, uint256, uint256));

        assertEq(recipient, Constants.CERTORA, "wrong recipient");
        assertEq(amount, proposal.amountUsdc(), "wrong usdc amount");
        assertEq(token, Constants.USDC_TOKEN, "wrong usdc token address");

        assertEq(endTime - startTime, 60 * 60 * 24 * 365, "wrong usdc stream duration");

        // amount and duration must be divisible without remainder
        assertEq(amount % (endTime - startTime), 0, "usdc amount not divisible by duration");

        // startTime must be after current time + 2 weeks
        assertGt(startTime, block.timestamp +  Constants.MAX_VOTING_PERIOD * 15, "usdc stream starts too soon");
    }

    function _testDescription() internal {
        assertGt(bytes(description).length, 20);
    }

    function testProposalData() public {
        proposal.buildProposalData();
        bytes memory data = proposal.getProposalData();
        emit log_named_bytes("propose() calldata", data);
        
        (targets, values, signatures, calldatas, description) = abi.decode(data, 
            (address[], uint256[], string[], bytes[], string));

        _testTargets();
        _testValues();
        _testSignatures();
        _testCalldatas();
        _testDescription();
    }

    function testCompToUsdcConversion() public {
        PriceOracle oracle = PriceOracle(Constants.COMP_USD_ORACLE);
        uint256 compAmount = proposal.convertUSDAmountToCOMP(Constants.COMP_VALUE);
        console.log("comp amount:", compAmount);
        (, int256 compPrice, , , ) = oracle.latestRoundData();
        uint256 givenCompValue = compAmount * uint256(compPrice);
        uint256 expectedUsdValue = Constants.COMP_VALUE * 10 ** (Constants.COMP_DECIMALS + oracle.decimals());
        console.log("given comp value:", givenCompValue);
        console.log("expected usd:", expectedUsdValue);
        uint256 margin;
        if (expectedUsdValue > givenCompValue) {
            margin = expectedUsdValue - givenCompValue;
        } else {
            margin = givenCompValue - expectedUsdValue;
        }

        assertLt(margin, ERROR_MARGIN);
    }

    function testUsdToUsdcConversion() public {
        uint256 usdcAmount = proposal.convertUSDAmountToUSDC(Constants.USDC_VALUE);
        console.log("usdc amount:", usdcAmount);

        assertEq(usdcAmount, Constants.USDC_VALUE * 10 ** Constants.USDC_DECIMALS);
    }

    function testE2E() public {
        // build proposal data
        // deal quorum of tokens to msg.sender
        // delegate to self
        // run propose()
        // vote for proposal
        // warp forward
        // queue
        // warp forward
        // execute

        // check the stream using sablier.nextStreamId()


    }

}
