// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "../Proposal.sol";
import {Constants} from "../Constants.sol";
import "../interfaces/Oracle.sol";

uint256 constant ERROR_MARGIN = 10 ** 12;

contract ContractTest is DSTest {
    Proposal proposal;

    address[] targets;
    uint256[] values;
    string[]  signatures;
    bytes[]   calldatas;
    string    description;

    Vm public constant vm = Vm(HEVM_ADDRESS);

    function setUp() public {
        proposal = new Proposal(1000,1000, 5000, 20000, Constants.CERTORA);
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
        assertEq(target, Constants.SABLIER);
        assertEq(amount, proposal.amountComp());

        // action 2
        (target, amount) = abi.decode(calldatas[0], (address, uint256));
        assertEq(target, Constants.SABLIER);
        assertEq(amount, proposal.amountUsdc());

        // TODO add action 3 + 4

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

    // TODO add the whole simulation and price calculation with chainlink oracle

}

