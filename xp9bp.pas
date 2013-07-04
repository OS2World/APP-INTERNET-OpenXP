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
{ $Id: xp9bp.pas,v 1.41 2001/09/11 09:25:43 MH Exp $ }

{ CrossPoint - BoxPar verwalten }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp9bp;

interface

uses xpglobal, dos,typeform,fileio,datadef,database,xp0,xp1,xp2,xpnt;


const bm_changesys  = 1;
      bm_GUP        = 2;
      bm_Feeder     = 3;
      bm_AutoSys    = 4;
      bm_postmaster = 5;

procedure nt_bpar(nt:byte; var bpar:BoxRec);
procedure DefaultBoxPar(nt:byte; bp:BoxPtr);
procedure ReadBox(nt:byte; dateiname:pathstr; bp:BoxPtr);
procedure WriteBox(dateiname:pathstr; bp:BoxPtr; nt:byte);
procedure ReadBoxPar(nt:byte; box:string);
function  BoxBrettebene(box:string):string;

procedure ReadQFG(dateiname:pathstr; var qrec:QfgRec);
procedure WriteQFG(dateiname:pathstr; qrec:QfgRec);


implementation  { ------------------------------------------------- }


procedure nt_bpar(nt:byte; var bpar:BoxRec);
var i : integer;
begin
  with bpar do
    case nt of
      nt_Quick : begin
                   uparcer:='lharc a $UPFILE $PUFFER';
                   downarcer:='lharc e $DOWNFILE';
                   loginname:='NET410';
                 end;
      nt_Maus  : begin
                   pointname:=boxname;
                   exclude[1,1]:='04:00';
                   exclude[1,2]:='06:00';
                   for i:=2 to excludes do begin
                     exclude[i,1]:='  :  ';
                     exclude[i,2]:='  :  ';
                     end;
                   MagicBrett:='/MAUS/';
                 end;
      nt_Magic : begin
                   zerbid:='2200';
                   lightlogin:=false;
                 end;
      nt_Fido  : MagicBrett:='/FIDO/';
      nt_UUCP  : begin
                   uparcer:='compress -v -b12 $PUFFER';
                   downarcer:='compress -vdf $DOWNFILE';
                   unfreezer:='freeze -vdif $DOWNFILE';
                   ungzipper:='gzip -vdf $DOWNFILE';
                   chsysbetr:='your latest sys file entry';
                 end;
      nt_PPP   : begin
                   pointname:=boxname;
                   uparcer:='';
                   downarcer:='';
                   ungzipper:='';
                   unfreezer:='';
                 end;
      nt_Pronet: begin
                   MagicNET:='ProNET';
                   MagicBrett:='/PRONET/';
                   pointname:='01';
                   downloader:='gsz.exe portx $ADDRESS,$IRQ rz';
                 end;
      nt_Turbo : MagicBrett:='/IST/';
    end;
end;


