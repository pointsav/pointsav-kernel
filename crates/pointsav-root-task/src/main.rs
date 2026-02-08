#![no_std]
#![no_main]

use core::panic::PanicInfo;

// 2030 Standard: Minimalist Entry Point
#[no_mangle]
pub extern "C" fn _start() -> ! {
    // 1. Root-Task takes control of capabilities
    // 2. Initialises Hardware
    // 3. Spawns VMM
    
    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
