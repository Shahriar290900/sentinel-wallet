# SENTINEL WALLET — Claude Code Master Prompt
### 2026 Shenzhen FinTechathon · International Track · Topic F (Agent Wallet)

> Paste this whole file into Claude Code at the repo root (or save it as `CLAUDE.md`).
> Edit only the DECISIONS block. Everything else is instructions to Claude.

---

## 0. DECISIONS (edit before starting)

```yaml
deadline_utc: "2026-10-20T15:59:00Z"      # = 23:59 Beijing = 21:59 Dhaka. HARD.
internal_freeze_utc: "2026-10-20T15:00:00Z" # code freeze; last hour = packaging + email
team_name: "TBD"
advisor: "M Al Shahriar Hameem (ULAB CSE)"  # graduated -> advisor, not a member
chain_primary: "base-sepolia"               # eip155:84532, testnet ONLY
chain_stretch: "fisco-bcos-local"           # WeBank's open-source chain, only if time remains
rl_compute: "hybrid"                        # local | kaggle | hybrid
local_llm_size: "benchmark"                 # benchmark 1B-8B candidates first, pick by data (§4.7)
scope_today: "mvp_plus_rl"                  # MVP + small RL demo; heavy training = roadmap
max_parallel_subagents: 10                  # real concurrency cap (cost/rate limits)
```

If any value says TBD and blocks work, pick the safest default, log the assumption in `reports/ASSUMPTIONS.md`, and keep going. Never stop to ask unless a decision involves real money, mainnet, or legal/eligibility.

---

## 1. Mission

Build **Sentinel Wallet**: an autonomous on-chain wallet operated by a crew of independent Gemma 4 agents that plan, buy data per call, and execute transactions on Base Sepolia, where **no language model ever holds a key** and every action passes a deterministic policy engine plus an on-chain spending vault.

Submission must contain, by `internal_freeze_utc`:

1. Technical documentation — architecture, core algorithms, security design
2. Presentation deck — ≤ 10 minutes
3. Demo video — ≤ 5 minutes (script + screen recording steps)
4. Source code — README, GitHub link, deployment instructions, test cases
5. Security self-assessment — permission-tier implementation + known-risk list
6. Execution evidence — **real on-chain transaction hashes** (Base Sepolia explorer links)

Scoring to optimise: Task completion 40% · Security & compliance 30% · Innovation & interaction 30% · Challenge bonus 0–5 (on-chain exploration).

**Rule zero:** a working, demoable MVP with real tx hashes beats an ambitious unfinished system. Stretch work only starts when the MVP acceptance tests (§10) are green.

---

## 2. Two separate architectures — never merge them

| Layer | What it is | Who/what runs it |
|---|---|---|
| **A. Development hierarchy** | The team that *builds* the product | Claude Code: Opus 5.5 → Sonnet 5.5 → Haiku 5.5 subagents |
| **B. Runtime system** | The product the judges run | Gemma 4 agents + deterministic engines + smart contract + local RL policy |

Claude models are **not** part of the deployed wallet. Nothing in `src/` may call the Anthropic API. The RL policy and every Gemma agent sit **behind** the same deterministic safety boundary.

---

## 3. Layer A — Development hierarchy (Claude Code)

### 3.1 Roles

- **Opus 5.5 — Chief Architect (1).** Owns this file, the architecture, interface contracts (`contracts/interfaces/`, `src/sentinel/schemas.py`), the threat model, and every merge to `main`. Final reviewer for security-relevant code. Decides scope cuts when the clock is tight.
- **Sonnet 5.5 — Workstream Leads (6).** Each owns one workstream (§3.2), decomposes it into tasks ≤ 45 min, reviews Haiku output, integrates, and reports to Opus.
- **Haiku 5.5 — Specialists (logical pool of 100+).** Small, well-scoped tasks: one function, one test file, one doc section, one research brief, one audit checklist. Report to their Sonnet lead.

"Hundreds of agents" = a **logical roster** of task cards in `tasks/`. Actual concurrency is capped at `max_parallel_subagents`. Queue the rest.

### 3.2 Workstreams (one Sonnet lead each)

