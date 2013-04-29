$NOMOD51
#include <Reg517a.inc>

name prozesse
PUBLIC console, prozessA, prozessB
EXTRN DATA (zweitesA, zweitesR0, varConsole, varProzessA, varProzessB)
EXTRN CODE (new, delete, save)

my_code SEGMENT CODE
RSEG my_code



;-----------------------------------------------------------------------------
console:;---------------------------------------------------------------------
;interpretiert Eingabe(Polling) 											DONE
;ruft new auf und schreibt in A richtige Zahl rein: a=1, b=1, c=2 			DONE

CLR RI0
empfangen:
			SETB WDT
			SETB SWDT
			JNB RI0, empfangen
MOV A,S0BUF

CJNE A,#61h, keinA
MOV A,#1
Call new
JMP console

keinA:
	CJNE A,#62h, keinB
	MOV A,#1
	Call delete
	JMP console
keinB:
	CJNE A,#63h, keinAkzeptierterBuchstabe
	MOV A,#2
	Call new
	JMP console
keinAkzeptierterBuchstabe:
	NOP
	JMP console

RET


;-----------------------------------------------------------------------------
prozessA:;--------------------------------------------------------------------
;gibt pro sekunde 1 a aus (Timer) 											DONE
MOV A,#1	
;Timer 
SETB TR1 ;Timer starten
	
zaehlerminuseins:
				timerEnde:	NOP
							JNB TF1, timerEnde
				CLR TF1 ;löst Timer Interrupt aus (zurückgesetzt)
				SUBB A,#1
				SETB WDT
				SETB SWDT
				CJNE A,#0, zaehlerminuseins
;schreibt ein a pro Sekunde
MOV S0BUF,#61h		
Call gesendet
JMP prozessA
RET


;-----------------------------------------------------------------------------
prozessB:;--------------------------------------------------------------------
;gibt einmalig 54321 aus, beendet sich dann									DONE
MOV S0BUF,#35h	
Call gesendet
MOV S0BUF,#34h	
Call gesendet
MOV S0BUF,#33h	
Call gesendet
MOV S0BUF,#32h	
Call gesendet
MOV S0BUF,#31h	
Call gesendet

MOV zweitesA,A
MOV zweitesR0,R0
MOV R0,#varProzessB
Call save

MOV A,#2
Call delete
RET


;-----------------------------------------------------------------------------
gesendet:;--------------------------------------------------------------------
;sichert ab, dass etwas gesendet wurde 										DONE
SETB WDT
SETB SWDT
JNB TI0, gesendet
CLR TI0
RET
	
	
END