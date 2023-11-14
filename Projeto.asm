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
MULT MACRO XL ;multiplica AL por XL
    PUSH BX

    MOV BL,XL
    MUL BL

    POP BX
ENDM
DIVI MACRO XL ;divide AL por XL
    PUSH BX

        MOV BL,10
        CBW
        DIV BL

    POP BX
ENDM
PRINT MACRO TEXT ;imprime texto em TEXT, nn sei se eh necessario
    PUSH AX
    PUSH DX

    MOV AH,09
    LEA DX,TEXT
    INT 21h

    POP DX
    POP AX
ENDM
CLR MACRO
    PUSH AX
    PUSH CX
    PUSH DX

    MOV CX,24
    MOV AH,02
    MOV DL,10
    NEXT_LINE:INT 21h
    LOOP NEXT_LINE

    POP DX
    POP CX
    POP AX
ENDM

.DATA
    TABELA DB 19 DUP(?),'$',4 DUP(?) ;20 bytes para nome, 4 para notas e media
           DB 19 DUP(?),'$',4 DUP(?)
           DB 19 DUP(?),'$',4 DUP(?)
           DB 19 DUP(?),'$',4 DUP(?)
           DB 19 DUP(?),'$',4 DUP(?)
    MSG1 DB "Nome:$"
    MSG2 DB "Nota 1:$"
    MSG3 DB "Nota 2:$"
    MSG4 DB "Nota 3:$"
    MSG5 DB "Qual aluno? (digite o nome):$"
    MSG6 DB "Nenhum aluno possui esse nome.$"
    TEMP DB 19 DUP(?),'$'
.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    MOV ES,AX

    CLR

    CALL EDIT_TABELA

    CALL CHEC_NOME

    CALL IMP_TABELA 

    MOV AH,4Ch
    INT 21h
MAIN ENDP

EDIT_NOME PROC
    ;modifica o nome escolhido
    ;entrada em AX, offset do nome
    ;saida na memoria, modificando o nome
    S_REG AX,CX,DX,DI

    MOV DI,AX       ;offset do nome
    MOV CX,19       ;max de caracteres (tem que ser 19 para o vigesimo ser "$")
    CLD
    MOV AH,01
    INT 21H

    INP_NOME:
        CMP AL,0Dh
        JE END_INP_NOME

        CMP AL,8h       ;backspace
        JNE NOT_DELETE
            DEC DI
            INC CX
        JMP NEXT_INP_NOME

        NOT_DELETE:
            STOSB
        NEXT_INP_NOME:
        INT 21h
    LOOP INP_NOME
    END_INP_NOME:

    R_REG AX,CX,DX,DI
    RET
EDIT_NOME ENDP

EDIT_NOTA PROC
    ;modifica a nota escolhida
    ;entrada em AX, offset do aluno (0,24,48,72,96) e em BX, offset da nota (20 a 22)
    ;saida na memoria, modificando as notas
    S_REG AX,BX,CX,DX
    PUSH DI

    MOV DI,BX  ;offset da nota
    MOV BX, AX ;offset do aluno
    MOV CX,5
    XOR DL,DL  ;valor a ser guardado

    INP_NOTA:MOV AH,01
        INT 21h
        CMP AL,13
        JE END_INP_NOTA

        CMP AL,8
        JNE NOT_DEL
            INC CX
            MOV AL,DL
            DIVI 10
            MOV DL,AL
        JMP INP_NOTA

        NOT_DEL:
        AND AL,0Fh
        XCHG DL,AL      ;permite a multiplicaçao da soma atual por 10 para incluir o prox digito no caso de nota 10
        MULT 10
        XCHG DL,AL      ;retorna a soma pra DL
        ADD DL,AL
    LOOP INP_NOTA       ;guarda o valor da nota no espaço determinado pelos offsets

    LINHA
    END_INP_NOTA:
    MOV BYTE PTR [BX][DI], DL  ;nn importa qual matriz, é especificado que é uma matriz DB

    POP DI
    R_REG AX,BX,CX,DX
    RET
EDIT_NOTA ENDP

