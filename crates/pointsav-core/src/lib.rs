#![no_std]

use core::ops::Range;

#[derive(Debug, Clone, Copy)]
pub struct MemoryRegion {
    pub start: usize,
    pub size: usize,
    pub region_type: RegionType,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum RegionType {
    Untyped,  
    Device,   
    Reserved, 
}

pub struct CapabilityAccountant {
    pub total_memory: usize,
    pub allocated_slots: Range<usize>,
}

impl CapabilityAccountant {
    pub const fn new() -> Self {
        Self {
            total_memory: 0,
            allocated_slots: 0..0,
        }
    }
}
