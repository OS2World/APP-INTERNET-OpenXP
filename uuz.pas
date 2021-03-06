{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams,  }
{ Aenderungen des Sources die vom OpenXP Teams getaetigt wurden,  }
{ unterliegen den Rechten die bis zum 09.04.2000 fuer das OpenXP  }
{ Team gueltig waren                                              }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: uuz.pas,v 1.52 2002/04/18 23:36:59 rb Exp $ }

{ UUCP/RFC <-> ZConnect }
{ PM 10/92              }

{$I XPDEFINE.INC }

{$IFDEF Delphi }
  {$APPTYPE CONSOLE }
{$ENDIF }

{$IFDEF BP }
  {$M 16384,$a000,655360}
{$ENDIF }

program uuz;

uses  xpglobal,
{$IFDEF BP }
  ems,
{$ENDIF }
  crt,dos,dosx,typeform,fileio,xpdatum,montage,stack,mimedec;

const
      midlen      = 120;
      orglen      = 80;
      adrlen      = 80;
      realnlen    = 70;           { 11.10.1999 robo - Realname verl�ngert }
      hderrlen    = 60;
      maxemp      = 50;
      maxulines   = 60;               { max. zus�tzliche U-Zeilen }
      maxmore     = 15;               { max. String's pro RFC-Headerzeile }
      maxrefs     = 20;               { max. gespeicherte References }
      maxfollow   = 10;               { max. Followup-To-Zeilen }
{$IFDEF BP }
      bufsize     = 16384;
      outbufsize  = 16384;
{$ELSE }
      bufsize     = 32768;
      outbufsize  = 32768;
{$ENDIF }
      BetreffLen  = 248;
      readempflist= true;
      postadrlen  = 80;
      telelen     = 60;
      homepagelen = 90;
      { 01/2000 oh }
      custheadlen = 60;
      { /oh }
      maxaddhds   = 10;
      xpboundary  : string = '-';     { 06.01.2000 robo }

{      attrCrash   = $0002; }
      attrFile    = $0010;            { File Attach }
      AttrMPbin   = $0040;            { Multipart-Binary }
      attrReqEB   = $1000;            { EB anfordern }
      attrIsEB    = $2000;            { EB }
      AttrPmReply = $0100;            { PM-Reply auf AM (Maus/RFC) }
      AttrControl = $0020;            { Cancel-Nachricht }
      AttrQPC     = $0001;

      fPGP_encoded  = $0001;          { Nachricht ist PGP-codiert  }
      fPGP_avail    = $0002;          { PGP-Key vorhanden          }
      fPGP_signed   = $0004;          { Nachricht ist mit PGP sign.}
      fPGP_clearsig = $0008;          { Clear-Signatur             }
      fPGP_sigok    = $0010;          { Signatur war ok            }
      fPGP_sigerr   = $0020;          { Signatur war fehlerhaft    }
      fPGP_please   = $0040;          { Verifikations-Anforderung  }
      fPGP_request  = $0080;          { Key-Request                }
      fPGP_haskey   = $0100;          { Nachricht enth�lt PGP-Key  }
      fPGP_comprom  = $0200;          { Nachricht enth�lt compromise }

      nt_ZConnect = 2;
      nt_RFC      = 40;
      nt_PPP      = 41;
      uncompress  = 'compress.exe -df ';
      unfreeze    = 'freeze.exe -dif ';
      ungzip      = 'gzip.exe -df ';
{$IFDEF BP }
      SwapFileName= 'uuz.swp';
{$ENDIF }
      UUserver    = 'UUCP-Fileserver';
      tspecials   = '()<>@,;:\"/[]?=';       { RFC822-Special Chars    }
      tspecials2  = tspecials+' ';           { RFC1341-Speical Chars   }

      XpWindow    : byte = 0;

      ParSize     : boolean = false;         { Size negotiation }
      SMTP        : boolean = false;
      cSMTP       : boolean = false;         { compressed SMTP  }
      fSMTP       : boolean = false;         { frozen SMTP      }
      zsmtp       : boolean = false;         { GNU-Zipped SMTP  }
      NewsMIME    : boolean = false;
      NoMIME      : boolean = false;         { -noMIME }
      MakeQP      : boolean = false;         { -qp: MIME-quoted-printable }
      RFC1522     : boolean = false;         { Headerzeilen gem. RFC1522 codieren }
{ 31.01.2000 robo - Envelope-Empf�nger aus Received auslesen? }
      getrecenvemp: boolean = false;
{ /robo }
      AbsNSStyle  : boolean = false;         { Absender im Netscape-Stil }
      ppp         : boolean = false;         { -ppp (f�r UKA* etc.) }
      MailUser    : string[30] = 'mail';     { fuer U-Zeile im X-File }
      NewsUser    : string[30] = 'news';
      FileUser    : string[30] = 'root';
      OwnSite     : string[60] = '';         { f�r Empf�ngeradresse von Mails }
      boxname     : string[20] = '';         { Boxname }
      shrinkheader: boolean = false;         { uz: r-Schalter }
      nomailer    : boolean = false;

      tText       = 1;        { Content-Types: plain, richtext       }
      tMultipart  = 2;        { mixed, parallel, alternative, digest }
      tMessage    = 3;        { rfc822, partial, external-body       }
      tApplication= 4;        { octet-stream, postscript, oda        }
      tImage      = 5;        { gif, jpeg                            }
      tAudio      = 6;        { basic                                }
      tVideo      = 7;        { mpeg                                 }
      tModel      = 8;        { model                                }

      encBase64   = 1;        { Content-Transfer-Encodings           }
      encQP       = 2;        { quoted-printable                     }
      enc8bit     = 3;
      enc7bit     = 4;
      encBinary   = 5;

type  OrgStr  = string[orglen];
      mimedata= record
                  mversion : string[10];     { MIME-Version              }
                  encoding : byte;           { Content-Transfer-Encoding }
                  ctype    : byte;           { Content-Type              }
                  subtype  : string[20];     { Content-Subtype           }
                  charset  : string[20];     { text/*; charset=...       }
                  filetype : string[20];     { application/o-s; type=... }
                  boundary : string[100];    { multipart: boundary=...   }
                end;
      mimeproc= procedure(var s:string);
      empflistt = array[1..maxemp] of string[AdrLen];

      empfnodep=^empfnode;
      empfnode= record
                  next   : empfnodep;
                  empf   : string[adrlen];
                end;

      header  = record
                  netztyp    : byte;
                  ulines     : byte;          { Anzahl "U-"-Zeilen }
                  lines      : longint;       { "Lines:" }
                  archive    : boolean;       { archivierte PM }
                  empfaenger : string[AdrLen];
                  kopien     : empfnodep;
                  xempf      : empflistt;
                  empfanz    : integer;       { Anzahl EMP-Zeilen }
                  betreff    : string[250];   { verl�ngert wegen MIME-Codierung }
                  absender   : string[80];
                  datum      : string[11];    { Netcall-Format }
                  zdatum     : string[22];    { ZConnect-Format }
                  pfad,pfad2 : string;        { Netcall-Format }
                  msgid,ref  : string[midlen];{ ohne <> }
                  ersetzt    : string[midlen];
                  addrefs    : integer;
                  addref     : array[1..maxrefs] of string[midlen];
                  typ        : string[1];     { T / B }
                  crypttyp   : string[1];
                  groesse    : longint;
                  komlen     : longint;       { Kommentar-L�nge }
                  ckomlen    : longint;
                  realname   : string[realnlen];
                  programm   : string[120];   { Mailer-Name }
                  datei      : string[40];    { Dateiname }
                  ddatum     : string[22];    { Dateidatum, jjjjmmtthhmmss }
                  prio       : byte;          { 10=direkt, 20=Eilmail }
                  real_box   : string[20];    { falls Adresse = User@Point }
                  hd_point   : string[25];    { eigener Pointname }
                  pm_bstat   : string[20];    { Bearbeitungs-Status }
                  attrib     : word;          { Attribut-Bits }
                  filterattr : word;
                  fido_to    : string[36];
                  organisation: OrgStr;
                  postanschrift : string[PostAdrLen];
                  telefon    : string[TeleLen];
                  homepage   : string[HomepageLen];
                  PmReplyTo  : string[AdrLen];   { Antwort-An }
                  AmReplyTo  : string[AdrLen];   { Diskussiom-In, nicht benutzt! }
                  amrepanz   : integer;
                  followups  : integer;          { Anzahl Followup's }
                  followup   : array[1..maxfollow] of string[AdrLen];
                  error      : string[hdErrLen]; { ERR-Header }
                  ReplyPath  : string[8];
                  ReplyGroup : string[40];
                  wab        : string;           { Envelope-Absender }
                  oem,oab    : string[AdrLen];
                  xoem       : empflistt;
                  oemanz     : integer;
{                  oar,war    : string[40]; }      { Realnames }
                  oar,war    : string[realnlen]; { Realnames }
                  { 11.10.1999 robo - Realname verl�ngert }

                  gateway    : string[80];
                  empfbestto : string[AdrLen];
                  x_charset  : string[25];
                  keywords   : string[60];
                  summary    : string[200];
                  priority   : byte;           { Priority by MH }
                  distribution:string[40];
                  pm_reply   : boolean;
                  sender     : string[80];
                  MIME       : mimedata;
                  QuoteString: string[20];
                  charset    : string[7];
                  ccharset   : string[7];
                  org_msgid  : string[midlen];
                  org_xref   : string[midlen];
                  pgpflags   : word;
                  pgp_uid    : string[80];
                  vertreter  : string[80];
                  XPointCtl  : longint;
                  nokop      : boolean;
                  boundary   : string[70];
                  mimetyp    : string[30];
                  mimereltyp : string[25];
                  xnoarchive : boolean;
                  Cust1,Cust2: string[custheadlen];
                  envemp     : string[AdrLen];
                  xpmode     : string[20];          { hdronly }
                 {xpmsg      : string[6];}
                end;
      charr   = array[0..65530] of char;
      charrp  = ^charr;
      ulinea  = array[1..maxulines] of string;


var   source,dest   : pathstr;       { Quell-/Zieldateien  }
      f1,f2         : file;          { Quell/Zieldatei     }
{      errorlevel    : integer; }
      u2z           : boolean;       { Richtung; mail/news }
      mails,news    : longint;       { Counter             }
      buffer        : array[0..bufsize] of char;    { Kopierpuffer }
      bufpos,bufanz : integer;       { Leseposition / Anzahl Zeichen }
      hd            : header;
      empflist      : empfnodep;
      uline         : ^ulinea;
      uunumber      : word;          { fortlaufende Hex-Paketnummer }
      _from,_to     : string[20];    { UUCP-Systemnamen }
      smore         : array[1..maxmore] of string;
      outbuf        : charrp;
      outbufpos     : word;
      s             : string;
      MaxSlen       : longint;       { max. L�nge f�r ReadString() }
      qprint,b64    : boolean;       { MIME-Content-TT's (ReadRFCheader) }
      qprchar       : set of char;
      addpath       : string;
      addhd         : array[1..maxaddhds] of string;
      addhdmail     : array[1..maxaddhds] of boolean;
      addhds        : integer;


{ 01/2000 oh : wird zum Einlesen der Customizable Headerlines ben�tigt }

const mheadercustom : array[1..2] of string[custheadlen] = ('','');


procedure Charset2IBM;
  begin
    with hd.mime do
      if (ctype<>tMultipart)
      { text/html nicht konvertieren: }
{     and not ((ctype=tText) and (subtype='html')) }
      and ((ctype<>tText) or (subtype<>'html'))
        then CharsetToIBM(charset,s);
  end;

procedure logo;
begin
   {$ifndef linux}         { ML 25.03.2000  workaround f�r Linux - Outputumleitung mgl. }
  assign(output, '');
  rewrite(output);
{$endif}
  writeln;
  writeln('ZConnect <-> RFC/UUCP/SMTP Converter with MIME (c) ''93-99 PM');
  writeln('XP2-Version ',verstr,pformstr,betastr,' ',x_copyright,
            ' by ',author_name,' <',author_mail,'>');
  writeln;
end;

procedure HelpPage;
begin
  writeln('UUZ -uz [Switches] <Source file(s)> <Destination file> [ownsite.domain]');
  writeln('UUZ -zu [Switches] <Source file> <Dest.Dir.> <fromSite> <toSite> [Number]');
  writeln;
  writeln('uz switches:  -graberec  =  grab envelope recipient from Received-header');
  writeln('              -bBoxname');
  writeln;
  writeln('zu switches:  -s      =  Taylor UUCP size negotiation');
  writeln('              -SMTP   =  Batched SMTP (-c/f/zSMTP = compressed)');
  writeln('              -MIME   =  Use MIME for news');
  writeln('              -noMIME =  Do not create any MIME headers');
  writeln('              -qp     =  MIME: quoted-printable (default: 8bit)');
  writeln('              -1522   =  MIME: create RFC-1522 headers');
  writeln('              -uUser  =  User to return error messages to');
  halt(1);
end;

procedure error(s:string);
begin
  writeln('Fehler: ',s);
  halt(1);
end;

procedure GetPar;
var i      : integer;
    switch : string[10];
begin
  if (lstr(paramstr(1))<>'-uz') and (lstr(paramstr(1))<>'-zu') then
    HelpPage;
  if lstr(paramstr(1))='-uz' then begin
    if paramcount<3 then helppage;
    u2z:=true;
    source:=''; dest:=''; OwnSite:='';
    for i:=2 to paramcount do
      if left(paramstr(i),1)='-' then begin
        switch:=lstr(mid(paramstr(i),2));
        if left(switch,2)='w:' then
          XpWindow:=minmax(ival(mid(switch,3)),15,60) else
        { 31.01.2000 robo - Envelope-Empf�nger aus Received auslesen? }
        if switch='graberec' then
          getrecenvemp:=true else
        { /robo }
        if switch='r' then
          shrinkheader:=true else
        if switch='ppp' then
          ppp:=true else
        if switch[1]='b' then
          boxname:=mid(paramstr(i),3);
        end
      else
        if source=''  then source:=ustr(paramstr(i)) else
        if dest=''    then dest:=ustr(paramstr(i)) else
        if OwnSite='' then OwnSite:=paramstr(i);
    end
  else begin
    u2z:=false;
    if paramcount<5 then helppage;
    source:=''; dest:=''; _from:=''; _to:='';
    for i:=2 to paramcount do
      if left(paramstr(i),1)='-' then begin
        switch:=lstr(mid(paramstr(i),2));
        if left(switch,2)='w:' then
          XpWindow:=minmax(ival(mid(switch,3)),15,60) else
        if switch='s' then ParSize:=true else
        if switch='smtp' then SMTP:=true else
        if switch='csmtp' then begin
          SMTP:=true; cSMTP:=true; end else
        if switch='fsmtp' then begin
          SMTP:=true; fSMTP:=true; end else
        if switch='zsmtp' then begin
          SMTP:=true; zSMTP:=true; end else
        if switch='mime' then
          NewsMIME:=true else
        if switch='nomime' then
          NoMIME:=true else
        if switch='qp' then
          MakeQP:=true else
        if switch='1522' then
          RFC1522:=true else
        if switch='absnsstyle' then
          AbsNSStyle:=true else
        if switch='ppp' then
          ppp:=true else
        if switch[1]='u' then begin
          MailUser:=mid(paramstr(i),3);
          NewsUser:=Mailuser;
          FileUser:=MailUser;
          end;
        end
      else
        if source='' then source:=paramstr(i) else
        if dest=''   then dest:=paramstr(i) else    { Ziel-*Verzeichnis* }
        if _from=''  then _from:=paramstr(i) else
        if _to=''    then _to:=paramstr(i) else
        uunumber:=hexval(paramstr(i));
    end;
  if exist('nomime.uuz') then NoMIME:=true;
  if exist('igate.exe') then nomailer:=true;
  if exist('absnssty.uuz') then AbsNSStyle:=true;
end;

procedure initvar;
var t : text;
    s : string;

  procedure rh(fn:pathstr; mail:boolean);
  begin
    if exist(fn) then begin
      assign(t,fn);
      reset(t);
      while not eof(t) and (addhds<maxaddhds) do begin
        readln(t,s);
        s:=trim(s);
        if s<>'' then
          if cpos(':',s)<3 then
            writeln('Warning: Illegal Line in '+fn+': "'+s+'"'#7)
          else begin
            inc(addhds);
            addhd[addhds]:=s;
            addhdmail[addhds]:=mail;
            end;
        end;
      close(t);
      end;
  end;

begin
  randomize;
  mails:=0; news:=0;
  uunumber:=0;
  new(uline);
  MaxSlen:=255;
  qprchar:=[^L,'=',#127..#255];
  getmem(outbuf,outbufsize);

  if exist('addpath') then begin    { ADDPATH: Zusatz f�r Pfadzeile }
    assign(t,'addpath');
    reset(t);
    readln(t,addpath);
    close(t);
    if (addpath<>'') and (lastchar(addpath)<>'!') then
      addpath:=addpath+'!';
    end
  else
    addpath:='';

  addhds:=0;                        { zus�tzliche Headerzeilen einlesen }
  rh('NEWS.RFC',false);
  rh('MAIL.RFC',true);
end;

procedure donevar;
  begin
    freemem(outbuf,outbufsize);
    dispose(uline);
  end;

procedure testfiles;
begin
  if not exist(source) then error('Quelldatei fehlt');
  if u2z and not validfilename(dest) then
    error('ung�ltige Zieldatei: '+dest);
  if not u2z then begin
    if (right(dest,1)<>':') and (right(dest,1)<>'\') then
      dest:=dest+'\';
    if not IsPath(dest) then
      error('ung�ltiges Zielverzeichnis: '+dest);
    end;
end;


{ --- Shell --------------------------------------------------------- }

procedure shell(prog:string; space:word);  { Externer Aufruf }
{$IFNDEF BP }
begin
  Exec(prog, '');
end;
{$ELSE }
{$ifndef ver55}
  const freeptr : pointer = nil;
{$endif}
type so = record
            o,s : word;
          end;
var regs  : registers;
    p     : pointer;
    fs    : word;
    brk   : boolean;
    paras : word;            { belegte Paragraphs von M2  }
    free  : word;            { freie Paras nach Set Block }
    envir : array[0..1023+18] of byte;    { neues Environment }
    dpath : pathstr;
    para  : string[130];
    pp    : byte;
    sm2t  : boolean;

    swapfile : file;
    swappars : word;        { auszulagernde Paragraphen }
    EMShandle: word;        { EMS-Handle, oder 0        }
    heapfree : word;
    swapok   : boolean;


  function memfree:word;
  var regs : registers;
  begin
    with regs do begin
      ah:=$48;                { Test, ob residentes Prog. geladen }
      bx:=$ffff;
      msdos(regs);
      memfree:=bx;
      end;
  end;

  procedure SwapOut(swapp,count:word);
  var page,spar,rr : word;
  begin
    if EmsAvail>=count div 1024 +1 then
    begin
      EMSAlloc(count div 1024+1,EMShandle);
      page:=0;
      repeat
        EmsPage(EMShandle,0,page);
        if count>=1024 then spar:=1024
        else spar:=count;
        FastMove(mem[swapp:0],mem[emsbase:0],spar*16);
        inc(swapp,spar);
        dec(count,spar);
        inc(page);
      until count=0;
      swapok:=true;
      end
    else begin
      EmsHandle:=0;
      assign(swapfile,SwapFileName);
      rewrite(swapfile,1);
      repeat
        blockwrite(swapfile,mem[swapp:0],min(count,$ff0)*16,rr);
        if (count>0) and (rr=0) then
          inoutres:=101;
        inc(swapp,rr div 16);
        dec(count,rr div 16);
      until (count=0) or (inoutres<>0);
      close(swapfile);
      if inoutres=0 then
        setfattr(swapfile,readonly);
      swapok:=inoutres=0;
      if not swapok then begin
        error('Fehler beim Speicherauslagern!');
        if existf(swapfile) then erase(swapfile);
        end;
      end;
  end;

  procedure SwapIn(swapp,count:word);
  var rr,page,spar : word;
  begin
    if emshandle<>0 then begin
      page:=0;
      repeat
        EmsPage(EMShandle,0,page);
        if count>=1024 then spar:=1024
        else spar:=count;
        FastMove(mem[emsbase:0],mem[swapp:0],spar*16);
        inc(swapp,spar);
        dec(count,spar);
        inc(page);
      until count=0;
      EmsFree(EMShandle);
      end
    else begin
      setfattr(swapfile,0);
      reset(swapfile,1);
      if ioresult<>0 then error('SWAP-File nicht mehr vorhanden!');
      { swapp:=so(heapptr).s-swappars+2; count:=swappars; }
      repeat
        blockread(swapfile,mem[swapp:0],min(count,$ff0)*16,rr);
        inc(swapp,rr div 16);
        dec(count,rr div 16);
      until (count=0) or (rr=0) or (inoutres<>0);
      if (count<>0) or (inoutres<>0) then
        error('Fehler beim Lesen des SWAP-Files');
      close(swapfile);
      erase(swapfile);
      end;
  end;

  { MK Funktion ist eigentlich sinnlos, rausnehmen ? }
{
  procedure geterrorlevel;
  var
    regs : registers;
  begin
    errorlevel:=lo(dosexitcode);
    if errorlevel=0 then begin
      regs.ah:=$4d;
      msdos(regs);
      errorlevel:=regs.al;
      end;
  end;
}

begin
  doserror:=0;
  if maxavail<$8000 then
    writeln('Zu wenig freier Speicher f�r externen Programmaufruf!')
  else begin
    pp:=pos(' ',prog);
    if pp=0 then para:=''
    else begin
      para:=' '+trim(copy(prog,pp+1,127));
      prog:=left(prog,pp-1);
      end;
    prog:=ustr(prog);

    {$IFDEF DPMI}
      exec(prog,para);
    {$ELSE}

      if so(freeptr).o>0 then          { Gr��e der Free-Liste ermitteln }
        fs:=$1000a-so(freeptr).o
      else
        fs:=0;
      if fs>0 then begin               { Freeliste sichern }
        getmem(p,fs);
        FastMove(freeptr^,p^,fs);
        end;


      paras:=memw[prefixseg:2]-prefixseg+1;
      space:=(space+1)*64;   { KB -> Paragraphs, + 1 extra-KB }
      heapfree:=prefixseg+paras-so(heapptr).s;
      swapok:=true;
      if (heapfree>=space) or (so(heapptr).s-ovrheaporg<64) then
        swappars:=0
      else begin
        swappars:=min(space-heapfree,so(heapptr).s-ovrheaporg-2);
        SwapOut(so(heapptr).s-swappars+2,swappars);
        end;

      if swapok then begin
        with regs do begin
          ah:=$4a;          { set block }
          bx:=so(heapptr).s+3-prefixseg-swappars;
          es:=prefixseg;
          msdos(regs);                   { Speicher freigeben }
          end;
        free:=memfree;

        if (pos('|',para)>0) or (pos('>',para)>0) or (pos('<',para)>0) then
          dpath:=''
        else begin
          if exist(prog) then dpath:=prog
          else dpath:=UStr(fsearch(prog,getenv('PATH')));
          if (right(dpath,4)<>'.EXE') and (right(dpath,4)<>'.COM') then
            dpath:='';
          end;
        swapvectors;
        if (para<>'') and (para[1]<>' ') then para:=' '+para;
        if dpath<>'' then
          exec(dpath,para)
        else
          exec(getenv('comspec'),' /c '+prog+iifs(para<>'',para,''));
        swapvectors;
{        geterrorlevel; }

        with regs do begin
          ah:=$4a;                { Speicherblock wieder herstellen }
         { bx:=paras;  - klappt nicht bei DR-DOS 3.41 }
          bx:=$ffff;
          es:=prefixseg;
          msdos(regs);
          ah:=$4a;
          es:=prefixseg;
          msdos(regs);
          end;

        if swappars>0 then SwapIn(so(heapptr).s-swappars+2,swappars);
        end;  { is swapok }

      if fs>0 then begin
        FastMove(p^,freeptr^,fs);
        freemem(p,fs);
        end;

    {$ENDIF}    { not DPMI }

    if doserror<>0 then
      error('Fehler '+strs(doserror)+' bei Programm-Aufruf');
    end;
end;

{$ENDIF }


procedure fmove(var f1,f2:file);
var rr : word;
begin
  while not eof(f1) do begin
    blockread(f1,buffer,bufsize,rr);
    blockwrite(f2,buffer,rr);
    end;
end;


{ --- ZConnect-Header verarbeiten ----------------------------------- }

procedure AddToEmpflist(empf:string);
var p : empfnodep;
begin
  p:=@empflist;
  while p^.next<>nil do p:=p^.next;
  new(p^.next);
  p^.next^.next:=nil;
  p^.next^.empf:=empf;
end;

procedure DisposeEmpflist(var list:empfnodep);
var p : empfnodep;
begin
  while list<>nil do begin
    p:=list^.next;
    dispose(list);
    list:=p;
    end;
end;

function compmimetyp(typ:string):string;
begin
  if left(typ,12)='application/' then
    compmimetyp:=lstr(mid(typ,12))
  else
    compmimetyp:=lstr(typ);
end;

const ReadKoplist = false;

{$define uuzrefs}
{$define ulines}
{$define pgp}

{ 03.02.2000 robo }
{$define uuzmime }
{ /robo }

{$I xpmakehd.inc}


procedure FlushOutbuf;
begin
  if outbufpos>0 then
    blockwrite(f2,outbuf^,outbufpos);
  outbufpos:=0;
end;

procedure wrfs(var s:string);
begin
  if outbufpos+length(s)>=outbufsize then
    FlushOutbuf;
  FastMove(s[1],outbuf^[outbufpos],length(s));
  inc(outbufpos,length(s));
end;


procedure WriteHeader;
var i  : integer;
    ml : shortint;
    ss : string;

  procedure wrs(s:string);
  begin
    TruncStr(s,253);
    s:=s+#13#10;
    wrfs(s);
  end;

  procedure WriteStichworte(keywords:string);
  var p  : byte;
      stw: string[60];
  begin
    while keywords<>'' do begin
      p:=cpos(',',keywords);
      if p=0 then p:=length(keywords)+1;
      stw:=trim(left(keywords,p-1));
      if stw<>'' then wrs('Stichwort: '+stw);
      delete(keywords,1,p);
      end;
  end;

begin
  with hd do begin
    if empfanz=0 then wrs('EMP: /UNZUSTELLBAR');
    for i:=1 to empfanz do
      wrs('EMP: '+xempf[i]);
    for i:=1 to oemanz do begin
      ml:=min(length(xoem[i]),length(xempf[1]));
      if (xoem[i]<>'') and (left(lstr(xoem[i]),ml)<>left(lstr(xempf[1]),ml))
      then
        wrs('OEM: '+xoem[i]);
      end;
    if not getrecenvemp and (envemp<>'') then wrs('U-X-Envelope-To: '+envemp);
    wrs('ABS: '+absender+iifs(realname='','',' ('+realname+')'));
    if wab<>'' then wrs('WAB: '+wab);
    wrs('BET: '+betreff);
    if pfad2='' then
      wrs('ROT: '+pfad)
    else begin              { Pfad > 255 Zeichen }
      ss:='ROT: ';
      wrfs(ss); wrfs(pfad); wrs(pfad2);
      end;
    wrs('MID: '+msgid);
    wrs('EDA: '+zdatum);
    wrs('LEN: '+strs(groesse));
    if (PmReplyTo<>'') and (PmReplyTo<>absender) then
      wrs('Antwort-an: '+PmReplyTo);
    for i:=1 to followups do
      wrs('Diskussion-in: '+followup[i]);
    if typ='B'        then wrs('TYP: BIN');
    if datei<>''      then wrs('File: '  +datei);
    if ddatum<>''     then wrs('DDA: '   +ddatum);
    if ref<>''        then wrs('BEZ: '   +ref);
    for i:=1 to addrefs do wrs('BEZ: '  +addref[i]);
    if ersetzt<>''    then wrs('ersetzt: '+ersetzt);
    if error<>''      then wrs('ERR: '   +error);
    if programm<>''   then wrs('Mailer: '+programm);
    if xnoarchive     then wrs('U-X-NO-ARCHIVE: yes');
    if priority<>0    then wrs('U-X-PRIORITY: '+strs(priority));
    if prio<>0        then wrs('Prio: '  +strs(prio));
    if xpmode<>''     then wrs('X-XP-MODE: '+xpmode);
    if organisation<>''  then wrs('ORG: '+organisation);
    if postanschrift<>'' then wrs('Post: '+postanschrift);
    if telefon<>''       then wrs('Telefon: '+telefon);
    if homepage<>''      then wrs('U-X-Homepage: '+homepage);
    if EmpfBestTo<>'' then wrs('EB: '    + iifs(empfbestto<>absender,empfbestto,''));
    if attrib and attrIsEB<>0  then wrs('STAT: EB');
    if pm_reply       then wrs('STAT: PM-REPLY');
    if pgpflags and fPGP_encoded<>0 then wrs('CRYPT: PGP');
    if keywords<>''   then WriteStichworte(keywords);
    if summary<>''    then wrs('Zusammenfassung: '+summary);
    if distribution<>''  then wrs('U-Distribution: '+distribution);
    if mime.boundary<>'' then wrs('X-XP-Boundary: '+mime.boundary);
    if gateway<>''    then wrs('X-Gateway: '+gateway);
    if sender<>''     then wrs('U-Sender: '+sender);
    for i:=1 to ulines do
      wrs(uline^[i]);
    wrs('X-XP-NTP: '+strs(netztyp));
    if boxname<>''  then wrs('X-XP-BOX: '+boxname);
    attrib:=attrib and not (attrReqEB+attrIsEB);
    if attrib<>0    then wrs('X-XP-ATT: '+hex(attrib,4));
    if fido_to<>''  then wrs('F-TO: '+fido_to);
    if XPointCtl<>0 then wrs('X-XP-CTL: '+strs(XPointCtl));
    wrs('');
    end;
end;


{ Datumsformate:         11 Jan 92 01:02 GMT
                    Mon, 11 Jan 1992 01:02:03 GMT
                    Mon Jan 11, 1992 01:02:03 XYZ  }

function RFC2Zdate(var s0:string):string;
const tzones = 52;
      tzone  : array[0..tzones-1,0..1] of string[7] =
               (('GMT','W+0'),('MST','W-7'),('MET','W+1'),('CET','W+1'),
                ('MEST','S+2'),('MES','S+2'),('MESZ','S+2'),
                ('NT','W-11'),('AHST','W-10'),('YST','W-9'),('PST','W-8'),
                ('PDT','S-7'),('CST','W-6'),('MDT','S-6'),
                ('EST','W-5'),('CDT','S-5'),('AST','W-4'),('EDT','S-4'),
                ('NST','W-3:30'),('GST','W-3'),('ADT','S-3'),('AT','W-2'),
                ('WAT','W-1'),('UT','W+0'),('Z','W+0'),('BST','S+1'),
                ('MEWT','W+1'),('SWT','W+1'),
                ('FWT','W+1'),('HFH','W+1'),('EET','W+2'),
                ('SST','S+2'),('FST','S+2'),('HFE','S+2'),('BT','W+3'),
                ('ZP4','W+4'),('ZP5','W+5'),('IST','W+5:30'),('ZP6','W+6'),
                ('WAST','W+7'),('JT','W+7:30'),('WADT','S+8'),('CCT','W+8'),
                ('JST','W+9'),('CAST','W+9:30'),('SAST','W+9:30'),
                ('EAST','W+10'),('CADT','S+10:30'),('SADT','S+10:30'),
                ('NZT','W+12'),('NZST','W+12'),('NZDT','S+13'));

var p,p2  : byte;
    t,m,j : word;
    h,min,s : integer;
    ti    : datetimest;
    zone  : string[10];
    i     : integer;

  function getstr:string;
  var p : byte;
  begin
    p:=cpos(' ',s0); if p=0 then p:=cpos(#9,s0);
    if p=0 then begin
      getstr:=s0; s0:='';
      end
    else begin
      getstr:=left(s0,p-1);
      s0:=trim(mid(s0,p+1));
      end;
  end;

  procedure CorrTime;           { Zonenoffset zu Zeit addieren }
  var res     : integer;
      off,moff: integer;
      p       : byte;
  begin
    val(copy(ti,1,2),h,res);
    val(copy(ti,4,2),min,res);
    val(copy(ti,7,2),s,res);
    p:=cpos(':',zone);
    if p=0 then begin
      off:=minmax(ival(mid(zone,2)),-13,13);
      moff:=0;
      end
    else begin
      off:=minmax(ival(copy(zone,2,p-2)),-13,13);
      moff:=minmax(ival(mid(zone,p+1)),0,59);
      end;
    zone:=left(zone,2)+formi(abs(off),2)+iifs(moff<>0,':'+formi(moff,2),'');
    dec(min,sgn(off)*moff);
    dec(h,off);
    while min<0  do begin  inc(min,60); dec(h); end;
    while min>59 do begin  dec(min,60); inc(h); end;
    while h<0    do begin  inc(h,24);   dec(t); end;
    while h>23   do begin  dec(h,24);   inc(t); end;
    if t<1 then begin
      dec(m);
      if m=0 then begin m:=12; dec(j); end;
      schalt(j);
      t:=monat[m].zahl;
      end
    else begin
      schalt(j);
      if t>monat[m].zahl then begin
        t:=1; inc(m);
        if m>12 then begin m:=1; inc(j); end;
        end;
      end;
  end;

begin
  p:=cpos(',',s0);
  p2:=cpos(' ',s0);
  if p>0 then
    if (p2=0) or (p2>p) then
      s0:=trim(mid(s0,p+1))   { Mon, 11 Jan ...   Wochentag killen }
    else begin                { [Mon ]Jan 11, ... }
      p2:=p-1;
      while s0[p2]<>' ' do dec(p2);
      s0:=copy(s0,p2+1,p-p2-1)+' '+copy(s0,max(1,p2-3),3)+' '+trim(mid(s0,p+1));
      end;
  t:=minmax(ival(getstr),1,31);
  p:=pos(lstr(getstr),'janfebmaraprmayjunjulaugsepoctnovdec');
  if p>0 then m:=(p+2)div 3 else m:=1;
  j:=minmax(ival(getstr),0,2099);
  if j<100 then
    if j<70 then inc(j,2000)   { 2stellige Jahreszahl erg�nzen }
    else inc(j,1900);
  ti:=getstr;
  if pos(':',ti)=0 then
    if length(ti)=4 then ti:=left(ti,2)+':'+right(ti,2)+':00'  { RFC 822 }
    else ti:='00:00:00';
  zone:=getstr;
  if zone='' then zone:='W+0'
  else if (zone[1]='+') or (zone[1]='-') then begin
    zone:='W'+left(zone,3)+':'+copy(zone,4,2);
    if lastchar(zone)=':' then zone:=zone+'00';
    end
  else begin
    UpString(zone);
    i:=0;
    while (i<tzones) and (zone<>tzone[i,0]) do inc(i);
    if i=tzones then zone:='W+0'
    else zone:=tzone[i,1];
    end;
  CorrTime;
  RFC2Zdate:=formi(j,4)+formi(m,2)+formi(t,2)+formi(h,2)+formi(min,2)+
             formi(s,2)+zone;
end;



{ --- MIME ---------------------------------------------------------- }

{ Content-Types:  text        plain            charset=us-ascii
                              richtext                 iso-8851-x

                  multipart   mixed, parallel  boundary=...
                              alternative        "
                              digest             "

                  message     rfc822
                              partial          number=  total=  id=
                              external-body    access-type=  size= ...

                  application octet-stream     name= type= conversions=
                              postscript, oda    x-date=

                  image       gif, jpeg        x-filename=  x-date=
                  audio       basic
                  video       mpeg

  MIMEdata      : mversion : string[10];     MIME-Version
                  encoding : byte;           Content-Transfer-Encoding
                  ctype    : byte;           Content-Type
                  subtype  : string[20];     Content-Subtype
                  charset  : string[20];     text/*; charset=...
                  filetype : string[20];     application/o-s; type=...
                  boundary : string[100];    multipart; boundary=...   }


procedure UnQuote(var s:string);    { RFC-822-quoting entfernen }
var p : byte;
begin
  if s[1]='"' then delete(s,1,1);
  if s[length(s)]='"' then dellast(s);
  p:=1;
  while (p<length(s)) do begin
    if s[p]='\' then delete(s,p,1);
    inc(p);
    end;
end;

procedure QuoteStr(var s:string; qspace:boolean);   { Quoting erzeugen }
var p : byte;
begin
  if (qspace and multipos(tspecials2,s)) or
     (not qspace and multipos(tspecials,s)) then begin
    for p:=length(s) downto 1 do
      if s[p] in ['"','\'] then insert('\',s,p);
    s:='"'+s+'"';
    end;
end;


procedure GetMimeVersion(var s:string); {$IFNDEF Ver32 } far; {$ENDIF }
begin
  hd.mime.mversion:=s;
end;

procedure GetCTencoding(var s:string); {$IFNDEF Ver32 } far; {$ENDIF }
begin
  LoString(s);
  with hd.mime do
    if s='7bit' then encoding:=enc7bit else
    if s='8bit' then encoding:=enc8bit else
    if s='quoted-printable' then encoding:=encQP else
    if s='base64' then encoding:=encBase64 else
    if s='binary' then encoding:=encBinary
    else encoding:=enc8bit;       { Default: 8bit }
end;


procedure GetContentType(var s:string); {$IFNDEF Ver32 } far; {$ENDIF }
var p     : byte;
    s1    : string[20];
    value : string;

  procedure SkipWhitespace;
  begin
    inc(p);
    while (p<=length(s)) and (s[p] in [' ',#9]) do inc(p);    { whitespaces �berlesen }
    delete(s,1,p-1);
    p:=1;
  end;

  function filename:string;
  var p : byte;
  begin
    p:=length(value);
    while (p>0) and not (value[p] in ['/','\']) do dec(p);
    filename:=mid(value,p+1);
  end;

begin
  with hd.mime do begin
    p:=1;
    while (p<=length(s)) and not (s[p] in ['/',' ',#9]) do inc(p);
    s1:=lstr(left(s,p-1));
    if s1='text'        then ctype:=tText else    { --- Type }
    if s1='application' then ctype:=tApplication else
    if s1='multipart'   then ctype:=tMultipart else
    if s1='message'     then ctype:=tMessage else
    if s1='image'       then ctype:=tImage else
    if s1='audio'       then ctype:=tAudio else
    if s1='video'       then ctype:=tVideo else
    if s1='model'       then ctype:=tModel
    else ctype:=tApplication;     { Default: Application }
    while (p<=length(s)) and (s[p]<>'/') do inc(p)  ;   { / suchen }
    SkipWhitespace;
    if s<>'' then begin
      while (p<=length(s)) and not (s[p] in [';',' ',#9]) do inc(p);
      subtype:=lstr(left(s,p-1));       { --- Subtype  }
      if p>1 then delete(s,1,p-1);
      repeat                            { --- Parameter }
        p:=1;
        while (p<=length(s)) and (s[p]<>';') do inc(p);
        SkipWhitespace;
        if s<>'' then begin
          while (p<=length(s)) and (s[p]<>'=') do inc(p);
          s1:=lstr(trim(left(s,p-1)));
          SkipWhitespace;
          if s<>'' then begin
            if s[1]='"' then
              repeat inc(p) until (p=length(s)) or (s[p]='"')
            else
              repeat inc(p) until (p=length(s)) or (s[p]<=' ');
            value:=trim(left(s,p));
            if lastchar(value)=';' then
              dellast(value);
            inc(p);
            if value[1]='"' then UnQuote(value);
            case ctype of
              tText       : if s1='charset'   then charset:=lstr(value);
              tApplication: if s1='name'      then hd.datei:=filename else
                            if s1='type'      then filetype:=value else
                            if s1='x-date'    then hd.ddatum:=RFC2Zdate(value);
              tMultipart  : if s1='boundary'  then boundary:=value;
              tMessage    : ;
              else          if s1='x-filename'then hd.datei:=value else
                            if s1='x-date'    then hd.ddatum:=RFC2Zdate(value);
            end;
            end;
          end;
      until s='';
      end;
    if subtype='' then
      case ctype of
        tText        : subtype:='plain';
        tApplication : subtype:='octet-stream';
        tMultipart   : subtype:='mixed';
        tMessage     : subtype:='rfc822';
      end;
    if (ctype=tText) and (charset='') then charset:='us-ascii';
    end;
end;


procedure MimeAuswerten;
var ismime : boolean;
    binary : boolean;
begin
  with hd.mime do begin
    ismime:=(mversion<>'');
    qprint:=ismime and (encoding=encQP);
    b64:=ismime and (encoding=encBase64);
    binary:=ismime and (not (ctype in [tText,tMultipart,tMessage]) or
                        ((encoding=encBinary) and (ctype<>tText)));
    hd.typ:=iifc((binary or b64) and (ctype<>tText),'B','T');
    convert_cs(charset);
    if (ctype=tText) and (charset<>'') and (charset<>'us-ascii') and
{      (charset<>'iso-8859-1') }
       (left(charset,9)<>'iso-8859-') and (charset<>'windows-1252') and
       (charset<>'utf-8') and (charset<>'utf-7') then
      hd.error:='Unsupported character set: '+charset;
    end;
end;


procedure MakeQuotedPrintable;          { ISO-Text -> quoted-printable }
var p,q : byte;
begin
  if not MakeQP or (hd.mime.encoding<>encQP) then exit;
  p:=1;
  while p<=length(s) do begin           { qp-Codierung }
    if s[p] in qprchar then begin
      insert(hex(ord(s[p]),2),s,p+1);
      s[p]:='=';
      inc(p,2);
      end;
    inc(p);
    end;
(*p:=length(s);                         { white spaces am Ende codieren }
  while (p>0) and ((s[p]=' ') or (s[p]=#9)) do begin
    insert(hex(ord(s[p]),2),s,p+1);
    s[p]:='=';
    dec(p);
    end; *)

  p:=length(s);
  if (p>0) and (p<253) and ((s[p]=' ') or (s[p]=#9)) then begin
    s:=s+'='#10;
    q:=1;
  end
  else q:=0;

  p:=76;                                { Zeilen auf 76 Zeichen k�rzen }
  while p<length(s)-q do begin
    if s[p-1]='=' then dec(p)           { keine qp's auseinanderrei�en }
    else if s[p-2]='=' then dec(p,2);
    insert('='#10,s,p);
    inc(p,77);
    end;
end;

procedure RFC1522form;     { evtl. s mit quoted-printable codieren }
var p,p1,p2 : integer;
    encoded : boolean;
begin
  if RFC1522 then begin
    p1:=0;
    p2:=0;
    for p:=1 to length(s) do
      if s[p]>#127 then
        if p1=0 then begin
          p1:=p;
          p2:=p;
        end
        else p2:=p;
    if p1=0 then begin
      p1:=1;
      p2:=length(s);
    end
    else begin
      p:=posn(' ',reverse(s),length(s)-p1+1);
      if p=0 then p1:=1 else p1:=length(s)-p+2;
      p:=posn(' ',s,p2);
      if p=0 then p2:=length(s) else p2:=p-1;
    end;
    p:=p1;
    { wenn =? und ?= von Hand in den Header geschrieben wurden, m�ssen
      sie codiert werden: }
    encoded:=(pos('=?',copy(s,p1,p2-p1+1))>0) and
             (pos('?=',copy(s,p1,p2-p1+1))>0);
    while p<=p2 do begin           { qp-Codierung }
      if s[p]>=#127 then begin
        insert(hex(ord(s[p]),2),s,p+1);
        s[p]:='=';
        inc(p,2);
        inc(p2,2);
        encoded:=true;
        end
      else
        if s[p]='=' then s[p]:=#255;
      inc(p);
      end;
    if encoded then begin
      p:=p1;
      while p<=p2 do begin           { qp-Codierung }
        if s[p]=' ' then
          s[p]:='_'
        else
          if (s[p] in [#255,'?','_']) then begin
            if s[p]=#255 then s[p]:='=';
            insert(hex(ord(s[p]),2),s,p+1);
            s[p]:='=';
            inc(p,2);
            inc(p2,2);
            end;
        inc(p);
        end;
      insert('?=',s,p2+1);
      insert('=?ISO-8859-1?Q?',s,p1);
      end
    else
      for p:=1 to length(s) do
        if s[p]=#255 then s[p]:='=';
    end
  else
    begin end;   { !!! IBM -> ASCII }
end;


procedure GetBinType(fn:pathstr);    { vgl. MAGGI.PAS }
var p   : byte;
    ext : string[6];
    t   : text;
    s   : string;
begin
  with hd.mime do begin
    ctype:=tApplication;
    subtype:='octet-stream';
    p:=rightpos('.',fn);
    if p>0 then begin
      ext:=mid(fn,p+1);
      assign(t,'mimetyp.cfg');
      reset(t);
      if ioresult=0 then begin
        while not eof(t) do begin
          readln(t,s);
          if (s<>'') and (firstchar(s)<>'#') and
             stricmp(ext,GetToken(s,'=')) then
            GetContentType(s);
          end;
        close(t);
        end;
      end;
    end;
end;


procedure SetMimeData;
var i: integer;
begin
  xpboundary := '----=_XP2_NextPart_';
  for i := 1 to 10 + random (20) do
    xpboundary := xpboundary + char (random (25) + byte ('A'));
  with hd,hd.mime do begin
    mversion:='1.0';
    if typ='T' then begin
      if x_charset='' then encoding:=enc7bit
      else if MakeQP then encoding:=encQP
      else encoding:=enc8bit;

{ 03.02.2000 robo - multipart/mixed outgoing }

      if left(mimetyp,10)='multipart/' then begin
        ctype:=tMultipart;
        subtype:=mid(mimetyp,11);
        xpboundary:=hd.boundary;
      end
      else begin

        ctype:=tText;
        subtype:='plain';

      end;

{ /robo }

      charset:=iifs(x_charset='','us-ascii',x_charset);
      end
    else if attrib and AttrMPbin <> 0 then begin
      ctype:=tMultipart;
      subtype:='mixed';
      encoding:=enc7bit;
      end
    else begin
      encoding:=encBase64;
      if datei='' then begin
        ctype:=tApplication;
        subtype:='octet-stream';
        end
      else
        GetBinType(datei);
      end;
   end;
end;



{ --- UUCP/RFC -> ZConnect ------------------------------------------ }

var { ok   : boolean; }
    fpos : longint;
    eol  : byte;        { ReadString ist am Zeilenende angekommen }
    lasteol : boolean;  { eol der vorausgehenden Zeile>0 }


procedure ReadBuf;
begin
  fpos:=filepos(f1);
  blockread(f1,buffer,bufsize,bufanz);
  bufpos:=0;
end;

procedure OpenFile(var fn:pathstr);
begin
  assign(f1,fn);
  reset(f1,1);
  ReadBuf;
  eol:=1;    { damit lasteol beim ersten RestString true wird }
end;


{$R-}
procedure ReadString(umbruch:boolean);
const l : byte = 0;
      c : char = #0;

  procedure reload; {$IFNDEF Ver32 } far; {$ENDIF }
  begin
    if eof(f1) then { ok:=false }
    else ReadBuf;
  end;

  procedure IncPos;
  begin
    inc(bufpos);
    if bufpos=bufanz then reload;
  end;

{$IFNDEF Ver32 }
const
      savedi : word = 0;
      savebx : word = 0;
{$ENDIF }
begin
  lasteol:=(eol>0);
  eol:=0;
{$IFDEF Ver32 }
  l:=0;
  while (bufpos<bufanz) and (buffer[bufpos]<>#10) and
        (not umbruch or (l<253)) and (l<MaxSlen) do begin
    c:=buffer[bufpos];
    if c<>#13 then begin
      inc(l);
      s[l]:=c;
      end
    else
      inc(eol);
    IncPos;
    end;
  s[0]:=char(l);
  if buffer[bufpos]=#10 then begin
    inc(eol);
    IncPos;
    end;
{$ELSE  }
   asm
     mov   si,bufpos
     mov   di,0                    { l:=0 }
     mov   dl,umbruch
     mov   bx,word ptr maxslen
     mov   dh,byte ptr maxslen+2   { maxslen>$ffff -> dh<>0 }
     or    dh,byte ptr maxslen+3
     mov   cx,bufanz
@@1: cmp   si,cx                   { bufpos>=bufanz? }
     jae   @@8                     { Ende der Eingabedatei }
     or    dh,dh                   { l<maxslen? }
     jnz   @@2
     cmp   di,bx
     jae   @@8
@@2: or    dl,dl                   { not umbruch or .. }
     jz    @@3
     cmp   di,253                  { .. l<253 }
     jae   @@8
@@3: mov   al,byte ptr buffer[si]
     inc   si                      { c:=buffer[bufpos] }
     cmp   al,13
     jz    @@4
     cmp   al,10                   { eol-Zeichen? }
     jz    @@4
     cmp   di,253                  { max. Stringl�nge erreicht? }
     ja    @@5
     inc   di                      { inc(l)  }
     mov   byte ptr s+di,al        { s[l]:=c }
     jmp   @@5
@@4: inc   eol
@@5: cmp   si,cx                   { bufpos = bufanz? }
     jb    @@7
     push  ax
     mov   savebx,bx
     mov   savedi,di
     mov   bufpos,si
     mov   bufanz,cx
     push  cs
     call  reload                  { nachladen }
     mov   si,bufpos
     mov   cx,bufanz
     mov   di,savedi
     mov   bx,savebx
     pop   ax
@@7: cmp   al,10
     jnz   @@1

@@8: mov   ax,di
     mov   byte ptr s,al           { s[0]:=char(l) }
     mov   bufpos,si
   end;
{$ENDIF }
  MaxSlen:=255;
end;


procedure ReadBinString(bytesleft:longint);    { Base64-Codierung }
const b64chr : array[0..63] of char =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var   b1,b2,b3,p : byte;

  function getbyte:byte;
  begin
    if bufpos=bufanz then
      getbyte:=0
    else begin
      getbyte:=byte(buffer[bufpos]);
      inc(bufpos);
      if (bufpos=bufanz) and not eof(f1) then
        ReadBuf;
      end;
  end;

begin
  if (bytesleft>54) and (bufpos<bufanz-54) then
    asm
{$IFNDEF VER32}
      cld
      mov   si,offset buffer
      add   si,bufpos
      mov   dx,18                { 18 byte-Tripel konvertieren }
      mov   cl,2
      mov   bx,offset b64chr
      mov   di,offset s[1]
      mov   ax,ds
      mov   es,ax
 @@1: lodsb                      { Byte 1 }
      mov   ah,al
      lodsb                      { Byte 2 }
      shr   ax,1
      rcr   ch,1
      shr   ax,1
      rcr   ch,1
      xchg  al,ah
      xlat
      stosb                      { Bit 7..2/1 }
      mov   al,ch
      shr   ax,cl
      xchg  al,ah
      xlat
      stosb                      { Bit 1..0/1 + Bit 7..4/2 }
      lodsb                      { Byte 3 }
      shr   ah,cl
      shr   ah,cl
      shl   ax,cl
      xchg  al,ah
      xlat
      stosb                      { Bit 3..0/2 + Bit 7..6/3 }
      mov   al,ah
      shr   al,cl
      xlat
      stosb                      { Bit 5..0/3 }
      dec   dx
      jnz   @@1
      mov   byte ptr s[0],72
      add   bufpos,54
{$ELSE}
      cld
      mov   esi,offset buffer
      add   esi,bufpos
      mov   edx,18                { 18 byte-Tripel konvertieren }
      mov   ecx,2
      mov   ebx,offset b64chr
      mov   edi,offset s[1]
 @@1: lodsb                      { Byte 1 }
      mov   ah,al
      lodsb                      { Byte 2 }
      shr   ax,1
      rcr   ch,1
      shr   ax,1
      rcr   ch,1
      xchg  al,ah
      xlat
      stosb                      { Bit 7..2/1 }
      mov   al,ch
      shr   ax,cl
      xchg  al,ah
      xlat
      stosb                      { Bit 1..0/1 + Bit 7..4/2 }
      lodsb                      { Byte 3 }
      shr   ah,cl
      shr   ah,cl
      shl   ax,cl
      xchg  al,ah
      xlat
      stosb                      { Bit 3..0/2 + Bit 7..6/3 }
      mov   al,ah
      shr   al,cl
      xlat
      stosb                      { Bit 5..0/3 }
      dec   edx
      jnz   @@1
      mov   byte ptr s[0],72
      add   bufpos,54
{$ENDIF}
    end
  else begin
    p:=0;
    repeat
      b1:=getbyte; b2:=getbyte; b3:=getbyte;
      s[p+1]:=b64chr[b1 shr 2];
      s[p+2]:=b64chr[(b1 and 3) shl 4 + b2 shr 4];
      s[p+3]:=b64chr[(b2 and 15) shl 2 + b3 shr 6];
      s[p+4]:=b64chr[b3 and 63];
      inc(p,4); dec(bytesleft,3);
      if bytesleft<0 then begin
        s[p]:='=';
        if bytesleft<-1 then s[p-1]:='=';
        end;
    until (p>70) or (bytesleft<=0);
    s[0]:=chr(p);
    end;
end;
{$IFDEF Debug }
  {$R+}
{$ENDIF }


procedure ReadRFCheader(mail:boolean; s0:string);
const zz  : string[40] = '';    { Datensegment-optimiert }
var p,i   : integer; { 28.01.2000 robo - byte -> integer }
    s1    : string;

{    d40   : string[40]; }
    drealn: string[realnlen]; { 11.10.1999 robo - Realname verl�ngert }
    manz  : integer;      { Anzahl zus�tzliche Strings in 'smore' }

  procedure AppUline(s:string);
  begin
    if hd.ulines<maxulines then begin
      inc(hd.ulines);
      uline^[hd.ulines]:=s;
      end;
  end;

  procedure GetAdr(var adr,realname:string);
  var p,p2 : byte;
  begin
    realname:='';
    s0:=trim(s0);
    if (firstchar(s0)='"') and (cpos('<',s0)>5) then begin  { neu in 3.11 }
      p:=pos('"',mid(s0,2));

{ 23.11.1999 robo - Realname-Konvertierung: Hans \"Hanswurst\" Wurst }

      while s0[p]='\' do begin
        delete(s0,p,1);
        p:=pos('"',mid(s0,p+1))+p-1;
      end;

{ /robo }

      if p>0 then begin
{        realname:=copy(s0,2,min(40,p-1)); }
        realname:=copy(s0,2,min(realnlen,p-1));
        { 11.10.1999 robo - Realname verl�ngert }

        s0:=trim(mid(s0,p+2));
        end;
      end;                                                  { ... bis hier }
    p:=cpos('(',s0);
    p2:=cpos('<',s0);      { 06.01.1999 robo - Klammer im Realname beachten }
    if (p>0) and ((p2=0) or (p2>cpos('>',s0))) then begin { 06.01.1999 robo }
{      realname:=copy(s0,p+1,min(length(s0)-p-1,40)); }
      realname:=copy(s0,p+1,min(length(s0)-p-1,realnlen));
      { 11.10.1999 robo - Realname verl�ngert }

      s0:=trim(left(s0,min(p-1,80)));
      p:=pos('),',realname);   { mehrerer ","-getrennte Adressen }
      if p>0 then truncstr(realname,p-1);
      end;
    p:=cpos('<',s0);
    if p>0 then begin
      p2:=cpos('>',s0);
      if p2<p then adr:=copy(s0,p+1,AdrLen)
        else begin
          adr:=copy(s0,p+1,min(p2-p-1,AdrLen));
          if realname='' then
{            if p=1 then realname:=trim(copy(s0,p2+1,40)) }
{            else realname:=trim(left(s0,min(p-1,40)));   }
            if p=1 then realname:=trim(copy(s0,p2+1,realnlen))
            else realname:=trim(left(s0,min(p-1,realnlen)));
            { 11.10.1999 robo - Realname verl�ngert }

          end;
      end
    else
      adr:=left(s0,80);
    if (adr[1]='@') and (cpos(':',adr)>0) then begin
      delete(adr,1,cpos(':',adr));   { Route-Adresse nach RFC-822 aufl�sen }
      if cpos('@',adr)=0 then adr:=adr+'@nowhere';
      end;
    if (realname<>'') and (realname[1]='"') then UnQuote(realname);
  end;

  procedure GetEmpf;

{ 06.01.1999 robo - bei Mails mit mehreren Empf�ngern wurden nicht alle
  Empf�nger korrekt konvertiert }

  var p,p2 : byte;
      sto  : string;
      pk   : byte;
      _i   : integer; { 06.01.1999 robo }
      _quote : boolean; { 06.01.1999 robo }
  begin
    if not mail then
      AppUline('U-To: '+s0)
    else begin
      sto:=trim(s0);                           { 06.01.1999 robo }
      if lastchar(sto)<>',' then sto:=sto+','; { 06.01.1999 robo }
      _i:=1;                                   { 06.01.1999 robo }
      hd.empfanz:=0;
      repeat

{ 06.01.1999 robo }
{        pk:=cpos(',',sto); }

        _quote:=false;
        pk:=0;
        repeat
          inc(pk);
          if sto[pk]='"' then _quote:=not _quote;
        until ((sto[pk]=',') and not _quote) or (pk=length(sto));
{ /robo }

        s0:=trim(left(sto,pk-1));
        sto:=trim(mid(sto,pk+1));
        if cpos('@',s0)=0 then begin
          p:=length(s0);
          while (p>0) and (s0[p]<>'!') do dec(p);
          if p=0 then s0:=s0+'@'+'??'
          else begin
            p2:=p-1;
            while (p2>0) and (s0[p2]<>'!') do dec(p2);
            s0:=mid(s0,p+1)+'@'+copy(s0,p2+1,p-p2-1);
            end;
          end
        else begin
          p:=cpos('!',s0);
          if (p>0) and (p<cpos('@',s0)) then
            s0:=mid(s0,p+1);
          end;
        inc(hd.empfanz);
{        GetAdr(hd.xempf[hd.empfanz],d40); }  { hd.xempf[1]:=s0; }
        GetAdr(hd.xempf[hd.empfanz],drealn);   { hd.xempf[1]:=s0; }
        { 11.10.1999 robo - Realname verl�ngert }

        if (sto='') and (_i<=manz) then begin      { 06.01.1999 robo }
          sto:=trim(smore[_i]);                    { 06.01.1999 robo }
          if lastchar(sto)<>',' then sto:=sto+','; { 06.01.1999 robo }
          inc(_i);                                 { 06.01.1999 robo }
        end;                                       { 06.01.1999 robo }
      until (sto='') or (hd.empfanz=maxemp);       { 06.01.1999 robo }
    end;
  end;

  procedure GetFollowup;
  var p : byte;
  begin
    if mail or (cpos('@',s0)>0) then exit;
    s0:=trim(s0);
    if s0<>'' then with hd do begin
      repeat
        p:=cpos('.',s0);
        if p>0 then s0[p]:='/';     { '.' -> '/' }
      until p=0;
      if right(s0,1)<>',' then s0:=s0+',';
      while (followups<maxfollow) and (cpos(',',s0)>0) do begin
        p:=cpos(',',s0);
        if lstr(left(s0,p-1))='poster' then
          pm_reply:=true
        else if p>5 then begin
          inc(followups);
          followup[followups]:='/'+left(s0,p-1);
          end;
        s0:=trim(mid(s0,p+1));
        end;
      end;
  end;

  procedure GetNewsgroups;
  var p : byte;
      i : integer;

    procedure replslash(var s0:string);
    var p : byte;
    begin
      repeat
        p:=cpos('.',s0);
        if p>0 then s0[p]:='/';     { '.' -> '/' }
      until p=0;
    end;

  begin
    if mail then exit;
    s0:=trim(s0);
    replslash(s0);
    for i:=1 to manz do
      replslash(smore[i]);
    i:=1;
    while (s0<>'') and (hd.empfanz<maxemp) do with hd do begin
      p:=cpos(',',s0);
      if (p=0) and (i<=manz) and (smore[i][1]<>',') then begin
                  { getrennte Newsgroup wieder zusammensetzen }
        p:=cpos(',',smore[i]);
        if p=0 then p:=min(length(smore[i])+1,255);
        s0:=s0+left(smore[i],p-1);
        delete(smore[i],1,p);
        if smore[i]='' then inc(i);
        p:=0;
        end;
      if p=0 then p:=min(length(s0)+1,255);
      if p>2 then begin
        inc(empfanz);
        xempf[empfanz]:='/'+left(s0,p-1);
        end;
      s0:=trim(mid(s0,min(p+1,255)));
      if (s0='') and (i<=manz) then begin
        s0:=smore[i]; inc(i);
        end;
      end;
  end;

  procedure GetKOPs;
  var p : byte;
      s : string;
      a : string[adrlen];
{      r : string[40]; }
      r : string[realnlen]; { 11.10.1999 robo - Realname verl�ngert }
  begin
    s0:=trim(s0)+',';
    while cpos(',',s0)>0 do begin
      p:=cpos(',',s0);
      s:=trim(mid(s0,p+1));
      if p>2 then begin
        truncstr(s0,p-1);
        GetAdr(a,r);
        AppUline('KOP: '+a+iifs(r<>'',' ('+r+')',''));
        end;
      s0:=s;
      end;
  end;

  function GetMsgid:string;
  begin
    s0:=trim(s0);
    if firstchar(s0)='<' then delfirst(s0);
    if lastchar(s0)='>' then dellast(s0);
    GetMsgid:=s0;
  end;

  procedure GetRef(s0:string);
  var p : integer;
  begin
    while (s0<>'') and (s0[1]='<') do with hd do begin
      p:=cpos('>',s0);
      if p<3 then p:=length(s0)+1;
      if ref='' then
        ref:=copy(s0,2,p-2)
      else begin
        if addrefs<maxrefs then inc(addrefs)
        else FastMove(addref[2],addref[1],(maxrefs-1)*sizeof(addref[1]));
        addref[addrefs]:=copy(s0,2,p-2);
        end;
      while (p<=length(s0)) and ((s0[p+1]=' ') or (s0[p+1]=#9)) do
        inc(p);
      delete(s0,1,p);
      end;
  end;

  procedure GetReferences;
  var i,p : integer;
  begin
    if mail and (hd.ref<>'') then exit;
    i:=1;
    while (s0<>'') or (i<=manz) do begin
      if s0='' then begin
        s0:=smore[i]; inc(i);
        end;
      p:=blankpos(s0);
      while (p=0) and (s0[length(s0)]<>'>') and (i<=manz) do begin
        p:=blankpos(smore[i]);
        if p=0 then begin
          s0:=s0+smore[i]; inc(i);
          end
        else begin
          s0:=s0+left(smore[i],p-1);
          smore[i]:=trim(mid(smore[i],p+1));
          end;
        p:=blankpos(s0);
        end;
      if p=0 then p:=min(255,length(s0)+1);
      GetRef(left(s0,p));
      delete(s0,1,p);
      end;
  end;

  procedure GetInReplyto;
  var i:word; { robo }
  begin
    hd.addrefs:=0;
    if firstchar(s0)='<' then delfirst(s0);
    i:=pos('>',s0);
    if i>0 then s0:=copy (s0,1,i-1);
    hd.ref:=s0;
  end;

  procedure GetReceived;        { Mail - "Received: by" an Pfad anh�ngen }
  var by,from : string[80];

    function GetRec(key:string):string;
    var p : byte;
    begin
      p:=pos(key,lstr(s0));
      if p>0 then begin
        key:=trim(mid(s0,p+length(key)));
        p:=blankpos(key);
        if p>0 then key[0]:=chr(p-1);
        if key[length(key)]=';' then dellast(key);
        GetRec:=key;
        end
      else
        GetRec:='';
    end;

  begin
    appUline('U-'+s1);
    by:=GetRec('by ');
    from:=GetRec('from ');
    if getrecenvemp and (hd.envemp='') then hd.envemp:=GetRec('for ');
    if (by<>'') and (lstr(by)<>lstr(right(hd.pfad,length(by)))) then begin
      if hd.pfad<>'' then hd.pfad:=hd.pfad+'!';
      hd.pfad:=hd.pfad+by;
      end;
    if from<>'' then begin
      if hd.pfad<>'' then hd.pfad:=hd.pfad+'!';
      hd.pfad:=hd.pfad+from;
      end;
  end;

  procedure GetDate;
  begin
    hd.zdatum:=RFC2Zdate(s0);
    ZCtoZdatum(hd.zdatum,hd.datum);
  end;

  procedure GetBetreff(control:boolean);
  begin
    with hd do
      if control or (attrib and attrControl=0) then
        betreff:=s0;
    if control then
      hd.attrib:=hd.attrib or attrControl;
  end;

  procedure GetMime(p:mimeproc);
  begin
    AppUline('U-'+s1);
    p(s0);
  end;

  procedure GetPath;
  begin
    hd.pfad:=s0;
    if manz>0 then hd.pfad2:=smore[1]
    else hd.pfad2:='';
  end;

  procedure GetPriority;  { robo: X-Priority konvertieren }
  var p: integer;
  begin
    if hd.priority = 0 then begin  { nur ersten X-Priority Header beachten }
      p := 1;
      { nur Zahl am Anfang beachten: }
      while (s0 [p] in ['0'..'9']) and (p <= length (s0)) do inc (p);
      if p = 1 then begin
        { keine Zahl: auf urgent/high, normal, low pr�fen }
        s0 := lstr (left (s0, 3));
        { laufzeitoptimierte Abfrage: das Wahrscheinlichste zuerst }
        if s0 = 'nor' then hd.priority := 3
        else if (s0 = 'hig') or (s0 = 'urg') then hd.priority := 1
        else if s0 = 'low' then hd.priority := 5;
      end
      else begin
        { Zahl 1:1 konvertieren und auf 1..5 begrenzen }
        s0 := left (s0, p - 1);
        hd.priority := minmax (ival (s0), 1, 5);
      end;
    end;
  end;

  procedure GetProgramm;
  begin
    if hd.programm=''
      then hd.programm:=s0
      else if length(hd.programm)+length(s0)+3<=120
        then hd.programm:=hd.programm+' / '+s0;
  end;

  procedure LoZZ;      { LoString(zz);  -  zz<>'' }
  begin
    asm
{$IFNDEF Ver32}
      cld
      mov   si,offset zz
      lodsb
      mov   cl,al
      mov   ch,0
 @@1: lodsb
      cmp   al,'A'
      jb    @@2
      cmp   al,'Z'
      ja    @@2
      add   byte ptr [si-1],32
@@2:  loop  @@1
{$ELSE }
      mov ebx,offset zz
      movzx ecx,byte ptr [ebx]
      jecxz @@3
      mov edi,ecx
    @@1:
      mov al,byte ptr [ebx+edi]
      cmp al,'A'
      jnae @@2
      cmp al,'Z'
      jnbe @@2
      add byte ptr [ebx+edi],32
    @@2:
      dec edi
      jnz @@1
    @@3:
{$ENDIF }
    end;
  end;

begin
  manz:=0;
  hd.mime.ctype:=tText;   { Default: Text }
  repeat
    while eol=0 do begin
      ReadString(true);
      if (manz<maxmore) then begin
        inc(manz);
        smore[manz]:=s;
        end;
      end;
    ReadString(true);
    if (s<>'') and ((s[1]=' ') or (s[1]=#9)) then
      if (length(s0)+length(s)<254) and (manz=0) then
        s0:=trim(s0)+' '+trim(s)                { fortgesetzte Zeile }
      else if manz<maxmore then begin
        if (manz=0) or (length(smore[manz])+length(s)>253) then begin
          inc(manz);
          smore[manz]:=trim(s);
          end
        else
          smore[manz]:=smore[manz]+' '+trim(s);
        end
      else
    else with hd do begin
      p:=cpos(':',s0);
      if p>1 then begin
        s1:=s0;
        zz:=left(s0,p-1);                   { Identifier }
        inc(p);
        while (p<length(s0)) and (s0[p]<=' ') do
          inc(p);
        delete(s0,1,p-1);
        while (zz[length(zz)]=' ') do
          dec(byte(zz[0]));
        LoZZ;
        case zz[1] of
        'c': if zz='cc'           then GetKOPs else
             if zz='content-type' then getmime(GetContentType) else
             if zz='content-transfer-encoding' then getmime(GetCTencoding) else
             if zz='control'      then GetBetreff(true)
             else AppUline('U-'+s1);
        'd': if zz='date'         then GetDate {argl!} else
             if zz='distribution' then distribution:=s0
             else AppUline('U-'+s1);
        'r': if zz='references'   then GetReferences else
             if zz='received'     then GetReceived else
{             if zz='reply-to'     then GetAdr(PmReplyTo,d40) else  }
{             if zz='return-receipt-to' then GetAdr(EmpfBestTo,d40) }
             if zz='reply-to'     then GetAdr(PmReplyTo,drealn) else
             if zz='return-receipt-to' then GetAdr(EmpfBestTo,drealn)
             { 11.10.1999 robo - Realname verl�ngert }

             else AppUline('U-'+s1);
        's': if zz='subject'      then GetBetreff(false) else
{             if zz='sender'       then GetAdr(sender,d40) else }
             if zz='sender'       then GetAdr(sender,drealn) else
             { 11.10.1999 robo - Realname verl�ngert }

             if zz='supersedes'   then ersetzt:=GetMsgid else
             if zz='summary'      then summary:=s0
             else AppUline('U-'+s1);
        'x': if zz='x-gateway'    then gateway:=s0 else
             if zz='x-mailer'     then GetProgramm else
             if zz='x-newsreader' then GetProgramm else
             if zz='x-news-reader'then GetProgramm else
             if zz='x-software'   then GetProgramm else
             if zz='x-z-post'     then postanschrift:=s0 else
             if zz='x-zc-post'    then postanschrift:=s0 else
             if zz='x-z-telefon'  then telefon:=s0 else
             if zz='x-zc-telefon' then telefon:=s0 else
             if zz='x-xp-ctl'     then XPointCtl:=ival(s0) else
             if zz='x-no-archive' then begin
               if LStr(s0)='yes' then xnoarchive:=true;
             end else
             if zz='x-priority'   then GetPriority else
             if zz='x-xp-mode'    then xpmode:=s0 else
             if zz='x-homepage'   then homepage:=s0 else
             if zz='x-envelope-to'then envemp:=s0 else
             if zz='x-comment-to' then fido_to:=s0 else

             if (zz<>'xref') and (left(zz,4)<>'x-xp') then AppUline(s1);
        else if zz='from'         then GetAdr(absender,realname) else
             if zz='to'           then GetEmpf else
             if zz='message-id'   then msgid:=GetMsgid else
             if zz='organization' then organisation:=s0 else
             if zz='newsgroups'   then getnewsgroups else
             if zz='path'         then GetPath else
             if zz='mime-version' then getmime(GetMimeVersion) else
             if zz='keywords'     then keywords:=s0 else
             if zz='in-reply-to'  then GetInReplyto else
             if zz='followup-to'  then getFollowup else
             if zz='newsreader'   then GetProgramm else
             if zz='user-agent'   then GetProgramm else
             if zz='encrypted'    then pgpflags:=iif(ustr(s0)='PGP',fPGP_encoded,0) else
             if zz='priority'     then GetPriority else
             if zz='envelope-to'  then envemp:=s0 else
             if zz<>'lines'       then AppUline('U-'+s1);
        end; { case }
        end;
      s0:=s;
      manz:=0;
      end;
  until (s0='') and (lasteol or (bufpos>=bufanz));
  with hd do begin
    if (cpos('@',absender)=0) and (cpos('@',sender)>0) then
      absender:=sender;
    if absender='' then absender:=wab;
    if absender='' then absender:='Unknown@Sender';
    if ustr(wab)=ustr(absender) then
      wab:='';
    MimeIsoDecode(betreff,250);
{   MimeIsoDecode(realname,40); }
    MimeIsoDecode(realname,realnlen);
    { 11.10.1999 robo - Realname verl�ngert }

    MimeIsoDecode(summary,200);
    MimeIsoDecode(keywords,60);
    MimeIsoDecode(organisation,OrgLen);
    MimeIsoDecode(postanschrift,PostAdrLen);

{ 28.01.2000 robo }
    for i := 1 to hd.ulines do MimeIsoDecode (uline^ [i], 255);
{/robo }

 {  s:=betreff;  ISO2IBM; betreff:=s;
    s:=realname; ISO2IBM; realname:=s;
    s:=summary;  ISO2IBM; summary:=s;
    s:=keywords; ISO2IBM; keywords:=s; }
    if (empfanz=1) and (followups=1) and (xempf[1]=followup[1]) then
      followups:=0;
    MimeAuswerten;
    end;
end;


function SetMailUser(mailuser:string):string;
begin
  if (OwnSite='') or (mailuser='') then
    if cpos('@',mailuser)=0 then
      SetMailUser:=''
    else
      SetMailUser:=mailuser
  else
    if cpos('@',mailuser)=0 then
      if cpos('!',mailuser)=0 then
        SetMailUser:=mailuser+'@'+OwnSite
      else
        SetMailUser:=mid(mailuser,rightpos('!',mailuser)+1)+'@'+OwnSite
    else
      SetMailUser:=left(mailuser,cpos('@',mailuser))+OwnSite;
end;


{ UUCP-Mail -> ZCONNECT }

procedure ConvertMailfile(fn:pathstr; mailuser:string);
var p,p2  : byte;
    p3    : byte;
    i     : integer;
    fp,bp : longint;
    c     : char;
    binaer: boolean;
begin
  write('mail: ',fn);
  inc(mails);
  OpenFile(fn);
{  ok:=true; }
  fillchar(hd,sizeof(hd),0);
  if ppp then
    hd.netztyp:=nt_PPP
  else
    hd.netztyp:=nt_RFC;
  repeat             { Envelope einlesen }
    ReadString(true);
    p:=cpos(' ',s); if p=0 then p:=cpos(#9,s);
    if p=0 then p:=length(s)+1;
    c:=s[1];
    for i:=1 to p-1 do
      s[i]:=LoCase(s[i]);
    if s[p-1]<>':' then begin
      if (left(s,p-1)='from') or (left(s,p-1)='>from') then begin
        s:=trim(mid(s,p));                           { Envelope-Absender }
        p:=cpos(' ',s);
        if p>0 then begin
          hd.wab:=left(s,p-1);
          delete(s,1,p);
          p:=cpos('!',hd.wab);
          if cpos('!',hd.wab)>0 then begin
            p2:=length(hd.wab);
            while hd.wab[p2]<>'!' do dec(p2);   { rechtes "!" suchen }
            p:=p2-1;
            while (p>0) and (hd.wab[p]<>'!') do dec(p);   { n�chstes "!" suchen }
            p3:=pos('@',mid(hd.wab,p2+1));
            if p3>0 then
              if stricmp(copy(hd.wab,p2+1,p3-1)+'@'+copy(hd.wab,p+1,p2-p-1),
                         hd.absender) then
                hd.wab:=''
              else
                hd.wab:=copy(hd.wab,p2+1,p3-1)+'%'+copy(hd.wab,p+1,p2-p-1)+
                       mid(hd.wab,p2+p3)
            else
              hd.wab:=mid(hd.wab,p2+1)+'@'+copy(hd.wab,p+1,p2-p-1);
            end
          else if cpos('@',hd.wab)=0 then begin
            p:=pos('remote from',s);
            if p>0 then hd.wab:=hd.wab+'@'+mid(s,p+12)
            else hd.wab:='';   { war wohl nix }
            end;
          end;
        end;
      p:=0;
      end;
    if (eol=0) and ((p=0) or (s[p-1]<>':')) then
      ReadString(false);
  until ((p>0) and (s[p-1]=':')) or (bufpos=bufanz);
  if bufpos<bufanz then begin
    writeln(' from ',hd.wab);
    s[1]:=c;
    ReadRFCheader(true,s);
    binaer:=(hd.typ='B');
{ 28.01.2000 robo }
    if (mailuser='') and (hd.envemp<>'') then begin
      if cpos('<',hd.envemp)=1 then delete (hd.envemp,1,1);
      if (cpos('>',hd.envemp)=length(hd.envemp))
       and (length(hd.envemp)>0) then dellast(hd.envemp);
      mailuser:=SetMailuser(hd.envemp);
    end;
{ /robo }
    if (mailuser<>'') and (mailuser<>hd.xempf[1]) then begin
      hd.xoem:=hd.xempf;
      hd.oemanz:=hd.empfanz;        { Envelope-Empf�nger einsetzen }
      hd.xempf[1]:=mailuser;
      hd.empfanz:=1;
      end;
    fp:=fpos; bp:=bufpos;
    hd.groesse:=0;
    while bufpos<bufanz do begin
      ReadString(true);
      UnQuotePrintable(s,qprint,b64,eol>0);
      if not binaer then Charset2IBM;
      inc(hd.groesse,length(s));
      end;
    seek(f1,fp); ReadBuf; bufpos:=bp;
    WriteHeader;
    end
  else
    writeln;
  while bufpos<bufanz do begin
    ReadString(true);
    UnQuotePrintable(s,qprint,b64,eol>0);
    if not binaer then Charset2IBM;
    wrfs(s);
    end;
  close(f1);
  setfattr(f1,0);   { Archivbit abschalten }
end;


{ SMTP-Mail -> ZCONNECT }

procedure ConvertSmtpFile(fn:pathstr; compressed:boolean);
var f     : file;
    ende  : boolean;
    fp,bp : longint;
    n     : longint;
    rr    : word;
    p1,p2 : byte;
    mempf : string[AdrLen];
    binaer: boolean;
    nofrom: boolean;
    smtpende: boolean;

  function GetAdr:string;
  var p : byte;
  begin
    p:=cpos('<',s);
    if p=0 then GetAdr:=''
    else GetAdr:=copy(s,p+1,length(s)-p-1);
  end;

begin
  n:=0;
  write('mail: ',fn);
  if compressed then begin
    assign(f,fn);
    reset(f,1);
    s[0]:=#4;
    blockread(f,s[1],4,rr);
    close(f);
    if (left(s,2)=#$1f#$9d) or (left(s,2)=#$1f#$9f) or
       (left(s,2)=#$1f#$8b) then begin
      rename(f,fn+'.Z');
      case s[2] of
        #$9d : begin
                 write(' - uncompressing SMTP mail...');
                 shell(uncompress+fn,500);
               end;
        #$9f : begin
                 write(' - unfreezing SMTP mail...');
                 shell(unfreeze+fn,500);
               end;
        #$8b : begin
                 write(' - unzipping SMTP mail ...');
                 shell(ungzip+fn,500);
               end;
      end;
      end;
    end;
  write(sp(7));
  OpenFile(fn);
  repeat
    fillchar(hd,sizeof(hd),0);
    if ppp then
      hd.netztyp:=nt_PPP
    else
      hd.netztyp:=nt_RFC;
    ende:=false;
    repeat
      ReadString(false);
      if ustr(left(s,9))='MAIL FROM' then hd.wab:=GetAdr else      { Envelope-From }
      if ustr(left(s,7))='RCPT TO'   then hd.empfaenger:=GetAdr;   { Envelope-To }
      ende:=(bufpos>=bufanz) {or (s='QUIT')};
    until ende or (s='DATA') or (s='QUIT');
    if s='DATA' then begin
      with hd do
        if wab<>'' then begin
          p1:=cpos('@',wab);
          if p1=0 then p1:=length(wab)+1;
          p2:=cpos('!',wab);
          if ((p2>0) and (p2<p1)) then begin
            p2:=p1-1;
            wab:=left(wab,p1-1);
            while wab[p2]<>'!' do dec(p2);   { rechtes "!" suchen }
            p1:=p2-1;
            while (p1>0) and (wab[p1]<>'!') do dec(p1);
            wab:=mid(wab,p2+1)+'@'+copy(wab,p1+1,p2-p1-1);
            end;
          end;
      inc(n); inc(mails);
      write(#8#8#8#8#8,n:5);
      repeat                       { UUCP-Envelope �berlesen }
        ReadString(true);
        nofrom:=(lstr(left(s,5))<>'from ') and (lstr(left(s,5))<>'>from');
        if (eol=0) and not nofrom then
          ReadString(false);
      until nofrom;
      mempf:=SetMailUser(hd.empfaenger);
      ReadRFCheader(true,s);
      binaer:=(hd.typ='B');
      if (mempf<>'') and (mempf<>hd.xempf[1]) then begin
        hd.xoem:=hd.xempf;
        hd.oemanz:=hd.empfanz;
        hd.xempf[1]:=mempf;
        hd.empfanz:=1;
        end;
      fp:=fpos; bp:=bufpos;
      hd.groesse:=0;
      smtpende:=false;
      while (bufpos<bufanz) and not smtpende do begin   { Mailgr��e berechnen }
        ReadString(true);
        smtpende:=(s='.') and lasteol;
        if not smtpende then begin
          if (s<>'') and (s[1]='.') and lasteol then     { SMTP-'.' entfernen }
            delfirst(s);
          UnQuotePrintable(s,qprint,b64,eol>0);    { h�ngt CR/LF an, falls kein Base64 }
          if not binaer then Charset2IBM;
          inc(hd.groesse,length(s));
          end;
        end;
      seek(f1,fp); ReadBuf; bufpos:=bp;
      WriteHeader;
      smtpende:=false;
      while (bufpos<bufanz) and not smtpende do begin
        ReadString(true);
        smtpende:=(s='.') and lasteol;
        if not smtpende then begin
          if (s<>'') and (s[1]='.') and lasteol then    { SMTP-'.' entfernen }
            delfirst(s);
          UnQuotePrintable(s,qprint,b64,eol>0);    { h�ngt CR/LF an, falls kein Base64 }
          if not binaer then Charset2IBM;
          wrfs(s);
          end;
        end;
      end;
  until ende;
  close(f1);
  setfattr(f1,0);   { Archivbit abschalten }
  writeln(' - ok');
end;


function unbatch(s:string):boolean;
begin
  unbatch:=(left(s,11)='#! cunbatch') or (left(s,11)='#! funbatch') or
           (left(s,11)='#! gunbatch') or (left(s,11)='#! zunbatch');
end;


{ Newsbatch -> ZCONNECT }

procedure ConvertNewsfile(fn:pathstr);
var f       : file;
    size,ss : longint;
    fp,bp,n : longint;
    freeze  : boolean;
    gzip    : boolean;
    p       : byte;
    newfn   : pathstr;
    dir     : dirstr;
    name    : namestr;
    ext     : extstr;
    binaer  : boolean;
label ende;
begin
  write('news: ',fn);
  OpenFile(fn);
  ReadString(false);
  while unbatch(s) do begin
    freeze:=(pos('funbatch',lstr(s))>0);
    gzip:=(pos('gunbatch',lstr(s))>0) or (pos('zunbatch',lstr(s))>0);
    seek(f1,length(s)+1);
    fsplit(fn,dir,name,ext);
    if ext='' then newfn:=fn+'.Z'
    else
      if freeze then newfn:=dir+name+left(ext,2)+'XZ'
      else newfn:=dir+name+left(ext,3)+'Z';
    assign(f,newfn);
    rewrite(f,1);
    fMove(f1,f);
    close(f);
    close(f1);
    close(f2);
    if freeze then begin
      write(' - unfreezing news...');
      shell(unfreeze+newfn,500);
      end
    else if gzip then begin
      write(' - unzipping news...');
      shell(ungzip+newfn,500);
      end
    else begin
      write(' - uncompressing news...');
      shell(uncompress+newfn,500);
      end;
    reset(f2,1); seek(f2,filesize(f2));
    if exist(newfn) then begin
      writeln(' - Fehler beim Entpacken');
      assign(f,newfn); erase(f);
      exit;
      end;
    OpenFile(fn);
    ReadString(false);
    end;
  n:=0;
  if left(s,2)='#!' then
    if left(s,8)<>'#! rnews' then begin
      writeln(' - unbekanntes Batchformat');
      goto ende;
      end
    else begin
      write(sp(7));
      repeat
        while ((pos('#! rnews',s)=0) or (length(s)<10)) and
              (bufpos<bufanz) do
          ReadString(false);
        if bufpos<bufanz then begin
          p:=pos('#! rnews',s);
          if p>1 then delete(s,1,p-1);
          inc(n);
          write(#8#8#8#8#8,n:5);
          inc(news);
          size:=minmax(ival(mid(s,10)),0,maxlongint);
          fp:=fpos; bp:=bufpos;
          fillchar(hd,sizeof(hd),0);
          if ppp then
            hd.netztyp:=nt_PPP
          else
            hd.netztyp:=nt_RFC;
          ReadString(true);
          ReadRFCheader(false,s);
          binaer:=(hd.typ='B');
          seek(f1,fp); ReadBuf; bufpos:=bp;
          repeat                           { Header �berlesen }
            ReadString(true);
            dec(size,length(s)+eol);
          until (s='') and (lasteol or (bufpos>=bufanz));
          fp:=fpos; bp:=bufpos;
          ss:=size;
          while (ss>0) and (bufpos<bufanz) do begin     { Gr��e des Textes berechnen }
            MaxSlen:=ss;
            ReadString(true);
            dec(ss,length(s)+eol);
            UnQuotePrintable(s,qprint,b64,eol>0);
            if not binaer then Charset2IBM;
            inc(hd.groesse,length(s));
            end;
          WriteHeader;                     { ZC-Header erzeugen }
          seek(f1,fp); ReadBuf; bufpos:=bp;
          while (size>0) and (bufpos<bufanz) do begin    { ZC-Text anh�ngen }
            MaxSlen:=size;
            ReadString(true);
          { if length(s)+eol>size then
              s[0]:=chr(size-eol); }
            dec(size,length(s)+eol);
            UnQuotePrintable(s,qprint,b64,eol>0);
            if not binaer then Charset2IBM;
            wrfs(s);
            end;
          if bufpos<bufanz then
            ReadString(false);
          end;
      until (bufpos>=bufanz{-8}) or (s='');
      writeln(' - ok');
      end;
ende:
  close(f1);
  setfattr(f1,0);   { Archivbit abschalten }
  if n=0 then writeln;
end;


procedure UtoZ;
var sr    : searchrec;
    spath : pathstr;
    s     : string;
    typ   : string[10];   { 'mail' / 'news'   }
    dfile : string[12];   { Name des D.-files }
    p     : byte;
    n     : longint;
    mailuser: string[60];

  procedure GetStr;   { eine Textzeile aus X.-File einlesen }
  var c : char;
  begin
    s:='';
    repeat
      blockread(f1,c,1);
      if (c=#9) or (c>=' ') then s:=s+c;
    until (c=#10) or eof(f1);
  end;

  function U2DOSfile(s:string):string;
  var i : integer;
      b : byte;
  begin
    s:=s[1]+'-'+right(s,5);
    b:=0;
    for i:=0 to 3 do            { Schreibweise in einem Byte codieren }
      if (s[i+4]>='A') and (s[i+4]<='Z') then
        inc(b,1 shl i);
    U2DOSfile:=s+hex(b,1);
  end;

  procedure ReadXfile;
  begin
    assign(f1,spath+sr.name);
    reset(f1,1);
    typ:=''; dfile:='';
    mailuser:='';
    while not eof(f1) do begin
      GetStr;
      if s<>'' then
        case UpCase(s[1]) of
          'C' : if typ='' then begin    { Befehl: 'rmail' / 'rnews' / 'rsmtp' }
                  s:=trim(mid(s,2));
                  p:=blankpos(s);
                  if p>0 then begin
                    typ:=left(s,p-1); mailuser:=trim(mid(s,p+1));
                    p:=blankpos(mailuser);
                    if p>0 then truncstr(mailuser,p-1);
                    end
                  else typ:=s;
                end;
          'F' : if dfile='' then begin  { zugeh�riges Datenfile }
                  s:=trim(mid(s,2));
                  dfile:=U2DOSfile(s);
                end;
        end;
      end;
    close(f1);
  end;

  function FileType:shortint;
  var f  : file;
      s  : string[12];
      rr : word;
  begin
    assign(f,spath+sr.name);
    reset(f,1);
    blockread(f,s[1],12,rr);
    close(f);
    s[0]:=chr(rr);
    if left(s,8)='#! rnews' then
      FileType:=1
    else if unbatch(s) then       { '#! cunbatch' / '#! funbatch' }
      FileType:=2
    else if left(ustr(s),5)='HELO ' then
      FileType:=3
    else if left(lstr(s),5)='from ' then
      FileType:=4
{ 28.01.2000 robo - Bugfix }
{    else if left(lstr(s),6)='>From ' then }
    else if left(lstr(s),6)='>from ' then
{ /robo }
      FileType:=4
    else
      FileType:=0;
  end;

begin
  assign(f2,dest);
  {rewrite(f2,1);}
  if exist(dest) then begin
    reset(f2,1);
    seek(f2,filesize(f2));
  end
  else rewrite(f2,1);
  outbufpos:=0;
  spath:=GetFileDir(source);
  n:=0;
  findfirst(source,archive,sr);
  while doserror=0 do begin
    if left(sr.name,2)='X-' then begin
      ReadXFile;                          { X.-file interpretieren }
      LoString(typ);
      if exist(spath+dfile) then begin
        inc(n);
        if (typ='rnews') or (typ='crnews') or
           (typ='frnews') or (typ='grnews') then
          ConvertNewsfile(spath+dfile)
        else if typ='rmail' then ConvertMailfile(spath+dfile,SetMailuser(mailuser))
        else if (typ='rsmtp') or (typ='crsmtp') or (typ='rcsmtp') or
                (typ='frsmtp') or (typ='rfsmtp') or
                (typ='rzsmtp') or (typ='zrsmtp') or
                (typ='rgsmtp') or (typ='grsmtp') then
          ConvertSmtpFile(spath+dfile,typ<>'rsmtp');
      end;
    end
    else begin
      inc(n);
      case FileType of
        1,2 : ConvertNewsfile(spath+sr.name);
        3   : ConvertSmtpFile(spath+sr.name,false);
        4   : ConvertMailfile(spath+sr.name,'');
      else
        dec(n);
      end;
    end;
    findnext(sr);
  end;
{$ifdef ver32}
  findclose(sr);
{$endif}
  if n>0 then writeln;
  writeln('Mails:',mails:6);
  writeln('News :',news:6);
  flushoutbuf;
  close(f2);
end;


{ --- ZConnect -> UUCP/RFC ------------------------------------------ }

{$I xpfiles.inc}    { Unix2DOSfile }


function NextUunumber:word;
begin
  NextUunumber:=uunumber;
  if uunumber=65535 then uunumber:=0
  else inc(uunumber);
end;


procedure wrs(var f:file; s:string);
begin
  if length(s)>254 then s[0]:=#254;
  s:=s+#10;
  blockwrite(f,s[1],length(s));
end;

procedure wrs_nolf(var f:file; s:string);
begin
  blockwrite(f,s[1],length(s));
end;


procedure WriteRFCheader(var f:file; mail:boolean);
const smtpfirst : boolean = true;
var dat    : string[30];
    p      : byte;
    s,
    rfor   : string;
    first  : boolean;
    i      : integer;
    j      : integer; { 24.09.1999 robo }
    xdate  : boolean;
    ep     : empfnodep;

  procedure wrref;
  begin
    if first then begin
      wrs(f,'References: '+s);
      first:=false;
    end
    else
      wrs(f,#9+s);
    s:='';
  end;

  procedure WrLongline(txt:string; var ss:string);
  var p,r,ml : byte;
  begin
    IBM2ISO(ss);
    ml:=iif(rfc1522,60,78);
    r:=ml+1-length(txt);
    while length(ss)>r do begin
      p:=r;
      while (p>0) and (ss[p]<>' ') do dec(p);
      if p<2 then begin
        p:=r+1;
        while (p<=length(ss)) and (ss[p]<>' ') do inc(p);
      end;
      if ss[p]=' ' then dec(p);
      uuz.s:=left(ss,p);
      RFC1522form;
      wrs(f,txt+uuz.s);
      ss:=trim(mid(ss,p+1));
      txt:=#9; r:=ml;
    end;
    if ss<>'' then begin
      uuz.s:=ss;
      RFC1522form;
      wrs(f,txt+uuz.s);
    end;
  end;

  function month(m:string):string;
  begin
    month:=copy('Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ',
                ival(m)*4-3,4);
  end;

  function ZtoRFCdate(date,zdate:string):string;
  var p : byte;
  begin
    p:=cpos(':',zdate);
    if p=0 then p:=length(zdate)+1;
    ZtoRFCdate:=copy(date,5,2)+' '+month(copy(date,3,2))+left(zdate,2)+
         left(date,2)+' '+copy(date,7,2)+':'+copy(date,9,2)+':'+
         copy(zdate,13,2)+' '+zdate[16]+formi(ival(copy(zdate,17,p-17)),2)+
         formi(ival(mid(zdate,p+1)),2);
  end;

  function formnews(s:string):string;
  var p : byte;
  begin
    if s[1]='/' then delfirst(s);
    repeat
      p:=cpos('/',s);
      if p>0 then s[p]:='.';
    until p=0;

{ 03.09.1999 robo - bei Netztyp RFC Gruppennamen nicht nach }
{ lowercase wandeln wegen Macrosuff-Schrottnewsservern }

    if hd.netztyp in [nt_RFC, nt_PPP]
      then formnews:=s
      else

{ /robo }

    formnews:=lstr(s);
  end;

  procedure WriteNewsgroups;   { Newsgroups nicht folden! }
  var s : string;
      p : empfnodep;
  begin
    s:='Newsgroups: '+formnews(hd.empfaenger);
    wrs_nolf(f,s);
    while empflist<>nil do begin
      s:=','+formnews(empflist^.empf);
      wrs_nolf(f,s);
      p:=empflist^.next;
      dispose(empflist);
      empflist:=p;
    end;
    wrs(f,'');
  end;

  function maintype(ctype:byte):string;
  begin
    case ctype of
      tText        : maintype:='text';
      tApplication : maintype:='application';
      tImage       : maintype:='image';
      tMessage     : maintype:='message';
      tMultipart   : maintype:='multipart';
      tAudio       : maintype:='audio';
      tVideo       : maintype:='video';
      tModel       : maintype:='model';
      else           maintype:='application';
    end;
  end;


begin
  with hd do begin
    dat:=ZtoRFCdate(datum,zdatum);
    if mail then begin
      if wab='' then s:=absender          { Envelope erzeugen }
      else s:=wab;
      p:=cpos('@',s);
      if SMTP then begin
        if smtpfirst or ppp then begin
          wrs(f,'HELO '+mid(s,p+1));
          smtpfirst:=false;
        end;
        wrs(f,'MAIL FROM:<'+s+'>');
        wrs(f,'RCPT TO:<'+hd.empfaenger+'>');
        ep:=empflist;
        while ep<>nil do begin
          wrs(f,'RCPT TO:<'+ep^.empf+'>');
          ep:=ep^.next;
        end;
        wrs(f,'DATA');
      end
      else
        wrs(f,'From '+left(s,p-1)+' '+dat+' remote from '+mid(s,p+1));
      if (wab<>'') and (cpos('@',oem)>0) and not smtp   { (*1) - s.u. }
        then rfor:=empfaenger
        else rfor:='';
      wrs(f,'Received: by '+mid(s,cpos('@',s)+1)+
            iifs(programm<>'',' ('+programm+')','')+
            iifs(rfor<>'',#10#9'  for '+rfor+';',';'));
      wrs(f,#9'  '+left(date,2)+' '+month(copy(date,4,2))+right(date,4)+' '+
            time+' '+right(dat,5));   { akt. Datum/Uhrzeit }
    end
    else
      wrs(f,'Path: '+addpath+pfad);
    wrs(f,'Date: '+dat);
    uuz.s:=realname;
    IBM2ISO(uuz.s);
    RFC1522form;
    if AbsNSStyle
     then wrs(f,'From: '+iifs(uuz.s<>'',uuz.s+' <'+absender+'>',absender))
     else wrs(f,'From: '+absender+iifs(uuz.s<>'',' ('+uuz.s+')',''));
    if wab<>'' then begin
      uuz.s:=war;
      IBM2ISO(uuz.s);
      RFC1522form;
      if AbsNSStyle
       then wrs(f,'Sender: '+iifs(uuz.s<>'',uuz.s+' <'+wab+'>',wab))
       else wrs(f,'Sender: '+wab+iifs(uuz.s<>'',' ('+uuz.s+')',''));
    end;
    if mail then begin
      if (wab<>'') and (cpos('@',oem)>0)   { s. (*1) }
        then wrs(f,'To: '+oem)
        else wrs(f,'To: '+empfaenger);
      while empflist<>nil do begin
        if not nokop then
          wrs(f,'cc: '+empflist^.empf);
        ep:=empflist^.next;
        dispose(empflist);
        empflist:=ep;
      end;
    end
    else
      WriteNewsgroups;
    wrs(f,'Message-ID: <'+msgid+'>');
    if ersetzt<>'' then wrs(f,'Supersedes: <'+ersetzt+'>');
    if ref<>'' then
      if mail and (attrib and attrPmReply=0) then

{ 14.01.2000 robo - BEZ bei Strg-B Antworten in Mailinglisten. }

      begin
        if addrefs>0 then ref:=addref[addrefs]; { neu }
        wrs(f,'In-Reply-To: <'+ref+'>');
      end
      else begin

{ /robo }

{ 03.09.1999 robo - References einigermassen RFC-konform k�rzen }

        repeat
          j:=12+length(ref)+2;
          for i:=1 to addrefs do j:=j+length(addref[i])+3;
          if j>980 then begin
            FastMove(addref[2],addref[1],(maxrefs-1)*sizeof(addref[1]));
            dec(addrefs);
          end;
        until j<=980;

{ /robo }

        first:=true;
        s:='<'+ref+'>';
        for i:=1 to addrefs do begin
          if length(s)+length(addref[i])>iif(first,60,70) then
            wrref;
          if s='' then s:='<'+addref[i]+'>'
          else s:=s+' <'+addref[i]+'>';
        end;
        if s<>'' then wrref;
      end;
    if attrib and attrControl<>0 then
      wrs(f,'Control: '+betreff);
    if mail and (lstr(betreff)='<none>') then
      betreff:='';
    uuz.s:=betreff;
    IBM2ISO(uuz.s);
    RFC1522form;
    wrs(f,'Subject: '+uuz.s);
    if keywords<>'' then begin
      uuz.s:=keywords;
      IBM2ISO(uuz.s);
      RFC1522form;
      wrs(f,'Keywords: '+uuz.s);
    end;
    if summary<>'' then
      WrLongline('Summary: ',summary);

    if not nomailer and (programm<>'') then
    begin
      if mail then
        wrs(f,'X-Mailer: ' + programm)
      else
        wrs(f,'X-Newsreader: ' + programm);
    end;
    if xnoarchive then wrs(f,'X-No-Archive: yes');
    if priority<>0 then wrs(f,'X-Priority: '+strs(priority));
    if not NoMIME and
    (mail or (NewsMIME and (x_charset<>'')) or (attrib and AttrMPbin<>0)) then
    with mime do begin
      wrs(f,'MIME-Version: '+mversion);
      s:=maintype(ctype)+'/'+subtype;
      datei:=trim(datei);
      QuoteStr(datei,true);
      case ctype of
        tText        : s:=s+'; charset='+charset;
        tApplication : if datei<>''  then s:=s+'; name='+datei;
        { 03.02.2000 robo }
        tMultipart   : s:=s+'; boundary="'+xpboundary+'"'
                          +iifs(mimereltyp='','','; type="'+mimereltyp+'"');
        { /robo }
        else           if datei<>''  then s:=s+'; x-filename='+datei;
      end;
      xdate:=(typ='B') and (ddatum<>'') and (attrib and AttrMPbin=0);
      if xdate then s:=s+';';
      wrs(f,'Content-Type: '+s);
      if xdate then
        wrs(f,#9'      x-date="'+ZtoRFCdate(copy(ddatum,3,10),ddatum+'W+0')+'"');
      case encoding of
        enc7bit   : s:='7bit';
        enc8bit   : s:='8bit';
        encQP     : s:='quoted-printable';
        encBase64 : s:='base64';
        encBinary : s:='binary';
      end;
      if s<>'7bit' then
        wrs(f,'Content-Transfer-Encoding: '+s);
    end;

    if not mail and (distribution<>'') then
      wrs(f,'Distribution: '+distribution);
    if organisation<>'' then begin
      uuz.s:=organisation;
      IBM2ISO(uuz.s);
      RFC1522form;
      wrs(f,'Organization: '+uuz.s);
    end;
    if PmReplyTo<>'' then
      wrs(f,'Reply-To: '+pmreplyto);
    if pm_reply then
      wrs(f,'Followup-To: poster')
    else
      if not mail and (AmReplyTo<>'') then
        wrs(f,'Followup-To: '+formnews(AmReplyTo));
    if mail and (attrib and attrReqEB<>0) then
      wrs(f,'Return-Receipt-To: '+iifs(empfbestto<>'',empfbestto,
            iifs(wab<>'',wab,iifs(pmReplyTo='',absender,pmReplyTo))));
    if mail and (pgpflags and fPGP_encoded<>0) then
      wrs(f,'Encrypted: PGP');
    if homepage<>'' then
      wrs(f,'X-Homepage: '+homepage);
    if XPointCtl<>0 then
      wrs(f,'X-XP-Ctl: '+strs(XPointCtl));
    if fido_to<>'' then
      wrs(f,'X-Comment-To: '+fido_to);
    for i:=1 to ulines do begin
      uuz.s:=uline^[i];
      IBM2ISO(uuz.s);
      RFC1522form;
      wrs(f,uuz.s);
    end;
    if not mail then
      wrs(f,'Lines: '+strs(lines+iif(attrib and AttrMPbin<>0,16,0)));
    for i:=1 to addhds do
      if mail=addhdmail[i] then
        wrs(f,addhd[i]);
    wrs(f,'');
    if attrib and AttrMPbin<>0 then begin
      { Anzahl der Zeilen incl. Trailer oben bei Lines einsetzen! }
      wrs(f,'--'+xpboundary);
      wrs(f,'Content-Type: text/plain');
      wrs(f,'');
      wrs(f,'Diese Nachricht enthaelt eine MIME-codierte Binaerdatei. Falls Ihr');
      wrs(f,'Mailer die Datei nicht decodieren kann, verwenden Sie dafuer bitte');
      wrs(f,'ein Tool wie ''munpack'' oder ''udec''.');
      wrs(f,'');
      wrs(f,'This message contains a MIME encoded binary file. If your mailer');
      wrs(f,'cannot decode the file, please use a decoding tool like ''munpack''.');
      wrs(f,'');
      wrs(f,'--'+xpboundary);
      GetBinType(datei);
      wrs(f,'Content-Type: '+maintype(mime.ctype)+'/'+mime.subtype+
            iifs(datei<>'','; name="'+datei+'"','')+
            iifs(ddatum<>'',';',''));
      if ddatum<>'' then wrs(f,#9'      x-date="'+ZtoRFCdate(copy(ddatum,3,10),ddatum+'W+0')+'"');
      wrs(f,'Content-Transfer-Encoding: base64');
      wrs(f,'');
    end;
  end;
end;


procedure WriteRfcTrailer(var f : file);
begin
  if hd.attrib and AttrMPbin <>0 then
    wrs(f,'--'+xpboundary+'--');
end;


procedure ZtoU;
var hds,adr : longint;
    fs,n,gs : longint;
    ok      : boolean;
    f       : file;
    fn      : string[12];
    fc      : text;
    server  : string[80];   { Adresse UUCP-Fileserver }
    files   : longint;
    binmail : boolean;
    copycount : integer;    { f�r Mail-'CrossPostings' }
    ldstr   : string[2];
    ovrwrt  : boolean;

  procedure FlushOutbuf(var f:file);
  begin
    if outbufpos>0 then
      blockwrite(f,outbuf^,outbufpos);
    outbufpos:=0;
  end;

  procedure wrbuf(var f:file);
  begin
    if length(s)<255 then inc(byte(s[0]));
    s[length(s)]:=#10;
    if outbufpos+length(s)>=outbufsize then
      FlushOutbuf(f);
    FastMove(s[1],outbuf^[outbufpos],length(s));
    inc(outbufpos,length(s));
  end;

  procedure MakeXfile(sender:string);
  var name,name2 : string[14];
      mail,smtp  : boolean;
      nr         : string[4];
      fs         : longint;
  begin
    mail:=(sender='mail');
    smtp:=(sender='smtp');
    nr:=hex(NextUunumber,4);
    assign(f2,dest+'X-'+nr+'.OUT');
    rewrite(f2,1);
    if mail or smtp then wrs(f2,'U '+MailUser+' '+_from)
    else wrs(f2,'U '+NewsUser+' '+_from);
    name:=fn[1]+'.'+left(_from,7)+iifc(mail or smtp,'C','d')+right(fn,4);
    wrs(f2,'F '+name);
    wrs(f2,'I '+name);
    if smtp and csmtp then
      wrs(f2,'C rcsmtp')
    else if smtp and fsmtp then
      wrs(f2,'C rfsmtp')
    else if smtp and zsmtp then
      wrs(f2,'C rgsmtp')
    else
      wrs(f2,'C r'+sender+iifs(mail,' '+hd.empfaenger,''));
    fs:=filesize(f2);
    close(f2);
    name2:=fn[1]+'.'+left(_to,7)+'D'+right(fn,4);
    write(fc,'S ',name2,' ',name,' ',iifs(mail or smtp,MailUser,NewsUser),
             ' - ',name2,' 0666');
    if ParSize then writeln(fc,' "" ',_filesize(dest+fn+'.OUT'))
    else writeln(fc);
    name2:='D.'+left(_to,7)+'X'+nr;
    write(fc,'S ',name2,' X.',left(_from,7),iifc(mail or smtp,'C','d'),nr,' ',
             iifs(mail or smtp,MailUser,NewsUser),' - ',name2,' 0666');
    if ParSize then writeln(fc,' "" ',fs)
    else writeln(fc);
  end;

  procedure WrFileserver;
  var p        : byte;
      fromfile : string;
      tofile   : string[40];
      request  : boolean;
      transfer : boolean;
      tfiles   : integer;

    function slashs(fn:pathstr):pathstr;
    var i : byte;
    begin
      for i:=1 to length(fn) do
        if fn[i]='\' then fn[i]:='/';
      slashs:=fn;
    end;

    procedure WriteTransfer(s:string);
    begin
      writeln(fc,'S ',slashs(fromfile),' ',s,' ',FileUser,' - ',
              getfilename(fromfile),' 0666' +
              iifs(ParSize,' "" '+strs(_filesize(fromfile)),''));
    end;

  begin
    request:=(ustr(hd.betreff)='REQUEST');
    transfer:=(hd.attrib and attrFile)<>0;
    if transfer then begin
      fromfile:=hd.betreff;
      if not exist(fromfile) then begin
        writeln(' warning: ',fromfile,' not found!');
        exit;
        end;
      tfiles:=0;
      end;
    seek(f1,adr+hds);
    ReadBuf;
    while fpos+bufpos<adr+hds+hd.groesse do begin
      ReadString(false);
      s:=trim(s);
      if (s<>'') and (s[1]<>'#') then begin
        if request then begin
          p:=blankpos(s);
          if p=0 then begin
            fromfile:=s;
            tofile:=Unix2DOSfile(s,'');
            end
          else begin
            fromfile:=left(s,p-1);
            tofile:=trim(mid(s,p+1));
            end;
          writeln(fc,'R ',fromfile,' ',tofile,' ',FileUser,' -');
          end
        else begin
          WriteTransfer(s);
          inc(tfiles);
          end;
        inc(files);
        end;
      end;
    if transfer and (tfiles=0) then
      WriteTransfer(lstr(getfilename(fromfile)));
  end;

  { String abk�rzen, falls Zeile nicht mit CR/LF beendet }
  { und nachfolgendes EMP: angeh�ngt wurde               }

  procedure ShortS;
  begin
    s:=left(s,max(0,integer(length(s))-(fpos+bufpos-gs)+2));
  end;

  procedure CreateNewfile;
  begin
    repeat
      fn:=ldstr+hex(NextUunumber,4);
    until not exist(dest+fn+'.OUT') or ovrwrt;
    assign(f2,dest+fn+'.OUT');
    rewrite(f2,1);
  end;

begin
  assign(f1,source);
  reset(f1,1);
  adr:=0; n:=0;
  if not ppp then begin
    assign(fc,dest+'C-'+hex(NextUunumber,4)+'.OUT');   { "C."-File }
    rewrite(fc);
  end;
  if filesize(f1)<10 then begin
    close(f1);
    if not ppp then close(fc);
    exit;
  end;
  assign(f,'uuz.tmp');
  rewrite(f,1);
  server:=ustr(UUserver+'@'+_to);
  files:=0;

  ldstr:=iifs(ppp,'N','D-');
  ovrwrt:=iifb(ppp,false,true);

  if not ppp then CreateNewfile;           { 1. Durchgang: News }
  fs:=filesize(f1);
  repeat
    seek(f1,adr);
    empflist:=nil;
    makeheader(true,f1,1,0,hds,hd,ok,false);
    if not ok then begin
      close(f1);
      error('fehlerhafter Eingabepuffer!');
    end;
    binmail:=(hd.typ<>'T');
    if cpos('@',hd.empfaenger)=0 then      { AM }
      if binmail and not NewsMIME then
        writeln(#13'Bin�rnachricht <',hd.msgid,'> wird nicht konvertiert')
      else begin   { AM }
        inc(n); write(#13'News: ',n);
        if ppp then CreateNewFile;
        seek(f1,adr+hds);
        if binmail then
          hd.lines:=(hd.groesse+53) div 54    { Anzahl Base64-Zeilen }
        else begin
          ReadBuf;                            { Zeilen z�hlen }
          while fpos+bufpos<adr+hds+hd.groesse do begin
            ReadString(true);
            inc(hd.lines);
          end;
        end;
        SetMimeData;
        seek(f,0);
        WriteRFCheader(f,false);
        seek(f1,adr+hds);   { Text kopieren }
        ReadBuf;
        gs:=adr+hds+hd.groesse;
        outbufpos:=0;
        if binmail then
          while fpos+bufpos<gs do begin
            ReadBinString(gs-fpos-bufpos);
            wrbuf(f);
          end
        else
          while fpos+bufpos<gs do begin
            ReadString(true);
            if fpos+bufpos>gs then ShortS;
            IBM2ISO(uuz.s);
            if NewsMIME then MakeQuotedPrintable;
            wrbuf(f);
          end;
        flushoutbuf(f);
        WriteRfcTrailer(f);
        truncate(f);
        if not ppp then wrs(f2,'#! rnews '+strs(filesize(f)));
        seek(f,0);
        fmove(f,f2);
        if ppp then close(f2);
      end;
    disposeempflist(empflist);
    inc(adr,hds+hd.groesse);
  until adr>fs-10;
  empflist:=nil;
  if not ppp then close(f2);
  if n=0 then begin
    if not ppp then erase(f2);
  end
  else begin
    if not ppp then MakeXfile('news');
    writeln;
  end;
  close(f); erase(f);

  adr:=0; n:=0;                     { 2. Durchgang: Mail }

  ldstr:=iifs(ppp,'M','D-');

  if SMTP and not ppp then CreateNewfile;
  repeat
    copycount:=1;
    repeat
      seek(f1,adr);
      makeheader(true,f1,copycount,0,hds,hd,ok,false);
      binmail:=(hd.typ='B');
      if cpos('@',hd.empfaenger)>0 then
        if ustr(left(hd.empfaenger,length(server)))=server then begin
          if not ppp then WrFileserver;
        end
        else begin
          inc(n); write(#13'Mails: ',n);
          if not SMTP or ppp then
            CreateNewfile;
          if binmail then
            seek(f1,adr+hds);
          SetMimeData;
          WriteRFCheader(f2,true);
          seek(f1,adr+hds);   { Text kopieren }
          ReadBuf;
          gs:=adr+hds+hd.groesse;
          outbufpos:=0;
          if binmail then
            while fpos+bufpos<gs do begin
              ReadBinString(gs-fpos-bufpos);
              wrbuf(f2);
            end
          else
            while fpos+bufpos<gs do begin
              ReadString(true);
              if fpos+bufpos>gs then ShortS;
              if SMTP and (s<>'') and (s[1]='.') then s:='.'+s;
              IBM2ISO(uuz.s);
              MakeQuotedPrintable;
              wrbuf(f2);
            end;
          flushoutbuf(f2);
          WriteRfcTrailer(f2);
          if SMTP then begin
            wrs(f2,'.');          { Ende der Mail }
            if ppp then begin
              wrs(f2,'QUIT');
              close(f2);
            end;
          end
          else begin
            close(f2);
            if not ppp then MakeXfile('mail');
          end;
        end;
      disposeempflist(empflist);
      if SMTP then copycount:=hd.empfanz;
      inc(copycount);
    until copycount>hd.empfanz;
    inc(adr,hds+hd.groesse);
  until adr>fs-10;
  if n>0 then writeln;
  if files>0 then
    writeln('Files: ',files);
  if SMTP and not ppp then begin
    wrs(f2,'QUIT');
    close(f2);
    if n=0 then erase(f2)
    else if not ppp then MakeXfile('smtp');
  end;
  close(f1);
  if not ppp then close(fc);
end;


procedure SetWindow;
var y : byte;
begin
  y:=wherey;
  close(output); assigncrt(output); rewrite(output);
  window(1,4,80,xpwindow-2);
  gotoxy(1,y-3);
end;



begin
  logo;
  initvar;
  getpar;
  testfiles;
  if XpWindow>0 then SetWindow;
  if u2z then UtoZ
  else ZtoU;
  donevar;
end.

{
  $Log: uuz.pas,v $
  Revision 1.52  2002/04/18 23:36:59  rb
  Unterst�tzung f�r IANA-Charset-Aliase

  Revision 1.51  2002/04/17 21:34:58  rb
  Betreff outgoing verl�ngert

  Revision 1.50  2002/03/08 17:42:27  rb
  Neue Zeichens�tze: ISO-8859-15, Windows-1252

  Revision 1.49  2002/03/08 14:34:04  rb
  Unfolding-Bug behoben (2 Leerzeichen bei umgebrochenem Subject)

  Revision 1.48  2002/02/26 00:58:06  rb
  - RFC152Form kodiert jetzt nicht mehr den ganzen String, sondern nur noch
    den Teil vom ersten bis zum letzten Wort, in dem ein Zeichen vorkommt,
    das kodiert werden muss.

  Revision 1.47  2002/02/20 19:56:03  rb
  - MimeIsoDecode auch f�r andere Zeichens�tze
  - Iso1ToIBM und IBMToIso1 nach mimedec.pas verlagert
  - text/html wird von UUZ nicht mehr nach IBM konvertiert

  Revision 1.46  2002/02/15 22:02:07  rb
  - einige Zeichenkonvertier- und Dekodierroutinen in neue Unit ausgelagert
  - RFC1522-Dekodierung f�r Dateinamen von Attachments

  Revision 1.45  2002/02/08 15:17:49  rb
  Log

  Revision 1.44  2002/02/08 15:12:48  rb
  Fix aus 1.42 ge�ndert (Max, ich hatte dir das doch per Mail geschrieben!)

  Revision 1.43  2002/01/14 08:48:06  mm
  Textnachrichten wurden unter Umstaenden als Binaer-Nachrichten erkannt
  (z.B. wenn Transfer-Encoding = Base64 aber Conetent-Type = Text/Plain)

  Revision 1.42  2001/12/03 18:35:59  MH
  - Fix: Kaputte RefZeilen (Robo: Sonst wird das wieder vergessen) f�hren
         zum Absturz

  Revision 1.41  2001/07/23 20:44:15  rb
  bei -uz Schalter f�r Boxname

  Revision 1.40  2001/06/26 18:35:40  rb
  Unabgesprochene �nderung zur�ckgenommen

  Revision 1.39  2001/06/26 14:53:12  tg
  GMT-Fix bei Erstellungszeit 00:00

  Revision 1.38  2001/06/18 20:17:22  oh
  Teames -> Teams

  Revision 1.37  2001/02/16 20:13:02  rb
  QP-Kodierungs-Bug bei Leerzeichen am Zeilenende behoben

  Revision 1.36  2001/01/18 19:05:56  rb
  Multipart-Bin�r-Bugfix

  Revision 1.35  2000/11/27 18:39:40  rb
  GetMsgid toleranter gemacht

  Revision 1.34  2000/10/13 22:38:04  rb
  UTF-7 Support

  Revision 1.33  2000/10/13 14:00:19  MH
  Replace:
  - Wir verabschieden uns von X-XP-MSG und setzen nun die Datenbank ein

  Revision 1.32  2000/10/11 21:25:01  MH
  XP-MSG: MyMail...hinzugef�gt

  Revision 1.31  2000/10/11 21:09:36  rb
  Multipart wird jetzt auch bei 8 Bit Kodierung korrekt behandelt

  Revision 1.30  2000/10/08 23:58:49  rb
  Wenn kein charset im Header steht, wird jetzt wieder standardm��ig
  eine ISO-to-IBM-Dekodierung gemacht, weil dieses Drecks-Outlook keinen
  entsprechenden Header setzt. Grmbls.

  Revision 1.29  2000/10/08 16:20:16  rb
  UTF-8 Support incoming f�r Latin-1

  Revision 1.28  2000/10/07 00:55:18  rb
  Mailerstring auf 120 Zeichen verl�ngert

  Revision 1.27  2000/10/05 16:45:30  rb
  F�r 'Mailer' werden jetzt die entsprechenden RFC-Header zusammengef�gt

  Revision 1.26  2000/09/28 22:17:57  rb
  Patch von Frank Ellert f�r fido_to komplettiert

  Revision 1.25  2000/09/19 20:01:25  rb
  X-Envelope-To Unterst�tzung, QP-Decode f�r Post-Header

  Revision 1.24  2000/09/15 20:22:48  rb
  lange Zeilen werden jetzt korrekt konvertiert und nicht mehr umgebrochen

  Revision 1.23  2000/09/15 11:19:10  rb
  Auch bei batched SMTP werden Zeilen mit einer L�nge von mehr als
  255 Zeichen jetzt "zwangsumgebrochen" und nicht mehr abgeschnitten.

  Revision 1.22  2000/08/25 20:30:50  rb
  Unterst�tzung f�r X-XP-MODE eingebaut

  Revision 1.21  2000/08/18 20:48:11  rb
  Assemblerroutine nach 32 Bit portiert

  Revision 1.20  2000/07/18 20:05:12  rb
  Supersedes - outgoing

  Revision 1.19  2000/07/10 22:53:38  rb
  Update f�r XP-Boundary

  Revision 1.18  2000/07/05 21:44:52  MH
  Mailerzeile:
  - auf 66 Zeichen (in/out) verl�ngert
  - mit (XP2) gekennzeichnet

  Revision 1.17  2000/06/22 07:42:04  MH
  RFC/PPP: Puffer-Append-Funktion f�r eingehende Msg

  Revision 1.16  2000/06/21 20:31:51  rb
  Envelope-To:-Unterst�tzung

  Revision 1.15  2000/06/16 19:30:02  rb
  Bugfix f�r fortgesetzte Headerzeilen

  Revision 1.14  2000/06/06 21:31:35  rb
  nt_PPP und Gro�-/Kleinschreibung der Newsgroups

  Revision 1.13  2000/05/31 22:34:28  rb
  Bugfix f�r supersedes/ersetzt

  Revision 1.12  2000/05/31 19:59:04  rb
  Torstens Provisorien sauber portiert

  Revision 1.11  2000/05/31 15:14:47  tj
  Funktion AddCrLf fuer Ver32 provisorisch eingepflanzt

  Revision 1.10  2000/05/29 22:10:57  tj
  fehlende 32bit Routine (ein Befehl) reingepflanzt

  Revision 1.9  2000/05/18 21:12:03  rb
  UUZ Erweiterungen f�r Boxtyp PPP

  Revision 1.8  2000/05/09 22:00:23  rb
  Absender kann jetzt auch im Netscape-Stil geschrieben werden, siehe change.log

  Revision 1.7  2000/05/09 21:21:07  rb
  X-No-Archive, X-Priority, X-Homepage -> U-X-...

  Revision 1.6  2000/05/03 21:27:43  rb
  supersedes-konvertier-Bug gefixt

  Revision 1.5  2000/04/18 23:29:10  rb
  MIME-ISO-Decode-Bug gefixt

  Revision 1.4  2000/04/09 18:16:17  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.16  2000/04/04 21:01:22  mk
  - Bugfixes f�r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.15  2000/03/25 18:46:59  ml
  uuz lauff�hig unter linux

  Revision 1.14  2000/03/24 15:41:01  mk
  - FPC Spezifische Liste der benutzten ASM-Register eingeklammert

  Revision 1.13  2000/03/17 11:16:34  mk
  - Benutzte Register in 32 Bit ASM-Routinen angegeben, Bugfixes

  Revision 1.12  2000/03/16 20:24:12  rb
  Bug beim Erzeugen des Received-Headers behoben

  Revision 1.11  2000/03/16 10:14:24  mk
  - Ver32: Tickerabfrage optimiert
  - Ver32: Buffergroessen f�r Ein-/Ausgabe vergroessert
  - Ver32: Keypressed-Routine laeuft nach der letzen �nderung wieder

  Revision 1.10  2000/03/14 18:47:13  rb
  'programm' (=x-mailer etc.) von 40 auf 60 Zeichen verl�ngert

  Revision 1.9  2000/03/14 15:15:37  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.8  2000/02/25 20:01:46  rb
  unben�tigte Funktion und Variable ausgeklammert

  Revision 1.7  2000/02/25 19:07:08  rb
  Unterst�tzung von 'Priority:' und 'urgent' (incoming)

  Revision 1.6  2000/02/21 00:36:56  rb
  X-Priority Konvertierung verbessert

  Revision 1.5  2000/02/16 22:49:36  mk
  RB: * Verbesserte X-Priority Konvertierung

}
