# Smart Contract Security Analysis Makefile

.PHONY: install build test analyze fuzz exploit clean

# Installation
install:
	forge install foundry-rs/forge-std
	forge install OpenZeppelin/openzeppelin-contracts
	pip install slither-analyzer mythril

# Build contracts
build:
	forge build

# Run all tests
test:
	forge test -vvv

# Static Analysis
analyze: slither mythril

slither:
	@echo "Running Slither analysis..."
	slither contracts/vulnerable/ --print human-summary
	slither contracts/vulnerable/ --detect all

mythril:
	@echo "Running Mythril analysis..."
	myth analyze contracts/vulnerable/ReentrancyVulnerable.sol --solc-json mythril-config.json

# Fuzzing
fuzz:
	@echo "Running Foundry fuzzing..."
	forge test --match-test testFuzz -vvv
	@echo "Running Echidna fuzzing..."
	echidna security/echidna-config.yaml

# Exploit demonstrations
exploit:
	@echo "Running exploit tests..."
	forge test --match-test testExploit -vvv

# Clean build artifacts
clean:
	forge clean
	rm -rf out cache

# Security report
report:
	@echo "Generating security report..."
	slither contracts/vulnerable/ --json slither-report.json
	myth analyze contracts/vulnerable/ --solc-json mythril-config.json -o json > mythril-report.json