;*****************************************
; Version von Jens
;* @unit mm
;#210 = Laenge X waehrend Kalibrierung
;#211 = Laenge Y waehrend Kalibrierung
;#212 = 1. Messpunkt X waehrend Kalibrierung und Centerfinder
;#213 = 2. Messpunkt X waehrend Kalibrierung und Centerfinder
;#3000 = INIT
;#3001 = Used in change_tool
;#4200 = TLR Probe
;#4230 = X Position TLS
;#4231 = Y Position TLS
;#4232 = Sichere Höhe für Werkzeugwechsel (IN G53!!)
;#4233 = Sichere Höhe für Verfahrwege G53
;#4234 = Suchgeschwindigkeit TLS
;#4235 = Messgeschwindigkeit TLS
;#4300 = Durchmesser 3d Probe Spitze / 2
;#4301 = Kompensation Z Offset Probe-Toolsetter

;*******************
;Centerfinder

;#4310 = Laenge X
;#4311 = Laenge Y
;#4312 = Messhoehe
;#4313 = Sicherheitsdistanz Werkstueck
;#4314 = Suchdistanz
;#4315 = Suchgeschwindigkeit
;#4316 = Messgeschwindigkeit
;*******************

G17 G21 G90 F500			;Grundeinstellung setzen

sub INIT
	IF [#3500 == 0]
		#3500 = 1
		#4232 = -70 			;Sichere Höhe für Werkzeugwechsel (IN G53!!)
		#4233 = [#5113-1]		;Sichere Höhe für Verfahrwege G53
		#4234 = 200				;Suchgeschwindigkeit Probe/TLS (mm/min)
		#4235 = 10				;Messgeschwindigkeit Probe/TLS (mm/min)
		#4301 = 0.08			;Kompensation Z Offset Probe-Toolsetter
	ENDIF
endsub
	
;User functions, F1..F11 in user menu

Sub user_1
    gosub 3dmessung
Endsub

Sub user_2
    gosub Probe_X_pos
Endsub

Sub user_3 
    gosub Probe_Y_pos
Endsub

Sub user_4
    gosub Probe_Z_neg
Endsub

Sub user_5
    gosub dynamic_tls
Endsub

Sub user_6
    gosub spindle_warmup
Endsub

Sub user_7
    msg "sub user_7"
Endsub

Sub user_8
    msg "sub user_8"
Endsub

Sub user_9
    msg "sub user_9"
Endsub

Sub user_10
    msg "sub user_10"
Endsub

Sub user_11
    msg "sub user_11"
Endsub

;Homing per axis
Sub home_x
    home x
    ;;if A is slave of X uncomment next lines and comment previous line
    ;homeTandem X
Endsub

Sub home_y
    home y
Endsub

Sub home_z
    home z
Endsub

Sub home_a
    ;;If a is slave comment out next line
    ;;For homing a master-slave axis only homeTandem <master> should be done
    home a
Endsub

Sub home_b
    home b
Endsub

Sub home_c
    home c
Endsub

;Home all axes, uncomment or comment the axes you want.
sub home_all
    gosub home_z
    gosub home_y
    gosub home_x
    ;gosub home_a
    ;gosub home_b
    ;gosub home_c
    msg "Home complete"
endsub


sub m3
	M56 P102 ;(Read Relay Board1 Input2)
	If [#5399 <> 1]
  		Errmsg "Tool not clamped"
	Endif

	IF [#19 == 3]
		M5
		msg "Drehzahl fuer nicht rotierende Werkzeuge erkannt, Spindel startet nicht"
	ELSE
		M54 P104  ;(Sperrluft ein)
		M3 S#19
	ENDIF
endsub

sub m5
	m5 
	msg "Debug Spindel aus"
	M55 P104 ;(Sperrluft aus)
endsub


Sub probe_rotation
    msg "1. Position: 5mm vor das Werkstueck fahren, dann Cycle Start druecken!"
    m0
	G38.2 G91 Y+10 F50
	G0 G91 Y-2
    #5020 = #5051 ;x1
    #5021 = #5052 ;y1
    msg "2. Position: 5mm vor das Werkstueck fahren, dann Cycle Start druecken!"
    m0
	G38.2 G91 Y+10 F50
	G0 G91 Y-2
    #5022 = #5051 ;x2
    #5023 = #5052 ;y2
    #5024 = ATAN[#5023 - #5021]/[#5022 - #5020]
    if [#5024 > 45]
      #5024 = [#5024 - 90] ;points are in Y direction
    endif
    g68 R#5024
    msg "G68 R"#5024" applied, now zero XYZ normally"
	g90
Endsub


sub change_tool
	M5										;Spindel aus
	M9										;Kühlung aus
	G0 G53 Z#4233 							;Sichere Höhe Verfahrwege

    ;Use #5015 to indicate succesfull toolchange
    #5015 = 0 ;Tool change not performed
	#3001 = 0 ;Not the same tool being loaded

    ; check tool in spindle and exit sub
    If [ [#5011] == [#5008] AND [[#5008] <> 99] ]
        msg "Tool already in spindle"
        #5015 = 1 ;indicate tool change performed
		#3001 = 1 ;same tool being loaded
    ELSE    
		msg "Tool "#5011" einsetzen, dann mit Cycle Start fortfahren!"
		M0        
		#5015 = 1 ; Tool change performed
	ENDIF
	
	IF [[#3001] == 0] THEN   
		msg "Tool " #5008" durch Tool " #5011 " ersetzt."
	    M6 T[#5011]					; Neue Werkzeugnummer setzen
		gosub dynamic_tls			; Tool einmessen
	ENDIF
    
        
endsub      

sub change_tool_atc
	M5										;Spindel aus
	M9										;Kühlung aus
	G0 G53 Z#4233 							;Sichere Höhe Verfahrwege

    ;Use #5015 to indicate succesfull toolchange
    #5015 = 0 ;Tool change not performed
	#3001 = 0 ;Not the same tool being loaded

    ; check tool in spindle and exit sub
    If [ [#5011] == [#5008] AND [[#5008] <> 99] ]
        msg "Tool already in spindle"
        #5015 = 1 ;indicate tool change performed
		#3001 = 1 ;same tool being loaded
    ELSE  
		msg "Tool festhalten, mit Cycle Start wird dieses ausgeworfen!"
		M0

		M54 P101  ;(Relay Board1 Out1 on, Air inlet)
		M56 P101 L1 Q10 ;(Read Relay Board1 Input1)
		If [#5399 == -1]
  			Errmsg "Timeout while waiting for Tool released becoming active"
		Endif
		M54 P102  ;(Relay Board1 Out2 on, Dust removal)
		msg "Tool "#5011" einsetzen und festhalten, dann mit Cycle Start fortfahren!"
		M0   
		M55 P101  ;(Relay Board1 Out1 off, Air inlet)
		M55 P102  ;(Relay Board1 Out2 off, Dust removal)
		M56 P102 L1 Q10 ;(Read Relay Board1 Input2)
		If [#5399 == -1]
  			Errmsg "Timeout while waiting for Tool clamped becoming active"
		Endif
		M54 P103  ;(Relay Board1 Out3 on, Air return)
		G4 P5
		M55 P103  ;(Relay Board1 Out3 off, Air return)
		#5015 = 1 ; Tool change performed
	ENDIF
	
	IF [[#3001] == 0] THEN   
		msg "Tool " #5008" durch Tool " #5011 " ersetzt."
	    M6 T[#5011]					; Neue Werkzeugnummer setzen
		gosub dynamic_tls			; Tool einmessen
	ENDIF
endsub
    
sub dynamic_tls
	; Variablen 27-4994 sind frei verfügbar
	; 4000- 4999 sind im NVM gespeichert

	; Benötigte Variablen:
	; 5051 - 5056 Probe Position in X..C in G53
	; #5053 ist die Probe Position in Z (G53)

	; G43 aktiviert das Z Offset vom Tooltable
	; G49 löscht das Z Offset, kann aber stattdessen auch überschrieben werden

	; Position X des WLS G53
	IF[#5008 == 31]
		#4230 = -214 ;offset für T31
	ELSE
		#4230 = -202 ;wenn nicht T31, dann kein Offset
	ENDIF

	; #4200 speichert den Referenzwert(in Z G53) von T99
	
	M5													;Spindel aus
	M9													;Kühlung aus
	G0 G53 Z#4233										;Sichere Höhe Verfahrwege
	G0 G53 X#4230 										;Fahre zur X Position des TLS
	G0 G53 Z#4232 										;Starthöhe Messung TLS
	G4 P0												;wait for moves to finish

	IF [[#5008 <> 99] AND [#4200 == 0]]
		dlgmsg "Es ist noch kein Z Offset für die Probe gesetzt. Fortfahren?"
			IF [[#5398] == 1]
														;Programm fortführen
			ELSE
				errmsg "Es wurde kein Z Offset gesetzt, bitte neu starten."
			ENDIF
	ENDIF

	msg "Messung wird gesartet. Mit Cycle Start fortfahren."
	M0
;
; MAKE SURE YOUR DON'T TRIGGER SOFTLIMITS WITH THE FOLLOWING TWO G38.2's
;
	G38.2 G91 Z-95 F#4234 									;look for TLS
	G0 G91 Z+2												;Von Sensor zurück fahren

	IF [[#5067] == 1]										;Wenn Sensor gefunden wurde
		G38.2 G91 Z-3 F#4235 								;Werkzeug messen
		G0 G91 Z+5											;Von Sensor zurück fahren
		G90													;Absolute Koordinaten verwenden
		G0 G53 Z#4233										;Sichere Höhe Verfahrwege

		IF [[#5008] == 99]									;Wenn T99(Probe)
			#4200 = #5053									;Referenzwert setzen
			msg "Referenz auf G53 "#5053" gesetzt."
		ELSE												;Wenn nicht T99
			IF [[#4200] <> 0]								;Wenn Referenzwert vorhanden
				#[5400+#5008]=[#5053 - #4200 + #4301]		;Z-Offset berechnen und auf Tooltable anwenden
				msg "Neuer Z-Offset fuer Tool "#5008" : "[#5053-#4200+#4301]""
				G43											;TLO vom Tooltable aktivieren
			ELSE											;Wenn kein Referenzwert vorhanden
				#4200 = #5053								;Referenzwert setzen
				msg "Referenz auf G53 "#5053" gesetzt."
			ENDIF
		ENDIF
	ELSE
		G0 Z#4233	 										;Sichere Höhe Verfahrwege
		warnmsg "Kein Sensor gefunden!"						;Error ausgeben, kein Sensor gefunden
	ENDIF
EndSub


sub 3dmessung
	; Messergebnisse in G53
	;X -> #5051
	;Y -> #5052
	;Z -> #5053

	msg "PROBE ANSCHLIESSEN! und an linke untere Ecke fahren, Z wird zuerst gemessen."
	M0

	G38.2 G91 Z-10 F100								;Werkstück suchen
	G0 G91 Z+2										;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 Z-5 F25							;Werkstück langsam messen
		G10 L20 P1 Z0								;G54 auf Z0 setzen
		G0 G91 Z+5									;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF

	G0 G91 X-10 									;links neben das Werkstück fahren, um X+ zu messen
	G0 G90 Z-3 										;Auf (absolut/G90) Z-3 fahren (Messhöhe)

	G38.2 G91 X+15 F100								;Werkstück suchen
	G0 G91 X-2										;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 X+5 F25							;Werkstück messen
		G10 L20 P1 X-#4300							;G54 auf X0 setzen
		G0 G91 X-10									;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF

	G0 G90 Z10 										;10mm über das Werkstück fahren
	G0 G91 Y-10 									;10mm nach vorne fahren
	G0 G90 X10 										;10mm nach rechts fahren
	G0 G90 Z-3 										;Auf (absolut/G90) Z-3 fahren (Messhöhe)

	G38.2 G91 Y+15 F100								;Werkstück suchen
	G0 G91 Y-2										;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 Y+5 F25							;Werkstück messen
		G10 L20 P1 Y-#4300							;G54 auf Y0 setzen
		G0 G91 Y-10									;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF

	G90												;Auf Absolutwerte umschalten
	G0 Z5 											;Über das Werkstück fahren
	G0 X0 											;Auf X0 fahren
	G0 Y0 											;Auf Y0 fahren
	G4 P0											;Auf Fahrbewegungen warten

	msg "Messung abgeschlossen!"
endsub

sub Probe_X_pos
	msg "maximal 5mm links neben das zu messende Werkstueck fahren, dann cycle start druecken!"
	M0
	G38.2 G91 X+5 F25								;Werkstück messen
	G10 L20 P1 X-#4300								;G54 auf X0 setzen
	G0 G91 X-5 										;Vom Sensor zurück fahren
	G90
	IF [#5067 == 1]
		msg "Messung erfolgreich"
	ELSE
		errmsg "Werkstueck nicht gefunden!"
	ENDIF
endsub

sub Probe_Y_pos
	msg "maximal 5mm vor das zu messende Werkstueck fahren, dann cycle start druecken!"
	M0
	G38.2 G91 Y+5 F25								;Werkstück messen
	G10 L20 P1 Y-#4300								;G54 auf Y0 setzen
	G0 G91 Y-5 										;Vom Sensor zurück fahren
	G90
	IF [#5067 == 1]
		msg "Messung erfolgreich"
	ELSE
		errmsg "Werkstueck nicht gefunden!"
	ENDIF
endsub

sub Probe_Z_neg
	msg "maximal 5mm ueber das zu messende Werkstueck fahren, dann cycle start druecken!"
	M0
	G38.2 G91 Z-5 F25							;Werkstück messen
	G10 L20 P1 Z0								;G54 auf Z0 setzen
	G0 G91 Z+5 									;Vom Sensor zurück fahren
	G90
	IF [#5067 == 1]
		msg "Messung erfolgreich"
	ELSE
		errmsg "Werkstueck nicht gefunden!"
	ENDIF
endsub

sub calib_probe


	; Messergebnisse in G53
	;X -> #5051
	;Y -> #5052
	;Z -> #5053

	msg "Mittig ueber das zu messende Werkstueck fahren, es wird zuerst Z gemessen"
	M0
	dlgmsg "Referenzmaß eingeben (z.B. von einem 1-2-3 Block)" "Laenge X" 210 "Laenge Y" 211
	msg "Laenge X = " #210 ", Laenge Y = " #211
	G38.2 G91 Z-10 F100								;Werkstück Z suchen
	G0 G91 Z+2 										;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 Z-5 F25							;Werkstück langsam messen
		G10 L20 P1 Z0								;G54 auf Z0 setzen
		G0 G91 Z+5									;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF
	G10 L20 P1 X0									;G54 auf X0 setzen
	G10 L20 P1 Y0									;G54 auf Y0 setzen
	G0 G90 X-[#210/2+10] 							;10mm links neben das Werkstück fahren
	G0 G90 Z-3 										;Auf Z-3 (Messhöhe) fahren
	G38.2 G91 X+20 F200								;Werkstück in X+ Richtung suchen
	G0 G91 X-2										;Vom Messpunkt zurück fahren
	G38.2 G91 X+5 F25								;Langsame Messung
	G0 G91 X-5										;Vom Messpunkt zurück fahren
	#212 = #5051									;Erste Messung zwischenspeichern
	G0 G90 Z10										;Über das Werkstück fahren
	G0 G90 X+[[#210/2]+10] 							;10mm rechts neben das Werkstück fahren
	G0 G90 Z-3 										;Auf Z-3 (Messhöhe) fahren
	G38.2 G91 X-20 F200								;Werkstück in X- Richtung suchen
	G0 G91 X+2										;Vom Messpunkt zurück fahren
	G38.2 G91 X-5 F25								;Langsame Messung
	G0 G91 X+2										;Vom Messpunkt zurück fahren
	#213 = #5051									;Zweite Messung zwischenspeichern

	#4300 = [[[[#212-#213]*-1]-#210]/2]
	msg "Differenz wird in #4300 gespeichert : " #4300

endsub

sub modbus_write_on_0

	Modbus s1 f5 a0 v1 b9600 fb=n1
	
endsub

sub modbus_write_off_0

	Modbus s1 f5 a0 v0 b9600 fb=n1
	
endsub

sub modbus_write_on_1

	Modbus s1 f5 a1 v1 b9600 fb=n1
	
endsub

sub modbus_write_off_1

	Modbus s1 f5 a1 v0 b9600 fb=n1
	
endsub

sub spindle_warmup
	msg "Zu sicherer Position fahren, dann Cycle Start druecken!"
	M0
	M3 S3000
	G4 P60
	M3 S6000
	G4 P180
	M3 S12000
	G4 P180
	M3 S18000
	G4 P180
	M3 S24000
	G4 P180
	M5 
	msg "Warmup abgeschlossen."
endsub

;*******************
;Centerfinder

;#4310 = Laenge X
;#4311 = Laenge Y
;#4312 = Messhoehe
;#4313 = Sicherheitsdistanz Werkstueck
;#4314 = Suchdistanz
;#4315 = Suchgeschwindigkeit
;#4316 = Messgeschwindigkeit
;#212 = 1. Messpunkt
;#213 = 2. Messpunkt
;*******************


sub Centerfinder
	M5
	M9
	dlgmsg "Center finder" "Laenge X" 4310 "Laenge Y" 4311 "Messhoehe" 4312 "Sicherheitsdistanz Werkstueck" 4313 "Suchdistanz" 4314 "Suchgeschwindigkeit" 4315 "Messgeschwindigkeit" 4316
	IF [#5398 == 1]
		msg "Ungefaehr ueber die Mitte des Werkstuecks fahren, maximal 5mm Hoehe. Es wirz zuerst Z vermessen!"
		M0
		G38.2 G91 Z-#4314 F#4315
		G0 G91 Z+2
		G38.2 G91 Z-3 F#4316
		G10 L20 P1 Z0
		G0 G91 Z+5
		G0 G91 X-[#4310+#4313]
		G1 G90 Z#4312 F#4315
		G38.2 G91 X+#4314 F#4315
		G0 G91 X-2
		G38.2 G91 X+#4314 F#4316
		#212 = #5061
		G0 G90 Z5
		G0 G90 X[#212+#4310+#4313]
		G1 G90 Z#4312 F#4315
		G38.2 G91 X-#4314 F#4315
		G0 G91 X+2
		G38.2 G91 X-#4314 F#4316
		#213 = #5061
		G0 G91 X+5
		G0 G90 Z5
		
	ENDIF
endsub

sub zhcmgrid
;;;;;;;;;;;;;
;probe scanning routine for uneven surface milling
;scanning starts at x=0, y=0

  if [#4100 == 0]
   #4100 = 10  ;nx
   #4101 = 5   ;ny
   #4102 = 40  ;max z 
   #4103 = 10  ;min z 
   #4104 = 1.0 ;step size
   #4105 = 100 ;probing feed
  endif    

  #110 = 0    ;Actual nx
  #111 = 0    ;Actual ny
  #112 = 0    ;Missed measurements counter
  #113 = 0    ;Number of points added
  #114 = 1    ;0: odd x row, 1: even xrow

  ;Dialog
  dlgmsg "gridMeas" "nx" 4100 "ny" 4101 "maxZ" 4102 "minZ" 4103 "gridSize" 4104 "Feed" 4105 
    
  if [#5398 == 1] ; user pressed OK
    ;Move to startpoint
    g0 z[#4102];to upper Z
    g0 x0 y0 ;to start point
        
    ;ZHCINIT gridSize nx ny
    ZHCINIT [#4104] [#4100] [#4101] 
    
    #111 = 0    ;Actual ny value
    while [#111 < #4101]
        if [#114 == 1]
          ;even x row, go from 0 to nx
          #110 = 0 ;start nx
          while [#110 < #4100]
            ;Go up, goto xy, measure
            g0 z[#4102];to upper Z
            g0 x[#110 * #4104] y[#111 * #4104] ;to new scan point
            g38.2 F[#4105] z[#4103];probe down until touch
                    
            ;Add point to internal table if probe has touched
            if [#5067 == 1]
              ZHCADDPOINT
              msg "nx="[#110 +1]" ny="[#111+1]" added"
              #113 = [#113+1]
            else
              ;ZHCADDPOINT
              msg "nx="[#110 +1]" ny="[#111+1]" not added"
              #112 = [#112+1]
            endif

            #110 = [#110 + 1] ;next nx
          endwhile
          #114=0
        else
          ;odd x row, go from nx to 0
          #110 = [#4100 - 1] ;start nx
          while [#110 > -1]
            ;Go up, goto xy, measure
            g0 z[#4102];to upper Z
            g0 x[#110 * #4104] y[#111 * #4104] ;to new scan point
            g38.2 F[#4105] z[#4103];probe down until touch
                    
            ;Add point to internal table if probe has touched
            if [#5067 == 1]
              ZHCADDPOINT
              msg "nx="[#110 +1]" ny="[#111+1]" added"
              #113 = [#113+1]
            else
              ;ZHCADDPOINT
              msg "nx="[#110 +1]" ny="[#111+1]" not added"
              #112 = [#112+1]
            endif

            #110 = [#110 - 1] ;next nx
          endwhile
          #114=1
        endif
	  
      #111 = [#111 + 1] ;next ny
    endwhile
        
    g0 z[#4102];to upper Z
    ;Save measured table
    ZHCS zHeightCompTable.txt
    msg "Done, "#113" points added, "#112" not added" 
        
  else
    ;user pressed cancel in dialog
    msg "Operation canceled"
  endif
endsub

;Remove comments if you want additional reset actions
;when reset button was pressed in UI
sub user_reset
    msg "User reset"
	gosub INIT
endsub 

; The start subroutine is called when a job is started
sub start
  ; msg "start macro called"
endsub
