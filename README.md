# Zigvale Barebones Kernel
This is a brief example of how to use the Zigvale library for the stivale2 boot protocol in a simple kernel. Zigvale can be found [here](https://github.com/ominitay/zigvale).

## Build
To build this, you will need a recent build of Zig, and the `zigmod` package manager.

``` sh
# Fetch Zigvale & Limine bootloader
zigmod fetch

# Build the kernel
zig build iso
```

## Run
### QEMU
To run this with QEMU, you (obviously) need QEMU installed with x86 support. 

``` sh
# Run the kernel in QEMU
zig build run
```

### Bare Metal
The kernel is built for x86. To run it, flash the iso you built (found in `zig-out/iso/zigvale-barebones.iso`) to a removable medium, and boot to it.
