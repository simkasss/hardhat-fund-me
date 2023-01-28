// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__AlreadyFunded();
error FundMe__NotFirst();
error FundMe__NotEnoughBalance();
error FundMe__NoOneWithMoreThan1k();

contract FundMe is PriceConverter {
    mapping(address => uint256) private addressToAmountFunded;
    address[] private funders;

    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18;
    uint256 public constant MAXIMUM_USD = 10_000 * 10 ** 18;

    AggregatorV3Interface private priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    function fund() public payable {
        if (addressToAmountFunded[msg.sender] != 0) {
            revert FundMe__AlreadyFunded();
        }

        require(
            getConversionRate(msg.value, priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        require(
            getConversionRate(msg.value, priceFeed) < MAXIMUM_USD,
            "You need to spend less than 10 000 USD!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }
}
