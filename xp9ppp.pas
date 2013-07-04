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
{ $Id: xp9ppp.pas,v 1.51 2002/04/26 22:23:16 MH Exp $ }


{ --- Bearbeitungs-Routinen fr RFC/PPP-Boxen ------------------- }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+,R-}
{$ENDIF }

unit xp9ppp;

interface

uses xpglobal,crt,dos,typeform,fileio,inout,keys,winxp,win2,maske,
     datadef,database,maus2,mouse,resource,xp0,xp1,xp1o,xp1o2,xp1input,xp2c;

procedure EditPOP3(var brk:boolean);
procedure EditSMTP(var brk:boolean);
procedure EditNNTP(var brk:boolean);
procedure EditZugang(var brk:boolean);
procedure EditClients(var brk:boolean);
{$IFDEF ToBeOrNotToBe}
procedure EditTCPIP(var brk:boolean);
{$ENDIF}
procedure getdname(box:string;slash:boolean);
function getserverlist:string;

implementation  {-------------------------------------------------}

uses xp2,xp3,xp3o,xp9,xp9bp,xp10,xpnt,xpterm;
  {
  maddint: ...typ,displ,von,bis
  Typ 2 = ShortInt, 3 = Byte, 4 = Integer, 5 = Word, 6 = LongInt
  }

  const
    dname : string[9] = '';

  function getbname(dn:string):string;
  var
    d  : DB;
    bn : string[BoxNameLen];
  begin
    dbOpen(d,BoxenFile,1);
    dbSeek(d,boiDatei,ustr(dn));
    if dbFound and (dbReadInt(d,'netztyp')=41) then begin
      dbRead(d,'boxname',bn);
      getbname:=bn;
    end
    else
      getbname:='';
    dbClose(d);
  end;

  procedure getdname(box:string;slash:boolean);
  var
    d : DB;
  begin
    dbOpen(d,BoxenFile,1);
    dbSeek(d,boiName,ustr(Box));
    if dbFound and (dbReadInt(d,'netztyp')=41) then begin
      dbRead(d,'dateiname',dname);
      if slash then
        dname:=dname+'\';
    end
    else
      if slash then
        dname:=ustr(left(Box,8))+'\'
      else
        dname:='';
    dbClose(d);
  end;

  function getserverlist:string;
  var
    d     : DB;
    p     : integer;
    dn    : string[8];
    paket : string;
    result: string;

    function getbn:string;
    var
      bname : string[BoxNameLen];
    begin
      dbSeek(d,boiDatei,ustr(dn));
      if dbFound and (dbReadInt(d,'netztyp')=41) then begin
        dbRead(d,'boxname',bname);
        getbn:=bname;
      end
      else
        getbn:='';
    end;

  begin
    dbOpen(d,BoxenFile,1); result:='';
    paket:=trim(boxpar^.ppp_boxpakete);
    repeat
      p:=blankpos(paket);
      if p=0 then p:=length(paket);
      dn:=left(paket,p); dn:=rtrim(dn);
      paket:=mid(paket,p+1);
      result:=result+'ù'+getbn;
    until ((p=0) or (paket=''));
    dbClose(d);
    delfirst(result);
    getserverlist:=result;
  end;

  procedure EditPOP3(var brk:boolean);
  var x,y: byte;
  begin
    dialog(47,16,getres2(936,1),x,y);  { 'POP3-Einstellungen' }
    with BoxPar^ do begin
      maddstring(3,2,getres2(936,6),Pop3Server,32,60,without(range('-','z'),'/:;<=>?@[\]^'));      { 'Server     ' }
      mappsel(false,getres2(936,57));                          { Serverauswahl }
      mhnr(9000);
      maddstring(3,3,getres2(936,7),Pop3User,32,60,'');        { 'User       ' }
      maddstring(3,4,getres2(936,8),Pop3Pass,32,40,'');        { 'Passwort   ' }
      maddstring(3,5,getres2(936,9),Pop3Envelope,32,60,'');    { 'Envelope   ' }
      maddstring(3,6,getres2(936,12),Pop3Spool,32,79,without(range('-','z')+'#','/;<=>?@[]^'));    { 'Spool      ' }
      getdname(boxname,true);
      mappsel(false,iifs(PPP_UUZ_Spool<>OwnPath+XFerDir+dname,PPP_UUZ_Spool,
                         OwnPath+XFerDir)+'ù'+OwnPath+XFerDir+dname);
      msetVfunc(formpath);
      maddint(3,8,getres2(936,13),Pop3Port,6,5,0,99999);             { 'Port       ' }
      mappsel(false,getres2(936,90)); {'110ù25ù143ù585ù993'}         { Portauswahl }
      maddint(23,8,getres2(936,14),Pop3TimeOut,4,3,0,300);           { 'TimeOut    ' }
      mappsel(false,getres2(936,91)); {'10ù20ù30ù60ù90ù120ù180ù240ù300'}
      maddtext(length(getres2(936,14))+30,8,getres2(936,61),0);
      maddint(3,10,getres2(936,51),Pop3MaxLen,6,7,0,9999999);        { 'MaxLen   ' }
      mappsel(false,getres2(936,97)+getres2(936,96));
      {'0ù8192ù16384ù32768ù65536ù131072ù262144ù524288ù1048576ù2621440ù5242880ù7864320ù9999999'}
      maddtext(length(getres2(936,51))+14,10,' Bytes',0);
      maddbool(3,12,getres2(936,10),Pop3UseEnvelope);                { 'UseEnvelope' }
      maddbool(3,13,getres2(936,11),Pop3Keep);                       { 'Keep       ' }
      maddbool(3,14,sp(2)+getres2(936,53),Pop3Auth);                 { 'sichere Authentifizierung verwenden' }
      maddbool(3,15,getres2(936,43),IMAP);                           { 'POP3/IMAP  ' }
      freeres;
      readmask(brk);
      enddialog;
    end;
  end;

  procedure EditSMTP(var brk:boolean);
  var x,y: byte;

    function cvtlang(s: string; engtoger: boolean):string;
    var
      p : byte;
    begin
      s:=trim(s);
      p:=blankpos(s);
      if p<>0 then
        s:=left(s,p-1);
      if engtoger then begin
        if lstr(s)='disabled' then s:='Keine';
      end
      else
        if lstr(s)='keine' then s:='disabled';
      cvtlang:=rtrim(s);
    end;

  begin
    dialog(49,17,getres2(936,2),x,y);  { 'SMTP-Einstellungen' }
    with BoxPar^ do begin
      maddstring(3,2,getres2(936,6),SmtpServer,34,60,without(range('-','z'),'/:;<=>?@[\]^'));           { 'Server         ' }
      mappsel(false,getres2(936,58));                               { Serverauswahl }
      mhnr(9020);
      if SmtpFallback<>'' then
        SmtpFallback:=getbname(SmtpFallback);
      maddstring(3,3,'Fallback',SmtpFallback,34,20,without(range('-','z'),'/:;<=>?@[\]^'));           { 'Fallback-Server' }
      if ppp_boxpakete<>'' then
        mappsel(false,getserverlist);
      mhnr(9031);
      maddstring(3,4,getres2(936,7),SmtpUser,34,60,''); mhnr(9021); { 'User           ' }
      maddstring(3,5,getres2(936,8),SmtpPass,34,40,'');             { 'Passwort       ' }
      maddstring(3,6,getres2(936,9),SmtpEnvelope,34,60,'');         { 'Envelope       ' }
      maddstring(3,7,getres2(936,12),SmtpSpool,34,79,without(range('-','z')+'#','/;<=>?@[]^'));           { 'Spool          ' }
      getdname(boxname,true);
      mappsel(false,iifs(PPP_UUZ_Spool<>OwnPath+XFerDir+dname,PPP_UUZ_Spool,
                         OwnPath+XFerDir)+'ù'+OwnPath+XFerDir+dname);
      msetVfunc(formpath);
      SmtpAuth:=cvtlang(SmtpAuth,deutsch); { 'sichere Authentifizierung verwenden' }
      maddstring(3,9,getres2(936,53),SmtpAuth,17,11,without(range('-','z'),'/:;<=>?@[\]^012346789'));
      { 'KeineùAutoùLoginùPlainùDigest-MD5ùCram-MD5' }
      mappsel(false,getres2(936,55));
      maddbool(3,11,getres2(936,15),SmtpAfterPop);                  { 'AfterPop       ' }
      maddint(3,13,getres2(936,13),SmtpPort,6,5,0,99999);           { 'Port           ' }
      mappsel(false,getres2(936,101)); {'25'}                       { Portauswahl }
      maddint(25,13,getres2(936,14),SmtpTimeOut,4,3,0,300);         { 'TimeOut        ' }
      mappsel(false,getres2(936,91)); {'10ù20ù30ù60ù90ù120ù180ù240ù300'}
      maddtext(length(getres2(936,14))+32,13,getres2(936,61),0);
      maddint(3,15,getres2(936,16),SmtpAfterPopTimeOut,4,3,0,300); { 'AfterPopTimeOut' }
      mappsel(false,getres2(936,91)); {'10ù20ù30ù60ù90ù120ù180ù240ù300'}
      maddtext(length(getres2(936,16))+10,15,getres2(936,61),0);
      maddint(3,16,getres2(936,17),SmtpAfterPopDelay,4,3,0,300);   { 'AfterPopDelay  ' }
      {'0ù1ù2ù3ù4ù5ù10ù15ù20ù30ù60ù90ù120ù180ù240ù300'}
      mappsel(false,'0ù'+getres2(936,92)+getres2(936,93));
      maddtext(length(getres2(936,17))+10,16,getres2(936,61),0);
      freeres;
      readmask(brk);
      SmtpAuth:=cvtlang(SmtpAuth,false);
      if not brk and (ppp_boxpakete<>'') then begin
        getdname(SmtpFallback,false);
        SmtpFallback:=dname;
      end;
      enddialog;
    end;
  end;

  procedure EditNNTP(var brk:boolean);
  var x,y: byte;
  begin
    dialog(53,20,getres2(936,3),x,y);  { 'NNTP-Einstellungen' }
    with BoxPar^ do begin
      maddstring(3,2,getres2(936,6),NntpServer,38,60,without(range('-','z'),'/:;<=>?@[\]^'));    { 'Server   ' }
      mappsel(false,getres2(936,59));                        { Serverauswahl }
      mhnr(9040);
      if NntpFallback<>'' then
        NntpFallback:=getbname(NntpFallback);
      maddstring(3,3,'Fallback',NntpFallback,38,20,without(range('-','z'),'/:;<=>?@[\]^'));    { 'Fallback-Server' }
      if ppp_boxpakete<>'' then
        mappsel(false,getserverlist);
      mhnr(9031);
      maddstring(3,4,getres2(936,7),NntpUser,38,60,''); mhnr(9041);  { 'User     ' }
      maddstring(3,5,getres2(936,8),NntpPass,38,40,'');      { 'Passwort ' }
      maddstring(3,6,getres2(936,12),NntpSpool,38,79,without(range('-','z')+'#','/;<=>?@[]^'));    { 'Spool    ' }
      getdname(boxname,true);
      mappsel(false,iifs(PPP_UUZ_Spool<>OwnPath+XFerDir+dname,PPP_UUZ_Spool,
                         OwnPath+XFerDir)+'ù'+OwnPath+XFerDir+dname);
      msetVfunc(formpath);
      maddint(3,8,getres2(936,13),NntpPort,6,5,0,99999);      { 'Port     ' }
      mappsel(false,'119');                                   { Portauswahl }
      maddint(29,8,getres2(936,14),NntpTimeOut,4,3,0,300);    { 'TimeOut        ' }
      mappsel(false,getres2(936,91)); {'10ù20ù30ù60ù90ù120ù180ù240ù300'}
      maddtext(length(getres2(936,14))+36,8,getres2(936,61),0);
      maddbool(3,10,getres2(936,18),NntpList);                { 'Newsliste' }
      maddbool(3,11,getres2(936,19),NntpRescan);              { 'Rescan   ' }
      maddbool(3,12,getres2(936,49),NntpPosting);             { 'Posting   ' }
      maddbool(3,13,sp(2)+getres2(936,52),ReplaceOwn);              { 'ReplaceOwn ' }
      maddint(3,15,getres2(936,20),NntpQueue,4,6,1,20);       { 'Queue    ' }
      mappsel(false,getres2(936,92)); {'1ù2ù3ù4ù5ù10ù15ù20'}
      maddint(3,16,getres2(936,45),NntpArtclAnz,4,6,0,32000); { 'Anzahl   ' }
      mappsel(false,getres2(936,98)+getres2(936,100));
      {'0ù10ù25ù50ù75ù100ù150ù200ù250ù500ù750ù1000ù2500ù5000ù10000ù20000ù32000'}
      maddint(3,17,getres2(936,21),NntpMaxLen,6,6,0,999999);  { 'MaxLen   ' }
      mappsel(false,getres2(936,97)+'999999');
      {'0ù8192ù16384ù32768ù65536ù131072ù262144ù524288ù786432ù999999'}
      maddtext(length(getres2(936,21))+13,17,' Bytes',0);
      maddint(3,18,getres2(936,22),NntpNewMax,6,6,0,999999);  { 'NewMax   ' }
      mappsel(false,getres2(936,98)+getres2(936,99));
      {'0ù10ù25ù50ù75ù100ù250ù500ù750ù1000ù2500ù5000ù10000ù25000ù50000ù75000ù999999'}
      maddint(3,19,getres2(936,23),NntpDupeSize,6,6,0,999999);{ 'DupeSize ' }
      mappsel(false,getres2(936,97)+'999999');
      {'0ù8192ù16384ù32768ù65536ù131072ù262144ù524288ù786432ù999999'}
      maddtext(length(getres2(936,23))+13,19,' Bytes',0);
      freeres;
      readmask(brk);
      if not brk and (ppp_boxpakete<>'') then begin
        getdname(NntpFallback,false);
        NntpFallback:=dname;
      end;
      enddialog;
    end;
  end;

  procedure EditZugang(var brk:boolean);
  var x,y      : byte;
     {schnitte : string[4];}
      DialNr   : string[28];
  begin
    dialog(46,14,getres2(936,5),x,y);  { 'Zugangs-Einstellungen' }
    with BoxPar^ do begin
      DialNr:=DialInNumber;
      maddstring(3,2,getres2(936,24),DialInAccount,26,40,'');       { 'Account       ' }
      mhnr(9060);
      maddstring(3,3,getres2(936,7)+sp(5),DialInUser,26,40,'');      { 'User          ' }
      maddstring(3,4,getres2(936,8)+sp(5),DialInPass,26,40,'');      { 'Passwort      ' }
      maddstring(3,5,getres2(936,25),DialNr,26,28,'0123456789wW');{ 'Rufnummer     ' }
      mappsel(false,getres2(936,60)); {'..0191011..'}
      (*
      maddstring(3,6,getres2(921,9)+sp(3),modeminit,43,60,''); mhnr(168); { 'Modem-Init ' }
      schnitte:='COM'+strs(bport);
      maddstring(3,8,getres2(921,10),schnitte,4,4,'');                  { 'Schnittstelle ' }
      mappsel(true,getres2(936,87)); {'COM1ùCOM2ùCOM3ùCOM4'}
      maddint(29,8,getres2(921,11),baud,6,6,150,115200); { 'šbertragungsrate:' }
      mappsel(false,getres2(936,86));
      {'150ù300ù1200ù2400ù4800ù9600ù19200ù38400ù57600ù115200'}
      msetvfunc(testbaud);
      maddtext(length(getres2(921,12))+55,8,getres2(921,12),0);          { 'bd' }
      mhnr(9067);
      maddint(35,7,getres2(921,2),loginwait,5,4,1,1000); mhnr(160);     { 'Warten auf Login     ' }
      mappsel(false,'0ù'+getres2(936,92)+getres2(936,93)+getres2(936,94));
      {'0ù1ù2ù3ù4ù5ù10ù15ù20ù30ù60ù90ù120ù180ù240ù300ù600ù999'}
      mhnr(9069);
      maddint(35,8,getres2(921,3),redialwait,5,4, 2,1000); mhnr(162);   { 'W„hl-Pause           ' }
      mappsel(false,'0ù'+getres2(936,92)+getres2(936,93)+getres2(936,94));
      {'0ù1ù2ù3ù4ù5ù10ù15ù20ù30ù60ù90ù120ù180ù240ù300ù600ù999'}
      maddint(35,12,getres2(921,8)+sp(5),mincps,5,4,0,9999); mhnr(167);{ 'min. cps-Rate   ' }
      *)
      maddbool(3,7,getres2(936,26),PerformPass); {mhnr(9064);}          { 'Perform Password entry' }
      maddbool(3,8,getres2(936,27),AfterDialinState);                   { 'Disconnect after Dial-In State' }
      maddbool(3,9,getres2(936,28),AskForDisconnect);                   { 'Ask for Disconnect' }
      maddint(3,11,getres2(936,29),RedialOnBusy,4,3,0,999);              { 'Redial on busy' }
      mappsel(false,'0ù'+getres2(936,92)+getres2(936,95));
      {'0ù1ù2ù3ù4ù5ù10ù15ù20ù50ù75ù100ù250ù500ù750ù999'}
      maddint(3,12,getres2(936,30),RedialTimeout,4,3,0,999);            { 'Redial TimeOut' }
      mappsel(false,'0ù'+getres2(936,92)+getres2(936,93)+getres2(936,94));
      {'0ù1ù2ù3ù4ù5ù10ù15ù20ù30ù60ù90ù120ù180ù240ù300ù600ù999'}
      maddtext(length(getres2(936,30))+10,12,getres2(936,61),0);
      maddint(3,13,getres2(936,50),HangupTimeout,4,3,0,999);             { 'Verbindung trennen nach' }
      mappsel(false,'0ù'+getres2(936,92)+getres2(936,93)+getres2(936,94));
      {'0ù1ù2ù3ù4ù5ù10ù15ù20ù30ù60ù90ù120ù180ù240ù300ù600ù999'}
      maddtext(length(getres2(936,50))+10,13,getres2(936,61),0);
      freeres;
      readmask(brk);
      if not brk and (DialNr<>DialInNumber) and mmodified then
        DialInNumber:=without(DialNr,without(AllChar,range('0','9')+'wW'));
      enddialog;
    end;
  end;

  procedure EditClients(var brk:boolean);
  var
    x,y        : byte;
    StoreSpool : string[79];
  begin
    dialog(47,11,getres2(936,4),x,y);  { 'Clients-Einstellungen' }
    with BoxPar^ do begin
      StoreSpool:=PPP_UUZ_Spool;
      maddstring(3,2,getres2(936,31),PPP_Dialer,30,79,'');    { 'DialIn  ' }
      mhnr(9080);
      mappsel(false,getres2(936,80)); {'WDIAL.EXE /DIAL $CONFIG'}
      msetvfunc(progtest);
      maddstring(3,3,getres2(936,44),PPP_HangUp,30,79,'');    { 'DialOut ' }
      mappsel(false,getres2(936,81)); {'WDIAL.EXE /HANGUP $CONFIG'}
      msetvfunc(progtest);
      maddstring(3,4,getres2(936,32),PPP_Mail,30,160,'');     { 'Mail    ' }
      mappsel(false,getres2(936,82));
      {'XP3P.EXE -CONFIG:$CONFIG -SMTPùE-MAIL.EXE $CONFIGù
      UKAD.BAT $CONFIG $POP3 $SMTP $NNTP $PKTVECù
      E-AGENT.EXE $CONFIGùSTART /W G-AGENT.EXE $CONFIG'}
      msetvfunc(progtest);
      maddstring(3,5,getres2(936,33),PPP_News,30,160,'');     { 'News    ' }
      mappsel(false,getres2(936,83)); {'E-NEWS.EXE $CONFIG'}
      msetvfunc(progtest);
      maddstring(3,6,getres2(936,34),PPP_UUZ_In,30,255,'');   { 'UUZ-In  ' }
      mappsel(false,getres2(936,84)); {'UUZ.EXE -uz $SCREENLINES $SPOOL $PUFFER'}
      msetvfunc(uuz_in_test);
      maddstring(3,7,getres2(936,35),PPP_UUZ_Out,30,255,'');  { 'UUZ-Out ' }
      mappsel(false,getres2(936,85)); {'UUZ.EXE -zu -SMTP -ppp -1522 -qp -MIME -absnsstyle $PUFFER $SPOOL'}
      msetvfunc(uuz_out_test);
      maddstring(3,8,getres2(936,46),PPP_UUZ_Spool,30,79,without(range('-','z')+'#','/;<=>?@[]^')); { 'UUZ-Spool ' }
      getdname(boxname,true);
      mappsel(false,iifs(PPP_UUZ_Spool<>OwnPath+XFerDir+dname,PPP_UUZ_Spool,
                         OwnPath+XFerDir)+'ù'+OwnPath+XFerDir+dname);
      msetVfunc(formpath);
      maddint(3,10,getres2(936,56),PPP_Shell,4,3,0,999);      { 'PPP-Shell/Screenlines' }
      mappsel(false,getres2(936,88)); {'25ù26ù28ù30ù33ù36ù40ù44ù50'}
      readmask(brk);
      if not brk and (ustr(StoreSpool)<>ustr(PPP_UUZ_Spool)) and
        {'Sollen alle Spooleintr„ge dieser Box mit UUZ-Spool berschrieben werden'}
        ReadJN(getres2(936,110),false) then begin
        Pop3Spool:=PPP_UUZ_Spool;
        SmtpSpool:=PPP_UUZ_Spool;
        NntpSpool:=PPP_UUZ_Spool;
      end;
      freeres;
      enddialog;
    end;
  end;

{$IFDEF ToBeOrNotToBe}
  procedure EditTCPIP(var brk:boolean);
  var x,y: byte;
  begin
    dialog(49,13, getres2(936,70),x,y);  { 'TCP/IP-Einstellungen' }
    with BoxPar^ do begin
      maddstring(3,2,getres2(936,71),TCP_PktDrv,10,10,'');            { 'Paketdriver' }
      mhnr(9110);
      mappsel(false,getres2(936,89)); {'MODEMù1TR6ùDSS1ùLANùADSL'}
      maddint(3,3,getres2(936,72),TCP_PktVec,4,3,0,999);              { 'Vektor' }
      maddint(3,4,getres2(936,73),TCP_PktInt,4,3,0,999);              { 'COM-Interrupt' }
      maddstring(3,6,getres2(936,74),TCP_NameServer,15,15,'');        { 'Nameserver' }
      maddstring(3,7,getres2(936,75),TCP_Gateway,15,15,'');           { 'Gateway' }
      maddstring(3,8,getres2(936,76),TCP_Netmask,15,15,'');           { 'Netmask' }
      maddstring(3,9,getres2(936,77),TCP_LocalIP,15,15,'');           { 'lokale IP-Adresse' }
      maddint(3,11,getres2(936,78),TCP_Socket_Timeout,4,3,0,999);     { 'TimeOut fr normale Socket' }
      maddint(3,12,getres2(936,79),TCP_Bootp_Timeout,4,3,0,999);      { 'TimeOut fr BOOTP' }
      freeres;
      readmask(brk);
      enddialog;
    end;
  end;
{$ENDIF}

end.

{
 $Log: xp9ppp.pas,v $
 Revision 1.51  2002/04/26 22:23:16  MH
 - Fix: POP3/Envelope-To verwenden F2-Taste entfernt

 Revision 1.50  2001/12/23 17:28:06  MH
 - Fix in FallBack: Variable war nicht initialisiert

 Revision 1.49  2001/09/12 08:32:00  MH
 -.-

 Revision 1.48  2001/09/11 14:20:33  MH
 -.-

 Revision 1.47  2001/09/11 10:18:53  MH
 - erlaubte Zeichen in einigen Feldern definiert

 Revision 1.46  2001/09/10 09:48:03  MH
 RFC/PPP:
 - TCP/IP-Men und dessen Parameter entfernt (UKAD wird nicht mehr angeboten)
 - Mens angepasst

 Revision 1.45  2001/09/07 14:39:29  MH
 - Fallback: Boxtypprfung hinzugefgt

 Revision 1.44  2001/09/07 12:34:16  MH
 - Fallbackfeld nun immer aktiv

 Revision 1.43  2001/09/07 09:39:46  MH
 - RFC/PPP:
   Smtp- und NntpFallback-Felder fr Clients hinzugefgt, die
   diese Funktion untersttzen m”chten. Es wird der BFG-Dateiname
   ohne Extention bergeben.

 Revision 1.42  2001/08/02 01:45:29  MH
 - RFC/PPP: Anpassungen im Mailclientbereich

 Revision 1.41  2001/07/30 10:41:43  MH
 - Spoolverzeichnis per F2 anbieten - ...;)

 Revision 1.40  2001/07/30 09:47:51  MH
 - Spoolverzeichnis per F2 anbieten, wenn UUZ-Spool eingetragen wurde

 Revision 1.39  2001/07/11 17:47:15  MH
 - Forwarddeklaration fr VER32 vergessen

 Revision 1.38  2001/07/11 17:46:26  MH
 - Forwarddeklaration fr VER32 vergessen

 Revision 1.37  2001/07/09 23:37:08  MH
 - TCP/IP-Men fr DOSonly - dafr immer!

 Revision 1.36  2001/07/08 22:30:00  MH
 - RFC/PPP-Boxmen: Einige Inkonsistenzen beseitigt

 Revision 1.35  2001/07/08 19:17:51  MH
 - TCP/IP-Men: Wird als Client UKAD eingetragen, wird dynamisch
   das Men hinzugefgt

 Revision 1.34  2001/07/08 13:20:29  MH
 - Zeile zuviel (EditZugang)

 Revision 1.33  2001/07/08 13:18:21  MH
 - MultiBoxFunktion [RFC/PPP] aus PreRelease uebernommen

 Revision 1.32  2001/07/08 00:31:38  MH
 - Client Einstellungen: Dialog fr Spool-Verzeichnisse hinzugefgt

 Revision 1.31  2001/07/04 17:21:39  MH
 - Fixversuch-Nachrichtenweiterschaltung: Beim scrollen in jedem LeseMode
   sprang der CursorBalken auf die erste Position, aber auf die falsche
   Nachricht (!Back! in GoDown() auskommentiert)

 Revision 1.30  2001/07/03 20:08:09  MH
 - pophp-Aufruf verschoben

 Revision 1.29  2001/06/18 20:17:41  oh
 Teames -> Teams

 Revision 1.28  2001/06/11 07:27:18  mm
 Hilfe bei "Pakete mitsenden" gefixt

 Revision 1.27  2001/04/10 07:33:59  tg
 DOS TCP/IP Dialer-Konfiguration

 Revision 1.26  2001/03/23 15:49:43  tg
 $POP, $SMTP, $NNTP und $PKTVEC Feature

 Revision 1.25  2001/03/20 18:58:32  tg
 DOS TCP/IP-Einstellungen, MailerShell

 Revision 1.24  2001/01/29 22:08:47  MH
 RFC/PPP:
 - Einige Grenzen erweitert

 Revision 1.23  2001/01/05 21:59:51  MH
 - SmtpAuth um weitere Elemente erweitert

 Revision 1.22  2001/01/05 17:16:15  MH
 - cut and paste BugFix...;-)

 Revision 1.21  2001/01/05 13:13:41  MH
 - dis/enabled < > de/aktiviert

 Revision 1.20  2001/01/04 22:08:14  MH
 - DialInAccount von 25 auf 40 Zeichen erh”ht

 Revision 1.19  2000/12/16 19:06:00  MH
 RFC/PPP:
 - Einige Erweiterungen im Boxmen

 Revision 1.18  2000/10/27 12:01:04  MH
 Optisches fixing...

 Revision 1.17  2000/10/27 11:46:27  MH
 RFC/PPP: Optischer Fix im Zugangsmen

 Revision 1.16  2000/10/27 11:38:58  MH
 RFC/PPP: Kleiner Umbau des Boxmens

 - ReplaceOwn bei weiteren Boxen hinzugefgt

 Revision 1.15  2000/10/11 17:13:59  MH
 RFC/PPP: Fix:
 - String fr UUZ-In/Out zu kurz

 Revision 1.14  2000/10/06 21:14:40  MH
 RFC/PPP:
 Artikel durch Rckl„ufer ersetzen nun im Boxmen einzustellen

 Revision 1.13  2000/08/12 09:16:14  MH
 [RFC/PPP] Fix: Maximale Artikelanzahl bei Neubestellung
 darf nicht gr”áer 32K sein - nun begrenzt -

 Revision 1.12  2000/08/01 21:18:08  MH
 RFC/PPP: Angaben fr maximale Mail/News-Gr”áe sind Bytes,
 daher fr Mails das Limit 7-Stellig erm”glicht

 Revision 1.11  2000/07/31 19:15:44  MH
 RFC/PPP: Maximale Gr”áe einer E-Mail kann konfiguriert werden

 Revision 1.10  2000/07/27 16:59:07  MH
 RFC/PPP: Einige Grenzen erweitert und mit M”glichkeit
          der Einstellung der Hangup-Zeit erg„nzt

 Revision 1.9  2000/07/26 21:34:22  MH
 NNTP-DupeBase nun 6-Stellig

 Revision 1.8  2000/07/26 14:20:43  MH
 Client-Zugang:
 Telefon: 'W' (fr wait) in der Eingabemaske zul„ssig

 Revision 1.7  2000/07/16 00:41:25  MH
 RFC/PPP: Kleine nderung fr XP3P und Men-Inkonsistenz beseitigt

 Revision 1.6  2000/07/11 18:35:18  MH
 RFC/PPP: String 'NNTP-Einstellungen' in die Resourcen eingebunden

 Revision 1.5  2000/07/07 20:01:23  MH
 RFC/PPP: SpoolDirs werden nun nur bei nderung dessen
          ber das Clientmen berschrieben

 Revision 1.4  2000/07/03 19:51:48  rb
 xpdefine.inc included

 Revision 1.3  2000/07/03 12:21:20  MH
 - no coment...

 Revision 1.2  2000/07/03 12:18:00  MH
 - LogInfos unten hinzugefgt

}
