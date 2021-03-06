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
{ $Id: xp1help.inc,v 1.7 2001/07/11 18:15:30 tj Exp $ }

{ --- Hilfe -------------------------------------------------- }

procedure showkeys(nr:integer);
const kss : byte = 2;

  procedure ks(s:string);
  var p : byte;
  begin
    p:=pos('^',s);
    delete(s,p,1);
    inc(shortkeys);
    if shortkeys>maxskeys then
      interr('Shortkey Overflow');
    with shortkey[shortkeys] do begin
      keypos:=wherex;
      keylen:=length(s);
      keyspot:=p;
      key:=LoCase(s[p]);
      end;
    attrtxt(col.colkeys);
    write(left(s,p-1));
    attrtxt(col.colkeyshigh);
    write(s[p]);
    attrtxt(col.colkeys);
    write(copy(s,p+1,30));
    if kss=2 then write('  ')
    else write(' ');
  end;

  procedure AddSK(pos,len,spot:shortint; _key:taste);
  begin
    inc(shortkeys);
    if shortkeys>maxskeys then
      interr('Shortkey Overflow');
    with shortkey[shortkeys] do begin
      keypos:=pos;
      keylen:=len;
      keyspot:=spot;
      key:=_key;
      end;
  end;

  procedure ende(s1,s2:string);
  begin
    write(sp(79-length(s1)-length(s2)-wherex));
    attrtxt(col.colkeyshigh);
    write(s1);
    attrtxt(col.colkeys);
    write(s2,'  ');
  end;

  procedure ksesc;
  begin
    ende('Esc','');
    AddSK(76,3,-3,keyesc);
  end;

  procedure plusminus;
  begin
    AddSK(wherex,1,1,'+');
    attrtxt(col.colkeyshigh);
    write('+');
    attrtxt(col.colkeys);
    write('/');
    AddSK(wherex,1,1,'-');
    attrtxt(col.colkeyshigh);
    write('-');
    attrtxt(col.colkeys);
  end;

  procedure tabkey;
  begin
    attrtxt(col.colkeys);
    write(sp(69-wherex));
    addsk(wherex,3,-3,keytab);
    attrtxt(col.colkeyshigh);
    write('Tab');
    attrtxt(col.colkeys);
    write(' / ');
    addsk(wherex,4,1,'q');
    ende('Q','uit');
  end;

  procedure hitxt(s:string);
  begin
    attrtxt(col.colkeyshigh);
    write(s);
  end;

  procedure ksmark;
  begin
    AddSK(wherex,21,-11,' ');
    hitxt('Space/F7/F');
    ks('^8-'+getres2(20,0));    { 'markieren' }
    dec(shortkeys);
  end;

  procedure kscr(txt:string);
  begin
    AddSK(wherex,length(txt)+4,-3,keycr);
    hitxt(#17'�');
    ks('^�-'+txt);
    dec(shortkeys);
  end;

  procedure kstr(nr:word);
  var s : string[80];
      p : byte;
  begin
    s:=getres2(20,nr)+' ';
    repeat
      p:=cpos(' ',s);
      if s[1]='~' then begin      { Ctrl-Zeichen }
        hitxt('^');
        s[1]:='^';
        ks(left(s,p-1));
        with shortkey[shortkeys] do begin
          key:=chr(ord(upcase(s[2]))-64);
          dec(keypos);
          inc(keylen);
          keyspot:=-keyspot-1;
          end;
        end
      else
        ks(left(s,p-1));
      delete(s,1,p);
    until s='';
  end;

begin
  if not keydisp then exit;
  shortkeys:=0;
  gotoxy(1,2);
  attrtxt(col.colkeys);
  moff;
  write('  ');
  case abs(nr) of
    0 : write(sp(78));
    1 : begin       { Brettfenster }
          kstr(1);  { ^Alle ^Brief T^extfile B^in�r ^Spezial ^Lesen: }
          lesemodepos:=wherex-1;
          gotoxy(wherex+10,wherey);     { gegen flackernden Lesemode }
          tabkey;
        end;
    2 : begin       { User-Fenster }
          kstr(2);  { ^Alle ^Brief T^extfile B^in�r ^Spezial S^uche Ad^re�buch ^Pa�wort }
          tabkey;
        end;
    3 : begin       { Edit-Brettfenster }
          if length(getres2(20,3))>=58 then
            kss:=1;
          kstr(3);  { ^Hinzuf. ^L�schen ^Edit ^Verkn�pfen ^Pos. ~Trenn. ^Spezial }
          plusminus;
          kss:=2;
          tabkey;
        end;
    4 : begin       { Edit-Userfenster }
          kstr(4);  { ^Alle ^Hinzuf. ^Vert. ^L�schen ^Edit ^Spezial Ad^re�buch ^PW }
          plusminus;
          tabkey;
        end;
    5 : begin       { Msg-Fenster / User-Msg-Fenster }
          if nr>0 then kstr(5)   { ^Alle ^Halten ^L�schen ^Kill Bezu^g ^BrettBrief ^PM ^User ^Info ^Sonst. }
          else kstr(6);          { ^Alle ^Halten ^L�schen ^Kill Bezu^g ^PM ^Info D^ruck ^Sonstiges }
          ksesc;
        end;
    6 : begin             { markierte Nachrichten / Kommentarbaum }
          if nr>0 then kstr(7)   { ^Halten ^L�schen ^Kill ^BrettBrief ^PM ^Info ^Absender ^Sonstige }
          else kstr(8);          { ^Adresse ^Halten ^L�schen ^Kill ^BrettBrief ^PM ^Info ^Sonstige  }
          ksesc;
        end;
    7 : begin             { Brett-Weiterleitfenster }
          kscr(getres2(20,9));   { 'best�tigen' }
          ksesc;
        end;
    8 : begin             { User-Weiterleitfenster }
          ks(getres2(20,10));    { '^Alle' }
          ks(getres2(20,22));    { 'S^uche' }
          kscr(getres2(20,9));   { 'best�tigen' }
          ksesc;
        end;
    9 : begin             { Maps - Brettliste }
          ksmark;
          kscr(getres2(20,iif(nr<0,11,12)));  { 'abbestellen' / 'bestellen' }
          ksesc;
        end;
   10 : begin             { Fileserver - Dateiliste }
          ksmark;
          kscr(getres2(20,21));   { 'bestellen' }
          ksesc;
        end;
   11 : begin             { Archiv-Viewer }
          ksmark;
          kstr(13);       { 'E^xtrakt' }
          kscr(getres2(20,14));    { 'anzeigen' }
          ksesc;
        end;
   12 : begin             { Brettliste - hinzuf�gen }
          ksmark;
          kscr(getres2(20,15));   { 'Bretter anlegen' }
          ksesc;
        end;
   13 : begin             { Auto-Netcall }
          hitxt('Spac');
          ks('^e-'+getres2(20,16));   { 'Netcall direkt starten' }
          ksesc;
        end;
   14 : begin       { Autoversand-Liste }
          kstr(17); { ^Aktiv ^Hinzuf�gen ^Kopie ^L�schen ^Edit ^TextEdit ^Info ^Senden }
          AddSK(wherex,3,-3,keycr);
          hitxt(#17'��');
          ksesc;
        end;
   15 : begin             { Netcall - Anwahl }
          plusminus;
          write(getres2(20,18));   { ' Zeit' }
          ksesc;
        end;
   16 : begin             { Netcall - Warten }
          hitxt('Spac');
          ks('^e-'+getres2(20,19));    { 'Netcall starten' }
          ksesc;
        end;
   17 : ksesc;            { Esc = Abbruch }
   18 : begin             { Online-Anruf - Warten }
          hitxt('Spac');
          ks('^e-'+getres2(20,20));    { 'Anruf starten' }
          ksesc;
        end;
  end;
  mon;
  freeres;
  lastkeys:=nr;
end;

procedure showlastkeys;
begin
  showkeys(lastkeys);
end;


procedure hlp(nr:word);
begin
  helpst[helpstp]:=nr;
end;

procedure pushhp(nr:word);
begin
  if helpstp>=maxhelpst then
    interr('PushHP: Overflow')
  else begin
    inc(helpstp);
    helpst[helpstp]:=nr;
    end;
end;

procedure pophp;
begin
  if helpstp=1 then
    interr('PopHP: Underflow')
  else
    dec(helpstp);
end;


procedure set_helppos;
begin
  sethelppos(15,6+(screenlines-24)div 4,16+(screenlines-25)div 2);
end;

procedure do_help(n:word);
var   yadd : byte;
      x,y  : byte;
      hlp  : string[10];
      mh   : boolean;
begin
  if not inithlp then
    if not inithelp(OwnPath+helpfile,1,1,HInvers,HKeinBlocksatz,HHeadNotHigh) then
    begin
      rfehler1(1,helpfile);   { Die Hilfsdatei XP.HLP fehlt }
      if ioresult<>0 then;
      end
    else begin
      inithlp:=true;
      set_helppos;
      end;
  if inithlp then begin
    hlp:='';
    setrahmen(2);
    openbox(58,18+(actscreenlines-25)div 2,hlp,x,y,col.colHelp,col.colHelp);
    setrahmen(1);
    mh:=hotkeys;
    hotkeys:=false;
    IHS(n);
    hotkeys:=mh;
    closebox;
    end;
end;


procedure hprint;
begin
  help_printable(^D,printstring(druckinit),printstring(druckexit));
end;

procedure hilfe;
begin
  savecursor;
  hprint;
  if readmask_active and (mask_helpnr>0) then
    do_help(mask_helpnr)
  else
    do_help(helpst[helpstp]);
  restcursor;
end;


procedure hilfealt;
begin
  hprint;
  do_help(0);
end;


procedure freehelp;  { wird von shell() benutzt }
begin
  if inithlp then begin
    releasehelp;
    inithlp:=false;
    end;
end;


{ F-Tastenk�rzel in letzter Zeile anzeigen }

procedure dispfunctionkeys(editor:boolean);
const fs : array[1..3] of char = 'SCA';
var fks,fkn : integer;
    i,j,spc : integer;
    hilfe,
    makros  : string[10];

  procedure wf(s:string);
  begin
    attrtxt(col.colkeyshigh);
    write(left(s,pos('-',s)-1));
    attrtxt(col.colkeys);
    write(copy(s,pos('-',s),60),sp(spc));
  end;

begin
  fks:=0; fkn:=0;
  if not editor then
    for i:=1 to 3 do                     { ben�tigten Platz berechnen }
      for j:=1 to 10 do                  { ohne Spaces                }
        with fkeys[i]^[j] do
          if menue<>'' then begin
            inc(fks,length(menue)+3);
            inc(fkn);
            end;
  spc:=iif(fks+2*fkn<42,2,1);
  inc(fks,spc*fkn);

  hilfe:=getres(100);
  makros:=getres(101);
  moff;
  gotoxy(1,screenlines);
  if fks<70-length(hilfe) then wf('F1-'+hilfe);
  if fks<57-length(hilfe)-length(makros) then wf('F6-'+makros);
{$IFDEF Ver32 }
  if fks<62-length(hilfe) then wf('F9-Shell');
{$ELSE }
  if fks<62-length(hilfe) then wf('F9-DOS');
{$ENDIF }
  inc(windmax,$100);
  if editor then
    wf('F10-'+getres(133))
  else
    for i:=1 to 3 do
      for j:=1 to 10 do
        with fkeys[i]^[j] do
          if menue<>'' then
            if (wherex+length(menue)+3<=81) and (wherey=screenlines) then
              wf(fs[i]+strs(j)+'-'+menue);
  attrtxt(col.colkeys);
  XPdisplayed:=(wherey=screenlines) and (wherex<=70);
  if XPdisplayed then
    write(sp(81-length(xp_xp)-wherex),xp_xp)   { 'CrossPoint' }
  else
    if wherey=screenlines then write(sp(81-wherex));
  mon;
  dec(windmax,$100);
  fnkeylines:=1;
end;

{
  $Log: xp1help.inc,v $
  Revision 1.7  2001/07/11 18:15:30  tj
  was vergessen

  Revision 1.6  2001/07/11 17:46:29  tj
  32 Bit: F9-DOS -> F9-Shell

  Revision 1.5  2001/06/18 20:17:23  oh
  Teames -> Teams

  Revision 1.4  2000/08/27 09:29:42  MH
  Usersuche bei Auswahl �ber F2 erm�glicht

  Revision 1.3  2000/05/25 23:18:05  rb
  Loginfos hinzugef�gt

}
