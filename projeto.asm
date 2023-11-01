.MODEL SMALL
.STACK 100h
S_REG MACRO WX,XX,YX,ZX
    ;empilha 4 registradores escolhidos
    PUSH WX
    PUSH XX
    PUSH YX
    PUSH ZX
ENDM
R_REG MACRO WX,XX,YX,ZX
    ;restaura os 4 registradores escolhidos previamente
    POP ZX
    POP YX
    POP XX
    POP WX
ENDM

VAL MACRO VALUE  ;teste de passar imediato como parametro (teste feito na linha 33)
MOV AX,VALUE
ENDM

.DATA
    TABELA DB 20 DUP(?),?,?,?,?
           DB 20 DUP(?),?,?,?,?
           DB 20 DUP(?),?,?,?,?
           DB 20 DUP(?),?,?,?,?
           DB 20 DUP(?),?,?,?,?
.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

    VAL 13

    LEA AX,TABELA
    ADD AX,48;endereço do terceiro nome
    CALL EDIT_NOME

    MOV AH,09
    LEA DX,TABELA
    ADD DX,48
    INT 21h

    MOV AH,4Ch
    INT 21h
MAIN ENDP

EDIT_NOME PROC
    ;modifica o nome escolhido
    ;entrada em AX, offset do nome
    ;saida na memoria, modificando o nome
    S_REG BX,CX,DX,DI

    MOV BX,AX       ;endereço da linha
    XOR DI,DI       ;endereço da coluna
    MOV CX,19       ;max de caracteres (tem que ser 19 para o vigesimo ser "$")
    MOV AH,01
    INP_NOME:INT 21h
        CMP AL,13
        JE END_INP_NOME
        MOV BYTE PTR [BX][DI],AL
        INC DI
    LOOP INP_NOME   ;coleta os caracteres e guarda na matriz
    END_INP_NOME:
    MOV BYTE PTR [BX][DI],"$"  ;fim do nome

    R_REG BX,CX,DX,DI
    RET
EDIT_NOME ENDP

END MAIN