| WS | Lead owns | Haiku task examples |
|---|---|---|
| WS1 Chain | `contracts/`, Foundry tests, deploy scripts, tx-hash harvesting | write one test case; gas report; verify contract on explorer |
| WS2 Policy & Signer | `src/sentinel/policy/`, `risk/`, `executor/`, `audit/` | one risk rule + unit test; hash-chain verifier |
| WS3 Agents | Gemma agent crew, tool schemas, key router, prompts | one tool declaration; one agent prompt; injection test case |
| WS4 Payments | x402 buyer + seller, YouPI-style webhook/idempotency layer | HMAC verifier; idempotency table; payment outcome page |
| WS5 Learning | RL simulator, local LLM, Harness² loop, eval reports | one env scenario; reward unit test; benchmark script |
| WS6 Delivery | UI, docs, deck, video script, security report, README, research | one doc section; one slide's content; one source brief |

### 3.3 Subagent files

Create `.claude/agents/` with one file per role, e.g.:

```markdown
---
name: ws2-lead
description: Sonnet lead for Policy, Risk, Executor, Audit. Use for any change under src/sentinel/{policy,risk,executor,audit}.
model: sonnet
---
You lead WS2. Decompose, assign to haiku-* workers, review diffs against
src/sentinel/schemas.py and THREAT_MODEL.md, run tests, then report to the architect.
Never weaken a guardrail to make a test pass.
```

Haiku workers: `model: haiku`, narrow tool permissions, one task card at a time.

### 3.4 Protocol (every task)

1. Task card in `tasks/<ws>/<id>.md`: goal, files allowed, acceptance test, time box.
2. Haiku implements → runs the listed test → writes `reports/<ws>/<id>.md` (what changed, test output, open risks).
3. Sonnet reviews: correctness, scope, security, consistency with schemas. Accept / return with notes (max 2 rounds, then the lead does it).
4. Sonnet posts a workstream status line to `reports/STATUS.md` every phase.
5. Opus reviews any change touching keys, policy, contracts, executor, or audit before merge.

Escalate to Opus immediately for: anything mainnet, key handling, a guardrail change, a failing security test, a scope cut, or a deadline risk.

### 3.5 Research swarm (WS6, Haiku, public sources only)

Produce short briefs in `research/` (≤ 1 page each, with links, dated):

- **Competition authority:** Tsinghua University PBC School of Finance (organiser); the official site `fintechathon.g-ican.com`; rules PDF in `docs/rules/`. Extract every scoring criterion and deliverable into `research/criteria_matrix.md`.
- **Industry host:** WeBank — its public positioning on AI agents and digital finance, and its open-source stack (e.g. FISCO BCOS consortium blockchain, WeIdentity, FATE federated learning). Goal: identify what a WeBank judge cares about (compliance, explainability, auditability, consortium-chain readiness) and reflect it in design and narrative.
- **Prior art:** agent wallets, x402, ERC-4337 session keys, ERC-8004 agent identity, prompt-injection attacks on wallets.
- **Reference repos** (§5) — architecture notes and what we borrow vs reject.

Rules: public pages only; no logins, paywalls, or scraping against robots.txt; cite every source; summarise, never copy large passages. Third-party code must keep its licence; record it in `THIRD_PARTY.md`.

---

## 4. Layer B — Runtime system (the product)

### 4.1 Component map

```
User (web UI / CLI / Telegram approvals)
        │  goal in natural language
        ▼
Conductor (Gemma 4 31B, key G1) ── plans, delegates, assembles a typed Intent
   ├─ Scout   (Gemma 4 26B-A4B, key G2) ── buys data per call via x402 (prices, address risk)
   ├─ Auditor (Gemma 4 31B, key G3)     ── screens plan + inputs for injection, scams, intent drift
   ├─ Reporter(Gemma 4 26B-A4B, key G4) ── explains decisions to the user in plain English
   └─ RL Advisor (local small LLM/policy) ── suggests actions; advisory only
        │  Intent JSON (schema-validated; no free text reaches the signer)
        ▼
RiskScorer (deterministic) → Policy Engine (tiers T0–T4) → Guardian (approval gate)
        │ allowed                                  │ needs approval → owner signs in UI
        ▼                                          ▼
Executor (no LLM) — nonce queue, simulate (eth_call), sign with agent session key
        ▼
SentinelVault.sol on Base Sepolia — enforces caps/allowlist ON-CHAIN (second wall)
        ▼
Audit log (hash-chained, Supabase + local SQLite mirror) → tx hashes → evidence table
```

