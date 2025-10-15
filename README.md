# Smart Contract Security & Exploits Demo

This project demonstrates common smart contract vulnerabilities, their exploits, and fixes using multiple security analysis tools.

<!-- ## Project Structure

```
├── contracts/
│   ├── vulnerable/          # Vulnerable contracts
│   ├── exploits/           # Exploit contracts
│   └── fixed/              # Fixed versions
├── test/                   # Test files including exploit tests
├── security/               # Security analysis configs
└── scripts/                # Deployment and analysis scripts
``` -->

## Security Tools Used

- **Slither**: Static analysis for vulnerability detection
- **Mythril**: Symbolic execution and static analysis
- **Echidna**: Property-based fuzzing
- **Foundry**: Testing framework with fuzzing capabilities

## Vulnerabilities Demonstrated

1. **Reentrancy Attack** - Classic withdrawal pattern vulnerability
2. **Integer Overflow/Underflow** - Arithmetic vulnerabilities
3. **Access Control Issues** - Improper permission checks
4. **Unchecked External Calls** - Return value handling

## Setup

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install Python tools
pip install slither-analyzer mythril

# Install Echidna
# Follow: https://github.com/crytic/echidna
```

## Usage

```bash
# Run static analysis
make analyze

# Run fuzzing tests
make fuzz

# Run exploit demonstrations
make exploit
```