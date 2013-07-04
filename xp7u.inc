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
{ $Id: xp7u.inc,v 1.49 2001/12/26 10:39:07 MH Exp $ }


var uunum : word;    { fortlaufende 16-Bit-Nummer der UUCP-Dateien }


function uu_nummer:word;     { nÑchste Paketnummer aus UUNUMMER.DAT lesen }
var t : text;
    s : string[20];
begin
  if _filesize(UUnumdat)<2 then
  uu_nummer:=1
  else begin
    assign(t,UUnumdat);
    reset(t);
    readln(t,s);
    close(t);
    uu_nummer:=minmax(ival(s),0,$ffff);
  end;
end;

function GetNextUUnummer:word;   { nÑchste Nummer aus C-File auslesen }
var t : text;
    s : string[60];
    w : word;
begin
  w:=uu_nummer;
  if exist(XFerDir+caller) and (_filesize(XFerDir+caller)>0) then begin
    assign(t,XFerDir+caller);
    reset(t);
    while not eof(t) do begin
      readln(t,s);
      if left(s,4)='S D.' then begin
        s:=trim(mid(s,cpos(' ',s)));
        s:=left(s,cpos(' ',s)-1);
        w:=hexval(right(s,4));
      end;
    end;
    close(t);
    if w=$ffff then w:=0
    else inc(w);
  end;
  GetNextUUnummer:=w;
end;

procedure WriteUUnummer(w:word);    { nÑchste Nr. in UUNUMER.DAT schreiben }
var t : text;
begin
  assign(t,UUnumdat);
  rewrite(t);
  writeln(t,w);
  close(t);
end;


procedure NoUUZ;
begin
  window(1,1,80,25);
  trfehler(105,errortimeout);    { 'Netcall-Konvetierer UUZ.EXE fehlt!' }
  twin;
end;

procedure NoUUCICO;
begin
  window(1,1,80,25);
  trfehler(110,errortimeout);    { 'UUCICO.EXE fehlt!' }
  twin;
end;

procedure PackFehler;
begin
  window(1,1,80,25);
  trfehler(713,errortimeout);    { 'Fehler beim Packen!' }
  twin;
end;


{ Puffer in RFC-Files konvertieren }