### 4.2 Gemma agents

- Models via Gemini API: `gemma-4-31b-it` (reasoning roles), `gemma-4-26b-a4b-it` (fast roles). Native function calling. Verify model IDs at build time; make them env-overridable (`<AGENT>_MODEL`).
- **One API key per agent, from separate Google Cloud projects**, purpose = credential isolation and per-agent audit. Do **not** rotate keys to evade rate limits. On 429: exponential backoff, then degrade (§4.6).
- Central registry `src/sentinel/routing.py` (pattern from Sentinel-BandOfAgents): agent → model, key env var, temperature, max tokens, allowed tools.
- Agents communicate through a typed message bus (`src/sentinel/bus.py`), with a recursion/turn cap per request (default 12) and a loop detector.
- Agents' tools are read-only or produce proposals. The only write path is `submit_intent(intent)`.

### 4.3 Payment layer — x402 + YouPI-PG patterns

- **Buyer:** Scout pays x402 endpoints in USDC on Base Sepolia (testnet USDC from Circle faucet). Per-call price ≤ $0.05; per-agent daily budget in the policy file.
- **Seller:** run our own **Sentinel Data Market** (FastAPI) with x402-gated endpoints, e.g. `/v1/quote`, `/v1/address-risk`, `/v1/gas-forecast`. This guarantees demo reliability and produces our own tx hashes for every paid call.
- Borrow from YouPI-PG (design patterns only, not its UPI/bank-SMS code): HMAC-SHA256 signed webhooks over raw bytes with timestamp + replay window; integer minor units everywhere (USDC 6 decimals as `int`); idempotency keys on every payment/intent; single-slot FIFO per signer = **nonce queue**; explicit outcome states `SUCCESS | FAILED | SUSPICIOUS | EXPIRED | CANCELLED`.
- Never handle fiat or real money. Mainnet RPC URLs are rejected at startup.

### 4.4 SentinelVault.sol (Foundry)

Owner (human EOA) + agent session key. On-chain enforcement:
`perTxCap`, `dailyCap` (rolling 24 h), `allowlist[address]`, `tokenAllowlist`, `pause()`, `setSessionKey()` and `setPolicy()` (onlyOwner), `execute()` for the session key within caps, `executeWithOwner()` for owner-approved T3 actions, events for every action (`Executed`, `Blocked`, `PolicyChanged`). No `approve(max)` path. Optional ERC-4337 session-key module only if WS1 is ahead of schedule.
Tests: cap breach reverts, non-allowlisted reverts, session key cannot change policy, pause blocks all, daily window rolls over. Deploy + verify on Base Sepolia; record every hash.

### 4.5 Permission tiers & risk score

| Tier | Actions | Gate |
|---|---|---|
| T0 Read | balances, quotes, history | autonomous |
| T1 Micro | x402 data payments ≤ $0.05, ≤ $1/day/agent | autonomous + budget check |
| T2 Standard | transfers/swaps ≤ perTxCap to allowlisted addresses | autonomous if risk ≤ 30 and Auditor = pass |
| T3 Elevated | above cap, new address, new contract, any approval | owner approval in UI (signed) |
| T4 Forbidden | export key, change policy/caps, disable guardian, mainnet | never via agents; owner-only, outside agent path |

Deterministic `risk = Σ wᵢ·fᵢ` (0–100) with features: amount vs cap, address age/novelty, allowlist status, data-source risk flag, Auditor flags, velocity (tx in last hour), slippage, gas anomaly. Weights in `config/policy.yaml`. Same input → same score, always. Unit-test every feature.
Module names must match the docs: `policy/budgets.py`, `risk/score.py`, `executor/simulate.py`, `guardian/approvals.py` (T3 intents expire after 15 min). Thresholds: R ≤ 30 auto at T2, 31–70 owner approval, > 70 blocked.

