@echo off

rem ###########################################################################
rem
rem    backup.bat - Version 006 - 06.05.2016
rem
rem    Differentielle Backups unter Verwendung von Hardlinks.
rem
rem    (c) 2007 - Mark Neugebauer - info@raketenphysik.de
rem    http://www.raketenphysik.de/backup.html
rem        2016 - Michael K.
rem    https://www.github.com/pikim
rem
rem ---------------------------------------------------------------------------
rem
rem    H I N W E I S E
rem
rem    Der Prozess 'LVPrcSrv.exe' kann dazu fÅhren, dass das Backup-Skript
rem    beim Setzen der Hardlinks sehr langsam wird bzw. fast vollstÑndig
rem    anhÑlt. Der Prozess steht im Zusammenhang mit Logitech-Webcams und ist
rem    fÅr problematisches Verhalten bekannt (vgl. hierzu die einschlÑgigen
rem    Internet-Foren). Durch Start im 'Abgesicherten Modus' kann dieses
rem    Problem ggf. wirksam umgangen werden!
rem
rem    NICHT-Administratoren mÅssen erst eine Berechtigung erhalten damit sie
rem    Hardlinks erstellen dÅrfen.
rem    Das geschieht unter Windows 7 auf folgendem Weg:
rem    1. "secpol.msc" als Administrator ausfÅhren
rem    2. Navigation nach "Sicherheitseinstellungen", "Lokale Richtlinie",
rem       "Zuweisen von Benutzerrechten"
rem    3. Doppelklick auf "Erstellen symbolischer VerknÅpfungen"
rem    4. Klick auf "Benutzer oder Gruppe hinzufÅgen..."
rem    5. Den Benutzernamen in das Eingabefeld eintragen und den
rem       "Namen ÅberprÅfen"
rem    6. Beide Dialoge mit "OK" bestÑtigen
rem    7. Aus- und wieder Einloggen
rem
rem ---------------------------------------------------------------------------
rem
rem    C H A N G E L O G
rem
rem    Version 002: - umfangreiche Log-Funktion ergÑnzt
rem                 - Unterroutinen fÅr Trennlinien eingerichtet
rem                 - unterschiedliche Behandlung von %date% fÅr XP und
rem                   W2k vorgesehen
rem                 - PrÅfung auf aktivierte Befehlserweiterungen ergÑnzt
rem                 - automatische Aktivierung der verzîgerten Erweiterung
rem                   von Umgebungsvariablen ergÑnzt
rem                 - automatische Aktivierung der Befehlserweiterung ergÑnzt
rem                 - Quellpfad-Eingabe via 'set' vorgesehen, damit Leer-
rem                   zeichen berÅcksichtigt werden kînnen
rem    Version 003: - einzelne Pfade kînnen vom Backup ausgeschlossen werden
rem    Version 004: - Verfahren fÅr den Ausschluss einzelner Pfade vereinfacht
rem    Version 005: - Hardlinks werden nur fÅr identische Dateien eingerichtet
rem                 - Log-Dateien werden im tmp-Verzeichnis erstellt
rem                 - Log-Datei fÅr 'Problemdateien' wird erstellt
rem    Version 006: - Portierung auf Windows 7 in Verbindung mit mklink und fc
rem                 - Quellverzeichnis kann als Argument Åbergeben werden
rem                 - Neben differentiellen Sicherungen kînnen auch Voll-
rem                   Sicherungen und Einzel-Sicherungen erstellt werden
rem                 - Verzeichnisstruktur leicht modifiziert: Sicherungen
rem                   werden auf der Ebene von backup.bat erstellt (siehe unten)
rem                 - Log-Dateien werden direkt im log-Verzeichnis der
rem                   jeweiligen Sicherung erstellt
rem                 - weitere kleinere énderungen
rem
rem ---------------------------------------------------------------------------
rem
rem    W U N S C H L I S T E
rem
rem       - Hardlinks auch fÅr Dateien mit Sonderzeichen wie '!' oder '%'
rem         ermîglichen
rem
rem ---------------------------------------------------------------------------
rem
rem    V A R I A B L E N
rem
rem      d:\           (Quellverzeichnis)  %src_path%
rem      f:\           (Backup-Laufwerk)   %home_path%
rem         backup\    (Optional)
rem            backup.bat
rem            bu_name1\                   %backup_name%
rem               2007_08_01
rem               2007_09_05               %prev_dir%
rem               2007_10_03               %dest_dir% bzw. %dest_path%
rem            bu_name2\
rem               ...
rem
rem ###########################################################################

  cls
  echo.
  echo ###############################################################################
  echo #                                                                             #
  echo #  backup.bat                                                                 #
  echo #                                                                             #
  echo ###############################################################################
  echo.

  rem PrÅfung auf aktivierte Befehlserweiterungen
  rem set ERRORLEVEL=
  rem if "%ERRORLEVEL%"=="" (
  rem     echo  FEHLER: Die Befehlserweiterungen sind nicht aktiviert.
  rem     echo          Die Shell muss mit der Option /E:ON gestartet werden.
  rem     echo.
  rem     exit
  rem )

  rem Aktivierung der Befehlserweiterungen
  setlocal ENABLEEXTENSIONS

  rem Aktivierung der verzîgerten Erweiterung von Umgebungsvariablen
  setlocal ENABLEDELAYEDEXPANSION

  rem Shell einrichten
  color 0A
  set header=backup.bat - info@raketenphysik.de
  title %header%

  rem Windows-Version ermitteln
  set win=
  for /F "tokens=3 delims= " %%V in ('ver') do set win=%%V

  rem Pfad fÅr Backup-Verzeichnisse ermitteln
  rem Punkt hinten anhÑngen um Probleme mit folgendem \ zu vermeiden
  set home_path=%~dp0.
  rem Noch besser ist es aber \ und . zu lîschen
  set home_path=%home_path:\.=%

  rem GewÑhlte Aktion als Variable verfÅgbar machen
  set action=
  set action=%~1

  rem Backup-Namen als Variable verfÅgbar machen
  set backup_name=
  set backup_name=%~2
  
  rem Aktion und Name sind jetzt gesichert und werden entfernt
  shift
  shift

  rem Die restlichen Argumente als Variable verfÅgbar machen
  set args=%~1

