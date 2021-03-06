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
{ $Id: xp6s.inc,v 1.21 2001/06/18 20:17:34 oh Exp $ }

{ Unterroutinen f�r XP6.PAS }


{ Signatur-Shuffler / Signatur-Makro-Ersetzer }

procedure MakeSignature(var signat, sigfile:pathstr; var sigtemp:boolean);
const sigsep = '-*-';
var t,t2    : text;
    s       : string;
    buf     : string;
    num,n   : word;
begin
  sigtemp:=false;
  if _filesize(signat)=0 then
    sigfile:=''
  else begin
    assign(t,signat);
    settextbuf(t,buf);
    reset(t);
    readln(t,s);
    if s=sigsep then begin
      num:=0;
      while not eof(t) do begin
        readln(t,s);
        if s=sigsep then inc(num);
        end;
      n:=random(num)+1;    { zuf�llige Signatur ausw�hlen }
      end
    else
      n:=0;
    close(t);
    reset(t);
    while n>0 do begin     { ausgew�hlte Signatur suchen }
      repeat
        readln(t,s);
      until s=sigsep;
      dec(n);
      end;
    sigfile:=TempS(2048);
    sigtemp:=true;
    assign(t2,sigfile);
    rewrite(t2);
    s:='';
    while not eof(t) and (s<>sigsep) do begin
      readln(t,s);
      if pm then
        rpsuser(s,empfaenger,sdata^.empfrealname);
      rpsdate(s);
      if s<>sigsep then writeln(t2,s);
      end;
    close(t);
    close(t2);
    end;
end;

function getsize:boolean;
begin
  fs:=_filesize(datei);
  if (fs=0) and not ntMsg0(netztyp) then begin   { Test auf leere Msg }
    rfehler(602);   { 'leere Nachricht - nicht abgeschickt' }
    getsize:=false;
    end
  else begin
    if (fs=0) and not exist(datei) then
      MakeFile(datei);
    getsize:=true;
    end;
end;

procedure showbetreff;
begin
  attrtxt(col.coldiahigh);
  mwrt(x+13,y+4,' '+forms(betreff,52)+' ');
end;


procedure showbox;
var ss : string[BoxNameLen];

   function SameServer:boolean;
   var i : integer;
   begin
     ss:=ccm^[iif(verteiler,1,0)].server;
     SameServer:=true;
     for i:=1 to cc_anz do
       if ccm^[i].server<>ss then begin
         ss:=''; SameServer:=false;
         end;
   end;

begin
  attrtxt(col.coldiahigh);
  gotoxy(x+14,y+6);
  moff;
  if cc_anz=0 then write(forms(box,17))
  else if forcebox='' then
          if SameServer then write(forms(ss,17))
          else write(forms('('+box+')',17))
       else write(forms(forcebox,17));
  mon;
end;

procedure showsize;
var ms : longint;
begin
  attrtxt(col.coldialog);
  moff;
  wrt(x+14,y+8,sp(18));
  attrtxt(col.coldiahigh);
  wrt(x+14,y+8,strs(fs+addsize));
  attrtxt(col.coldialog);
  write(getres(13));    { ' Bytes' }
  ms:=maxsize;
  if binary and ntBinEncode(netztyp) then  { aut. uu-Codierung }
    ms:=system.round((ms-400)/1.415);
  oversize:=iif((maxsize>0) and (fs+addsize>ms),fs+addsize-ms,0);
  if oversize>0 then write('!');
  mon;
end;

function FidoAbsAdr:string;
begin
  if AltAdr<>'' then
    FidoAbsAdr:=AltAdr
  else
    if aliaspt then
      FidoAbsAdr:=left(box,cpos('/',box))+pointname
    else
      FidoAbsAdr:=box+'.'+pointname;
end;

function KomOrgReg:string;
begin
  with registriert do
    if orgreg then KomOrgreg:='Org-'
    else if komreg then KomOrgreg:='Kom-'
    else KomOrgreg:='';
end;

function krk(s:string):string;
begin
  if (KomOrgReg='') or (s='') then
    krk:=s
  else
    krk:=' '+KomOrgReg+trim(s);
end;

procedure Set_XP_ID;
begin
  case netztyp of
    nt_UUCP : XP_ID:='## '+xp_xp+' '+verstr+krk(regstr2)+' ##'+#13#10;
    else      XP_ID:='## '+xp_xp+' '+verstr+krk(regstr1)+' ##'+#13#10;
  end;
end;

function orishuffle(fn:pathstr):string;
var t     : text;
    s     : string;
    buf   : array[0..511] of byte;
    num,n : word;
begin
  assign(t,fn);
  if not existf(t) then
    orishuffle:=getreps(621,fn)    { 'Origin-Datei fehlt: %s' }
  else begin
    settextbuf(t,buf);
    reset(t);
    num:=0;
    while not eof(t) do begin      { Origins z�hlen }
      readln(t,s);
      if s<>'' then inc(num);
      end;
    close(t);
    reset(t);
    n:=random(num)+1; s:='';
    while not eof(t) and (n>0) do begin
      readln(t,s);
      if s<>'' then dec(n);
      end;
    orishuffle:=left(s,54);
    close(t);
    end;
end;