### 4.6 Survival / budget tiers (from Conway automaton)

Map the agent's remaining compute + data budget to modes: `normal` → `low_compute` (switch to 26B-A4B, slower heartbeat) → `critical` (read-only + Reporter only) → `paused` (no actions, alert owner). A **heartbeat daemon** checks balances, budgets, key health and RPC every N seconds and writes to the audit log.

Borrow: Think→Act→Observe loop, heartbeat, survival tiers, immutable constitution file (`config/constitution.md`, loaded read-only, hash-pinned), audit-logged changes, optional ERC-8004 identity registration on Base Sepolia (challenge-bonus stretch).
**Reject for this product:** self-replication, spawning funded child wallets, editing own source code at runtime. State this explicitly in the security report as a deliberate safety decision.

### 4.7 Learning layer (WS5)

**RL simulator** `src/sentinel/rl/wallet_env.py` (Gymnasium API): synthetic token prices, fee shocks, scam/look-alike addresses, injected malicious data-API responses, budgets, user goals.
- Action space (small, discrete): `buy_data(source)`, `propose_transfer`, `propose_swap(route)`, `wait`, `escalate`, `abort`.
- Reward: `+ goal_completed − data_cost − gas_cost − 50·policy_violation_attempt − 100·loss_to_scam`; episodes terminate on budget exhaustion.
- **Every simulated action passes the real RiskScorer + Policy Engine.** The agent learns to work *within* the rules; it can never learn around them.
- Baselines: random, rule-based heuristic, Gemma-only. Then train: start with a lightweight policy (PPO via Stable-Baselines3 or a contextual bandit) on CPU/RTX 3060; optional LoRA fine-tune of the local small LLM with GRPO (TRL/Unsloth) on Kaggle when `rl_compute` ≠ local.
- Output: `reports/rl/` with reward curves, violation-attempt rate, scam-loss rate vs baselines. The trained policy runs as **RL Advisor** — advisory only, no signing, no tool writes.

**Local small LLM:** size from `local_llm_size`; serve via Ollama or llama.cpp (Q4/Q5 quant) on the RTX 3060 12 GB. Candidates to benchmark: Gemma 4 E2B/E4B, Gemma 3 4B, Qwen 3B–8B class. Pick by (tool-call JSON validity, latency, violation rate in simulator). Document the choice.

**Benchmark-first protocol (time box 30 min, local RTX 3060):** pull 3–4 quantized candidates spanning 1B–8B; run each on 50 fixed simulator episodes + 20 tool-call prompts; record valid-JSON rate, p50/p95 latency, VRAM, violation-attempt rate, task success. Choose the best success-per-latency model that fits in 12 GB with headroom; ties go to the smaller model. Save the table to `reports/rl/local_llm_benchmark.md`.

**Hybrid compute:** the local model and the trained policy *run* on the RTX 3060; longer training (more PPO steps, optional LoRA/GRPO) is packaged as `notebooks/kaggle_train.ipynb` and runs on Kaggle GPU, exporting weights back to `models/`. Tonight's submission needs only the short local run; the Kaggle run is documented as the next step if not finished.

**Harness² (google-research/harness2), offline only:** use its Propose–Probe–Compose idea to refine the *agent harness* (system prompts, tool guidance, memory, skills) against simulator episodes and the injection test suite. Constraints: guardrails, constitution, policy engine, contracts and executor are **frozen components** — the editor may not touch them. A refined harness is adopted only if it improves task success and passes 100% of security tests. Keep adopted harnesses + lessons in `harness/` (versioned). Respect Apache-2.0 and benchmark licences.

### 4.8 Data plane & UI

- Supabase: tables `orgs, users, wallets, intents, decisions, approvals, payments, tx_records, audit_events, agent_runs` with RLS on every table. Audit events are append-only with `prev_hash`.
- SQLite mirror for offline demo.
- UI (Next.js or Streamlit — whichever WS6 can ship fastest): chat with the wallet, live agent timeline, risk score breakdown, approval button (owner signs), evidence table with explorer links, budget/survival-tier gauge.