EDIT_TABELA PROC
    ;modifica a tabela como um todo
    ;sem entrada
    ;saida na memoria
    S_REG AX,BX,CX,DX
    PUSH SI

    MOV CX,1      ;loop externo
    ;;;as linhas abaixo e acima devem ser MOV CX,5 e LEA AX,TABELA, se estao diferentes, é um teste
    MOV AX,48     ;offset do aluno

    INP_TABELA:
        MOV DL,3      ;loop interno
        LEA SI,MSG2   ;guarda o endereço da mensagem "Nota 1:$"
        XOR BX,BX     ;offset da coluna

        PRINT MSG1
        CALL EDIT_NOME

        MOV BX,20     ;primeira nota
        INP_NOTAS:
            
            PUSH AX
            PUSH DX
            MOV AH,09
            MOV DX,SI ;imprime a mensagem atual
            INT 21h
            POP DX
            POP AX

            CALL EDIT_NOTA
            
            INC BX    ;prox nota
            ADD SI,8  ;prox mensagem
        DEC DL
        JNZ INP_NOTAS

        LINHA

        CALL CALC_MEDIA

        ADD AX,24     ;prox aluno
    LOOP INP_TABELA

    POP SI
    R_REG AX,BX,CX,DX
    RET
EDIT_TABELA ENDP

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

    ;ideia: nao colocar o $ no fim e sempre imprimir 19 caracteres para manter o mesmo espaço de txto

    MOV AH, 09 ; NOME 
    LEA DX, TABELA[BX][DI]
    INT 21H 

    MOV AH,02
    MOV DL,20h ;imprime um espaço
    INT 21h

    MOV CL,4   ;imprime as 3 notas e a media
    MOV DI,20  ;primeira nota
        INTER: 
            MOV DL, ' '
            INT 21H 

            MOV AH, 02 ; NOTA 
            MOV DL, TABELA[BX][DI]
            CMP DL,10
            JNE NOT_TEN

            ADD DL,27h ;imprime o 1
            INT 21h
            XOR DL,DL  ;imprime o 0

            NOT_TEN:
            OR DL, 30H 
            INT 21H 

            INC DI 
            DEC CL 
        JNZ INTER 

    ADD BX, 24 
    LINHA 
    DEC CH 
    JNZ EXTERN 
    
    R_REG AX,BX,CX,DX
    RET 
IMP_TABELA ENDP 

CALC_MEDIA PROC
; calculo da media 
; entrada AX como offset do aluno 
; saida na memoria 
    S_REG SI, BX, CX, DX 
    PUSH AX

    MOV BX, AX ; offset do aluno que representa a linha que deve pego as notas a calcular a media 
    XOR AX,AX
    MOV SI, 20 ; posicionar na linha da nota 1 
    MOV CX, 3 ; qnts notas devem ser adicionadas a soma da media 

    MED:
        ADD AL, TABELA[BX][SI]
        INC SI 
    LOOP MED 
 
    MOV DL, 3
    DIV DL

    MOV TABELA[BX][SI], AL 

    POP AX
    R_REG SI, BX, CX, DX  
    RET
CALC_MEDIA ENDP 

CHEC_NOME PROC
    ;checa se o nome inputado esta na tabela
    ;entrada pelo teclado
    ;saida em AX, offset do nome igual, retorna FFFFh se nao for igual a nenhum
    S_REG CX,DX,SI,DI

    MOV AH,09
    LEA DX,MSG5
    INT 21h

    LEA AX,TEMP
    CALL EDIT_NOME;pega nome para comparar

    LEA SI,TABELA ;primeiro nome
    LEA DI,TEMP   ;nome para ser comparado
    MOV DL, 5     ;para comparar com todos os nomes

    SEARCH:
        PUSH SI
        PUSH DI
        MOV CX,19
        REPE CMPSB ;enquanto forem iguais os caracteres, é scanneado
        OR CX,CX
        JZ ENCONTRADO
        POP DI
        POP SI
        ADD SI,24  ;prox nome
    DEC DL
    JNZ SEARCH
    
    MOV AX,0FFFFh  ;se chegou aqui, nenhum é igual
    PRINT MSG6
    LINHA
    JMP NAO_ENCONTRADO

    ENCONTRADO:
    POP DI
    POP SI          ;esses dois estao aqui para o nao dar problema com o RET
    MOV AX,SI
    NAO_ENCONTRADO: ;usar um CMP para verificar se ax é FFFFh na hora de usar o endereço

    R_REG CX,DX,SI,DI
    RET
CHEC_NOME ENDP

END MAIN