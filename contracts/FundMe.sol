// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__AlreadyFunded();
error FundMe__NotFirst();
error FundMe__NotEnoughBalance();
error FundMe__NoOneWithMoreThan1k();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private addressToAmountFunded;
    address[] private funders;

    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10 ** 18; // 1eth = 1e18 = 1*10**18 WEI.
    // We will have to compare minimum_usd with msg.value, which is in WEI.
    // The numbers that we want to compare have to have same amount of dec. places.
    uint256 public constant MAXIMUM_USD = 10_000 * 10 ** 18;

    AggregatorV3Interface private priceFeed;

    constructor(address priceFeedAddress) {
        //priceFeedAddress is in the chainlink docs (Data Feeds -> Contract Addresses -> Ethereum Data Feeds)
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable fundOnce {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, //msg.value is in therms of WEI.
            // since we use library for uint256, when we call a function, we first write the specified variable for the library functions
            // a function takes a specified variable as the first parameter of the function
            "You need to spend more ETH!"
        );
        require(
            msg.value.getConversionRate(priceFeed) < MAXIMUM_USD,
            "You need to spend less than 10 000 USD!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); //1TODO: one address can only fund once. Throw an error when trying to fund for the second time
    }

    // 1ANS: This doesnt work (after I add this modifier, my tests fails)
    modifier fundOnce() {
        if (addressToAmountFunded[msg.sender] != 0)
            revert FundMe__AlreadyFunded();
        _;
    }

    function withdraw()
        public
        payable
    /*onlyFirst
        morethan10k
    atLeastOneWithMoreThan1k*/
    {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; //3TODO: why is this necessary. How is this pattern called.
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // 4TODO: only allow withdrawals if there is more than 10000 ETH funded across all addresses
        // 5TODO: only allow withdrawals if there is at least one address with more than 1000 ETH
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
        _; // 2TODO: can you change the contract in such a way that only the first funder can withdraw ETH
    }
    // 2ANS: It should work, but i dont know if I test it right
    modifier onlyFirst() {
        if (msg.sender != funders[0]) revert FundMe__NotFirst();
        _;
    }
    //4ANS: It should work, but i dont know if I test it right
    modifier morethan10k() {
        if (address(this).balance <= 10_000 * 10 ** 18)
            revert FundMe__NotEnoughBalance();
        _;
    }
    //5ANS: Im not sure how to do it
    modifier atLeastOneWithMoreThan1k() {
        uint256 amountOfAddressesWithMoreThan1K = 0;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            if (funder.balance > 1000 * 10 * 18) {
                amountOfAddressesWithMoreThan1K++;
            }
        }
        if (amountOfAddressesWithMoreThan1K < 1)
            revert FundMe__NoOneWithMoreThan1k();
        _;
    }
}
