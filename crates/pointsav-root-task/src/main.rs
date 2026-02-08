#![no_std]
#![no_main]

use core::panic::PanicInfo;
use pointsav_core::CapabilityAccountant;

#[no_mangle]
#[link_section = ".text._start"]
pub extern "C" fn _start() -> ! {
    let _accountant = CapabilityAccountant::new();
    
    boot_sequence_complete();
}

fn boot_sequence_complete() -> ! {
    loop {
        core::hint::spin_loop();
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
