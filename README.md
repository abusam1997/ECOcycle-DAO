Here’s a formatted README.md for your EcoCycleDAO Clarity contract:

---

# EcoCycleDAO

Decentralized Recycling Incentive & Funding DAO  
**Version:** 2.0 (Refactored)

## Overview

EcoCycleDAO is a decentralized autonomous organization (DAO) built on Stacks using Clarity smart contracts. It incentivizes recycling, manages staking, and funds community proposals through a transparent, on-chain process.

---

## Features

- **Token Minting:** Users can mint tokens for participation.
- **Staking:** Stake tokens to gain voting power.
- **Recycling Submissions:** Submit and verify recycling actions for rewards.
- **Governance:** Propose, vote, and execute funding proposals.
- **DAO Treasury:** Centralized fund management for proposals and rewards.
- **Admin Controls:** Admin can verify recycling and assign new admins.

---

## Contract Structure

- **Error Constants:** Standardized error codes for contract operations.
- **Configuration:** Admin, reward rate, and quorum settings.
- **Storage:** Maps for balances, stakes, submissions, proposals, and votes.
- **Read Functions:** Query balances, stakes, proposals, and submissions.
- **Internal Helpers:** Credit and debit logic for balances.
- **Token Operations:** Minting and funding the DAO.
- **Recycling Logic:** Submit and verify recycling actions.
- **Staking:** Stake and unstake tokens.
- **Governance:** Propose, vote, and execute proposals.
- **Admin:** Set a new admin.

---

## Key Functions

### Token Operations

- `mint(amount)`  
  Mint new tokens to the sender.

- `fund-dao(amount)`  
  Transfer tokens to the DAO treasury.

### Recycling

- `submit(weight)`  
  Submit a recycling action for verification.

- `verify(id)`  
  Admin verifies a submission and rewards the user.

### Staking

- `stake(amount)`  
  Stake tokens to gain voting power.

- `unstake(amount)`  
  Unstake tokens and retrieve them.

### Governance

- `propose(title, desc, amount)`  
  Create a new funding proposal.

- `vote(id)`  
  Vote on a proposal using staked tokens.

- `execute(id)`  
  Execute a proposal if it meets quorum and is not already executed.

### Admin

- `set-admin(new)`  
  Assign a new admin.

---

## Usage

1. **Mint tokens:**  
   Call `mint` to receive tokens.

2. **Stake tokens:**  
   Use `stake` to gain voting power.

3. **Submit recycling:**  
   Call `submit` and wait for admin verification.

4. **Propose and vote:**  
   Use `propose` to create proposals and `vote` to participate in governance.

5. **Execute proposals:**  
   Once quorum is reached, call `execute` to fund proposals.

---

## Development

- **Check contract:**  
  ```
  clarinet check
  ```

- **Run tests:**  
  ```
  npm install
  npm test
  ```

---

## Security Notes

- Only the admin can verify recycling submissions and assign new admins.
- All user input is validated, but warnings about unchecked data may appear during compilation.

---

## License

MIT

---
