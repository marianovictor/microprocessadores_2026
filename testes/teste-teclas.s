.data
TABELA_7SEG:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07
    .byte 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

.text
/* TRATAMENTO DE EXCECAO  */
.org 0x20
RTI:
    rdctl et, ipending          /* Le as interrupcoes de hardware pendentes */
    beq   et, r0, FIM_RTI       /* Se for 0, nenhuma interrupcao externa ocorreu */

    subi  ea, ea, 4             /* Decrementa ea em 4 (obrigatorio para interrupcao de hardware) */

    andi  r13, et, 0x2          /* Verifica se a interrupcao veio dos pushbuttons */
    beq   r13, r0, FIM_RTI

    call  EXT_IRQ1              /* Chama a sub-rotina de tratamento dos botoes */

FIM_RTI:
    eret                        /* Retorna da interrupcao */


.global _start
_start:
    movia r10, 0x10000040       /* Endereco dos switches (SW17..SW0) */
    movia r11, 0x10000020       /* Endereco dos displays HEX3..HEX0 */
    movia r14, TABELA_7SEG      /* Endereco base da tabela de 7 segmentos */
    movi  r18, -1               /* Guarda o ultimo valor exibido (-1 forca atualizar no inicio) */

    /* Apaga HEX7..HEX4 e limpa cliques antigos no Edge Capture */
    movia r8, 0x10000030
    stwio r0, 0(r8)
    movia r8, 0x1000005C
    movi  r9, 0xF
    stwio r9, 0(r8)

    /* 1. Habilita interrupcao apenas do KEY2 (bit 2 -> 0x4) no dispositivo */
    movia r8, 0x10000058        /* Registrador interruptmask dos pushbuttons */
    movi  r9, 0x4
    stwio r9, 0(r8)

    /* 2. Habilita IRQ1 (pushbuttons) no processador */
    movi  r8, 0x2
    wrctl ienable, r8

    /* 3. Habilita interrupcoes globais no processador (bit PIE) */
    movi  r8, 0x1
    wrctl status, r8

MAIN:
    /* Le SW[17:14] e desloca para os 4 bits menos significativos */
    ldwio r8, 0(r10)
    srli  r8, r8, 14
    andi  r8, r8, 0xF

    /* Se as chaves nao mudaram (ou display foi limpo pelo KEY2), aguarda */
    beq   r8, r18, MAIN

    /* Atualiza o ultimo valor e exibe no HEX0 */
    mov   r18, r8
    add   r9, r14, r8
    ldbu  r9, 0(r9)
    stwio r9, 0(r11)

    br    MAIN


/* INTERRUPCAO DOS PUSHBUTTONS*/
EXT_IRQ1:
    movia r4, 0x1000005C        /* Endereco do Edge Capture dos botoes */
    ldwio r12, 0(r4)            /* Le qual botao gerou a interrupcao antes de limpar */

    /* Limpa o pedido de interrupcao no dispositivo escrevendo 1s */
    movi  r5, 0xF
    stwio r5, 0(r4)

    /* Confere se o clique foi no KEY2 (bit 2 -> 0x4) */
    andi  r12, r12, 0x4
    beq   r12, r0, FIM_EXT_IRQ1

    /* Apaga HEX3..HEX0 e salva a posicao atual das chaves em r18 */
    stwio r0, 0(r11)
    ldwio r18, 0(r10)
    srli  r18, r18, 14
    andi  r18, r18, 0xF

FIM_EXT_IRQ1:
    ret
.end