procedure ZtoRFC(cleardir:boolean; source,destdir:pathstr);
var sr    : searchrec;
    f1,f2 : ^file;
    s     : string[8];
    p,p1  : byte;
    b0    : byte;
    cunb  : string[15];
    opt   : string[60];
    news  : boolean;
    freeze: boolean;
    gzip  : boolean;
    f     : boolean;
    bpsave   : BoxPtr;
    savebfile: string[8];
    savedom  : string[60];
    ppp_boxen: string[200];
    CompPath : array[1..10] of string;

 procedure DelAll(fn:string);
 begin
    findfirst(DestDir+fn,DOS.Archive,sr);
    new(f1);
    while doserror=0 do begin
      assign(f1^,DestDir+sr.name);
      erase(f1^);
      findnext(sr);
    end;
    {$IFDEF VP}
    FindClose(sr);
    {$ENDIF}
    dispose(f1);
  end;

  procedure NoCompSmtp(w:word);       { rcsmtp -> csmtp }
  var f1,f2 : file;
      s     : string[40];
      p     : byte;
      rr    : word;
      adr   : longint;
  begin
    if w=$ffff then w:=0
    else inc(w);
    assign(f1,DestDir+'X-'+hex(w,4)+'.OUT');
    if existf(f1) then begin
      reset(f1,1);
      adr:=0;
      assign(f2,DestDir+'smtp.tmp');
      rewrite(f2,1);
      repeat
        seek(f1,adr);
        blockread(f1,s[1],40,rr);
        s[0]:=chr(rr);
        p:=cpos(#10,s);
        s[0]:=chr(p-1);
        inc(adr,p);
        if (s='C rcsmtp') or (s='C rfsmtp') or (s='C rgsmtp') or (c='rzsmtp')
        then
          s:='C rsmtp';
        s:=s+#10;
        blockwrite(f2,s[1],length(s));
      until adr>=filesize(f1);
      close(f1);
      close(f2);
      erase(f1);
      rename(f2,DestDir+'X-'+hex(w,4)+'.OUT');
    end;
  end;

  function filesum(fmask:string):longint;
  var sum : longint;
      sr  : searchrec;
  begin
    sum:=0;
    findfirst(fmask,DOS.Archive,sr);
    while doserror=0 do begin
      inc(sum,sr.size);
      findnext(sr);
    end;
    {$IFDEF VP}
    FindClose(sr);
    {$ENDIF}
    filesum:=sum;
  end;

  procedure LogExternal(s:string);
  begin
    if logopen then begin
      writeln(netlog^);
      writeln(netlog^,'Æ',s,'Ø');
    end;
  end;

  procedure LogErrorlevel;
  begin
    if logopen then
      writeln(netlog^,'ÆErrorlevel: '+strs(errorlevel)+'Ø');
  end;

  procedure ZtoPPP;
  begin
    with BoxPar^ do begin
      f:=OutFilter(source);
      if ppp_uuz_out <> '' then begin
        exchange(PPP_UUZ_Out,'$SCREENLINES','-w:'+strs(screenlines));
        exchange(PPP_UUZ_Out,'$PUFFER',ownpath+source);
        exchange(PPP_UUZ_Out,'$SPOOL',DestDir);
      end else
        PPP_UUZ_Out:='UUZ.EXE -zu -w:'+strs(screenlines)+' '+opt+ownpath+source+
                     ' '+DestDir+' '+pointname+' '+boxname;
      LogExternal(PPP_UUZ_Out);
      shell(PPP_UUZ_Out,400,3);
      LogErrorlevel;
      if errorlevel<>0 then begin
        NC^.abbruch:=true;
        nouuzerror:=false;
        addpp^.ppperrbox:=boxname+' '+addpp^.ppperrbox;
      end;
      if f then _era(ownpath+source);
    end;
  end;

  procedure _cleardir;
  var
    b1   : byte;
    kill : boolean;
  begin
    kill:=true;
    for b1:=1 to 10 do begin
      if (DestDir=CompPath[b1]) then kill:=false;
      if (pos(' ',CompPath[b1])=1) then break;
    end;
    if kill then begin
      message('Spoolverzeichnis rÑumen...');
      DelAll('*.IN');
      DelAll('*.MSG');
      DelAll('*.OUT');
      DelAll('*.');
      closebox;
    end;
  end;

begin
  if cleardir and (exist(DestDir+'*.*')) then begin  { Spool rÑumen }
    message('Spoolverzeichnis rÑumen...');
    DelAll('*.IN');
    DelAll('*.MSG');
    DelAll('*.OUT');
    DelAll('*.');
    closebox;
  end;
  spacksize:=0;
  spufsize:=0;
  if not exist('UUZ.EXE') then begin
    NoUUZ; exit;
  end;
  MakeMimetypCfg;
  with boxpar^ do begin
    if not (netztyp=nt_PPP) and SizeNego then opt:='-s '
      else opt:='';
    if UUsmtp then
      if UpArcer='' then opt:=opt+'-SMTP '
      else if pos('freeze',lstr(uparcer))>0 then opt:=opt+'-fSMTP '
      else if pos('gzip',lstr(uparcer))>0 then opt:=opt+'-zSMTP '
      else opt:=opt+'-cSMTP ';
    if NewsMIME then opt:=opt+'-MIME ';
    if MIMEqp then opt:=opt+'-qp ';
    if RFC1522 then opt:=opt+'-1522 ';

    if (netztyp=nt_PPP) then begin
      fillchar(CompPath,sizeof(CompPath),' ');
      opt:=opt+'-ppp ';
      CompPath[1]:=DestDir;
      NC^.sendbuf:=_filesize(ownpath+source);
      outpmsgs:=testpuffer(ownpath+source,false,ldummy);
      if exist(ownpath+source) then ZtoPPP; { MainBox bedienen }
      if ((ppp_boxpakete<>'') and (not SysopMode)) then begin
        ppp_boxen:=ppp_boxpakete;
        dbOpen(d,BoxenFile,1);
        bpsave:=boxpar;
        savebfile:=bfile;
        savedom:=domain;
        b0:=2;
        repeat
          p:=blankpos(ppp_boxen);
          if p=0 then p:=length(ppp_boxen)+1;
          if p>=3 then begin
            box:=left(ppp_boxen,p-1);
            ppp_boxen:=trim(mid(ppp_boxen,p));
            {dbSeek(d,boiName,ustr(box)); alte Fassung! }
            dbSeek(d,boiDatei,ustr(box)); { wir lesen nun BFG-Dateinamen aus }
            if not dbfound then
              rfehler1(744,box) { 'UngÅltiger Box-Eintrag - %s ist keine Serverbox!' }
            else begin
              new(boxpar);
              bfile:=box; {dbReadStr(d,'dateiname'); alte Fassung! }
              box:=dbReadStr(d,'boxname');
              ReadBoxPar(nt_PPP,box);
              dbRead(d,'domain',domain);
              source:=bfile+'.PP';
              NC^.sendbuf:=NC^.sendbuf + _filesize(ownpath+source);
              outepmsgs:=outepmsgs + testpuffer(ownpath+source,false,ldummy);
              if addpp^.pppanz<maxaddpps then with boxpar^ do begin
                inc(addpp^.pppanz);
                addpp^.pppbox[addpp^.pppanz]:=box;
                addpp^.ppp_ppfile[addpp^.pppanz]:=source;
                if PPP_UUZ_Spool<>'' then begin
                  DestDir:=PPP_UUZ_Spool;
                  addpp^.ppp_spool[addpp^.pppanz]:=PPP_UUZ_Spool;
                end else begin
                  DestDir:=OwnPath+XFerDir;
                  addpp^.ppp_spool[addpp^.pppanz]:=OwnPath+XferDir;
                end;
                addpp^.ppprescan[addpp^.pppanz]:=NntpRescan;
                addpp^.ppp_uuzin[addpp^.pppanz]:=PPP_UUZ_In;
              end;
              if (exist(DestDir+'*.*')) then _cleardir;
              CompPath[b0]:=DestDir;
              inc(b0);
              if exist(ownpath+source) then ZtoPPP; { alle weiteren Boxen bedienen (max. 10) }
              dispose(boxpar);
            end;
          end;
        until (p<3) or (addpp^.pppanz=maxaddpps);
        dbClose(d);
        boxpar:=bpsave;
        bfile:=savebfile;
        domain:=savedom;
      end;   { end of Pakete mitsenden }
    end else begin    { end of PPP }
      opt:=opt+'-u'+username+' ';
      f:=OutFilter(source);
      shell('UUZ.EXE -zu '+opt+source+' '+DestDir+' '+pointname+' '+
             boxname+' '+copy(caller,3,4),400,0);
      if f then _era(source);
    end;
  end; { end of BoxPar^ }
  if errorlevel<>0 then exit;
  if netztyp=nt_PPP then exit;

  if BoxPar^.uparcer='' then begin             { Mail/News nicht packen }
    spufsize:=filesum(DestDir+'D*.OUT');
    spacksize:=spufsize;
  end
  else begin                                   { Mail/News packen }
    freeze:=pos('freeze',lstr(BoxPar^.uparcer))>0;
    gzip:=pos('gzip',lstr(BoxPar^.uparcer))>0;
    new(f1); new(f2);
    p:=pos('$PUFFER',ustr(boxpar^.uparcer));
    s[0]:=#8;
    if freeze then cunb:='#! funbatch'#10
    else if gzip then cunb:='#! gunbatch'#10
    else cunb:='#! cunbatch'#10;
    findfirst(DestDir+'D*.OUT',DOS.Archive,sr);
    while doserror=0 do begin
      inc(spufsize,sr.size);
      assign(f1^,DestDir+sr.name);
      reset(f1^,1);
      blockread(f1^,s[1],8);
      close(f1^);
      news:=(s='#! rnews');
      if news or (left(s,5)='HELO ') then begin    { News/SMTPmail packen }
        shell(left(boxpar^.UpArcer,p-1)+DestDir+sr.name+mid(boxpar^.UpArcer,p+7),
              500,3);
        if not existf(f1^) then begin    { Datei wurde gepackt }
          if freeze then assign(f1^,DestDir+left(sr.name,length(sr.name)-2)+'XZ')
          else assign(f1^,DestDir+left(sr.name,length(sr.name)-1)+'Z');
          if (errorlevel<>0) or not existf(f1^) then begin
            PackFehler;
            dispose(f1); dispose(f2);
            exit;
          end;
          if news then begin
            reset(f1^,1);
            assign(f2^,DestDir+sr.name);
            rewrite(f2^,1);                          { cunbatch erzeugen }
            blockwrite(f2^,cunb[1],length(cunb));
            fmove(f1^,f2^);
            close(f1^); close(f2^);
            erase(f1^);
          end
          else
            rename(f1^,DestDir+sr.name);
        end
        else
        if not news then     { SMTP-File nicht gepackt - Packrate zu schlecht }
        NoCompSmtp(hexval(copy(sr.name,3,4)));
      end;
      inc(spacksize,_filesize(DestDir+sr.name));
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
    dispose(f1); dispose(f2);
  end;
  uunum:=GetNextUUnummer;
end;


{ RFC-Daten aus SPOOL\ konvertieren und einlesen }

function ImportUUCPfromSpool(XFerDir:pathstr):boolean;
var sr      : searchrec;
    f1,f2   : ^file;
    s       : string[80];
    rr      : word;
    uncompy : byte;
    dummy   : longint;

  procedure uncompress(fn:string; freeze,gzip:boolean);
  var s : string[120];
  begin
    if freeze then s:=boxpar^.unfreezer
    else if gzip then s:=boxpar^.ungzipper
    else s:=BoxPar^.downarcer;
    exchange(s,'$DOWNFILE',XFerDir+fn+'.Z');
    gotoxy(1,uncompy);
    shell(s,600,5);
    inc(uncompy);
    if uncompy=screenlines-fnkeylines-5 then begin
      clrscr;
      uncompy:=2;
    end;
    if not exist(XFerDir+fn) then
      if _rename(XFerDir+fn+'.Z',XFerDir+fn) then
        MoveToBad(XFerDir+fn);
  end;

begin
  ImportUUCPfromSpool:=false;
  findfirst(XFerDir+'D*.',DOS.Archive,sr);   { Datenfiles - ohne Extension }
  if doserror=0 then begin
    twin;
    clrscr;
    uncompy:=2;
    cursor(curoff);
    new(f1); new(f2);
    while doserror=0 do begin
      inc(NC^.recpack,sr.size);
      assign(f1^,XFerDir+sr.name);
      reset(f1^,1);
      blockread(f1^,s[1],40,rr);
      s[0]:=chr(rr);
      if (left(s,11)='#! cunbatch') or (left(s,11)='#! funbatch') or   { Datei entpacken }
         (left(s,11)='#! gunbatch') or (left(s,11)='#! zunbatch')
      then begin
        assign(f2^,XFerDir+sr.name+'.Z');
        rewrite(f2^,1);
        seek(f1^,cpos(#10,s));
        fmove(f1^,f2^);
        close(f1^); close(f2^);
        uncompress(sr.name,pos('funbatch',s)>0,
                   (pos('gunbatch',s)>0) or (pos('zunbatch',s)>0));
      end
      else begin
        close(f1^);
        if (left(s,2)=#$1f#$9d) or (left(s,2)=#$1f#$9f) or
           (left(s,2)=#$1f#$8b) then begin     { compressed/frozen SMTP o.Ñ. }
          rename(f1^,XFerDir+sr.name+'.Z');
          uncompress(sr.name,s[2]=#$9f,s[2]=#$8b);
        end;
      end;
      inc(NC^.recbuf,_filesize(XFerDir+sr.name));
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
    dispose(f1); dispose(f2);
    clrscr;
    window(1,1,80,25);
    shell('UUZ.EXE -uz -w:'+strs(screenlines)+
          ' '+XFerDir+'X*. '+dpuffer+' '+boxpar^.pointname+domain,600,3);
    findfirst(XFerDir+'*.0??',DOS.Archive,sr);
    while doserror=0 do begin       { abgebrochene UUCP-Files -> BAD }
      MoveToBad(XFerDir+sr.name);
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
    findfirst(XFerDir+'D*',DOS.Archive,sr);   { Åbriggebliebene D-Files sicherstellen }
    while doserror=0 do begin
      if sr.attr and dos.Archive<>0 then
        MoveToBad(XFerDir+sr.name);
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
    EmptySpool('D*.OUT');        { ausgehende Pakete lîschen }
    EmptySpool('X*.OUT');        { C-File mu· stehenbleiben! }
    if nDelPuffer and (errorlevel=0) and (testpuffer(dpuffer,false,dummy)>=0)
    then
      EmptySpool('*.*');         { entpackte Dateien lîschen }
    CallFilter(true,dpuffer);
    if _filesize(dpuffer)>0 then
    if PufferEinlesen(dpuffer,box,false,false,true,pe_Bad) then begin
      _era(dpuffer);
      ImportUUCPfromSpool:=true;
    end;
  end
  else
    CallFilter(true,dpuffer);
end;

function UUCPnetcall: Boolean;
var
    res  : integer;
    f       : file;
begin
  recs:='';
  netcall_connect:=true;
  fidologfile:=TempFile('');
  if not exist('uucico.exe') then begin
    NoUUCICO;
    res:=uu_parerr;
  end
  else begin
    if not comn[comnr].fossil then ReleaseC;
    {$IFNDEF Ver32 }
    res:=uucico(XFerDir+caller,ConnTicks,ende,      { --- UUCICO ---------- }
                   NC^.waittime,NC^.sendtime,NC^.rectime,fidologfile);
    {$ENDIF }
    if not comn[comnr].fossil then Activate;
  end;
  aufhaengen;
  DropDtr(comnr);
  ReleaseC;
  if (res<>uu_nologin) and (res<>uu_parerr) then
    WriteUUnummer(uunum);
  UUCPnetcall:=(res=uu_ok);
  cursor(curoff);
  if not exist('UUZ.EXE') then begin
    nouuz; exit;
  end;
  window(1,1,80,25);
  if (res=uu_ok) or (res=uu_recerr) then begin
    NC^.sendbuf:=spufsize;
    NC^.sendpack:=spacksize;
    NC^.abbruch:=(res<>uu_ok);
    moment;
    outmsgs:=0;
    ClearUnversandt(ppfile,box);
    if exist(ppfile) then
      _era(ppfile);
    if exist(eppfile) then
      _era(eppfile);
    if res=uu_ok then
      wrtiming('NETCALL '+ustr(boxpar^.boxname));
    if res=uu_recerr then begin    { doppeltes Senden verhindern }
      assign(f,XFerDir+caller);
      rewrite(f,1);                   { Inhalt des C-Files lîschen }
      close(f);
    end;
    closebox;
  end
  else
    NC^.abbruch:=true;
  if ImportUUCPfromSpool(XFerDir) and (res=uu_recerr) then
    erase_mask(XFerDir+'*.');         { Doppeltes Einlesen verhindern }
  SendNetzanruf(once,false);
  SendFilereqReport;    { ... falls vorhanden }
  AppLog(fidologfile,UUCPlog);
  if exist(fidologfile) then _era(fidologfile);
  twin;
end;

function ImportPPPfromSpool(XFerDir:pathstr):boolean;
var dummy : longint;
begin
  ImportPPPfromSpool:=false;
  if exist(XFerDir+'*.MSG') then begin
    twin;
    clrscr;
    cursor(curoff);
    window(1,1,80,25);
    with BoxPar^ do begin
      if PPP_UUZ_In <> '' then begin
        exchange(PPP_UUZ_In,'$SCREENLINES','-w:'+strs(screenlines));
        exchange(PPP_UUZ_In,'$SPOOL',XFerDir+'*.MSG');
        exchange(PPP_UUZ_In,'$PUFFER',ownpath+dpuffer)
      end else
      PPP_UUZ_In:='UUZ.EXE -uz -w:'+strs(screenlines)+' '+XFerDir+
                  '*.MSG '+ownpath+dpuffer;
      shell(PPP_UUZ_In,600,3);
    end;
    findfirst(XFerDir+'*.MSG',DOS.Archive,sr);
    while doserror=0 do begin       { abgebrochene PPP-Files -> BAD }
      MoveToBad(XFerDir+sr.name);
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
    EmptySpool('*.OUT');            { ausgehende Pakete lîschen }
    if nDelPuffer and (errorlevel=0) and (testpuffer(dpuffer,false,dummy)>=0)
    then EmptySpool('*.*');         { Alle Dateien lîschen }
    CallFilter(true,dpuffer);
    if _filesize(dpuffer)>0 then
    if PufferEinlesen(dpuffer,box,false,false,true,pe_Bad) then begin
      _era(dpuffer);
      ImportPPPfromSpool:=true;
    end;
  end else
  CallFilter(true,dpuffer);
end;

procedure PPPSysopTransfer;
var dummy : longint;

  procedure EmptySysin;
  var sr : searchrec;
  begin
    findfirst(BoxPar^.sysopinp+'*.*',DOS.Archive,sr);
    while doserror=0 do begin
      _era(BoxPar^.sysopinp+sr.name);
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
  end;

begin
  inmsgs:=0; outmsgs:=0; outemsgs:=0;
  with boxpar^ do begin
    if not IsPath(SysopInp) then begin              { Verzeichnisse testen }
      trfehler(727,errortimeout);   { 'ungÅltiges Eingabeverzeichnis' }
      exit;
    end;
    if not IsPath(SysopOut) then begin
      trfehler(728,errortimeout);   { 'ungÅltiges Ausgabeverzeichnis' }
      exit;
    end;
    NC^.sendbuf:=_filesize(ppfile);
    if NC^.sendbuf>0 then begin                     { -- Ausgabepaket -- }
      outmsgs:=testpuffer(ppfile,false,dummy);
      twin;
      cursor(curoff);
      ZtoRFC(false,ppfile,SysopOut);
      window(1,1,80,25);
      Moment;
      RemoveEPP;
      outmsgs:=0;
      ClearUnversandt(ppfile,box);
      closebox;
      _era(ppfile);
      if exist(eppfile) then _era(eppfile);
    end;
    if exist(SysopInp+'*.*') then                   { -- Eingangspaket -- }
    if ImportPPPfromSpool(SysopInp) then EmptySysin;
    Netcall_connect:=true;
  end;
end;

procedure UUCPSysopTransfer;
var dummy : longint;

  procedure EmptySysin;
  var sr : searchrec;
  begin
    findfirst(BoxPar^.sysopinp+'*.*',DOS.Archive,sr);
    while doserror=0 do begin
      _era(BoxPar^.sysopinp+sr.name);
      findnext(sr);
    end;
    {$IFDEF virtualpascal}
    FindClose(sr);
    {$ENDIF}
  end;

begin
  inmsgs:=0; outmsgs:=0; outemsgs:=0;
  with boxpar^ do begin
    if not IsPath(SysopInp) then begin              { Verzeichnisse testen }
      trfehler(727,errortimeout);   { 'ungÅltiges Eingabeverzeichnis' }
      exit;
      end;
    if not IsPath(SysopOut) then begin
      trfehler(728,errortimeout);   { 'ungÅltiges Ausgabeverzeichnis' }
      exit;
      end;

    NC^.sendbuf:=_filesize(ppfile);
    if NC^.sendbuf>0 then begin               { -- Ausgabepaket -- }
      outmsgs:=testpuffer(ppfile,false,dummy);
      twin;
      cursor(curoff);
      ZtoRFC(false,ppfile,SysopOut);
      window(1,1,80,25);
      WriteUUnummer(uunum);
      Moment;
      RemoveEPP;
      outmsgs:=0;
      ClearUnversandt(ppfile,box);
      closebox;
      _era(ppfile);
      if exist(eppfile) then _era(eppfile);
      end;

    if exist(SysopInp+'*.*') then                   { -- Eingangspaket -- }
      if ImportUUCPfromSpool(SysopInp) then
        EmptySysin;
    Netcall_connect:=true;
    end;
end;
{
  $Log: xp7u.inc,v $
  Revision 1.49  2001/12/26 10:39:07  MH
  - RFC/PPP: $SCREENLINES-Makro auch outgoing

  Revision 1.48  2001/09/08 10:26:00  MH
  Bei gro·en Puffern kann man den Eindruck gewinnen, das sich nichts mehr tut:
  - HDO-Ersetzung optisch anzeigen
  - Spooldir lîschen optisch anzeigen

  Revision 1.47  2001/08/20 21:14:44  MH
  - kleine Korektur des letzten co

  Revision 1.46  2001/08/20 13:04:14  MH
  - Ab sofort werden BFG-Dateinamen ohne Extension ins Boxenfile unter
    PPP_BoxPakete geschrieben. Diese mîchten die Clients zukÅnftig dort
    fÅr den Multiboxbetrieb erwarten. Eine Konvertierung der bereits
    bestehenden Konfiguration findet nicht statt, und mu· ggfs. selbst
    angepasst werden.

  Revision 1.45  2001/07/22 17:36:40  MH
  - FileExist funzt nicht mit *.* unter W32

  Revision 1.44  2001/07/22 12:06:54  MH
  - FindFirst-Attribute ge‰ndert: 0 <--> DOS.Archive

  Revision 1.43  2001/07/14 11:05:51  MH
  - Multiboxbetrieb beachtet beim Puffereinlesen Vertreter der jeweiligen Box

  Revision 1.42  2001/06/18 20:17:37  oh
  Teames -> Teams

  Revision 1.41  2001/04/04 19:57:03  oh
  -Timeouts konfigurierbar

  Revision 1.40  2001/01/29 22:08:47  MH
  RFC/PPP:
  - Einige Grenzen erweitert

  Revision 1.39  2001/01/04 15:25:16  MH
  - Box fÅr Timingliste gro·schreiben

  Revision 1.38  2000/12/19 16:55:23  MH
  RFC/PPP-Netcall Fix:
  - Probleme beim lîschen der alten Msg-Dateien behoben

  Revision 1.37  2000/12/17 21:19:55  MH
  RFC/PPP-Netcall:
  - Probleme beim lîschen der alten Msg-Dateien behoben

  Revision 1.36  2000/12/04 19:02:46  MH
  - Fix: Multithreading

  Revision 1.35  2000/12/03 09:55:30  MH
  RFC/PPP:
  - Fix: Online-NetCall

  Revision 1.34  2000/10/28 09:49:23  MH
  RFC/PPP: Fixes uvs

  Revision 1.33  2000/09/23 23:38:24  MH
  Baustellen bereinigt

  Revision 1.32  2000/08/06 16:26:23  MH
  RFC/PPP: Fix:
  o Bei einem OutGoing-UUZ-Error konnten unter UmstÑnden
    Unversandte Nachrichten verloren gehen.
  o Artikelpointer (Rescan) werden nun bei Erfolg zurÅckgesetzt

  Revision 1.31  2000/07/18 00:02:38  MH
  RFC/PPP: Fix: OutGoing UUZ-Aufruf schrieb in den MenÅscreen

  Revision 1.30  2000/07/13 13:56:59  MH
  RFC/PPP: Sysoptransfer fertig gestellt

  Revision 1.29  2000/07/04 14:16:19  MH
  RFC/PPP: Ausgangsfilter:
  - jetzt wieder auf Nummer Sicher...

  Revision 1.28  2000/07/03 22:11:16  MH
  RFC/PPP: Fix:
  - Ausgangsfilter
  - Dupes (incomming)

  Revision 1.27  2000/07/02 13:30:24  MH
  RFC/PPP: Kleine énderung fÅr OutFilter...

  Revision 1.26  2000/07/02 11:58:00  MH
  RFC/PPP: Code ein wenig aufgerÑumt

  Revision 1.25  2000/07/02 11:12:19  MH
  RFC/PPP: UUZ wird nun auch Outgoing mitgelogt

  Revision 1.24  2000/06/30 11:22:37  MH
  RFC/PPP: Pakete mitsenden:
  - ClearDir verbessert

  Revision 1.23  2000/06/29 19:13:18  MH
  RFC/PPP: Errorlevelabfrage verschoben...

  Revision 1.22  2000/06/29 18:10:18  MH
  RFC/PPP: Fix fÅr Netzanrufbericht:
  - Variable fÅr eingehende Nachrichten wurde nicht zurÅckgesetzt

  Revision 1.21  2000/06/29 15:07:07  MH
  RFC/PPP: Kleinere énderungen um Konvertierungsfehler:
  - zu beseitigen
  - weitere zu finden: Dazu wird eine Temp-Datei vorrÅbergehend ins
    XP-Verzeichnis geschrieben (nur OutGoing)...bitte da mal reinsehen

  Revision 1.20  2000/06/28 21:17:14  MH
  RFC/PPP: - Neue Makros fÅr UUZ (In/Out) angelegt:
  - $SCREENLINES, $SPOOL, $PUFFER

  Revision 1.18  2000/06/26 17:37:05  MH
  RFC/PPP: Pakete mitsenden:
  - Nicht versendete Nachrichten bleiben auf Unversandt und
    der Puffer wird entsprechend angepasst, falls einige
    Nachrichten versendet werden konnten
  - Netzanrufbericht sollte nun auch zusÑtzlich entstehendes
    Mailaufkommen berÅcksichtigen

  Revision 1.17  2000/06/24 10:16:30  MH
  RFC/PPP: Pakete mitsenden:
  nDelPuffer-Schalter wird nun beim lîschen von *.MSG berÅcksichtigt

  Revision 1.16  2000/06/24 06:32:55  MH
  RFC/PPP: Pakete mitsenden:
  Nach der Konvertierung und Puffertest werden
  die MSG-Dateien aus den SpoolDirs entfernt

  Revision 1.15  2000/06/23 17:56:52  MH
  RFC/PPP: Pakete mitsenden:
  Einige Abfragen eingespart, um das wechseln zwischen
  den Boxen zu beschleunigen

  Revision 1.14  2000/06/22 12:29:16  MH
  RFC/PPP: Fix Pakete mitsenden: PPP_UUZ_In wurde nicht gewechselt

  Revision 1.13  2000/06/22 09:24:28  MH
  RFC/PPP: Pakete mitsenden: Kosmetische Aenderung

  Revision 1.12  2000/06/21 07:02:50  MH
  RFC/PPP: Pakete mitsenden implementiert

  Revision 1.11  2000/06/18 21:52:06  MH
  RFC/PPP: UUZ-SpoolDir eingerichtet (f. Pakete mitsenden v. Bedeutung)

  Revision 1.10  2000/06/09 23:40:23  MH
  RFC/PPP: *.MSG werden per Schalter PufferLoeschen spaetestens beim naechsten Call entfernt

  Revision 1.9  2000/06/09 16:43:13  MH
  RFC/PPP: Puffersicherung bei Fehler verbessert

  Revision 1.8  2000/06/07 22:25:12  MH
  *** empty log message ***

  Revision 1.7  2000/06/04 04:23:00  MH
  RFC/PPP: Errorlevelhandling angepasst

  Revision 1.6  2000/06/02 08:36:47  MH
  RFC/PPP: LoginTyp hergestellt

  Revision 1.4  2000/04/09 18:27:50  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.6  2000/04/04 10:33:57  mk
  - Compilierbar mit Virtual Pascal 2.0

  Revision 1.5  2000/02/19 11:40:08  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.4  2000/02/15 20:43:36  mk
  MK: Aktualisierung auf Stand 15.02.2000

}
