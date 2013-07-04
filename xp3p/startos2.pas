{ $Id: startos2.pas,v 1.2 2002/01/02 23:16:48 MH Exp $ }

{$B-,D+,H-,I+,J+,P-,Q+,R+,S+,T-,V-,W-,X+,Z-}
{&AlignCode+,AlignData+,AlignRec-,Asm-,Cdecl-,Comments-,Delphi+,Frame+,G3+}
{&G5-,LocInfo+,Open32-,Optimise-,OrgName-,SmartLink-,Speed+,Use32-,ZD+}
{$M 32768}

Unit StartOS2;

Interface

Type TStartData = record
                    Length:        Word; { Must be 0x18,0x1E,0x20,0x32, or 0x3C }
                    Related:       Word; { 00 independent, 01 child }
                    FgBg:          Word; { 00 foreground, 01 background }
                    TraceOpt:      Word; { 00-02, 00 = no trace }
                    PgmTitle:      PChar; { max 62 chars or 0000:0000 }
                    PgmName:       PChar; { max 128 chars or 0000:0000 }
                    PgmInputs:     PChar; { max 144 chars or 0000:0000 }
                    TermQ:         PChar; { reserved, must be 00000000 }
                    Environment:   PChar; { max 486 bytes or 0000:0000 }
                    InheritOpt:    Word;  { 00 or 01 }
                    SessionType:   Word;  { 00 OS/2 session manager determines type (default)
                                            01 OS/2 full-screen
                                            02 OS/2 window
                                            03 PM
                                            04 VDM full-screen
                                            07 VDM window }
                    IconFile:      PChar; { max 128 chars or 0000:0000 }
                    PgmHandle:     LongInt; { reserved, must be 00000000 }
                    PgmControl:    Word;
                    InitXPos:      Word;
                    InitYPos:      Word;
                    InitXSize:     Word;
                    InitYSize:     Word;
                    Reserved:      Word; { 0x00 }
                    ObjectBuffer:  PChar; { reserved, must be 00000000 }
                    ObjectBuffLen: LongInt; { reserved, must be 00000000 }
  End;

Procedure Start(Programm,Parameter,Title:String);
Procedure WaitForEnd(_Semaphore:String);

Implementation

Uses Dos,Strings;

Var Shell:String;

Function Dos32CreateEventSem(Name:PChar; Var Handle:LongInt; Attr:Word;
                              State:Byte):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0144
        mov     cx, $636C
        push    ds
        mov     dx, Attr
        mov     al, State
        les     di, Name
        lds     si, Handle
        int     $21
        pop     ds
 End;

Function Dos32ResetEventSem(Handle:LongInt; Var Count:Word):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0147
        mov     cx, $636C
        les     si, Handle
        push    es
        pop     dx
        les     di, Count
        int     $21
 End;

Function Dos32PostEventSem(Handle:LongInt):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0148
        mov     cx, $636C
        les     si, Handle
        push    es
        pop     dx
        int     $21
 End;

Function Dos32WaitEventSem(Handle:LongInt; Seconds:ShortInt):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0149
        mov     cx, $636C
        les     si, Handle
        push    es
        pop     dx
        mov     al, Seconds
        int     $21
 End;

Function Dos32QueryEventSem(Handle:LongInt; Var Count:Word):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $014A
        mov     cx, $636C
        les     si, Handle
        push    es
        pop     dx
        les     di, Count
        int     $21
 End;

Function Dos32OpenEventSem(Name:PChar; Var Handle:LongInt):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0145
        mov     cx, $636C
        push    ds
        les     di, Name
        lds     si, Handle
        int     $21
        pop     ds
 End;

Function Dos32CloseEventSem(Handle:LongInt):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0146
        mov     cx, $636C
        les     si, Handle
        push    es
        pop     dx
        int     $21
 End;

Function DosStartSession(Var Data:TStartData):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0025
        mov     cx, $636C
        push    ds
        lds     si, Data
        int     $21
        pop     ds
 End;

Procedure Start(Programm,Parameter,Title:String);
Var StartData:TStartData;
    Temp:String;
    PrgName,PrgParam,PrgTitle:PChar;
 Begin
 GetMem(PrgName,256);
 GetMem(PrgParam,256);
 GetMem(PrgTitle,256);
 StrPCopy(PrgName,Shell);
 Temp:='/C'+' '+Programm+' '+Parameter;
 StrPCopy(PrgParam,Temp);
 StrPCopy(PrgTitle,Title);
 With StartData Do
  Begin
  Length:=SizeOf(TStartData);
  Related:=1;
  FgBg:=0;
  TraceOpt:=0;
  PgmTitle:=PrgTitle;
  PgmName:=PrgName;
  PgmInputs:=PrgParam;
  TermQ:=Nil;
  Environment:=Nil;
  InheritOpt:=0;
  SessionType:=2;
  IconFile:=Nil;
  PgmHandle:=0;
  PgmControl:=0;
  InitXPos:=0;
  InitYPos:=0;
  InitXSize:=0;
  InitYSize:=0;
  Reserved:=0;
  ObjectBuffer:=Nil;
  ObjectBuffLen:=0;
  End;

 DosStartSession(StartData);
 FreeMem(PrgTitle,256);
 FreeMem(PrgParam,256);
 FreeMem(PrgName,256);
 End;

Procedure WaitForEnd(_Semaphore:String);
Var SemHandle:LongInt;
    Semaphore:PChar;
    r,s:Word;
 Begin
 GetMem(Semaphore,64);
 StrPCopy(Semaphore,_Semaphore);
 SemHandle:=0;
 r:=Dos32CreateEventSem(Semaphore,SemHandle,0,0);
 If r<>0 Then Dos32OpenEventSem(Semaphore,SemHandle);
 r:=Dos32ResetEventSem(SemHandle,s);
 r:=Dos32WaitEventSem(SemHandle,-1);
 r:=Dos32CloseEventSem(SemHandle);
 FreeMem(Semaphore,64);
 End;


Begin
  Shell:='CMD.EXE';
End.


{
  $Log: startos2.pas,v $
  Revision 1.2  2002/01/02 23:16:48  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.1  2001/07/11 19:47:18  rb
  checkin


}
