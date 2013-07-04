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
{                                                                 }
{ Globale Konstanten/Variablen (XP2) und Tools                    }
{                                                                 }
{ --------------------------------------------------------------- }
{ $Id: xpglobal.pas,v 1.43 2002/04/19 20:49:47 rb Exp $ }

unit xpglobal;

interface

{$I XPDEFINE.INC }

const
  verstr      = 'v3.31.007';      { Versionnr. - steht nur an dieser Stelle }
  betastr     = ' Beta';          { '' oder ' Beta' }
  teamstr     = ' (www.xp2.de)';  { Team-Logo (kurz) }
{$IFNDEF VER32}
  xp2str      = '[XP2] ';         { Team-Logo nur Mailerzeile }
{$ELSE}
  xp2str      = '';               { Rendundant }
{$ENDIF}

{$IFDEF VER32 }
  {$IFDEF Win32 }
  pformstr    = ' W32';       { 32 Bit Windows mit Virtual Pascal }
  {$ENDIF }
  {$IFDEF OS2 }
  pformstr    = ' OS/2';      { 32 Bit OS/2 mit Virtual Pascal }
  {$ENDIF}
  {$IFDEF Linux }
  pformstr    = ' Linux';     { 32 Bit Linux mit Virtual Pascal }
  {$ENDIF}
  {$IFDEF Dos32 }
  pformstr    = ' DOS/32';    { 32 Bit DOS mit TMT Pascal }
  {$ENDIF}

{$ELSE}
  {$IFDEF DPMI}
  pformstr    = ' DOS/XL';    { 16 Bit DPMI mit Borland Pascal }
  {$ELSE}
  pformstr    = ' DOS/16'; { 16 Bit Realmode mit Borland Pascal }
  {$ENDIF}
{$ENDIF }

  author_name = 'XP2 Team';
  {$IFnDEF EXTERN}
  author_mail = 'verteiler@xp2.de';
  {$ELSE}
  author_mail = '< None Support >';
  {$ENDIF}
  x_copyright = '(c) 2001';

type
  { Regeln fÅr Datentypen unter 16/32 Bit

  Die grî·e einiger Datentypen unterscheidet sich je nach verwendetem
  Compiler und der Systemumgebung. Folgende Regeln sollten beachtet werden:

  Der im Regelfall zu verwendede Datentyp ist Integer. Dieser Datentyp
  ist unter 16 Bit natÅrlich 16 Bit gro· und unter 32 Bit wiederum 32 Bit
  gro· und immer signed (vorzeichenbehaftet). Dieser Datentyp ist immer der
  _schnellste_ fÅr das System verfÅgbare Datentyp, sollte also in Schleifen
  usw. wenn mîglich genommen und den spezielleren Datentypen vorgezogen
  werden.

  Der Datentyp rtlword ist je nach dem verwendeten Compiler und der damit
  verwendeten RTL 16 oder 32 Bit gro·.

  Folgende Datentypen sind immer gleich gro· und z.B. fÅr Records geeignet:
  Byte       1 Byte  unsigned  0..255
  SmallWord  2 Byte  unsigned  0..65535
  DWord      4 Byte  unsigned  0..4294967295
  (Vorsicht bei BP und VP, dort gibt es kein echtes DWord)

  Integer8   1 Byte  signed   -128..127
  Integer16  2 Byte  signed   -32768..32767
  Integer32  4 Byte  signed   -2147493647..2147493647

  }

  {$IFDEF VER32 }
    {$ifdef virtualpascal}
      { Virtual Pascal, 32 Bit }
      integer8 =   shortint;
      integer16 =  smallint;
      integer32 =  longint;
      integer =    longint;
      word =       longint; { = signed }
      dword =      longint; { = signed }
      rtlword =    longint;     { 32 Bit bei VP }
    {$ENDIF }
    {$IFDEF FPC }
      { FreePascal, 32 Bit }
      integer8 =   shortint;
      integer16 =  integer;
      integer32 =  longint;
      { Unter FPC ist ein Integer standardmÑ·ig 16 Bit gro· }
      integer =    longint;
      word =       longint;  { = signed }
      smallword =  system.word;
      dword =      Cardinal; { = signed }
      rtlword =    system.word; { 16 Bit bei FPC }
    {$endif}
  {$ELSE}
    { Borland Pascal bis Version 8, 16 Bit }
    integer8 =   shortint;
    integer16 =  integer;
    integer32 =  longint;
    smallint =   integer;
    smallword =  word;
    dword =      longint; { Vorsicht: siehe oben! }
    rtlword =    system.word; { 16 Bit bei FPC }
  {$ENDIF}

const
  {$ifdef ver32}
  wordsize = 32;
  {$else}
  wordsize = 16;
  {$endif}

implementation

begin
  {$IFDEF Debug }
    {$IFDEF FPC }
       Writeln('Compiled at ',{$I %TIME%}, ' on ', {$I %DATE%},
        ' with Compiler ', {$I %FPCVERSION%}, ' for ', {$I %FPCTARGET%});
    {$ENDIF }
  {$ENDIF }
