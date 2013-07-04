{ $Id: pho.pas,v 1.2 2002/01/02 23:19:54 MH Exp $ }

{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 2000,2001 XP2 Team                                          }
{ --------------------------------------------------------------- }


{
Beschreibung     : PHO.PAS ist eine Filtereigenschaft von XP3P, welches
                   von unliebsame Zeitgenossen nur den Nachrichtenkopf
                   vom NNTP Server holt. (person header only)
Autor            : T.W.Jaehnigen (tj@xp2.de)
Datum            : 06.08.2001
letzte Aenderung : siehe cvs id
letzter Autor    : siehe Changelog im Anhang dieses Sources
Bemerkung        : siehe Changelog im Anhang dieses Sources
}

{.$DEFINE DBG} { mAx }

{$i asldefine.inc}

unit pho;

interface
        procedure twj_create_list;
        function  twj_check_filter(vergleich : string) : boolean;
        procedure twj_del_list;
        function  twj_oeffne_datei(rlspfad : string) : boolean;
        function  twj_negation : boolean;
        function  twj_unixtime : longint;
implementation

uses dos, sysutils, {typeform}xp3pmisc, unixtime;

type
        twj_zeiger = ^twj_32fxp2;
        twj_32fxp2 = record
                       fuser     : string;
                       naechster : twj_zeiger;
                     end;

var
        twj_p, wurzel   : twj_zeiger;
        twj_kette       : string;
        twj_dummy       : string;
        fuser_da        : boolean;
        {$IFDEF DBG}
        dbg,
        {$ENDIF}
        filterdatei     : text;
        y,m,d,dw,h,mi,
        s,s100          : integer;

const
        twj_list_exist  : boolean = false;

{$IFDEF DBG}
procedure opendbg;
begin
  assign(dbg,'dbg.log');
  {$I-}
  reset(dbg);
  {$I+}
  if ioresult<>0 then begin
    rewrite(dbg);
    writeln(dbg,'-.-.-.-');
    flush(dbg);
  end;
  close(dbg);
  append(dbg);
end;

procedure closedbg;
begin
  flush(dbg);
  close(dbg);
end;

procedure wrdbg(s: string);
begin
  writeln(dbg, s)
end;
{$ENDIF}

function twj_oeffne_datei(rlspfad : string) : boolean;

begin
  assign(filterdatei,rlspfad{+'filter.rls'});
  {$I-}
  reset(filterdatei);
  {$I+}
  twj_oeffne_datei:=(IORESULT = 0);
end; {oeffne_datei}


{hier wird die Liste im Speicher erstellt}

procedure twj_create_list;

begin
  twj_list_exist:=(memavail >= 15000);
  if not twj_list_exist then begin
    close(filterdatei);
    exit;
  end;
  {$IFDEF DBG}
  opendbg;
  wrdbg('FilterListCreate');
  {$ENDIF}
  wurzel:=nil;
  new(twj_p);
  twj_dummy:='';
  twj_kette:='';
  fuser_da:=false;
  repeat
    readln(filterdatei,twj_kette);
    delspace(twj_kette);
    twj_kette:=lowercase(twj_kette);
    twj_dummy:=copy(twj_kette,1,9);
    delete(twj_kette,1,9);
    delspace(twj_kette);
    {$IFDEF DBG}
    wrdbg(twj_dummy+' '+twj_kette);
    {$ENDIF}
    if twj_dummy='xp3p-pho:' then begin
      twj_p^.fuser:=twj_kette;
      fuser_da:=true;
    end; {if}
//  if twj_dummy='!NEGATION' then begin
//  end; {if}
    if fuser_da then begin
      twj_p^.naechster:=wurzel;
      wurzel:=twj_p;
      new(twj_p);
      fuser_da:=false;
    end; {if}
  until eof(filterdatei);
  close(filterdatei);
  {$IFDEF DBG}
  closedbg;
  {$ENDIF}
end; {twj_create_list}


{hier wird ein String mit denen in der Liste verglichen}

function twj_check_filter(vergleich : string) : boolean;

begin
  twj_check_filter:=false;
  if not twj_list_exist then exit;
  {$IFDEF DBG}
  opendbg;
  {$ENDIF}
  twj_p:=wurzel;
  while assigned(twj_p) do with twj_p^ do begin
    {$IFDEF DBG}
    wrdbg('FilterList : '+fuser);
    wrdbg('MessageFrom: '+vergleich);
    {$ENDIF}
    if (pos('<'+fuser+'>',vergleich) > 0)
      or (pos(fuser+' ',vergleich) = 1)
      or (fuser=vergleich) then
    begin
      twj_check_filter:=true;
      {$IFDEF DBG}
      wrdbg('Filter matched: '+vergleich);
      closedbg;
      {$ENDIF}
      exit;
    end; {if}
    twj_p:=naechster;
  end; {while}
  {$IFDEF DBG}
  wrdbg('Filter not matched!');
  closedbg;
  {$ENDIF}
end; {twj_check_filter}

{Heapspeicher wieder freigeben, Liste loeschen}

procedure twj_del_list;

var
  loc_p : twj_zeiger;

begin
  if not twj_list_exist then exit;
  {$IFDEF DBG}
  opendbg;
  wrdbg('Filter unloading...');
  closedbg;
  {$ENDIF}
  new(loc_p);
  twj_p:=wurzel;
  while assigned(twj_p) do begin
    loc_p^:=twj_p^;
    dispose(twj_p);
    twj_p:=loc_p^.naechster;
  end; {while}
  dispose(loc_p);
end; {twj_del_list}

function twj_negation : boolean;

begin
  twj_negation:=false;
end; {twj_negation}


function twj_unixtime : longint;

var
  unix_dummy : longint;

begin
  gettime(h,mi,s,s100);
  getdate(y,m,d,dw);
  gregtounix(y,m,d,h,mi,s,unix_dummy);
  twj_unixtime:=unix_dummy;
end; {twj_unixtime}

end. {pho}

{
 $Log: pho.pas,v $
 Revision 1.2  2002/01/02 23:19:54  MH
 # Komplette Ueberarbeitung der letzten Tage:
 - Fix: AccessViolations -> HugoStrings = AnsiString != String
   (evtl. Bug in Sysutils: Exception.Message)
 - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
 - Anpassungen an neuer Schnittstelle
 - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
 - CPS-SpeedAnzeige im Screen (TWJ)
 - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                       ein TimeStamp mit dem Password crypted werden muﬂ?!?

}
