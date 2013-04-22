$NOMOD51
#include <Reg517a.inc>

name betriebssysteme

EXTRN CODE (console, prozessA, prozessB)

; (default) Code Segment für Interrupt - Routinen reservieren

; --------- intRoutineA -----------------
CSEG 
ORG A9H
JMP intRoutineA


;----------------- intRoutineB -------------
CSEG 
ORG ABh
JMP intRoutineB

;
;------------------ Code Segment für Hauptprogramm -----------------
;
CSEG
ORG 0
JMP init


codeSegment SEGMENT CODE
RSEG codeSegment

start:

;----------------Initialisierungen für den Prozessor----------------------
; Interrupts aktivieren
SETB EAL
SETB IEN0.1
SETB IEN0.3

; 
;------------- Hauptprogramm -----------------
;

init:
		
		; ConsolenProzess - Flag setzen 
		SETB 10
		
		; Scheduling - Tabelle anlegen und Dauer der Prozesse A, B und Console mit 0 initialisieren
		
		varProzessA EQU #00h
		MOV 25h, varProzessA
		
		varProzessB EQU #00h
		MOV 26h, varProzessB
		
		varConsole EQU #00h
		MOV 27h, varConsole


; 
;-------------- Scheduler ---------------------
;
scheduler:     
			   SETB	WDT
			   SETB	SWDT
			   CLR 00
checkIfConsole:	
               JNB 10, checkIfA
			   CALL console
checkIfA:	   JNB PSW.1, checkIfB
			   CALL prozessA
			   
			   ; Timer 0 initialisieren
			   SETB TMOD.0
			   CLR  TMOD.1
			   SETB TR0
		
timerA:        NOP
			   JNB TF0, timerA
			   
		   
checkIfB:      JNB PSW.5, checkIfDelete
			   CALL prozessB
			   
			   ; Timer 1 initialisieren
			   SETB TM0D.4
			   CLR  TMOD.5
			   SETB TR1
timerB:        NOP 
               JNB, TF1, timerB
			   
			   
			   
			   
checkIfDelete: JB 00, scheduler
			

;
;----------------- Starten von Prozessen --------
;

new:
	       CJNE A, #01h, checkFlagB
	       SETB PSW.1	
checkFlagB:SETB PSW.5
	       RET
; 
;---------------- Löschen von Prozessen ----------------
;

delete:
		SETB 00
		RET

;
;----------- Timer Interrupt Routinen --------------------
;


intRoutineA: 
			MOV R0, varProzessA
			INC R0
			MOV varProzessA, R0
			CJNE R0, #4, checkFlagDelete
			
     		; Dauer von Prozess A und Wert des Hilfregisters zurücksetzen
			MOV R0, #00h
			MOV varProzessA, R0
			
			; Flag von Prozess A zurücksetzen
			
			CLR PSW.1
			
			; Zeitscheibe abgelafuen
			; Prüfen ob Prozess B aufgerufen wurde
			JB, PSW.5, checkIfB
			
			; Wenn Zeitscheibe abgelaufen und Prozess B nicht aufgerufen wurde, zum Consolen-Prozess springen
			SETB 10
			JMP checkIfConsole
			
			
			; Zeitscheibe nicht abgelaufen
checkFlagDelete:     
			JB 00, checkIfDelete	
			RETI

intRoutineB:
			; von default Registerbank (0) zu Registerbank 1 wechseln 
			CLR PSW.4
			SETB PSW.3
			MOV R0, varProzessB
			INC R0
			MOV varProzessB, R0
			CJNE R0, #2, timerB

			; Zeitscheibe ist abgelaufen
		    ; Dauer von Prozess A und Wert des Hilfregisters zurücksetzen
			MOV R0, #00h
			MOV varProzessA, R0
			
			; Flag von Prozess A zurücksetzen
			
			CLR PSW.5
			
			JB, PSW.1, checkIfA

			; Wenn Zeitscheibe abgelaufen und Prozess B nicht aufgerufen wurde, zum Consolen-Prozess springen
			SETB 10
			JMP checkIfConsole
			RETI

END