end.
{
  $Log: xpglobal.pas,v $
  Revision 1.43  2002/04/19 20:49:47  rb
  Version erhîht fÅr interne Beta

  Revision 1.42  2002/04/19 19:35:08  rb
  Version erhîht fÅr îffentliche Beta

  Revision 1.41  2001/12/27 14:30:59  MH
  - Zur besseren Unterscheidung Version erhîht

  Revision 1.40  2001/12/27 14:00:46  MH
  - Zur besseren Unterscheidung Version erhîht

  Revision 1.39  2001/12/23 17:28:11  MH
  - Versionserhoehung fuer internen Betrieb nach Ausgabe der Weihnachtsversion

  Revision 1.38  2001/07/14 17:08:49  MH
  - None Support Area fÅr externe Ausgabe!

  Revision 1.37  2001/06/18 20:17:42  oh
  Teames -> Teams

  Revision 1.36  2001/04/24 05:35:55  MH
  - Versionsstring geaendert: 2000 <-> 2001

  Revision 1.35  2001/03/19 13:49:14  MH
  - neue Betaserie festgelegt

  Revision 1.34  2001/02/21 22:13:11  MH
  -.-

  Revision 1.33  2000/11/17 17:28:08  MH
  Entwickler Version gesetzt: 019

  Revision 1.32  2000/11/13 19:24:35  oh
  -Version set to .18

  Revision 1.31  2000/11/02 01:11:40  rb
  Kommentarbaumlimits erhîht

  Revision 1.30  2000/11/01 18:20:40  MH
  XP2STR in Versionen <> DOS rendundant

  Revision 1.29  2000/10/28 07:55:23  MH
  Mailerzeile incl. Support-Url

  Revision 1.28  2000/10/26 20:22:52  MH
  EndgÅltige Fassung des Mailer- und Tearlinestrings

  Revision 1.27  2000/10/26 14:49:33  MH
  Mailerzeile angepasst

  Revision 1.26  2000/10/14 17:24:56  MH
  v3.30.017: Interne Entwicklerversion...

  Revision 1.25  2000/10/14 10:24:54  MH
  Neue Beta (îffentlich)

  Revision 1.24  2000/10/03 16:24:33  MH
  Versionskennung fÅr die Entwickler erhîht

  Revision 1.23  2000/10/03 10:32:16  MH
  Versionskennung erhîht

  Revision 1.22  2000/10/02 21:18:01  MH
  Versionsnummer erhîht fÅr îffentliche Beta

  Revision 1.21  2000/09/26 18:16:03  oh
  beta 12

  Revision 1.20  2000/08/29 16:45:35  MH
  Versionsnummer erhîht

  Revision 1.19  2000/08/24 15:23:49  MH
  Versionsnummer erhîht...

  Revision 1.18  2000/08/13 11:19:05  MH
  Versionsnummer erhîht

  Revision 1.17  2000/08/08 18:03:11  MH
  Versionsnummer erhîht

  Revision 1.16  2000/07/31 15:33:55  MH
  Version 007 f. internen Betatest

  Revision 1.15  2000/07/24 13:20:16  MH
  Versionsnummer erhîht

  Revision 1.14  2000/07/15 14:38:48  MH
  Versionnummer erhîht

  Revision 1.13  2000/07/06 16:35:56  MH
  - Mailerstring angepasst

  Revision 1.12  2000/07/05 23:11:56  MH
  Mailerzeile:
  - mit (XP2) gekennzeichnet: neue Variable (teamstr) beachten

  Revision 1.11  2000/07/05 21:44:51  MH
  Mailerzeile:
  - auf 66 Zeichen (in/out) verlÑngert
  - mit (XP2) gekennzeichnet

  Revision 1.10  2000/07/02 13:01:46  tg
  Versionsnummer erhoeht

  Revision 1.9  2000/06/24 16:47:23  tg
  Beta Version/String geaendert

  Revision 1.8  2000/06/08 20:06:49  MH
  Teamname geandert

  Revision 1.7  2000/06/02 09:07:47  MH
  Versionsnr. erhoeht

  Revision 1.6  2000/04/12 14:04:52  tj
  Lizenzhinweis auf XP2 angepasst

  Revision 1.5  2000/04/10 22:13:15  rb
  Code aufgerÑumt

  Revision 1.4  2000/04/09 18:31:08  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.20  2000/04/04 21:01:24  mk
  - Bugfixes f¸r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.19  2000/03/24 20:25:50  rb
  ASM-Routinen gesÑubert, Register fÅr VP + FPC angegeben, Portierung FPC <-> VP

  Revision 1.18  2000/03/24 15:41:02  mk
  - FPC Spezifische Liste der benutzten ASM-Register eingeklammert

  Revision 1.17  2000/03/24 08:35:30  mk
  - Compilerfaehigkeit unter FPC wieder hergestellt

  Revision 1.16  2000/03/24 00:03:39  rb
  erste Anpassungen fÅr die portierung mit VP

  Revision 1.15  2000/03/22 18:18:44  mk
  - Versionsinfo auf 3.21.23 geaendert

  Revision 1.14  2000/03/17 11:16:35  mk
  - Benutzte Register in 32 Bit ASM-Routinen angegeben, Bugfixes

  Revision 1.13  2000/03/16 10:14:25  mk
  - Ver32: Tickerabfrage optimiert
  - Ver32: Buffergroessen f¸r Ein-/Ausgabe vergroessert
  - Ver32: Keypressed-Routine laeuft nach der letzen ƒnderung wieder

  Revision 1.12  2000/03/14 18:16:15  mk
  - 16 Bit Integer unter FPC auf 32 Bit Integer umgestellt

  Revision 1.11  2000/03/09 23:39:34  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.10  2000/03/08 22:36:33  mk
  - Bugfixes f¸r die 32 Bit-Version und neue ASM-Routinen

  Revision 1.9  2000/03/06 08:51:04  mk
  - OpenXP/32 ist jetzt Realitaet

  Revision 1.8  2000/03/04 11:53:20  mk
  Version auf 3.21.022 beta geaendert und Debug eingeschaltet

  Revision 1.7  2000/03/02 18:32:24  mk
  - Code ein wenig aufgeraeumt

}