function fido_origin(withcr:boolean):string;
var s : string;
begin
  if netztyp<>nt_fido then
    fido_origin:=''
  else begin
    if not pm then
     if XP_ID_Fido then
        s:=#13#10+XP_origin+' '+verstr+krk(regstr1)
     else
        s:=#13#10+'---'
    else
      s:='';
    if not pm then begin
      if left(lstr(fidoname),8)='shuffle:' then
        fidoname:=OriShuffle(trim(mid(fidoname,9)));
      s:=s+#13#10' * Origin: '+fidoname+' ('+FidoAbsAdr+')';
      end;
    if withcr then
      s:=s+#13#10;
    fido_origin:=s;
    end;
end;

procedure calc_hdsize;
var f : file;
begin
  Set_XP_ID;
  addsize:=0;
  if header<>'' then begin           { Kopf-File testen }
    assign(f,header);
    reset(f,1);
    if ioresult=0 then begin
      inc(addsize,filesize(f)); close(f); end
    else
      header:='';
    end;
  if not flOhnesig and (sigfile<>'') then
    inc(addsize,_filesize(sigfile));
  if (netztyp=nt_Maus) and not pm and (Developer or
     ((right(lstr(empfaenger),11)<>'/maustausch') and
       (right(lstr(empfaenger),6)<>'/mt.xp')) or
       (registriert.r2 and not XP_ID_AMs)) then
    XpID:=false;
  XID:=iifs(XpID and (netztyp<>nt_Fido),XP_ID,'');
  inc(addsize,length(XID));
  inc(addsize,length(fido_origin(true)));
{ if flMnet then inc(addsize,length(MausNet)+2);
  if flMloc then inc(addsize,length(MausLoc)+2); }
end;

procedure showcode;
  function pmcode(c:byte):string;
  begin
    pmcode:=left(pmcrypt[c-2].name,14);
  end;
begin
  attrtxt(col.coldialog);
  moff;
  wrt(x+51,y+6,sp(22));
  gotoxy(x+51,y+6);
  if docode=0 then
    case cancode of
      -1 : write(getreps2(601,1,'Rot13'));       { '%s m�glich' }
       0 : write(getres2(601,iif(pm,2,3)));      { 'kein Pa�wort' / 'nicht m�glich' }
       1 : if binary then write(getres2(601,4))  { 'evtl. QPC m�glich' }
           else write(getreps2(601,1,'QPC'));    { 'QPC m�glich' }
       2 : write(getreps2(601,1,'DES'));         { 'DES m�glich' }
       3..2+maxpmc : write(getreps2(601,1,pmcode(cancode)));
       9 : write(getreps2(601,1,'PGP'));         { 'PGP m�glich' }
    end
  else begin
    attrtxt(col.coldiahigh);
    case docode of
      -1 : write('Rot13');
       0 : write(getres2(601,3));
       1 : write('QPC');
       2 : write('DES');
       3..2+maxpmc: write(pmcode(docode));
       9 : write('PGP');
    end;
  end;
  mon;
  freeres;
end;

procedure showcc;
begin
  attrtxt(col.coldialog);
  mwrt(x+51,y+8,sp(20));
  if cc_anz=0 then
    mwrt(x+51,y+8,getres(602))   { 'keine' }
  else begin
    attrtxt(col.coldiahigh);
    mwrt(x+51,y+8,strs(cc_anz));
    end;
end;

procedure ShowLine(spezial:boolean);
begin
  attrtxt(col.coldialog);
  if spezial then begin
    mwrt(x+3,y+10,getres2(603,1));   { 'Spezial..  ' }
    mwrt(x+39,y+10,'               ');
    end
  else begin
    mwrt(x+3,y+10,getres2(603,2));   { 'Absenden..'  }
    mwrt(x+39,y+10,getres2(603,3));  { '�ndern..'    }
  end;
  freeres;
end;

procedure ShowFlags;
var flags : string[80];

  function pmcc_anz:integer;
  var i,anz : integer;
  begin
    anz:=0;
    for i:=1 to cc_anz do
      if cpos('@',cc^[i])>0 then inc(anz);
    pmcc_anz:=anz;
  end;

begin
  if flCrash then flags:='Crash '
  else flags:='';
  if flohnesig then flags:=flags+getres2(604,1);    { 'ohneSig '   }
  if flEB then flags:=flags+getres2(604,2);         { 'EmpfBest '  }
  if flLoesch then flags:=flags+getres2(604,3);     { 'l�schen '   }
  if flMnet then flags:=flags+getres2(604,4);       { '(MausNet) ' }
  if flMloc then flags:=flags+getres2(604,5);       { '(lokal) '   }
  if flNokop and (pmcc_anz>0) then
    flags:=flags+getres2(604,13);                   { 'NOKOP '     }
  case msgprio of
    10 : flags:=flags+getres2(604,iif(length(flags)<20,6,7));  { 'Direktmail ' / 'Direkt ' }
    20 : flags:=flags+getres2(604,iif(length(flags)<20,8,9));  { 'Eilmail ' / 'Eilmail ' }
  end;
  { RFC: Gew�hlten X-Priority-Flag im Sendefenster anzeigen     }
  case rfcprio of
    1 : flags:=flags+getres2(604, 14);           { 'H�chste '   }
    2 : flags:=flags+getres2(604, 15);           { 'Hoch '      }
    3 : flags:=flags+getres2(604, 16);           { 'Normal '    }
    4 : flags:=flags+getres2(604, 17);           { 'Niedrig '   }
    5 : flags:=flags+getres2(604, 18);           { 'Niedrigste '}
  end;
  if flPGPkey then flags:=flags+getres2(604,10);   { 'PGP-Key ' }
  if flPGPsig then flags:=flags+getres2(604,11);   { 'PGP-Sig ' }
  if flPGPreq then flags:=flags+getres2(604,12);   { 'PGP-Req ' }
  attrtxt(col.coldiarahmen);
  if trim(flags)='' then
    mwrt(x+35,y-iif(echomail,2,0),dup(41,'�'))
  else
    mwrt(x+40,y-iif(echomail,2,0),right(dup(39,'�')+' '+flags,36));
  freeres;
end;


{ Aufbau der MessageID  (hi..lo):
  16 bit   tag/monat/Jahr
  16 bit   laufender Z�hler
  12 bit   Zufallszahl
  16 bit   CRC �ber Username

  MausTausch:  2 Ziffern Tagesdatum      Fido:  13 bit  Datum
               6 Ziffern lfd. Z�hler            16 bit  laufender Z�hler
               2 Ziffern Zufallszahl             3 bit  Zufallszahl }

{ Es wird dei INT_NR des aktuellen Datensatzes der mbase verwendet }

function MessageID:string;
const rev = 'B';   { Revision des MsgID-Algorithmus }
var inr     : longint;
    t,m,j,d : rtlword;
    h,mm,s,ss: rtlword;
    dat     : word;
    count   : word;
    rand    : word;
    csum    : word;
    b64     : array[0..63] of char;
    _domain : string[80];
    msgidtyp: byte;
    local_part : string[20];

  function b30(l:longint):string;   { 30bit -> 5char }
  const bc : string[5] = '     ';
  var i : byte;
  begin
    for i:=5 downto 1 do begin
      bc[i]:=b64[l and 63];
      l:=l shr 6;
      end;
    b30:=bc;
  end;

begin
  msgidtyp:=ntMessageID(netztyp);
  if nomids or (msgidtyp=0) then
    MessageID:=''
  else begin
    b64:='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ$abcdefghijklmnopqrstuvwxyz-';
    getdate(j,m,t,d);
    gettime(h,mm,s,ss);
    dat:=(t-1)+(m-1)*32+(j mod 165)*32*12;
    dbRead(mbase,'INT_NR',inr);
    case msgidtyp of
      3 : MessageID:=formi(t,2)+formi(inr mod 1000000,6)+    { MausTausch }
                     formi(random(100),2)+'@'+box;
      4 : MessageID:=fidoAbsAdr+iifs(domain<>'','@'+domain,'')+' '+ { Fido }
                     lstr(hex(longint(dat and $1fff) shl 19+(inr and $ffff) shl 3
                          +random(8),8));   { eindeutig f. 16 Jahre, }
                                            { max. 65536 Msgs/Tag    }
      6 : MessageID:=iifc(pm,iifc(_bezug='','P','Q'),iifc(_bezug='','A','R'))
                     +'/'+formi(h,2)+formi(mm,2)+formi(inr mod 10000,4)+
                     formi(t,2)+formi(m,2)+formi(j,4)+'_013@'+box+';'+ { ProNet }
                     pointname+domain; { X/HHMMSSssDDMMYYYY_KKK@BOX;NR.pro }
    else begin
      count:=word(inr and $ffff);
      rand:=random($1000);
      csum:=crc16strXP(username);
      case netztyp of
        {17.01.00 HS: Message-IDs mit dem FQDN erstellen, falls eingetragen}
        nt_ZConnect : if fqdn='' then _domain:=rev+'@'+lstr(pointname+'.'+box)+domain
                        else {if pos('@',fqdn)>1 then _domain:=rev+'.'+fqdn else}
                         _domain:=rev+'@'+fqdn;
        nt_Magic    : if aliaspt then _domain:=pointname+rev+'@'+lstr(box)+domain
                      else _domain:=rev+'@'+lstr(pointname)+domain;
        nt_Quick,
        nt_GS       : _domain:=rev+'@'+pointname;
        nt_UUCP,
        nt_PPP     : if fqdn='' then _domain:=rev+'@'+pointname+domain
                        else if pos('@',fqdn)>1 then _domain:=rev+'.'+fqdn else
                        _domain:=rev+'@'+fqdn;
      else
        _domain:='@'+box;
      end;
      local_part:=b30(longint(dat) shl 14+count shr 2)+
                  b30(longint(count and 3) shl 28+longint(rand) shl 16 +csum);
      MessageID:=local_part+_domain;
      end;
    end;  { Case }
    end;
end;


procedure wrs(s:string);
begin
  s:=s+#13#10;
  blockwrite(f2^,s[1],length(s));
end;

{ Datei aus f (geschlossen) an f2 (offen) anh�ngen }
{ code<>0 -> mit passwd^ codieren                  }

procedure AppendFile(code:shortint; ofs:longint; iso:boolean);
type barr = array[0..65000] of byte;
var p     : ^barr;
    siz: word;
    rr: word;
    rr0   : word;
