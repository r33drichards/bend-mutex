# Implementation and proof boundary

An experimental two-client mutex for Bend 2, with a guarded-data API, a formal permission/CAS model, and native contention tests.

## API

`mutex.bend` provides a two-client CPU mutex protecting one U32 value. Client IDs are 1 and 2. A client can have only one live guard for this mutex. Both IDs may contend; neither has priority.

- `create(value)` allocates a mutex. Logical cell 0 is the lock owner, cell 1 the protected value. Cells 2–3 are reserved for test instrumentation.
- `fork(m)` creates two handles to the **same** mutex, for separate clients. `join(a,b)` reunites handles after work completes; join only handles from the same allocation.
- `try_lock(m, owner)` makes one attempt. `Held{guard}` grants access; `Busy{mutex}` preserves the handle and grants no new access. IDs outside 1–2 are rejected. Acquisition uses CAS(0, owner), with old == 0 required for success.
- `update(guard, callback)` consumes and returns a guard. The callback receives a U32 value and returns its replacement. It receives no shared address. It must return normally for the caller to release the guard.
- `release(guard)` consumes the guard and returns `(mutex, released)`. CAS(owner, 0) releases only when the observed owner matches. A wrong-owner or already-unlocked release leaves the word unchanged and returns false.
- `try_update(m, owner, callback)` combines one acquisition attempt, update and release. It returns `(mutex, success)`; a busy mutex does not invoke the callback.

The API is nonblocking and non-reentrant. There is no destructor, cancellation cleanup, fairness, or starvation guarantee. Dropping a guard leaks the lock. Native loops in the test have explicit bounds.

Guards are affine: ordinary Bend code cannot copy one or use it after consuming it. Constructor visibility is **not** enforced by the module system: public callers must treat constructors, helper functions, and backing arrays as internal. Foreign JS/C can bypass affinity. A forged stale guard with the same owner ID as a later acquisition can unlock that later acquisition: IDs are not generation counters or capabilities against hostile callers. The CAS check handles wrong owners, not malicious guard forgery. No claim covers unguarded access, forged guards, forked guards, joining unrelated allocations, or concurrent use of the same logical client's guard.

## Laws and proof boundary

`model.bend` stores two independent client permission flags. The invalid state `(true,true)` exists in the datatype; safety is not true by construction. Acquisition sets a flag only when the peer has no permission. Reentrant/failed acquisition preserves permissions. Release revokes the caller's permission; wrong-owner release leaves the owner's permission intact.

`LAWS.bend` and `PROOF.bend` prove:

1. The initial state is safe.
2. Each of four acquisition/release actions preserves safety for every safe state.
3. Every finite sequence of those actions, by structural induction, preserves safety.
4. The two clients cannot both have permission after any such sequence.
5. Acquisition can succeed, a contender is blocked, wrong-owner release preserves the holder, and release allows handoff. These rule out an implementation that simply never grants access.
6. Encoding a safe permission state as owner 0, 1, or 2 agrees with the CAS specification for each transition. The runtime and laws share `protocol.bend`'s grant predicate.

The proof is over arbitrary finite histories, not just enumerated test traces. Critical-section entry is permitted only after a successful acquisition; the affine guard must be retained until after the last protected operation. Under that usage rule and the atomic contract, overlapping critical sections would require both permission flags to be true, which the invariant excludes.

**This is a conditional mutex safety proof, not a verified compiler or runtime.** `PROOF.bend` imports the pure model and protocol, not the unsafe shared-array implementation. The trusted boundary includes: the compiler and scheduler preserving dependencies; Array.fork sharing one allocation; strong linearizable CAS returning the old word; correct array indexing; CPU acquire/release memory ordering; and callers obeying guard ownership. Tests connect the model to the actual compiled API, but do not prove this boundary.

The emitted CPU C was inspected: acquisition/release use `a32_cmpx`; it retries spurious weak-CAS failures. `a32_cas` uses acquire-release success ordering and acquire failure ordering. These are runtime implementation observations, not Bend proofs. No new foreign effects are introduced by this project. GPU memory semantics and GPU execution are unverified; no GPU mutex claim is made.

Bend IO tasks run through one event loop. The concurrency test instead uses native parallel calls with shared arrays and CPU worker threads. JavaScript tests exercise API semantics and interleavings sequentially; they are not concurrency evidence.

## Reproduce

Use an existing Bend 2.0.39 compiler and Node.js (the test uses `import.meta.dirname`). Nothing is installed by these commands:

```sh
BEND=/absolute/path/to/bend node tests/test.mjs
BEND_NO_TELEMETRY=1 /absolute/path/to/bend PROOF.bend
BEND_NO_TELEMETRY=1 /absolute/path/to/bend PROOF.bend -o .build/PROOF.bendtt
```

The test runner uses `bend` on PATH, or the compiler selected by `BEND`. It compiles native code with the existing system compiler and limits each subprocess to 60 seconds.

For an independent kernel verdict, supply an already-built compatible kernel:

```sh
BENDTT=/absolute/path/to/bendtt BEND_NO_TELEMETRY=1 /absolute/path/to/bend PROOF.bend --verdict
```

Independent verification succeeded on 2026-10-30 using Bend's supported `BENDTT` override. Lean 4.34.0 checked the unmodified `bendtt.lean` from Bend v2.0.39, then `leanc` built the kernel. The kernel accepted the complete elaborated proof book and rejected a deliberately false initial-safety claim. See [kernel output](validation/kernel.txt) and [build provenance](validation/kernel-build.md).

The Lean toolchain and kernel were built inside ignored task directories. No global defaults were changed. Run the repeatable positive and negative kernel checks with `BEND=/absolute/path/to/bend BENDTT=/absolute/path/to/bendtt npm run test:kernel`. This requires an existing kernel and does not install one.
