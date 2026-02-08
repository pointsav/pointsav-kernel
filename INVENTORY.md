# Toolchain Inventory & Heritage

> **Status:** Active Tracking
> **Objective:** Document every external script required to build the kernel, prior to Rust rewriting.

## 📦 Verified Scripts (The "Python Bridge")
These scripts are currently vendored in `package-system/tools` to enable offline builds. They are the primary targets for replacement by `pointsav-toolchain`.

| Script | Full Name | Purpose | Replacement Target |
| :--- | :--- | :--- | :--- |
| **`bitfield_gen.py`** | Bitfield Generator | Generates C structs and proofs from `.bf` specs. | `bitfield-rs` |
| **`umm.py`** | **Unique Memory Manager** | A dependency of `bitfield_gen.py`. Handles memory allocation logic for bitfields. | `bitfield-rs` (Internal Logic) |
| **`hardware_gen.py`** | Hardware Generator | Parses Device Trees (`.dts`) into kernel headers. | `hardware-rs` |

### 🛑 Critical Dependency Note: `umm.py`
*Discovered: Feb 2026*
During the "Hermetic Build" transition of the Sovereign SDK, `bitfield_gen.py` failed with `ModuleNotFoundError: No module named 'umm'`. This script is not a standalone tool but a **library** used by the generators to track unique memory slots. It must be present in the `tools/` root or `PYTHONPATH` for generation to succeed.
