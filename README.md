## Auto Split

Auto split is a contract that manages two tokens in the contract pool and make sure they are balanced against each other. 


### Functions🛠️

deposit📥 : Owner deposits any of the two tokens through this function
        * Owner can deposit only one token or both tokens in the pool
        * Emits a deposit event

needRebalance📊: Checks whether the pool requires rebalancing

rebalance⚖️: Rebalances the protocol in a 50:50 ratio with a rebalance threshhold of 5%
        * The threshold allows the rebalance ratio to be short of at least 5% or more than at most 5%

_swap🔄: An internal function that facilitates rebalancing by swapping the excess of the specified token by the rebalance logic to the other token of the pool to maintain the TARGET RATIO

withdraw📤: Owner can withdraw any of the two tokens deposited
        * Emits a withdraw event

getTotalBalances: Gets the balances of the two tokens in the pool respectively


### Users👥

Owner👑: Manages protocol(deposits, withdraws, etc)

rebalancers🤖: Can be any address or bot that will call rebalance upon noticing pool is onsided

### Purpose
To learn more about how rebalancing works


### Test

```shell
$ forge test
```

### Help

```shell
$ forge --help
```