:get_params
  shift
  if "%~1"=="" goto got_all_params
  set args=%args% %~1
  goto get_params
:got_all_params
  
  if "%action%"=="" goto help
  if "%action%"=="/?" goto help
  if "%action%"=="/h" goto help
  if "%action%"=="/H" goto help
  if "%action%"=="/help" goto help
  if "%action%"=="/n" goto new
  if "%action%"=="/N" goto new
  if "%action%"=="/b" goto backup
  if "%action%"=="/B" goto backup
  if "%action%"=="/d" goto date
  if "%action%"=="/D" goto date
  if "%action%"=="/i" goto info
  if "%action%"=="/I" goto info
  if "%action%"=="/f" goto file
  if "%action%"=="/F" goto file

  color 0C
  echo FEHLER: Parameter "%action%" ist nicht bekannt.
  goto end

rem ###########################################################################
rem                   H E L P
rem ###########################################################################

:help

  color
  echo  Erstellt differentielle Backups unter Verwendung von Hardlinks.
  echo.
  echo  BACKUP [/N Name [Pfad] [Optionen]] [/B Name] [/D] [/F Name] [/I Name]
  echo.
  echo    /N   Ein neues Backup 'Name' vom Quell-Verzeichnis 'Pfad' wird eingerichtet.
  echo         Die Angabe von 'Pfad' und weiterer Optionen ist optional.
  echo.
  echo         Mîgliche Optionen:
  echo         /diff    Differentielle Sicherung (Standard)
  echo         /full    VollstÑndige Sicherung
  echo         /single  Sichert den aktuellen Stand ohne jegliche Historie.
  echo.
  echo    /B   Es wird ein Backup fÅr 'Name' erstellt.
  echo.
  echo    /D   FÅr die eingerichteten Backups wird jeweils das Datum der
  echo         letzten Aktualisierung angezeigt.
  echo.
  echo    /F   FÅr eine einzelne Datei wird eine Historie innerhalb des
  echo         Backups 'Name' erstellt.
  echo.
  echo    /I   Die Historie der freien Notizen fÅr 'Name' werden angezeigt.
  echo.

  goto end

rem ###########################################################################
rem                   D A T E
rem ###########################################################################

