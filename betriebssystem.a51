$NOMOD51
#include <Reg517a.inc>

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


init:
;Hauptprogramm
;startet Scheduler, 
;legt komplette Schedule Tabelle an
;setzt Flag bei ConsolenProzess


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



;nur für mich zum testen obs meine Funktionen klappen!
	Call console
	;Call prozessA
	;Call prozessB

scheduler:
;interpretiert die Schedule-Tabelle
;weist die Prozesse der CPU zu (Timer, Interrupt)
;speichert Infos vor Prozesswechsel ab 

new:
;setzt Flag in ScheduleTabelle (bei entsprechendem Prozess)
MOV A,#0
RET 

delete:
;löscht Flag in ScheduleTabelle
MOV A,#0
RET

infinity:
	SETB WDT
	SETB SWDT
	JMP infinity
	
END