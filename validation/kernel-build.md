# Independent kernel build

Verified on 2026-10-30. All build inputs and outputs remained in ignored project directories; no global toolchain or configuration was changed.

- Lean: 4.34.0, arm64 macOS, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.
- Official archive: `lean-4.34.0-darwin_aarch64.tar.zst` from [Lean's v4.34.0 release](https://github.com/leanprover/lean4/releases/tag/v4.34.0).
- Archive SHA-256, checked against the official release asset digest: `69f263fa6e21bbc2466bbfb1affcd92479ee2714c883a07de548e099a5922932`.
- Kernel source: unmodified `bend2/bendtt.lean` from [Bend v2.0.39](https://github.com/bendlang/bend/blob/v2.0.39/bend2/bendtt.lean), commit `a3efe8a3801f423827424227172eed9802c5e6cb`.
- Kernel source SHA-256: `d7268ff461de974bd4cd875d9766c71c62ee6b2e6411b9bab84839870db68a80`.

With the official archive extracted under `.tools` and that pinned source copied to `.build/kernel`, run from `.build/kernel`:

```sh
../../.tools/lean-4.34.0-darwin_aarch64/bin/lean -c bendtt.c bendtt.lean
../../.tools/lean-4.34.0-darwin_aarch64/bin/leanc -O3 -DNDEBUG bendtt.c -o bendtt
```

Then run from the project root:

```sh
BEND=/absolute/path/to/bend BENDTT="$PWD/.build/kernel/bendtt" npm run test:kernel
```

The test invokes Bend's supported `BENDTT` configuration, checks the exact positive verdict, exports the elaboration, changes the initial-safety conclusion from True to False without changing its proof, and requires independent-kernel rejection. See [kernel.txt](kernel.txt) for actual output. The runtime adapter remains outside this proof scope.
