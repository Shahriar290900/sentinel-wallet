# Sentinel Wallet

**2026 Shenzhen FinTechathon · International Track · Topic F (Agent Wallet)** · Team Sentinel (ULAB)

An autonomous AI wallet where Gemma 4 agents plan and act, but **no language model ever holds a key**. Agents may only propose typed intents; a deterministic gate (risk score + five permission tiers) decides; and the `SentinelVault` smart contract enforces the same limits on-chain, so even a compromised agent or server cannot overspend.

## Status at submission (honest summary)

| Component | Status |
|---|---|
| `SentinelVault.sol` — on-chain caps, allowlist, pause, owner-only policy, T3 owner path | **Implemented and tested** (11 Foundry tests incl. 256-run fuzz, all passing — see `test_output.txt`) |
| On-chain deployment + transaction hashes | Not yet executed at submission time |
| Gemma 4 agent crew (Conductor, Scout, Auditor, Reporter) | Designed (see technical documentation) |
| Deterministic RiskScorer + policy tiers T0–T4 (off-chain) | Designed |
| x402 pay-per-call data market | Designed |
| RL advisor in a wallet simulator | Designed |
| Build plan for the full system | `CLAUDE.md` (Claude Code master prompt) |

## What the vault guarantees

- The **agent key** can call `execute(to, amount)` only if: not paused, `to` is allowlisted, `amount ≤ perTxCap`, and the rolling 24 h total stays `≤ dailyCap`.
- Only the **owner** can change caps, the allowlist, the agent key or pause state (tier T4 — unreachable by the agent).
- Actions outside agent limits go through `executeWithOwner` (tier T3, owner signature).
- Every action emits an event for the audit trail.

## Run the tests

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup
forge install foundry-rs/forge-std --no-commit
forge test -vv
```

## Deploy (Base Sepolia testnet)

```bash
forge create src/SentinelVault.sol:SentinelVault \
  --rpc-url $BASE_SEPOLIA_RPC --private-key $OWNER_KEY --broadcast \
  --constructor-args $AGENT_ADDRESS 1000000000000000 3000000000000000
```

Or paste `src/SentinelVault.sol` into remix.ethereum.org (compiler 0.8.24, Injected Provider). Testnet only; never use real funds.

## Repository contents

- `src/SentinelVault.sol` — the contract
- `test/SentinelVault.t.sol` — 11 tests (limits, allowlist, daily rollover, pause, privilege separation, fuzz)
- `test_output.txt` — test run output
- `CLAUDE.md` — full system design and build plan
- `foundry.toml`

Licence: MIT.
