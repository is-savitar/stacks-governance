
# Bitcoin Governance System

This project implements a decentralized governance system for Bitcoin through Stacks, using Clarity smart contracts. It allows token holders to create proposals, vote on them, and execute approved proposals.

## Features

- **Governance Token**: An ERC20-like token that represents voting power in the governance system.
- **Proposal Creation**: Any user holding a minimum amount of governance tokens can create proposals.
- **Voting**: Token holders can vote on proposals, with voting power proportional to their token holdings.
- **Proposal Execution**: Approved proposals can be executed after meeting quorum and majority requirements.

## Smart Contracts

### Governance Token (`governance-token.clar`)

This contract implements the governance token with the following features:

- Minting (restricted to contract owner)
- Transferring tokens between accounts
- Checking token balances
- Retrieving token metadata (name, symbol, URI, decimals)

### Governance Contract (`governance.clar`)

This contract manages the governance process with the following functionality:

- Creating proposals
- Voting on proposals
- Executing approved proposals
- Querying proposal and vote data

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet): A Clarity runtime packaged as a command line tool.

### Installation

1. Clone this repository:

