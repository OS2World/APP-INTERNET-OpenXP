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
{ $Id: xp7.pas,v 1.106 2002/02/14 09:42:15 MH Exp $ }

{ Netcall-Teil }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit  xp7;

interface

uses  xpglobal, {$IFDEF virtualpascal}sysutils,{$endif}
      crt,dos,dosx,typeform,uart,datadef,database,fileio,inout,keys,winxp,
      video,maske,maus2,montage,lister,resource,stack,
{$IFDEF CAPI }
  capi,
{$ENDIF }
      xp0,xp1,xp1help,xp1input,xp2c,xpterm,xpdiff,xpuu;


function  netcall(net:boolean; box:string; once,relogin,crash:boolean):boolean;
procedure netcall_at(zeit:datetimest; box:string);
procedure EinzelNetcall(box:string);
procedure DropAllCarrier;

function  AutoMode:boolean;

const CrashGettime : boolean = false;  { wird nicht automatisch zurÅckgesetzt }
      maxaddpkts   = 8;
      maxaddpps    = 10;

      { In abox stehen nur die Boxen fÅr die Daten zu verschicken sind }
      { (anzahl StÅck), in akabox alle eingetragenen Mitsende-Boxen    }
      { (akanz StÅck).                                                 }

type  addpktrec    = record
                       anzahl : shortint;
                       akanz  : shortint;
                       addpkt : array[1..maxaddpkts] of string[12];
                       abfile : array[1..maxaddpkts] of string[8];
                       abox,
                       akabox : array[1..maxaddpkts] of string[BoxNameLen];
                       reqfile: array[1..maxaddpkts] of string[12];
                     end;
      addpktpnt    = ^addpktrec;

type  addppp_rec   = record
                       pppanz    : shortint;
                       ppperrbox : string[210];
                       ppp_ppfile: array[1..maxaddpps] of string[12];
                       pppbox    : array[1..maxaddpps] of string[20];
                       ppp_spool : array[1..maxaddpps] of string[79];
                       ppp_uuzin : array[1..maxaddpps] of string;
                       ppprescan : array[1..maxaddpps] of boolean;
                     end;
      addppp_pnt   = ^addppp_rec;

var Netcall_connect : boolean;
    _maus,_fido     : boolean;     { dbg : text; }

implementation  {---------------------------------------------------}

uses xpnt,xp1o,xp2,xp3,xp3o,xp3o2,xp4o,xp5,xp4o2,xp6,xp8,xp9bp,xp9,xp10,
     xpfido,xpfidonl,xpf2,xpmaus,xp7l,xp7o,xp7f;

var  epp_apppos : longint;              { Originalgrî·e von ppfile }


procedure DropAllCarrier;
var p : ScrPtr;
begin
  if comnr<=4 then begin
    sichern(p);
    ActivateCom(comnr,512,false);
    DropDtr(comnr);
    ReleaseCom(comnr);
    holen(p);
    end;
end;


function exclude_time:byte;
var i : integer;
    t : string[5];
begin
  exclude_time:=0;
  if forcepoll then exit;
  t:=left(typeform.time,5);
  with boxpar^ do
    for i:=1 to excludes do
      if (t>=exclude[i,1]) and (t<=exclude[i,2]) then
        exclude_time:=i;
end;


{ --- Netcall -------------------------------------------------------- }

{ net:  FALSE -> Online-Anruf }
{ box:  '' -> UniSel(Boxen)   }
{ once: TRUE -> RedialMax:=1  }
{ FALSE -> Netcall mu· wiederholt werden }

function netcall(net:boolean; box:string; once,relogin,crash:boolean):boolean;

const crlf : array[0..1] of char = #13#10;
      ACK  = #6;
      NAK  = #21;
      back7= #8#8#8#8#8#8#8;

var bfile      : string[14];
    ppfile     : string[14];
    eppfile    : string[14];
    user       : string[30];
    ppp_spool  : string[79];
    ende       : boolean;
    d          : DB;
    f          : file;
    retries    : integer;
    cps        : cpsrec;
    IgnCD,
    IgnCTS     : boolean;
    recs,lrec  : string;    { Empfangspuffer-String }
    zsum       : byte;
    i          : integer;
    size       : longint;
    noconnstr  : string[30];
    c          : char;
    startscreen: boolean;
    display    : boolean;
    showconn   : boolean;
    rz         : string[5];
    spufsize,
    spacksize  : longint;
    brkadd     : longint;         { s. tkey() }
    s          : string;

    ticks      : longint;
    nulltime   : DateTimeSt;      { Uhrzeit der ersten Anwahl }
    connects   : integer;         { ZÑhler 0..connectmax }
    netztyp    : byte;
    logintyp   : shortint;        { ltNetcall / ltZConnect / ltMagic / }
                                  { ltQuick / ltMaus                   }
    pronet     : boolean;
    prodir     : string[8];
    janusp     : boolean;
    msgids     : boolean;         { fÅr MagicNET }
    alias      : boolean;         { Fido: Node- statt Pointadresse     }
    CrashBox   : FidoAdr;
    OwnFidoAdr : string[20];    { eigene z:n/n.p, fÅr PKT-Header und ArcMail }
    ldummy     : longint;
    CrashPhone : string[30];
    NumCount   : byte;            { Anzahl Telefonnummern der Box }
    NumPos     : byte;            { gerade gewÑhlte Nummer        }
    error      : boolean;
    scrfile    : string[50];
    domain     : string[60];
    ft         : longint;

    caller,called,
    upuffer,dpuffer,
    olddpuffer : string[14];
    addpkts    : addpktpnt;
    source     : pathstr;
    ff         : boolean;

    isdn       : boolean;
    orgfossil  : boolean;
    jperror    : boolean;

    sr         : searchrec;
    addpp      : addppp_pnt;
    outerror   : boolean;
    nouuzerror : boolean;
    callbox    : string[BoxNameLen];
    saveboxpar : BoxPtr;
    saveppfile : string[12];
    storebfile : string[8];