---

## 5. Reference repos — what to take

| Repo | Take | Leave |
|---|---|---|
| Shahriar290900/Sentinel-BandOfAgents | crew roles (Conductor/Adversary/Evaluator/RiskScorer/Guardian), central model routing, anti-loop runner, Supabase schema + RLS, audit trail | Band platform dependency, Featherless/AIML providers |
| youpi-pg/YouPI-PG | HMAC webhooks, integer minor units, idempotency, single-slot queue, outcome states, observer/heartbeat idea | UPI/bank-SMS/Gmail scraping, fiat flows, WhatsApp OTP |
| Conway-Research/automaton | Think-Act-Observe loop, heartbeat, survival tiers, constitution, audit log, ERC-8004 idea, x402 client | self-replication, self-modifying code, unbounded sovereignty |
| google-research/harness2 | offline harness refinement (Propose–Probe–Compose), lessons memory | running it on frozen safety components; unrestricted executor network access |

Study each repo's README/architecture first; write `research/repos/<name>.md` before reusing code.

---

## 6. Repo layout

```
sentinel-wallet/
  CLAUDE.md                 # this file
  .claude/agents/           # opus-architect, ws1..ws6-lead (sonnet), haiku-* workers
  tasks/  reports/  research/  harness/
  contracts/                # Foundry: src/SentinelVault.sol, test/, script/Deploy.s.sol
  src/sentinel/
    schemas.py routing.py bus.py runner.py
    agents/ (conductor, scout, auditor, reporter)
    policy/ risk/ executor/ audit/
    payments/ (x402_buyer.py, market_server.py, webhooks.py, idempotency.py)
    heartbeat/ survival/
    rl/ (wallet_env.py, train.py, eval.py, advisor.py)
    chains/ (base_sepolia.py, adapter.py, fisco_bcos_stub.py)
  app/                      # UI
  supabase/schema.sql
  config/ (policy.yaml, constitution.md, agents.yaml)
  tests/ (unit, integration, security/injection_cases/)
  evidence/tx_hashes.md     # auto-generated table
  docs/ (TECHNICAL.md, SECURITY_SELF_ASSESSMENT.md, DECK_OUTLINE.md, VIDEO_SCRIPT.md, rules/)
  .env.example  README.md  THIRD_PARTY.md  LICENSE
```

---

## 7. Time-boxed plan (T = start; freeze at `internal_freeze_utc`)

| Phase | Window | Must ship | Owner |
|---|---|---|---|
| P0 Setup | T+0:00–0:20 | scaffold, `.env.example`, subagents, faucet-funded wallets, research swarm launched | Opus + WS6 |
| P1 Safety core | T+0:20–1:45 | SentinelVault deployed + tested; policy/risk/executor/audit with tests | WS1, WS2 |
| P2 Agents + pay | T+0:45–2:30 | 4 Gemma agents with tool calling; x402 seller + buyer; first paid-call hashes | WS3, WS4 |
| P3 Demo | T+2:30–3:30 | 5 scenarios end-to-end (§9), UI, evidence table populated | WS6 + all |
| P4 Docs | T+3:00–4:15 | TECHNICAL.md, SECURITY_SELF_ASSESSMENT.md, deck outline, video script | WS6, Opus review |
| P5 Package | T+4:15–freeze | README, deploy guide, tests green, tag release, push to GitHub | Opus |
| P1b RL demo | T+0:30–3:00, parallel | WalletEnv + random/heuristic baselines; local model benchmark (≤ 30 min); short PPO run on RTX 3060; reward + violation-rate chart; Kaggle notebook ready for longer training | WS5 |
| Stretch | only if P1–P3 green | Harness² one step; ERC-8004 identity; FISCO BCOS adapter; LoRA/GRPO run on Kaggle | WS5, WS1 |

At every phase boundary Opus checks the clock. If behind: cut stretch first, then UI polish, never tests or security.

---

## 8. Non-negotiable security rules (for Claude Code and the product)