:date

  set datum=

  rem Verzeichnisse durchlaufen ...
  for /D %%V in ("%home_path%\*") do (

    rem Backup-Verzeichnis feststellen
    if exist "%%V\config.bak" (

      rem Backups durchlaufen ...
      rem (letzes Verzeichnis entspricht letzter Aktualisierung)
      for /D %%B in ("%%V\*") do (
        set datum=%%~nB
      )
      echo  !datum! - %%~nV
    )
  )

  echo.

  goto end

rem ###########################################################################
rem                   I N F O
rem ###########################################################################

:info

  if "%backup_name%"=="" goto parameter_err

  if not exist "%home_path%\%backup_name%" (
      color 0C
      echo  FEHLER: Ein Backup unter dem Namen "%backup_name%"
      echo          wurde noch nicht eingerichtet.
      echo.
      goto end
  )

  for /D %%D in ("%home_path%\%backup_name%\*") do (type  "%%D\log\notes.txt")

  goto end

rem ###########################################################################
rem                   F I L E
rem ###########################################################################

:file

  if "%backup_name%"=="" goto parameter_err

  if not exist "%home_path%\%backup_name%" (
      color 0C
      echo  FEHLER: Ein Backup unter dem Namen "%backup_name%"
      echo          wurde noch nicht eingerichtet.
      echo.
      goto end
  )

  set /p filename=" Bezeichnung der gesuchten Datei: "
  echo.

  for /f "tokens=1* delims=" %%D in ('dir "%home_path%\%backup_name%\%filename%" /s /b') do (
    set help=%%D
    set help=!help:%home_path%=!
    echo   %%~tD  %%~zD Bytes  !help!
  )

  echo.

  goto end

rem ###########################################################################
rem                   N E W
rem ###########################################################################

:new

  rem Wenn ein Backup mit diesem Namen bereits existiert, muss dieses gelîscht
  rem oder ein neuer Name vergeben werden.
  if exist "%home_path%\%backup_name%" (
    color 0C
    echo  FEHLER: Ein Backup unter dem Namen "%backup_name%"
    echo          existiert bereits.
    echo.
    set delete=
    set /p delete=" Soll das vorhandene Backup gelîscht werden (j/n)? "
    echo.
    rem if "!delete!"=="Y" set delete=j
    rem if "!delete!"=="y" set delete=j
    if "!delete!"=="J" set delete=j
    if "!delete!"=="j" (
      rem rd kann nicht mit Hardlinks umgehen, daher ist evtl. auch del nîtig
      rem del /f /s /q "%home_path%\%backup_name%\__old__" >> "!deleted_txt!" 2>&1
      rd /s /q "%home_path%\%backup_name%"
      echo "%backup_name%" wurde gelîscht.
    ) else (
      set backup_name=
      set /p backup_name=" Neuer Name fÅr neues Backup (nur 'Enter' zum abbrechen): "
      if "!backup_name!"=="" (
        echo.
        echo Vorgang abgebrochen.
        goto end
      )
    )
    echo.
    color 0A
  )

  rem Etwaigen Source-Pfad als Variable verfÅgbar machen
  set src_path=

  rem öberprÅfen ob es sich um einen existierenden relativen Pfad handelt, oder
  rem um einen existierenden absoluten Pfad. Reihenfolge beibehalten, da sonst
  rem mit dem relativen Pfad fortgefahren und kein absoluter erzeugt wird.
  for %%a in (%args%) do (
    set temp=%%a
    if exist "%home_path%\!temp!" (
      set src_path=%home_path%\!temp!
      goto src_found
    ) else (
      if exist "!temp!" (
        set src_path=!temp!
        goto src_found
      )
    )
  )

:src_found

  if "%src_path%"=="" (
    rem Eingabe des zu sichernden Pfades
    set /p src_path=" Quellpfad fÅr Backup "%backup_name%": "
  ) else (
    rem Ausgabe des per Argument Åbergebenen Pfades
    echo Quellpfad fÅr Backup "%backup_name%": "%src_path%"
    rem Dieses Argument jetzt ebenfalls entfernen
    call set args=%%args:%temp%=%%
  )
  echo.

  rem Fehlerbehandlung fÅr manuell eingegebenen Pfad.
  rem Nur absolute Pfade sind erlaubt, sonst kann der Dateiname nicht
  rem extrahiert werden, siehe Kommentar bei Hardlink-Erstellung
  if "%src_path%"=="%src_path::=%" (
    set src_path=%home_path%\%src_path%
  )

  if not exist "%src_path%" (
    color 0C
    echo  FEHLER: Der angegebene Pfad "%src_path%"
    echo          existiert nicht.
    echo.
    goto end
  )

  mkdir "%home_path%\%backup_name%"
  echo  %time:~0,-3% - Backup-Verzeichnis "%home_path%\%backup_name%" eingerichtet.
  echo.

  rem ACHTUNG: Hier kein Leerzeichen hinter "%src_path%", da dies mit in die Datei
  rem          geschrieben und spÑter den Pfad ungÅltig machen wÅrde!
  echo INCLUDE: "%src_path%"> "%home_path%\%backup_name%\config.bak"

  echo  HINWEIS: Eingabe weiterer Pfade beenden mit [RETURN].
  echo.