procedure DefaultBoxPar(nt:byte; bp:BoxPtr);
var i  : integer;
begin
    fillchar(bp^,sizeof(bp^),0);
    with bp^ do begin
      passwort  := iifs(deutsch,'GEHEIM','SECRET');
      areapw    := iifs(deutsch,'GEHEIM','SECRET');
      telefon   := '011-91';
      zerbid    := '0000';
      uploader  := 'Zmodem';
      downloader:= 'Zmodem';
      prototyp  := 'Z';
      uparcer   := 'pkzip $UPFILE $PUFFER';
      downarcer := 'pkunzip $DOWNFILE';
      uparcext  := 'ZIP';
      downarcext:= 'ZIP';
      connwait  := 45;
      loginwait := 60;
      redialwait:= 240;
      redialmax := 100;
      connectmax:= 5;
      packwait  := 1200;
      retrylogin:= 10;
      conn_time := 5;
      owaehlbef := '';
      mincps    := 150;
      bport     := 2;
      params    := '8n1';
      baud      := 19200;
      gebzone   := 'City';
      o_passwort:= iifs(deutsch,'GEHEIM','SECRET');
      o_logfile := '';
      MagicNet  := 'MagicNET';
      MagicBrett:= '/MAGIC/';
      for i:=1 to excludes do begin
        exclude[i,1]:='  :  ';
        exclude[i,2]:='  :  ';
      end;
      fPointNet:=20000;
      f4D:=true;
      fTosScan:=true;
      areaplus:=false;
      areabetreff:=true;
      EMSIenable:=true;
      AKAs:=''; SendAKAs:='';
      FileScanner:='FileScan';
      FilescanPW:=iifs(deutsch,'GEHEIM','SECRET');
      LocalIntl:=true;
      GetTime:=false;
      LightLogin:=false;
      SendTrx:=false;
      NotSEmpty:=false;
      brettmails:=true;
      MaxWinSize:=7;
      MaxPacketSize:=64;
      VarPacketSize:=true; ForcePacketSize:=false;
      if nt=nt_ppp then SizeNego:=false else
      SizeNego:=true;
      if nt=nt_ppp then UUsmtp:=true else
      UUsmtp:=false;
      UUprotos:='Ggz';
      efilter:='';
      afilter:='';
      SysopNetcall:=true;
      SysopPack:=false;
      PacketPW:=false;
      ExtPFiles:=false;
      uucp7e1:=false;
      DelQWK:=true;
      BMtyp:=bm_changesys;
      BMdomain:=false;
      maxfsize:=0;
      janusplus:=false;

      Pop3Server := 'pop.t-online.de';
      Pop3Port := 110;
      Pop3User := '';
      Pop3Pass := iifs(deutsch,'GEHEIM','SECRET');
      Pop3Envelope := '';
      Pop3UseEnvelope := false;
      Pop3Keep := false;
      Pop3Spool := ownpath+xferdir;
      Pop3TimeOut := 30;
      Pop3MaxLen := 4194304;
      Pop3ReportInfo := '';
      IMAP := false;
      Pop3Auth := false;
      SmtpServer := 'mailto.t-online.de';
      SmtpFallback := '';
      SmtpUser := '';
      SmtpPass := iifs(deutsch,'GEHEIM','SECRET');
      SmtpPort := 25;
      SmtpEnvelope := '';
      SmtpAfterPop := false;
      SmtpAfterPopTimeOut := 20;
      SmtpAfterPopDelay := 1;
      SmtpSpool := ownpath+xferdir;
      SmtpTimeOut := 30;
      SmtpReportInfo := '';
      SmtpAuth := 'disabled';
      NntpServer := 'news.t-online.de';
      NntpFallback := '';
      NntpPort := 119;
      NntpUser := '';
      NntpPass := iifs(deutsch,'GEHEIM','SECRET');
      NntpList := true; {'enabled';}
      NntpTimeOut := 30;
      NntpSpool := ownpath+xferdir;
      NntpMaxLen := 65536;
      NntpNewMax := 2500;
      NntpDupeSize := 65536;
      NntpRescan := false; {'disabled';}
      NntpQueue := 10;
      NntpArtclAnz:=10;
      NntpReportInfo := '';
      NntpPosting := true; {'enabled';}
      {NntpReplaceOwn := 'disabled';}
      ReplaceOwn := false;
      PPP_Dialer := 'WDIAL.EXE /DIAL $CONFIG';
      PPP_HangUp := 'WDIAL.EXE /HANGUP $CONFIG';
      PPP_Mail := 'E-MAIL.EXE $CONFIG';
      PPP_News := 'E-NEWS.EXE $CONFIG';
      PPP_UUZ_Out := '';
      PPP_UUZ_In := '';
      PPP_UUZ_Spool := ownpath+xferdir;
      PPP_Shell:=Screenlines;
    {$IFDEF ToBeOrNotToBe}
      TCP_PktDrv := '';
      TCP_PktVec := 60;
      TCP_PktInt := 14;
      TCP_NameServer := '';
      TCP_Gateway := '0.0.0.0';
      TCP_Netmask := '0.0.0.0';
      TCP_LocalIP := '';
      TCP_Socket_Timeout := 60;
      TCP_Bootp_Timeout := 60;
    {$ENDIF}
      DialInAccount := 'T-Online';
      DialInNumber := '0191011';
      DialInPass := iifs(deutsch,'GEHEIM','SECRET');
      DialInUser := '';
      RedialOnBusy := 3;
      RedialTimeout := 60;
      HangupTimeout := 0;
      PerformPass := false;
      AfterDialinState := true;
      AskForDisconnect := false;
      XpScoreAktiv := false;
      ScoreFile := '';
      PPP_KillFile := '';
      PPP_BoxPakete := '';
      MailerDaemon := false;
    end;
    nt_bpar(nt,bp^);
end;


{ Box- Parameter aus angegebener Datei lesen }
{ bp^ mu· initialisiert sein.                }

procedure ReadBox(nt:byte; dateiname:pathstr; bp:BoxPtr);
var t      : text;
    s,su   : string;
    p      : byte;
    dummyb : byte;
    dummys : string[10];
    dummyl : boolean;
    dummyw : smallword;
    dummyr : real;
    i      : integer;

  function get_exclude:boolean;
  var n : byte;
  begin
    get_exclude:=false;
    if (left(su,10)='AUSSCHLUSS') then begin
      n:=ival(copy(s,11,1));
      if (n>=1) and (n<=excludes) then begin
        BoxPar^.exclude[n,1]:=copy(s,p+1,5);
        BoxPar^.exclude[n,2]:=copy(s,p+7,5);
        get_exclude:=true;
        end;
      end;
  end;

