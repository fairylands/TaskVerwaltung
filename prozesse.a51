;Datei Prozesse enthält den Consolenprozess, sowie Prozess A und B 

$NOMOD51
#include <Reg517a.inc>

name prozesse
PUBLIC console, prozessA, prozessB
EXTRN DATA (zweitesA, zweitesR0, varConsole, varProzessA, varProzessB)
EXTRN CODE (new, delete, save)

my_code SEGMENT CODE
RSEG my_code



;--------------------------------- DER CONSOLENPROZESS --------------------------------------------------------------------------
console:;------------------------------------------------------------------------------------------------------------------------
;interpretiert die Eingabe an der Schnittstelle durch Polling 	
;schreibt in den Akkumulator (im Weiteren 'A') die der Eingabe entsprechende Zahl(a=1,b=1,c=2) 	
;ruft den Prozess 'new' (in betriebssystem.a51) auf 		

CLR RI0 							;zurücksetzen des Empfangsbit
empfangen:							;Empfangsroutine
			SETB WDT				;Watchdog zurücksetzen, damit keine unerwünschte Unterbrechung(Interrupt) erfolgt
			SETB SWDT
			JNB RI0, empfangen		;wenn das Empfangsbit gesetzt wurde, so springt man aus der Empfangsroutine raus
MOV A,S0BUF							;der Schnittstelleninhalt wird im A gespeichert
CJNE A,#61h, keinA					;wenn im A kein "a" gespeichert wurde, so wird zum Unterprozess 'keinA' gesprungen 
MOV A,#1							;falls im A ein "a" gespeichert wurde, so wird eine "1" in den A geschrieben
Call new							;der Prozess 'new' wird aufgerufen (durch die 1 im A wird er den Prozess A starten)
JMP console							;der Consolenprozess startet wieder von Beginn an

keinA:
	CJNE A,#62h, keinB				;wenn im A kein "b" gespeichert wurde, so wird zum Unterprozess 'keinB' gesprungen 
	MOV A,#1						;falls im A ein "b" gespeichert wurde, so wird eine "1" in den A geschrieben
	Call delete						;der Prozess 'delete' wird aufgerufen (durch die 1 im A wird er den Prozess A beenden)
	JMP console						;der Consolenprozess startet wieder von Beginn an
keinB:
	CJNE A,#63h, keinAkzeptierterBuchstabe 	;wenn im A kein "C" gespeichert wurde, so wird zum Unterprozess 
											;'keinAkzeptierterBuchstabe' gesprungen 
	MOV A,#2						;falls im A ein "c" gespeichert wurde, so wird eine "2" in den A geschrieben
	Call new						;der Prozess 'new' wird aufgerufen (durch die 2 im A wird er den Prozess B starten)
	JMP console						;der Consolenprozess startet wieder von Beginn an
keinAkzeptierterBuchstabe:
	NOP								;nichts passiert
	JMP console						;der Consolenprozess startet wieder von Beginn an

RET


;--------------------------------- DER PROZESS A  -------------------------------------------------------------------------------
prozessA:;-----------------------------------------------------------------------------------------------------------------------
;Pro Sekunde soll ein 'a' ausgegeben werden. Dieser Prozess wird mit der Eingabe eines 'a' gestartet und 
;erst du die Eingabe eines 'b' beendet

MOV A,#255 							;A wird auf den Wert 255 gesetzt und dient als Zählvariable (dies geschieht zur Simulation 
									;einer Sekunde, der Wert kann von PC zu PC unterschiedlich sein)
SETB TR1 							;durch setzen des TR1 Bit wird der Timer1 gestartet
   zaehlerminuseins:				
           timerEnde:  NOP			;diese Schleife stellt die Timerroutine dar, sie läuft solange, 
									;bis der TimerInterrupt ausgelöst wird
                 JNB TF1, timerEnde ;wenn der TimerInterrupt ausgelöst wurde, wird das TF1 Bit auf 1 gesetzt (solange das TF1 Bit 
									;auf 0 ist wird die Schleife durchlaufen)
          CLR TF1 ;setzt das TF1 Bit wieder zurück 
          SUBB A,#1					;die äußere Schleife zählt um eins herunter
          SETB WDT					;Watchdog zurücksetzen, damit keine unerwünschte Unterbrechung(Interrupt) erfolgt
          SETB SWDT
    CJNE A,#0, zaehlerminuseins		;erst wenn A auf 0 herunter gezählt wurde (der Timer als A-mal durchgelaufen ist) wird die 
									;Schleife verlassen
MOV S0BUF,#61h						;in die Schnittstelle wird ein 'a' eingetragen, welches dann ausgegeben werden soll
Call gesendet						;der Unterprozess 'gesendet' stellt sicher, dass der Inhalt der Schnittstelle auch ausgegeben 
									;wurde
JMP prozessA						;der ProzessA startet wieder von Beginn an 

RET


;--------------------------------- DER PROZESS B  -------------------------------------------------------------------------------
prozessB:;-----------------------------------------------------------------------------------------------------------------------
;Es soll einmalig '54321' ausgegeben werden (danach beendet sich der Prozess selbst)
;die serielle Schnittstelle muss ein Zeichen nach dem anderen senden, das heißt jeder Sendevorgang muss einzeln geprüft werden

MOV S0BUF,#35h						;es wird eine '5' in die serielle Schnittstelle geschrieben
Call gesendet						;der Unterprozess 'gesendet' stellt sicher, dass der Inhalt der Schnittstelle auch ausgegeben 
									;wurde
MOV S0BUF,#34h	
Call gesendet
MOV S0BUF,#33h	
Call gesendet
MOV S0BUF,#32h	
Call gesendet
MOV S0BUF,#31h	
Call gesendet
MOV A,#2							;in den A wird eine 2 geschrieben
Call delete							;der Prozess 'delete' wird aufgerufen (durch die 2 im A wird er den Prozess B beenden)

RET


;--------------------------------- UNTERPROZESS GESENDET ------------------------------------------------------------------------
gesendet:;-----------------------------------------------------------------------------------------------------------------------
;sichert ab, dass etwas gesendet wurde 									

CLR EAL								;die globalen Interrupts werden ausgeschaltet, damit der Prozess nicht unterbrochen wird
SETB WDT							;Watchdog zurücksetzen, damit keine unerwünschte Unterbrechung(Interrupt) erfolgt
SETB SWDT							
JNB TI0, gesendet					;wenn das TI0 Bit gesetzt wurde, so ist der Sendevorgang erfolgreich abgeschlossen
CLR TI0								;das TI0 Bit wird wieder zurückgesetzt
SETB EAL							;die globalen Interrupts werden wieder eingeschalten

RET	
END