:get

  set input=
  set /p input=" Quellpfad exklusive folgender Pfade: "

  if not "%input%"=="" (
    echo EXCLUDE: "%input%">> "%home_path%\%backup_name%\config.bak"
    goto get
  )

  rem Etwas Dummy-Text einfÅgen fÅr die Suche nach weiteren SchlÅsselwîrtern
  set args=dummytext %args%

  rem Sicherungstyp feststellen und in Konfiguration schreiben
  set temp=diff
  if not "%args%"=="%args:/full=%" (
    set temp=full
  )
  if not "%args%"=="%args:/single=%" (
    set temp=single
  )
  echo BACKUP-TYPE: %temp%>> "%home_path%\%backup_name%\config.bak"

  echo.
  echo  %time:~0,-3% - Konfigurationsdatei "%home_path%\%backup_name%\config.bak" erstellt.
  echo.

  goto backup

rem ###########################################################################
rem                   B A C K U P
rem ###########################################################################

:backup

  if "%backup_name%"=="" goto parameter_err

  if not exist "%home_path%\%backup_name%" (
      color 0C
      echo  FEHLER: Ein Backup unter dem Namen "%backup_name%"
      echo          wurde noch nicht eingerichtet.
      echo.
      goto end
  )

  rem Verzeichnis des vorigen Backups ermitteln - sofern vorhanden
  rem (Backups durchlaufen - letzes Verzeichnis entspricht letzter Aktualisierung)
  set prev_dir=
  for /D %%B in ("%home_path%\%backup_name%\*") do (
    set prev_dir=%%~nB
  )

  rem Zielpfad fÅr aktuelles Backup aus Tagesdatum ermitteln
  rem (Aufbau der Umgebungsvariable %date% ist abhÑngig von Betriebssystem)
  set dest_dir=

  for /F "tokens=1,2,3,4 delims=. " %%K in ("%date%") do (
    if "%win%"=="2000" (
      set dest_dir=%%N_%%M_%%L
    ) else (
      set dest_dir=%%M_%%L_%%K
    )
  )

  set dest_path=%home_path%\%backup_name%\%dest_dir%

  if exist "%dest_path%" (
      color 0C
      echo  FEHLER: Es existiert bereits ein Backup unter dem Namen "%backup_name%"
      echo          fÅr das aktuelle Datum.
      echo.
      goto end
  )

  rem Verzeichnisse fÅr aktuelles Backup erstellen
  mkdir "%dest_path%\backup"
  echo  %time:~0,-3% - Verzeichnis "%dest_path%\backup" erstellt.
  echo.
  mkdir "%dest_path%\log"
  echo  %time:~0,-3% - Verzeichnis "%dest_path%\log" erstellt.
  echo.

  rem Pfade zu den Log-Dateien als Variablen anlegen
  set log_txt=%dest_path%\log\log.txt
  set files_txt=%dest_path%\log\files.txt
  set notes_txt=%dest_path%\log\notes.txt
  set problem_txt=%dest_path%\log\problem.txt
  set hardlink_txt=%dest_path%\log\hardlink.txt
  set verify_txt=%dest_path%\log\verify.txt
  set deleted_txt=%dest_path%\log\deleted.txt
  
  rem Textfile fÅr Log-Informationen anlegen
  type NUL > "%log_txt%"
  call :stripline >> "%log_txt%"
  echo. >> "%log_txt%"
  echo  %time:~0,-3% - Log-Datei wurde erstellt.
  echo.
  call :stripline
  echo.

  rem Quellpfad und exkludierte Pfade aus Stammdatei ermitteln
  set src_path=
  set exc_path=
  set backup_type=
  rem Die Option 'usebackq' wird verwendet, um AnfÅhrungszeichen in der Pfadangabe
  rem verwenden zu kînnen!
  for /F "usebackq tokens=1* delims=: " %%I in ("%home_path%\%backup_name%\config.bak") do (
    if "%%I"=="INCLUDE" set src_path=%%J
    if "%%I"=="EXCLUDE" (
      if "!exc_path!"=="" (set exc_path=%%J) else (set exc_path=!exc_path! %%J)
    )
	  if "%%I"=="BACKUP-TYPE" set backup_type=%%J
  )

  rem AnfÅhrungszeichen aus dem gelesenen String entfernen. Diese mÅssen
  rem bei Verwendung immer manuell angefÅgt werden
  set src_path=%src_path:"=%

  rem Nulldateien erstellen, sofern neues Backup eingerichtet wird;
  rem Hardlinks auf das vorige Backup erstellen, sofern aktualisiert wird.

  if "%action%"=="/n" (

    echo    BACKUP.BAT: NULLDATEIEN ERSTELLEN ... >> "%log_txt%"
    echo  BACKUP.BAT: NULLDATEIEN ERSTELLEN ...

    rem Erstellt Nulldateien und Verzeichnisstruktur, au·er denen in exc_path
    start /b robocopy "%src_path%" "%dest_path%\backup" /LOG+:"%log_txt%" ^
      /XD %exc_path% /TEE /NDL /NFL /create /E /R:2 /W:1
    call :progress

    echo. >> "%log_txt%"
    echo. >> "%log_txt%"
    call :robocopy_errlvl

  ) else (

    rem Verzeichnisstruktur entsprechend Quellverzeichnis(!) anlegen
    echo    BACKUP.BAT: VERZEICHNISSTRUKTUR ANLEGEN ... >> "%log_txt%"
    echo  BACKUP.BAT: VERZEICHNISSTRUKTUR ANLEGEN ...

    rem Erstellt nur die Verzeichnisstruktur
    start /b robocopy "%src_path%" "%dest_path%\backup" /LOG+:"%log_txt%" ^
      /XD %exc_path% /TEE /NDL /NFL /E /R:2 /W:1 /XF *
    call :progress

    echo. >> "%log_txt%"
    echo. >> "%log_txt%"
    call :robocopy_errlvl
    call :stripline
    echo.

    rem Hardlinks nur fÅr die Dateien des vorigen Backups einrichten, die auch
    rem im Quellverzeichnis noch unverÑndert existieren.

    echo  BACKUP.BAT: HARDLINKS EINRICHTEN ...
    echo.
    call :separator
    echo.
    echo  Basis fÅr Hardlinks [letzte Aktualisierung]      : %prev_dir%

    rem ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    rem  ALTERNATIV: Liste identischer Dateien mit 'windiff' erstellen
    rem ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    rem rem Liste identischer Dateien erstellen
    rem start /WAIT windiff -Ssx "%dest_path%\log\windiff.txt" -T ^
    rem  "%home_path%\%backup_name%\%prev_dir%\backup" ^
    rem  "%src_path%"
    rem
    rem rem ACHTUNG: in der folgenden Zeile ist <TAB> als Delimiter angegeben
    rem for /F "usebackq eol=- delims=	" %%I in ("%dest_path%\log\windiff.txt") do (
    rem
    rem   set help=%%I
    rem
    rem   rem Hardlink setzen (Ausgabe unterdrÅcken)
    rem   fsutil hardlink create "%dest_path%\backup!help:~1!" ^
    rem     "%home_path%\%backup_name%\%prev_dir%\backup!help:~1!" >> "%hardlink_txt%"
    rem
    rem   rem DateizÑhler inkrementieren
    rem   set /A count_links=count_links+1
    rem   title backup.bat - Hardlinks: !count_links!
    rem
    rem )
    rem ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    rem Liste identischer Dateien erstellen
    start /b robocopy "%src_path%" "%home_path%\%backup_name%\%prev_dir%\backup" ^
      /LOG:"%files_txt%" /XD %exc_path% /NDL /E /NOCOPY /NS /V /R:2 /W:1
    call :progress

    rem ZÑhler zurÅcksetzen
    set /A count_links=0
    set help=

    rem Log-Datei fÅr Hardlinks und Problemdateien (Åbersprungen) anlegen
    type NUL > "%hardlink_txt%"
    type NUL > "%problem_txt%"

    rem kurze Pause einfÅgen, damit 'files.txt' zur VerfÅgung steht
    ping localhost -n 1 > NUL

    rem Hardlinks bei Voll-Sicherungen nicht erstellen
    if not "%backup_type%"=="full" (
      rem ACHTUNG: in der folgenden Zeile ist <TAB><SPACE> als Delimiter angegeben
      for /F "usebackq eol=- tokens=1* delims=	 " %%I in ("%files_txt%") do (

        if "%%I"=="Gleich" (

          rem Dateinamen holen und extrahieren
          set help=%%J
          set help=!help:%src_path%=!

          rem Hardlinks setzen, aber Problemdateien mit '!' oder '%' im Pfad ignorieren
          rem Problemdateien werden spÑter mit robocopy kopiert ...
          if exist "%home_path%\%backup_name%\%prev_dir%\backup!help!" (

            rem ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            rem  ALTERNATIV: Hardlink setzen mit mklink
            rem ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
            rem Hardlink setzen (Ausgabe unterdrÅcken)
            mklink /h "%dest_path%\backup!help!" ^
              "%home_path%\%backup_name%\%prev_dir%\backup!help!" ^
              >> "%hardlink_txt%"

            rem Hardlink setzen (Ausgabe unterdrÅcken)
            rem start /b /wait fsutil hardlink create "%dest_path%\backup!help!" ^
            rem   "%home_path%\%backup_name%\%prev_dir%\backup!help!" ^
            rem  >> "%hardlink_txt%"

            rem DateizÑhler inkrementieren
            set /A count_links=count_links+1
            title backup.bat - Hardlinks: !count_links!

          ) else (

            rem Log-Datei fÅr Problemdateien schreiben
            echo "!help!" >> "%problem_txt%"
          )
        )
      )
    )

    title %header%

    echo.
    echo  Anzahl Hardlinks im aktuellen Backup "%dest_dir%": !count_links!
    echo.
  )

  rem Die Option /MIR wird hier nicht benîtigt, da es im Zielverzeichnis weder
  rem Verzeichnisse noch Hardlinks geben kann, die im Quellverzeichnis nicht
  rem enthalten sind!

  call :stripline >> "%log_txt%"
  echo. >> "%log_txt%"
  call :stripline
  echo.
  echo    BACKUP.BAT: DATEIEN KOPIEREN ... >> "%log_txt%"
  echo  BACKUP.BAT: DATEIEN KOPIEREN ...

  rem Dateien kopieren
  start /b robocopy "%src_path%" "%dest_path%\backup" /LOG+:"%log_txt%" ^
    /XD %exc_path% /NP /NDL /TEE /E /R:2 /W:1
    rem folgende Optionen unterdrÅcken die Ausgabe von Datei- und Pfadangaben
    rem /XD %exc_path% /TEE /NDL /NFL /E /R:2 /W:1
  call :progress

  echo. >> "%log_txt%"
  echo. >> "%log_txt%"
  call :robocopy_errlvl
  call :stripline
  echo.

  rem Backup mit Schreibschutz versehen
  echo  %time:~0,-3% - ATTRIB gestartet ... [Schreibschutz setzen]
  echo.
  attrib -h +r "%dest_path%\backup\*" /s /d > NUL
  echo  %time:~0,-3% - ATTRIB beendet.
  echo.

  rem Textfile fÅr Verify-Informationen anlegen
  type NUL > "%verify_txt%"

  rem Inhalt von Quell- und Zielverzeichnis prÅfen
  echo  %time:~0,-3% - Verifikation gestartet ...
  echo.
  start /b fc /b "%src_path%\*" "%dest_path%\backup\*" | find "FC:" | find /v ^
    "Keine Unterschiede gefunden" >> "%verify_txt%"
  echo  %time:~0,-3% - Verifikation beendet.
  echo.

  rem Verifikations-Log ausgeben sowie an Log-Datei anhÑngen und im Anschluss lîschen
  call :stripline >> "%log_txt%"
  echo. >> "%log_txt%"
  call :stripline
  echo.
  echo    BACKUP.BAT: Verifikations-LOG ... >> "%log_txt%"
  echo  BACKUP.BAT: Verifikations-LOG ...
  echo. >> "%log_txt%"
  call :separator >> "%log_txt%"
  echo. >> "%log_txt%"
  echo.
  call :separator
  echo.

  rem Textfile fÅr freie Notizen anlegen und îffnen
  type NUL > "%notes_txt%"
  call :separator >> "%notes_txt%"
  echo Backup   : %backup_name% >> "%notes_txt%"
  echo Pfad     : "%src_path%" >> "%notes_txt%"
  echo Datum    : %date% %time:~0,-3% >> "%notes_txt%"
  echo. >> "%notes_txt%"
  echo Kommentar: >> "%notes_txt%"
  echo. >> "%notes_txt%"
  echo. >> "%notes_txt%"
  call :separator >> "%notes_txt%"
  echo  %time:~0,-3% - Textfile fÅr freie Notizen angelegt.
  echo.

  rem Batch-Datei in das Log-Verzeichnis kopieren
  copy backup.bat "%dest_path%\log\backup.bak" > NUL
  echo  %time:~0,-3% - Batch-Backup in Log-Verzeichnis kopiert.
  echo.
  call :stripline
  echo.

  set file_size=
  call :get_filesize "%verify_txt%" file_size

  rem Wenn verify.txt 0 Bytes gro· ist, sind keine Unterschiede gefunden worden,
  rem sprich die Verifikation war erfolgreich.
  rem Verschieben der Verzeichnisse bei erfolgreicher einfacher Sicherung
  if %file_size%==0 (
    del "%verify_txt%"
    if "%backup_type%"=="single" (
      rem Verzeichnisse umbenennen (sofern vorhanden)
      if "%prev_dir%"=="" (
        set prev_dir=current
      ) else (
        ren %home_path%\%backup_name%\%prev_dir% __old__
      )
      ren %dest_path% !prev_dir!

      rem Pfade zu Text-Dateien umbiegen
      call set log_txt=%%log_txt:%dest_dir%=!prev_dir!%%
      call set notes_txt=%%notes_txt:%dest_dir%=!prev_dir!%%
      call set deleted_txt=%%deleted_txt:%dest_dir%=!prev_dir!%%
      call set problem_txt=%%problem_txt:%dest_dir%=!prev_dir!%%

      echo    "%dest_path%" umbenannt in "!prev_dir!". >> "!log_txt!"
      echo. >> "!log_txt!"
      echo  %time:~0,-3% - "%dest_path%" umbenannt in "!prev_dir!".
      echo.
      
      echo Bei Vorhandensein von Hardlinks wird der Zugriff verweigert. >> "!deleted_txt!"
      echo Eine entsprechende Meldung ist bei unverÑnderten Dateien daher normal. >> "!deleted_txt!"
      echo. >> "!deleted_txt!"

      rem "Altes" Verzeichnis lîschen (sofern vorhanden)
      if exist "%home_path%\%backup_name%\__old__" (
        rem Alle Dateien lîschen (auch schreibgeschÅtzte)
        rem >> "!deleted_txt!" 2>&1 leitet auch STDERR-Ausgaben in Datei um
        del /f /s /q "%home_path%\%backup_name%\__old__" >> "!deleted_txt!" 2>&1
        rem Alle Verzeichnisse lîschen (rd kommt nicht mit Hardlinks klar)
        rd /s /q "%home_path%\%backup_name%\__old__"
      )
    )
    echo  Die Datensicherung war erfolgreich.
  ) else (
    color 0C
    echo    FEHLER: Original und Sicherung unterscheiden sich. >> "%log_txt%"
    echo            Details finden Sie in "%verify_txt%" >> "%log_txt%"
    if not "%prev_dir%"=="" (
      echo            Die letzte Sicherung "%prev_dir%" wurde beibehalten. >> "%log_txt%"
    )
    echo  FEHLER: Original und Sicherung unterscheiden sich.
    echo          Details finden Sie in "%verify_txt%"
    if not "%prev_dir%"=="" (
      echo          Die letzte Sicherung "%prev_dir%" wurde beibehalten.
    )
    echo.
    echo  Die Datensicherung war NICHT erfolgreich.
    start notepad.exe "%verify_txt%"
    echo.
    pause
  )

  rem Problemdatei lîschen oder îffnen
  if exist "%problem_txt%" (
    call :get_filesize "%problem_txt%" file_size
    if !file_size!==0 (
      del "%problem_txt%"
    ) else (
      start notepad.exe "%problem_txt%"
    )
  )
  
  start notepad.exe "%notes_txt%"

  goto end