begin
  assign(t,dateiname+BfgExt);
  DefaultBoxPar(nt,bp);
  if existf(t) then begin
    reset(t);
    with bp^ do
      while not eof(t) do begin
        readln(t,s);
        if (s<>'') and (left(s,1)<>'#') then begin
          su:=ustr(s);
          p:=pos('=',s);
          if (p=0) or not (
            get_exclude or
            (s=bfgver+bfgnr) or
            gets(s,su,'Boxname',boxname,BoxNameLen) or
            gets(s,su,'Pointname',pointname,25) or
            gets(s,su,'Username',username,30) or
            gets(s,su,'Domain',dummys,1) or
            gets(s,su,'FQDN',dummys,1) or  {16.01.00 HS}
            gets(s,su,'Passwort',passwort,25) or
            gets(s,su,'Telefon',telefon,60) or
            gets(s,su,'ZerbID',zerbid,4) or
            getb(su,  'Netztyp',dummyb) or
            gets(s,su,'Upload',uploader,100) or
            gets(s,su,'Download',downloader,100) or
            gets(s,su,'ProtokollTyp',prototyp,1) or
            gets(s,su,'ZMOptions',ZMOptions,60) or
            gets(s,su,'UpArc',uparcer,60) or
            gets(s,su,'DownArc',downarcer,60) or
            gets(s,su,'UnFreeze',unfreezer,40) or
            gets(s,su,'UnGZIP',ungzipper,40) or
            gets(s,su,'UpArcExt',uparcext,3) or
            gets(s,su,'DownArcExt',downarcext,3) or
            geti(su,  'ConnWait',connwait) or
            geti(su,  'LoginWait',loginwait) or
            geti(su,  'RedialWait',redialwait) or
            geti(su,  'RedialMax',redialmax) or
            geti(su,  'ConnectMax',connectmax) or
            geti(su,  'PackWait',packwait) or
            geti(su,  'RetryLogin',retrylogin) or
            geti(su,  'ConnectTime',conn_time) or
            gets(s,su,'Waehlbef',owaehlbef,10) or
            gets(s,su,'ModemInit',modeminit,60) or
            geti(su,  'cpsmin',mincps) or
            getb(su,  'Port',bport) or
            gets(s,su,'Params',params,3) or
            getl(su,  'Baud',baud) or
            getr(su,  'GebuehrNormal',dummyr) or
            getr(su,  'GebuehrBillig',dummyr) or
            getw(su,  'GebuehrProEinheit',dummyw) or
            gets(s,su,'Waehrung',dummys,5) or
            gets(s,su,'Tarifzone',gebzone,20) or
            gets(s,su,'SysopInFile',sysopinp,60) or
            gets(s,su,'SysopOutfile',sysopout,60) or
            gets(s,su,'SysopStartprg',sysopstart,60) or
            gets(s,su,'SysopEndprg',sysopend,60) or
            gets(s,su,'OnlinePasswort',o_passwort,25) or
            gets(s,su,'LogFile',o_logfile,60) or
            gets(s,su,'MagicNET',magicnet,8) or
            gets(s,su,'MagicBrett',magicbrett,25) or
            getw(su,  'FidoFakenet',fPointNet) or
            getx(su,  'Fido4Dadr',f4D) or
            getx(su,  'TosScan',fTosScan) or
            getx(su,  'LocalINTL',localintl) or
            getx(su,  'FidoArea+',areaplus) or
            getx(su,  'AreaBetreff',areabetreff) or
            gets(s,su,'AreaPasswort',areaPW,12) or
            gets(s,su,'AreaListe',dummys,10) or
            gets(s,su,'FileScanner',filescanner,15) or
            gets(s,su,'FilescanPW',filescanpw,12) or
            getx(su,  'EMSI',EMSIenable) or
            gets(s,su,'AKAs',akas,AKAlen) or
            gets(s,su,'SendAKAs',sendakas,AKAlen) or
            getx(su,  'GetTime',gettime) or
            getx(su,  'SendTrx',sendtrx) or
            getx(su,  'PacketPW',packetpw) or
            getx(su,  'ExtFidoFNames',ExtPFiles) or
            getx(su,  'LightLogin',lightlogin) or
            getx(su,  'NotSEmpty',notsempty) or
            gets(s,su,'LoginName',loginname,20) or
            gets(s,su,'UUCPname',UUCPname,8) or
            getb(su,  'UU-MaxWinSize',maxwinsize) or
            getw(su,  'UU-MaxPacketSize',maxpacketsize) or
            getx(su,  'UU-VarPacketSize',varpacketsize) or
            getx(su,  'UU-ForcePacketSize',forcepacketsize) or
            getx(su,  'UU-SizeNegotiation',sizenego) or
            getx(su,  'UU-SMTP',UUsmtp) or
            gets(s,su,'UU-Protocols',uuprotos,10) or
            gets(s,su,'Eingangsfilter',eFilter,60) or
            gets(s,su,'Ausgangsfilter',aFilter,60) or
            getx(su,  'SysopNetcall',sysopnetcall) or
            getx(su,  'SysopPacken',sysoppack) or
            getw(su,  'SerienNR',seriennr) or
            gets(s,su,'NetcallScript',script,50) or
            gets(s,su,'OnlineScript',o_script,50) or
            getx(su,  'Brettmails',brettmails) or
            getx(su,  'SendSerial',dummyl) or
            gets(s,su,'Sysfile',chsysbetr,50) or
            getx(su,  '7e1Login',uucp7e1) or
            getx(su,  'janusplus',JanusPlus) or
            getx(su,  'delqwk',DelQWK) or
            getb(su,  'brettmanagertyp',BMtyp) or
            getx(su,  'brettmanagerdomain',BMdomain) or
            getw(su,  'maxfilesize',maxfsize) or

            gets(s,su,  'ReplyTo',dummys,1) or
            gets(s,su,  'pop3server',Pop3Server,60) or
            getl(su,    'pop3port',Pop3Port) or
            gets(s,su,  'pop3user',Pop3User,60) or
            gets(s,su,  'pop3pass',Pop3Pass,40) or
            gets(s,su,  'pop3envelope',Pop3Envelope,60) or
            getx(su,    'pop3useenvelope',Pop3UseEnvelope) or
            getx(su,    'pop3keep',Pop3Keep) or
            gets(s,su,  'pop3spool',Pop3Spool,79) or
            geti(su,    'pop3timeout',Pop3TimeOut) or
            getl(su,    'pop3maxlen',Pop3MaxLen) or
            gets(s,su,  'pop3reportinfo',Pop3ReportInfo,40) or
            getx(su,    'pop3auth',Pop3Auth) or
            getx(su,    'imap',IMAP) or
            gets(s,su,  'smtpserver',SmtpServer,60) or
            gets(s,su,  'smtpfallback',SmtpFallback,20) or
            getl(su,    'smtpport',SmtpPort) or
            gets(s,su,  'smtpuser',SmtpUser,60) or
            gets(s,su,  'smtppass',SmtpPass,40) or
            gets(s,su,  'smtpenvelope',SmtpEnvelope,60) or
            getx(su,    'smtpafterpop',SmtpAfterPop) or
            geti(su,    'smtpafterpoptimeout',SmtpAfterPopTimeOut) or
            geti(su,    'smtpafterpopdelay',SmtpAfterPopDelay) or
            gets(s,su,  'smtpspool',SmtpSpool,79) or
            geti(su,    'smtptimeout',SmtpTimeOut) or
            gets(s,su,  'smtpreportinfo',SmtpReportInfo,40) or
            gets(s,su,  'smtpauth',SmtpAuth,11) or
            gets(s,su,  'nntpserver',NntpServer,60) or
            gets(s,su,  'nntpfallback',NntpFallback,20) or
            getl(su,    'nntpport',NntpPort) or
            gets(s,su,  'nntpuser',NntpUser,60) or
            gets(s,su,  'nntppass',NntpPass,40) or
            getx(su,    'nntplist',NntpList) or
            geti(su,    'nntptimeout',NntpTimeOut) or
            gets(s,su,  'nntpspool',NntpSpool,79) or
            getl(su,    'nntpmaxlen',NntpMaxLen) or
            getl(su,    'nntpnewmax',NntpNewMax) or
            getl(su,    'nntpdupesize',NntpDupeSize) or
            getx(su,    'nntprescan',NntpRescan) or
            geti(su,    'nntpqueue',NntpQueue) or
            geti(su,    'nntpartclanz',NntpArtclanz) or
            gets(s,su,  'nntpreportinfo',NntpReportInfo,40) or
            getx(su,    'nntpposting',NntpPosting) or
            {gets(s,su,  'nntpreplaceown',NntpReplaceOwn,8) or}
            getx(su,    'replaceown',ReplaceOwn) or
            gets(s,su,  'ppp_dialer',PPP_Dialer,79) or
            gets(s,su,  'ppp_hangup',PPP_HangUp,79) or
            gets(s,su,  'ppp_mail',PPP_Mail,255) or
            gets(s,su,  'ppp_news',PPP_News,255) or
            gets(s,su,  'ppp_uuz_out',PPP_UUZ_Out,79) or
            gets(s,su,  'ppp_uuz_in',PPP_UUZ_In,79) or
            gets(s,su,  'ppp_uuz_spool',PPP_UUZ_Spool,79) or
            geti(su,    'ppp_shell',PPP_Shell) or
          {$IFDEF ToBeOrNotToBe}
            gets(s,su,  'tcp_pktdrv',TCP_PktDrv,15) or
            geti(su,    'tcp_pktvec',TCP_PktVec) or
            geti(su,    'tcp_pktint',TCP_PktInt) or
            gets(s,su,  'tcp_nameserver',TCP_NameServer,15) or
            gets(s,su,  'tcp_gateway',TCP_Gateway,15) or
            gets(s,su,  'tcp_netmask',TCP_Netmask,15) or
            gets(s,su,  'tcp_localip',TCP_LocalIP,15) or
            geti(su,    'tcp_socket_timeout',TCP_Socket_Timeout) or
            geti(su,    'tcp_bootp_timeout',TCP_Bootp_Timeout) or
          {$ENDIF}
            gets(s,su,  'dialinaccount',DialInAccount,40) or
            gets(s,su,  'dialinnumber',DialInNumber,25) or
            gets(s,su,  'dialinpass',DialInPass,40) or
            gets(s,su,  'dialinuser',DialInUser,60) or
            geti(su,    'redialonbusy',RedialOnBusy) or
            geti(su,    'redialtimeout',RedialTimeout) or
            geti(su,    'hanguptimeout',HangupTimeout) or
            getx(su,    'performpass',PerformPass) or
            getx(su,    'afterdialinstate',AfterDialinState) or
            getx(su,    'askfordisconnect',AskForDisconnect) or
            getx(su,    'xpscoreaktiv',XpScoreAktiv) or
            gets(s,su,  'scorefile',ScoreFile,79) or
            gets(s,su,  'ppp_killfile',PPP_KillFile,79) or
            gets(s,su,  'ppp_boxpakete',PPP_BoxPakete,255) or
            getx(su,    'mailerdaemon',MailerDaemon)
          ) then
            trfehler1(901,left(s,35),errortimeout);   { 'UngÅltige Box-Config-Angabe: %s' }
          end;
        end;
    close(t);
    if (ustr(bp^.boxname)=ustr(DefaultBox)) and (bp^.owaehlbef<>'') then begin
      for i:=1 to 4 do begin       { 2.93 beta: Waehlbefehl -> Config/Modem }
        freemem(comn[i].MDial,length(comn[i].MDial^)+1);
        getmem(comn[i].MDial,length(boxpar^.owaehlbef)+1);
        comn[i].MDial^:=boxpar^.owaehlbef;
        end;
      SaveConfig;
      bp^.owaehlbef:='';
      WriteBox(dateiname,bp,nt);
      if bp=BoxPar then BoxPar^.owaehlbef:='';
      end;
    end;
end;

procedure WriteBox(dateiname:pathstr; bp:BoxPtr; nt:byte);
var t : text;
    i : byte;

  function jnf(b:boolean):char;
  begin
    jnf:=iifc(b,'J','N');
  end;

begin
  assign(t,OwnPath+dateiname+BfgExt);
  rewrite(t);
  if ioresult<>0 then begin
    rfehler(902);     { 'ungÅltiger Boxname!' }
    exit;
    end;
  with bp^ do begin
    writeln(t,bfgver+bfgnr);
    writeln(t,'Boxname=',boxname);
    writeln(t,'Pointname=',pointname);
    writeln(t,'Username=',username);
    writeln(t,'Domain=',_domain);
    writeln(t,'FQDN=',_fqdn);  {16.01.00 HS}
    writeln(t,'Passwort=',passwort);
    writeln(t,'Telefon=',telefon);
    writeln(t,'ZerbID=',zerbid);
    writeln(t,'Upload=',uploader);
    writeln(t,'Download=',downloader);
    writeln(t,'Protokolltyp=',prototyp);
    writeln(t,'ZMOptions=',zmoptions);
    writeln(t,'UpArc=',uparcer);
    writeln(t,'DownArc=',downarcer);
    if UnFreezer<>'' then
      writeln(t,'UnFreeze=',unfreezer);
    if Ungzipper<>'' then
      writeln(t,'UnGZIP=',ungzipper);
    writeln(t,'UpArcExt=',uparcext);
    writeln(t,'DownArcExt=',downarcext);
    writeln(t,'ConnWait=',connwait);
    writeln(t,'LoginWait=',loginwait);
    writeln(t,'RedialWait=',redialwait);
    writeln(t,'RedialMax=',redialmax);
    writeln(t,'ConnectMax=',connectmax);
    writeln(t,'PackWait=',packwait);
    writeln(t,'RetryLogin=',retrylogin);
    writeln(t,'ConnectTime=',conn_time);
    writeln(t,'ModemInit=',modeminit);
    writeln(t,'cpsMin=',mincps);
    writeln(t,'Port=',bport);
    writeln(t,'Params=',params);
    writeln(t,'Baud=',baud);
    writeln(t,'Tarifzone=',gebzone);
    writeln(t,'SysopInfile=',sysopinp);
    writeln(t,'SysopOutfile=',sysopout);
    writeln(t,'SysopStartprg=',sysopstart);
    writeln(t,'SysopEndprg=',sysopend);
    writeln(t,'MagicNET=',magicnet);
    writeln(t,'MagicBrett=',magicbrett);
    writeln(t,'LightLogin=',jnf(lightlogin));
    writeln(t,'OnlinePasswort=',o_passwort);
    writeln(t,'Logfile=',o_logfile);
    writeln(t,'NetcallScript=',script);
    writeln(t,'OnlineScript=',o_script);
    for i:=1 to excludes do
      if exclude[i,1]<>'  :  ' then
        writeln(t,'Ausschluss',i,'=',exclude[i,1],'-',exclude[i,2]);
    writeln(t,'Brettmails=',jnf(brettmails));
    writeln(t,'Eingangsfilter=',eFilter);
    writeln(t,'Ausgangsfilter=',aFilter);
    writeln(t,'SysopNetcall=',jnf(sysopnetcall));
    writeln(t,'SysopPacken=',jnf(sysoppack));
    if seriennr<>0 then writeln(t,'SerienNR=',seriennr);
    writeln(t);
    writeln(t,'FidoFakenet=',fpointnet);
    writeln(t,'Fido4Dadr=',jnf(f4d));
    writeln(t,'TosScan=',jnf(ftosscan));
    writeln(t,'LocalINTL=',jnf(localintl));
    writeln(t,'FidoArea+=',jnf(areaplus));
    writeln(t,'AreaBetreff=',jnf(areabetreff));
    writeln(t,'AreaPasswort=',AreaPW);
    writeln(t,'FileScanner=',filescanner);
    writeln(t,'FilescanPW=',filescanpw);
    writeln(t,'EMSI=',jnf(EMSIenable));
    writeln(t,'GetTime=',jnf(gettime));
    if akas<>'' then writeln(t,'AKAs=',akas);
    if SendAKAs<>'' then writeln(t,'SendAKAs=',SendAKAs);
    if sendtrx  then writeln(t,'SendTrx=J');
    if notsempty then writeln(t,'NotSEmpty=J');
    if packetpw then writeln(t,'PacketPW=J');
    if ExtPFiles then writeln(t,'ExtFidoFNames=J');
    if loginname<>'' then writeln(t,'LoginName=',loginname);
    if uucpname<>''  then writeln(t,'UUCPname=',uucpname);
    if maxwinsize<>7 then writeln(t,'UU-MaxWinSize=',maxwinsize);
    if maxpacketsize<>64 then writeln(t,'UU-MaxPacketSize=',maxpacketsize);
    writeln(t,'UU-VarPacketSize=',jnf(varpacketsize));
    writeln(t,'UU-ForcePacketSize=',jnf(forcepacketsize));
    writeln(t,'UU-SizeNegotiation=',jnf(sizenego));
    if uusmtp then writeln(t,'UU-SMTP=',jnf(uusmtp));
    if uuprotos<>'' then writeln(t,'UU-protocols=',uuprotos);
    if maxfsize>0 then writeln(t,'MaxFileSize=',maxfsize);
    writeln(t,'BrettmanagerTyp=',BMtyp);
    writeln(t,'BrettmanagerDomain=',jnf(BMdomain));
    if chsysbetr<>'' then writeln(t,'Sysfile=',chsysbetr);
    writeln(t,'7e1Login=',jnf(uucp7e1));
    if janusplus then writeln(t,'JanusPlus=J');
    writeln(t,'DelQWK=',jnf(DelQWK));
    if (nt=nt_ppp) or (nt=nt_uucp) then
    writeln(t,'MailerDaemon=',jnf(MailerDaemon));
    writeln(t,'ReplaceOwn=',jnf(ReplaceOwn));
    if nt=nt_ppp then begin
      writeln(t,'ReplyTo=',_replyto);
      writeln(t,'Pop3Server=',Pop3Server);
      writeln(t,'Pop3Port=',Pop3Port);
      writeln(t,'Pop3User=',Pop3User);
      writeln(t,'Pop3Pass=',Pop3Pass);
      writeln(t,'Pop3Envelope=',Pop3Envelope);
      writeln(t,'Pop3UseEnvelope=',jnf(Pop3UseEnvelope));
      writeln(t,'Pop3Keep=',jnf(Pop3Keep));
      writeln(t,'Pop3Spool=',Pop3Spool);
      writeln(t,'Pop3TimeOut=',Pop3TimeOut);
      writeln(t,'Pop3MaxLen=',Pop3MaxLen);
      writeln(t,'Pop3ReportInfo=',Pop3ReportInfo);
      writeln(t,'Pop3Auth=',jnf(Pop3Auth));
      writeln(t,'IMAP=',jnf(IMAP));
      writeln(t,'SmtpServer=',SmtpServer);
      writeln(t,'SmtpFallback=',SmtpFallback);
      writeln(t,'SmtpPort=',SmtpPort);
      writeln(t,'SmtpUser=',SmtpUser);
      writeln(t,'SmtpPass=',SmtpPass);
      writeln(t,'SmtpEnvelope=',SmtpEnvelope);
      writeln(t,'SmtpAfterPop=',jnf(SmtpAfterPop));
      writeln(t,'SmtpAfterPopTimeOut=',SmtpAfterPopTimeOut);
      writeln(t,'SmtpAfterPopDelay=',SmtpAfterPopDelay);
      writeln(t,'SmtpSpool=',SmtpSpool);
      writeln(t,'SmtpTimeOut=',SmtpTimeOut);
      writeln(t,'SmtpReportInfo=',SmtpReportInfo);
      writeln(t,'SmtpAuth=',SmtpAuth);
      writeln(t,'NntpServer=',NntpServer);
      writeln(t,'NntpFallback=',NntpFallback);
      writeln(t,'NntpPort=',NntpPort);
      writeln(t,'NntpUser=',NntpUser);
      writeln(t,'NntpPass=',NntpPass);
      writeln(t,'NntpList=',jnf(NntpList));
      writeln(t,'NntpTimeOut=',NntpTimeOut);
      writeln(t,'NntpSpool=',NntpSpool);
      writeln(t,'NntpMaxLen=',NntpMaxLen);
      writeln(t,'NntpNewMax=',NntpNewMax);
      writeln(t,'NntpDupeSize=',NntpDupeSize);
      writeln(t,'NntpRescan=',jnf(NntpRescan));
      writeln(t,'NntpQueue=',NntpQueue);
      writeln(t,'NntpArtclAnz=',NntpArtclAnz);
      writeln(t,'NntpReportInfo=',NntpReportInfo);
      writeln(t,'NntpPosting=',jnf(NntpPosting));
      {writeln(t,'NntpReplaceOwn=',NntpReplaceOwn);}
      writeln(t,'PPP_Dialer=',PPP_Dialer);
      writeln(t,'PPP_HangUp=',PPP_HangUp);
      writeln(t,'PPP_Mail=',PPP_Mail);
      writeln(t,'PPP_News=',PPP_News);
      writeln(t,'PPP_UUZ_Out=',PPP_UUZ_Out);
      writeln(t,'PPP_UUZ_In=',PPP_UUZ_In);
      writeln(t,'PPP_UUZ_Spool=',PPP_UUZ_Spool);
      writeln(t,'PPP_Shell=',PPP_Shell);
    {$IFDEF ToBeOrNotToBe}
      writeln(t,'TCP_PktDrv=',TCP_PktDrv);
      writeln(t,'TCP_PktVec=',TCP_PktVec);
      writeln(t,'TCP_PktInt=',TCP_PktInt);
      writeln(t,'TCP_NameServer=',TCP_NameServer);
      writeln(t,'TCP_Gateway=',TCP_Gateway);
      writeln(t,'TCP_Netmask=',TCP_Netmask);
      writeln(t,'TCP_LocalIP=',TCP_LocalIP);
      writeln(t,'TCP_Socket_Timeout=',TCP_Socket_Timeout);
      writeln(t,'TCP_Bootp_Timeout=',TCP_Bootp_Timeout);
    {$ENDIF}
      writeln(t,'DialInAccount=',DialInAccount);
      writeln(t,'DialInNumber=',DialInNumber);
      writeln(t,'DialInPass=',DialInPass);
      writeln(t,'DialInUser=',DialInUser);
      writeln(t,'RedialOnBusy=',RedialOnBusy);
      writeln(t,'RedialTimeout=',RedialTimeout);
      writeln(t,'HangupTimeout=',HangupTimeout);
      writeln(t,'PerformPass=',jnf(PerformPass));
      writeln(t,'AfterDialinState=',jnf(AfterDialinState));
      writeln(t,'AskForDisconnect=',jnf(AskForDisconnect));
      writeln(t,'XpScoreAktiv=',jnf(XpScoreAktiv));
      writeln(t,'ScoreFile=',ScoreFile);
      writeln(t,'PPP_KillFile=',PPP_KillFile);
      writeln(t,'PPP_BoxPakete=',PPP_BoxPakete);
    end;
  end;
  close(t);
end;


procedure ReadBoxPar(nt:byte; box:string);
var d     : DB;
    bfile : pathstr;
begin
  dbOpen(d,BoxenFile,1);               { zugehîrigen Dateiname holen }
  dbSeek(d,boiName,ustr(box));
  if dbFound then
  begin
    dbRead(d,'dateiname',bfile);
    ReadBox(nt,bfile,BoxPar);             { Pollbox-Parameter einlesen }
  end;
  dbClose(d);
end;


procedure ReadQFG(dateiname:pathstr; var qrec:QfgRec);
var t  : text;
    s  : string;
    id : string[10];
begin
  fillchar(qrec,sizeof(qrec),0);
  qrec.midtyp:=2;   { Default }
  assign(t,dateiname+QfgExt);
  if existf(t) then with qrec do begin
    reset(t);
    s:='';
    while not eof(t) do begin
      readln(t,s);
      id:=ustr(GetToken(s,':'));
      if id='BBS' then RepFile:=s else
      if id='ZIP' then packer:=s else
      if id='SYS' then door:=s else
      if id='REQ' then requests:=(ustr(s)<>'N') else
      if id='REC' then ebs:=(ustr(s)<>'N') else
      if id='PMA' then privecho:=s else
      if id='NMA' then netecho:=s else
      if id='EMA' then emailecho:=s else
      if id='NMT' then nmt:=minmax(ival(s),0,255) else
      if id='MID' then midtyp:=minmax(ival(s),0,9) else
      if id='HDR' then hdr:=(ustr(s)<>'M') else
      if id='BEB' then bretter:=s;
      end;
    close(t);
    end;
