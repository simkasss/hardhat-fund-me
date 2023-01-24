// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// TODO: Typing club
library PriceConverter {
    //TODO: change priceconverter to a contract type
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // TODO: why do we multiply
        // ANS: The function returns latest price of ETH in terms of USD.
        // There are 8 decimal places associated with this price feed (there is a "decimals" function in the aggregator contract that says that)
        // msg.value have 18 decimal places
        // We want values (price and msg. value) to have same decimal places and same data type (uint256 instead of int256)
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // TODO: why do we divide
        // ANS: Since ethPrice and ethAmount both have 18 decimal places, if we multiply the number would be with 36 decimal places
        // So we have to divide it by 1e18 for it to have 18 decimal places.
        return ethAmountInUsd;
    }
}