begin
  siz:=min(maxavail-10000,30000);
  getmem(p,siz);
  fm_ro; reset(f^,1); fm_rw;
  seek(f^,ofs);
  while not eof(f^) do begin
    if ((umlaute<>1) and (umlaute<>2)) or newbin then begin
      blockread(f^,p^,siz,rr);
      if iso then IbmToIso1(p^,rr);
      end
    else begin
      blockread(f^,p^[1500],siz-1500,rr);  { Platz f�r Umlaut-Konvertierung }
      rr0:=rr;
      ukonv(umlaute,p^,rr);   { ver�ndert evtl. rr }
      inc(fs,rr-rr0);
      end;
    if code=-1 then Rot13(p^,rr);
    blockwrite(f2^,p^,rr);
    end;
  close(f^);
  freemem(p,siz);
end;

procedure encode_file(des:boolean; var f1,f2:file);
var p    : pointer;
    rr   : word;
    show : boolean;
    x,y  : byte;
    ofs  : longint;
    total: longint;
begin
  getmem(p,8000);
  seek(f1,0);
  total:=filesize(f1);
  show:=des and (total>2000);
  if show then begin
    message(getres(605));    { 'DES-Codierung...     %' }
    x:=wherex-5; y:=wherey;
    end
  else
    x:=0;
  ofs:=0;
  while not eof(f1) do begin
    blockread(f1,p^,8000,rr);
    if des then
      DES_code(false,p^,ofs,total,rr,x,y)
    else
      QPC(false,p^,rr,passwd,passpos);
    blockwrite(f2,p^,rr);
    inc(ofs,rr);
    end;
  if show then closebox;
  freemem(p,8000);
end;

procedure SetCryptFlag;
var flag : byte;
begin
  dbReadN(mbase,mb_unversandt,flag);
  flag:=flag or 4;
  dbWriteN(mbase,mb_unversandt,flag);
end;

procedure pmCryptFile(var hd:xp0.header; var fn:pathstr);
var s   : string;
    hdp : headerp;
    hds : longint;
    ok  : boolean;
    oemp: string[AdrLen];
    bin : boolean;

  procedure AddZer(var s:string);
  var  p,p2: byte;
  begin
    p:=cpos('@',s);
    p2:=pos('.',mid(s,p+1));
    if p2>0 then s:=left(s,p+p2)+'ZER';
  end;

  function IsBinary(var f:file):boolean;   { true -> Datei enth�lt }
  const bufs  = 2048;                      {         Steuerzeichen }
  var   isbin : boolean;
        buf   : charrp;
        rr    : word;
  begin
    isbin:=false;
    getmem(buf,bufs);
    while not isbin and not eof(f) do begin
      blockread(f,buf^,bufs,rr);
      if rr>0 then
        isbin:=testbin(buf^,rr);
      end;
    seek(f,0);
    freemem(buf,bufs);
    IsBinary:=isbin;
  end;

begin
  assign(f2^,temppath+cryptedfile);
  if existf(f2^) then erase(f2^);
  assign(f2^,temppath+uncryptedfile); rewrite(f2^,1);
  assign(f^,fn);
  fm_ro; reset(f^,1); fm_rw;
  new(hdp);
  makeheader(ntZConnect(hd.netztyp),f^,0,0,hds,hdp^,ok,false);
  oemp:=hdp^.empfaenger;
  if hdp^.netztyp=nt_ZConnect then with hdp^ do begin
    AddZer(absender);
    AddZer(empfaenger);
    end;
  hdp^.netztyp:=nt_Netcall;
  WriteHeader(hdp^,f2^,nil);
  seek(f^,hds);
  fmove(f^,f2^);
  close(f^); close(f2^);
  s:=pmcrypt[docode-2].encode;
  rps(s,'$KEY',passwd^);
  rps(s,'$INFILE',temppath+uncryptedfile);
  rps(s,'$OUTFILE',temppath+cryptedfile);
  rps(s,'$USER',oemp);
  dispose(hdp);
  shell(s,500,3);                     { Nachricht codieren }
  if exist(temppath+uncryptedfile) then
    _era(temppath+uncryptedfile);
  assign(f^,temppath+cryptedfile);
  if not existf(f^) then
    rfehler(603)    { 'Datei wurde nicht codiert!' }
  else begin
    reset(f^,1);
    bin:=pmcrypt[docode-2].binary or IsBinary(f^);
    if bin and not ntBinary(netztyp) then
      rfehler(609)     { In diesem Netz sind keine Bin�rnachrichten m�glich. }
    else begin
      assign(f2^,fn);
      rewrite(f2^,1);
      hd.groesse:=filesize(f^);
      hd.betreff:=PMC_ID+' by XP ('+pmcrypt[docode-2].name+') '+
                  hex(dbReadInt(mbase,'groesse'),6);
      hd.typ:=iifc(bin,'B','T');
      inc(hd.attrib,AttrPmcrypt);
      WriteHeader(hd,f2^,_ref6list);
      fmove(f^,f2^);
      close(f2^);
      SetCryptFlag;
      end;
    close(f^); erase(f^);
    end;
end;

function fileserver(var adresse:string):boolean;
var d      : DB;
    p,p2   : byte;
    fsname : string[30];
begin
  p:=cpos('@',adresse);
  if p=0 then exit;
  p2:=p+pos('.',copy(adresse,p+1,255));
  if p2=0 then exit;
  dbOpen(d,SystemFile,siName);
  dbSeek(d,siName,copy(adresse,p+1,p2-p-1));
  if dbFound then dbRead(d,'fs-name',fsname)
  else fsname:='';
  dbClose(d);
  fileserver:=left(adresse,p-1)=fsname;
end;

