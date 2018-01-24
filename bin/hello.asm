; Initial layout-Credit: Dr. Jesus C. Fraga 
$NOLIST
$MODLP51
$LIST

; Reset vector
org 0x0000
    ljmp Main

; Include files
$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros-Credit: Dr. Jesus C. Fraga
$include(math32.inc) ; A library of 32bit math functions and utility macros-Credit: Dr. Jesus C. Fraga
$LIST

; Symbolic constants
CLK     EQU 22118400
BAUD    EQU 115200
BRG_VAL EQU (0x100-(CLK/(16*BAUD)))

; LCD hardware wiring
LCD_RS EQU P1.1
LCD_RW EQU P1.2
LCD_E  EQU P1.3
LCD_D4 EQU P3.2
LCD_D5 EQU P3.3
LCD_D6 EQU P3.4
LCD_D7 EQU P3.5

; ADC hardware wiring
CE_ADC  EQU P2.0
MY_MOSI EQU P2.1
MY_MISO EQU P2.2
MY_SCLK EQU P2.3
CHANGE_DISPLAY_BUTTON EQU P0.2

; Direct access variables (address 0x30 - 0x7F) used by math32 library
dseg at 30H
x:      ds 4
y:      ds 4
bcd:    ds 5
Result: ds 2
buffer: ds 30
display_mode: ds 1 ; This flag will tell us which "mode of display" we are in

bseg
mf: dbit 1

cseg
; macro wouldn't work in LCD_4bit.inc ?
;---------------------------------------------------------------------------
;---------------------------------;
; Send a BCD number to PuTTY      ;
;---------------------------------;
Send_BCD mac
	push ar0
	mov r0, %0
	lcall ?Send_BCD
	pop ar0
endmac

?Send_BCD:
	push acc
	; Write most significant digit
	mov a, r0
	swap a
	anl a, #0fh
	orl a, #30h
	lcall putchar
	; write least significant digit
	mov a, r0
	anl a, #0fh
	orl a, #30h
	lcall putchar
	pop acc
	ret
;---------------------------------------------------------------------------


; Adjusts the display_mode flag everytime the button is pushed. 
; Initially set to zero in main
; Modes are as follows:
; Mode 1 == Degrees Celsius 
; Mode 2 == Farenheit
; Mode 3 == Kelvin
adjust_display_mode:
	set_cursor(2,1)
	display_bcd(display_mode)
	mov a, display_mode
    add a, #0x01
    set_cursor(2,1)
    display_bcd(a)
	
	; check if we need to reset to mode 1. 
	; i.e if we are in mode 3 we need to go to mode 1
	cjne a, #0x04, Change_temp_display
	mov a, #0x01 
	mov display_mode, a
	
; Change the format of temperature being displayed
Change_temp_display:
	Set_cursor(2,8) 
	
	; Check which mode we must display
	mov a, display_mode
	cjne a, #0x01, Check_Far
	Display_char(#67) ; Ascii for 'C'
	
Check_Far:
	cjne a, #0x02, Check_K
	Display_Char(#70)
	
Check_K:
	cjne a, #0x03, return_to_main
	Display_char(#75)

return_to_main:
	ljmp Fetch_Voltage_Loop

; Sends 10-digit BCD number in bcd to the LCD
Display_10_digit_BCD:
	Set_Cursor(2, 7)
	Display_BCD(bcd+4)
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	ret

; Convert the voltage signal to a temperature in Celsius 
Convertor:
	mov x+0, Result + 0
	mov x+1, Result + 1
	mov x+2, #0x00
	mov x+3, #0x00
	
	Load_Y(410)
	lcall mul32 
	Load_Y(1023)
	lcall div32
	
	Load_Y(273)
	lcall sub32
	lcall hex2bcd
	ret

; Some constant messages to be displayed
newline:
    DB  ' ', '\r', '\n', 0
Screen_Format:
	db 'Temperature:', '\r', '\n', 0
LCD_Message:
	db 'Temperature:', 0  
   
; Send data to putty to be displayed or processed
Execute_Result:
	lcall Convertor
	
	Send_BCD(bcd) 	 ; Send to PuTTy 
	
	mov DPTR, #newline
	lcall sendstring

	ret

; Configure the serial port and baud rate
InitSerialPort:
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    mov R1, #222
    mov R0, #166
    djnz R0, $   ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, $-4 ; 22.51519us*222=4.998ms
    
    ; Now we can proceed with the configuration
	orl	PCON,#0x80
	mov	SCON,#0x52
	mov	BDRCON,#0x00
	mov	BRL,#BRG_VAL
	mov	BDRCON,#0x1E ; BDRCON=BRR|TBCK|RBCK|SPD;
    ret

; Send a character using the serial port
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

; Send a constant-zero-terminated string using the serial port
SendString:
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString

SendStringDone:
    ret ; returns to main, not SendString

; Initialize the SPI. This is done in Main
INIT_SPI:
	setb MY_MISO ; Make MISO an input pin
	clr MY_SCLK  ; Mode 0,0 default
	ret

; Bit-Bang-Credit: Dr. Jesus C. Fraga
; Used for transmiting data between the MCP chip and the Atmel chip
DO_SPI_G:
	mov R1, #0 ; Received byte stored in R1
	mov R2, #8 ; Loop counter (8-bits)
DO_SPI_G_LOOP:
	mov a, R0 ; Byte to write is in R0
	rlc a ; Carry flag has bit to write
	mov R0, a
	mov MY_MOSI, c
	setb MY_SCLK ; Transmit
	mov c, MY_MISO ; Read received bit
	mov a, R1 ; Save received bit in R1
	rlc a
	mov R1, a
	clr MY_SCLK
	djnz R2, DO_SPI_G_LOOP
	ret

; More comunication between chips. This routine calls the bitbang and handles the transmition 
; of data. 
Fetch_Voltage:
	clr CE_ADC
	mov R0, #00000001B ; Start bit:1
	lcall DO_SPI_G
	mov R0, #10000000B ; Single ended, read channel 0
	lcall DO_SPI_G
	mov a, R1 ; R1 contains bits 8 and 9
	anl a, #00000011B ; We need only the two least significant bits
	mov Result+1, a ; Save result high.
	mov R0, #55H ; It doesn't matter what we transmit...
	lcall DO_SPI_G
	mov Result, R1 ; R1 contains bits 0 to 7. Save result low.
	setb CE_ADC
	lcall Wait_Second
	lcall Execute_Result
	Set_Cursor(2,5) 
	Display_BCD(bcd) ; Display on LCD 
	ret

; Used to create a delay of one second
Wait_Second:
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	Wait_Milli_Seconds(#250)
	ret  

; Main program. Contains the loop that fetches voltage
Main:
    mov SP, #7FH ; Set the stack pointer to the begining of idata
    lcall LCD_4bit
    lcall InitSerialPort
    lcall INIT_SPI 
    mov P0M0, #0
    mov P0M1, #0 ; set pins in biconditional mode
    mov display_mode, #0x01 ; Some initialization
    
    Set_Cursor(1,1)
    Send_Constant_String(#LCD_Message) ; Display a constant string on LCD
    
    lcall change_temp_display

Fetch_Voltage_Loop:
    jb CHANGE_DISPLAY_BUTTON, Continue2 
	Wait_Milli_Seconds(#50)	; Debounce delay
	jb CHANGE_DISPLAY_BUTTON, Continue2
	Set_Cursor(2,1)
	Display_char(#33)
	lcall adjust_display_mode

Continue2:
	lcall Fetch_Voltage
	sjmp Fetch_Voltage_Loop
    
END