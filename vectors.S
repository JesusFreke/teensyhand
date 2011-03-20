.macro ISR op op2 op3 op4 op5 op6 op7 op8 op9
.align 2
\op \op2 \op3 \op4 \op5 \op6 \op7 \op8 \op9
.endm

.section .vectors

__vectors:
/*RESET*/       ISR rjmp main
/*INT0*/        ISR reti
/*INT1*/        ISR reti
/*INT2*/        ISR reti
/*INT3*/        ISR reti
/*INT4*/        ISR reti
/*INT5*/        ISR reti
/*INT6*/        ISR reti
/*INT7*/        ISR reti
/*PCINT0*/      ISR reti
/*USBGEN*/      ISR rjmp usb_gen
/*USBENP*/      ISR reti
/*WDT*/         ISR reti
/*T2COMPA*/     ISR reti
/*T2COMPB*/     ISR reti
/*T2OVF*/       ISR reti
/*T1CAPT*/      ISR reti
/*T1COMPA*/     ISR rjmp t1_int
/*T1COMPB*/     ISR reti
/*T1COMPC*/     ISR reti
/*T1OVF*/       ISR reti
/*T0COMPA*/     ISR reti
/*T0COMPB*/     ISR reti
/*T0OVF*/       ISR reti
/*SPISTC*/      ISR reti
/*USART1RX*/    ISR reti
/*USART1UDRE*/  ISR reti
/*USART1TX*/    ISR reti
/*ACOMP*/       ISR reti
/*ADC*/         ISR reti
/*EEREADY*/     ISR reti
/*T3CAPT*/      ISR reti
/*T3COMPA*/     ISR reti
/*T3COMPB*/     ISR reti
/*T3COMPC*/     ISR reti
/*T3OVF*/       ISR reti
/*TWI*/         ISR reti
/*SPMREADY*/    ISR reti
