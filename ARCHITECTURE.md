# Toolchain Architecture

## Component 1: `bitfield-rs`
A Rust rewrite of `bitfield_gen.py` AND `umm.py`.
- **Input:** seL4 `.bf` specification files.
- **Output:** Rust `struct`s with `#[repr(C)]` and verified bit-packing.
- **Safety:** Uses Rust's type system to ensure overlapping bits are impossible.
- **Legacy Note:** Must reimplement the allocation logic currently found in `umm.py`.

## Component 2: `capdl-loader-rs`
A Rust implementation of the CapDL (Capability Distribution Language) loader.
- Replaces the C++ based CapDL initializer.
- Ensures the "Root Task" starts in a known, safe state.

## Component 3: The Sovereign Orchestrator
A master CLI tool to replace `repo` and `cmake`.
- Command: `pst build --target imac`
- Behavior: Fetches sources, verifies signatures, compiles toolchain, builds kernel.
