.data
TABELA_7SEG:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07
    .byte 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

/* Tabela de 32 bytes (0..F) sem vizinhos iguais para evitar repeticao */
TABELA_ALEATORIA:
    .byte 0x0A, 0x03, 0x0E, 0x01, 0x0C, 0x07, 0x0F, 0x04
    .byte 0x09, 0x02, 0x0D, 0x06, 0x0B, 0x00, 0x08, 0x05
    .byte 0x0E, 0x09, 0x04, 0x0F, 0x02, 0x0B, 0x06, 0x0D
    .byte 0x01, 0x08, 0x03, 0x0C, 0x05, 0x0A, 0x00, 0x07

.align 2
ALVO_ATUAL:    .word 0          /* Ultimo digito sorteado (0..15) */
INDICE_PRNG:   .word 0          /* Posicao atual na TABELA_ALEATORIA (0..31) */
SORTEAR_NOVO:  .word 1          /* Comeca em 1 para sortear logo ao iniciar */

/* ---------------------------------------------------------
 * VETOR DE RESET (Endereco 0x00000000)
 * --------------------------------------------------------- */
.section .reset, "ax"
    movia r2, _start
    jmp   r2

/* ---------------------------------------------------------
 * VETOR DE EXCECAO / INTERRUPCAO (Endereco 0x00000020)
 * --------------------------------------------------------- */
.section .exceptions, "ax"
.global RTI
RTI:
    subi  sp, sp, 24
    stw   et, 0(sp)
    rdctl et, ipending
    beq   et, r0, FIM_RTI       /* Ignora se nao for interrupcao externa */

    subi  ea, ea, 4             /* Ajuste obrigatorio para IRQ de hardware */
    stw   ea, 4(sp)
    stw   ra, 8(sp)
    stw   r4, 12(sp)
    stw   r5, 16(sp)
    stw   r6, 20(sp)

    andi  r4, et, 0x2           /* Verifica IRQ 1 (Pushbuttons) */
    beq   r4, r0, RESTAURA
    call  EXT_IRQ1

RESTAURA:
    ldw   ea, 4(sp)
    ldw   ra, 8(sp)
    ldw   r4, 12(sp)
    ldw   r5, 16(sp)
    ldw   r6, 20(sp)

FIM_RTI:
    ldw   et, 0(sp)
    addi  sp, sp, 24
    eret

/* ---------------------------------------------------------
 * PROGRAMA PRINCIPAL
 * --------------------------------------------------------- */
.text
.global _start
_start:
    movia sp, 0x02000000        /* Inicializa pilha na SDRAM */

    /* Apaga todos os displays inicialmente */
    movia r4, 0x10000020
    stwio r0, 0(r4)
    movia r4, 0x10000030
    stwio r0, 0(r4)

    /* Liga o Interval Timer em contagem livre (sem IRQ) apenas como semente */
    movia r4, 0x10002000
    movui r5, 0xFFFF
    stwio r5, 8(r4)             /* periodl */
    stwio r5, 12(r4)            /* periodh */
    movi  r5, 0x6               /* START (4) | CONT (2), ITO = 0 */
    stwio r5, 4(r4)

    /* Habilita interrupcao apenas do KEY1 (bit 1 -> 0x2) */
    movia r4, 0x1000005C
    movi  r5, 0xF
    stwio r5, 0(r4)             /* Limpa cliques antigos no Edge Capture */
    movia r4, 0x10000058
    movi  r5, 0x2
    stwio r5, 0(r4)             /* interruptmask = KEY1 */

    /* Habilita IRQ 1 e PIE global no processador */
    movi  r4, 0x2
    wrctl ienable, r4
    movi  r4, 0x1
    wrctl status, r4

MAIN:
    /* 1. Espelha SW[17:14] continuamente no HEX0 */
    movia r4, 0x10000040
    ldwio r5, 0(r4)
    srli  r5, r5, 14
    andi  r5, r5, 0xF

    movia r6, TABELA_7SEG
    add   r6, r6, r5
    ldbu  r6, 0(r6)
    movia r4, 0x10000020
    stwio r6, 0(r4)

    /* 2. Verifica se precisa sortear um novo elemento para o HEX7 */
    movia r4, SORTEAR_NOVO
    ldw   r5, 0(r4)
    beq   r5, r0, MAIN

    stw   r0, 0(r4)             /* Limpa a flag */
    call  SORTEIA_ALVO
    br    MAIN

/* ---------------------------------------------------------
 * SUB-ROTINA: SORTEIA_ALVO (Sorteia 0..F e mostra no HEX7)
 * --------------------------------------------------------- */
SORTEIA_ALVO:
    /* Captura a contagem rapida do timer (snapl) no momento do clique */
    movia r4, 0x10002010
    stwio r0, 0(r4)
    ldwio r5, 0(r4)

    /* Calcula proximo indice na tabela aleatoria (0..31) */
    movia r4, INDICE_PRNG
    ldw   r6, 0(r4)
    add   r6, r6, r5
    addi  r6, r6, 1
    andi  r6, r6, 0x1F

    /* Busca digito candidato */
    movia r7, TABELA_ALEATORIA
    add   r7, r7, r6
    ldbu  r7, 0(r7)
    andi  r7, r7, 0x0F

    /* Se for igual ao ALVO_ATUAL, avanca +1 na tabela */
    movia r8, ALVO_ATUAL
    ldw   r9, 0(r8)
    bne   r7, r9, EXIBE_SORTEADO

    addi  r6, r6, 1
    andi  r6, r6, 0x1F
    movia r7, TABELA_ALEATORIA
    add   r7, r7, r6
    ldbu  r7, 0(r7)
    andi  r7, r7, 0x0F

EXIBE_SORTEADO:
    stw   r6, 0(r4)             /* Salva novo INDICE_PRNG */
    stw   r7, 0(r8)             /* Salva novo ALVO_ATUAL */

    /* Converte para 7 segmentos e desloca 24 bits para cair no HEX7 */
    movia r4, TABELA_7SEG
    add   r4, r4, r7
    ldbu  r5, 0(r4)
    slli  r5, r5, 24            /* Bits [31:24] de 0x10000030 = HEX7 */

    movia r4, 0x10000030
    stwio r5, 0(r4)
    ret

/* ---------------------------------------------------------
 * ISR DOS PUSHBUTTONS (IRQ 1 - KEY1)
 * --------------------------------------------------------- */
EXT_IRQ1:
    movia r4, 0x1000005C
    ldwio r5, 0(r4)
    movi  r6, 0xF
    stwio r6, 0(r4)             /* Limpa Edge Capture */

    andi  r6, r5, 0x2           /* Confere se foi KEY1 (bit 1) */
    beq   r6, r0, FIM_EXT_IRQ1

    movia r4, SORTEAR_NOVO
    movi  r5, 1
    stw   r5, 0(r4)

FIM_EXT_IRQ1:
    ret
.end