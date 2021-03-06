{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xpx.pas,v 1.9 2000/11/24 14:39:31 rb Exp $ }

{ CrossPoint - First Unit }

unit xpx;

{$I XPDEFINE.INC }

interface

uses xpglobal,

{$IFDEF BP }
  ems, mcb,
{$ENDIF }
  crt, dos,dosx,typeform,fileio,mouse,inout,xp0,xpcrc32;

implementation

{$IFDEF BP }
  {$IFDEF DPMI}
  const MinVersion = $330;
        MinVerStr  = '3.3';
        MaxHandles = 31;
  {$ELSE}
  uses  overlay;
  const MinVersion = $300;
        MinVerStr  = '3.0';
        MaxHandles = 30;
  var   handles    : array[1..maxhandles] of byte;
  {$ENDIF}
{$ENDIF}

const starting : boolean = true;

var oldexit : pointer;



procedure stop(txt:string);
begin
  writeln;
  writeln(txt);
  runerror:=false;
  halt(1);
end;

{ Diese Funktion und deren Aufruf d�rfen nicht ver�ndert werden }
{ (siehe LIZENZ.TXT).                                           }
procedure logo;
var t : text;
begin
  assign(t,'');
  rewrite(t);
  writeln(t);
  write(t,xp_xp);
  if (xp_xp='CrossPoint') then write(t,'(R)');
  writeln(t,' ',verstr,pformstr,betastr,' ',x_copyright,
            ' by ',author_name,' (',author_mail,')');
  writeln(t);
  writeln(t,'basierend auf CrossPoint(R) v3.2 (c) 1992-99 by ',pm);
  writeln(t);
{$IFNDEF VP }
  close(t); { !? }
{$ENDIF }
end;


procedure readname;
var t    : text;
    name : string[10];
    short: string[2];
    code : string[20];
begin
  assign(t,progpath+'pname.dat');
  if existf(t) then begin
    reset(t);
    readln(t,name);
    readln(t,short);
    readln(t,code);
    close(t);
    if (ioresult=0) and
       (ival(code)=sqr(crc32(reverse(name)) and $ffff)) then begin
      XP_xp:=name;
      XP_name := '## '+name+' '+verstr+betastr;
      XP_origin := '--- '+name;
      XP_short := short;
      end;
    end;
end;

{$IFDEF BP }
procedure SetHandles;
var i    : integer;
    regs : registers;
begin
  {$IFNDEF DPMI }
    for i:=1 to maxhandles do
      handles[i]:=$ff;
    for i:=1 to 5 do
      handles[i]:=mem[PrefixSeg:$18+pred(i)];
    MemW[PrefixSeg:$32] := MaxHandles;
    MemW[PrefixSeg:$34] := Ofs(handles);
    MemW[PrefixSeg:$36] := Seg(handles);
  {$ELSE}
    with regs do begin
      ah:=$67;
      bx:=maxhandles;
      msdos(regs);
      if flags and fcarry<>0 then
        writeln('Warnung: Fehler beim Anfordern von File Handles!');
      end;
  {$ENDIF}
end;
{$ENDIF }

{$IFDEF BP }
procedure TestOVR;
var ft   : longint;
    c,cc : char;
