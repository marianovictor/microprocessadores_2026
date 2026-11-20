.data
TABELA_7SEG:
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07
    .byte 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

.section .reset, "ax"
    movia r2, _start
    jmp   r2

.section .exceptions, "ax"
.global RTI
RTI:
    rdctl et, ipending
    andi  et, et, 0x2           /* Verifica IRQ 1 (Pushbuttons) */
    beq   et, r0, FIM_RTI

    subi  ea, ea, 4             /* Ajuste obrigatorio para IRQ de hardware */
    movia et, 0x1000005C
    movi  r18, 0xF              /* Limpa Edge Capture e ativa flag r18 != 0 */
    stwio r18, 0(et)

FIM_RTI:
    eret

.text
.global _start
_start:
    movia r10, 0x10000030       /* Base HEX7..HEX4 */
    movia r14, TABELA_7SEG
    movi  r16, 0                /* Contador livre (semente) */
    movi  r17, -1               /* Ultimo digito sorteado (-1 = nenhum) */
    movi  r18, 1                /* Flag = 1 para ja sortear ao ligar */

    /* Apaga HEX3..HEX0 e limpa cliques antigos dos botoes */
    movia r8, 0x10000020
    stwio r0, 0(r8)
    movia r8, 0x1000005C
    movi  r9, 0xF
    stwio r9, 0(r8)

    /* Habilita interrupcao do KEY1 (0x2) e liga IRQ 1 no processador */
    movia r8, 0x10000058
    movi  r9, 0x2
    stwio r9, 0(r8)
    wrctl ienable, r9
    movi  r8, 0x1
    wrctl status, r8

MAIN:
    addi  r16, r16, 1           /* Gira continuamente enquanto espera o clique */
    beq   r18, r0, MAIN         /* Se KEY1 nao foi apertado, continua girando */

    mov   r18, r0               /* Zera a flag */
    andi  r8, r16, 0xF          /* Sorteia numero de 0..15 a partir de r16 */
    bne   r8, r17, EXIBE        /* Se nao repetiu o anterior, exibe */

    addi  r8, r8, 1             /* Se repetiu, avanca +1 (0..15) */
    andi  r8, r8, 0xF

EXIBE:
    mov   r17, r8               /* Salva como ultimo digito sorteado */
    add   r9, r14, r8
    ldbu  r9, 0(r9)             /* Converte para 7 segmentos */
    slli  r9, r9, 24            /* Desloca para o HEX7 */
    stwio r9, 0(r10)
    br    MAIN
.end