end;


procedure WriteQFG(dateiname:Pathstr; qrec:QfgRec);
var t1,t2 : text;
    s,ss  : string;
    id    : string[10];
begin
  assign(t1,dateiname+QfgExt);
  if existf(t1) then with qrec do begin
    reset(t1);
    assign(t2,'qwktemp.$$$');
    rewrite(t2);
    while not eof(t1) do begin
      readln(t1,s);
      ss:=s;
      id:=ustr(GetToken(s,':'));
      if id='BBS' then writeln(t2,'BBS: '+RepFile) else
      if id='ZIP' then writeln(t2,'ZIP: '+packer) else
      if id='SYS' then writeln(t2,'SYS: '+door) else
      if id='REQ' then writeln(t2,'REQ: '+iifc(requests,'J','N')) else
      if id='REC' then writeln(t2,'REC: '+iifc(ebs,'J','N')) else
      if id='PMA' then writeln(t2,'PMA: '+privecho) else
      if id='NMA' then writeln(t2,'NMA: '+netecho) else
      if id='EMA' then writeln(t2,'EMA: '+emailecho) else
      if id='NMT' then writeln(t2,'NMT: '+strs(nmt)) else
      if id='MID' then begin
        writeln(t2,'MID: '+strs(midtyp));
        midtyp:=-1;
        end else
      if id='HDR' then begin
        writeln(t2,'HDR: '+iifc(hdr,'J','N'));
        hdr:=false;
        end else
      if id='BEB' then writeln(t2,'BEB: '+bretter)
      else begin
        if lstr(ss)='[brettstart]' then begin
            { MID: und HDR: kînnen fehlen, weil ZQWK sie nicht }
            { automatisch erzeugt                              }
          if midtyp>=0 then writeln(t2,'MID: '+strs(midtyp));
          if hdr then writeln(t2,'HDR: J');
          end;
        writeln(t2,ss);
        end;
      end;
    close(t1);
    close(t2);
    erase(t1);
    rename(t2,dateiname+QfgExt);
    end;