rem ###########################################################################
rem                   S U B : R O B O C O P Y _ E R R L V L
rem ###########################################################################

:robocopy_errlvl

  echo.
  if errorlevel 16 echo     ROBOCOPY: +++ FATAL ERROR +++ & echo. & goto end
  if errorlevel 15 echo     ROBOCOPY: FAIL MISM XTRA COPY & echo. & goto :eof
  if errorlevel 14 echo     ROBOCOPY: FAIL MISM XTRA      & echo. & goto :eof
  if errorlevel 13 echo     ROBOCOPY: FAIL MISM      COPY & echo. & goto :eof
  if errorlevel 12 echo     ROBOCOPY: FAIL MISM           & echo. & goto :eof
  if errorlevel 11 echo     ROBOCOPY: FAIL      XTRA COPY & echo. & goto :eof
  if errorlevel 10 echo     ROBOCOPY: FAIL      XTRA      & echo. & goto :eof
  if errorlevel 09 echo     ROBOCOPY: FAIL           COPY & echo. & goto :eof
  if errorlevel 08 echo     ROBOCOPY: FAIL                & echo. & goto :eof
  if errorlevel 07 echo     ROBOCOPY:      MISM XTRA COPY & echo. & goto :eof
  if errorlevel 06 echo     ROBOCOPY:      MISM XTRA      & echo. & goto :eof
  if errorlevel 05 echo     ROBOCOPY:      MISM      COPY & echo. & goto :eof
  if errorlevel 04 echo     ROBOCOPY:      MISM           & echo. & goto :eof
  if errorlevel 03 echo     ROBOCOPY:           XTRA COPY & echo. & goto :eof
  if errorlevel 02 echo     ROBOCOPY:           XTRA      & echo. & goto :eof
  if errorlevel 01 echo     ROBOCOPY:                COPY & echo. & goto :eof
  if errorlevel 00 echo     ROBOCOPY: ++++ NO CHANGE ++++ & echo. & goto :eof
  goto end

