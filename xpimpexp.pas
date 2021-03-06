{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xpimpexp.pas,v 1.8 2001/07/22 12:07:05 MH Exp $ }

{ Import/Export }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xpimpexp;

interface

uses  xpglobal, {$IFDEF virtualpascal}sysutils,{$endif}
      dos,typeform,fileio,inout,maske,datadef,database,maus2,resource,
      xp0,xp1;


procedure ImportUserbase;     { X/Import/MB-Userbase }
procedure ImportMautauBase;   { X/Import/MauTau      }
procedure ImportYuppiebase;   { X/Import/Yuppie      }
procedure ImportQWKpacket;    { X/Import/QWK-Paket   }
procedure readfremdpuffer;    { X/Import/Fremdformat }

function imptestpollbox(var s:string):boolean;


implementation  { ----------------------------------------------------- }

uses  xp1o,xp1o2,xp3,xp3o,xp3o2,xpmaus,xp9bp,xp9,xpnt, winxp;

const mdaten = 'MDATEN.DAT';    { f�r ImportMautaubase }
      mindex = 'MDATEN.IND';
      outtmp = 'OUTFILE.TXT';

var   impnt  : byte;


{ USERBASE.DAT aus MessageBase einlesen :-) }

procedure ImportUserbase;

type ubrec = record
               nextfree  : longint;
               typ       : byte;    { 0=User, 1=Brett }
               aufnehmen : byte;
               name      : string[80];
               adresse   : string[80];
               haltezeit : byte;
               pollbox   : string[8];
               ablage    : byte;
               xx3       : byte;
               zielnetz  : byte;    { 1=Zerberus, 2=Magic }
              end;

var fn   : pathstr;
    brk  : boolean;
    x,y  : byte;
    f    : file of ubrec;
    r    : ubrec;
    grnr : longint;

    getuser,getbretter   : boolean;
    repluser,replbretter : boolean;

  procedure wrhalten(d:DB);
  var halten : integer16;
  begin
    halten:=r.haltezeit;
    dbWrite(d,'haltezeit',halten);
  end;

  procedure w0;
  begin
    savecursor;
    window(1,1,80,25);
  end;

  procedure w1;
  begin
    window(x+2,y+1,x+76,y+screenlines-8);
    restcursor;
  end;

