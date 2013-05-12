$NOMOD51
#include <Reg517a.inc>
;Einstellungen----------------------------------------------------------------
PUBLIC zweitesA,zweitesR0,varConsole,varProzessA,varProzessB,new,delete,save
EXTRN CODE (console, prozessA, prozessB)

CSEG 
ORG 0x0B
JMP schedulerInterrupt

my_data SEGMENT DATA
RSEG my_data 
stack: DS 8

;Reservieren von Datenspeicher
zweitesA: DS 1
zweitesR0: DS 1
varConsole: DS 14
varProzessA: DS 14
varProzessB: DS 14
prozessAStack: DS 8
prozessBStack: DS 8
consolenProzessStack: DS 8
nextStack: DS 1

;Scheduler Zeitscheibe
varDauer: DS 1

;Schedule Tabelle 
tabAktivCon: DS 1
tabAktivA: DS 1
tabAktivB: DS 1

tabAdresseCon: DS 2
tabAdresseA: DS 2
tabAdresseB: DS 2

tabPrioCon: DS 1
tabPrioA: DS 1
tabPrioB: DS 1

CSEG
ORG 0
JMP init
codeSegment SEGMENT CODE
RSEG codeSegment


;-----------------------------------------------------------------------------
;Hauptprogramm----------------------------------------------------------------
;besteht aus init, scheduler, new und delete
init:
;Initialisierungen für den Prozessor------------------------------------------
	; Interrupts aktivieren
		SETB EAL
		SETB IEN0.1
	; Serial Mode 1: 8bit-UART bei Baudrate 9600
		CLR SM0
		SETB SM1
	; Schnittstelle aktivieren
		SETB REN0 ; Empfang ermöglichen
		SETB BD ; Baudraten-Generator aktivieren
		MOV S0RELL,#0xD9 ; Baudrate einstellen
		MOV S0RELH,#0x03 ; 9600 = 03D9H		
		
	;Stack
	MOV sp,#stack
	
	;Consolenprozess starten--------------------------------------------------
	;(setzt A auf 0 damit 'new' erkennt, dass er ein 'aktiv' Flag beim 
	;Consolenprozess setzen soll)
		MOV A,#0
		Call new
		
		;Timer 
		; Timer 0 für Scheduler-Interrupt
		SETB TR0
		; Scheduler-Interrupt starten
		SETB TF0
		
		
;-----------------------------------------------------------------------------
;--------------------------SCHEDULER------------------------------------------		

scheduler:

;alter Prozess wird abgelöst--------------------------------------------------
	;scannt "byte aktiv", findet den vergangenen prozess heraus (speichert in R0 ab)
	;sichern von A und R0 (des noch nicht bekannten Prozesses)
	MOV zweitesA,A 
	MOV zweitesR0,R0
	
	MOV A, #1
	CJNE A, tabAktivCon, pruefeAktivA
	;Con aktiv
		;ruecksprungSpeichern
			POP tabAdresseCon+1
			POP tabAdresseCon												
		;Daten des Prozesses sichern
			MOV R0,#varConsole
			Call save
		;Byte aktiv auf 0 setzen
			MOV tabAktivCon, #0
		JMP prozessAuswahl
	
	pruefeAktivA:
	CJNE A, tabAktivA, pruefeAktivB
	;ProzessA aktiv
		;ruecksprungSpeichern
			POP tabAdresseA+1
			POP tabAdresseA													
		;Daten des Prozesses sichern
			MOV R0,#varProzessA
			Call save
		;Byte aktiv auf 0 setzen
			MOV tabAktivA, #0
		JMP prozessAuswahl

	pruefeAktivB:
	CJNE A, tabAktivB, weiterleitung							
	;ProzessB aktiv
		;ruecksprungSpeichern
			POP tabAdresseB+1
			POP tabAdresseB												
		;Daten des Prozesses sichern
			MOV R0,#varProzessB
			Call save
		;Byte aktiv auf 0 setzen
			MOV tabAktivB, #0
		JMP prozessAuswahl
		

