{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams.  }
{ Aenderungen des Sources, die vom OpenXP Team getaetigt wurden,  }
{ unterliegen den Rechten, die bis zum 09.04.2000 fuer das OpenXP }
{ Team gueltig waren.                                             }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: ems.pas,v 1.6 2001/12/30 11:50:56 mm Exp $ }

(***********************************************************)
(*                                                         *)
(*                        UNIT EMS                         *)
(*                                                         *)
(*                 LIM/EMS - Schnittstelle                 *)
(*                                                         *)
(***********************************************************)

UNIT EMS;

{$I XPDEFINE.INC}

{$IFNDEF BP }
  !! Diese Routine kann nur unter Borland Pascal compiliert werden�
{$ENDIF }


{  ==================  Interface-Teil  ===================  }

INTERFACE

uses dos;

const emsintnr = $67;

var   emsbase  : word;                              { SegAdr des Page-Frame }

function  EmsTest:boolean;                          { EMS vorhanden ?       }
function  EmsTotal:word;                            { EMS-Speicher gesamt   }
function  EmsAvail:word;                            { EMS-Speicher in Pages }
function  EmsHandlePages(handle:word):word;         { belegte Seiten holen  }
function  EmsVersion:byte;                          { EMS-Versionsnummer    }

procedure EmsAlloc(pages:word; var handle:word);    { EMS allokieren        }
procedure EmsPage(handle:word; phy:byte; log:word); { Seite einblenden      }
procedure EmsFree(handle:word);                     { EMS freigeben         }
procedure EmsSaveMap(handle:word);                  { Mapping sichern       }
procedure EmsRestoreMap(handle:word);               { Mapping wiederherst.  }


{ ================= Implementation-Teil ==================  }

IMPLEMENTATION



var emsok : boolean;      { EMS installiert }
    pages : word;         { Gesamtspeicher  }

function EmsTest:boolean;
begin
  emstest:=emsok;
end;

procedure emsint(var regs:registers);
begin
  if emsok then intr(emsintnr,regs);
end;


procedure emsinit;
const emsid  : array[0..7] of char = 'EMMXXXX0';
type  pntrec = record
                 o,s : word
               end;
var   p      : ^string;
      i      : byte;
      regs   : registers;
begin
  getintvec(emsintnr,pointer(p));
  p:=ptr(pntrec(p).s,10);
  emsok:=true;
  for i:=0 to 7 do
    if p^[i]<>emsid[i] then emsok:=false;
  if emsok then
    with regs do begin
      ah:=$41; emsint(regs);
      if ah<>0 then
        emsok:=false      { kein Page Frame vorhanden }
      else begin
        emsbase:=bx;
        ah:=$42; emsint(regs); pages:=dx;
        end;
      end
  else
    pages:=0;
end;


function EmsTotal:word;
begin
  emstotal:=pages;
end;


function EmsAvail:word;
var regs : registers;
begin
  if emsok then begin
    regs.ah:=$42;
    emsint(regs);
    emsavail:=regs.bx;
    end
  else
    emsavail:=0;
end;


{ belegte Seiten f�r ein Handle abfragen }

function EmsHandlePages(handle:word):word;
var regs : registers;
begin
  with regs do begin
    ah:=$4c;
    dx:=handle;
    emsint(regs);
    EmsHandlePages:=bx;
    end;
end;


function EmsVersion:byte;
var regs : registers;
begin
  regs.ah:=$46;
  emsint(regs);
  emsversion:=regs.al;
end;


procedure EmsAlloc(pages:word; var handle:word);
var regs : registers;
begin
  with regs do begin
    ah:=$43;
    bx:=pages;
    emsint(regs);
    handle:=dx;
    end;
end;


procedure EmsPage(handle:word; phy:byte; log:word);
var regs : registers;
begin
  with regs do begin
    ah:=$44;
    al:=phy;
    bx:=log;
    dx:=handle;
    emsint(regs);
    end;
end;


procedure EmsFree(handle:word);
var regs : registers;
begin
  regs.ah:=$45;
  regs.dx:=handle;
  emsint(regs);
end;


procedure EmsSaveMap(handle:word);
var regs : registers;
begin
  regs.ah:=$47;
  regs.dx:=handle;
  emsint(regs);
end;


procedure EmsRestoreMap(handle:word);
var regs : registers;
begin
  regs.ah:=$48;
  regs.dx:=handle;
  emsint(regs);
end;

begin
  emsinit;
end.
{
  $Log: ems.pas,v $
  Revision 1.6  2001/12/30 11:50:56  mm
  - Sourceheader

  Revision 1.5  2000/06/08 20:04:09  MH
  Teamname geandert

  Revision 1.4  2000/04/09 18:07:07  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.5  2000/02/17 16:14:19  mk
  MK: * ein paar Loginfos hinzugefuegt

}
