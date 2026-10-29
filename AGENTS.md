# Project instructions

Robert authorized public publication of the tested implementation and task-local independent-kernel setup. Keep toolchains, build outputs, credentials, and unrelated files out of Git.

Use Bend 2.0.39. Do not change global settings, deploy, or use paid compute without separate approval. Set BEND_NO_TELEMETRY=1 when invoking Bend. Run tests/test.mjs after relevant changes.

Preserve the distinction between the proved permission/CAS model, tested unsafe shared-array adapter, and trusted compiler/runtime. Never describe tests or BendTT export as an independent kernel verdict. Never claim protection from unguarded access. Keep mutual-exclusion safety separate from fairness, starvation, and cleanup.
