SECTIONS {
  .text 0x00 : {
    *(.vectors)

    . = 0x98;

    *(.text)
  }
  .bss 0x100 : {
    *(.bss)
  }
}