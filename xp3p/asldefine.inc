{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.3 $    $Date: 2002/01/04 19:04:09 $    $Author: MH $ }
{                                                                             }
{ Defines and compiler switches used by asl                                   }

{ $Id: asldefine.inc,v 1.3 2002/01/04 19:04:09 MH Exp $ }

{.$B-,D+,H+,I+,J+,P-,Q+,R+,S+,T-,V-,W-,X+,Z-}
{.&AlignCode+,AlignData+,AlignRec-,Asm-,Delphi+,Frame+,G3+,LocInfo+,Open32-}
{.&Optimize-,Smartlink-}
{.&OrgName-,Use32+,ZD+}
{.$M 32768}


{ VP 2.1b 243: Bitte AnsiStrings im Source definieren, nicht hier! }

{$B-,D+,H-,I+,J+,P-,Q+,R+,S+,T-,V-,W-,X+,Z-}
{&AlignCode+,AlignData+,AlignRec-,Asm-,Cdecl-,Comments-,Delphi+,Frame+,G3+}
{&G5-,LocInfo+,Open32-,Optimise-,OrgName-,SmartLink-,Speed+,Use32+,ZD+}
{$M 32768}

{$DEFINE VIRTUALPASCAL}
{$DEFINE USE32}
{$DEFINE VER32
{$DEFINE VP}

{$IFDEF OS2}
  {$DEFINE XPTEST}
{$ENDIF}


{
  $Log: asldefine.inc,v $
  Revision 1.3  2002/01/04 19:04:09  MH
  - OpenXP-Unterstuetzung fuer W32-Version
  - Schalter hinzugefuegt: NntpFallback und SmtpAuth

  Revision 1.2  2002/01/02 23:16:47  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.1  2001/07/11 19:47:16  rb
  checkin


}