begin
  if exist('userbase.dat') then         { Name bestimmen }
    fn:='userbase.dat'
  else begin
    dialog(51,7,'',x,y);
    maddtext(3,2,'Im '+xp_xp+'-Verzeichnis befindet sich keine',col.coldialog);
    maddtext(3,3,'USERBASE.DAT.  Bitte geben Sie den Namen Ihres',col.coldialog);
    maddtext(3,4,'MessageBase-Verzeichnisses an:',col.coldialog);
    fn:='';
    maddstring(3,6,'',fn,44,75,'');
    readmask(brk);
    closemask;
    closebox;
    if brk then exit;
    if (right(fn,1)<>'\') and (right(fn,1)<>':') then
      fn:=fn+'\';
    fn:=fn+'userbase.dat';
    if not exist(fn) then begin
      fehler('Ung�ltiges Verzeichnis oder keine USERBASE.DAT vorhanden!');
      exit;
      end;
    end;

  if _filesize(fn) mod sizeof(ubrec)<>0 then begin   { Dateiformat testen }
    fehler('Sorry. Unbekanntes Dateiformat.');
    exit;
    end;

  getuser:=(useraufnahme<2); getbretter:=true;      { Optionen abfragen }
  repluser:=true; replbretter:=true;
  dialog(40,7,'UserBase einlesen',x,y);
  maddbool(3,2,'User einlesen?      ',getuser);
  maddbool(3,3,'Bretter einlesen?   ',getbretter);

  maddbool(3,5,'vorhandene User �berschreiben? ',repluser);
  maddbool(3,6,'vorh. Bretter �berschreiben?   ',replbretter);
  readmask(brk);
  closemask; closebox;
  if brk then exit;

  msgbox(78,screenlines-6,'UserBase einlesen',x,y);   { Fenster aufmachen.. }
  window(x+2,y+1,x+76,y+screenlines-8);
  assign(f,fn);
  reset(f);
  read(f,r);    { Header �berlesen }
  while not eof(f) do begin                         { .. und einlesen }
    attrtxt(col.colmbox);
    read(f,r);
    with r do begin
      if nextfree=0 then begin
        name:=left(name,79);
        if (typ=1) and getbretter and
           (left(name,2)<>'/'#0) and (left(name,2)<>'/'#255) then begin
          moff;
          write(#13#10'Brett:  ',name);
          mon;
          name:='A'+name;
          dbSeek(bbase,biBrett,ustr(name));
          if not dbFound then begin
            dbAppend(bbase);
            dbWriteN(bbase,bb_brettname,name);
            w0;
            setbrettindex;
            w1;
            end;
          if not dbFound or replbretter then begin
            dbWriteN(bbase,bb_pollbox,pollbox);
            wrhalten(bbase);
            grnr:=NetzGruppe;
            dbWriteN(bbase,bb_gruppe,grnr);
            end;
          end;
        if (typ=0) and getuser and
           ((useraufnahme<>1) or ((pos('%',name)=0) and (pos(':',name)=0)))
        then begin
          if cpos('@',name)=0 then name:=left(name+'@'+DefaultBox+'.ZER',79);
          moff;
          write(#13#10'User:   ',name);
          mon;
          dbSeek(ubase,uiName,ustr(name));
          if not dbFound then begin
            dbAppend(ubase);
            dbWriteN(ubase,ub_username,name);
            end;
          if not dbFound or repluser then begin
            if name<>adresse then
              dbWriteX(ubase,'adresse',length(adresse)+1,adresse);
            dbWriteN(ubase,ub_pollbox,pollbox);
            wrhalten(ubase);
            dbWriteN(ubase,ub_userflags,aufnehmen);
            end;
          end;
        end;
      end;
    end;
  FlushClose;
  close(f);
  moff;
  writeln; writeln;
  write('Fertig!');
  mon;
  errsound; errsound;
  wkey(2,false);
  window(1,1,80,25);
  closebox;
  aufbau:=true;
end;


function imptestpollbox(var s:string):boolean;
var d : DB;
begin
  dbOpen(d,BoxenFile,1);
  SeekLeftBox(d,s);
  if dbFound then
    if (impnt<>nt_QWK) or (dbReadInt(d,'netztyp') in [nt_Fido,nt_QWK]) then
      imptestpollbox:=true
    else begin
      rfehler(2413);    { 'Falscher Netztyp - Netztyp mu� QWK oder Fido sein!' }
      imptestpollbox:=false;
      end
  else begin
    rfehler(2412);   { 'unbekannte Serverbox - w�hlen mit <F2>' }
    imptestpollbox:=false;
    end;
  dbClose(d);
end;


procedure readfremdpuffer;    { X/Import/Fremdformat }
var t   : text;
    s   : string[80];
    fn  : pathstr;
    nt  : shortint;
    x,y : byte;
    brk : boolean;
    d   : DB;
    box : string[BoxNameLen];
    red : boolean;
    eb  : boolean;
    useclip : boolean;
    ft  : longint;
begin
  if not exist('MAGGI.EXE') then begin
    rfehler(102);    { 'Netcallkonvertierer MAGGI.EXE fehlt!' }
    exit;
    end;
  if IsPath('PUFFER') then begin
    rfehler1(741,'PUFFER');
    exit;
    end;
  fn:='*.*';
  useclip:=false;
  if ReadFilename(getres(2420),fn,true,useclip)   { 'Nachrichtenpaket konvertieren/einlesen' }
  then
    if not exist(fn) then rfehler(106)
    else begin
      UpString(fn);
      if pos(ustr(MausLogfile),fn)>0 then begin
        box:='';  { dummy }
        MausLogFiles(0,false,box);
        MausLogFiles(2,false,box);
        exit;
        end;
      if pos(ustr(MausStLog),fn)>0 then begin
        box:=UniSel(1,false,'');
        if box<>'' then
          MausLogFiles(1,false,box);
        exit;
        end;
      if right(ustr(fn),4)='.QWK' then begin
        nt:=nt_QWK;
        if DefFidoBox<>'' then box:=DefFidoBox
        else box:='';
        end
      else begin
        assign(t,fn);
        reset(t);
        readln(t,s);
        close(t);
        if s=^A then nt:=nt_Magic else           { Puffertyp ermitteln }
        if cpos(#0,s)>0 then nt:=nt_Fido else
        if left(s,1)='#' then nt:=nt_Maus else
        if cpos('\',s)>0 then nt:=nt_Quick
        else nt:=nt_Netcall;
        if nt=nt_Fido then box:=DefFidoBox       { Vorgabe-Box ermitteln }
        else box:=DefaultBox;
        end;
      if (box='') or ((nt<>nt_Netcall) and (nt<>nt_Fido)) then begin
        dbOpen(d,BoxenFile,1);
        while not dbEOF(d) and (dbReadInt(d,'netztyp')<>nt) do
          dbNext(d);
        if not dbEOF(d) then dbRead(d,'boxname',box);
        dbClose(d);
        end;

      dialog(45,8,'',x,y);                     { Pollbox einlesen }
      maddtext(3,2,getres2(2421,1),0);         { 'Pufferdatei' }
      maddtext(4+length(getres2(2421,1)),2,fitpath(fn,28),col.coldiahigh);    { 'Ursprungsbox ' }
      MaddString(3,4,getres2(2421,2),box,BoxRealLen,BoxNameLen,'>'); mhnr(760);
      mappcustomsel(BoxSelproc,false);
      msetvfunc(imptestpollbox); impnt:=nt;
      red:=false; eb:=false;
      maddbool(3,6,getres2(2421,3),red);   { 'Empfangsdatum = Erstellungsdatum' }
      maddbool(3,7,getres2(2421,4),eb);    { 'Empfangsbest�tigungen verschicken' }
      readmask(brk);
      enddialog;
      if brk then exit;

      nt:=ntBoxNetztyp(box);                   { Puffer konvertieren }
      ReadBoxpar(nt,box);
      s:='PUFFER';
      case iif(impnt<>nt_QWK,nt,impnt) of
        nt_Magic : shell('MAGGI.EXE -mz -n'+boxpar^.MagicNET+' '+fn+' PUFFER '+
                         box+'.BL',300,3);
        nt_Quick,
        nt_GS    : shell('MAGGI.EXE -qz '+fn+' PUFFER',300,3);
        nt_Maus  : begin
                     ft:=filetime(box+'.itg');
                     shell('MAGGI.EXE -sz -b'+box+' -h'+boxpar^.MagicBrett+' '+
                         '-it '+fn+' PUFFER',300,3);
                   end;
        nt_Fido  : if not exist('ZFIDO.EXE') then begin
                     fehler('Netcallkonvertierer ZFIDO.EXE fehlt!');
                     exit;
                     end
                   else
                     shell('ZFIDO.EXE -fz -h'+BoxPar^.MagicBrett+' '+
                           iifs(KeepVia,'-via ','')+
                           fn+' PUFFER -w:'+strs(screenlines),300,3);
        nt_QWK   : if not exist('ZQWK.EXE') then
                     rfehler(2414)   { 'ZQWK.EXE fehlt! (ZQWK.EXE ist im getrennt erh�ltlichen QWK-Paket enthalten)' }
                   else begin
                     shell('ZQWK.EXE -qz -c'+BoxFilename(box)+' -b'+box+
                           ' -i'+fn+' -o'+GetFileDir(fn)+' -h'+BoxPar^.MagicBrett+
                           iifs(nt=nt_Fido,' -t30',''),600,1);
                     if errorlevel=100 then begin
                       errorlevel:=0;
                       s:=left(fn,length(fn)-4)+'.ZER';
                       end;
                     end;
        nt_Netcall,
        nt_ZConnect: begin
                       s:=fn;
                       errorlevel:=0;
                     end;
      else begin
        rfehler(2410);   { 'nicht unterst�tzter Netztyp' }
        exit;
        end;
      end;

      if errorlevel<>0 then
        if impnt=nt_QWK then begin
          if errorlevel in [90..110] then
            fehler(getres2(2422,4)+getres2(2422,errorlevel))  { 'Fehler bei ZQWK-Konvertierung:~ }
          else
            rfehler1(737,strs(errorlevel));  { 'ZQWK-Fehler Nr. %s bei Nachrichtenkonvertierung!' }
          freeres;
          end
        else
          rfehler(2411)   { 'Fehler bei Nachrichtenkonvertierung' }
      else begin
        if nt=nt_Maus then begin
          MausLogFiles(0,false,box);
          MausLogFiles(1,false,box);
          MausLogFiles(2,false,box);
          if filetime(box+'.itg')<>ft then
            MausImportITG(box);
          end;
        if PufferEinlesen(s,box,red,false,eb,iif(nt=nt_Fido,pe_ForcePfadbox,0))
        then begin
          if s='PUFFER' then _era(s);
          signal;
          end;
        end;
      end;
end;


{ --- nach MT2OUTF.PAS von Peter Redecker @ DO ------------------------ }

procedure MakeOutfile(var box:string; path:pathstr);
const EndOfLine = 13;
      EndOfMsg  = 10;
      bufsize   = 4096;
type  MsgITyp   = WORD;
      MsgCrcTyp = WORD;
      Msg_Index = RECORD
                    LfCrc: MsgCrcTyp;
                    HeaderSize,      { Header-Gr��e }
                    MsgSize: WORD;   { Msg-Gr��e in Bytes }
                    DIndex: LongINT;
                    KommentarZu,
                    Antwort,
                    RechteAntwort,
                    LinkeAntwort : MsgITyp;
                    AnzahlKommentare: BYTE;
                    Datum: LongINT;
                    Status: CHAR;
                    SDatum: LongINT;
                  END;
      buft      = array[0..bufsize-1] of byte;

var   daten    : FILE;
      index    : FILE OF Msg_Index;
      outfile  : TEXT;
      x,tempx  : msg_index;
      tempdatum: DateTime;
      was      : byte;
      mx,my    : byte;
      n        : longint;
      buf      : ^buft;
      bufpos,
      bufend   : word;
      rr       : word;

      textzeile,idzeile,gruppe,
      betreff,absender,empfaenger,vonzeile : ^string;
      seek_daten_merk,seek_index_merk      : longint;

  procedure ReadBuf;
  begin
    blockread(daten,buf^,bufsize,bufend);
    bufpos:=0;
  end;

  function zeile_auslesen(var letztes_zeichen:byte):string;
  var was,p    : byte;
      ergebnis : string;
  begin
    was:=0;
    p:=0;
    while (bufpos<bufend) and (was<>EndOfLine) and (was<>EndOfMsg) do begin
      was:=buf^[bufpos];
      inc(bufpos);
      if (bufpos=bufend) and not eof(daten) then
        ReadBuf;
      if (was<>EndOfLine) and (was<>EndOfMsg) and (p<255) then begin
        inc(p);
        ergebnis[p]:=chr(was);
        end;
      end;
    ergebnis[0]:=chr(p);
    letztes_zeichen:=was;
    zeile_auslesen:=ergebnis;
  end;

  procedure datum_ins_outfile(td:DateTime);
  begin
    with td do begin
      write(outfile,year:4);
      if month<10 then write(outfile,'0',month)
                  else write(outfile,month:2);
      if  day<10  then write(outfile,'0',day)
                  else write(outfile,day:2);
      IF  hour<10 then write(outfile,'0',hour)
                  else write(outfile,hour:2);
      IF  min<10  then writeln(outfile,'0',min)
                  else writeln(outfile,min:2);
      end;
  end;

BEGIN
  msgbox(37,5,'MauTau-Daten konvertieren',mx,my);
  wrt(mx+3,my+2,'bearbeitete Nachrichten:');
  n:=0;
  new(textzeile); new(idzeile); new(gruppe);
  new(betreff); new(absender); new(empfaenger); new(vonzeile);
  new(buf);
  bufpos:=0; bufend:=0;

  Assign(daten,path+mdaten); Reset(daten,1);
  Assign(index,path+mindex); Reset(index);
  Assign(outfile,outtmp);    Rewrite(outfile);
  while not eof(index) do begin
    read(index,x);
    Seek(daten,x.DIndex);
    ReadBuf;

    idzeile^   := zeile_auslesen(was);
    gruppe^    := zeile_auslesen(was);
    betreff^   := zeile_auslesen(was);
    absender^  := zeile_auslesen(was);
    if cpos('@',absender^)=0 then
      absender^:=absender^+' @ '+box;
    empfaenger^:= zeile_auslesen(was);
    if (empfaenger^<>'') and (cpos('@',empfaenger^)=0) then
      empfaenger^:=empfaenger^+' @ '+box;
    vonzeile^  := zeile_auslesen(was);
    inc(n);
    attrtxt(col.colmboxhigh);
    mwrt(mx+29,my+2,strs(n));

    writeln(outfile,'#',idzeile^);
    writeln(outfile,'V',absender^);
    IF gruppe^='PRIVAT' then writeln(outfile,'A',empfaenger^);
    writeln(outfile,'W',betreff^);
    UnPackTime(x.datum,tempdatum);
    write(outfile,'E');
    datum_ins_outfile(tempdatum);
    UnPackTime(x.SDatum,tempdatum);
    write(outfile,'B',upcase(x.status));
    datum_ins_outfile(tempdatum);

    if gruppe^<>'PRIVAT' then writeln(outfile,'G',gruppe^);
    if x.KommentarZu<>0 then begin
      seek_index_merk:=FilePos(index);
      seek_daten_merk:=FilePos(daten);
      Seek(index,x.KommentarZu);
      read(index,tempx);
      Seek(daten,tempx.DIndex);
      blockread(daten,idzeile^[1],40,rr);
      idzeile^[0]:=chr(rr);
      writeln(outfile,'-',left(idzeile^,cpos(#13,idzeile^)-1));
      Seek(daten,Seek_daten_merk);
      Seek(index,seek_index_merk);
      end;

    writeln(outfile,'>',vonzeile^);
    was:=0;
    while (bufpos<bufend) and (was<>EndOfMsg) do begin
      textzeile^:=zeile_auslesen(was);
      if was<>EndOfMsg then writeln(outfile,':',textzeile^);
      end;
    end;   { while not eof(index) }

  close(index);
  close(daten);
  close(outfile);
  dispose(buf);
  dispose(textzeile); dispose(idzeile); dispose(gruppe);
  dispose(betreff); dispose(absender); dispose(empfaenger);
  dispose(vonzeile);
  closebox;
end;


procedure ReadOutfile(var box:string);
begin
  ReadBoxPar(0,box);
  shell('MAGGI.EXE -sz -b'+box+' -h'+boxpar^.MagicBrett+' '+outtmp+' PUFFER',
        300,3);
  if errorlevel<>0 then
    fehler('Fehler bei Nachrichtenkonvertierung')
  else begin
    _era(outtmp);
    if PufferEinlesen('PUFFER',box,true,false,false,0) then
      _era('PUFFER');
    end;
end;


procedure ImportMautauBase;   { X/Import/MauTau }
var mtpath : pathstr;
    brk    : boolean;
    x,y    : byte;
    box    : string[boxnamelen];
begin
  if not mfehler(exist('MAGGI.EXE'),'MAGGI.EXE fehlt!') then begin
    dialog(51,9,'',x,y);
    maddtext(3,2,'Geben Sie den Namen der Box, f�r die die Daten',0);
    maddtext(3,3,'eingelesen werden sollen, und den Namen Ihres',0);
    maddtext(3,4,'MauTau-Verzeichnisses an:',0);
    mtpath:=''; box:='';
    maddstring(3,6,'Box   ',box,boxnamelen,boxnamelen,'>');
    mappcustomsel(boxselproc,false);
    msetvfunc(imptestpollbox);
    maddstring(3,8,'Verz. ',mtpath,35,75,'');
    readmask(brk);
    closemask;
    closebox;
    if brk or (mtpath='') then exit;
    if (right(mtpath,1)<>'\') then
      mtpath:=mtpath+'\';
    if not mfehler(ntBoxNetztyp(box)=nt_Maus,box+' ist keine MausNet-Box') and
       not mfehler(IsPath(mtpath),'ung�ltiges Verzeichnis') then begin
      if not exist(mtpath+mdaten) and IsPath(mtpath+'daten') then
        mtpath:=mtpath+'DATEN\';
      if not mfehler(exist(mtpath+mdaten),'In diesem Verzeichnis befindet sich keine MauTau-Datenbank.') and
         not mfehler(exist(mtpath+mindex),mtpath+mindex+' fehlt') and
         not mfehler(diskfree(0)>2.5*_filesize(mtpath+mdaten),
             'zu wenig freier Speicherplatz zum Einlesen der Daten') then
      begin
        MakeOutfile(box,mtpath);
        ReadOutfile(box);
        end;
      end;
    end;
end;


function FehlerFidoStammbox:boolean;
begin
  FehlerFidoStammbox:=mfehler(DefFidoBox<>'','Erst Fido-Stammbox w�hlen!') or
         mfehler(IsBox(DefFidoBox),'Ung�ltige Fido-Stammbox: '+DefFidoBox);
end;

procedure ImportYuppiebase;          { --- Yuppie-Import ----------------- }
var ypath : pathstr;
    brk   : boolean;
    x,y   : byte;

  function YupMailsize:longint;
  var sr  : searchrec;
      sum : longint;
  begin
    sum:=0;
    findfirst(ypath+'*.DBT',DOS.Archive,sr);
    while doserror=0 do begin
      inc(sum,sr.size);
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
    YupMailsize:=sum;
  end;

  procedure ImportYupbase;
  const TempPKT = '1.PKT';
  begin
    shell('YUP2PKT.EXE '+ypath+' '+TempPKT+' '+DefFidoBox,300,3);
    if not mfehler(errorlevel=0,'Fehler bei Nachrichtenkonvertierung') then begin
      ReadBoxPar(0,DefFidoBox);
      shell('ZFIDO.EXE -fz -h'+boxpar^.MagicBrett+' '+TempPKT+' PUFFER',300,3);
      if errorlevel<>0 then
        fehler('Fehler bei Nachrichtenkonvertierung')
      else begin
        _era(TempPKT);
        if PufferEinlesen('PUFFER',DefFidoBox,true,false,false,0) then
          _era('PUFFER');
        end;
      end;
  end;

begin
  if not mfehler(exist('YUP2PKT.EXE'),'YUP2PKT.EXE fehlt!') and
     not mfehler(exist('ZFIDO.EXE'),'ZFIDO.EXE fehlt!') and
     not FehlerFidoStammbox then
  begin
    dialog(56,5,'',x,y);
    maddtext(3,2,'Geben Sie den Namen Ihres Yuppie-Verzeichnisses an:',0);
    ypath:='';
    maddstring(3,4,'',ypath,50,75,'');
    readmask(brk);
    closemask;
    closebox;
    if brk or (ypath='') then exit;
    if (right(ypath,1)<>'\') then
      ypath:=ypath+'\';
    if not mfehler(IsPath(ypath),'ung�ltiges Verzeichnis') then begin
      if not exist(ypath+'AREABASE.DBF') and IsPath(ypath+'MAILBASE') then
        ypath:=ypath+'MAILBASE\';
      if not mfehler(exist(ypath+'AREABASE.DBF'),'In diesem Verzeichnis befindet sich keine Yuppie-Datenbank.') and
         not mfehler(exist(ypath+'NET-MAIL.DBF'),ypath+'NET-MAIL.DBF fehlt') and
         not mfehler(diskfree(0)>2.5*YupMailsize,
                'zu wenig freier Speicherplatz zum Einlesen der Daten')
      then
        ImportYupbase;
      end;
  end;
end;


procedure ImportQWKpacket;
var x,y     : byte;
    fn      : pathstr;
    useclip : boolean;
    bretth  : string[40];
    brk     : boolean;
    dir     : dirstr;
    name    : namestr;
    ext     : extstr;
begin
  if not mfehler(exist('ZQWK.EXE'),getres2(2422,1)) and not FehlerFidoStammbox
  then begin
    fn:='*.QWK';
    useclip:=false;
    if ReadFilename(getres2(2422,2),fn,true,useclip) then begin
      ReadBoxPar(nt_Fido,DefFidoBox);
      bretth:=BoxPar^.MagicBrett;
      dialog(50,3,fitpath(fn,46),x,y);
      maddstring(3,2,getres2(2422,3),bretth,32,32,''); mhnr(880);
      readmask(brk);
      enddialog;
      if not brk then begin
        if left(bretth,1)<>'/' then bretth:='/'+bretth;
        if right(bretth,1)<>'/' then bretth:=bretth+'/';
        shell('ZQWK.EXE -qz -b'+{DefFidoBox}'blafasel'+' -h'+bretth+' '+fn,500,4);
        fsplit(fn,dir,name,ext);
        fn:=name+'.ZER';
        if not exist(fn) then
          fehler(getres2(2422,4))
        else begin
          if PufferEinlesen(fn,DefFidoBox,true,false,false,0) then
            signal;
          _era(fn);
          end;
        end;
      end;
    end;
  freeres;
end;

end.
{
  $Log: xpimpexp.pas,v $
  Revision 1.8  2001/07/22 12:07:05  MH
  - FindFirst-Attribute ge�ndert: 0 <--> DOS.Archive

  Revision 1.7  2000/11/09 22:44:01  MH
  Fix: Server > 15 Zeichen

  Revision 1.6  2000/06/22 03:47:10  rb
  Haltezeit-Bug bei ver32 gefixt

  Revision 1.5  2000/04/10 22:13:15  rb
  Code aufger�umt

  Revision 1.4  2000/04/09 18:31:16  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.7  2000/03/30 14:05:05  mk
  - unn�tigen Debugcode entfernt

  Revision 1.6  2000/03/04 14:53:50  mk
  Zeichenausgabe geaendert und Winxp portiert

  Revision 1.5  2000/02/19 11:40:09  mk
  Code aufgeraeumt und z.T. portiert

}