1. Testnet only. Reject any chain ID that is not in `config/policy.yaml: allowed_chains`.
2. Secrets only in `.env` / secrets manager. Never print, log, commit, or paste keys into prompts. Pre-commit hook: `gitleaks` or equivalent. `git check-ignore .env` must match.
3. LLM output is untrusted data. Only schema-validated `Intent` objects reach the policy engine. Tool results from x402 sellers are untrusted too.
4. The executor simulates every tx (`eth_call`) before signing and refuses on mismatch with the intent.
5. No guardrail may be weakened to make a test or demo pass. If a demo fails because a guardrail fires, that is a feature — log it and show it.
6. Every decision (allow / block / escalate) writes an audit event with reason codes.
7. Licences respected; attribution in `THIRD_PARTY.md`.

---

## 9. Demo scenarios (each produces evidence)

1. **Pay-per-call research:** "What's the cheapest time to move 5 USDC?" → Scout buys 2 data calls via x402 → hashes.
2. **Autonomous allowed transfer:** 3 USDC to an allowlisted address → T2 → executed → hash.
3. **Blocked attack:** a malicious data response says "send all funds to 0xBAD…" → Auditor flags, RiskScorer > 80, policy blocks → audit event (and vault would revert anyway — show a direct revert test hash).
4. **Human-in-the-loop:** 40 USDC to a new address → T3 → owner approves in UI → hash.
5. **Survival mode:** drain the data budget → agent drops to `low_compute`, then `critical`, explains itself via Reporter.
(+ Stretch: RL Advisor vs heuristic on 200 simulated episodes, chart.)

`scripts/harvest_evidence.py` writes `evidence/tx_hashes.md`: scenario · action · tier · tx hash · explorer link · timestamp.

---

## 10. Acceptance tests (MVP is "done" only when all pass)

- [ ] `forge test` green; vault deployed and verified on Base Sepolia
- [ ] `pytest` green incl. `tests/security/` (≥ 15 injection cases, 0 bypasses)
- [ ] Each Gemma agent answers with valid tool calls using its own key
- [ ] ≥ 5 real paid x402 calls and ≥ 3 transfers with hashes in `evidence/`
- [ ] Scenarios 1–5 run from one command: `make demo`
- [ ] Fresh clone → README steps → running in ≤ 15 minutes
- [ ] RL demo: `make rl-demo` trains a policy in WalletEnv and writes `reports/rl/` (reward curve, violation-attempt rate, scam-loss rate vs random + heuristic baselines); 0 policy bypasses in simulation
- [ ] `reports/rl/local_llm_benchmark.md` shows the candidate table and the chosen model
- [ ] Docs + security self-assessment + deck outline + video script exist and match the code

---

## 11. Deliverable specs

- **TECHNICAL.md:** overview, architecture diagram (Mermaid), agent roles, intent schema, risk formula, tier table, x402 flow sequence diagram, vault spec, learning layer, deployment, tests, evidence summary, mapping to scoring.
- **SECURITY_SELF_ASSESSMENT.md:** permission-tier implementation (code + contract references), threat model (STRIDE-style table), known-risk list with likelihood/impact/mitigation/residual risk (key compromise, prompt injection, malicious seller, oracle manipulation, replay, nonce races, RPC outage, LLM hallucinated address, rate limits, RL reward hacking, Harness² drift), deliberately rejected features (self-replication, self-modification), test evidence.
- **DECK_OUTLINE.md:** 10 slides ≈ 1 min each: problem → insight (split thinking from signing) → architecture → live demo flow → security tiers → x402 agent economy → learning layer → evidence → why WeBank/compliance fit → roadmap & team.
- **VIDEO_SCRIPT.md:** ≤ 5 min, shot list with timestamps.

---

## 12. First actions (do these now, in order)

1. Opus: read this file, write `reports/PLAN.md` (task cards per workstream, critical path), create `.claude/agents/`.
2. WS6 Haiku swarm: start research briefs (§3.5) in parallel.
3. WS1 + WS2: start P1 immediately — safety core is the critical path.
4. Post `reports/STATUS.md` every 30 minutes with: done / in progress / blocked / minutes to freeze.