rem ###########################################################################
rem                  S U B : GET_FILESIZE
rem  Usage: CALL :get_filesize %1 result
rem  where %1 is a fully qualified path name and result a variable for the result
rem ###########################################################################

:get_filesize

  set %~2=%~z1
  goto :eof

rem ###########################################################################
rem                  S U B : S T R I P L I N E
rem ###########################################################################

:stripline

  echo ===============================================================================
  goto :eof

rem ###########################################################################
rem                  S U B : S E P E R A T O R
rem ###########################################################################

:separator

  echo -------------------------------------------------------------------------------
  goto :eof

rem ###########################################################################
rem                  S U B : P R O G R E S S
rem ###########################################################################

:progress

  set count=

  :loop

  tasklist | find "robocopy.exe" > NUL

  if not errorlevel 1 (

    if "%count%" == "11" set count=
    set /a count +=1

    if "%count%" ==  "1" title ROBOCOPY:
    if "%count%" ==  "2" title ROBOCOPY: c
    if "%count%" ==  "3" title ROBOCOPY: co
    if "%count%" ==  "4" title ROBOCOPY: cop
    if "%count%" ==  "5" title ROBOCOPY: copy
    if "%count%" ==  "6" title ROBOCOPY: copyi
    if "%count%" ==  "7" title ROBOCOPY: copyin
    if "%count%" ==  "8" title ROBOCOPY: copying
    if "%count%" ==  "9" title ROBOCOPY: copying.
    if "%count%" == "10" title ROBOCOPY: copying..
    if "%count%" == "11" title ROBOCOPY: copying...

    ping localhost -n 1 > NUL

    goto loop

  )

  title %header%

  goto :eof

rem ###########################################################################
rem                  P A R A M E T E R _ E R R
rem ###########################################################################

:parameter_err

  color 0C
  echo  FEHLER: Es wurden nicht genÅgend Parameter Åbergeben.
  goto end

rem ###########################################################################
rem                   E N D
rem ###########################################################################

:end

  rem Shell in ursprÅnglichen Zustand zurÅck versetzen
  title Eingabeaufforderung
  color

  rem énderungen am Status der Befehlserweiterung zurÅcksetzen
  endlocal
