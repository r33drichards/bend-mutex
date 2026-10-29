# Validation results

Tested locally on 2026-10-30 with Bend 2.0.39 and the existing macOS CPU toolchain. See test.log for the final complete run.

- Bend checker: ALL PROOFS CHECK for 16 laws (including symbolic induction over every finite action history).
- BendTT: independently built kernel accepted the complete elaboration through `bend PROOF.bend --verdict`; it also rejected a deliberately false initial-safety claim (see kernel.txt).
- Sequential compiled-API/model comparison: 87,380 acquisition/release transitions through depth 8.
- API: successful guarded update, contention, handoff, callback update, invalid owner rejection, wrong-owner release, immediate double-release refusal, and reentrant acquisition refusal.
- Negative checks: four deliberate model/protocol mutations rejected by the law checker; affine guard copying rejected; actual runtime unconditional-unlock mutant detected by invalid-release test.
- Native concurrency: 12 runs with two client computations and worker pools configured at 1, 2, 4, and 8 CPU threads (three runs each). 240,000 acquisition attempts; 153,373 successes. Every success corresponded to one protected counter update. Zero observed overlapping critical sections; owner and active counters returned to zero. Nine runs observed failed acquisitions under contention. Scheduling varies, and not every multi-thread run must contend.

The overlap diagnostic increments an atomic active count after acquisition, records any prior active holder, performs the read/modify/write, decrements active before release, and checks the diagnostic total after both clients join. Protected update uses a separate atomic read and write, not a single atomic increment; equality of the final value with successful acquisitions checks for lost updates.

These tests support, but do not prove, the unsafe runtime adapter. The laws prove the pure permission/CAS model under the contract and ownership assumptions in IMPLEMENTATION.md. No GPU validation, fairness proof, or formal compiler verification is claimed. The kernel result checks the symbolic proof; finite model tests alone do not establish its unbounded-history theorem.

Compiler source tag inspected: bendlang/bend v2.0.39, a3efe8a3801f423827424227172eed9802c5e6cb. Current upstream guide/source was inspected initially; the generated C from the installed 2.0.39 compiler was then checked for the actual CAS and acquire-release implementation. No upstream checkout was modified.