function QuoteOK:boolean;
var t     : text;
    buf   : array[0..2047] of byte;
    n,nq  : integer;
    s     : string;
    x,y,i : byte;
    lines : byte;
    a     : taste;
    p     : byte;
begin
  QuoteOK:=true;
  assign(t,datei);
  settextbuf(t,buf);
  if not existf(t) or (trim(QChar)='') then exit;
  fm_ro; reset(t); fm_rw;
  n:=0; nq:=0;
  while not eof(t) do begin
    inc(n);
    readln(t,s);
    p:=cpos('>',s);
    if ((p>0) and (p<5)) or (left(s,length(QChar))=QChar) then
      inc(nq);
    end;
  close(t);
  if (nq/n)>=0.5 then begin
    lines:=ival(getres2(606,1));
    msgbox(51,lines+6,getres2(606,0),x,y);    { 'Hinweis' }
    for i:=1 to lines-1 do
      mwrt(x+3,y+i+1,getreps2(606,i+1,strsr(nq/n*100,0)));
    mwrt(x+3,y+lines+2,getres2(606,lines+1));
    errsound;
    a:='';
    n:=readbutton(x+3,y+lines+4,2,getres2(606,lines+2),2,true,a);   { '  ^Ja  , ^Nein ' }
    if (n=0) or (n=2) then begin
      QuoteOK:=false;
      if n=2 then keyboard(getres2(606,lines+3));  { 'T' }
      end;
    closebox;
    freeres;
    end;
end;


function SizeOK:boolean;
var t     : text;
    buf   : array[0..2047] of char;
    lines : longint;
begin
  SizeOK:=true;
  assign(t,datei);
  settextbuf(t,buf);
  if not existf(t) then exit;
  fm_ro; reset(t); fm_rw;
  lines:=0;
  while not eof(t) do begin
    inc(lines);
    readln(t);
    end;
  close(t);
  if lines>495 then begin
    fehler('Nachricht zu lang f�r ProNET - maximal 500 Zeilen erlaubt!');
    SizeOK:=false;
    end;
end;

procedure ParkMsg;
var f : file;
    i : integer;
  procedure wrs(s:string);
  begin
    s:=left(s,253)+#13#10;
    blockwrite(f,s[1],length(s));
  end;
begin
  if exist(datei) then begin
    assign(f,TempS(_filesize(fn^)+200));
    rewrite(f,1);
    wrs(getres(600){oempf}+' '+mid(vert_name(empfaenger),iif(pm,1,2)));
    for i:=1 to cc_anz do
      wrs(getres(600)+' '+cc^[i]);
    wrs('');
    assign(f2^,datei);
    reset(f2^,1);
    fmove(f2^,f);
    close(f2^); close(f);
    erase(f2^);
    rename(f,datei);
    if ioresult<>0 then begin
      rewrite(f2^,1); reset(f,1);
      fmove(f,f2^);
      close(f); close(f2^);
      erase(f);
      end;
    end;
end;

function DateSend:boolean;
var brk      : boolean;
    x,y      : byte;
    mind     : fdate;
    dd,mm,yy : rtlword;
    dow      : rtlword;
begin
  if AutoActive then    { d�rfte nicht vorkommen }
    DateSend:=false
  else begin
    getdate(yy,mm,dd,dow);
    mind.t:=dd; mind.m:=mm; mind.j:=yy;
    incd(mind);
    senddate:=formi(mind.t,2)+'.'+formi(mind.m,2)+'.'+formi(mind.j mod 100,2);
    min_send:=ixdispdat(senddate);
    dialog(27,3,'',x,y);
    madddate(3,2,getres(607),senddate,false,false);   { 'absenden am ' }
    msetvfunc(test_senddate);
    readmask(brk);
    enddialog;
    DateSend:=not brk;
    end;
end;

procedure DateSendIt;
var dat   : longint;
    flags : word;
    typ   : char;
    empf  : string[AdrLen];
    mon   : word;
begin
  rmessage(608);    { 'Nachricht speichern...' }
  repeat
    fn^:=SendPath+strs(random(10000))+'.MSG';
  until not exist(fn^);
  if filecopy(datei,fn^) then;
  dbOpen(auto,AutoFile,1);
  dbAppend(auto);
  dbWrite(auto,'dateiname',fn^);
  dbWrite(auto,'betreff',betreff);
  if pm then empf:=empfaenger
  else empf:=mid(empfaenger,2);
  dbWrite(auto,'empfaenger',empf);
  typ:=iifc(binary,'B','T');
  dbWrite(auto,'typ',typ);
  dbWrite(auto,'pollbox',box);
  dat:=IxDispdat(senddate);
  dbWrite(auto,'datum1',dat);
  mon:=$fff;
  dbWrite(auto,'monate',mon);
  flags:=3;   { aktiv, l�schen }
  dbWrite(auto,'flags',flags);
  dbClose(auto);
  closebox;
end;

procedure get_xref;
var hdp : headerp;
    hds : longint;
    p   : byte;
