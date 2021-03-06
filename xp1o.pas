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
{ $Id: xp1o.pas,v 1.55 2002/06/05 18:08:11 mm Exp $ }

{ Overlay-Teil zu xp1 }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp1o;

interface

uses  xpglobal, crt,dos,dosx,typeform,keys,fileio,inout,maus2,lister,
  printerx, datadef,database,maske,archive,resource,clip, xp0,xpcrc32;

const ListKommentar : boolean = false;   { beenden mit links/rechts }
      ListQuoteMsg  : pathstr = '';
      ListXHighlight: boolean = true;    { f�r F-Umschaltung }
      showhdr       : boolean = false;   { ShowHeader aktiv  }
      ListWrapToggle: boolean = false;   { f�r Wortumbruch-Umschaltung }

var  listexit : shortint;   { 0=Esc/BS, -1=Minus, 1=Plus, 2=links, 3=rechts }
     listkey  : taste;


function  ReadFilename(txt:atext; var s:pathstr; subs:boolean;
                       var useclip:boolean):boolean;
function  ReadFilename2(txt:atext; var s:pathstr; subs:boolean):boolean;
function  overwrite(fname:pathstr; replace:boolean; var brk:boolean):boolean;
procedure listExt(var t:taste);
procedure ExtListKeys;
function  filecopy(fn1,fn2:pathstr):boolean;
function  FileDa(fn:pathstr):boolean;   { Programm im Pfad suchen }
procedure ExpandTabs(fn1,fn2:string);

function  GetDecomp(atyp:shortint; var decomp:string):boolean;
function  UniExtract(_from,_to,dateien:pathstr):boolean;
function  g_code(s:string):string;
procedure SeekLeftBox(var d:DB; var box:string);
procedure KorrBoxname(var box:string);
function  BoxFilename(var box:string):string;

procedure AddBezug(var hd:header; dateadd:byte);
procedure DelBezug;
function  GetBezug(var ref:string):longint;
function  KK:boolean;
function  HasRef:boolean;
function  ZCfiletime(var fn:pathstr):string;   { ZC-Dateidatum }
procedure SetZCftime(fn:pathstr; var ddatum:string);

function  testtelefon(var s:string):boolean;
function  IsKomCode(nr:longint):boolean;
function  IsOrgCode(nr:longint):boolean;

function XPWinShell(prog:string; parfn:pathstr; space:word;
                    cls:shortint; Fileattach:boolean):boolean;
{ true, wenn kein DOS-Programm aufgerufen wurde }

implementation

uses xp1,xp1o2,xp1input,xpkeys,xpnt,xp10,xp4,xp4o,xp9;       {JG:24.01.00}

function getline:string;
begin
  if list_markanz<>0 then getline:=first_marked else
  if list_selbar then getline:=get_selection else getline:='';
end;

{ Dateinamen abfragen. Wenn Esc gedr�ckt wird, ist s undefiniert! }
function ReadFilename(txt:atext; var s:pathstr; subs:boolean;
                      var useclip:boolean):boolean;
const urlchars:set of char=['a'..'z','A'..'Z','0'..'9','.',':','/','~','?',
                            '-','_','#','=','&','%','@','$','+',',',';'];
var x,y    : byte;
    fn     : string[20];
    brk    : boolean;
    bl     : boolean;
    bin    : boolean;