;Welcher Prozess soll gestartet werden?------------------------------------------------------------
prozessAuswahl:
	;welche Prozesse "laufen" im Hintergrund? R5 = Console läuft(sollte immer laufen)
	;R6 = Prozess A läuft; R7 = Prozess B läuft	
		MOV A,#0
		CJNE A, tabAdresseCon, conLaeuft 
			MOV R5,#0
			CJNE A, tabAdresseA, ALaeuft 
				MOV R6,#0
				CJNE A, tabAdresseB, BLaeuft
					MOV R7,#0
					JMP aktiviereCon
		conLaeuft:
			MOV R5,#1
			CJNE A, tabAdresseA, ALaeuft 
				MOV R6,#0
				CJNE A, tabAdresseB, BLaeuft
					MOV R7,#0	
					;nur Consolenprozess läuft, in R0 speichern, 
					;welcher Prozess zu aktivieren ist
					MOV R0, #0
					JMP aktiviereCon
									
		ALaeuft:
			MOV R6,#1
			CJNE A, tabAdresseB, BLaeuft
					MOV R7,#0
					;nur Prozess A und Console läuft, Priorität muss verglichen 
					;werden R2 wird gesetzt, das heißt tabPrioA und tabPrioCon 
					;werden verglichen
					MOV R2, #1
					CALL compare
					JMP prozessAktivierung
										
		BLaeuft:
			MOV R7,#1
			;entweder Con und B laufen, oder alle drei
			;zur Identifikation der laufenden Prozesse: B läuft auf jeden Fall,
			;R5+R6 = x , wenn x = 1 dann läuft nur Con und B, wenn x = 2 laufen 
			;alle Prozesse
				MOV A,R5
				ADD A,R6
				CJNE A,#1, dreiProzesse
					;nur Con und B 
					MOV R2, #2
					CALL compare
					JMP prozessAktivierung
		dreiProzesse:
			MOV R2,#3
			CALL compare
			JMP prozessAktivierung
		
weiterleitung:
	JMP aktiviereCon
	
			
;ProzessAktivierung------------------------------------------------------------------------
prozessAktivierung:	
	;in R2 steht die Nummer des Prozesses mit der höchsten Priorität (0= Con, 1=A, 2=B)
	
	CJNE R2,#0, aktiviereAoderB
		;aktiviere Con
		MOV R0,#varConsole
		Call datenHolen;
		MOV tabAktivCon,#1
		DEC tabPrioCon
		INC tabPrioA
		INC tabPrioB
		MOV SP,nextStack
		PUSH tabAdresseCon												
		PUSH tabAdresseCon+1
		RETI
		
	aktiviereAoderB:
	CJNE R2,#1, aktiviereB
		;aktiviere A
		MOV R0,#varProzessA
		Call datenHolen;
		MOV tabAktivA,#1
		DEC tabPrioA
		INC tabPrioCon
		INC tabPrioB
		MOV SP,nextStack
		PUSH tabAdresseA												
		PUSH tabAdresseA+1
		RETI
		
	aktiviereB:
	CJNE R2,#2, aktiviereCon
		;aktiviere B
		MOV R0,#varProzessB		
		Call datenHolen;
		MOV tabAktivB,#1
		DEC tabPrioB
		INC tabPrioCon
		INC tabPrioA
		MOV SP,nextStack
		PUSH tabAdresseB												
		PUSH tabAdresseB+1
		RETI
			
	aktiviereCon:;einfach per default, wenn was schief geht 
		;aktiviere Con
		MOV R0,#varConsole		
		Call datenHolen;
		MOV tabAktivCon,#1
		DEC tabPrioCon
		INC tabPrioA
		INC tabPrioB
		MOV SP,nextStack
		PUSH tabAdresseCon											
		PUSH tabAdresseCon+1
		RETI
	
JMP scheduler


;-----------------------------------------------------------------------------
;-----------------------------scheduler Interrupt----------------------------- 
schedulerInterrupt:
JMP scheduler

RET


;-----------------------------------------------------------------------------
;-----------------------------NEW---------------------------------------------	

new:
;setzt Flag in ScheduleTabelle (bei entsprechendem Prozess) Console=0 A=1 B=2 			
;wenn a schon aktiv ist und nochmal aktiviert wird, ignoriert der new prozess diesen 
CJNE A,#0, keinConsolenprozess
;Consolenprozess starten
	;Flag aktiv
		MOV tabAktivCon,#0
	;Byte läuft 
		MOV DPTR, #console
		MOV tabAdresseCon, DPL						
		MOV tabAdresseCon+1, DPH	
	;Priorität initialisieren
		MOV tabPrioCon,#2
		MOV A,#0
		MOV R0,#varConsole
		
		conSpeicherAufNull: 
			INC A
			MOV @R0,#0
			INC R0 
			CJNE A,#14,conSpeicherAufNull		
		MOV A,#0
		MOV R0, #varConsole+12
		MOV @R0,#consolenProzessStack-1
		JMP endeNew

