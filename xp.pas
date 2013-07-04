{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams.  }
{ Aenderungen des Sources, die vom OpenXP Teams getaetigt wurden, }
{ unterliegen den Rechten, die bis zum 09.04.2000 fuer das OpenXP }
{ Team gueltig waren.                                             }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xp.pas,v 1.29 2002/02/20 19:56:03 rb Exp $ }

{   Cross\\//        }
{        //\\point   }

{$I XPDEFINE.INC }

{$IFDEF Win32 }
  {$R ICON.RES }
{$ENDIF }

{$IFDEF BP }
  {$F+}
  {$M 32768,150000,655360}
{$ENDIF}

program xp;

uses xpglobal, xpx,crt,dos,typeform,uart,keys,fileio,inout,help,video,datadef,
     database,databaso,maske,mouse,maus2,winxp,win2,montage,lister,archive,
     printerx,crc16,resource,stack,clip,eddef,editor,feiertag,
     xpdiff,xpdatum,xpcrc32,
{$IFDEF CAPI }
     capi,
{$ENDIF }
{$IFDEF OS2 }
     Os2Base,
{$ENDIF }
     xp0,      { Definitionen       }
     xp1,      { allg. Routinen     }
     xp1o,
     xp1o2,
     xp1help,  { Online-Hilfe u.a.  }
     xp1input, { Eingabefunktionen  }
     xpnt,     { Netztypen          }
     xp_des,   { DES-Codierung      }
     xp_pgp,   { PGP-Codierung      }
     xpkeys,   { F-Tasten/Makros    }
     xp_uue,   { UUencode/UUdecode  }
     xp2,      { Startup            }
     xp2par,   { Startup/Parameter  }
     xp2db,    { Database-Startup   }
     xp2c,     { Konfiguration      }
     xp2f,     { Farben & F-Keys    }
     xp3,      { Datenbearbeitung   }
     xp3o,
     xp3o2,
     xp3ex,    { Msg. extrahieren   }
     xp4,      { Hauptmodul         }
     xp4e,
     xp4o,
     xp4o2,    { BezÅge, packen     }
     xp4o3,
     xpauto,   { Autoversand/-Exec  }
     xp5,      { Utilities          }
     xpreg,    { Registrierung      }
     xp6,      { Nachrichten senden }
     xp6o,     { Unversandt, Weiterleiten }
     xp7,      { Netcall            }
     xp7o,
     xp7f,     { Fido-Netcall       }
     xpuu,     { ucico              }
     xp8,      { 'maps & Fileserver }
     xp9,      { UniSel (B/G/S/K)   }
     xp10,     { Timing-Lst./Makros }
     xpe,      { Editor             }
     xpstat,   { Statistik          }
     xpterm,   { CrossTerm          }
     xpcc,     { Verteiler          }
     xpfido,   { Nodelist u.a.      }
     xpfidonl, { Nodelist-Config    }
     xpf2,
     xpmaus,   { Maus-Funktionen    }
     xp_iti,   { Maus-ITI-Infofile  }
     xpview,   { Binfile-Viewer     }
     xpmime,   { Multipart-Decode   }
{$IFDEF BP }
     xpfonts,  { interne Fonts      }
{$ENDIF }
     xpimpexp, { Import/Export      }
     mimedec;

{$IFNDEF Ver32 } { Bei 32 Bit brauchen wir keine Overlays }
  {$O archive}   {$O clip}     {$O crc16}     {$O databaso}
  {$O editor}    {$O feiertag}
  {$O help}      {$O lister}   {$O maske}      {$O video}     {$O win2}
  {$O xp_iti}    {$O xp_pgp}   {$O xp_uue}
  {$O xp10}      {$O xp1help}  {$O xp1input}   {$O xp1o}      {$O xp1o2}
  {$O xp2}       {$O xp2c}     {$O xp2db}      {$O xp2f}      {$O xp2par}
  {$O xp3}       {$O xp3ex}    {$O xp3o}       {$O xp3o2}
  {$O xp4}       {$O xp4e}     {$O xp4o}       {$O xp4o2}     {$O xp4o3}
  {$O xp5}       {$O xp6}      {$O xp6o}
  {$O xp7}       {$O xp7f}     {$O xp7o}       {$O xp8}
  {$O xp9}       {$O xp9bp}    {$O xp9ppp}
  {$O xpauto}    {$O xpcc}     {$O xpdatum}    {$O xpe}
  {$O xpf2}      {$O xpfido}   {$O xpfidonl}   {$O xpfonts}   {$O xpimpexp}
  {$O xpmaus}    {$O xpmime}   {$O xpnt}       {$O xpreg}     {$O xpstat}
  {$O xpterm}    {$O xpuu}     {$O xpview}     {$O mimedec}
  {$IFDEF CAPI }
    {$O capi }
  {$ENDIF }
{$ENDIF }

label ende;

var
        pwcnt      : byte;
        pwrc       : boolean;
{$IFDEF OS2 }
        twj_cp     : smallword;
{$ENDIF }
        twj_scr_ln : byte;

begin
{$IFDEF OS2 }
  VioGetCP(0,twj_cp,0);
  VioSetCP(0,437,0);
{$ENDIF }
  twj_scr_ln:=25;
  twj_scr_ln:=GetScreenLines;
  readpar;
  loadresource;
  testlock;
  testcfg; { CFG-File bei Updates kompatible machen }
  initvar;
    testdiskspace;  { Tests auf freien DiskSpace und Dateihandles verschoben }
    {$IFDEF BP }
    testfilehandles;
    {$ENDIF }
    {$IFDEF OS2 }
    DosSetMaxFH(255);    {TJ 070500 - Provisorikum }
    SetKbd_BinMode;
    {$ENDIF }
  if ParDDebug then dbOpenLog('database.log');
  TestAutostart;
    if not quit then
  begin
    cursor(curoff);
    defaultcolors; SetColors;
    read_regkey;
    readconfig;    { setzt MenÅs }
    convbfg; { BFG-Konvertierung }
    if ParG1 or ParG2 then
    begin
      gtest;
      goto ende;
    end;
    ChangeTboxSN;  { alte IST-Box-Seriennummer -> Config-File }
    test_pfade;
    readkeydefs;
    if not parmono then
    begin
      readcolors(''); { Defaultfarben laden }
      SetColors;
    end;
    showscreen(true);
    DelTmpfiles('*.$$$');
    if getenv('DELVTMP')<>''then begin  {Temporaere Viewer-Files loeschen}
      Delviewtmp:=true;
      DelTmpfiles('TMP-????.*');
      chdir(temppath);
      DelTmpfiles('TMP-????.*');
      chdir(ownpath);
    end;
    (*
    testdiskspace;
    {$IFDEF BP }
    testfilehandles;
    {$ENDIF }
    {$IFDEF OS2 }
    DosSetMaxFH(255);    {TJ 070500 - Provisorikum }
    SetKbd_BinMode;
    {$ENDIF }
    *)
    initdatabase;
    pwcnt:=0; { drei PW-Versuche, dann beenden }
    repeat
      pwrc:=password;
      inc(pwcnt);
    until (pwrc or (pwcnt=3));
    if pwrc then
    begin
      test_defaultbox;
      ReadDomainlist;
      if quit then
      begin    { Registrierungshinweis abgebrochen }
        closedatabases;
        exitscreen(0);
        goto Ende;
      end;
{$IFDEF Beta } { MK 25.01.2000 Betameldung anzeigen, /nb schaltet diese ab }
      if not ParNoBeta then
      begin
        BetaMessage;
        if quit then
        begin    { Betahinweis abgebrochen }
           closedatabases;
           exitscreen(0);
           goto Ende;
        end;
      end;
{$ENDIF }
      test_defaultgruppen;
      test_systeme;
      ReadDefaultViewers;
      testtelefon(telefonnr^);
      check_date;
      check_tz;
      InitNodelist;
      startup:=false;
      showusername;
      AutoSend;
      AutoExec(true);
      if not AutoMode then     { in XP7 }
        mainwindow;
      AutoStop;
{$IFDEF BP }
      FlushSmartdrive(true);
{$ENDIF }
      SetScreenLines(twj_scr_ln);
{$IFDEF OS2 }
      VioSetCP(0,twj_cp,0);
{$ENDIF }
      closedatabases;
      exitscreen(iif(ParNojoke,0,1));
      delete_tempfiles;
      set_checkdate;
    end
  else
    exitscreen(2);
  end;
ende:
  closeresource;
  runerror:=false;
  halt(errlevel);
end.
{
  $Log: xp.pas,v $
  Revision 1.29  2002/02/20 19:56:03  rb
  - MimeIsoDecode auch fÅr andere ZeichensÑtze
  - Iso1ToIBM und IBMToIso1 nach mimedec.pas verlagert
  - text/html wird von UUZ nicht mehr nach IBM konvertiert

  Revision 1.28  2002/01/24 21:41:07  mm
  Unit crc16 -> Overlay

  Revision 1.27  2001/12/22 18:24:59  mm
  - OVR-Part sortiert
  - Units xp9ppp und video sind zwar OVR-faehig, waren aber nicht im OVR

  Revision 1.26  2001/07/24 09:20:30  mm
  - twj_scr_ln auch fuer die Win32-Version aktiviert

  Revision 1.25  2001/07/23 11:25:24  mm
  - icons.res > icon.res (icons.res war kein binaer-file, daher unbrauchbar)
  - {$IFDEF Delphi } {$APPTYPE CONSOLE } rausgenommen - Delphi nutzt hier eh keiner

  Revision 1.24  2001/06/26 17:47:08  MH
  - Parameter /dd: Bei Doppelstart problematisch, daher wird das LogFile
    nun spÑter geîffnet.

  Revision 1.23  2001/06/26 15:02:07  MH
  - Resourcen bei Fehler entladen

  Revision 1.22  2001/06/18 20:17:23  oh
  Teames -> Teams

  Revision 1.21  2001/06/18 07:09:00  MH
  - FileHandleCheck korrigiert
    (konnte natÅrlich nicht funktionieren: Keine Meldung erschienen)

  Revision 1.20  2001/04/20 16:59:26  MH
  BugFix (/mailto:)
  - wurde versucht per F2 den EmpfÑnger zu Ñndern, stÅrzte XP2 in den Abgrund

  Revision 1.19  2001/03/22 16:02:33  oh
  - Farbprofil-UnterstÅtzung

  Revision 1.18  2001/02/01 10:49:50  MH
  - Tests auf freien DiskSpace und FileHandles an den Start verschoben

  Revision 1.17  2000/11/02 23:52:26  rb
  Automatische Sommer-/Winterzeitumstellung bei korrekt gesetzter
  TZ-Umgebungsvariable

  Revision 1.16  2000/10/27 21:55:34  MH
  Konvertierung der BFGs verlagert

  Revision 1.15  2000/09/21 21:59:29  rb
  Codeteile ausgelagert

  Revision 1.14  2000/08/11 15:05:50  MH
  Parameter 'mailto:' startet CrossPoint in 'Nachrichten/Direkt'
  und Åbergibt den EmpfÑnger

  Revision 1.13  2000/07/09 17:16:50  MH
  Updateroutine erstellt nun beim ersten Start eine Sicherheitskopie
  von XPOINT.CFG und gibt zuvor eine Meldung aus

  Revision 1.12  2000/07/08 10:24:36  MH
  - Updateroutine erstellt

  Revision 1.11  2000/06/29 20:34:52  tj
  unter OS/2 Codepage automatisch auf 437 umschalten

  Revision 1.10  2000/06/08 20:05:47  MH
  Teamname geandert

  Revision 1.9  2000/06/04 14:32:45  tj
  SetKbd_BinMode Aufruf in XP.PAS ausgegliedert

  Revision 1.8  2000/05/25 23:20:49  tj
  Bugfixes im Bildschirmaufbau

  Revision 1.6  2000/05/09 16:56:10  tj
  OS/2 I/O Fehler 4 provisorisch behoben

  Revision 1.5  2000/04/10 22:13:07  rb
  Code aufgerÑumt

  Revision 1.4  2000/04/09 18:19:33  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.18  2000/04/04 21:01:22  mk
  - Bugfixes f¸r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.17  2000/04/04 10:33:56  mk
  - Compilierbar mit Virtual Pascal 2.0

  Revision 1.16  2000/04/03 00:27:33  oh
  - Startpasswort: drei Versuche statt nur einem.

  Revision 1.15  2000/03/25 20:22:20  mk
  - kleinere Anpassungen fuer Linux

  Revision 1.14  2000/03/14 15:15:37  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.13  2000/03/09 23:39:32  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.11  2000/03/07 17:45:11  jg
  - Viewer: Bei Dateien mit Leerzeichen im Namen wird
    grundsaetzlich ein .tmp File erzeugt
  - Env.Variable DELVTMP setzt jetzt nur noch beim Start
    die Globale Variable DELVIEWTMP

  Revision 1.10  2000/03/04 12:39:36  jg
  - weitere Aenderungen fuer externe Windowsviewer
    Umgebungsvariable DELVTMP

  Revision 1.9  2000/03/02 18:32:24  mk
  - Code ein wenig aufgeraeumt

}
