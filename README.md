# the-daio
The Decentralized Autonomous Investment Organization (DAIO)

## Objective

Coordinate a simple investment decision—buy something or not— among all participants with a predetermined redistribution timeframe

---

## Setup

### Geth, Ethereum Wallet, Mist (OSX)

1. Download and install either Ethereum Wallet or Mist from the [official repo](https://github.com/ethereum/mist/releases). Geth will be installed as well.

2. (Optional) Sync the mainnet chain (use `--fast` or light client)

### Testnet Blockchain (OSX)

1. Create a new dir to store testnet blockchain files: `mkdir ~/testnet`

2. Define genesis block configs in a new json file `genesis.json`:

```json
{
    "config": {
        "chainId": 15,
        "homesteadBlock": 0,
        "eip155Block": 0,
        "eip158Block": 0
    },
    "nonce": "0x0000000000000042",
    "timestamp": "0x0",
    "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "gasLimit": "0x8000000",
    "difficulty": "0x400",
    "mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "coinbase": "0x3333333333333333333333333333333333333333",
    "alloc": {}
}
```

3. Initialize testnet blockchain: `geth --datadir "~/testnet" --identity "Private" --networkid 15 --nodiscover --maxpeers 0 init genesis.json`

4. Create an address and start mining:

`geth --datadir "~/eth-private" --identity "Private" --networkid 15 --nodiscover --maxpeers 0 console`

`personal.newAccount("password")`

`miner.setEtherbase(personal.listAccounts[0])`

`miner.start()`

### Deploy Contract

0. Make sure testnet blockchain is active and mining (see [Testnet Blockchain (OSX)](#testnetblockchainosx)

1. Launch Ethereum Wallet or Mist on testnet: `/Applications/Ethereum\ Wallet.app/Contents/MacOS/Ethereum\ Wallet --rpc ~/testnet/geth.ipc`

2. Contracts -> Deploy New Contract

3. Copy&paste code in `daio.sol` into `Solidity Contract Source Code`, choose From account and Ether amount to send (this initial amount will be considered as the `fundShare`)

4. Deploy
