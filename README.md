# bend-mutex

An experimental **two-client CPU mutex** protecting a U32 value in Bend 2. It provides affine guards, callback-based updates, and nonblocking acquisition. Client IDs are 1 and 2.

Bend’s checker and an independently built BendTT kernel both accept the proof book. The 16 Bend laws prove that both clients cannot hold permission simultaneously after any finite sequence of acquisition and release actions. The proof includes successful acquisition, failed contention, invalid release, handoff, and correspondence with a compare-and-swap specification.

This is a conditional safety proof of the permission/CAS model. The shared-array adapter and compiler/runtime are trusted and tested, not formally verified. Callers must preserve guard ownership and avoid direct backing-array access. There is no fairness or liveness guarantee. GPU use is unverified.

## Run

Use Bend **2.0.39**, Node.js 22+, and a native C toolchain:

```sh
BEND=/path/to/bend npm test
BEND_NO_TELEMETRY=1 /path/to/bend PROOF.bend
```

No npm dependencies or installation step are required. `BEND` defaults to `bend` on PATH. Tests cover guarded updates, invalid owners/releases, 87,380 runtime/model transitions, deliberate-bug rejection, affine guard rejection, and native contention across worker pools of 1, 2, 4, and 8 CPU threads.

Read [the API and trust assumptions](IMPLEMENTATION.md), [laws](LAWS.bend), [proofs](PROOF.bend), and [validation results](validation/RESULTS.md). The native test in [tests/concurrency.bend](tests/concurrency.bend) shows parallel clients using guards; [mutex.bend](mutex.bend) provides `create`, `fork`, `try_lock`, `update`, `release`, and `try_update`.
