# Building Permit System

A blockchain-based building permit system that allows:

- Property owners to submit building permit applications
- Payment of permit fees in STX tokens
- Permit extensions with additional fees
- Administrators to approve or reject permit applications
- Transparent tracking of permit status
- Immutable record of all permit applications and decisions
- Verification of permit validity

The system provides a decentralized and transparent way to manage construction permits, reducing fraud and improving efficiency in the construction approval process.

## Features

### Fee Management
- Base permit application fee required for approval
- Extension fees for prolonging permit validity
- All fees paid in STX tokens directly to contract owner

### Permit Extensions
- Permits can be extended up to 2 times
- Each extension requires additional fee payment
- Extension updates permit expiry date
- Transparent tracking of extension history

### Status Tracking
- PENDING: Initial state after application
- APPROVED: After admin approval and fee payment
- REJECTED: If application is denied
