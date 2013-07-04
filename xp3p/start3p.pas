{ $Id: start3p.pas,v 1.3 2002/01/02 23:16:48 MH Exp $ }

{$B-,D+,H-,I+,J+,P-,Q+,R+,S+,T-,V-,W-,X+,Z-}
{&AlignCode+,AlignData+,AlignRec-,Asm-,Cdecl-,Comments-,Delphi+,Frame+,G3+}
{&G5-,LocInfo+,Open32-,Optimise-,OrgName-,SmartLink-,Speed+,Use32+,ZD+}
{$M 32768}

uses startos2;

const sem_xp3p = 'SEMXP3P';
      xp3pnorev = 'Reverse engineering and disassembling prohibited.';

var i:word;
    omaj,omin,oem:byte;
    params,workdir:string;

procedure get_os(var major,minor,oem:byte); assembler;
  asm
    mov ax,3000h
    int 21h
    les di,[major]
    stosb
    les di,[minor]
    mov al,ah
    stosb
    les di,[oem]
    mov al,bh
    stosb
  end;

begin
{  params:=xp3pnorev;} { Dummy-Zugriff }
  get_os(omaj,omin,oem);
  if not ((omaj=20) and (omin>=30) and (oem=0)) then begin
    writeln('OS/2 ab Version 3 sollte es dann schon sein ...');
    halt(255);
  end;
  getdir(0,workdir);
  params:='/WORKDIR:'+workdir;
  for i:=1 to paramcount do params:=params+' '+paramstr(i);
  if pos('\',paramstr(0))=0
    then workdir:=workdir+'\'+paramstr(0)
    else workdir:=paramstr(0);
  Start(workdir,params,'XP3P for OS/2');
{  writeln('Starte ',workdir,' ',params,' ...'); }
  write('Warte auf RÅckkehr von ',workdir,' ...');
  WaitForEnd('\SEM32\'+sem_xp3p);
  writeln;
end.


{
  $Log: start3p.pas,v $
  Revision 1.3  2002/01/02 23:16:48  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.2  2001/07/14 12:07:44  oh
  Rechtschreibkorrektur

  Revision 1.1  2001/07/11 19:47:18  rb
  checkin


}
