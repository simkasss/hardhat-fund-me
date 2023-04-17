Smart contact FundMe.sol allows to fund collective goods (blockchain native token) and withdraw them:
   1. People can **send Ethereum** (or Polygon, Avalanche, Phantom, etc.) into this contract
   2. Owner of the contract then can **withdraw** those funds
FundMe.sol utilizes **Chainlink Data Feeds** feature to read a price of ETH in terms of USD (ETH/USD) from Chainlink Price Feeds interface AggregatorV3Interface.sol.
