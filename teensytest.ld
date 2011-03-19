SECTIONS {
  .text 0x00 : {
    *(.vectors)

    . = 0x80;

    *(.text)
  }
}