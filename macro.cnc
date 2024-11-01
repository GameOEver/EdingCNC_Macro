;*****************************************
; Version von Jens

;#210 = Laenge X waehrend Kalibrierung
;#211 = Laenge Y waehrend Kalibrierung
;#212 = 1. Messpunkt X waehrend Kalibrierung
;#213 = 2. Messpunkt X waehrend Kalibrierung
;#234 = Z Offset (errechnet)
;#4230 = X Position TLS
;#4231 = Y Position TLS
;#4232 = Sichere Höhe für Werkzeugwechsel (IN G53!!)
;#4233 = Sichere Höhe für Verfahrwege G53
;#4234 = Suchgeschwindigkeit TLS
;#4235 = Messgeschwindigkeit TLS
;#4300 = Durchmesser 3d Probe Spitze


G17 G21 G90

;User functions, F1..F11 in user menu

Sub user_1
    msg "sub user_1"
Endsub

Sub user_2
    msg "sub user_2"
Endsub

Sub user_3 
    msg "sub user_3"
Endsub

Sub user_4
    msg "sub user_4"
Endsub

Sub user_5
    msg "sub user_5"
Endsub

Sub user_6
    msg "sub user_6"
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
    gosub 3dmessung
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

Sub zero_set_rotation
    msg "move to first point, press control-G to continue"
    m0
    #5020 = #5071 ;x1
    #5021 = #5072 ;y1
    msg "move to second point, press control-G to continue"
    m0
    #5022 = #5071 ;x2
    #5023 = #5072 ;y2
    #5024 = ATAN[#5023 - #5021]/[#5022 - #5020]
    if [#5024 > 45]
      #5024 = [#5024 - 90] ;points are in Y direction
    endif
    g68 R#5024
    msg "G68 R"#5024" applied, now zero XYZ normally"
Endsub



sub change_tool
	M5										;Spindel aus
	M9										;Kühlung aus

    ;Use #5015 to indicate succesfull toolchange
    #5015 = 0 ; Tool change not performed

    ; check tool in spindle and exit sub
    	If [ [#5011] == [#5008] ]
        	msg "Tool already in spindle"
        	#5015 = 1 ;indicate tool change performed
    	ELSE    
	
		msg "Tool "#5011" einsetzen, dann mit Cycle Start fortfahren!"
		M0        
		#5015 = 1 ; Tool change performed
	ENDIF
	
	IF [[#5015] == 1] THEN   
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

	; G43.1 K<neues dynamisches Z offset>
	; G49 löscht das Z Offset, kann aber stattdessen auch überschrieben werden

	; Position X des WLS G53
	IF[#5008 == 31]
		#4230 = -193 ;offset für T31
	ELSE
		#4230 = -205 ;wenn nicht T31, dann kein Offset
	ENDIF

	; Position Y des WLS G53
	;#4231 = <TLS_Y> ;muss eingetragen werden
	; Y bei mir unnötig

	; Sichere Höhe für Werkzeugwechsel (IN G53!!)
	#4232 = -50 ;muss eingetragen werden

	; Sichere Höhe für Verfahrwege G53
	#4233 = [#5113-1] ;muss eingetragen werden

	; Suchgeschwindigkeit TLS 
	#4234 = 200 ;muss eingetragen werden

	; Messgeschwindigkeit TLS 
	#4235 = 10 ;muss eigetragen werden

	; #234 speichert den Referenzwert(in Z G53) von T99

	M5													;Spindel aus
	M9													;Kühlung aus
	G1 G53 Z#4233 F500									;Sichere Höhe Verfahrwege
	G1 G53 X#4230 F500									;Fahre zur X Position des TLS
	G1 G53 Z#4232 F500									;Starthöhe Messung TLS
	G4 P0												;wait for moves to finish

	IF [[#5008 <> 99] AND [#234 == 0]]
		dlgmsg "Es ist noch kein Z Offset für die Probe gesetzt. Fortfahren?"
			IF [[#5398] == 1]
														;Programm fortführen
			ELSE
				errmsg "Es wurde kein Z Offset gesetzt, bitte neu starten."
			ENDIF
	ELSE
	;
	ENDIF

	msg "Messung wird gesartet. Mit Cycle Start fortfahren."
	M0

	G38.2 G91 Z-100 F#4234 							;look for TLS
	G1 G91 Z+2 F500									;Von Sensor zurück fahren

	IF [[#5067] == 1]								;Wenn Sensor gefunden wurde
		G38.2 G91 Z-5 F#4235 						;Werkzeug messen
		G1 G91 Z+5 F500								;Von Sensor zurück fahren
		G90											;Absolute Koordinaten verwenden
		G1 G53 Z#4233 F500							;Sichere Höhe Verfahrwege

		IF [[#5008] == 99]							;Wenn T99(Probe)
			#234 = #5053							;Referenzwert setzen
			msg "Referenz auf G53 "#5053" gesetzt."
		ELSE										;Wenn nicht T99
			IF [[#234] <> 0]							;Wenn Referenzwert vorhanden
				#[5400+#5008]=[#5053 - #234]				;Z-Offset berechnen und auf Tooltable anwenden
				msg "Neuer Z-Offset fuer Tool "#5008" : "[#5053-#234]""
				G43									;TLO vom Tooltable aktivieren
			ELSE									;Wenn kein Referenzwert vorhanden
				#234 = #5053						;Referenzwert setzen
				msg "Referenz auf G53 "#5053" gesetzt."
			ENDIF
		ENDIF
	ELSE
		G1 Z#4233 F200 								;Sichere Höhe Verfahrwege
		errmsg "Kein Sensor gefunden!"				;Error ausgeben, kein Sensor gefunden
	ENDIF
EndSub


sub 3dmessung
	; Messergebnisse in G53
	;X -> #5051
	;Y -> #5052
	;Z -> #5053

	msg "PROBE ANSCHLIESSEN!!!"
	M0

	msg "an linke untere Ecke fahren, Z wird zuerst gemessen."
	M0

	G38.2 G91 Z-10 F100								;Werkstück suchen
	G1 G91 Z+2 F500									;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 Z-5 F25							;Werkstück langsam messen
		G10 L20 P1 Z0								;G54 auf Z0 setzen
		G1 G91 Z+5 F500								;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF

	G1 G91 X-10 F200								;links neben das Werkstück fahren, um X+ zu messen
	G1 G90 Z-3 F200									;Auf (absolut/G90) Z-3 fahren (Messhöhe)

	G38.2 G91 X+15 F100								;Werkstück suchen
	G1 G91 X-2 F500									;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 X+5 F25							;Werkstück messen
		G10 L20 P1 X0								;G54 auf X0 setzen
		G1 G91 X-10 F500							;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF

	G1 G90 Z10 F500									;10mm über das Werkstück fahren
	G1 G91 Y-10 F500								;10mm nach vorne fahren
	G1 G90 X10 F500									;10mm nach rechts fahren
	G1 G90 Z-3 F200									;Auf (absolut/G90) Z-3 fahren (Messhöhe)

	G38.2 G91 Y+15 F100								;Werkstück suchen
	G1 G91 Y-2 F500									;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 Y+5 F25							;Werkstück messen
		G10 L20 P1 Y0								;G54 auf Y0 setzen
		G1 G91 Y-10 F500							;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF

	G90												;Auf Absolutwerte umschalten
	G1 Z15 F200										;Über das Werkstück fahren
	G1 X0 F200										;Auf X0 fahren
	G1 Y0 F200										;Auf Y0 fahren
	G4 P0											;Auf Fahrbewegungen warten

	msg "Messung abgeschlossen!"
endsub

sub Probe_X_pos
	msg "maximal 5mm links neben das zu messende Werkstueck fahren, dann cycle start druecken!"
	M0
	G38.2 G91 X+5 F25							;Werkstück messen
	G10 L20 P1 X0								;G54 auf X0 setzen
	G1 G91 X-5 F500								;Vom Sensor zurück fahren
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
	G38.2 G91 Y+5 F25							;Werkstück messen
	G10 L20 P1 Y0								;G54 auf Y0 setzen
	G1 G91 Y-5 F500								;Vom Sensor zurück fahren
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
	G1 G91 Z+5 F500								;Vom Sensor zurück fahren
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
	G1 G91 Z+2 F500									;Vom Sensor zurück fahren
	IF [#5067 == 1]									;Wenn Sensor gefunden wurde
		G38.2 G91 Z-5 F25							;Werkstück langsam messen
		G10 L20 P1 Z0								;G54 auf Z0 setzen
		G1 G91 Z+5 F500								;Vom Sensor zurück fahren
	ELSE
		errmsg "Es wurde kein Werkstueck gefunden!"
	ENDIF
	G10 L20 P1 X0								;G54 auf X0 setzen
	G10 L20 P1 Y0								;G54 auf Y0 setzen
	G1 G90 X-[#210/2+10] F500
	G1 G90 Z-3 F300
	G38.2 G91 X+20 F200
	G1 G91 X-2 F500
	G38.2 G91 X+5 F200
	G1 G91 X-5 F500
	#212 = #5051
	msg #212
	G1 G90 Z10 F500
	G1 G90 X+[[#210/2]+10] F300
	G1 G90 Z-3 F300
	G38.2 G91 X-20 F200
	G1 G91 X+2 F500
	G38.2 G91 X-5 F200
	G1 G91 X+2 F500
	#213 = #5051
	msg #213
	msg "Subtraktion = " [[#212-#213]*-1]
	msg "Subtraktion von Referenz = "[[[#212-#213]*-1]-#210]
	msg "/2 = "[[[[#212-#213]*-1]-#210]/2]
	#4300 = [[[[#212-#213]*-1]-#210]/2]
	msg "Differenz = " #4300

endsub

sub zhcmgrid
;;;;;;;;;;;;;
;probe scanning routine for eneven surface milling
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
;sub user_reset
;    msg "Ready for operation"
;endsub 

;The 4 subroutines below can be used to add extra code
;add the beginning and end for engrave or laser_engrave
sub laser_engrave_start
  msg "laser_engrave_start"
endsub

sub laser_engrave_end
  msg "laser_engrave_end"
endsub

sub engrave_start
  msg "laser_engrave_start"
endsub

sub engrave_end
  msg "laser_engrave_end"
endsub


; Functions below are used with sheetCAM 
; postprocessor Eding CNC plasma with THC-V2.scpost
sub thcOn
  m20
endsub

sub thcOff
  m21
endsub

sub thcPenDown
  gosub thcReference ; Determine zero pint always at start
  G0 Z4 ; 4 is pierce height. 0 is material surface.
  M3    ; plasma on
  G4 P3 ; pierce delay
endSub

sub thcPenUp
  m5    ; Plasma off
  g4 p1 ; end delay
endsub


sub thcReference
  if [[#5380 == 0] and [#5397 == 0]] ;Probe only when running
    G53 G38.2 Z[#5103+1] F50 ;lowest point 1 mm above negative Z limit with low Feed
    G0 Z[#5063] ;move back to toch point
    G92 Z0 ;Use 0 if the totch itself touches the material, otherwise use the switch offset
  endif
endsub

; The start subroutine is called when a job is started
sub start
  ; msg "start macro called"
endsub