begin
  if not exist('xp.ovr') then
    stop('Die Datei XP.OVR fehlt!');
  ft:=filetime('xp.exe');
  if (ft<>0) and (abs(ft-filetime('xp.ovr'))>=60) then begin
    writeln;
    writeln('WARNUNG: Das Dateidatum von XP.OVR stimmt nicht mit dem von XP.EXE');
    writeln('         �berein. XP.OVR stammt offenbar von einer anderen '+xp_xp+'-');
    writeln('         Version. Bitte spielen Sie das Programm aus einem '+xp_xp+'-');
    writeln('         Originalarchiv neu auf! Wenn Sie das Programm jetzt fortsetzen,');
    writeln('         wird es wahrscheinlich abst�rzen.');
    writeln;
    writeln('         Falls Sie nach einem Neuaufspielen wieder die gleiche Fehler-');
    writeln('         meldung erhalten, ist Ihr Rechner m�glicherweise mit einem');
    writeln('         Virus infiziert.');
    writeln;
    write(#7'Programm fortsetzen (J/N)? ');
    c:='N';
    repeat
      write(c,#8);
      cc:=readkey;
      case cc of
        #0 : if readkey='' then;
        'j','J' : c:='J';
        'n','N' : c:='N';
      end;
    until (cc=#13) or (cc=#27);
    writeln;
    if (cc=#27) or (c='N') then begin
      runerror:=false;
      halt(1);
      end;
    end;
end;
{$ENDIF }

function _deutsch:boolean;
var t : text;
    s : string;
begin
  filemode:=0;
  assign(t,'xp.res');
  reset(t);
  readln(t,s);
  close(t);
  _deutsch:=(ioresult=0) and (ustr(s)='XP-D.RES');
  filemode:=2;
end;


{$S-}
procedure setpath; {$IFNDEF Ver32 } far; {$ENDIF }
begin
  if ioresult = 0 then ;
  GoDir(shellpath);
  if ioresult<>0 then GoDir(ownpath);
  if runerror and not starting then begin
    attrtxt(7);
    writeln;
    writeln('Fehler: ',ioerror(exitcode,'<interner Fehler>'));
    end;
  exitproc:=oldexit;
end;
{$IFDEF Debug }
  {$S+}
{$ENDIF }


procedure TestCD;
var f    : file;
    attr : rtlword;
begin
  assign(f,paramstr(0));
  getfattr(f,attr);
  if attr and ReadOnly<>0 then begin
    assign(f,OwnPath+'XP$T.$1');
    rewrite(f);
    if ioresult=0 then begin
      close(f);
      erase(f);
      end
    else begin
      writeln;
      writeln(xp_xp+' kann nicht von einem schreibgesch�tzten Laufwerk gestartet');
      writeln('werden. Kopieren Sie das Programm bitte auf Festplatte.');
      runerror:=false;
      halt(1);
      end;
    end;
end;

{.$define mcbdebug}

function xpshell:boolean; { true, wenn XP in seiner eigenen Shell gestartet wurde }
{$ifdef bp}
var mcb:mcbp;
    envseg:word;
    s:string;
begin
  xpshell:=false;

{$ifdef mcbdebug}
  writeln;
  writeln('PSP  Env. Typ    Gr��e  Prog.   Prog. (Environment)');
  writeln('Seg. Seg.               (MCB)');
  writeln('------------------------------------------------------------------------');
{$endif}

  mcb:=firstmcb;
  repeat
    s:=getmcbprog(mcb);
{   if s='' then s:=getmcbenvprog(getmcbenvseg(mcb)); }
{ F�r DOS-Versionen kleiner 4.0 m�sste man obige Zeile eigentlich aktivieren,
  da ich es aber nicht mit DOS < 4.0 testen konnte, bin ich nicht sicher, ob
  es 100%ig funktioniert.
}
    if (ustr(shortp(paramstr(0)))=ustr(s)) and (mcb^.psp_seg<>prefixseg)
       and (mcb^.size*16>20480)
      then xpshell:=true;

{$ifdef mcbdebug}
    write(hex(mcb^.psp_seg,4),' ',
          hex(getmcbenvseg(mcb),4),' ');
    if ispsp(mcb) then write('PSP   ') else case mcb^.psp_seg of
      $0000: write('frei  ');
      $0008: write('DOS   ');
      $0006: write('DRDOS ');
      $0007: write('DRDOS ');
      $FFF7: write('386MAX');
      $FFFA: write('386MAX');
      $FFFD: write('386MAX');
      $FFFE: write('386MAX');
      $FFFF: write('386MAX');
      else write('?     ');
    end;
    write(mcb^.size*16:6,
          getmcbprog(mcb):9,' ',
          getmcbenvprog(getmcbenvseg(mcb)));
    writeln;
{$endif}

    mcb:=nextmcb(mcb);
  until mcb^.id='Z';

{$ifdef mcbdebug}
  write(#13#10'-> Enter');
  readln;
{$endif}

end;
{$else}
begin
  xpshell:=false;
end;
{$endif}

begin
  checkbreak:=false;
{$IFDEF BP } { Die Abfrage der DOS-Version ist nur bei 16 Bit sinnvoll }
  if swap(dosversion)<MinVersion then
    stop('DOS Version '+MinVerStr+' oder h�her erforderlich.');
{$ENDIF }
  readname;
  if (left(getenv('PROMPT'),4)='[XP]') or xpshell then
    if _deutsch then stop('Zur�ck zu '+xp_xp+' mit EXIT.')
    else stop('Type EXIT to return to '+xp_xp+'.');
{$IFDEF BP }
  SetHandles;
{$ENDIF }
  ShellPath:=dospath(0);
  if Shellpath+'\'<>progpath then
    GoDir(progpath);
  oldexit:=exitproc;
  exitproc:=@setpath;
  mausunit_init;
  logo;
{$IFDEF BP }            { alles andere sind sowieso 32 Bit Versionen }
  {$IFNDEF NO386 }      { Die XT und 286er Version darf hier nicht testen }
  if Test8086 < 2 then
  begin
    if _deutsch then begin
      Writeln('XP2 l�uft in dieser Version erst ab 386er CPUs.');
      Writeln('Eine XT-Version kann von der Homepage http://www.xp2.de/ bezogen werden.');
    end
    else begin
      Writeln('XP2 needs at least a 386 CPU in this version.');
      Writeln('A XT version is available at http://www.xp2.de/');
    end;
    runerror := false;
    Halt(1);
  end;
  {$ELSE}
    {$IFNDEF NO286 }      { Die XT Version darf hier nicht testen }
  if Test8086 < 1 then
  begin
    if _deutsch then begin
      Writeln('XP2 l�uft in dieser Version erst ab 286er CPUs.');
      Writeln('Eine XT-Version kann von der Homepage http://www.xp2.de/ bezogen werden.');
    end
    else begin
      Writeln('XP2 needs at least a 286 CPU in this version.');
      Writeln('A XT version is available at http://www.xp2.de/');
    end;
    runerror := false;
    Halt(1);
  end;
    {$ENDIF }
  {$ENDIF }
{$ENDIF }

{$IFDEF BP }      { Unter 32 Bit haben wir keine Overlays }
  {$IFNDEF DPMI}     { mit DPMI auch nicht }
    TestOVR;
    OvrInit('xp.ovr');
    if EmsTest and (ustr(left(paramstr(1),4))<>'/AV:') and (paramstr(1)<>'/?') then
      OvrInitEMS;
    OvrSetBuf(OvrGetBuf+40000);   { > CodeSize(MASKE.TPU) }
  {$ENDIF}
{$ENDIF}

  OwnPath:=progpath;
  if ownpath='' then getdir(0,ownpath);
  if right(ownpath,1)<>'\' then
    ownpath:=ownpath+'\';
  if cpos(':',ownpath)=0 then begin
    if left(ownpath,1)<>'\' then ownpath:='\'+ownpath;
    ownpath:=getdrive+':'+ownpath;
    end;
  UpString(ownpath);
  TestCD;
  starting:=false;
end.
{
  $Log: xpx.pas,v $
  Revision 1.9  2000/11/24 14:39:31  rb
  MCB-Erkennung sicherer gemacht

  Revision 1.8  2000/11/17 02:22:36  rb
  Mehrfachstart in einer Shell verhindern, auch wenn der Prompt in der Shell
  ge�ndert wurde. Funktioniert ab DOS 4.0.

  Revision 1.7  2000/09/13 21:25:34  rb
  Schalter f�r 8088/286/386er Version

  Revision 1.6  2000/06/08 20:07:54  MH
  Teamname geandert

  Revision 1.5  2000/04/10 22:13:18  rb
  Code aufger�umt

  Revision 1.4  2000/04/09 18:33:46  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.10  2000/04/04 10:33:57  mk
  - Compilierbar mit Virtual Pascal 2.0

  Revision 1.9  2000/03/24 08:35:30  mk
  - Compilerfaehigkeit unter FPC wieder hergestellt

  Revision 1.8  2000/03/24 00:03:39  rb
  erste Anpassungen f�r die portierung mit VP

  Revision 1.7  2000/03/02 18:32:24  mk
  - Code ein wenig aufgeraeumt

  Revision 1.6  2000/02/19 11:40:09  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.5  2000/02/15 20:43:37  mk
  MK: Aktualisierung auf Stand 15.02.2000

}
