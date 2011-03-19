.macro ISR op op2 op3 op4 op5 op6 op7 op8 op9
.align 2
\op \op2 \op3 \op4 \op5 \op6 \op7 \op8 \op9
.endm

.section .vectors

__vectors:
/*RESET*/       ISR RJMP main
/*INT0*/        ISR nop
/*INT1*/        ISR nop
/*INT2*/        ISR nop
/*INT3*/        ISR nop
/*INT4*/        ISR nop
/*INT5*/        ISR nop
/*INT6*/        ISR nop
/*INT7*/        ISR nop
/*PCINT0*/      ISR nop
/*USBGEN*/      ISR nop
/*USBEND*/      ISR nop
/*WDT*/         ISR nop
/*T2COMPA*/     ISR nop
/*T2COMPB*/     ISR nop
/*T2OVF*/       ISR nop
/*T1CAPT*/      ISR nop
/*T1COMPA*/     ISR nop
/*T1COMPB*/     ISR nop
/*T1COMPC*/     ISR nop
/*T1OVF*/       ISR nop
/*T0COMPA*/     ISR nop
/*T0COMPB*/     ISR nop
/*T0OVF*/       ISR nop
/*SPISTC*/      ISR nop
/*USART1RX*/    ISR nop
/*USART1UDRE*/  ISR nop
/*USART1TX*/    ISR nop
/*ACOMP*/       ISR nop
/*ADC*/         ISR nop
/*EEREADY*/     ISR nop
/*T3CAPT*/      ISR nop
/*T3COMPA*/     ISR nop
/*T3COMPB*/     ISR nop
/*T3COMPC*/     ISR nop
/*T3OVF*/       ISR nop
/*TWI*/         ISR nop
/*SPMREADY*/    ISR nop
