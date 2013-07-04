{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 2000 XP˝ Team, weitere Informationen unter:                 }
{                   http://www.xp2.de                             }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Compilerdirektiven fÅr CrossPoint (XP˝)                         }
{ --------------------------------------------------------------- }
{ $Id: xpdefine.inc,v 1.2 2001/08/04 12:54:24 mm Exp $ }

{ Wenn gesetzt, werden erweiterte Checks in der EXE-Datei durchgefÅhrt
  (Rangecheck) usw. }

{.$DEFINE Debug }

{ Wenn gesetzt, werden in die TPU/TPP Debug Informationen gespeichert
  und es kann eine ausfÅhrliche Map-Datei erstellt werden. éndert den
  Code der EXE-Datei nicht }

{$DEFINE DebugInfo }

{ Folgende beiden Schalter dienen zur Simulation und debuggens von UUCICO }

{.$DEFINE UUDEBUG }  { Empfangs-Logfile UU-DEBUG.                }
{.$DEFINE SIM }      { Simulierter Netcall; Eingabedatei: UUSIM. }

{ Keine Assembler-Routine verwenden. Ein Gegenpart in Pascal mu·
  existieren }
{.$DEFINE NOASM }

{ Ist definiert, wenn Beta-Informationen anzeigt werden sollen }
{$DEFINE Beta }

{ Ist zu aktivieren, wenn au·erhalb des XP2-Teams verîffentlicht wird }
{.$DEFINE EXTERN }

{ Wenn dieser Schalter nicht gesetzt ist, benîtigt XP einen 386er,
  ansonsten ... }
{.$DEFINE NO386 }

{ ... tritt folgender Schalter in Kraft: ist er nicht gesetzt, benîtigt XP
  einen 286er, ansonsten einen 8088.

  ACHTUNG!!!
  ==========
  Wenn man eine 8088er Version kompilieren will, mÅssen beide Schalter,
  also NO386 und NO286 gesetzt sein! }
{.$DEFINE NO286 }

{ Wenn dieser Schalter definiert ist, wird eine Version mit CAPI-
  UnterstÅzung compiliert }
{.$DEFINE CAPI }


{ Wenn dieser Schalter definiert ist, wird der Indexcache eingeschaltet }

{.$define useindexcache}


{ --- ab hier sind keine énderungen nîtig --- }

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

{$IFDEF BP } { Nur fÅr Borland Pascal 7 und 8 }
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

{$IFDEF __CON__ } { Nur fÅr TMT Pascal >= 3.30 }
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
  {$IFDEF BP } { Nur fÅr Borland Pascal 7 }
    {$D+,L+,Y+}
  {$ENDIF }
  {$IFDEF VirtualPascal }
    {$D+,LocInfo+}
  {$ENDIF }
{$ENDIF }

{$IFDEF Debug }
  {$IFDEF BP } { Nur fÅr Borland Pascal 7 }
    {$R+,S+,Q+}
  {$ENDIF }
  {$IFDEF VirtualPascal }
    {$R+,S+,Q+,W+,Optimize-}
  {$ENDIF }
{$ENDIF }

{$IFDEF Ver32 }
  {$IFDEF CAPI } { Umgeht hÑssliche Warnings in TMT Pascal }
    {$UNDEF CAPI } { Bis jetzt keine CAPI-UnterstÅtzung in 32 Bit Versionen }
  {$ENDIF CAPI }
{$ENDIF }

{
  $Log: xpdefine.inc,v $
  Revision 1.2  2001/08/04 12:54:24  mm
  -.-

  Revision 1.1  2001/08/04 12:49:36  mm
  - xpdefine.inc hinzugefuegt

}