begin
  fn:=getres(106);
  dialog(45+length(fn),3,txt,x,y);
  bin:=(txt=getres(613));
  bl:=(pos('block',lstr(txt))<>0);
  useclip:=clipboard and (useclip or bl);
  maddstring(3,2,fn,s,37,255,'');   { Dateiname: }
  if useclip then begin
    if not bin then
      mappsel(false,'Windows-Clipboard');
    if not bl and not bin and (aktdispmode in [10,11,12]) then begin
      mappsel(false,'Win-Clipboard (URL)');
      mappsel(false,'Win-Clipboard (MAIL)');
    end;
  end;
  readmask(brk);
  enddialog;
  if not brk then begin
    UpString(s);
    useclipwin:=(s='WINDOWS-CLIPBOARD');
    if useclip and useclipwin then begin
      s:=TempS(65535);
      ClipToFile(s);
    end else
    if useclip and (s='WIN-CLIPBOARD (MAIL)') then begin     { Markierten Text als Mailadresse}
      s:=mailstring(getline,false);
      string2clip(s);                                        { ins Clipboard }
      ReadFilename:=false;
      exit;
    end else
    if useclip and (s='WIN-CLIPBOARD (URL)') then begin      { Markierten Text als URL}
      s:=getline;
      y:=pos('HTTP://',ustr(s));                             {WWW URL ?}
      if y=0 then y:=pos('HTTPS://',ustr(s));                {HTTP Sec.?}
      if y=0 then y:=pos('FTP://',ustr(s));                  {oder FTP ?}
      if y=0 then y:=pos('WWW.',ustr(s));                    {oder WWW URL ohne HTTP:? }
      if y<>0 then begin
        s:=mid(s,y);
        y:=1;
        while (y<=length(s)) and (s[y] in urlchars) do inc(y); {Ende der URL suchen...}
        s:=left(s,y-1);
      end;
      string2clip(s);
      ReadFilename:=false;
      exit;
    end else
      useclip:=false;
    if (trim(s)='') or ((length(s)=2) and (s[2]=':')) or (right(s,1)='\')
    then
      s:=s+'*.*'
    else
    if IsPath(s) then s:=s+'\*.*';
    file_box(s,subs);
    if (s<>'') and (IsDevice(s) or not ValidFilename(s)) then begin
      rfehler(3);   { Ung�ltiger Pfad- oder Dateiname! }
      s:='';
    end;
    ReadFilename:=(s<>'');
  end
  else begin
    ReadFilename:=false;
    UseClip:=false;
  end;
end;


{ Dateinamen abfragen. Wenn Esc gedr�ckt wird, ist s undefiniert! }
function ReadFilename2(txt:atext; var s:pathstr; subs:boolean):boolean;
var x,y    : byte;
    fn     : string[20];
    brk    : boolean;
    bl     : boolean;
    bin    : boolean;
    dir    : pathstr;
    name   : pathstr;
begin
  fn:=getres(106);
  dialog(45-19+length(fn),3,txt,x,y);
  bin:=(txt=getres(613));
  bl:=(pos('block',lstr(txt))<>0);
  
  dir:=GetFileDir(s);
  name:=GetBareFileName(s)+'.COL';
  
  maddstring(3,2,fn,name,13,12,'');   { Dateiname: }
  readmask(brk);
  enddialog;
  if not brk then begin
    s:=dir+GetBareFileName(name)+'.COL';
    UpString(s);
    file_box(s,subs);
    if (s<>'') and (IsDevice(s) or not ValidFilename(s)) then begin
      rfehler(3);   { Ung�ltiger Pfad- oder Dateiname! }
      s:=''
    end;
    ReadFilename2:=(s<>'')
  end else ReadFilename2:=false
end;


function overwrite(fname:pathstr; replace:boolean; var brk:boolean):boolean;
var x,y : byte;
    nr  : shortint;
    t   : taste;
    f   : file;
    w   : rtlword;
begin
  assign(f,fname);
  getfattr(f,w);
  if w and readonly<>0 then begin
    rfehler(9);        { 'Datei ist schreibgesch�tzt.' }
    brk:=true;
    exit;
  end;
  diabox(57,5,'',x,y);
  mwrt(x+2,y+1,ustr(fitpath(fname,28))+getres(117));  { ' ist bereits vorhanden.' }
  t:='';
  pushhp(76);
  nr:=readbutton(x+2,y+3,2,getres(118),iif(replace,2,1),true,t);  { ' ^Anh�ngen , ^�berschreiben , A^bbruch ' }
  pophp;
  closebox;
  overwrite:=(nr=2);
  if nr=2 then
  begin    { Datei l�schen -> evtl. Undelete m�glich }
    setfattr(f,0);
    erase(f);
    if ioresult<>0 then
    begin { Michael Koppel und MK 07.01.2000 Abbruch, wenn Datei
      nicht gel�scht werden kann, weil z.B. von anderem Prog. ge�ffnet }
      rfehler(9);        { 'Datei ist schreibgesch�tzt.' }
      brk:=true;
      exit;
    end;
  end;
  brk:=(nr=0) or (nr=3);
end;

procedure listExt(var t:taste);
var s     : string;
    all   : boolean;
    b     : byte;
    ok    : boolean;
    fname : pathstr;
    _append: boolean;
    tt    : text;
    brk   : boolean;
    c     : char;
    useclip: boolean;
    nr    : longint;
    i     : integer;

  procedure msgrequest(otherbox:boolean);
  var
    nt   : byte;
    i    : integer;
    s1   : string[MidLen];
    box  : string[boxnamelen];
    ungueltig : longint;
    _markanz  : longint;
    idfound   : boolean;
    request   : boolean;
    brkreq    : boolean;
    mid_ok    : boolean;

    function getbfn(bn:string):string;
    var
      d : db;
    begin
      dbOpen(d,BoxenFile,1);
      dbSeek(d,boiName,ustr(bn));
      if dbFound then begin
        getbfn:=dbReadStr(d,'dateiname');
        dbRead(d,'netztyp',nt);
      end else getbfn:=left(ustr(bn),8);
      dbClose(d);
    end;

  begin
    s1:=getline;
    brkreq:=true;
    if (list_markanz=0) and ((pos('@',s1)=0) or (s1='')) then begin
      fehler(getres(172)); { 'Keine g�ltige Message-ID markiert' }
      exit;
    end;
    if otherbox then begin
       box:=UniSel(1,false,DefaultBox);
       box:=getbfn(box);
    end else box:='!';
    if box='' then
      { 'Markierte Nachrichten beim ersten erreichbaren Server holen?' }
      if readjn(getres(345),false) then box:='*'
    else exit;
    if otherbox and (box<>'*') and (nt<>nt_PPP) then begin
      fehler(getres(170)); {'Diese Funktion wird nur bei RFC/PPP-Boxtypen unterst�tzt'}
      exit;
    end;
    if (not otherbox) and (box<>'*') then begin  { Keine Box ausgew�hlt?   }
      dbReadN(mbase,mb_brett,box);
      dbSeek(bbase,BiIntnr,copy(box,2,4));
      dbReadN(bbase,bb_pollbox,box);      { Pollbox des Brettes     }
      box:=getbfn(box);                   { BoxFileName formen      }
      if nt<>nt_PPP then begin
        fehler(getres(170)); {'Diese Funktion wird nur bei RFC/PPP-Boxtypen unterst�tzt'}
        exit;
      end;
    end;
    _markanz:=list_markanz;
    ungueltig:=0;
    request:=false;
    brkreq:=false;
    reqfname:=ownpath+midreqfile;
    assign(reqfile,reqfname);
    if not exist(reqfname) then rewrite(reqfile) else reset(reqfile);
    repeat
      dec(_markanz);
      idfound:=false;
      if ShowHdr then
        mid_ok:=((pos('MID:',s1)=1) or (pos('BEZ:',s1)=1)) else
        mid_ok:=(pos('@',s1)<>0);
      s1:=mailstring(s1,false);
      if mid_ok and (pos('@',s1)<>0) then begin
        if s1[1]<>'<' then s1:='<'+s1;
        if s1[length(s1)]<>'>' then s1:=s1+'>';
        for i:=1 to filesize(reqfile) do begin
          read(reqfile,midrec);
          if (midrec.aktiv<>0) and (midrec.mid=s1) then begin
            idfound:=true;
            { Der User w�rde nicht erkennen, das einige Anforderungen
              schon existierten und diese nun storniert wurden, wenn
              er mehr als eine markiert hat: Deshalb mu� er gefragt werden! }
            if ReadJN(getres(137),false) then begin { 'Anforderung besteht bereits. Stornieren' }
              seek(reqfile,i-1);
              midrec.aktiv:=0;
              midrec.zustand:=0;
              midrec.box:='';
              midrec.mid:='';
              write(reqfile,midrec);
            end;
            break;
          end;
        end;
        if not idfound then begin
          seek(reqfile,filesize(reqfile));      { eof }
          midrec.aktiv:=1;
          midrec.zustand:=0;
          midrec.box:=box;
          midrec.mid:=s1;
          write(reqfile,midrec);
          request:=true;
        end;
      end else inc(ungueltig);
      s1:=next_marked;
      seek(reqfile,0);                          { bof }
    until (_markanz<=0) or (s1=#0);
    close(reqfile);
    if ungueltig<>0 then fehler(getres(171)); { 'Ung�ltige Message-ID erkannt' }
    if request then begin
      rmessage(479);  { 'Angeforderte Nachrichten werden beim n�chsten Netcall requestet' }
      wkey(1,false);
      closebox;
      t:=^E;
    end else
    if (not brkreq) and (((ungueltig<>list_markanz) and (list_markanz<>0)) or
       ((list_markanz=0) and mid_ok)) then begin
      rmessage(481); { 'Anforderung existiert bereits' }
      wkey(1,false);
      closebox;
    end;
  end;

  procedure ex(i:shortint);
  begin
    listexit:=i;
    t:=keyesc;
  end;

{JG:28.01.00}
  procedure ShowfromLister;
  begin
    showscreen(true);      {Menuepunkte die Probleme machen koennten deaktivieren:}

    setenable(0,1,false);  {XPOINT}
    setenable(0,2,false);  {Wartung}
    setenable(0,4,false);  {Netcall}
    setenable(0,5,false);  {Fido}
    setenable(0,6,false);  {Edit}
    setenable(0,7,false);  {Config}
    setenable(3,8,false);  {Nachricht/Brettmannager}
    setenable(3,9,false);  {N/Fileserver}
    setenable(3,11,false); {N/Direkt}

    attrtxt(col.ColKeys);
    mwrt(screenwidth-9,screenlines,' Lister ! ');
    attrtxt(col.ColMenu[0]);
    mwrt(1,1,dup(Screenwidth,' '));
    normtxt;

    select(11);            {Suchergebnis zeigen}

    setenable(0,1,true);   {XPOINT wieder einschalten}
    setenable(0,2,true);   {Wartung}
    setenable(0,4,true);   {Netcall}
    setenable(0,5,true);   {Fido}
    setenable(0,6,true);   {Edit}
    setenable(0,7,true);   {Config}
    setenable(3,8,true);   {Nachricht/Brettmannager}
    setenable(3,9,true);   {N/Fileserver}
    setenable(3,11,true);  {N/Direkt}
    ex(5);
  end;
{/JG}

begin
  if listmakros<>0 then begin
    if t=keyf6 then Makroliste(iif(listmakros=8,4,5));
    Xmakro(t,ListMakros);
  end;
  c:=t[1];
  if (UpCase(c)=k4_D) or (deutsch and (UpCase(c)='D')) then begin   { ^D }
    rmessage(119);   { 'Ausdruck l�uft...' }
    InitPrinter;
    all:=(list_markanz=0);
    if all then s:=first_line else s:=first_marked;
    while checklst and (s<>#0) do begin
      PrintLine(s);
      if all then s:=next_line else s:=next_marked;
    end;
    ExitPrinter;
    closebox;
  end;
  if UpCase(c)=k4_W then begin                           { 'W' }
    fname:=DefaultSavefile;
    pushhp(74);
    useclip:=true;
    ok:=ReadFileName(getres(120),fname,true,useclip);  { 'Text in Datei schreiben' }
    pophp;
    if ok then begin
      if (pos('\',fname)=0) and (pos(':',fname)=0) then
        fname:=extractpath+fname;
      while cpos('/',fname)>0 do
        fname[cpos('/',fname)]:='\';
      if not validfilename(fname) then begin
        rfehler(316);   { 'Ung�ltiger Pfad- oder Dateiname!' }
        exit;
      end;
      if exist(fname) and not useclip then
        _append:=not Overwrite(fname,false,brk)
      else begin
        _append:=false;
        brk:=false;
      end;
      if not brk then begin
        assign(tt,fname);
        if _append then append(tt) else rewrite(tt);
        all:=(list_markanz=0);
        if all then s:=first_line else s:=first_marked;
        while s<>#0 do begin
          writeln(tt,s);
          if all then s:=next_line else s:=next_marked;
        end;
        close(tt);
        if useclip then WriteClipfile(fname);
      end else if useclip then _era(fname);
    end;
  end;

  if t=k2_R then msgrequest(false);        { 'r' Message-ID Request }
  if t=k2_SR then msgrequest(true);        { 'R' Message-ID Request }

  if UpCase(c)=k4_F then                                 { 'F' }
    ListXHighlight:=not ListXHighlight;

  if c = ^W then
  begin
    ListWrap := not ListWrap;
    ListWrapToggle := true;
    ex(-4);
  end;
  
  if Listmakros=8 then    {Diese Funktionen NUR im Lister ausfuehren, nicht im Archivviewer... }
  begin
    if upcase(c)='I' then msg_info;                        { 'I' fuer Lister }
    if upcase(c)='O' then begin                            { 'O' fuer Lister }
      ShowHeader;
      ex(5);
    end;
    if upcase(c)='Q' then                                  {'Q' Quotechars |: aktivieren}
      otherquotechars:=not otherquotechars;
  end;

  if markaktiv and {(aktdispmode=12) and} ((t=keyaltm) or (t=keyaltv)
     or (t=keyaltb) or (t=keyaltu))
  then hinweis(getres(136)) { 'Suchfunktion bei aktiver Liste markierter Nachrichten nicht m�glich!' }
  else begin

    nr:=dbRecno(mbase);

    if t = keyaltm then begin                                 { ALT+M = Suche MessageID }
      s:=mailstring(getline,false);
      if (pos('BEZ:',s)=1) or (pos('MID:',s)=1) then
        s:=copy(s,6,length(s)-5);
      if Suche(getres(437),'MsgID',s) then ShowfromLister;    { gefundene Nachr. zeigen }
    end;

    if t = keyaltv then begin                                 { ALT+V = Suche text }
      s:=getline;
      if Suche(getres(414),'',s) then Showfromlister;
    end;

    if t = keyaltb then begin                                  { Alt+B = Betreff }
      s:=getline;
      if s='' then s:=dbreadstr(mbase,'Betreff');
      if Suche(getres(415),'Betreff',s) then Showfromlister;
    end;

    if t = keyaltu then begin                                  { Alt+U = User }
      s:=mailstring(getline,false);
      if s='' then s:=dbreadstr(mbase,'Absender');
      if Suche(getres(416),'Absender',s) then Showfromlister;
    end;

    dbGo(mbase,nr);

  end;

  if listmakros=16 then   { Archiv-Viewer }
    if t=mausldouble then t:=keycr;

  if llh then begin
    if (t=keydel) or (ustr(t)=k4_L) or (t=k4_cL) then begin   { 'L' / ^L }
      b:=2;
      dbWriteN(mbase,mb_halteflags,b);
      if t=k4_cL then begin
        rmessage(121);   { 'Nachricht ist auf ''l�schen'' gesetzt.' }
        wkey(1,false);
        closebox;
      end else t:=keyesc;
    end else
    if (t=keyins) or (ustr(t)=k4_H) then begin         { 'H' }
      b:=1;
      dbWriteN(mbase,mb_halteflags,b);
      rmessage(122);   { 'Nachricht ist auf ''halten'' gesetzt.' }
      wkey(1,false);
      closebox;
    end else
    if (t=keybs) then begin
      NachWeiter:=false;
      t:=keyesc;
    end else
    if c=^K then kludges:=not kludges else
    if (c='-') or (upcase(c)='G') then ex(-1) else
    if c='+' then ex(1) else
    if (c=k2_p) or (c=k2_b) or
       ((listmakros<>16) and ((c=k2_cB) or (c=k2_cP) or (c=k2_cQ))) then
    begin
      ListKey:=t;
      if ((c=k2_cB) or (c=k2_cQ) or (c=k2_cP)) and (list_markanz>0) then begin
        ListQuoteMsg:=TempS(dbReadInt(mbase,'msgsize'));
        assign(tt,ListQuoteMsg);
        rewrite(tt);

{ Die Quote-Routine von XP erh�lt immer eine Nachricht mit Header und
  wirft den Header vor dem Quoten weg. Wenn nur einige markierte Zeilen
  zitiert werden sollen, kann nicht die komplette Nachricht mit Header
  extrahiert und an den Quoter �bergeben werden. Stattdessen wird vor
  dem extrahieren der markierten Zeilen ein Dummy-Header erzeugt. Die
  acht Leerzeilen sind ein Dummy-Header im alten Z-Netz-Format ("Z2.8"). }

        if ntZConnect(mbNetztyp) then begin  { Dummy-ZC-Header erzeugen }
          writeln(tt,'Dummy: das ist ein Dummy-Header');
          writeln(tt);
        end else for i:=1 to 8 do writeln(tt);

        s:=first_marked;
        nr:=current_linenr;
        while s<>#0 do begin
          writeln(tt,s);
          s:=next_marked;
          if current_linenr>nr+1 then writeln(tt,#3);
          nr:=current_linenr;
        end;
        close(tt);
      end;
      ex(4);
    end else if listkommentar then
    if t=keyleft then ex(2) else
    if t=keyrght then ex(3) else
    if t=keycpgu then ex(6) else
    if t=keycpgd then ex(7) else
    if t='0' then ex(5);
  end;
end;

procedure ExtListKeys;
begin
  case errorlevel of
    100 : listexit:=-1;   { - }
    101 : listexit:=1;    { + }
    102 : listexit:=2;    { links }
    103 : listexit:=3;    { rechts }
    104 : begin
            listexit:=4; listkey:=k2_b;
          end;
    105 : begin
            listexit:=4; listkey:=k2_p;
          end;
    106 : begin
            listexit:=4; listkey:=k2_cB;
          end;
    107 : begin
            listexit:=4; listkey:=k2_cP;
          end;
    108 : listexit:=5;    { 0 }
    109 : listexit:=6;    { PgUp }
    110 : listexit:=7;    { PgDn }
  end;
end;



function filecopy(fn1,fn2:pathstr):boolean;
var f1,f2 : file;
    time  : longint;
    res   : integer;
begin
  if (fexpand(fn1)=fexpand(fn2)) and exist(fn1) then
  begin
    filecopy:=true;
    exit;
  end;

  { 07.01.2000 oh
    Wo nichts ist, braucht auch nichts kopiert werden. Folgender Fix
    vermeidet die Fehlermeldung 'Fehler %s beim Kopieren von %s'
    beim Sysop-Poll ohne vorhandenen Ausgangspuffer:
    07.01.2000 MK
    byte(fn[0]) Referenzen in length(fn) ge�ndert, Source formatiert
  }
  if not exist(fn1) then { Datei fehlt! }
    if length(fn1)>2 then { Dateiname>2 Zeichen? }
    { Datei ist Ausgangspuffer: }
    if UStr(copy(fn1,length(fn1)-2,3))='.PP' then
    begin
      filecopy:=false;
      exit;
    end;
  { /oh }

  assign(f1,fn1);
  reset(f1,1);
  getftime(f1,time);
  assign(f2,fn2);
  rewrite(f2,1);
  fmove(f1,f2);
  setftime(f2,time);
  close(f1); close(f2);
  filecopy:=(inoutres=0);
  if inoutres<>0 then begin
    res:=ioresult;
    tfehler(ioerror(res,
       reps(getreps(123,strs(res)),fileio.getfilename(fn1))),errortimeout);
                                 { 'Fehler %s beim Kopieren von %s' }
  end;
end;


function GetDecomp(atyp:shortint; var decomp:string):boolean;
begin
  with unpacker^ do
    case atyp of
      1 : decomp:=UnARC;
      2 : decomp:=UnLZH;
      3 : decomp:=UnZOO;
      4 : decomp:=UnZIP;
      5 : decomp:=UnARJ;
      6 : decomp:=UnPAK;
      7 : decomp:=UnDWC;
      8 : decomp:=UnHYP;
      9 : decomp:=UnSQZ;
     10 : decomp:='tar -xvf $ARCHIV $DATEI';
     11 : decomp:=UnRAR;
     12 : decomp:='uc e $ARCHIV $DATEI';
    else begin  { ?? }
      getDecomp:=false;
      decomp:=''; exit;
    end;
  end;
  if (pos('$DATEI',ustr(decomp))=0) or (pos('$ARCHIV',ustr(decomp))=0) then begin
    rfehler1(8,arcname[atyp]);   { 'Die Einstellung des %s-Entpacker ist fehlerhaft' }
    getDecomp:=false;
  end else getdecomp:=true;
end;


function UniExtract(_from,_to,dateien:pathstr):boolean;
var decomp : pathstr;
    atyp   : shortint;
    p      : byte;
begin
  UniExtract:=false;
  atyp:=ArcType(_from);
  if atyp=0 then exit;
  GoDir(_to);
  if not GetDecomp(atyp,decomp) then exit;
  p:=pos('$ARCHIV',ustr(decomp));
  decomp:=left(decomp,p-1)+_from+mid(decomp,p+7);
  p:=pos('$DATEI',ustr(decomp));
  shell(left(decomp,p-1)+dateien+mid(decomp,p+6),400,3);
  if not exist(_to+dateien) then
    tfehler('Datei(en) wurde(n) nicht korrekt entpackt!',errortimeout)
  else
    UniExtract:=true;
end;


procedure AddBezug(var hd:header; dateadd:byte);
var c1,c2 : longint;
    satz  : longint;
    datum : longint;
    empfnr: byte;
begin
  if ntKomkette(hd.netztyp) and (hd.msgid<>'') then begin
    c1:=MsgidIndex(hd.msgid);
    if hd.ref='' then c2:=0
    else c2:=MsgidIndex(hd.ref);
    dbAppend(bezbase);           { s. auch XP3O.Bezugsverkettung }
    satz:=dbRecno(mbase);
    dbWriteN(bezbase,bezb_msgpos,satz);
    dbWriteN(bezbase,bezb_msgid,c1);
    dbWriteN(bezbase,bezb_ref,c2);
    dbReadN(mbase,mb_origdatum,datum);
    datum:=datum and $fffffff0;  { Bit 0-3 l�schen }
    if dateadd>0 then
      inc(datum,dateadd)
    else begin
      empfnr:=dbReadInt(mbase,'netztyp') shr 24;
      if empfnr>0 then inc(datum,iif(empfnr=1,1,2));
    end;
    dbWriteN(bezbase,bezb_datum,datum);
  end;
end;


function KK:boolean;
begin
  KK:=ntKomkette(dbReadInt(mbase,'netztyp')and $ff) and
     (dbReadStr(mbase,'msgid')<>'');
end;

function HasRef:boolean;
begin
  dbSeek(bezbase,beiRef,left(dbReadStr(mbase,'msgid'),4));
  HasRef:=dbFound;
end;

procedure DelBezug;
var crc : string[4];
    pos : longint;
    mi  : shortint;
    ok  : boolean;
    nr  : byte;
    dat : longint;

  function MidOK:boolean;
  begin
    MidOK:=(dbLongStr(dbReadInt(bezbase,'msgid'))=crc);
  end;

  function DatOK:boolean;
  begin
    DatOK:=(dbReadInt(bezbase,'datum') and $fffffff0)=dat;
  end;

begin
  if KK then begin
    pos:=dbRecno(mbase);
    crc:=left(dbReadStr(mbase,'msgid'),4);
    mi:=dbGetIndex(bezbase); dbSetIndex(bezbase,beiMsgid);
    dbSeek(bezbase,beiMsgid,crc);
    ok:=dbfound;
    while ok and (dbReadInt(bezbase,'msgpos')<>pos) do begin
      dbNext(bezbase);
      ok:=not dbEOF(bezbase) and MidOK;
    end;
    if ok then begin
      nr:=dbReadInt(bezbase,'datum') and 3;
      dat:=dbReadInt(bezbase,'datum') and $fffffff0;
      dbDelete(bezbase);
      if nr=1 then begin        { erste Kopie eines CrossPostings }
        dbSeek(bezbase,beiMsgid,crc);
        if dbFound then begin
          while not dbEOF(bezbase) and not DatOK and MidOK do
            dbNext(bezbase);
          if not dbEOF(bezbase) and DatOK and MidOK and
             (dbReadInt(bezbase,'datum') and 3=2) then begin
            inc(dat);        { + 1 }
            dbWrite(bezbase,'datum',dat);
          end;
        end;
      end;
    end
    else if developer then begin
{$IFDEF VP }
      playsound(4000, 5);
{$ELSE }
      sound(4000); delay(5); nosound;
{$ENDIF }
    end;
    dbSetIndex(bezbase,mi);
  end;
end;


function GetBezug(var ref:string):longint;
var pos : longint;
begin
  dbSeek(bezbase,beiMsgid,dbLongStr(MsgidIndex(ref)));
  if dbFound then begin
    pos:=dbReadInt(bezbase,'msgpos');
    dbGo(mbase,pos);
    if dbDeleted(mbase,pos) then GetBezug:=0  else GetBezug:=pos;
  end else GetBezug:=0;
end;


function g_code(s:string):string;
var i : byte;
begin
  for i:=1 to length(s) do
    s[i]:=chr(byte(s[i]) xor (i mod 7));
  g_code:=s;
end;


procedure SeekLeftBox(var d:DB; var box:string);
begin
  if ((length(box)<=2) and (left(box,1)=left(DefFidoBox,1))) then
    box:=DefFidoBox;
  dbSeek(d,boiName,ustr(box));
  if not dbFound and (box<>'') and not dbEOF(d) and
     (ustr(left(dbReadStr(d,'boxname'),length(box)))=ustr(box)) then begin
    dbRead(d,'boxname',box);
    dbSeek(d,boiName,ustr(box));
  end;
end;


function FileDa(fn:pathstr):boolean;   { Programm im Pfad suchen }
var dir  : dirstr;
    name : namestr;
    ext  : extstr;
  function Find(fn:pathstr):boolean;
  begin
    Find:=Fsearch(fn,GetEnv('PATH'))<>'';
  end;
begin
  if cpos(' ',fn)>0 then fn:=left(fn,cpos(' ',fn)-1);
  fsplit(fn,dir,name,ext);
  if ustr(name+ext)='COPY' then
    fileda:=true
    else
    if ext<>'' then
      FileDa:=Find(fn)
    else
      FileDa:=Find(fn+'.exe') or Find(fn+'.com') or Find(fn+'.bat') or
              Find(fn+'.cmd');
end;


function ZCfiletime(var fn:pathstr):string;   { ZC-Dateidatum      }
var l  : longint;
    dt : datetime;
    f  : file;
begin
  assign(f,fn);
  reset(f,1);
  if ioresult<>0 then
    ZCfiletime:=''
  else begin
    getftime(f,l);
    close(f);
    unpacktime(l,dt);
    with dt do
      ZCfiletime:=formi(year,4)+formi(month,2)+formi(day,2)+
                  formi(hour,2)+formi(min,2)+formi(sec,2);
  end;
end;

{ MK 01/00 fn jetzt kein var-Parameter mehr }
procedure SetZCftime(fn:pathstr; var ddatum:string);
var dt : datetime;
    l  : longint;
    f  : file;
begin
  assign(f,fn);
  reset(f,1);
  if ioresult=0 then with dt do begin
    year:=ival(left(ddatum,4));
    month:=ival(copy(ddatum,5,2));
    day:=ival(copy(ddatum,7,2));
    hour:=ival(copy(ddatum,9,2));
    min:=ival(copy(ddatum,11,2));
    sec:=ival(copy(ddatum,13,2));
    packtime(dt,l);
    setftime(f,l);
    close(f);
  end;
end;


procedure KorrBoxname(var box:string);
var d : DB;
begin
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  if dbFound or
     (not dbEOF(d) and (ustr(left(dbReadStr(d,'boxname'),length(box)))=ustr(box)))
  then
    dbRead(d,'boxname',box);  { -> korrekte Schreibweise des Systemnamens }
  dbClose(d);
end;


function BoxFilename(var box:string):string;
var d : DB;
begin
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  if dbFound then BoxFilename:=dbReadStr(d,'dateiname')
  else BoxFilename:=ustr(box);
  dbClose(d);
end;


function testtelefon(var s:string):boolean;
var tele,tnr : string[TeleLen+1];
    p,n      : byte;
    ok       : boolean;
    endc     : set of char;
    errmsg   : boolean;
begin
  errmsg:=(firstchar(s)<>'�');
  if not errmsg then delfirst(s);
  repeat
    p:=pos('+49-0',s);
    if p>0 then delete(s,p+4,1);   { 0 aus +49-0 wegschneiden }
  until p=0;
  ok:=true;
  n:=0;
  if s<>'' then begin
    tele:=trim(s)+' ';
    repeat
      inc(n);
      p:=blankpos(tele);
      tnr:=left(tele,p-1);
      tele:=ltrim(mid(tele,p));
      endc:=['0'..'9'];
      if pos('V',tnr)>0 then include(endc,'Q');
      while firstchar(tnr) in ['V','F','B','P'] do delfirst(tnr);
      if (firstchar(tnr)<>'+') or not (lastchar(tnr) in endc) then ok:=false;
      if pos('+',mid(tnr,2))>0 then ok:=false;
    until tele='';
    if not ok and errmsg then rfehler(iif(n=1,211,212));
  end; { 'Telefonnummer(n) hat/haben falsches Format - s. Online-Hilfe!' }
  testtelefon:=ok;
end;


function IsKomCode(nr:longint):boolean;
begin
  if (nr>=4000) and (nr<=4199) then
    IsKomCode:=(nr-4000 in [10..14,26..30,32..48,50,51,53..66,68..83,87,
                            89,93..115,122..124,126..131,134,137..139,
                            153..162,164..191,193..199])
  else if (nr>=4200) and (nr<=4399) then
    IsKomCode:=(nr-4200 in [0,44..60,63,64,68,70,71,82..120,122..131,135,
                            136])
  else
    IsKomCode := (nr>14000) and (nr<15000);
end;


function IsOrgCode(nr:longint):boolean;
begin
  if (nr>=4000) and (nr<=4199) then
    IsOrgCode:=(nr-4000 in [15..25,31,49,52,67,84..86,88,90..92,116..121,
                            125,132,133,135,136,140..152,163,192])
  else if (nr>=4200) and (nr<=4399) then
    IsOrgCode:=(nr-4200 in [1..43,61,62,65,67,69,72..81,121,132,134])
  else
    IsOrgCode := (nr>13000) and (nr<14000);
end;


procedure ExpandTabs(fn1,fn2:string);
var t1,t2 : text;
    s     : string;
    buf   : array[1..1024] of byte;
    p     : byte;
begin
  assign(t1,fn1);
  settextbuf(t1,buf);
  if existf(t1) then begin
    reset(t1);
    assign(t2,fn2);
    rewrite(t2);
    while not eof(t1) do begin
      readln(t1,s);
      while (s[length(s)]=' ') do dec(byte(s[0]));  { Spaces wegschneiden }
      repeat
        p:=pos(#9,s);              { TABs expandieren }
        if p>0 then begin
          delete(s,p,1);
          insert(sp(8-(p-1)mod 8),s,p);
        end;
      until p=0;
      writeln(t2,s);
    end;
    close(t2);
    close(t1);
  end;
end;


{ externer Programmaufruf (vgl. xp1s.shell())               }
{                                                           }
{ Bei Windows-Programmen wird direkt �ber START gestartet.  }
{ Bei OS/2-Programmen wird OS2RUN.CMD erzeugt/gestartet.    }

function XPWinShell(prog:string; parfn:pathstr; space:word;
                    cls:shortint; Fileattach:boolean):boolean;
{ true, wenn kein DOS-Programm aufgerufen wurde }

  function PrepareExe:integer;    { Stack sparen }
  {
  R�ckgabewert: -1 Fehler
                 0 DOS-Programm
                 1 Windows-Programm
                 2 OS/2-Programm
  }
  var ext     : string[3];
      exepath,
      batfile : pathstr;
      et      : TExeType;
      win,os2,
      winnt   : boolean;
      t       : text;
  begin
    PrepareExe:=0;
    exepath:=left(prog,blankposx(prog)-1);
    ext:=GetFileExt(exepath);
    if ext='' then exepath:=exepath+'.exe';
    exepath:=fsearch(exepath,getenv('PATH'));
    if not stricmp(right(exepath,4),'.exe') then et:=ET_Unknown
      else et:=exetype(exepath);

    win := (et=ET_Win16) or (et=ET_Win32);
    os2 := (et=ET_OS2_16) or (et=ET_OS2_32);
    winnt:=win and (lstr(getenv('OS'))='windows_nt');

    if win then begin
      if Delviewtmp then
        if ustr(left(prog,5))<>'START' then prog:='start '+prog
      else begin
        if ustr(left(prog,6))='START ' then prog:=mid(prog,7);
        batfile:=TempExtFile(temppath,'wrun','.bat');
        assign(t,batfile);
        rewrite(t);
        writeln(t,'@echo off');
        writeln(t,'rem  Diese Datei wird von CrossPoint zum Starten von Windows-Viewern');
        writeln(t,'rem  aufgerufen (siehe Online-Hilfe zu /Edit/Viewer).');
        writeln(t);
        writeln(t,'echo Windows-Programm wird ausgef�hrt ...');
        writeln(t,'echo.');
        writeln(t,'start '+iifs(fileattach,'','/wait ')+prog);
        if not fileattach then writeln(t,'del '+parfn);
        writeln(t,'del '+batfile);
        close(t);
        if winnt then prog:='cmd /c start cmd /c '+batfile
        else prog:='start command /c '+batfile;
      end;
      PrepareExe:=1;
    end
    else if os2 then begin
      batfile:=TempExtFile('','os2r','.cmd');
      assign(t,batfile);
      rewrite(t);
      writeln(t,'@echo off');
      writeln(t,'rem  Diese Datei wird von CrossPoint zum Starten von OS/2-Viewern');
      writeln(t,'rem  aufgerufen (siehe Online-Hilfe zu /Edit/Viewer).');
      writeln(t);
      writeln(t,'echo OS/2-Programm wird ausgef�hrt ...');
      writeln(t,'echo.');
      writeln(t,prog);
      if not fileattach then writeln(t,'del '+parfn);
      writeln(t,'del '+ownpath+batfile);
      close(t);
      prog:=batfile;
      PrepareExe:=2;
    end;
  end;

begin
  XPWinShell:=true;
  case PrepareExe of
     0 : begin                      { DOS-Programm aufrufen }
           shell(prog,space,cls);
           XPWinShell:=false;
         end;
     1 : shell(prog,space,0);       { Windows-Programm aufrufen }
  {$IFDEF BP}
     2 : Start_OS2(ownpath+prog,'','XP-View OS/2'); { OS/2-Programm aufrufen }
  {$else}
    {$ifdef os2}
     2 : shell(ownpath+prog,space,0);
    {$endif}
  {$ENDIF}
  end;
end;

end.
{
  $Log: xp1o.pas,v $
  Revision 1.55  2002/06/05 18:08:11  mm
  - Urlchars um ';' erweitert
  - Stringlaenge in ReadFilename von 78 auf 255 angehoben

  Revision 1.54  2001/12/22 14:36:31  mm
  - Urlchars um '+' und ',' ergaenzt
  - ListWrapToggle: mittels Ctrl-W kann im Lister und Archiv-Viewer der
    automatische Wortumbruch nicht-permanent umgeschaltet werden
    (Dank an Michael Heydekamp)

  Revision 1.53  2001/12/03 18:35:50  MH
  - Fix: AltU, AltB (Suche) konnte bei Widerholung mit Datenbankfehler
         austeigen (JG)

  Revision 1.52  2001/07/15 22:29:38  MH
  - auch CMD f�r FileDa akzeptieren

  Revision 1.51  2001/06/22 18:18:54  MH
  - User-, Betreff- MsgID-Suche mu� w�hrend Nachrichten bereits schon
    durch eine vorherige Suche im Lister sich befinden verhindert werden

  Revision 1.50  2001/06/18 20:17:24  oh
  Teames -> Teams

  Revision 1.49  2001/04/04 19:57:00  oh
  -Timeouts konfigurierbar

  Revision 1.48  2001/03/22 20:35:33  oh
  -Farbprofile update

  Revision 1.47  2000/12/31 17:12:52  MH
  Fix:
  - Clipboard (url,mail) jetzt auch in DispMode 10,11,12

  Revision 1.46  2000/12/25 17:14:53  MH
  Fix Editor:
  - ^Kw F2 -> Clipboard funktionierte nicht

  Revision 1.45  2000/11/19 17:14:19  MH
  Message-ID Request:
  - Stornierung erm�glicht

  Revision 1.44  2000/11/19 10:30:24  MH
  Message-Request-Editor implementiert
  - First version...

  Revision 1.43  2000/11/01 02:24:07  rb
  URL-Erkennung ge�ndert

  Revision 1.42  2000/10/26 17:13:49  rb
  Kommentar war zu lang, grmbls ...

  Revision 1.41  2000/10/25 21:09:36  rb
  JG: Suchfunktionen (Alt-M, -V, -B, -U) im Kommentarbaum bei aktiver Liste
      markierter Nachrichten abgeschaltet

  Revision 1.40  2000/10/07 20:23:28  rb
  Bugfix: externer OS/2-Viewer l�scht Fileattach nicht mehr

  Revision 1.39  2000/10/07 13:17:12  MH
  HDO: Kleinere Detailverbesserung (Fix):
  - BoxFileName ben�tigt nur einen Zugriff

  Revision 1.38  2000/10/05 16:20:46  MH
  Msg-ID Req.: Bei ShowHeader verbesserte Erkennung f. Mid

  Revision 1.37  2000/10/05 16:00:43  MH
  Msg-ID Req.: �berarbeitet...

  Revision 1.36  2000/10/03 08:47:56  MH
  - File schliessen vergessen...grrr

  Revision 1.35  2000/10/03 08:42:58  MH
  - Bei verschiedenen Funktionen wird eine Zeile vom Markierbalken
    gelesen, auch wenn nicht markiert wurde
  - Fix (MsgID-Req.): War der Markierbalken aktiv, kam eine Falsch-Meldung

  Revision 1.34  2000/10/03 07:59:27  MH
  Clipboard angepasst

  Revision 1.33  2000/10/01 18:36:03  MH
  - Code aufger�umt

  Revision 1.32  2000/10/01 15:23:36  MH
  HDO: Kleinere Detailverbesserungen:
  - Meldungen k�nnen vor Zeitablauf durch Tastendruck
    abgebrochen werden

  Revision 1.31  2000/10/01 11:47:11  MH
  HDO: Kleinere Korekturen vorgenommen

  Revision 1.30  2000/09/30 13:37:09  MH
  MsgID-Req.: Fehler melden, wenn Boxtyp nicht RFC/PPP

  Revision 1.29  2000/09/30 10:40:19  MH
  HDO/MidReq:
  - Weitere Meldung hinzugef�gt

  Revision 1.28  2000/09/30 08:14:28  MH
  Message-ID Request:
  - Funktioniert nun auch ohne Markierung

  Revision 1.27  2000/09/29 22:06:23  MH
  Message-ID Request:
  - Eine Meldung wird ausgegeben, wenn Nachrichten angefordert wurden

  Revision 1.26  2000/09/29 11:47:04  MH
  HDO:
  - Filename nun in XP0 definiert

  Revision 1.25  2000/09/28 21:22:29  MH
  HDO:
  - Mail-Request hinzugef�gt
  - Neuer Filename: REQUEST.ID (gilt f�r Mail und News)

  Revision 1.24  2000/09/26 21:23:51  MH
  Fix: MsgID-Req.: Aktiv-Byte wurde nicht beachtet

  Revision 1.23  2000/09/26 17:20:38  MH
  Message-ID Request: Dupecheck implementiert

  Revision 1.22  2000/09/24 00:42:05  MH
  Requester nun auf R-Taste (deutsch) und G-Taste (englisch)

  Revision 1.21  2000/09/23 21:00:44  MH
  HdrOnly und MsgID-Request:
  - beide im neuen Format: NEWS.ID
  - HdrOnly kann mit F3 ohne Boxauswahl bestellt und abbestellt werden
  - MsgID kann mit F3 ohne Boxauswahl bestellt werden
  - Shift+F3 = Boxauswahl

  Revision 1.20  2000/09/15 19:24:32  rb
  externe Viewer bei der OS/2 Version provisorisch reingeflickt

  Revision 1.19  2000/09/12 18:29:30  MH
  HdrOnly-/MessageID-Request:
  Resource ge�ndert

  Revision 1.18  2000/09/11 17:44:35  MH
  HdrOnlyRequest: Detailverbesserung:
  Einen Dialog bei Abbruch hinzugef�gt

  Revision 1.17  2000/09/03 15:52:47  MH
  Einige Anpassungen an Variablen vorgenommen

  Revision 1.16  2000/09/02 10:44:06  MH
  Filehandling korrigiert

  Revision 1.15  2000/08/29 16:45:14  MH
  Message-ID Request nun �ber F3 zu erreichen

  Revision 1.14  2000/08/21 23:01:21  oh
  Defaultfile bei W im Lister

  Revision 1.13  2000/08/21 18:04:02  MH
  Message-ID Request in den Resourcen aufgenommen

  Revision 1.12  2000/08/20 01:56:15  MH
  Message-ID Request: Jetzt auch ohne Clipboard verwendbar

  Revision 1.11  2000/08/19 15:43:06  MH
  Message-ID Request kann nun mehrere ID's �bernehmen

  Revision 1.10  2000/08/18 14:59:47  MH
  RFC/PPP: Message-ID Request: Reihenfolge im Men� ge�ndert

  Revision 1.9  2000/08/13 05:10:36  MH
  RFC/PPP: Message-ID Request:
  Zur Sicherheit verwenden wir die MailString-Routine

  Revision 1.8  2000/08/13 03:50:37  MH
  RFC/PPP: Message-ID Request:
  Meldung erscheint, wenn ID nicht erkannt werden kann

  Revision 1.7  2000/08/13 02:32:34  MH
  RFC/PPP: Message-ID Request implementiert

  Revision 1.6  2000/07/16 21:57:03  tj
  Sourceheader aktualisiert

  Revision 1.4  2000/04/09 18:21:11  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.32  2000/04/04 10:33:56  mk
  - Compilierbar mit Virtual Pascal 2.0

  Revision 1.31  2000/04/01 07:41:38  jg
  - "Q" im Lister schaltet otherquotechars (benutzen von | und :) um.
    neue Einstellung wird dann auch beim Quoten verwendet
  - Hilfe aktualisiert, und Englische Hilfe fuer
    Config/Optionen/Allgemeines auf Stand gebracht.

  - Externe-Viewer (Windows): "START" als Allroundviewer
    funktioniert jetzt auch mit der Loeschbatch-Variante
  - Text fuer MIME-Auswahl in englische Resource eingebaut

  Revision 1.30  2000/03/25 11:46:10  jg
  - Lister: Uhr wird jetzt auch bei freiem Nachrichtenkopf eingeblendet
  - Config/Optionen/Lister: Schalter ListUhr zum (de)aktivieren der Uhr

  Revision 1.29  2000/03/23 15:47:23  jg
  - Uhr im Vollbildlister aktiv
    (belegt jetzt 7 Byte (leerzeichen vorne und hinten)

  Revision 1.28  2000/03/14 15:15:38  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.27  2000/03/13 15:32:37  jg
  URL-Erkennung im Lister erkennt jetzt auch
  einen String der mit WWW. beginnt als URL an.

  Revision 1.26  2000/03/09 23:39:33  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.25  2000/03/07 17:45:14  jg
  - Viewer: Bei Dateien mit Leerzeichen im Namen wird
    grundsaetzlich ein .tmp File erzeugt
  - Env.Variable DELVTMP setzt jetzt nur noch beim Start
    die Globale Variable DELVIEWTMP

  Revision 1.24  2000/03/06 08:51:04  mk
  - OpenXP/32 ist jetzt Realitaet

  Revision 1.23  2000/03/04 18:34:18  jg
  - Externe Viewer: zum Ansehen von Fileattaches wird keine Temp-Kopie
    mehr erstellt, und nicht mehr gewartet, da kein Loeschen noetig ist

  Revision 1.22  2000/03/04 15:48:48  jg
  - Externe Windowsviewer, DELVTEMP-Modus:
    "start" wird nicht mehr zu "start start"
    Programmname wird wieder uebernommen.

  Revision 1.21  2000/03/04 12:39:36  jg
  - weitere Aenderungen fuer externe Windowsviewer
    Umgebungsvariable DELVTMP

  Revision 1.20  2000/03/04 11:07:32  jg
  - kleine Aenderungen am Tempfilehandling fuer externe Windowsviewer

  Revision 1.19  2000/03/03 20:26:40  rb
  Aufruf externer MIME-Viewer (Win, OS/2) wieder ge�ndert

  Revision 1.18  2000/03/02 21:39:01  rb
  Starten externer Windows-Viewer verbessert

  Revision 1.17  2000/03/02 21:19:51  jg
  - Uhr beim verlassen des Nachrichtenheaders eleganter deaktiviert

  Revision 1.16  2000/03/02 17:07:02  jg
  - Schoenheitsfix: bei "O" aus Vollbildlister
    wird Uhr nicht mehr aktiviert.

  Revision 1.15  2000/02/28 11:06:37  mk
  - Peters Kommentar zum Dummy-Quoten eingefuegt

  Revision 1.14  2000/02/26 18:14:46  jg
  - StrPCopy in Xp1s.inc integriert
  - Suche aus Archivviewer wieder zugelassen
    (zwecks Headereintregsuche im "O" Fenster)

  Revision 1.13  2000/02/25 22:19:52  rb
  Einbindung ext. Viewer (OS/2) verbessert

  Revision 1.12  2000/02/24 23:50:11  rb
  Aufruf externer Viewer bei OS/2 einigermassen sauber implementiert

  Revision 1.11  2000/02/23 23:49:47  rb
  'Dummy' kommentiert, Bugfix beim Aufruf von ext. Win+OS/2 Viewern

  Revision 1.10  2000/02/23 19:11:04  jg
  -Suchfunktionen im Lister benutzen Autosuche,
   "Global_Suchstring" und dessen auswertung entfernt.
  -!Todo.txt aktualisiiert

  Revision 1.9  2000/02/22 15:51:20  jg
  Bugfix f�r "O" im Lister/Archivviewer
  Fix f�r Zusatz/Archivviewer - Achivviewer-Macros jetzt aktiv
  O, I,  ALT+M, ALT+U, ALT+V, ALT+B nur noch im Lister g�ltig.
  Archivviewer-Macros g�ltig im MIME-Popup

  Revision 1.8  2000/02/21 15:07:55  mk
  MH: * Anzeige der eMail beim Nodelistbrowsen

  Revision 1.7  2000/02/17 08:40:29  mk
  RB: * Bug mit zurueckbleibenden Dummy-Header bei Quoten von Multipart beseitigt

  Revision 1.6  2000/02/15 21:19:24  mk
  JG: * Umlautkonvertierung von XP4O.Betreffsuche in Typeform verlagert
      * wenn man eine markierte Nachricht liest, wird beim Verlassen
        der Headeranzeige nicht gleich auch der Lister verlasssen
      * Die Suchfunktionen "Absender/User", "Betreff" und "Fidoempf�nger"
        k�nnen jetzt Umlautunabh�ngig geschalten werden

  Revision 1.5  2000/02/15 20:43:36  mk
  MK: Aktualisierung auf Stand 15.02.2000

}