begin
  new(hdp);
  ReadHeader(hdp^,hds,false);
  with hdp^ do begin
    _bezug:=msgid;
    _orgref:=org_msgid;
    _beznet:=netztyp;
    if netztyp=nt_Maus then
      _ReplyPath:=pfad;
    if cpos('#',absender)>0 then
      fidoto:=realname
    else begin
      p:=cpos('@',absender);
      if p=0 then p:=length(absender)+1;
      if netztyp<>nt_ZCONNECT then
        fidoto:=left(absender,min(35,p-1));
      end;
    if (sendflags and SendIQuote<>0) and (hdp^.fido_to<>'') then
      fidoto:=hdp^.fido_to;
    origbox:=pfadbox(ntZConnect(dbReadInt(mbase,'netztyp') and $ff),pfad);
    end;
  dispose(hdp);
end;

procedure get_origbox;
var hdp : headerp;
    hds : longint;
begin
  new(hdp);
  ReadHeader(hdp^,hds,false);
  origbox:=pfadbox(ntZConnect(dbReadInt(mbase,'netztyp') and $ff),hdp^.pfad);
  dispose(hdp);
end;

procedure LoadBoxData;
var flags : byte;
begin
  if forceabs='' then
    dbRead(d,'username',username)
  else
    username:=forceabs;
  dbRead(d,'pointname',pointname);
  dbRead(d,'dateiname',boxfile);
  dbRead(d,'nameomaps',mapsname);
  dbRead(d,'netztyp',netztyp);
  dbRead(d,'realname',realname);
  dbRead(d,'script',flags);
  if fidoname='' then
    dbRead(d,'fidoname',fidoname);
  aliaspt:=(flags and 4<>0);
  nomids:=(flags and 8<>0);
  nobox:=(flags and 16<>0);
  dbRead(d,'domain',domain);
  dbRead(d,'fqdn',fqdn);  {16.01.00 HS}
  if sData^.pmreplyto='' then
    dbRead(d,'ReplyTo',sdata^.pmreplyto);
  betrlen:=ntBetreffLen(netztyp);
  if (netztyp in [nt_UUCP,nt_PPP]) and (umlaute=2) then
    umlaute:=0;
end;

procedure SetEBkennung;
var haseb : boolean;
begin
  haseb:=(left(betreff,length(empfbkennung))=empfbkennung);
  if not ntEmpfBest(netztyp) then begin
    if flEB then begin
      if not haseb then betreff:=empfbkennung+betreff;
      end
    else
      if haseb then
        betreff:=trim(mid(betreff,length(empfbkennung)+1));
    end
  else
    if haseb then
      betreff:=trim(mid(betreff,length(empfbkennung)+1));
end;

function TestXPointID:boolean;
var s  : string;
    rr : word;
begin
  Set_XP_ID;
  TestXPointID:=true;
  assign(f^,datei);
  if existf(f^) then begin
    fm_ro; reset(f^,1); fm_rw;
    seek(f^,max(0,filesize(f^)-length(XP_ID)-100));
    blockread(f^,s[1],length(XP_ID)+100,rr);
    s[0]:=chr(rr);
    close(f^);
    TestXPointID:=(pos(XP_ID,s)>0);
    end;
end;

procedure SetLocalPM;
var l : byte;
begin
  lokalPM:=(right(empfaenger,length(box)+4)=box+'.ZER') or
           stricmp(right(empfaenger,length(box)+length(domain)),box+domain) or
           stricmp(right(empfaenger,length(box)),box);
  case netztyp of
    nt_Netcall,nt_ZCONNECT : l:=1;
    nt_Fido                : l:=2;
    nt_UUCP                : l:=3;
    nt_PPP                 : l:=4;
    nt_Maus                : l:=5;
    nt_Magic               : l:=6;
    nt_Quick,nt_GS         : l:=7;
  else begin
    maxsize:=0; exit;      { nt_Pronet (s. SizeOK), nt_turbo }
    end;
  end;
  maxsize:=pmlimits[l,iif(lokalPM,2,1)];
end;

function steuerzeichen(var s:string):boolean;
var i : integer;
begin
  i:=1;
  while (i<=length(s)) and (s[i]>=' ') do inc(i);
  steuerzeichen:=(i<=length(s));
end;

function Empferror:boolean;
var p  : byte;
    ee : string[40];
    fa : FidoAdr;
begin
  ee:='';
  p:=cpos('@',empfaenger);
  if p=0 then
    ee:=getres2(609,1)     { '"@" fehlt!' }
  else if (pos(' ',left(empfaenger,p))>0) and not ntNameSpace(netztyp) then
    ee:=iifs(ReadJN(getres2(609,2),true),'','*')   { 'Warnung: Leerzeichen in Adresse! Trotzdem absenden' }
  else if steuerzeichen(empfaenger) then
    ee:=getres2(609,7)     { 'unerlaubte Steuerzeichen in Useradresse' }
  else
    case ntDomainType(netztyp) of
        0 : if right(empfaenger,4)<>'.ZER' then begin
              errsound;
              ee:=iifs(ReadJN(getres2(609,3),false),'','*');   { '.ZER in Adresse fehlt! Trotzdem absenden' }
              end;
        4 : begin
              SplitFido(empfaenger,fa,DefaultZone);
              if fa.net=0 then ee:=getres2(609,4);   { 'Fido-Netznummer fehlt!' }
            end;
        5 : if pos('.',mid(empfaenger,p+1))=0 then ee:=getres2(609,5);  { 'Domain fehlt!' }
    end;
  if (ee<>'') and (ee<>'*') then
    afehler(getreps2(609,6,ee),not sendbox);   { 'fehlerhafter Empf�nger: %s' }
  EmpfError:=(ee<>'');
  freeres;
end;

