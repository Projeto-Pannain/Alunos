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

LINHA MACRO 
    PUSH AX 
    PUSH DX 

    MOV AH, 02 
    MOV DL, 10 
    INT 21H 
    MOV DL, 13 
    INT 21H 

    POP DX 
    POP AX 
ENDM 


VAL MACRO VALUE  ;teste de passar imediato como parametro (teste feito na linha 33)
MOV AX,VALUE
ENDM

.DATA
    TABELA DB 20 DUP('$'),1,2,3,?
           DB 20 DUP('$'),1,2,3,?
           DB 20 DUP('$'),1,2,3,?
           DB 20 DUP('$'),1,2,3,?
           DB 20 DUP('$'),1,2,3,?
.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX

    LEA AX,TABELA
    ADD AX,48;endereço do terceiro nome
    CALL EDIT_NOME

    MOV AX, 48
    CALL CALC_MEDIA 

    CALL IMP_TABELA 

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

IMP_TABELA PROC
; impressao da tabela completa com nomes, notas e media 
; entrada na memoria 
; saida na tela 
    S_REG AX, BX, CX, DX 

    XOR BX, BX

    ; impressao tabela inputada 
    MOV CH, 5 

    EXTERN: 
    XOR DI, DI

    MOV AH, 09 ; NOME 
    LEA DX, TABELA[BX][DI]
    INT 21H 

    MOV CL,4 
    MOV DI, 20 
        INTER: 
            MOV DL, ' '
            INT 21H 

            MOV AH, 02 ; NOTA 
            MOV DL, TABELA[BX][DI]
            OR DL, 30H 
            INT 21H 

            INC DI 
            DEC CL 
        JNZ INTER 

    ADD BX, 24 
    DEC CH 
    LINHA 
    JNZ EXTERN 
    
    R_REG AX, BX, CX, DX
    RET 
IMP_TABELA ENDP 

CALC_MEDIA PROC
; calculo da media 
; entrada AX como offset do aluno 
; saida na memoria 
    S_REG SI, BX, CX, DX 

    MOV BX, AX ; offset do aluno que representa a linha que deve pego as notas a calcular a media 
    XOR AX, AX
    MOV SI, 20 ; posicionar na linha da nota 1 
    MOV CX, 3 ; qnts notas devem ser adicionadas a soma da media 

    MED:
        ADD AL, TABELA[BX][SI]
        INC SI 
    LOOP MED 

    MOV DL, 3
    DIV DL 

    MOV TABELA[BX][SI], AL 

    R_REG SI, BX, CX, DX 
    RET
CALC_MEDIA ENDP 

END MAIN