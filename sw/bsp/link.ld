OUTPUT_ARCH( "riscv" )
ENTRY(_start)

MEMORY
{
  BRAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

SECTIONS
{
  .text :
  {
    *(.text.init)
    *(.text .text.*)
    *(.rodata .rodata.*)
  } > BRAM

  .data :
  {
    . = ALIGN(4);
    PROVIDE( __global_pointer$ = . + 0x800 );
    *(.data .data.*)
    *(.sdata .sdata.*)
  } > BRAM

  .bss :
  {
    . = ALIGN(4);
    PROVIDE( _sbss = . );
    *(.sbss .sbss.*)
    *(.bss .bss.*)
    *(COMMON)
    . = ALIGN(4);
    PROVIDE( _ebss = . );
  } > BRAM

  PROVIDE( _estack = ORIGIN(BRAM) + LENGTH(BRAM) );
}