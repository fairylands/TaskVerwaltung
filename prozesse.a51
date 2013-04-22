$NOMOD51
#include <Reg517a.inc>

name prozesse
PUBLIC console, prozessA, prozessB
EXTRN DATA (var1, var2, var3)

my_code SEGMENT CODE
RSEG my_code

console:
;interpretiert Eingabe(Polling)
;schickt StartAdressen an New weiter
	
NOP	

RET








prozessA:
;gibt pro sekunde 1 a aus (Timer)

MOV A,#15

ausgabe:
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


	MOV S0BUF,#61h	;schreibt ein a		
	gesendet: 	
				SETB WDT
				SETB SWDT
				JNB TI0, gesendet
	CLR TI0

JMP ausgabe

RET











prozessB:
;gibt einmalig 54321 aus 
	MOV A,#11b
	
RET
	
END