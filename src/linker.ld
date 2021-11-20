PHDRS
{
	null	PT_NULL	FLAGS(0);					/* Null segment */
	text	PT_LOAD	FLAGS((1 << 2) | (1 << 0));	/* Readable & Executable */
	rodata	PT_LOAD	FLAGS((1 << 2));			/* Readable */
	data	PT_LOAD	FLAGS((1 << 2) | (1 << 1)); /* Readable & Writable */
}

SECTIONS {
	. = 0xffffffff80100000; /* Place kernel in higher half */

	.text : {
		*(.text*)
	} :text

	. = ALIGN(4K);

	.stivale2hdr : {
		KEEP(*(.stivale2hdr))
	} :rodata

	.rodata : {
		*(.rodata*)
	} :rodata

	. = ALIGN(4K);

	.data : {
		*(.data*)
	} :data

	.bss : {
		*(COMMON)
		*(.bss*)
	} :data
}
