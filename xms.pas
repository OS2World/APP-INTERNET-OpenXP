{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ (c) 2000 XP� Team, weitere Informationen unter:                 }
{                   http://www.xp2.de                             }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xms.pas,v 1.3 2000/06/08 20:05:40 MH Exp $ }

(***********************************************************)
(*                                                         *)
(*                        UNIT XMS                         *)
(*                                                         *)
(*                 LIM/XMS - Schnittstelle                 *)
(*                                                         *)
(***********************************************************)


UNIT XMS;

{$I XPDEFINE.INC }

{$IFNDEF BP }
  !! Diese Routine kann nur unter Borland Pascal compiliert werden�
{$ENDIF }

{$I XPDEFINE.INC }
{$F+}

{  ==================  Interface-Teil  ===================  }

INTERFACE

uses  xpglobal, dos;

function  XmsTest:boolean;                          { XMS vorhanden ?       }
function  XmsVersion:word;
function  XmsTotal:word;                            { XMS-Speicher in KB    }
function  XmsAvail:word;                            { freier Speicher in KB }
function  XmsResult:byte;                           { 0 = ok                }

function  XmsAlloc(KB:word):word;                   { liefert Handle        }
procedure XmsRealloc(handle:word; KB:word);         { Blockgr��e �ndern     }
procedure XmsFree(handle:word);                     { Speicher freigeben    }
procedure XmsRead(handle:word; var data; offset,size:longint);
procedure XmsWrite(handle:word; var data; offset,size:longint);

{ Achtung: size wird immer auf eine gerade Zahl aufgerundet! }


{ ================= Implementation-Teil ==================  }

IMPLEMENTATION


var xmsok   : boolean;      { XMS installiert }
    xmscall : pointer;
    result  : byte;


procedure xmsinit;
var regs : registers;
begin
  with regs do begin
    ax:=$4300;
    intr($2f,regs);
    xmsok:=(al=$80);
    if xmsok then begin
      ax:=$4310;
      intr($2f,regs);
      xmscall:=ptr(es,bx);
      end;
    end;
end;


function XmsTest:boolean;                          { XMS vorhanden ?       }
begin
  XmsTest:=xmsok;
end;


function XmsResult:byte;
begin
  XmsResult:=result;
end;

{ Result-Codes:

  00h   ok
  80h   Funktion ist nicht implementiert
  81h   VDISK-Ger�t entdeckt. Aus Sicherheitsgr�nden wird die Funktion
        nicht ausgef�hrt.
  8Eh   genereller Treiberfehler
  8Fh   nicht behebbarer Treiberfehler
  A0h   kein XMS mehr frei
  A1h   keine Handles mehr frei
  A2h   ung�ltiges Handle
  A3h   ung�ltiges Quellhandle
  A4h   ung�ltiges Quelloffest
  A5h   ung�ltiges Zielhandle
  A6h   ung�ltiges Zieloffset
  A7h   ung�ltige Blockl�nge
  A8h   Quelle und Ziel �berlappen sich
  A9h   Parity-Fehler  }



{$L xms.obj}
function XmsVersion:word; external;
function XmsTotal:word; external;
function XmsAvail:word; external;
function  XmsAlloc(KB:word):word; external;
procedure XmsRealloc(handle:word; KB:word);  external;
procedure XmsFree(handle:word); external;
procedure XmsRead(handle:word; var data; offset,size:longint); external;
procedure XmsWrite(handle:word; var data; offset,size:longint);  external;


begin
  xmsinit;
  result:=0;
end.

{
  $Log: xms.pas,v $
  Revision 1.3  2000/06/08 20:05:40  MH
  Teamname geandert

  Revision 1.2  2000/05/25 23:12:50  rb
  Loginfos hinzugef�gt

}
