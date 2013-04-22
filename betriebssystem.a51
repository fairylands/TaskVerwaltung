$NOMOD51
#include <Reg517a.inc>
;Einstellungen----------------------------------------------------------------
PUBLIC zweitesA,zweitesR0,varConsole,varProzessA,varProzessB,new,delete
EXTRN CODE (console, prozessA, prozessB)

my_data SEGMENT DATA
RSEG my_data

;Reservieren von Datenspeicher
zweitesA: DS 1
zweitesR0: DS 1
varConsole: DS 14
varProzessA: DS 14
varProzessB: DS 14

CSEG
ORG 0
JMP init

;-----------------------------------------------------------------------------
;Hauptprogramm----------------------------------------------------------------
;besteht aus init, scheduler, new und delete
init:
;Initialisierungen für den Prozessor------------------------------------------
	; Interrupts aktivieren
		SETB EAL
	; Serial Mode 1: 8bit-UART bei Baudrate 9600
		CLR SM0
		SETB SM1
	; Schnittstelle aktivieren
		SETB REN0 ; Empfang ermöglichen
		SETB BD ; Baudraten-Generator aktivieren
		MOV S0RELL,#0xD9 ; Baudrate einstellen
		MOV S0RELH,#0x03 ; 9600 = 03D9H
	;Schedule Tabelle anlegen 															TO-DO


;Scheduler starten ----------------------------------------------------------- 			TO-DO





;Consolenprozess starten------------------------------------------------------
;(setzt A auf 0 damit 'new' erkennt, dass er ein 'aktiv' Flag beim 
;Consolenprozess setzen soll)
	MOV A,#0
	Call new

;Prozessaufrufe zum Testen----------------------------------------------------
	Call prozessB
	;Call console
	Call prozessA
	
	
	
	
	
scheduler:;-------------------------------------------------------------------
;interpretiert die Schedule-Tabelle 													TO-DO
;weist die Prozesse der CPU zu (Timer, Interrupt) 										TO-DO


	;speichert Infos vor Prozesswechsel ab -----------------------------------  
	;Label = direct, müssen noch an die richtige Stelle geschrieben werden				TO-DO
		MOV zweitesA,A
		MOV zweitesR0,R0
		MOV R0,#varConsole
		Call save
	
		;MOV zweitesA,A
		;MOV zweitesR0,R0
		;MOV R0,#varProzessA
		;Call save
		
		;MOV zweitesA,A
		;MOV zweitesR0,R0
		;MOV R0,#varProzessB
		;Call save
	





new:;-------------------------------------------------------------------------
;setzt Flag in ScheduleTabelle (bei entsprechendem Prozess) Console=0 A=1 B=2 			TO-DO
;wenn a schon aktiv ist und nochmal aktiviert wird, ignoriert der new prozess diesen 	
MOV A,#0
RET 


delete:;----------------------------------------------------------------------
;löscht Flag in ScheduleTabelle															TO-DO
MOV A,#0
RET

save:;------------------------------------------------------------------------
;nimmt den Sicherungsvorgang vor
MOV @R0,zweitesA
	INC R0
	MOV @R0,zweitesR0
	INC R0
	MOV A,R1
	MOV @R0,A
	INC R0
	MOV A,R2
	MOV @R0,A
	INC R0
	MOV A,R3
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
	MOV @R0,A
	INC R0
	MOV A,B
	MOV @R0,A
	
RET


endlosschleife:;--------------------------------------------------------------
	SETB WDT
	SETB SWDT
	JMP endlosschleife
	
END