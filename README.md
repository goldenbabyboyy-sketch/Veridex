# Veridex

A blockchain-powered decentralized food traceability platform that ensures transparency, safety, and accountability in the global food supply chain — from farm to table — all on-chain.

---

## Overview

Veridex consists of four main smart contracts that together form a secure, immutable, and verifiable ecosystem for food producers, distributors, retailers, and consumers:

1. **Food Batch NFT Contract** – Issues and manages NFTs representing food batches with embedded metadata.
2. **Supply Chain Log Contract** – Records immutable events and transfers throughout the supply chain.
3. **Verification Oracle Contract** – Integrates off-chain data for certifications, inspections, and real-world verifications.
4. **Stakeholder Governance Contract** – Enables voting on standards, disputes, and ecosystem improvements.

---

## Features

- **NFT-based batch tracking** for unique identification of food items  
- **Immutable supply chain logs** to prevent fraud and enable rapid recalls  
- **Oracle-verified certifications** for organic, fair-trade, or safety claims  
- **Decentralized governance** for stakeholders to influence protocols and resolve issues  
- **Transparent event history** accessible to consumers via QR codes or wallets  
- **Incentive mechanisms** tied to governance for compliant participants  
- **Real-time updates** on product status, location, and quality  

---

## Smart Contracts

### Food Batch NFT Contract
- Mint NFTs for food batches with metadata (origin, production date, ingredients)
- Update metadata for non-critical fields (e.g., storage conditions)
- Transfer ownership during supply chain handoffs with royalty options for producers

### Supply Chain Log Contract
- Log events like harvesting, processing, shipping, and retail arrival
- Enforce sequential updates to maintain chain integrity
- Queryable history for traceability audits

### Verification Oracle Contract
- Secure integration with external data providers (e.g., lab tests, GPS tracking)
- Trigger on-chain verifications for certifications or quality checks
- Dispute flagging for inconsistent data

### Stakeholder Governance Contract
- Token-weighted voting for protocol upgrades or dispute resolutions
- Proposal submission and execution for supply chain standards
- Quorum management and reward distribution for active participants

---

## Installation

1. Install [Clarinet CLI](https://docs.hiro.so/clarinet/getting-started)
2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/veridex.git
   ```
3. Run tests:
    ```bash
    npm test
    ```
4. Deploy contracts:
    ```bash
    clarinet deploy
    ```

## Usage

Each smart contract operates independently but integrates with others for a complete traceability experience.
Refer to individual contract documentation for function calls, parameters, and usage examples.

## License

MIT License

