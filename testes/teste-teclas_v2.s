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

    /* Mostra 0 (primeiro byte da tabela: 0x3F) inicialmente no HEX0 */
    ldbu  r8, 0(r14)
    stwio r8, 0(r11)

POLL:
    /* Fica aguardando ate o botao KEY2 (bit 2 -> 0x4) ser pressionado */
    ldwio r13, 0(r12)
    andi  r13, r13, 0x4
    beq   r13, r0, POLL

    /* Limpa a flag do Edge Capture escrevendo 1s */
    movi  r8, 0xF
    stwio r8, 0(r12)

    /* Le os switches e isola SW[17:14] (as 4 chaves mais a esquerda) */
    ldwio r8, 0(r10)
    srli  r8, r8, 14
    andi  r8, r8, 0xF

    /* Busca o codigo correspondente na tabela e atualiza o HEX0 */
    add   r9, r14, r8
    ldbu  r9, 0(r9)
    stwio r9, 0(r11)

    br    POLL
.end