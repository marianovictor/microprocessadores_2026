.data
TABELA_7SEG:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07
    .byte 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

.text
.global _start
_start:
    movia r10, 0x10000040       /* Endereco dos switches (SW17..SW0) */
    movia r11, 0x10000020       /* Endereco dos displays HEX3..HEX0 */
    movia r12, 0x1000005C       /* Endereco do Edge Capture dos botoes */
    movia r14, TABELA_7SEG      /* Endereco base da tabela de 7 segmentos */

    /* Apaga HEX7..HEX4 e limpa cliques antigos dos botoes */
    movia r8, 0x10000030
    stwio r0, 0(r8)
    movi  r8, 0xF
    stwio r8, 0(r12)

POLL:
    /* Le SW[17:14] e desloca para os 4 bits menos significativos */
    ldwio r8, 0(r10)
    srli  r8, r8, 14
    andi  r8, r8, 0xF

    /* Converte para 7 segmentos e mostra no HEX0 */
    add   r9, r14, r8
    ldb   r9, 0(r9)
    stwio r9, 0(r11)

    /* Verifica se KEY2 (bit 2 -> 0x4) foi pressionado */
    ldwio r13, 0(r12)
    andi  r15, r13, 0x4
    bne   r15, r0, LIMPA_DISPLAY

    br    POLL

LIMPA_DISPLAY:
    movi  r8, 0xF               /* Limpa a flag do Edge Capture */
    stwio r8, 0(r12)
    stwio r0, 0(r11)            /* Apaga HEX3..HEX0 */

    /* Guarda o valor atual das chaves para esperar uma mudanca */
    ldwio r16, 0(r10)
    srli  r16, r16, 14
    andi  r16, r16, 0xF

ESPERA_MUDANCA:
    ldwio r8, 0(r10)
    srli  r8, r8, 14
    andi  r8, r8, 0xF
    beq   r8, r16, ESPERA_MUDANCA

    br    POLL
.end