keinConsolenprozess:
CJNE A,#1, keineConOderProzA
;ProzessA starten
	MOV A, tabAktivA
	;Abfrage handelt es sich um ein 2. 'a' ?
	CJNE A,#0, keinProzessS
		;Flag aktiv
			MOV tabAktivA,#0
		;Byte läuft 
			MOV DPTR, #prozessA
			MOV tabAdresseA, DPL						
			MOV tabAdresseA+1, DPH					
		;Priorität initialisieren
			MOV tabPrioA,#2
			MOV A,#0
			MOV R0,#varProzessA
			
			aSpeicherAufNull: 
				INC A
				MOV @R0,#0
				INC R0 
				CJNE A,#14,aSpeicherAufNull		
			MOV A,#0
			MOV R0, #varProzessA+12
			MOV @R0,#prozessAStack-1
		JMP endeNew

keineConOderProzA:
CJNE A,#2, keinProzessS
;ProzessB starten
	;Flag aktiv
		MOV tabAktivB,#0
	;Byte läuft 
		MOV DPTR, #prozessB
		MOV tabAdresseB, DPL						
		MOV tabAdresseB+1,DPH							
	;Priorität initialisieren
		MOV tabPrioB,#2
		MOV A,#0
		MOV R0,#varProzessB
			
		bSpeicherAufNull: 
			INC A
			MOV @R0,#0
			INC R0 
			CJNE A,#14,bSpeicherAufNull		
		MOV A,#0
		MOV R0, #varProzessB+12
		MOV @R0,#prozessBStack-1
	JMP endeNew
	
keinProzessS: ;kann eigentlich nicht passieren, aber damit es vollständig ist
	MOV A,#0
	JMP endeNew
	
endeNew: 
	NOP
	
	
	

RET 


;-----------------------------------------------------------------------------
;-----------------------------DELETE------------------------------------------		

delete:
;löscht Flag in ScheduleTabelle	(nur bei Prozess A oder B)


CJNE A,#1, keinProzessA
;ProzessA löschen
	;Flag aktiv löschen
		MOV tabAktivA,#0
	;Byte läuft löschen
		MOV tabAdresseA, #0
	;Priorität löschen
		MOV tabPrioA,#0
	MOV A,#0
	JMP endeDelete

keinProzessA:
CJNE A,#2, keinProzessL
;ProzessB löschen
	;Flag aktiv löschen
		MOV tabAktivB,#0
	;Byte läuft löschen
		MOV tabAdresseB, #0
	;Priorität löschen
		MOV tabPrioB,#0
	MOV A,#0
	JMP endeDelete
	
keinProzessL: ;kann eigentlich nicht passieren, aber damit es vollständig ist
	MOV A,#0
	JMP endeDelete
	
endeDelete:
		SETB TF0
RET

;---------------------- UNTERPROZESS SAVE ---------------------------------------------------------------------------------------
save:;---------------------------------------------------------------------------------------------------------------------------
;Dieser Unterprozess nimmt den Sicherungsvorgang vor und speichert alle Regsiter in einen vorgesehenen Speicherbereich.
;Dazu muss zunächst R0 und der A gesichert werden, da diese zum Speicherungsvorgang benötigt werden.
;R0 wird in zweitesR0 zwischengespeichert, A wird in zweitesA zwischengespeichert -> dies geschieht schon vor Aufruf von 'save'

