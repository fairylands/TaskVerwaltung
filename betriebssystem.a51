$NOMOD51
#include <Reg517a.inc>

PUBLIC var1,var2,var3
EXTRN CODE (console, prozessA, prozessB)

my_data SEGMENT DATA
RSEG my_data
var1: DS 1;
var2: DS 1;
var3: DS 2;
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
	Call prozessA
	Call prozessB

scheduler:
;interpretiert die Schedule-Tabelle
;weist die Prozesse der CPU zu (Timer, Interrupt)
;speichert Infos vor Prozesswechsel ab 

new:
;setzt Flag in ScheduleTabelle (bei entsprechendem Prozess)

delete:
;löscht Flag in ScheduleTabelle
	
infinity:
	SETB WDT
	SETB SWDT
	JMP infinity
	
END