end;


function BoxBrettebene(box:string):string;
begin
  ReadBoxPar(nt_Fido {egal} ,box);
  BoxBrettebene:=boxpar^.MagicBrett;
end;


end.

{
  $Log: xp9bp.pas,v $
  Revision 1.41  2001/09/11 09:25:43  MH
  -.-

  Revision 1.40  2001/09/07 09:39:47  MH
  - RFC/PPP:
    Smtp- und NntpFallback-Felder fÅr Clients hinzugefÅgt, die
    diese Funktion unterstÅtzen mîchten. Es wird der BFG-Dateiname
    ohne Extention Åbergeben.

  Revision 1.39  2001/08/02 01:45:29  MH
  - RFC/PPP: Anpassungen im Mailclientbereich

  Revision 1.38  2001/07/03 20:08:09  MH
  - pophp-Aufruf verschoben

  Revision 1.37  2001/06/18 20:17:40  oh
  Teames -> Teams

  Revision 1.36  2001/04/04 19:57:03  oh
  -Timeouts konfigurierbar

  Revision 1.35  2001/03/20 18:59:15  tg
  DOS TCP/IP-Einstellungen, MailerShell

  Revision 1.34  2001/01/29 22:08:47  MH
  RFC/PPP:
  - Einige Grenzen erweitert

  Revision 1.33  2001/01/04 22:08:14  MH
  - DialInAccount von 25 auf 40 Zeichen erhîht

  Revision 1.32  2000/12/16 19:05:59  MH
  RFC/PPP:
  - Einige Erweiterungen im BoxmenÅ

  Revision 1.31  2000/11/25 08:31:44  MH
  RFC/PPP:
  - Weitere Schalter hinzugefÅgt

  Revision 1.30  2000/11/10 00:51:38  rb
  Fix: Server > 15 Zeichen

  Revision 1.29  2000/10/27 21:55:44  MH
  Konvertierung der BFGs verlagert

  Revision 1.28  2000/10/27 11:38:58  MH
  RFC/PPP: Kleiner Umbau des BoxmenÅs

  - ReplaceOwn bei weiteren Boxen hinzugefÅgt

  Revision 1.27  2000/10/05 19:02:56  MH
  RFC/PPP: NntpReplaceOwn hinzugefÅgt

  Revision 1.26  2000/08/17 14:50:11  MH
  RFC/PPP: Online-Filter: KillFile bei Diverses hinzugefÅgt

  Revision 1.25  2000/08/01 21:18:07  MH
  RFC/PPP: Angaben fÅr maximale Mail/News-Grî·e sind Bytes,
  daher fÅr Mails das Limit 7-Stellig ermîglicht

  Revision 1.24  2000/07/31 19:15:45  MH
  RFC/PPP: Maximale Grî·e einer E-Mail kann konfiguriert werden

  Revision 1.23  2000/07/31 15:11:33  MH
  MAILER-DAEMON kann nun fÅr jede Box separat konfiguriert werden

  Revision 1.22  2000/07/27 16:59:06  MH
  RFC/PPP: Einige Grenzen erweitert und mit Mîglichkeit
           der Einstellung der Hangup-Zeit ergÑnzt

  Revision 1.21  2000/06/24 17:03:08  MH
  RFC/PPP: Neuer Parameter NntpPosting hinzugefÅgt
           Pop3-/Smtp-/Port in einen String umgewandelt

  Revision 1.20  2000/06/22 17:50:24  tg
  neue Parameter fuer WDIAL

  Revision 1.19  2000/06/22 07:41:45  MH
  RFC/PPP: Pakete mitsenden: UUZ_In wird nun auch beachtet

  Revision 1.18  2000/06/21 07:02:49  MH
  RFC/PPP: Pakete mitsenden implementiert

  Revision 1.17  2000/06/18 21:52:43  MH
  RFC/PPP: UUZ-SpoolDir eingerichtet (f. Pakete mitsenden v. Bedeutung)

  Revision 1.16  2000/06/17 09:40:47  MH
  RFC/PPP: Pakete mitsenden ins Menue aufgenommen

  Revision 1.15  2000/06/05 09:04:36  MH
  RFC/PPP: Anzahl der Artikel kann nun selbst bestimmt werden

  Revision 1.14  2000/06/04 18:05:40  MH
  RFC/PPP: Vorgabe 'X:\XP\SPOOL' eingestellt

  Revision 1.13  2000/06/04 04:23:08  MH
  RFC/PPP: Errorlevelhandling angepasst

  Revision 1.12  2000/06/02 08:36:09  MH
  RFC/PPP: Code aufgeraeumt

  Revision 1.10  2000/05/30 20:32:59  MH
  RFC/PPP: automatisches Verzeichnis anlegen

  Revision 1.9  2000/05/30 17:18:52  MH
  RFC/PPP: Fix: grrrr...Schreibfehler beseitigt

  Revision 1.8  2000/05/30 16:49:10  MH
  RFC/PPP: Fix: ReplyTo und Pointname wurden bei neuen Boxen mit den Daten einer anderen gefuellt

  Revision 1.7  2000/05/29 19:09:42  MH
  RFC/PPP: Weitere Anpassungen (Port nun 5stellig, IMAP ge‰ndert, Abwahlstring hinzugefuegt)

  Revision 1.6  2000/05/25 23:26:28  rb
  Loginfos hinzugefÅgt

}