;ab hier werden die Daten gespeichert: 	(es gibt 3 Schritte, die sich immer wieder wiederholen)
	MOV @R0,zweitesA 					;R0 zeigt auf das 1. Byte des Speicherbereichs und legt "zweitesA" dort ab
	INC R0								;R0 wird um 1 erhöht und zeigt nun auf das 2. Byte
	MOV @R0,zweitesR0					;R0 speichert in das 2.Byte den Inhalt von "zweitesR0" ab
	INC R0								;R0 wird um 1 erhöht und zeigt nun auf das 3. Byte
	;es gibt 3 Schritte, die sich ab hier immer wieder wiederholen
	MOV A,R1							;(1) der Inhalt von R1 wird in A gespeichert	
	MOV @R0,A							;(2) R0 speichert in das 3.Byte den Inhalt von A ab
	INC R0								;(3) R0 wird um 1 erhöht und zeigt nun auf das 4. Byte
	MOV A,R2							;(1) der Inhalt von R2 wird in A gespeichert
	MOV @R0,A							;(2) R0 speichert in das 4.Byte den Inhalt von A ab
	INC R0								;(3) R0 wird um 1 erhöht und zeigt nun auf das 5. Byte
	MOV A,R3							;...Wiederholung
	MOV @R0,A
	INC R0
	MOV A,R4
	MOV @R0,A
	INC R0
	MOV A,R5
	MOV @R0,A
	INC R0
	MOV A,R6
	MOV @R0,A
	INC R0
	MOV A,R7
	MOV @R0,A
	INC R0
	MOV A,PSW
	MOV @R0,A
	INC R0
	MOV A,DPH
	MOV @R0,A
	INC R0
	MOV A,DPL
	MOV @R0,A
	INC R0
	MOV A,SP
	SUBB A,#2
	MOV @R0,A
	INC R0
	MOV A,B
	MOV @R0,A
	
RET

;----------------------------- UNTERPROZESS DATEN HOLEN -------------------------------------------------------------------------
datenHolen:;---------------------------------------------------------------------------------------------------------------------
;Beim Start eines Prozesses werden zunächst die zwischengespeicherten Daten wieder in die Register geladen
;Dazu muss zunächst der A und das Register R0 zwischengespeichert werden, da diese zum laden der Daten benötigt werden und um 
;Datenverlust zu verhindern 
	MOV A,@R0
	MOV zweitesA,A
	INC R0
	MOV A,@R0
	MOV zweitesR0,A
	INC R0
;ab hier werden die Daten geladen: 	(es gibt 3 Schritte, die sich immer wieder wiederholen)
	MOV A,@R0				;(1) R0 ist ein Zeiger auf das 3. Byte des Speichers und lädt den Inhalt in den A
	MOV R1,A				;(2) Der Inhalt des A wird nun in das zugehörige Register R1 geladen
	INC R0					;(3) R0 wird um 1 erhöht, also wird der Zeiger auf das 4. Byte verschoben 
	MOV A,@R0				;(1) R0 ist ein Zeiger auf das 4. Byte des Speichers und lädt den Inhalt in den A
	MOV R2,A				;(2) Der Inhalt des A wird nun in das zugehörige Register R2 geladen
	INC R0					;(3) R0 wird um 1 erhöht, also wird der Zeiger auf das 5. Byte verschoben 
	MOV A,@R0				;...Wiederholung
	MOV R3,A
	INC R0
	MOV A,@R0
	MOV R4,A
	INC R0
	MOV A,@R0
	MOV R5,A
	INC R0
	MOV A,@R0
	MOV R6,A
	INC R0
	MOV A,@R0
	MOV R7,A
	INC R0	
	MOV A,@R0
	MOV PSW,A
	INC R0
	MOV A,@R0
	MOV DPH,A
	INC R0
	MOV A,@R0
	MOV DPL,A
	INC R0
	MOV A,@R0
	MOV nextStack,A
	INC R0
	MOV A,@R0
	MOV B,A
	INC R0
;es wurden alle Daten wieder in die Register geladen, nun fehlen noch der A und R0 welche bisher zum Laden genutzt wurden	
	MOV A,zweitesA			;der Inhalt von zweitesA (welches zu Beginn des 'compare' gesichert wurde) wird in den A geladen
	MOV R0,zweitesR0		;der Inhalt von zweitesR0 (welches zu Beginn des 'compare' gesichert wurde) wird in R0 geladen
	
	
RET




;------------------------------ UNTERPROZESS COMPARE ----------------------------------------------------------------------------
compare:;------------------------------------------------------------------------------------------------------------------------
;Dieser Unterprozess dient dem Vergleich der verschiedenen laufenden Prozesse und entscheidet anhand der Priorität, welcher 
;Prozess gestartet werden soll
;im Register 2 wurde die Art des Vergleichs abgespeichert: 
	;R2=1 ->	Consolenprozess und Prozess A werden verglichen
	;R2=2 ->	Consolenprozess und Prozess B werden verglichen
	;R2=3 ->	alle drei Prozessprioritäten müssen verglichen werden