function FidoAdrOK(testbox:boolean):boolean;
var ni : NodeInfo;
    fa : fidoadr;
begin
  GetNodeinfo(empfaenger,ni,2);
  if not ni.found then begin
    if testbox then rfehler(2116);    { 'Unbekannte Nodeadresse! }
    FidoAdrOk:=false;
    end
  else begin
    splitfido(empfaenger,fa,DefaultZone);
    if testbox then
      if ni.ispoint then
        ShrinkPointToNode(fa,ni)
      else
        fa.ispoint:=false;
    if testbox and IsBox(MakeFidoAdr(fa,true)) then begin
      rfehler(604);   { 'Nachricht an Serverbox bitte als normale Mail absenden' }
      FidoAdrOK:=false;
      end
    else
      FidoAdrOK:=true;
    end;
end;

procedure SetCrashInfo;
var fa : FidoAdr;
    ni : NodeInfo;
begin
  GetNodeinfo(hdp^.empfaenger,ni,2);
  splitfido(hdp^.empfaenger,fa,DefaultZone);
  fa.ispoint:=ni.ispoint;
  SetCrash(makeFidoAdr(fa,true),true);
end;

function CrashAdr:string;
var fa : FidoAdr;
    ni : NodeInfo;
begin
  GetNodeinfo(hdp^.empfaenger,ni,2);
  splitfido(hdp^.empfaenger,fa,DefaultZone);
  fa.ispoint:=ni.ispoint;
  ShrinkPointToNode(fa,ni);
  CrashAdr:=MakeFidoAdr(fa,true);
end;

procedure SendMbox;
var s   : string[30];
begin
  s:=getres2(610,iif(intern,1,iif(parken,2,3)));  { 'Nachricht ' 'speichern' / 'parken' / 'abschicken' }
  if sendFlags and sendShow=0 then
    message(s+'...')
  else
    message(getres2(610,iif(intern,4,5))+   { 'Speichere Nachricht in ' / 'Sende Nachricht an ' }
            copy(empfaenger,iif(pm,1,2),50)+' ');
  freeres;
end;

procedure EditSdata;
var x,y : byte;
    brk : boolean;
    asc : string[120];
    sml : string[1];

begin
  case netztyp of
    nt_ZConnect    : y:=iif(pm and not brettverteiler,5,9);
    nt_UUCP,nt_PPP : y:=iif(pm and not brettverteiler,5,13);
  end;
  dialog(ival(getres2(616,0)),y,getres2(616,6),x,y);   { 'Zus�tzliche Informationen' }
  y:=2;
  asc:=range(' ',#126);
  with sData^ do begin
    if not pm or brettverteiler then begin
      if ntGrossBrett(netztyp) then sml:='>'
      else if ntKleinBrett(netztyp) then sml:='<'
      else sml:='';
      maddstring(3,y,getres2(616,1),AmReplyTo,40,eAdrLen,sml+asc); mhnr(850);
      mappcustomsel(selbrett,false);        { 'Brettantworten in' }
      mset3proc(firstslash);
      inc(y,2);
    end;
    maddstring(3,y,getres2(616,5),PmReplyTo,40,eAdrLen,asc); mhnr(851);
    mappcustomsel(seluser,false);           { 'PM-Antworten an  ' }
    msetvfunc(testReplyTo);
    inc(y,2);
    maddstring(3,y,getres2(616,2),keywords,40,60,       { 'Stichworte' }
               iifs(ntHeaderUmlaut(netztyp),'',asc)); mhnr(852);
    inc(y,2);
    if not pm or brettverteiler then begin
      maddstring(3,y,getres2(616,3),summary,40,200,  { 'Zusammenfassung' }
               iifs(ntHeaderUmlaut(netztyp),'',asc));   { max. L�nge: 200! }
      inc(y,2);                                 { (wg. RFC-1522-Codierung) }
      if (netztyp in [nt_UUCP,nt_PPP]) then begin
        maddstring(3,y,getres2(616,4),distribute,40,40,asc); { 'Verbreitung' }
        inc(y,2);
        if ntPmReply(netztyp) then
          maddbool(3,y,getres2(616,7),pm_reply); mhnr(849); { 'Followup-To by PM' }
      end;
    end;
  end;
  readmask(brk);
  if sData^.pm_reply and (sData^.AmReplyTo<>'') then sData^.AmReplyTo:='';
  freeres;
  enddialog;
end;

function MayCrash:boolean;
begin
  MayCrash:=(netztyp=nt_Fido) and pm;
end;

function FileContainsUmlaut:boolean;
var t     : text;
    buf   : array[0..2047] of byte;
    s     : string;
begin
  FileContainsUmlaut:=false;
  assign(t,datei);
  settextbuf(t,buf);
  if not existf(t) then exit;
  fm_ro; reset(t); fm_rw;
  while not eof(t) do begin
    readln(t,s);
    if ContainsUmlaut(s) then begin
      close(t);
      FileContainsUmlaut:=true;
      exit;
      end;
    end;
  close(t);
end;

procedure SendPGPOptions;
var brk : boolean;
    x,y : byte;
begin
  if not UsePGP then
    rfehler(633)    { 'Aktivieren Sie zuerst PGP unter /Config/Extern/PGP!' }
  else
  if netztyp<>nt_ZConnect then
    flPGPsig:=not flPGPsig
  else begin
    dialog(ival(getres2(645,0)),5,getres2(645,1),x,y); { 'PGP-Optionen' }
    maddbool(3,2,getres2(645,2),flPGPsig);             { 'Nachricht signieren' }
    mhnr(1021);
    mset1func(pgpo_sigtest);
    maddbool(3,3,getres2(645,3),flPGPreq);         { 'Public Key anfordern' }
    if not pm then mdisable;
    maddbool(3,4,getres2(645,4),flPGPkey);         { 'eigenen Key verschicken' }
    mset1func(pgpo_keytest);
    readmask(brk);
    freeres;
    enddialog;
  end;
end;

procedure SetXpointCtl;
var sum : longint;
    i   : integer;
begin
  with hdp^ do
    if exist(left(datum,6)+'.345') and stricmp(datei,SupportCfg) then begin
      sum:=0;
      for i:=1 to length(datum) do
        inc(sum,ord(datum[i])*7);
      for i:=1 to length(msgid) do
        inc(sum,ord(msgid[i])*3);
      XpointCtl:=sum*1000+random(1000);
      end;
end;

{ Dialog: Priorit�t ermitteln und in glob. Variable RFCPrio schreiben }
{ RFC: X-Priority: 1, 2, 3, 4, 5 }
procedure getprio;
var
  x,y : byte;
  brk : boolean;
  prio: string[10];
begin                                                  { 'Sende-Priorit�t' }
  dialog(ival(getres2(272,0)),3,getres2(272,7),x,y);
  prio:=getres2(272,iif(rfcprio=0,6,rfcprio));
  maddstring(3,2,getres2(272,8),prio,10,10,'');        { 'Priorit�t '      }
  mappsel(false,getres2(272,9));
  readmask(brk);          { 'H�chste�Hoch�Normal�Niedrig�Niedrigste�Keine' }
  if not brk and mmodified then begin
    if prio=getres2(272,1) then rfcprio:=1 else { 'H�chste'    }
    if prio=getres2(272,2) then rfcprio:=2 else { 'Hoch'       }
    if prio=getres2(272,3) then rfcprio:=3 else { 'Normal'     }
    if prio=getres2(272,4) then rfcprio:=4 else { 'Niedrig'    }
    if prio=getres2(272,5) then rfcprio:=5 else { 'Niedrigste' }
    if prio=getres2(272,6) then rfcprio:=0;     { 'Keine'      }
  end;
  freeres;
  enddialog;
end;

{
  $Log: xp6s.inc,v $
  Revision 1.21  2001/06/18 20:17:34  oh
  Teames -> Teams

  Revision 1.20  2000/11/04 10:26:43  MH
  FQDN: Auswahl f�r ISP (automatische Generrierung)
  - erweiterte FQDN m�glich: name@domain.tld
  - nur UUCP und PPP

  Revision 1.19  2000/11/01 15:34:43  MH
  -.-

  Revision 1.18  2000/11/01 12:01:54  rb
  Tearline-Schalter

  Revision 1.17  2000/10/26 17:13:35  MH
  �nderung der Mailer- und Tearlinezeile nun wirksam

  Revision 1.16  2000/10/26 14:49:20  MH
  Ein reiner Brettverteiler erf�hrt eine Sonderbehandlung

  Revision 1.15  2000/10/14 08:02:32  MH
  FollowUpTo: Meldungen entfernt

  Revision 1.14  2000/10/13 22:05:55  MH
  FollowUpTo: Brettantworten in verbieten...

  Revision 1.13  2000/10/13 20:06:59  MH
  Followup-To for PMs only...

  Revision 1.12  2000/10/13 07:19:51  MH
  PMLIMITS angepasst...

  Revision 1.11  2000/10/12 21:44:44  oh
  -PGP-Passphrase merken + Screenshot-File-Verkleinerung

  Revision 1.10  2000/07/02 09:28:20  MH
  - Sourceheader ausgetauscht

  Revision 1.9  2000/07/02 09:22:51  MH
  - Fix: Sendefenster Spezial wurde nicht sauber dargestellt
  - Priority: �bernimmt aktuelle Einstellung im Prio.-Fenster

  Revision 1.8  2000/06/02 09:46:45  MH
  RFC/PPP: Weitere Anpassungen

  Revision 1.7  2000/05/21 10:42:16  MH
  RFC/PPP: Verbreitung im Zusatzmenn aktiviert

  Revision 1.6  2000/05/17 17:27:30  MH
  Neuer Boxentyp: RFC/PPP

  Revision 1.5  2000/04/30 13:41:18  MH
  Empfaengertaste im Sendefenster

  Revision 1.4  2000/04/09 18:26:38  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.12  2000/04/04 10:33:57  mk
  - Compilierbar mit Virtual Pascal 2.0

  Revision 1.11  2000/03/14 15:15:40  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.10  2000/03/09 23:39:34  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.9  2000/03/01 09:24:30  mk
  HS: - FQDN jetzt auch bei UUCP-Boxen

  Revision 1.8  2000/02/21 14:55:43  mk
  MH: Prioritaetenbehandlung eingebaut

  Revision 1.7  2000/02/19 11:40:08  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.6  2000/02/18 00:03:01  mk
  MH: * Sendepriotitaet in Resourcen aufgenommen

  Revision 1.5  2000/02/17 13:04:05  mk
  MH: * Prioauswahl fuer keine Prioritaet hinzugefuegt

}
