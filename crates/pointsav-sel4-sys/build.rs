use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let sdk_include = manifest_dir.join("../../sovereign-sdk/include");

    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed={}", sdk_include.display());

    // Validation: Ensure the SDK was built with the new script
    if !sdk_include.join("sel4/sel4_arch/simple_types.h").exists() {
        panic!("\n\n❌ ARTIFACT OUTDATED: Run './build_sdk_production.sh' to fetch x86_64 headers.\n\n");
    }

    let bindings = bindgen::Builder::default()
        .header(format!("{}/sel4/sel4.h", sdk_include.display()))
        .clang_arg(format!("-I{}", sdk_include.display()))
        // Force include our config so CONFIG_WORD_SIZE is set
        .clang_arg("-include")
        .clang_arg("sel4/autoconf.h")
        .use_core()
        .ctypes_prefix("core::ffi")
        .blocklist_item("seL4_CPtr") 
        .generate();

    match bindings {
        Ok(b) => {
            let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
            b.write_to_file(out_path.join("bindings.rs")).expect("Couldn't write bindings!");
        },
        Err(_) => {
            panic!("\n\n❌ CLANG FAIL: Run 'cargo build -vv' to inspect.\n\n");
        }
    }
}
