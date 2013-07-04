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
{ $Id: xp2par.pas,v 1.8 2001/07/22 12:06:26 MH Exp $ }

{ CrossPoint - StartUp / Kommandozeilenparameter auswerten }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp2par;

interface

uses xpglobal,{$IFDEF virtualpascal}{sysutils,}{$endif}
     crt,dos,typeform,fileio,inout,database,
     video,lister,clip,xp0,xp1;

procedure readpar;

implementation

procedure readpar;
var i  : integer;
    s  : string[127];
    t  : text;
    sr : searchrec;

  function _is(ss:string):boolean;
  begin
    _is:=('/'+ss=lstr(s)) or ('-'+ss=lstr(s));
  end;

  function isl(ss:string):boolean;
  begin
    isl:=('/'+ss=lstr(left(s,length(ss)+1))) or
         ('-'+ss=lstr(left(s,length(ss)+1)));
  end;

  function ReplDP(s:string):string;   { Fido-Boxname: "_" -> ":" }
  var p1,p2 : byte;
  begin
    p1:=cpos(':',s);
    p2:=cpos('_',s);
    if (p2>0) and (((p1=0) or ((p2<p1) and (ival(left(s,p2-1))>0)))) then
      s[p2]:=':';
    ReplDP:=s;
  end;

  procedure NetPar(s:string);
  var p : byte;
  begin
    p:=cpos(':',s);
    s:=ReplDP(trim(s));
    if p=0 then
      ParNetcall:=s
    else begin
      ParNetcall:=left(s,min(p-1,BoxNameLen));
      ParNCtime:=formi(ival(copy(s,p+1,2)),2)+':'+formi(ival(copy(s,p+4,2)),2);
      end;
  end;

  procedure UserPar(s:string);
  var p : byte;
  begin
    p:=cpos(':',s);
    s:=ReplDP(s);
    if p=0 then
      writeln('fehlerhafte /user - Option')
    else begin
      s[p]:=' ';
      ParSetuser:=left(s,sizeof(ParSetuser)-1);
      end;
  end;

  procedure SetZeilen(z:byte);
  begin
    case videotype of
      2 : if z in [25,26,29,31,35,38,43,50] then ParZeilen:=z;
      3 : if z in [25,26,28,30,33,36,40,44,50] then ParZeilen:=z;
    end;
  end;

  procedure ParAuswerten;
  begin
    if _is('h') or _is('?') then ParHelp:=true else
    if _is('version') then ParVersion:=true else
    if _is('d')    then ParDebug:=true else
    if isl('df:')  then ParDebFlags:=ParDebFlags or ival(mid(s,5)) else
    if _is('dd')   then ParDDebug:=true else
    if _is('trace')then ParTrace:=true else
    if _is('m')    then ParMono:=true else
    if _is('j')    then ParNojoke:=true else
    if isl('n:')   then NetPar(ustr(mid(s,4))) else
    if isl('nr:')  then begin
                          NetPar(ustr(mid(s,5)));
                          ParRelogin:=true;
                        end else
    if _is('r')    then ParReorg:=true else
    if _is('rp')   then ParTestres:=false else
    if _is('pack') then ParPack:=true else
    if isl('xpack:') then begin
                           ParXpack:=true;
                           ParXPfile:=ustr(copy(s,8,8));
                         end else
    if _is('xpack') then ParXPack:=true else
    if _is('q')     then ParQuiet:=true else
    if _is('maus')  then ParMaus:=true else
    if isl('ip:')   then ParPuffer:=ustr(copy(s,5,70)) else
    if isl('ipe:')  then begin
                           ParPuffer:=ustr(copy(s,6,70));
                           ParPufED:=true;
                         end else
    if _is('g')     then ParGelesen:=true else
    if isl('ips:')  then ParSendbuf:=ustr(mid(s,6)) else
    if isl('t:')    then
{$IFDEF Beta }
                         begin
                           ParTiming:=ival(copy(s,4,2));
                           ParNoBeta:=true;
                         end else
{$ELSE}
                         ParTiming:=ival(copy(s,4,2)) else
{$ENDIF}
    if _is('x')     then ParExit:=true else
    if _is('xx')    then ParXX:=true else
    if isl('user:') then UserPar(mid(s,7)) else
    if isl('k:')    then ParKey:=iifc(length(s)>3,s[4],' ') else
    if _is('eb')    then ParEmpfbest:=true else
    if _is('pa')    then ParPass:='*' else
    if isl('pa:')   then ParPass:=mid(s,5) else
    if isl('pw:')   then ParPasswd:=mid(paramstr(i),5) else
    if isl('z:')    then SetZeilen(ival(mid(s,4))) else
    {if isl('mailto:') then ParMailto:=mid(paramstr(i),9) else}

    { Achtung! Folgende Reihenfolge muss bleiben! robo }
    if _is('w0')   then ParWintime:=0 else
    if _is('os2a') then begin ParWintime:=1; ParOS2:=1; end else
    if _is('os2b') then begin ParWintime:=1; ParOS2:=2; end else
    if _is('os2c') then begin ParWintime:=1; ParOS2:=3; end else
    if _is('os2d') then begin ParWintime:=1; ParOs2:=4; end else
    if _is('w')    then ParWintime:=1 else
    if _is('w1')   then ParWintime:=1 else
    if _is('w2')   then ParWintime:=2 else
    { Reihenfolge bis hier }

    if _is('ss')   then ParSsaver:=true else
  { if isl('gd:') then SetGebdat(mid(s,5)) else }
    if isl('av:')  then ParAV:=mid(s,5) else
    if isl('autostart:') then ParAutost:=mid(s,12) else
    if isl('l:')   then ParLanguage:=ustr(mid(s,4)) else
    if isl('f:')   then ParFontfile:=ustr(mid(s,4)) else
    if _is('nomem')then ParNomem:=true else
    if _is('sd')   then ParNoSmart:=true else
    if _is('lcd')  then ParLCD:=true else
    if _is('menu') then ParMenu:=true else
    if _is('g1')   then ParG1:=true else
    if _is('g2')   then ParG2:=true else
{$IFDEF Beta } { Keine Beta-Meldung anzeigen }
    if _is('nb')   then ParNoBeta := true else
{$ELSE } { nb Åbergehen, auch wenn nicht benîtigt }
    if _is('nb')   then else
{$ENDIF }
    if _is('nolock') then ParNolock:=true
    else               begin
                         writeln('unbekannte Option: ',paramstr(i),#7);
                         delay(500);
                       end
  end;

  procedure ReadParFile;
  begin
    reset(t);
    while not eof(t) do begin
      readln(t,s);
      s:=trim(s);
      if s<>'' then ParAuswerten;
      end;
    close(t);
  end;

begin
  { Unter Win/OS2/Linux: Default "/w", Rechenzeitfreigabe abschalten mit "/w0" }
{$IFDEF BP }
  if (winversion>0) or (lo(dosversion)>=20) or (DOSEmuVersion <> '')
    then ParWintime:=1;
{$else}
  ParWintime:=1;
{$ENDIF }
  s:='';
  { extended:=exist('xtended.15'); huch ?!? }
  findfirst(AutoxDir+'*.OPT',Archive,sr);    { permanente Parameter-Datei }
  while doserror=0 do begin
    assign(t,AutoxDir+sr.name);
    ReadParfile;
    findnext(sr);
  end;
  {$IFDEF Ver32 }
  FindClose(sr);
  {$ENDIF}
  for i:=1 to paramcount do            { Command-Line-Parameter in einem String }
    s:=s+' '+paramstr(i);
  if pos('mailto:',s)<>0 then begin
    s:=trim(s);
    s:=copy(s,pos('mailto:',s)-1,length(s)-pos('mailto:',s)+2);
    ParMailto:=mid(s,9);
  end else
  for i:=1 to paramcount do begin      { Command-Line-Parameter }
    s:=paramstr(i);
    ParAuswerten;
  end;
  findfirst(AutoxDir+'*.PAR',Archive,sr);    { temporÑre Parameter-Datei }
  while doserror=0 do begin
    assign(t,AutoxDir+sr.name);
    ReadParfile;
    erase(t);
    if ioresult<>0 then
      writeln('Fehler: kann '+AutoxDir+sr.name+' nicht lîschen!');
    findnext(sr);
  end;
  {$IFDEF Ver32 }
  FindClose(sr);
  {$ENDIF}
  if VideoType<2 then ParFontfile:='';
  if (ParFontfile<>'') and (ParFontfile[1]<>'*') then
    ParFontfile:=FExpand(ParFontfile);
  if ParDebug then Multi3:=ShowStack;
  {if ParDDebug then dbOpenLog('database.log');}
  ListDebug:=ParDebug;
  if (left(ParAutost,4)<='0001') and (right(ParAutost,4)>='2359') then
    ParAutost:='';
end;

end.

{
  $Log: xp2par.pas,v $
  Revision 1.8  2001/07/22 12:06:26  MH
  - FindFirst-Attribute ge‰ndert: 0 <--> DOS.Archive

  Revision 1.7  2001/06/26 17:47:08  MH
  - Parameter /dd: Bei Doppelstart problematisch, daher wird das LogFile
    nun spÑter geîffnet.

  Revision 1.6  2001/06/26 15:02:18  MH
  - ÅberflÅssiges entfernt (xtended.15 / extended)

  Revision 1.5  2001/06/18 20:17:27  oh
  Teames -> Teams

  Revision 1.4  2000/12/30 18:55:23  MH
  Fix:
  - Betascreen bei Paramter '/t:' ignorieren
  - Betaschalter fÅr BetaScreen hinzugefÅgt

  Revision 1.3  2000/12/05 20:13:36  MH
  - Fix: Parameter auch bei /mailto verarbeiten
    - wieder RÅckgÑngig gemacht, da sonst bei Betreffs es
      Fehlermeldungen hageln wÅrde!

  Revision 1.2  2000/12/05 19:41:38  MH
  - Fix: Parameter auch bei /mailto verarbeiten

  Revision 1.1  2000/09/21 21:59:30  rb
  Codeteile ausgelagert

}