;Der Vergleich ist kein direkter Vergleich, es werden alle Prozesse nacheinander mit vorgeschriebenen Prioritäten verglichen. 
;(Und nicht direkt miteinander.)
;Da die höchste Priorität die 2 ist wird erst geschaut: Hat Prozess X die Priorität 2? 
;JA -> Prozess X wird gestartet, NEIN -> Nächster Prozess wird auf gleiche Frage untersucht
;Sofern kein Prozess die Priorität 2 hat, wird die gleiche Frage mit der Priorität 1  gestellt. (usw.)
;das Ergebnis des Vergleichs wird dabei in Register 2 zwischengespeichert
	
	CJNE R2,#1, conBoderAlle					;der Inhalt des  R2 wird geprüft
		;R2=1, Consolenprozess und Prozess A werden verglichen
		MOV R2,tabPrioCon										
		CJNE R2,#2, conHatNichtPrio2test1		
			;Prio bei Con = 2
				MOV R2,#0
				JMP endeCompare
			
		conHatNichtPrio2test1:
			MOV R2,tabPrioA
			CJNE R2,#2, aHatNichtPrio2test1
			;Prio bei A = 2
				MOV R2,#1
				JMP endeCompare
			
		aHatNichtPrio2test1:
			CJNE R2,#1, aHatNichtPrio1test1
			;Prio bei A = 1
				MOV R2,#1
				JMP endeCompare
			
		aHatNichtPrio1test1:
			MOV R2,tabPrioCon
			CJNE R2,#1, beidePrio0test1
			;Prio bei Con = 1
				MOV R2,#0
				JMP endeCompare
			
		beidePrio0test1:
			MOV R2,#0
			JMP endeCompare
	;fertig für Eingangswert von R2 = 1----------------------------------------
		
		
	conBoderAlle:;-------------------------------------------------------------
	CJNE R2,#2, alleProzesse					;der Inhalt des  R2 wird geprüft
		;R2=2, Consolenprozess und Prozess B werden verglichen
		MOV R2,tabPrioCon
		CJNE R2,#2, conHatNichtPrio2test2
			;Prio bei Con = 2
				MOV R2,#0
				JMP endeCompare
			
		conHatNichtPrio2test2:
			MOV R2,tabPrioB
			CJNE R2,#2, bHatNichtPrio2test2
			;Prio bei B = 2
				MOV R2,#2
				JMP endeCompare
			
		bHatNichtPrio2test2:
			CJNE R2,#1, bHatNichtPrio1test2
			;Prio bei B = 1
				MOV R2,#2
				JMP endeCompare
			
		bHatNichtPrio1test2:
			MOV R2,tabPrioCon
			CJNE R2,#1, beidePrio0test2
			;Prio bei Con = 1
				MOV R2,#0
				JMP endeCompare
			
		beidePrio0test2:
			MOV R2,#0
			JMP endeCompare
			
		
	alleProzesse:;-------------------------------------------------------------
		;R2=2, alle Prozesse werden verglichen
		MOV R2,tabPrioCon
		CJNE R2,#2, conHatNichtPrio2test3
			;Prio bei Con = 2
				MOV R2,#0
				JMP endeCompare
				
		conHatNichtPrio2test3:
			MOV R2,tabPrioA
			CJNE R2,#2, aHatNichtPrio2test3
			;Prio bei A = 2
				MOV R2,#1
				JMP endeCompare
			
		aHatNichtPrio2test3:
			MOV R2,tabPrioB
			CJNE R2,#2, bHatNichtPrio2test3
			;Prio bei B = 2
				MOV R2,#2
				JMP endeCompare
			
		bHatNichtPrio2test3:
			CJNE R2,#1, bHatNichtPrio1test3
			;Prio bei B = 1
				MOV R2,#2
				JMP endeCompare
			
		bHatNichtPrio1test3:
			MOV R2,tabPrioCon
			CJNE R2,#1, conHatNichtPrio1test3
			;Prio bei Con = 1
				MOV R2,#0
				JMP endeCompare
				
		conHatNichtPrio1test3:
			MOV R2,tabPrioA
			CJNE R2,#1, allePrio0test3
			;Prio bei A = 1
			 MOV R2,#1
			 JMP endeCompare
			
		allePrio0test3:
			MOV R2,#0
			JMP endeCompare

endeCompare:
	NOP

RET






endlosschleife:;--------------------------------------------------------------
	SETB WDT
	SETB SWDT
	JMP endlosschleife
	
END