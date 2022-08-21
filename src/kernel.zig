// Import the stivale2 protocol
const zigvale = @import("zigvale").v2;

// Allocate a stack
// We add an extra bit in the form of a null terminator at the end, which allows us to point to the end of the stack
export var stack_bytes: [16 * 1024:0]u8 align(16) linksection(".bss") = undefined;

// This is the stivale2 header. Contained in the ELF section named '.stivale2hdr', it is detected
// by a stivale2-compatible bootloader, and provides the stack pointer, flags, tags, and (optionally) entry point.
export const header linksection(".stivale2hdr") = zigvale.Header{
    // The stack address for when the kernel is loaded. On x86, the stack grows downwards, and so
    // we pass a pointer to the top of the stack.
    // TODO workaround for ziglang/zig#12240
    //.stack = &stack_bytes[stack_bytes.len],
    .stack = &stack_bytes[@sizeOf(@TypeOf(stack_bytes)) - 1],

    // These flags communicate options to the bootloader
    .flags = .{
        // Tells the bootloader that this is a higher half kernel
        .higher_half = 1,
        // Tells the bootloader to enable protected memory ranges (PMRs)
        .pmr = 1,
    },

    // Pointer to the first in a linked list of tags.
    // Tags communicate to the bootloader various options which your kernel requires.
    .tags = &term_tag.tag,
};

// This tag tells the bootloader to set up a terminal for your kernel to use
const term_tag = zigvale.Header.TerminalTag{
    .tag = .{ .identifier = .terminal, .next = &fb_tag.tag },
};

// This tag tells the bootloader to select the best possible video mode
const fb_tag = zigvale.Header.FramebufferTag{};

// This generates and exports the entry point for the kernel.
// Stivale2-compatible bootloaders are capable of using the pointer to the entry point in
// zigvale.Header. This has the benefit of allowing you to add support for multiple bootloader
// protocols, using multiple entry points.
comptime {
    const entry = zigvale.entryPoint(kmain);
    @export(entry, .{ .name = "_start", .linkage = .Strong });
}

// This is the definition of your main kernel function.
// The generated entry point passes the parsed stivale2 structure.
fn kmain(stivale_info: zigvale.Struct.Parsed) noreturn {
    if (stivale_info.terminal) |term| {
        term.print("Hello, world from Zig {}!\n", .{@import("builtin").zig_version});
    }

    // Halts the kernel after execution
    halt();
}

fn halt() noreturn {
    // Loop in case an interrupt resumes execution
    while (true) {
        asm volatile ("hlt");
    }
}