label abbruch,ende0,ciao;

  procedure AppendEPP;
  var f,f2 : file;
  begin
    epp_apppos:=-1;
    if _filesize(eppfile)>0 then begin      { epp an pp anhÑngen }
      assign(f,ppfile);
      if existf(f) then reset(f,1)
      else rewrite(f,1);
      epp_apppos:=filesize(f);
      seek(f,epp_apppos);
      assign(f2,eppfile); reset(f2,1);
      fmove(f2,f);
      close(f); close(f2);
    end;
  end;

  procedure RemoveEPP;
  var f : file;
  begin
    if (epp_apppos>-1) and exist(ppfile) then begin
      assign(f,ppfile); reset(f,1);
      seek(f,epp_apppos);                 { epp aus pp lîschen }
      truncate(f);
      close(f);
      epp_apppos:=-1;
    end;
  end;

  {$I xp7.inc}         { diverse Unterfunktionen    }
  {$I xp7u.inc}        { TurboBox- und UUCP-Netcall }

  function ZM(cmd:string; upload:boolean):string;
  var s : string[127];
  begin
    with comn[boxpar^.bport] do begin
      if fossil then
        s:='ZM.EXE -c$PORT -f'
      else
        s:='ZM.EXE -c$ADDRESS,$IRQ -tl'+strs(tlevel);
      s:=s+' -b$SPEED';
      if IgCD then s:=s+' -d';
      if IgCTS then s:=s+' -h';
      if UseRTS then s:=s+' -rts';
      if not u16550 and not fossil then s:=s+' -n';
      s:=s+' -q -o3';
      if not upload and not ParQuiet then s:=s+' -beep';
      if boxpar^.MinCPS>0 then s:=s+' -z'+strs(boxpar^.MinCps);
      if ParOs2<>0 then s:=s+' -os2'+chr(ParOs2+ord('a')-1);
      if upload then
        s:=s+' sz $UPFILE'
      else begin
        s:=s+' rz';
        case netztyp of
          nt_Pronet:   ;
          nt_ZConnect: if BoxPar^.JanusPlus then s:=s+' $DOWNPATH'
                       else s:=s+' $DOWNFILE';
          nt_Maus    : if BoxPar^.downarcer='' then s:=s+' $DOWNFILE';
          else         s:=s+' $DOWNFILE';
        end;
      end;
    end;
    s:=s+mid(cmd,7);   { optionale Parameter anhÑngen }
    ZM:=s;
  end;

  procedure SetFilenames;
  begin
    with BoxPar^ do begin
      case logintyp of
        ltNetcall,             { Namen mÅssen ohne Pfade sein! }
        ltZConnect,
        ltTurbo    : begin
                       caller:='CALLER.'+uparcext;
                       called:='CALLED.'+downarcext;
                       upuffer:=PufferFile;
                       dpuffer:=PufferFile;
                     end;
        ltMagic    : begin
                       caller:='OUT.'+uparcext;
                       called:='OUT.'+downarcext;
                       upuffer:=box+'.TXT';
                       dpuffer:=pointname+'.TXT';
                     end;
        ltQuick,
        ltGS       : begin
                       caller:='PUFFER.'+uparcext;
                       called:='PUFFER.'+downarcext;
                       upuffer:=PufferFile;
                       dpuffer:=PufferFile;
                     end;
        ltMaus     : begin
                       caller:='INFILE.'+uparcext;
                       called:='OUTFILE.'+uparcext;
                       upuffer:='INFILE.TXT';
                       dpuffer:='OUTFILE.TXT';
                     end;
        ltFido     : begin
                       caller:=ARCmail(OwnFidoAdr,boxname);
                       called:='XXX$$$';
                       upuffer:=left(date,2)+left(typeform.time,2)+
                                copy(typeform.time,4,2)+right(typeform.time,2)+
                                '.PKT';
                       dpuffer:='YYY$$$';
                       fidologfile:='';
                     end;
        ltPPP      : begin
                       caller:='3pdummy1';
                       called:='3pdummy2';
                       upuffer:='3PPUFFER';
                       dpuffer:='3PPUFFER';
                     end;
        ltUUCP     : begin
                       caller:='C-'+hex(uu_nummer,4)+'.OUT';
                       called:='uudummy';
                       upuffer:='UPUFFER';
                       dpuffer:='UPUFFER';
                     end;
      end;
      if not (logintyp in [ltUUCP,ltPPP]) then begin
        {if _fido and sysopmode then
          exchange(uparcer,'$PUFFER',OwnPath+upuffer)
        else} if pronet then
          exchange(uparcer,'$PUFFER',upuffer+' '+bfile+'.REQ')
        else
          exchange(uparcer,'$PUFFER',upuffer);
        exchange(uparcer,'$UPFILE',caller);
        if not _fido then begin
          exchange(downarcer,'$DOWNFILE',called);
          if not ltMultiPuffer(logintyp) then
            exchange(downarcer,'$PUFFER',dpuffer)
          else
            exchange(downarcer,'$PUFFER','*.*');
        end;
      end;
      if ustr(left(uploader+' ',7))='ZMODEM ' then
        uploader:=ZM(uploader,true);
      if ustr(left(downloader+' ',7))='ZMODEM ' then
        downloader:=ZM(downloader,false);
      exchange(uploader,'$PORT',strs(bport));
      exchange(uploader,'$ADDRESS',hex(comn[bport].Cport,3));
      exchange(uploader,'$IRQ',strs(comn[bport].Cirq));
      exchange(uploader,'$SPEED',strs(baud));
      exchange(uploader,'$UPFILE',caller);
      exchange(uploader,'$LOGFILE',OwnPath+bilogfile);
      if janusplus or (netztyp=nt_Pronet) then
        exchange(uploader,'$DOWNPATH','SPOOL')
      else
        exchange(uploader,'$DOWNPATH',left(OwnPath,length(OwnPath)-1));
      exchange(downloader,'$PORT',strs(bport));
      exchange(downloader,'$ADDRESS',hex(comn[bport].Cport,3));
      exchange(downloader,'$IRQ',strs(comn[bport].Cirq));
      exchange(downloader,'$SPEED',strs(baud));
      exchange(downloader,'$DOWNFILE',called);
      if janusplus or (netztyp=nt_Pronet) then
        exchange(downloader,'$DOWNPATH','SPOOL')
      else
        exchange(downloader,'$DOWNPATH',left(OwnPath,length(OwnPath)-1));
      bimodem:=ntExtProt(netztyp) and (pos('bimodem',lstr(uploader))>0);
    end;
  end;

  procedure wrscript(x,y,col:byte; txt:string);
  begin
    spush(dphback,sizeof(dphback));
    dphback:=col;
    moff;
    disphard(x,y,txt);
    mon;
    spop(dphback);
  end;

  procedure AppendNetlog;
  const bs = 4096;
  var t  : text;
      s  : string;
      buf: pointer;
  begin
    assign(t,LogPath+NetcallLog);
    if existf(t) then append(t)
    else rewrite(t);
    writeln(t);
    writeln(t,reps(reps(getreps(716,date),box),nc^.starttime));
    writeln(t);
    getmem(buf,bs);
    settextbuf(netlog^,buf^,bs);
    reset(netlog^);
    while not eof(netlog^) do begin
      readln(netlog^,s);
      writeln(t,s);
    end;
    writeln(t,dup(78,'-'));
    flush(t);
    close(t);
    close(netlog^);
    freemem(buf,bs);
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

  function NoScript(script:pathstr):boolean;
  begin
    NoScript:=((script='') or not exist(script));
  end;

  procedure Del_PP_and_UV;
  begin
    if exist(ownpath+ppfile) then begin
      Moment;
      outmsgs:=0;
      ClearUnversandt(ownpath+ppfile,box);
      closebox;
      _era(ownpath+ppfile);
    end;
    if exist(ownpath+eppfile) then _era(ownpath+eppfile);
    if exist(TempPath+'STORING.PP') then
      if filecopy(TempPath+'STORING.PP',ownpath+ppfile) then ExErase(TempPath+'STORING.PP');
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
    {$IFDEF ver32}
    FindClose(sr);
    {$ENDIF}
    filesum:=sum;
  end;

  procedure RenAll(fn:string);
  var
    f1   : ^file;
    dir  : DirStr;
    name : NameStr;
    ext  : ExtStr;
  begin
    new(f1);
    findfirst(PPP_Spool+fn,DOS.Archive,sr);
    while doserror=0 do begin
      assign(f1^,PPP_Spool+sr.name);
      fsplit(sr.name,dir,name,ext);
      rename(f1^,PPP_Spool+name+'.IN');
      InOutRes:=0;
      findnext(sr);
    end;
    {$IFDEF ver32}
    FindClose(sr);
    {$ENDIF}
    dispose(f1);
  end;

  procedure PPPtoZ;
  begin
    with BoxPar^ do begin
      if PPP_UUZ_In <> '' then begin
        exchange(PPP_UUZ_In,'$SCREENLINES','-w:'+strs(screenlines));
        exchange(PPP_UUZ_In,'$SPOOL',PPP_Spool+'*.MSG');
        exchange(PPP_UUZ_In,'$PUFFER',ownpath+dpuffer);
        exchange(PPP_UUZ_In,'$BOX','-b'+ustr(box));
      end else
        PPP_UUZ_In:='UUZ.EXE -uz -w:'+strs(screenlines)+' -ppp '+PPP_Spool+
                    '*.MSG '+ownpath+dpuffer+' -b'+ustr(box);
      LogExternal(PPP_UUZ_In);
      shell(PPP_UUZ_In,600,3);
      LogErrorlevel;
      if errorlevel<>0 then begin
        NC^.abbruch:=true;
        nouuzerror:=false;
      end;
      RenAll('*.MSG');
    end;
  end;

  procedure StoreOutMsgIds; { MsgIds aus *.OUT extrahieren }
  var
    t          : text;
    line       : string;
    p          : byte;
    f          : file;
    FoundMsgid : boolean;

  procedure GetLine;   { eine Textzeile einlesen }
  var
    c : char;
  begin
    line:='';
    repeat
      blockread(f,c,1);
      if (c=#9) or (c>=' ') then line:=line+c;
    until (c=#10) or eof(f);
  end;

  begin
    assign(t,TempPath+'OUTMSGID.PPP');
    if exist(TempPath+'OUTMSGID.PPP') then append(t) else
    rewrite(t);
    findfirst(PPP_Spool+'*.OUT',DOS.Archive,sr);
    while doserror=0 do begin
      assign(f,PPP_Spool+sr.name);
      reset(f,1);
      {if sr.attr and dos.Archive<>0 then begin}
        FoundMsgid:=false;
        repeat
          GetLine;
          if pos('Message-ID:',line)<>0 then FoundMsgid:=true;
        until FoundMsgid or eof(f);
        if FoundMsgid then begin
          p:=pos('<',line);
          line:=copy(line,p+1,length(line)-p-1);
          writeln(t,line);
        end;
      {end;}
      close(f);
      findnext(sr);
    end;
    {$IFDEF ver32}
    FindClose(sr);
    {$ENDIF}
    flush(t);
    close(t);
    InOutRes:=0;
  {.$I-}
  end;

  procedure ReadSomeData;
  var
    dbBox : db;
  begin
    dbOpen(dbBox,BoxenFile,1);
    dbSeek(dbBox,boiName,ustr(box));
    if dbFound then begin
      dbRead(dbBox,'replyto',boxpar^._replyto);
      dbRead(dbBox,'domain',boxpar^._domain);
      dbRead(dbBox,'fqdn',boxpar^._fqdn);
    end;
    dbClose(dbBox);
  end;

  procedure WrPlog;
  var
    plog : text;
  begin
    RfcLogFile:=LogPath+PPPLog;
    assign(plog,RfcLogFile);
    rewrite(plog);
    NC^.datum:=ZDate;
    writeln(plog,'Netzanruf vom ',fdat(nc^.datum),' um ',ftime(nc^.datum),' bei ',
                 forms(boxpar^.boxname,16));
    writeln(plog);
    flush(plog);
    close(plog);
  end;

begin                  { of Netcall }
  (*assign(dbg,'NCDBG.LOG'); { Netcall-Debug }
  if exist('NCDBG.LOG') then append(dbg) else rewrite(dbg);
  writeln(dbg,'>---------<');*)
  netcall:=true;
  Netcall_connect:=false;
  logopen:=false; netlog:=nil;
  if (net and (memavail<50000)) or
     ((not net) and _ppp and (memavail<50000) and ntOnline(netztyp) ) then
  begin
    trfehler(704,errortimeout);   { 'Zu wenig freier Speicher fÅr Netcall!' }
    exit;
  end;

  if crash then
    if not isbox(DefFidoBox) then begin
      rfehler(705);         { 'keine Fido-Stammbox gewÑhlt' }
      exit;
    end
    else if not NodeOpen then begin
      rfehler(706);         { 'keine Nodeliste aktiviert' }
      exit;
    end
    else begin
      if box='' then box:=GetCrashbox;
      if (box=' alle ') or (box=CrashTemp) then begin
        AutoCrash:=box;
        exit;
      end;
      if box='' then exit;
      if IsBox(box) then
        crash:=false              { Crash beim Bossnode - normaler Anruf }
      else begin
        SplitFido(box,CrashBox,DefaultZone);
        box:=DefFidoBox;
      end;
    end;
  if not crash then begin
    if box='' then
      box:=UniSel(1,false,DefaultBox);         { zu pollende Box abfragen }
    if box='' then exit;
  end;

  dbOpen(d,BoxenFile,1);               { zugehîrigen Dateiname holen }
  dbSeek(d,boiName,ustr(box));
  if not dbFound then begin
    dbClose(d);
    trfehler1(709,box,errortimeout);   { 'unbekannte Box:  %s' }
    exit;
  end;
  dbRead(d,'dateiname',bfile);
  ppfile:=bfile+'.PP';       { mu· ohne Pfad bleiben, wg. XPU.INC.ZtoRFC! }
  eppfile:=bfile+'.EPP';
  dbRead(d,'username',user);
  dbRead(d,'netztyp',netztyp);
  dbRead(d,'kommentar',komment);
  dbRead(d,'domain',domain);
  msgids:=(dbReadInt(d,'script') and 8=0);
  alias:=(dbReadInt(d,'script') and 4<>0);
  dbClose(d);
  ReadBox(netztyp,bfile,BoxPar);               { Pollbox-Parameter einlesen }
  isdn:=(boxpar^.bport>4);
  if relogin then
    if isdn then begin
      rfehler(739);         { 'Relogin bei ISDN nicht mîglich' }
      exit;
    end else
    case ntRelogin(netztyp) of
      0 : begin
            rfehler(707);   { 'Relogin-Anruf bei dieser Box nicht mîglich' }
            exit;
          end;
      1 : if NoScript(boxpar^.script) then begin
            rfehler(738);   { 'Scriptdatei fÅr Relogin-Anruf erforderlich! }
            exit;
          end;
    end;
  if not net and not ntOnline(netztyp) and NoScript(boxpar^.o_script) then begin
    if netztyp=nt_ppp then rfehler(745) else
    rfehler(708);   { 'Online-Anruf bei dieser Box nicht mîglich' }
    exit;
  end;
  logintyp:=ntTransferType(netztyp);
  _maus:=(logintyp=ltMaus);
  _fido:=(logintyp=ltFido);
  _turbo:=(logintyp=ltTurbo);
  if _turbo then begin
    fehler('Dieser Netztyp wird nicht mehr unterstÅtzt.');
    exit;
  end;
  _uucp:=(logintyp=ltUUCP);
  _ppp:=(logintyp=ltPPP);
  pronet:=(logintyp=ltMagic) and (netztyp=nt_Pronet);
  janusp:=(logintyp=ltZConnect) and BoxPar^.JanusPlus;
  if _maus then begin
    if exist(mauslogfile) then _era(mauslogfile);
    if exist(mauspmlog) then _era(mauspmlog);
    if exist(mausstlog) then _era(mausstlog);
  end;

  with BoxPar^ do
    if alias then OwnFidoAdr:=left(boxname,cpos('/',boxname))+pointname
    else OwnFidoAdr:=boxname+'.'+pointname;
  if crash then begin
    ppfile:=FidoFilename(CrashBox)+'.cp';
    eppfile:=FidoFilename(CrashBox)+'.ecp';
    if FidoIsISDN(CrashBox) and IsBox('99:99/98') then
      FidoGetCrashboxData('99:99/98')
    else
      if IsBox('99:99/99') then
        FidoGetCrashboxData('99:99/99');
    with boxpar^ do begin
      boxname:=MakeFidoAdr(CrashBox,true);
      uparcer:='';
      SendAKAs:='';
      telefon:=FidoPhone(CrashBox,CrashPhone);
      GetPhoneGebdata(crashphone);
      passwort:='';
      SysopInp:=''; SysopOut:='';
      f4D:=true;
      fillchar(exclude,sizeof(exclude),0);
      GetTime:=CrashGettime;
      if not IsBox(boxpar^.boxname) then
        Passwort:=CrashPassword(Boxpar^.boxname);
    end;
  end;
  orgfossil:=comn[boxpar^.bport].fossil;

  if exist(ppfile) and (testpuffer(ppfile,false,ldummy)<0) then begin
    trfehler1(710,ppfile,errortimeout);  { 'Sendepuffer (%s) ist fehlerhaft!' }
    exit;
  end;
  if exist(eppfile) and (testpuffer(eppfile,false,ldummy)<0) then begin
    trfehler1(710,eppfile,errortimeout);  { 'Sendepuffer (%s) ist fehlerhaft!' }
    exit;
  end;
  if not _ppp then
  if not relogin and ((not net) or (boxpar^.sysopinp+boxpar^.sysopout=''))
  then begin
    i:=exclude_time;
    if i<>0 then with boxpar^ do begin
      tfehler(reps(reps(getres(701),exclude[i,1]),exclude[i,2]),errortimeout);
                   { 'Netcalls zwischen %s und %s nicht erlaubt!' }
      exit;
    end;
  end;
  if logintyp=ltMagic then testBL;    { evtl. Dummy-Brettliste anlegen }
  upuffer:=''; caller:='';
  NumCount:=TeleCount; NumPos:=1;
  FlushClose;
  with boxpar^,ComN[boxpar^.bport] do begin
    if not _ppp then
    if relogin and not ISDN and not IgCD and not carrier(bport) then begin
      rfehler(711);    { 'Keine Verbindung!' }
      exit;
    end;
    if once then
      RedialMax:=NumCount;
    if net or ((not net) and _ppp and ntOnline(netztyp)) then begin
      if BoxParOk<>'' then begin
        tfehler(box+': '+BoxParOk+getres(702),errortimeout);   { ' - bitte korrigieren!' }
        exit;
      end;
      if (logintyp in [ltMagic,ltQuick,ltGS,ltMaus]) and not exist('MAGGI.EXE')
      then begin
        trfehler(102,errortimeout);   { 'MAGGI.EXE fehlt!' }
        exit;
      end;
      if _fido then begin
        if not exist('ZFIDO.EXE') then begin
          trfehler(101,errortimeout); { 'ZFIDO.EXE fehlt! }
          exit;
        end;
        if not exist('XP-FM.EXE') then begin
          trfehler(104,errortimeout); { 'XP-FM.EXE fehlt!' }
          exit;
        end;
      end;
      if (logintyp=ltQWK) and not exist('ZQWK.EXE') then begin
        trfehler(111,errortimeout);   { 'ZQWK.EXE fehlt! }
        exit;
      end;
      if _ppp and not exist(ownpath+'UUZ.EXE') then begin
        trfehler(105,errortimeout);   { 'UUZ.EXE fehlt! }
        exit;
      end;
      New(NC);
      fillchar(NC^,sizeof(nc^),0);
      new(addpkts);
      addpkts^.anzahl:=0;
      new(addpp);
      fillchar(addpp^,sizeof(addpp^),0);
      addpp^.pppanz:=0;
      outpmsgs:=0; outepmsgs:=0; inmsgs:=0;
      nc^.abbruch:=false;
      nouuzerror:=true;
      if SysopMode then begin
        NC^.datum:=ZDate;
        NC^.box:=box;
        if SysopStart<>'' then shell(SysopStart,600,1);
        AppendEPP;
        case netztyp of
          nt_Fido : begin
                      SetFilenames;
                      FidoSysopTransfer;
                    end;
          nt_QWK  : QWKSysopTransfer;
          nt_PPP  : begin
                      SetFilenames;
                      PPPSysopTransfer;
                      {hinweis('Sysopmode fÅr RFC/PPP-Boxen in dieser Version noch nicht VerfÅgbar!');}
                    end;
          nt_UUCP : begin
                      SetFilenames;
                      UUCPSysopTransfer;
                    end;
          else      SysopTransfer;
        end;
        RemoveEPP;
        if SysopEnd<>'' then shell(SysopEnd,600,1);
        if SysopNetcall then   { in BoxPar }
          sendnetzanruf(false,false);
        dispose(NC);
        dispose(addpkts);
        dispose(addpp);
        aufbau:=true;
        exit;
      end
      else if logintyp=ltQWK then begin
        rfehler(735);    { 'Netzanruf QWK-Boxen ist nicht mîglich - Sysop-Mode verwenden!' }
        dispose(NC);
        dispose(addpkts);
        dispose(addpp);
        aufbau:=true;
        exit;
      end;
      SetFilenames;

      if exist(upuffer) then _era(upuffer);  { evtl. alte PUFFER lîschen }
      if exist(dpuffer) then _era(dpuffer);
      if exist(caller) then _era(caller);
    end
    else begin   { not net }
      new(NC);
      new(addpkts);
      new(addpp);
      fillchar(addpp^,sizeof(addpp^),0);
      addpp^.pppanz:=0;
      outpmsgs:=0; outepmsgs:=0; inmsgs:=0;
      nc^.abbruch:=false;
      nouuzerror:=true;
    end;

   if net and (IsPath(upuffer) or IsPath(dpuffer)) or
     ((not net) and _ppp and ntOnline(netztyp) and (IsPath(upuffer) or IsPath(dpuffer))) then
   begin
     if IsPath(upuffer) then
       rfehler1(741,getfilename(upuffer))    { 'Lîschen Sie das Unterverzeichnis "%s"!' }
     else
       rfehler1(741,getfilename(dpuffer));
     dispose(NC);
     dispose(addpkts);
     dispose(addpp);
     exit;
   end;

{$IFDEF CAPI }
   if ISDN and not (CAPI_Installed and (CAPI_Register=0)) then begin
     rfehler(740);   { 'ISDN-CAPI-Treiber fehlt oder ist falsch konfiguriert' }
     dispose(NC);
     dispose(addpkts);
     dispose(addpp);
     exit;
   end;
{$ENDIF }

    { Ab hier kein exit mehr! }

    AppendEPP;

    netcalling:=true;
    twin;
    mwriteln;

    showkeys(0);

    if (net and ntPackPuf(netztyp)) or
       ((not net) and _ppp and ntOnline(netztyp)) then
    begin
{$IFDEF CAPI }
      if ISDN then CAPI_suspend;
{$ENDIF }
      assign(f,ppfile);
      if logintyp in [ltMagic,ltQuick,ltGS,ltMaus,ltFido,ltUUCP,ltPPP] then begin
        if not existf(f) then
          makepuf(ppfile,false);      { leeren Puffer erzeugen }
        case logintyp of
          ltMagic : ZtoMaggi(ppfile,upuffer,pronet,1);
          ltQuick : ZtoQuick(ppfile,upuffer,false,1);
          ltGS    : ZtoQuick(ppfile,upuffer,true,1);
          ltMaus  : ZtoMaus(ppfile,upuffer,1);
          ltFido  : begin
                      ZtoFido(ppfile,upuffer,ownfidoadr,1,addpkts,alias);  { ZFIDO }
                      exchange(uparcer,'$UPFILE',caller);
                    end;
          ltPPP   : begin
                     callbox:=box;
                     if not logopen and _ppp then begin
                       new(netlog);
                       assign(netlog^,temppath+nlfile);
                       rewrite(netlog^);
                       logopen:=true;
                      end;
                      with boxpar^ do begin
                        if PPP_UUZ_Spool<>'' then
                        ppp_spool:=PPP_UUZ_Spool else
                        ppp_spool:=OwnPath+XFerDir;
                      end;
                      twin;
                      clrscr;
                      cursor(curoff);
                      window(1,1,80,25);
                      ZtoRFC(true,ppfile,ppp_spool);
                      box:=callbox;
                    end;
          ltUUCP  : ZtoRFC(true,ppfile,XFerDir);
        end;
        RemoveEPP;
        if not (logintyp in [ltUUCP,ltPPP]) then
          spufsize:=_filesize(upuffer);
        if errorlevel=MaggiFehler then begin
          window(1,1,80,25);
          trfehler(712,errortimeout);   { 'Fehler bei Netcall-Konvertierung' }
          if logintyp<>ltPPP then goto ende0 else
          begin
            nc^.abbruch:=true;
            goto ciao;
          end;
        end;
        if (logintyp in [ltQuick,ltGS]) and (spufsize=0) then begin   { nîtig ? }
          makepuf(upuffer,false);
        end;
        if not (logintyp in [ltUUCP,ltPPP]) then begin
          if uparcer<>'' then      { '' -> ungepackte Fido-PKTs }
            shell(uparcer,500,1);
          spacksize:=_filesize(caller);
        end;
      end
      else begin                            { Netcall/ZConnect/Fido }
        if existf(f) then begin             { gepacktes PP erzeugen }
          size:=_filesize(ppfile);
          if size<=2 then erase(f)
          else begin
            if logintyp in [ltNetcall,ltZConnect] then begin
              source:=ppfile;
              ff:=OutFilter(source);
              if ff then assign(f,source);
            end
            else
              ff:=false;
            rename(f,upuffer);
            spufsize:=size;
            shell(uparcer,500,1);           { Upload-Packer }
            if ff then
              erase(f)
            else
              rename(f,ppfile);
            RemoveEPP;
          end;
        end;
        assign(f,caller);
        if not existf(f) then begin
          makepuf(caller,true);
          spufsize:=2; spacksize:=2;
        end
        else
          spacksize:=_filesize(caller);
      end;

      if (uparcer<>'') and not (logintyp in [ltUUCP,ltPPP]) and not exist(caller) then begin
        window(1,1,80,25);
        trfehler(713,errortimeout);   { 'Fehler beim Packen!' }
        goto ende0;
      end;
      CallerToTemp;    { Maggi : OUT.ARC umbenennen }
{$IFDEF CAPI }
      if ISDN then CAPI_resume;
{$ENDIF }
    end;   { if net and not Turbo-Box }

    netcall:=false;

  if not _ppp then begin { !!MH: Anwahl umgehen! }

    ComNr:=bport;
    in7e1:=false; out7e1:=false;
    fossiltest;
    if not ISDN then begin
      SetComParams(bport,fossil,Cport,Cirq);
      if OStype<>OS_2 then
        SaveComState(bport,cps);
      SetTriggerLevel(tlevel);
      if SetUart(bport,baud,PNone,8,1,not IgnCTS) then;   { fest auf 8n1 ... }
    end;
    Activate;
    IgnCD:=IgCD; IgnCTS:=IgCTS;
    mdelay(300);
    flushin;

    if not IgnCTS then begin           { Modem an?  ISDN -> IgnCTS=true }
      i:=3;
      while not GetCTS(comnr) and (i>0) do begin
        time(2);
        while not GetCTS(comnr) and not timeout(false) do
          tb;
        if timeout(false) then begin
          window(1,1,80,25);
          trfehler(714,errortimeout);   { 'Modem nicht bereit - oder etwa ausgeschaltet?' }
          twin;
          writeln;
          if waitkey=keyesc then i:=1;
        end;
        dec(i);
      end;
      if i=0 then begin
        ende:=true;
        if _fido then ReleaseC;
        goto abbruch;
      end;
    end;


    display:=ParDebug;
    ende:=false;
    wahlcnt:=0; connects:=0;

    showkeys(17);

    if net and _fido then begin       { --- FIDO - Mailer --------------- }
      fillchar(nc^,sizeof(nc^),0);
      inmsgs:=0; outmsgs:=0; outemsgs:=0;
      ReleaseC;
      cursor(curoff);
      inc(wahlcnt);
      case FidoNetcall(box,bfile,ppfile,eppfile,caller,upuffer,downarcer,
                       uparcer<>'',crash,alias,addpkts,domain) of
        EL_ok     : begin
                      Netcall_connect:=true;
                      Netcall:=true;
                      goto ende0;
                    end;
        EL_noconn : begin
                      Netcall_connect:=false;
                      goto ende0;
                    end;
        EL_recerr,
        EL_senderr,
        EL_nologin: begin
                      Netcall_connect:=true;
                      inc(connects);
                      goto ende0;
                    end;
        EL_break  : begin
                      Netcall:=false;
                      goto ende0;
                    end;
      else          begin              { Parameter-Fehler }
                      Netcall:=true;
                      goto ende0;
                    end;
      end;
    end;

    recs:=''; lrec:='';
    showconn:=false;
    time(60);
    esctime0;

    if not ISDN then begin        { Modem-Init }
      if HayesComm and not relogin and not timeout(false) then begin
        moff;
        if not display then write(getres2(703,1));   { 'Modem initialisieren...' }
        mon;
        sendstr(#13); {mdelay(150);}    { alte Modem-Befehle verschlucken ... }
        sendstr(#13); mdelay(300);
        flushin;
        sendcomm('AT');
      end;
      if not relogin then begin
        if not timeout(false) then sendmstr(minit^);
        if not timeout(false) then begin
          sendmstr(modeminit);
          if HayesComm and not relogin then begin
            mwriteln; mwriteln;
          end;
        end;
      end;
      if timeout(false) then begin   { Init abgebrochen }
        ende:=true;
        goto abbruch;
      end;
    end;

    nulltime:=typeform.time;
    repeat
      in7e1:=false; out7e1:=false;
      showkeys(15);
      if net and exist(called) and (caller<>called) then _era(called);
      if net then TempToCaller;
      display:=ParDebug;
      inmsgs:=0; outmsgs:=0; outemsgs:=0;
      fillchar(NC^,sizeof(NC^),0);
      NC^.datum:=ZDate;
      NC^.box:=box;
      NC^.starttime:=nulltime;
      if display then begin
        mwriteln; mwriteln;
      end;
      inc(wahlcnt);
      moff;
      if not once then write(wahlcnt:2,'. ');
      write(getres2(703,iif(net,2,3)),box);  { 'Netza' / 'Anruf bei ' }
      if numcount>1 then write(' #',numpos);
      write(getres2(703,4),zeit);    { ' um ' }
      mon;

{$IFDEF CAPI }
      if ISDN then begin                      { ISDN-Anwahl }
        CAPI_showmessages(true,false);
        CAPI_debug:=ParDebug;
        write(' ');
        NC^.telefon:=GetTelefon;
        case CAPI_dial(ISDN_EAZ,NC^.telefon,X75) of
          1 : begin
                writeln('  -  ',getres2(709,4));   { kein Freizeichen }
                goto abbruch;
              end;
          2 : begin
                writeln('  -  ',getres2(709,3));   { keine Verbindung }
                goto abbruch;
              end;
        end;
      end
      else
{$ENDIF CAPI }
      begin                              { Hayes-Anwahl }
        mdelay(150);
        flushin;   { Return verschlucken }
        if display then begin
          mwriteln; mwriteln;
        end;
        if hayescomm and not relogin then begin                  { Anwahl }
          s:=comn[bport].MDial^;
          while pos('\\',s)>0 do begin
            sendcomm(left(s,pos('\\',s)-1));
            delete(s,1,pos('\\',s)+1);
          end;
          NC^.telefon:=GetTelefon;
          sendstr(s+NC^.telefon+#13);
        end;
        numpos:=numpos mod numcount + 1;
        if ParDebug then begin
          zaehler[3]:=1;
          repeat tb until zaehler[3]=0;
        end
        else
          mdelay(500);
        flushin; recs:=''; lrec:='';
        time(connwait);
        noconnstr:=getres2(703,5);    { 'keine Verbindung' }
        showconn:=not display;
        Netcall_connect:=false;
        if ParDebug then begin
          mdelay(200);
          for i:=1 to 20 do tb;
          mwriteln;
        end;
        rz:=''; write('        ');
        if not logopen then begin
          new(netlog);
          assign(netlog^,temppath+nlfile);
          rewrite(netlog^);
          logopen:=true;
        end;
        repeat                         { Warten auf CONNECT }
          if rz<>restzeit then begin
            rz:=restzeit;
            moff;
            write(back7,'(',rz,')');
            mon;
          end;
          tb;
          esctime0;
          if recs='' then XpIdle;
        until (IgnCD and (recs<>'')) or (not IgnCD and carrier(bport))
              or timeout(false) or busy;
        write(back7,sp(7),back7,#8);
        if timeout(true) or
           (IgnCD and hayescomm and not relogin and not TestConnect) then begin
          showconn:=false;
          moff;
          if timeout(true) then writeln('  -  ',noconnstr);
          mon;
          dropdtr(comnr);
          mdelay(100);
          setdtr(comnr);
          sendstr(#13); mdelay(200);
          sendstr(#13); mdelay(200);
          flushin;
          goto abbruch;
        end;
        if busy then goto abbruch;
      end;                              { Ende Hayes-Anwahl }

      NC^.ConnTime:=typeform.time;
      NC^.ConnDate:=typeform.date;
      ConnTicks:=ticker;
      NC^.ConnSecs:=conn_time;    { in BoxPar^ }

      in7e1:=(logintyp=ltUUCP) or uucp7e1;
      out7e1:=uucp7e1;
      startscreen:=BreakLogin and not relogin;    { ^X-Kennzeichen }
      if not net then begin
        display:=true;
        termscr;
      end;
      if net or (o_passwort<>'') then begin
        inc(connects);
        Netcall_connect:=true;
        if not relogin then
          while not timeout(true) and showconn do tb;
        error:=false;
        time(loginwait);
        scrfile:=iifs(net,script,o_script);
        if (scrfile<>'') and exist(scrfile) then begin   { Script-Login }
          if net then wrscript(3,2,col.colkeys,'*Script*')
          else if TermStatus then wrscript(55,1,col.colmenu[0],'*Script*');
          case RunScript(false,scrfile,not net,relogin,netlog) of
            0 : display:=ParDebug or (logintyp=ltMaus);
            1 : error:=true;
            2 : begin error:=true; ende:=true; end;
            3 : begin error:=true; rfehler(731); end;
          end;
          if net then wrscript(3,2,col.colkeys,'        ')
          else wrscript(55,1,$70,'        ');
        end
        else
          case logintyp of                          { Standard-Login }
            ltMagic    : MagicLogin;
            ltMaus     : MausLogin;
            else         login;
          end;
        NC^.logtime:=loginwait-zaehler[2]-brkadd;
        if timeout(true) or error then begin
          if not net then showscreen(false);
          aufhaengen;
          mwriteln;
          NC^.abbruch:=true;
          if net then SendNetzanruf(once,false)
          else ende:=true;
          goto abbruch;
        end;
      end;

      if ende then goto abbruch;

  (*  if net and _turbo then begin            { --- TURBO-BOX Mailer }
        LogExternal(getres(720));
        TurboNetcall;
        goto abbruch;
        end; *)
      if net and (logintyp=ltUUCP) then begin    { --- UUCICO }
        LogExternal(getres(719));
        Netcall := UUCPnetcall;
        goto abbruch;
      end;

      if net then begin
        showkeys(17);

        if (logintyp<>ltMagic) and (logintyp<>ltMaus) then begin
          waitpack(false);
          if (logintyp<>ltQuick) and (logintyp<>ltGS) then
            repeat                             { "Seriennr." Åbertragen }
              if timeout(true) then begin
                aufhaengen;
                mwriteln;
                cursor(curoff);
                NC^.abbruch:=true;
                SendNetzanruf(once,false);
                cursor(curon);
                goto abbruch;
              end;
              zsum:=0;
              { R-}
              for i:=1 to 4 do inc(zsum,ord(zerbid[i]));
              { R+}
              sendstr(zerbid+chr(zsum));
              repeat
                tb; tkey;
              until (pos(ACK,recs)>0) or (pos(NAK,recs)>0) or timeout(true);
            until (pos(ACK,recs)>0) or timeout(true);
          NC^.waittime:=packwait-zaehler[2]-brkadd;
          if timeout(true) then begin
            TimeoutStop1;
            goto abbruch;
          end;
        end;    { of Z-Netz-Packen & Seriennr. }

        if exist(bilogfile) then _era(bilogfile);   { DEL BiModem-Logfile }

        ticks:=ticker;
        if logintyp=ltMagic then begin
          flushin; recs:=''; lrec:='';
        end;
        if (netztyp=nt_ZCONNECT) and janusplus and (trim(downloader)='') then
          EmptySpool('*.*');
        ReleaseC;
        LogExternal(uploader);
        shell(uploader,500,1);                               { Upload }
        LogErrorlevel;
        jperror:=JanusP and (errorlevel<>0);
        NC^.sendtime:=tickdiff;
        if errorlevel=0 then begin
          NC^.sendbuf:=spufsize;
          NC^.sendpack:=spacksize;
        end;
        if logintyp=ltMagic then begin
          Activate;
          time(packwait);
          waitpack(false);
          NC^.waittime:=packwait-zaehler[2]-brkadd;
          if timeout(true) then begin
            TimeoutStop1;
            goto abbruch;
          end;
          ReleaseC;
        end;
        if logintyp=ltGS then begin
          mdelay(500);
          flushin;
          recs:=''; lrec:='';
          { waitpack(true); }
          mdelay(3000);
          inc(NC^.waittime,packwait-zaehler[2]);
        end;
        CallerToTemp;
        if (trim(downloader)<>'') and (errorlevel=0) then begin
          if JanusP then
            EmptySpool('*.*');
          if logintyp=ltMaus then begin
            Activate;
            moff;
            clrscr;
            mon;
            time(packwait);
            WaitForMaus;
            NC^.waittime:=packwait-zaehler[2]-brkadd;
            ReleaseC;
          end
          else
            time(99);
          if not timeout(true) then begin
            ticks:=ticker;
            if pronet then begin
              EmptySpool('*.*');
              chdir(XFerDir_);
              if not multipos(':/',downloader) then
                downloader:=OwnPath+downloader;
              LogExternal(downloader);
              shell(downloader,500,1);
              LogErrorlevel;
              if exist(boxname+'.REQ') or exist(boxname+'.UPD') then begin
                mdelay(1000);
                chdir(XFerDir_);      { File-Download }
                LogExternal(downloader);
                shell(downloader,500,1);
                LogErrorlevel;
              end;
            end
            else begin
              LogExternal(downloader);
              shell(downloader,500,1);                     { Download }
              LogErrorlevel;
            end;
            NC^.rectime:=tickdiff;
          end;
        end;
        Activate;

        if logintyp=ltMaus then
          if relogin then begin
            termscr;
            terminal(false);
            ttwin;
          end
          else
            MausAuflegen
        else
          aufhaengen;


        prodir:=iifs(ProNet,XFerDir,'');
        if exist(prodir+called) or (JanusP and not jperror) then
          if ((errorlevel=0) and not (bimodem and BimodemFehler)) or JanusP
          then begin
            jperror:=(JanusP and (errorlevel<>0));
            cursor(curoff);
            moff;
            clrscr;
            mon;
            if (pronet or (caller<>called)) and exist(caller) then
              _era(caller);
            if exist(dpuffer) then _era(dpuffer);
            if not jperror then begin
              ende:=true;                     { <-- Ende:=true }
              netcall:=true;
            end;
            if not crash then  { !! }
              wrtiming('NETCALL '+ustr(box));
            if pronet then chdir(XFerDir_);
            if JanusP then begin
              if jperror then MoveLastFileIfBad;
              MoveRequestFiles(size);
            end
            else
              size:=_filesize(called);
            NC^.recpack:=size;
            assign(f,iifs(JanusP,XferDir,'')+called);
            if (size<=16) and (called<>dpuffer) then begin
              if not exist(prodir+dpuffer) then
                if existf(f) then
                  rename(f,prodir+dpuffer)
                else
                  MakeFile(prodir+dpuffer);
            end
            else begin
              ReleaseC;
              if ltMultiPuffer(logintyp) then begin    { JANUS/GS-PKT-Puffer }
                if not JanusP then begin
                  EmptySpool('*.*');
                  ChDir(XFerDir_);
                  RepStr(downarcer,called,OwnPath+called);
                end
                else begin
                  ChDir(JanusDir_);
                  erase_mask('*.*');
                  RepStr(downarcer,called,OwnPath+XferDir+'*.*')
                end;
                window(1,1,80,25);
              end;
              if (DownArcer<>'') and
                 (not JanusP or (left(lstr(DownArcer),5)<>'copy ')) then
                shell(downarcer,500,1);      { Download-Packer }
              GoDir(OwnPath);
              if ltMultiPuffer(logintyp) then
                twin;
              Activate;
              case logintyp of
                ltZConnect : if JanusP then   { JANUS-Puffer zusammenkopieren }
                               MovePuffers(JanusDir+'*.*',dpuffer)
                             else
                               MovePuffers(XferDir+'*.*',dpuffer);
                ltGS       : MovePuffers(XferDir+'*.PKT',dpuffer);
              end;                            { GS-PKTs zusammenkopieren }
            end;
            window(1,1,80,25);
            if pronet then begin
              GoDir(ownpath);
              if exist(XFerDir+'BRETTER.LST') then begin
                message('Brettliste fÅr '+ustr(box)+' wird eingelesen ...');
                Readpromaflist(XFerDir+'BRETTER.LST',bfile);
              end;
            end;
            if (logintyp=ltGS) and not exist(dpuffer) then
              makefile(dpuffer);
            if not exist(prodir+dpuffer) then begin
              trfehler(715,errortimeout);  { 'Puffer fehlt! (Fehler beim Entpacken?)' }
              MoveToBad(called);   { fehlerhaftes Paket -> BAD\ }
              TempToCaller;
              end
            else begin
              ReleaseC;
              NC^.recbuf:=_filesize(prodir+dpuffer);
              Del_PP_and_UV;   { .PP/.EPP und unversandte Nachrichten lîschen }
              if exist(prodir+called) then
                _era(prodir+called);            { Platz schaffen.. }
              case logintyp of
                ltMagic : begin
                            MaggiToZ(prodir+dpuffer,PufferFile,pronet,3);
                            olddpuffer:=dpuffer;
                            dpuffer:=PufferFile;
                          end;
                ltQuick,
                ltGS    : begin
                            QuickToZ(dpuffer,'qpuffer',logintyp=ltGS,3);
                            olddpuffer:=dpuffer;
                            dpuffer:='qpuffer';
                          end;
                ltMaus  : begin
                            ft:=filetime(box+'.itg');
                            MausToZ(dpuffer,PufferFile,3);
                            MausGetInfs(box,mauslogfile);
                            MausLogFiles(0,false,box);
                            MausLogFiles(1,false,box);
                            MausLogFiles(2,false,box);
                            if ft<>filetime(box+'.itg') then
                              MausImportITG(box);
                            olddpuffer:=dpuffer;
                            dpuffer:=PufferFile;
                          end;
              else begin
                olddpuffer:='';
                errorlevel:=0;
              end;
            end;
              if errorlevel<>0 then begin
                window(1,1,80,25);
                trfehler(712,errortimeout);      { 'Fehler bei Netcall-Konvertierung' }
                if _filesize(olddpuffer)>0 then
                  MoveToBad(olddpuffer);
              end;
              CallFilter(true,dpuffer);
              Activate;
              if exist(dpuffer) then
                if PufferEinlesen(ownpath+dpuffer,box,false,false,true,pe_Bad)
                then begin
                { if _maus and not MausLeseBest then  - abgeschafft; s. XP7.INC
                    MausPMs_bestaetigen(box); }
                  if nDelPuffer then begin
                    if (olddpuffer<>'') and exist(olddpuffer) and (_filesize(dpuffer)>0) then
                      _era(olddpuffer);
                    if exist(dpuffer) then _era(dpuffer);
                  end;
                end;
              TempToCaller;
              if exist(caller) then _era(caller);
              if jperror then twin;
            end;
          end
          else begin
            MoveToBad(called);
            moff;
            writeln(getres2(713,5));   { 'Netcall abgebrochen; fehlerhaftes Paket wurde im Verzeichnis BAD abgelegt.' }
            mon;
          end;
        SendNetzanruf(once,false);
        end     { if net }

      else begin
        terminal(false);
        ende:=true;
      end;

  abbruch:
      if not ende and ((wahlcnt=redialmax) or (connects=connectmax)) then begin
        ende:=true;
        if not once and (connects<connectmax) then SendNetzanruf(false,false);
      end;

      if not ende then begin
        if (logintyp=ltUUCP) and (ISDN or not ComActive(comnr)) then
          Activate;              { wurde durch UUCPnetcall() abgeschaltet }
        if net then callertotemp;
        showkeys(iif(net,16,18));
        attrtxt(7);
        mwriteln;
        time(iif((numpos=1) or postsperre,redialwait,4));
        rz:='';
        repeat
          multi2(curon);
          if rz<>restzeit then begin
            moff;
            write(#13,getres2(703,iif(net,6,7)),  { 'Warten auf nÑchsten (Netz)anruf... ' }
                  restzeit);
            mon;
            rz:=restzeit;
          end;
          if keypressed then begin
            c:=readkey;
            if c=' ' then time(0)
            else ende:=(c=#27);
          end
          else                   { ISDN: Ring=false }
            if (redialwait-zaehler[2]>1) and ring and rring(comnr) then
              RingSignal   { ^^^ RING-Peak bei bestimmtem Modem amfangen }
            else
              XpIdle;
        until timeout(false) or ende;
        moff;
        write(#13,sp(60));
        mon;
        if not ende then gotoxy(1,wherey-1);
        end;
    until ende;
    if not _fido then begin
      if exist(caller) and ((logintyp<>ltMagic) or ndelpuffer) then
        _era(caller);
      if not ISDN and (net or not carrier(bport)) and ComActive(comnr)
      then begin
        DropDtr(comnr);
        { DropRts(comnr); - Vorsicht, ZyXEL-Problem }
      end;
      if ISDN or ComActive(comnr) then
        ReleaseC;
    end;
    if logopen then begin
      flush(netlog^);
      close(netlog^);
    end;
    if netlog<>nil then begin
      if NetcallLogfile then AppendNetlog;
      _era(temppath+nlfile);
      dispose(netlog);
    end;

ende0:
{$IFDEF CAPI }
    if ISDN then
      CAPI_release     { bei ISDN-CAPI abmelden }
    else
{$ENDIF }
    if net and (OStype<>OS_2) then begin
      RestComState(bport,cps);
      if SetUart(bport,baud,PNone,8,1,not IgnCTS) then;
    end;
    comn[boxpar^.bport].fossil:=orgfossil;

  end else { !!MH: Ende: Anwahl fÅr ppp umgehen }
  with boxpar^ do begin    { !!MH: RFC/PPP: hier nun die Clients aufrufen    }
    WrPlog;
    outerror:=false;
    {window(1,1,80,screenlines);}
    if net then
    MailerShell:=PPP_Shell;     { !!TG: 'Zeilenanzahl fÅr Shell-Routine setzen' }
    if PPP_Dialer <> '' then begin
      exchange(PPP_Dialer,'$CONFIG',bfile+BfgExt);
      LogExternal(PPP_Dialer);
      Shell(PPP_Dialer,600,6);
      LogErrorlevel;
      case errorlevel of
       {1 : trfehler(746,5); }  { 'Verbindung besteht bereits' }
        2 : begin
              trfehler(747,errortimeout); { 'Konnte DFUE-Netzverbindung nicht herstellen' }
              NC^.abbruch:=true;
              Netcall_connect:=false;
              netcall:=false;
              goto ciao;
            end;
        3 : begin
              trfehler(748,errortimeout); { 'Der Eintrag fÅr das DFUE-Netzwerk wurde nicht gefunden' }
              NC^.abbruch:=true;
              Netcall_connect:=false;
              netcall:=false;
              goto ciao;
            end;
      end;
      Netcall_connect:=true;
      netcall:=true;
    end else begin
      Netcall_connect:=true;
      netcall:=true;
    end;
    if not net then begin
      Netcall_connect:=true;
      netcall:=true;
    end;
    if PPP_Mail <> '' then begin
      exchange(PPP_MAIL,'$CONFIG',bfile+BfgExt);
    {$IFDEF ToBeOrNotToBe}
      exchange(PPP_MAIL,'$POP3', Pop3Server+' '+strs(Pop3Port)+' '+Pop3Spool);
      exchange(PPP_MAIL,'$SMTP', SmtpServer+' '+strs(SmtpPort)+' '+SmtpSpool);
      exchange(PPP_MAIL,'$NNTP', NntpServer+' '+strs(NntpPort)+' '+NntpSpool);
      exchange(PPP_MAIL,'$PKTVEC', '0x'+strs(TCP_PktVec));
    {$ENDIF}
      LogExternal(PPP_Mail);
      Shell(PPP_Mail,600,6);
      LogErrorlevel;
      if errorlevel>1 then NC^.abbruch:=true;
    end;
    if PPP_News <> '' then begin
      exchange(PPP_NEWS,'$CONFIG',bfile+BfgExt);
    {$IFDEF ToBeOrNotToBe}
      exchange(PPP_NEWS,'$POP3', Pop3Server+' '+strs(Pop3Port)+' '+Pop3Spool);
      exchange(PPP_NEWS,'$SMTP', SmtpServer+' '+strs(SmtpPort)+' '+SmtpSpool);
      exchange(PPP_NEWS,'$NNTP', NntpServer+' '+strs(NntpPort)+' '+NntpSpool);
      exchange(PPP_NEWS,'$PKTVEC', '0x'+strs(TCP_PktVec));
    {$ENDIF}
      LogExternal(PPP_News);
      Shell(PPP_News,600,6);
      LogErrorlevel;
      if errorlevel>1 then NC^.abbruch:=true;
    end;
    if net then
    if PPP_HangUp <> '' then begin
      exchange(PPP_HangUp,'$CONFIG',bfile+BfgExt);
      LogExternal(PPP_HangUp);
      Shell(PPP_HangUp,600,6);
      LogErrorlevel;
      if errorlevel=1 then trfehler(749,errortimeout); { 'Verbindung bleibt bestehen' }
      if errorlevel>1 then begin
        trfehler(750,errortimeout); { 'Konnte Verbindung nicht trennen' }
        NC^.abbruch:=true;
      end;
    end;
    errorlevel:=0;
    NC^.recbuf:=filesum(PPP_Spool+'*.MSG');
    if exist(PPP_Spool+'*.MSG') then begin
      PPPtoZ; { MainBox konvertieren }
      if nDelPuffer and (errorlevel=0) and (testpuffer(ownpath+dpuffer,false,ldummy)>=0)
      then EmptySpool('*.IN');         { empfangene Dateien lîschen }
    end;
    if exist(PPP_Spool+'*.OUT') then begin
      StoreOutMsgIds;
      EmptySpool('*.OUT'); { ausgehende Pakete lîschen }
      outerror:=true;
    end;
    window(1,1,80,25);     { MainBox: .PP/.EPP und unversandte Nachrichten lîschen }
    if (pos(box,addpp^.ppperrbox)=0) then Del_PP_and_UV;
    if addpp^.pppanz>0 then begin
      saveppfile:=ppfile;
      for i:=1 to addpp^.pppanz do begin
        PPP_Spool:=addpp^.ppp_spool[i];
        if exist(PPP_Spool+'*.MSG') then begin
          NC^.recbuf:=NC^.recbuf + filesum(PPP_Spool+'*.MSG');
          PPP_UUZ_In:=addpp^.ppp_uuzin[i];
          box:=addpp^.pppbox[i];
          PPPtoZ; { alle anderen Boxen konvertieren }
          if nDelPuffer and (errorlevel=0)
          and (testpuffer(ownpath+dpuffer,false,ldummy)>=0)
          then EmptySpool('*.IN'); { empfangene Dateien lîschen }
        end;
        if exist(PPP_Spool+'*.OUT') then begin { alle weiteren Boxen sichern }
          ppfile:=addpp^.ppp_ppfile[i];
          StoreOutMsgIds;
          EmptySpool('*.OUT'); { ausgehende Pakete lîschen }
          outerror:=true;
        end;
      end;
      for i:=1 to addpp^.pppanz do begin
        box:=addpp^.pppbox[i];
        ppfile:=addpp^.ppp_ppfile[i]; { .PP/.EPP und unversandte Nachrichten lîschen }
        if (pos(box,addpp^.ppperrbox)=0) then Del_PP_and_UV;
      end;
      ppfile:=saveppfile;
      box:=callbox;
    end;
    if exist(TempPath+'OUTMSGID.PPP') then _era(TempPath+'OUTMSGID.PPP');
    if exist(TempPath+'OUTMSGID.TMP') then _era(TempPath+'OUTMSGID.TMP');
    olddpuffer:='SAVEPUF.FER';
    if exist(ownpath+dpuffer) then copyfile(ownpath+dpuffer,Temppath+olddpuffer);
    if nouuzerror then begin
      olddpuffer:='';
      wrtiming('NETCALL '+ustr(box)); { TIMING.DAT schreiben: /NetCall/Letzte Anrufe }
    end else begin
      trfehler(712,errortimeout);  { 'Fehler bei Netcall-Konvertierung' }
      if _filesize(Temppath+olddpuffer)>0 then
      MoveToBad(Temppath+olddpuffer);
      NC^.abbruch:=true;
    end;
    if outerror then begin
      trfehler(751,errortimeout); { 'Es konnten nicht alle Nachrichten versendet werden' }
      NC^.abbruch:=outerror;
    end;
    CallFilter(true,ownpath+dpuffer);
    if _filesize(ownpath+dpuffer)>0 then
    if PufferEinlesen(ownpath+dpuffer,box,false,false,true,pe_Bad)
    then begin
      if nDelPuffer then begin
        if (olddpuffer<>'') and exist(Temppath+olddpuffer) and (_filesize(ownpath+dpuffer)>0)
        then _era(Temppath+olddpuffer);
      end;
      if exist(ownpath+dpuffer) then _era(ownpath+dpuffer);
    end;
    if exist(ownpath+caller) then _era(ownpath+caller);
  ciao:
    SendNetzanruf(false,false);
    ende:=true;
    if not nc^.abbruch then begin
      if NntpRescan then begin
        SaveBoxPar:=BoxPar;
        new(BoxPar);
        ReadBoxPar(nt_PPP,box);
        BoxPar^.NntpRescan:=false;
        ReadSomeData;
        WriteBox(bfile,BoxPar,nt_PPP);
        dispose(BoxPar);
        BoxPar:=SaveBoxPar;
      end;
      if addpp^.pppanz>0 then begin
        storebfile:=bfile;
        SaveBoxPar:=BoxPar;
        for i:=1 to addpp^.pppanz do
        if addpp^.pppRescan[i] then begin
          new(BoxPar);
          ReadBoxPar(nt_PPP,addpp^.pppbox[i]);
          BoxPar^.NntpRescan:=false;
          bfile:=copy(addpp^.ppp_ppfile[i],1,length(addpp^.ppp_ppfile[i])-3);
          box:=addpp^.pppbox[i];
          ReadSomeData;
          WriteBox(bfile,BoxPar,nt_PPP);
          dispose(BoxPar);
        end;
        BoxPar:=SaveBoxPar;
        bfile:=storebfile;
        box:=callbox;
      end;
    end;
    if logopen then begin
      flush(netlog^);
      close(netlog^);
    end;
    if assigned(netlog) then begin
      _era(temppath+nlfile);
      dispose(netlog);
    end;
    if exist(RfcLogFile) then _era(RfcLogFile);
    twin;
  end;   { End of PPP-NetCall }

    if net then begin
      if ltVarBuffers(logintyp) then begin
        if (upuffer<>'') and exist(upuffer) then _era(upuffer);
        if (caller<>'') and exist(caller) then _era(caller);
      end;
      RemoveEPP;    { Falls ein TurboBox-Netcall abgebrochen wurde; }
                    { in allen anderen FÑllen ist das EPP bereits   }
                    { entfernt.                                     }
      if exist(ppfile) and (_filesize(ppfile)=0) then
        _era(ppfile);
      DelPronetfiles;
    end;
    freeres;
    dispose(NC);
    dispose(addpkts);
    dispose(addpp);
    netcalling:=false;
    cursor(curoff);
    window(1,1,80,25);
    aufbau:=true;
  end;
  if Netcall_connect and not crash then
    AponetNews;
  {flush(dbg);
  close(dbg);}
end;


{ Achtung: BOX mu· ein gÅltiger Boxname sein! }

procedure netcall_at(zeit:datetimest; box:string);
var brk  : boolean;
    x,y  : byte;
    ende : boolean;
    t    : taste;
    xx   : byte;
    td   : datetimest;

  function timediff:string;
  var t1,t2,td : longint;
  begin
    if zeit=left(time,5) then
      timediff:='00:00:00'
    else begin
      t1:=3600*ival(left(zeit,2))+60*ival(right(zeit,2));
      t2:=3600*ival(left(time,2))+60*ival(copy(time,4,2))+ival(right(time,2));
      if t1<t2 then inc(t1,24*60*60);
      td:=t1-t2;
      timediff:=formi(td div 3600,2)+':'+formi((td div 60) mod 60,2)+':'+
                formi(td mod 60,2);
    end;
  end;

begin
  if zeit='' then begin
    zeit:=left(time,5);
    dialog(36,5,'',x,y);
    maddtime(3,2,getres2(704,1),zeit,false);   { 'autom. Netcall um ' }
    maddtext(31,2,getres2(704,2),0);   { 'Uhr' }
    box:=defaultbox;
    maddstring(3,4,getres2(704,3),box,15,20,'>');   { 'bei  ' }
    mappcustomsel(BoxSelProc,false);
    readmask(brk);
    enddialog;
    if brk then exit;
  end;

  msgbox(38,7,'',x,y);
  moff;
  wrt(x+3,y+2,getres2(704,4));   { 'Netcall bei ' }
  attrtxt(col.colmboxhigh);
  write(box);
  attrtxt(col.colmbox);
  write(getres2(704,5),zeit);    { ' um ' }
  wrt(x+3,y+4,getres2(704,6));   { 'Restzeit:   ' }
  xx:=wherex;
  mon;
  ende:=false;
  showkeys(13);
  attrtxt(col.colkeys);
  td:='';
  repeat
    attrtxt(col.colmboxhigh);
    if timediff<>td then begin
      mwrt(xx,y+4,timediff);
      td:=timediff;
    end;
    multi2(curoff);
    if keypressed then begin
      spush(hotkeys,sizeof(hotkeys));
      hotkeys:=false;
      get(t,curoff);
      spop(hotkeys);
      if t=' ' then begin
        zeit:=left(time,5);
        forcepoll:=true;
      end;
      ende:=(t=keyesc) or (t=mausunright);
    end
    else
      XpIdle;
  until (timediff='00:00:00') or ende;
  closebox;
  freeres;

  if not ende then
    netcall(true,box,false,false,false);
{$IFNDEF Delphi5 } forcepoll:=false; {$ENDIF }
end;


procedure EinzelNetcall(box:string);
var b   : byte;
    h,m : word;
begin
  if box='' then begin
    box:=UniSel(1,false,DefaultBox);         { zu pollende Box abfragen }
    if box='' then exit;
  end;
  ReadBoxPar(0,box);
  b:=exclude_time;
  if b=0 then
    if netcall(true,box,false,false,false) then
    else
  else with boxpar^ do begin
    h:=ival(left(exclude[b,2],2));
    m:=ival(right(exclude[b,2],2));
    inc(m);
    if m>59 then begin
      m:=0; inc(h);
      if h>23 then h:=0;
    end;
    netcall_at(formi(h,2)+':'+formi(m,2),box);
  end;
end;


procedure autosend(s:string);
var p,p2 : byte;
    box  : string[BoxNameLen];
begin
  p:=cpos(':',s);
  if p=0 then
    trfehler(716,errortimeout)   { 'fehlerhafte /ips:-Angabe' }
  else begin
    p2:=cpos('_',s);      { Fido: '_' -> ':' }
    if (p2>0) and (p2<p) and (ival(left(s,p2-1))>0) then
      s[p2]:=':';
    box:=left(s,p-1);
    if not isbox(box) then
      trfehler1(709,box,errortimeout)    { 'unbekannte Box: %s }
    else begin
      s:=mid(s,p+1);
      if exist(s) then
      if PufferEinlesen(s,box,false,true,ParEmpfbest,0) then begin
        AppPuffer(box,s);
        _era(s);
      end;
    end;
  end;
end;


function AutoMode:boolean;
var brk: boolean;
begin
{$IFDEF Debug }
  dbLog('-- AutoMode');
{$ENDIF }
  automode:=false;
  if ParSetuser<>'' then
    SetUsername(ParSetuser);
  if ParPuffer<>'' then
    if exist(ParPuffer) then
      if PufferEinlesen(ParPuffer,DefaultBox,ParPufED,false,ParEmpfbest,0) then;
  if ParSendbuf<>'' then
    AutoSend(ParSendbuf);
  if ParNetcall<>'' then
    if ParNetcall='*' then
      AutoTiming(-1,true,false)      { Netcall/Alle }
    else if not isbox(ParNetcall) then
      trfehler1(717,ParNetcall,errortimeout)   { '/n: Unbekannte Serverbox: %s' }
    else
      if ParNCtime='' then
        Netcall(true,ParNetcall,false,ParRelogin,false)
      else
        Netcall_at(ParNCtime,ParNetcall);
  if ParTiming>0 then begin
    AutoTiming(ParTiming,false,false);
    if quit then automode:=true;
  end;
  if ParDupeKill then
    DupeKill(true);
  if ParReorg then begin
    MsgReorgScan(true,false,brk);
    if not brk then MsgReorg;
  end;
  if ParPack or ParXPack then
    if ParXPfile<>'' then
      PackOne(ParXPfile)
    else
      PackAll(parxpack);
  if ParAV<>'' then begin
    if not multipos('\:',parav) then begin
      if right(shellpath,1)<>'\' then ParAV:='\'+ParAV;
      ParAV:=ShellPath+ParAV;
    end;
    if not exist(ParAV) then
      rfehler(718)   { 'Datei nicht vorhanden' }
    else
      FileArcViewer(ParAV);
    Automode:=true;
  end;
  if ParKey>' ' then begin
    clearkeybuf;       { wegen Maus }
    keyboard(ParKey);
  end;
  if ParSsaver then
    scsaver;
  if ParExit then automode:=true;
  ParGelesen:=false;
end;


end.
{
  $Log: xp7.pas,v $
  Revision 1.106  2002/02/14 09:42:15  MH
  - Fix: NntpRescan wurde nach Netcall nicht zurÅckgesetzt

  Revision 1.105  2001/12/26 09:21:45  MH
  - Fix in RFC/PPP-Netcall (UUZ_In): Variable zu kurz

  Revision 1.104  2001/09/10 09:48:02  MH
  RFC/PPP:
  - TCP/IP-MenÅ und dessen Parameter entfernt (UKAD wird nicht mehr angeboten)
  - MenÅs angepasst

  Revision 1.103  2001/08/02 01:45:30  MH
  - RFC/PPP: Anpassungen im Mailclientbereich

  Revision 1.102  2001/07/23 20:29:39  MH
  - RFC/PPP: UUZ-Parameter '-b' hinzugefÅgt

  Revision 1.101  2001/07/22 12:06:47  MH
  - FindFirst-Attribute ge‰ndert: 0 <--> DOS.Archive

  Revision 1.100  2001/07/20 11:46:49  MH
  - wir initialisieren mal eine Wichtigkeit (addppp)

  Revision 1.99  2001/07/14 11:09:20  MH
  - ';' vergessen...

  Revision 1.98  2001/07/14 11:05:53  MH
  - Multiboxbetrieb beachtet beim Puffereinlesen Vertreter der jeweiligen Box

  Revision 1.97  2001/07/10 22:50:20  MH
  - UKAD-Parameter korrigiert (news)

  Revision 1.96  2001/06/18 20:17:36  oh
  Teames -> Teams

  Revision 1.95  2001/04/04 19:57:02  oh
  -Timeouts konfigurierbar

  Revision 1.94  2001/03/23 15:49:35  tg
  $POP, $SMTP, $NNTP und $PKTVEC Feature

  Revision 1.93  2001/03/22 02:45:30  oh
  -Tempfile werden im Temp-Verzeichnis angelegt

  Revision 1.92  2001/03/20 18:58:24  tg
  MailerShell

  Revision 1.91  2001/02/26 22:21:05  MH
  - Fixversuch (JG) gegen Probleme bei langsamen Modems

  Revision 1.90  2000/12/25 17:17:17  MH
  RFC/PPP-Netcall Fix:
  - Probleme beim lîschen der alten Msg-Dateien behoben
  - Probleme bei nicht versendeten KopienempfÑnger behoben
  - Netcall Anrufliste

  Revision 1.89  2000/12/19 16:55:23  MH
  RFC/PPP-Netcall Fix:
  - Probleme beim lîschen der alten Msg-Dateien behoben

  Revision 1.88  2000/12/17 21:19:54  MH
  RFC/PPP-Netcall:
  - Probleme beim lîschen der alten Msg-Dateien behoben

  Revision 1.87  2000/12/09 16:37:40  MH
  - vor schlie·en flushen

  Revision 1.86  2000/12/03 18:35:00  MH
  - Logs vor dem schlie·en flushen

  Revision 1.85  2000/12/03 09:55:29  MH
  RFC/PPP:
  - Fix: Online-NetCall

  Revision 1.84  2000/11/04 17:38:38  MH
  RFC/PPP: Netcall/Bericht - Errorlevel 1 bei Mail/News-Client ignorieren

  Revision 1.83  2000/10/28 09:49:10  MH
  RFC/PPP: Fixes uvs

  Revision 1.82  2000/10/27 11:39:00  MH
  RFC/PPP: Kleiner Umbau des BoxmenÅs

  - ReplaceOwn bei weiteren Boxen hinzugefÅgt

  Revision 1.81  2000/10/26 14:48:44  MH
  RFC/PPP: Eingelesenen Puffer immer lîschen

  Revision 1.80  2000/10/11 17:04:01  MH
  RFC/PPP: Fix:
  - String fÅr UUZ-In/Out zu kurz

  Revision 1.79  2000/10/10 11:26:13  MH
  Weitere öberarbeitungen...

  Revision 1.78  2000/09/23 23:38:23  MH
  Baustellen bereinigt

  Revision 1.77  2000/09/21 17:28:28  MH
  HdrOnlyKill jetzt direkt in Puffereinlesen integriert

  Revision 1.76  2000/09/11 19:33:15  MH
  HdrOnlyRequest:
  Kleine Sicherung hinzugefÅgt, damit die ID-Files nicht
  entfernt werden, wenn keine öbertragung stattgefunden hat

  Revision 1.75  2000/09/09 20:44:44  MH
  HdrOnlyKill: ID-Files Sicherheitshalber auch lîschen

  Revision 1.74  2000/09/09 13:35:26  MH
  HeaderOnlyKill: Jetzt FunktionsfÑhig (Thomas: grrrrr)!
  Au·erdem mehrfach abgesichert...

  Revision 1.73  2000/09/05 19:34:55  MH
  HdrOnly [KILL]:
  Kleine Vereinfachung kosmetischer Natur

  Revision 1.72  2000/09/03 15:52:26  MH
  HeaderOnly-Killer implementiert: Dieser ist nur dann aktiv,
  wenn sich die Datei 'DEBUG_K.ILL' im XP-Verzeichnis befindet

  Revision 1.71  2000/09/02 13:59:17  MH
  - Bei PMs wird E-MAIL.ID geschrieben.
  - Markierte Nachrichten werden auf lîschen gesetzt

  Revision 1.70  2000/08/24 21:45:40  rb
  FindFirst/FindClose-Fixes

  Revision 1.69  2000/08/16 16:40:49  MH
  RFC/PPP: Kleineren unbedeutenden Fix

  Revision 1.68  2000/08/13 02:59:08  MH
  RFC/PPP: Message-ID Request:
  Nach einem erfolgreichen Netcall werden die ID-Files gelîscht

  Revision 1.67  2000/08/13 02:32:34  MH
  RFC/PPP: Message-ID Request implementiert

  Revision 1.66  2000/08/07 13:55:11  MH
  RFC/PPP:
  Bei mi·lungenen BinÑrversandt von Nachrichten grî·er maxbinsave
  wird das Unversandt-Flag entfernt und eine Meldung ausgegeben

  Revision 1.65  2000/08/06 16:26:21  MH
  RFC/PPP: Fix:
  o Bei einem OutGoing-UUZ-Error konnten unter UmstÑnden
    Unversandte Nachrichten verloren gehen.
  o Artikelpointer (Rescan) werden nun bei Erfolg zurÅckgesetzt

  Revision 1.64  2000/08/05 09:40:13  MH
  RFC/PPP: Kînnen wÑhrend eines Netcalls nicht alle
  Nachrichten versendet werden, und der Puffer enthÑlt
  BinÑrnachrichten und die Einstellung fÅr das speichern
  solcher Nachrichten (maxbinsave) ist grî·er '0', dann
  bleiben alle Nachrichten auf Unversandt, auch wenn sie
  teilweise bereits versendet wurden.

  Revision 1.63  2000/08/01 13:59:44  MH
  RFC/PPP: Fix:
  An TIMING.DAT und beim Puffereinlesen wurde, wenn
  'Pakete mitsenden' aktiv, die falsche Box Åbergeben

  Revision 1.62  2000/07/23 00:11:23  MH
  RFC/PPP: Meldung bei bestehender Verbindung entfernt

  Revision 1.61  2000/07/15 16:29:17  MH
  *** empty log message ***

  Revision 1.60  2000/07/15 16:16:14  MH
  RFC/PPP: AufrÑumen vergessen...grrrr

  Revision 1.59  2000/07/15 16:10:04  MH
  RFC/PPP: Fix Clearunversandt:
  Befand sich das Temp-Verzeichnis auf einem anderen Laufwerk,
  funktionierte das sichern der liegen gebliebenen Nachrichten
  nicht mehr

  Revision 1.58  2000/07/15 13:52:36  MH
  RFC/PPP: An einigen Stellen InOutRes zurÅckgesetzt

  Revision 1.57  2000/07/15 12:48:40  MH
  RFC/PPP: Fix: Evtl. konnte bei Clearunversandt eine
           Wichtigkeit nicht umbenannt werden

  Revision 1.56  2000/07/15 10:38:34  MH
  RFC/PPP: Online-Anruf in verÑnderter Form eingebunden
           (siehe Onlinehilfe)

  Revision 1.55  2000/07/14 19:16:13  MH
  RFC/PPP: Doppelt erscheinende Meldung entfernt

  Revision 1.54  2000/07/13 13:56:58  MH
  RFC/PPP: Sysoptransfer fertig gestellt

  Revision 1.53  2000/07/13 00:48:09  MH
  RFC/PPP: Meldungen sollten nun ohne Cursor erscheinen

  Revision 1.52  2000/07/12 10:01:32  MH
  RFC/PPP: Einige Meldungen in die Resourcen aufgenommen

  Revision 1.51  2000/07/11 19:10:37  tg
  Error-Meldungen ueberarbeitet

  Revision 1.50  2000/07/11 14:36:51  MH
  RFC/PPP: Weitere énderungen hinsichtlich Netcall/Alle vorgenommen

  Revision 1.49  2000/07/11 14:16:47  MH
  RFC/PPP: énderungen hinsichtlich Netcall/Alle vorgenommen

  Revision 1.48  2000/07/03 22:11:15  MH
  RFC/PPP: Fix:
  - Ausgangsfilter
  - Dupes (incomming)

  Revision 1.47  2000/07/03 10:37:56  MH
  RFC/PPP: Fix: Netcall-Automatik

  Revision 1.46  2000/07/03 01:20:24  MH
  RFC/PPP: Fehlt UUZ.EXE wird Netcall abgebrochen

  Revision 1.45  2000/07/02 23:46:53  MH
  RFC/PPP: Netzanrufbericht:
  - schreibt (Fehler) in den Betreff
  - kosmetisch aufgebessert

  Revision 1.44  2000/07/02 11:58:01  MH
  RFC/PPP: Code ein wenig aufgerÑumt

  Revision 1.43  2000/07/02 11:11:39  MH
  RFC/PPP: UUZ wird nun auch Outgoing mitgelogt

  Revision 1.42  2000/07/01 06:29:50  MH
  RFC/PPP: Errorlevel wird vor UUZ zurÅckgesetzt

  Revision 1.41  2000/06/30 21:33:57  MH
  RFC/PPP: Noch einige wichtige énderungen...

  Revision 1.40  2000/06/30 19:45:16  MH
  RFC/PPP: Onlineanruf verboten...

  Revision 1.39  2000/06/30 17:15:47  MH
  RFC/PPP: NetCall-Fehlermeldungen beenden sich nach 30 Sek. selbst

  Revision 1.38  2000/06/30 11:22:37  MH
  RFC/PPP: Pakete mitsenden:
  - ClearDir verbessert

  Revision 1.37  2000/06/29 20:47:35  MH
  RFC/PPP: Kleinen Unfall gefixed...

  Revision 1.36  2000/06/29 19:13:17  MH
  RFC/PPP: Errorlevelabfrage verschoben...

  Revision 1.35  2000/06/29 18:10:17  MH
  RFC/PPP: Fix fÅr Netzanrufbericht:
  - Variable fÅr eingehende Nachrichten wurde nicht zurÅckgesetzt

  Revision 1.34  2000/06/29 15:07:07  MH
  RFC/PPP: Kleinere énderungen um Konvertierungsfehler:
  - zu beseitigen
  - weitere zu finden: Dazu wird eine Temp-Datei vorrÅbergehend ins
    XP-Verzeichnis geschrieben (nur OutGoing)...bitte da mal reinsehen

  Revision 1.33  2000/06/28 21:17:13  MH
  RFC/PPP: - Neue Makros fÅr UUZ (In/Out) angelegt:
  - $SCREENLINES, $SPOOL, $PUFFER

  Revision 1.32  2000/06/28 16:36:07  MH
  RFC/PPP: *.OUT-Behandlung nun unabhÑngig vom Errorlevel

  Revision 1.31  2000/06/27 15:34:11  MH
  RFC/PPP: Fix: Pakete mitsenden:
  - unversandte Mails wurden gelîscht

  Revision 1.30  2000/06/26 17:37:04  MH
  RFC/PPP: Pakete mitsenden:
  - Nicht versendete Nachrichten bleiben auf Unversandt und
    der Puffer wird entsprechend angepasst, falls einige
    Nachrichten versendet werden konnten
  - Netzanrufbericht sollte nun auch zusÑtzlich entstehendes
    Mailaufkommen berÅcksichtigen

  Revision 1.29  2000/06/24 10:16:29  MH
  RFC/PPP: Pakete mitsenden:
  nDelPuffer-Schalter wird nun beim lîschen von *.MSG berÅcksichtigt

  Revision 1.28  2000/06/24 06:32:55  MH
  RFC/PPP: Pakete mitsenden:
  Nach der Konvertierung und Puffertest werden
  die MSG-Dateien aus den SpoolDirs entfernt

  Revision 1.27  2000/06/23 17:56:51  MH
  RFC/PPP: Pakete mitsenden:
  Einige Abfragen eingespart, um das wechseln zwischen
  den Boxen zu beschleunigen

  Revision 1.26  2000/06/23 15:38:33  MH
  RFC/PPP: Fix Pakete mitsenden:
  Wurde beim SpoolDir nichts eingetragen, dann wurde dieses
  nicht durch das StandardSpoolDir ersetzt

  Revision 1.25  2000/06/22 12:29:15  MH
  RFC/PPP: Fix Pakete mitsenden: PPP_UUZ_In wurde nicht gewechselt

  Revision 1.24  2000/06/22 09:24:27  MH
  RFC/PPP: Pakete mitsenden: Kosmetische Aenderung

  Revision 1.23  2000/06/22 07:41:44  MH
  RFC/PPP: Pakete mitsenden: UUZ_In wird nun auch beachtet

  Revision 1.22  2000/06/21 07:02:47  MH
  RFC/PPP: Pakete mitsenden implementiert

  Revision 1.21  2000/06/18 21:52:26  MH
  RFC/PPP: UUZ-SpoolDir eingerichtet (f. Pakete mitsenden v. Bedeutung)

  Revision 1.20  2000/06/18 08:31:52  MH
  RFC/PPP: LogFile kann vom Client f. Bericht beschrieben werden

  Revision 1.19  2000/06/11 10:56:10  MH
  RFC/PPP: Pruefung, ob UUZ.EXE vorhanden

  Revision 1.18  2000/06/11 10:38:30  MH
  RFC/PPP: Beim NetCall wird die Existenz der Clients geprueft

  Revision 1.17  2000/06/10 19:05:26  MH
  RFC/PPP: Fehlerhandling nochmals angepasst

  Revision 1.16  2000/06/10 10:51:20  MH
  RFC/PPP: Bei Fehler wird nun auch der Eingangspuffer gesichert

  Revision 1.15  2000/06/09 23:40:33  MH
  RFC/PPP: *.MSG werden per Schalter PufferLoeschen spaetestens beim naechsten Call entfernt

  Revision 1.14  2000/06/09 16:43:23  MH
  RFC/PPP: Puffersicherung bei Fehler verbessert

  Revision 1.13  2000/06/08 18:31:03  MH
  RFC/PPP: UUZ Voreinstellung (F2) ins BoxMenue eingebunden

  Revision 1.12  2000/06/07 22:25:03  MH
  *** empty log message ***

  Revision 1.11  2000/06/06 11:34:51  MH
  RFC/PPP: Es wird ein LogFile geschrieben

  Revision 1.10  2000/06/06 08:00:16  MH
  RFC/PPP: Weitere Anpassungen und Fixes

  Revision 1.9  2000/06/04 04:22:51  MH
  RFC/PPP: Errorlevelhandling angepasst

  Revision 1.8  2000/06/02 13:54:45  MH
  RFC/PPP: Onlineanruf/Letzter Anruf hinzugefuegt

  Revision 1.7  2000/06/02 12:51:36  MH
  RFC/PPP: ShellMode geaendert

  Revision 1.6  2000/06/02 08:36:23  MH
  RFC/PPP: LoginTyp hergestellt

  Revision 1.5  2000/04/10 22:13:12  rb
  Code aufgerÑumt

  Revision 1.4  2000/04/09 18:27:20  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.8  2000/03/14 15:15:40  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.7  2000/03/02 18:32:24  mk
  - Code ein wenig aufgeraeumt

  Revision 1.6  2000/02/19 11:40:08  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.5  2000/02/18 17:28:09  mk
  AF: Kommandozeilenoption Dupekill hinzugefuegt

}