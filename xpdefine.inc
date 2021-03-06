{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 2000 XP� Team, weitere Informationen unter:                 }
{                   http://www.xp2.de                             }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Compilerdirektiven f�r CrossPoint (XP�)                         }
{ --------------------------------------------------------------- }
{ $Id: xpdefine.inc,v 1.13 2002/01/05 14:23:17 mm Exp $ }

{ Wenn gesetzt, werden erweiterte Checks in der EXE-Datei durchgef�hrt
  (Rangecheck) usw. }

{.$DEFINE Debug }

{ Wenn gesetzt, werden in die TPU/TPP Debug Informationen gespeichert
  und es kann eine ausf�hrliche Map-Datei erstellt werden. �ndert den
  Code der EXE-Datei nicht }

{$DEFINE DebugInfo }

{ Folgende beiden Schalter dienen zur Simulation und debuggens von UUCICO }

{.$DEFINE UUDEBUG }  { Empfangs-Logfile UU-DEBUG.                }
{.$DEFINE SIM }      { Simulierter Netcall; Eingabedatei: UUSIM. }

{ Keine Assembler-Routine verwenden. Ein Gegenpart in Pascal mu�
  existieren }
{.$DEFINE NOASM }

{ Ist definiert, wenn Beta-Informationen anzeigt werden sollen }
{$DEFINE Beta }

{ Ist zu aktivieren, wenn au�erhalb des XP2-Teams ver�ffentlicht wird }
{.$DEFINE EXTERN }

{ Wenn dieser Schalter nicht gesetzt ist, ben�tigt XP einen 386er,
  ansonsten ... }
{.$DEFINE NO386 }

{ ... tritt folgender Schalter in Kraft: ist er nicht gesetzt, ben�tigt XP
  einen 286er, ansonsten einen 8088.

  ACHTUNG!!!
  ==========
  Wenn man eine 8088er Version kompilieren will, m�ssen beide Schalter,
  also NO386 und NO286 gesetzt sein! }
{.$DEFINE NO286 }

{ Wenn dieser Schalter definiert ist, wird eine Version mit CAPI-
  Unterst�zung compiliert }
{.$DEFINE CAPI }


{ Wenn dieser Schalter definiert ist, wird der Indexcache eingeschaltet }

{.$DEFINE USEINDEXCACHE }


{ --- ab hier sind keine �nderungen n�tig --- }

{$IFDEF VER70 }
  {$DEFINE BP }   { 16 Bit Borland Pascal 7 oder 8 (Delphi 1) }
  {$IFDEF DPMI }
    {$DEFINE DPMI16 }
  {$ENDIF }
{$ENDIF }

{$IFDEF VER80 }
  {$DEFINE BP }   { 16 Bit Borland Pascal 7 oder 8 (Delphi 1) }
  {$IFDEF DPMI }
    {$DEFINE DPMI16 }
  {$ENDIF }
{$ENDIF }

{$IFDEF BP } { Nur f�r Borland Pascal 7 und 8 }
  {$A+,B-,D-,E-,F-,I-,G+,L-,N-,O-,P-,Q-,R-,S-,T-,V-,X+,Y-}
  {$IFDEF NO386 }
    {$G+} { 286er Befehle }
    {$IFDEF NO286 }
      {$G-} { keine 286er Befehle }
    {$ENDIF }
  {$ENDIF }
{$ENDIF }

{$IFDEF VER130 }      { Delphi 5 }
  {$DEFINE Ver32 }
  {$DEFINE Win32 }
  {$DEFINE Delphi }
  {$A+,B-,C-,D+,E-,F-,G+,H-,I-,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U+,V-,W-,X+,Y-,Z1}
{$ENDIF }

{$IFDEF __CON__ } { Nur f�r TMT Pascal >= 3.30 }
  {$DEFINE VER32 }
  {$DEFINE TMT }
  {$DEFINE DOS32 }
  {$A+,B-,D-,F-,I-,L-,O-,P-,Q-,R-,S-,T-,V-,X+}
{$ENDIF }

{$IFDEF VirtualPascal }  { Virtual Pascal ab 2.0 }
  {$DEFINE VP }
  {$DEFINE Ver32 }
  {$B-,H-,I-,J+,P+,Q-,R-,T-,V-,W-,X+,Z-}
  {&AlignCode+,AlignData+,AlignRec-,Asm-,Cdecl-,Delphi-,Frame+,G3+,LocInfo-}
  {&Open32-,Optimise+,OrgName-,SmartLink+,Speed+,ZD-}
{$ENDIF }

{$IFDEF FPC }             { Freepascal >= 0.99.14 }
  {$DEFINE Ver32 }
  {$IFDEF GO32V2 }
    {$DEFINE DOS32 }
  {$ENDIF }
  {$C-,H-,I-,M-,P-,T-,V-,X+}
  {$MODE TP }
  {$ASMMODE Intel }
  {$GOTO ON }
{$ENDIF }

{$IFDEF DebugInfo }
  {$IFDEF BP } { Nur f�r Borland Pascal 7 }
    {$D+,L+,Y+}
  {$ENDIF }
  {$IFDEF VirtualPascal }
    {$D+,LocInfo+}
  {$ENDIF }
{$ENDIF }

{$IFDEF Debug }
  {$IFDEF BP } { Nur f�r Borland Pascal 7 }
    {$R+,S+,Q+}
  {$ENDIF }
  {$IFDEF VirtualPascal }
    {$R+,S+,Q+,W+,Optimize-}
  {$ENDIF }
{$ENDIF }

{$IFDEF Ver32 }
  {$IFDEF CAPI } { Umgeht h�ssliche Warnings in TMT Pascal }
    {$UNDEF CAPI } { Bis jetzt keine CAPI-Unterst�tzung in 32 Bit Versionen }
  {$ENDIF CAPI }
{$ENDIF }

{
  $Log: xpdefine.inc,v $
  Revision 1.13  2002/01/05 14:23:17  mm
  - IndexCache nicht mehr standardmaessig aktiviert, da eventuelle Probs noch
    unklar sind

  Revision 1.12  2002/01/05 09:16:27  mm
  - IndexCache in v3.31 standardmaessig aktiviert

  Revision 1.11  2001/12/23 12:24:20  mm
  - Debug erst mal deaktiviert, da sonst momentan nicht compilierbar

  Revision 1.10  2001/06/23 10:37:59  MH
  - Betascreen f�r externe Kompilate angepasst

  Revision 1.9  2001/02/09 22:14:26  rb
  define f�r Indexcache

  Revision 1.8  2001/01/04 17:09:09  MH
  - UUCICO-Schalter hierher verlagert

  Revision 1.7  2000/09/13 21:25:33  rb
  Schalter f�r 8088/286/386er Version

  Revision 1.6  2000/06/08 20:06:33  MH
  Teamname geandert

  Revision 1.5  2000/04/10 22:13:14  rb
  Code aufger�umt

  Revision 1.4  2000/04/09 18:29:36  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.15  2000/04/04 21:01:24  mk
  - Bugfixes f�r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.14  2000/03/24 08:35:30  mk
  - Compilerfaehigkeit unter FPC wieder hergestellt

  Revision 1.13  2000/03/24 00:03:39  rb
  erste Anpassungen f�r die portierung mit VP

  Revision 1.12  2000/03/07 00:48:22  mk
  in FPC Goto On und Beta-Warnung eingeschaltet

  Revision 1.11  2000/03/04 11:53:20  mk
  Version auf 3.21.022 beta geaendert und Debug eingeschaltet

  Revision 1.10  2000/03/02 18:32:24  mk
  - Code ein wenig aufgeraeumt

  Revision 1.9  2000/02/28 08:57:05  mk
  - Version auf 3.20 RC1 geandert

  Revision 1.8  2000/02/27 09:05:39  mk
  Ab Beta 3.20.21 ohne Debug-Infos

  Revision 1.7  2000/02/20 11:06:33  mk
  Loginfos hinzugeueft, Todo-Liste geaendert

  Revision 1.6  2000/02/19 11:40:09  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.5  2000/02/17 16:14:19  mk
  MK: * ein paar Loginfos hinzugefuegt

}
