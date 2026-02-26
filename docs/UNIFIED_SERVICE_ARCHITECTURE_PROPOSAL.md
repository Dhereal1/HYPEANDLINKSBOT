# Unified Service Architecture Proposal (M2)

## Goal

Build a single-root `services/unified` service that starts as a safe gateway/orchestrator and incrementally becomes the business-logic owner per domain, without risky cutover.

## Proposed Folder Structure

```text
services/unified/
  app/
    main.py
    config.py
    health.py
    observability/
      logging.py
      metrics.py
      tracing.py
    api/
      dependencies.py
      routers/
        auth.py
        ai.py
        rag.py
        wallet.py
        tasks.py
        feed.py
    modules/
      auth/
        service.py
        contracts.py
      ai/
        service.py
        contracts.py
      rag/
        service.py
        contracts.py
      wallet/
        service.py
        crypto.py
        contracts.py
        repository.py
      tasks/
        service.py
        contracts.py
      feed/
        service.py
        contracts.py
    forwarding/
      client.py
      policy.py
      registry.py
    shared/
      errors.py
      types.py
      idempotency.py
  tests/
    smoke/
    contract/
    integration/
  scripts/
    run_local.sh
  README.md
  requirements.txt
  Dockerfile
  railway.json
```

## Unified Service Role (Clear Boundary)

1. `M2` role: API gateway + orchestrator + policy enforcement.
2. `M3` role: Own business logic for one domain at a time (start with wallet).
3. `M4` role: Primary owner for auth/wallet/tasks/feed while AI/RAG can remain forwarded until stabilized.

Rule: route shape and security stay in unified from day one; domain logic migrates behind unchanged APIs.

## Migration Strategy (No Big-Bang Cutover)

1. Keep all current endpoints and compatibility aliases.
2. Introduce per-route mode flags:
   - `forward` -> call legacy service
   - `local` -> execute unified module logic
   - `shadow` -> execute both, return forward response, log diffs
3. Migrate one bounded context at a time:
   - Auth verification policy in unified
   - Wallet create/read/update paths
   - Tasks and feed aggregation
   - AI/RAG orchestration and rate policy
4. Remove legacy calls only after contract and shadow parity pass.

## Wallet Security Ownership

1. Mnemonic generation:
   - Generated client-side only (WebCrypto/secure RNG).
   - Never sent to unified or legacy backends.
2. PIN handling:
   - PIN never stored directly.
   - Client derives key material (KDF) and encrypts mnemonic locally.
3. Backend responsibility:
   - Store only non-secret wallet metadata (address, state, timestamps, optional device-scoped envelope metadata).
   - Enforce auth, rate limits, replay protection, audit events.
4. Session/logout behavior:
   - Clear in-memory secrets on logout/app lock.
   - Require PIN re-entry to decrypt local encrypted mnemonic.
5. Recovery UX:
   - Explicit "I saved 24 words" checkpoint before activation.
   - Soft-block sensitive actions until backup confirmation.

## API and Domain Contracts

1. API routers only parse/validate HTTP requests and map to module services.
2. Module services hold domain rules and return typed results.
3. Forwarding layer is infrastructure-only; no domain logic in forwarding code.
4. Shared errors define stable error codes across all modules.

## Immediate Next PR (Low Risk)

1. Create folders/files in `services/unified` with stubbed modules and routers.
2. Keep behavior unchanged by default (`forward` mode for all routes).
3. Add:
   - `/health` with module mode visibility
   - `/ready` dependency checks
   - smoke tests for auth/ai/rag forwarding contracts
4. Add route-level mode config (env-driven) to enable incremental migration.

## Message You Can Send in the Morning

I prepared a unified architecture proposal with a single-root modular layout and route-level migration flags. I will keep no-cutover behavior (forward-first), then migrate domains one by one starting with wallet/auth policy, with contract parity checks before switching ownership.
