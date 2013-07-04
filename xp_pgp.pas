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
{ $Id: xp_pgp.pas,v 1.20 2001/06/18 20:10:04 oh Exp $ }

{ PGP-Codierung }

{$I XPDEFINE.INC }
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit  xp_pgp;

interface

uses  xpglobal, dos,typeform,fileio,resource,database,maske,xp0,xp1,xp5;

procedure LogPGP(s:string);                  { s in PGP.LOG schreiben         }
procedure RunPGP(par:string);                { PGP 2.6.x bzw. 6.5.x aufrufen  }
procedure RunPGP5(exe:string;par:string);    { PGP 5.x aufrufen               }
procedure RunGPG1(par:string);               { GnuPG 1.x aufrufen             }
procedure UpdateKeyfile;
procedure WritePGPkey_header(var f:file);    { PGP-PUBLIC-KEY: ... erzeugen   }
procedure WritePGPkey_body(var t:text);      { PGP-PUBLIC-KEY: ... erzeugen   }
procedure PGP_SendKey(empfaenger:string; bin:boolean);    { Antwort auf Key-Request senden }
procedure PGP_EncodeFile(var source:file; var hd:xp0.header;
                         fn,UserID:string; encode,sign:boolean;
                         var fido_origin:string);

procedure PGP_RequestKey;
procedure PGP_DecodeMessage(hdp:headerp; sigtest:boolean);
procedure PGP_DecodeMsg(sigtest:boolean);  { dec. und/oder Signatur testen }
procedure PGP_DecodeKey(source,dest:string);
procedure PGP_ImportKey(auto:boolean);
procedure PGP_EditKey;
procedure PGP_RemoveID;

procedure PGP_BeginSavekey;      { Key aus ZCONNECT-Header tempor�r sichern }
procedure PGP_EndSavekey;


implementation  { --------------------------------------------------- }

uses  xp3,xp3o,xp3o2,xp3ex,xp6,xpcc,xpnt;

const
  savekey : string = '';
  flag_PGPSigOk = $01;    
  flag_PGPSigErr = $02;    

{ MK 06.01.00: die drei ASM-Routinen in Inline-Asm umgeschrieben
  JG 08.01.00: Routine optimiert }

  
function testbin(var bdata; rr:word):boolean; assembler; {&uses esi}
{$IFDEF BP }
asm
         push ds
         mov   cx,rr
         lds   si,bdata
         cld
@tbloop: lodsb
         cmp   al,9                     { Bin�rzeichen 0..8, ja: c=1 }
         jb    @tbend                  { JB = JC }
         loop  @tbloop
@tbend:  mov ax, 0
       {  adc ax,ax }                      { C=0: false, c=1: true }
         sbb ax,ax
         pop ds
end;
{$ELSE }
asm
         mov   ecx,rr
         mov   esi,bdata
         cld
@tbloop: lodsb
         cmp   al,9                     { Bin�rzeichen 0..8, ja: c=1 }
         jb    @tbend                  { JB = JC }
         loop  @tbloop
@tbend:  mov eax, 0
       {  adc ax,ax }                      { C=0: false, c=1: true }
         sbb eax,eax
{$IFDEF FPC }
end ['EAX', 'ECX', 'ESI'];
{$ELSE }
end;
{$ENDIF }
{$ENDIF}


procedure LogPGP(s:string);
var t : text;
begin
  assign(t,LogPath+'PGP.LOG');
  if existf(t) then append(t)
  else rewrite(t);
  writeln(t,left(date,6),right(date,2),' ',time,'  ',s);
  close(t);
  if (ioresult<>0) then;
end;


function getPGPPassphrase(ask:boolean) : boolean;
var rc:boolean;
begin
  rc:=false;
  { Falls die Phrase nicht gemerkt werden sollte: auf Environment resetten }
  if (PGP_Passphrase='') or (not PGPPassMemo)
    then begin
      PGP_Passphrase:=GetEnv('PGPPASS');
      if (GetEnv('PASSPHRASE')<>'') then PGP_Passphrase:=GetEnv('PASSPHRASE');
    end;
  
  { Eingabefenster nur, wenn nicht im Batchmode }
  if not PGPBatchmode then
    if (PGP_Passphrase='') then
      {if (PGPVersion<>PGP2) then}
      if ask then PGP_Passphrase := EnterPGPPassphrase;
  if (PGP_Passphrase<>'') then rc:=true;
  getPGPPassphrase:=rc
end;


{ PGP 2.6.x und 6.5.x }
procedure RunPGP(par:string);
const
  {$ifdef linux}
    PGPEXE = 'pgp';
    PGPBAT = 'xpgp.sh';
    pgptmpbatch = 'PGPTMP.sh';
  {$else}
    PGPEXE = 'PGP.EXE';
    PGPBAT = 'XPGP.BAT';
    pgptmpbatch = 'PGPTMP.BAT';
  {$endif}
var
  path : string;
  f:text;
begin
  if exist(PGPBAT) then
    path:=PGPBAT
  else begin
    path:=getenv('PGPPATH');
    if (path<>'') then begin
      if (lastchar(path)='\') then dellast(path);
      path:=fsearch(PGPEXE,path)
    end;
    if (path='') then
      path:=fsearch(PGPEXE,getenv('PATH'));
  end;
  if (path='') then
    trfehler(217,errortimeout)    { 'PGP fehlt oder ist nicht per Pfad erreichbar.' }
  else begin
    if (PGPVersion=PGP2) then
      path:=path+iifs(PGPbatchmode,' +batchmode ',' ')+par
    else
      path:=path+' '+par;
    shellkey:=PGP_WaitKey;
    if (PGP_Passphrase<>'') then begin
      assign(f,pgptmpbatch);
      rewrite(f);
      if (ioresult=0) then begin
        {$ifdef linux}
        writeln(f,'#!/bin/sh');
        { folgende Zeile mu� vielleicht noch angepa�t werden:}
        writeln(f,'SET PGPPASS='+PGP_Passphrase);
        {$else}
        writeln(f,'@echo off');
        writeln(f,'SET PGPPASS='+PGP_Passphrase);
        {$endif}
        writeln(f,path);
        writeln(f,'SET PGPPASS=');
        path:=pgptmpbatch;
        close(f)
      end
    end;
    shell(path,500,1);
    shellkey:=false;
    ExWipe(pgptmpbatch)
  end;
end;


{ PGP 5.x }
procedure RunPGP5(exe,par:string);
var path : string;
    pass,batch : string;
    {$ifdef linux}
    dir : dirstr;
    name : namestr;
    ext : extstr;
    {$endif}
begin
  {$ifdef linux}
  fsplit(exe,dir,name,ext);
  exe:=LStr(name); { aus PGPK.EXE wird pgpk etc ...}
  {$endif}
  path:=getenv('PGPPATH');
  if (path<>'') then begin
    if (lastchar(path)='\') then dellast(path);
    path:=fsearch(exe,path);
  end;
  if (path='') then
    path:=fsearch(exe,getenv('PATH'));
  if (path='') then
    trfehler1(3001,exe,errortimeout)   { '%s fehlt oder ist nicht per Pfad erreichbar.' }
  else begin
    shellkey:=PGP_WaitKey;
    pass:='';
    if (getPGPPassphrase(false)) then pass:='"'+PGP_Passphrase+'"';
    case UpCase(exe[4]) of
      'E' : batch := ' -z '+pass+' ';
      'K' : batch := ' -z ';
      'O' : batch := ' -z '+pass+' ';
      'S' : batch := ' -z '+pass+' ';
      'V' : begin
        if (getPGPPassphrase(true)) then pass:='"'+PGP_Passphrase+'"';
        batch := ' -z '+pass+' ';
      end;
    end;
    (* shell(path+iifs(PGPbatchmode,batch,' ')+par,2048{500},1); *)
    shell(path+batch+par,2048{500},1);
    shellkey:=false;
  end;
end;


{ GPG }
procedure RunGPG1(par:string);
const
  {$ifdef linux}
    PGPEXE = 'gnupg';
    PGPBAT = 'xgpg.sh';
    pgptmpbatch = 'GPGTMP.sh';
  {$else}
    PGPEXE = 'GPG.EXE';
    PGPBAT = 'XGPG.BAT';
    pgptmpbatch = 'GPGTMP.BAT';
  {$endif}
var
  path : string;
  f:text;
begin
  if exist(PGPBAT) then
    path:=PGPBAT
  else begin
    path:=getenv('PGPPATH');
    if (path<>'') then begin
      if (lastchar(path)='\') then dellast(path);
      path:=fsearch(PGPEXE,path)
    end;
    if (path='') then
      path:=fsearch(PGPEXE,getenv('PATH'));
  end;
  if (path='') then
    trfehler(217,errortimeout)    { 'PGP fehlt oder ist nicht per Pfad erreichbar.' }
  else begin
    path:=path+iifs(PGPbatchmode,' --batch ',' ')+par;
    shell(path,500,1);
    shellkey:=false;
    ExWipe(pgptmpbatch)
  end
end;


{ User-ID f�r Command-Line-Aufruf in Anf�hrungszeichen setzen }
function IDform(s:string):string;
begin
  if multipos(' /<>|',s) then begin
    if (firstchar(s)<>'"') then s:='"'+s;
    if (lastchar(s)<>'"') then s:=s+'"'
  end;
  IDform:=s
end;


procedure UpdateKeyfile;
var secring : string;
begin
  if UsePGP and (PGP_UserID<>'') then begin
    secring:=fsearch('PUBRING.PGP',getenv('PGPPATH'));
    if (secring<>'') and (filetime(secring)>filetime(PGPkeyfile)) then begin
      if exist(PGPkeyfile) then _era(PGPkeyfile);
      if exist(PGPkeyfileAscii) then _era(PGPkeyfileAscii);
      if (PGPVersion=PGP2) then begin
        RunPGP('-kx +armor=off '+IDform(PGP_UserID)+' '+PGPkeyfile);
        RunPGP('-kxa +armor=on '+IDform(PGP_UserID)+' '+PGPkeyfileAscii)
      end else if (PGPVersion=PGP5) then begin
        RunPGP5('PGPK.EXE','-x +armor=off '+IDform(PGP_UserID)+' -o '+PGPkeyfile);
        RunPGP5('PGPK.EXE','-xa +armor=on '+IDform(PGP_UserID)+' -o '+PGPkeyfileAscii)
      end else if (PGPVersion=GPG1) then begin
        RunGPG1('--extract '+IDform(PGP_UserID)+' '+PGPkeyfile);
        RunGPG1('--extract --armor '+IDform(PGP_UserID)+' '+PGPkeyfileAscii)
      end
    end
    { #### PGP6 ? #### }
  end
end;

procedure WritePGPkey_body(var t:text);      { PGP-PUBLIC-KEY: ... erzeugen   }
  var
    t1   : text;
    line : string[90];
begin
  if exist(PGPkeyfileAscii) then begin
    assign(t1,PGPkeyfileAscii);
    reset(t1);
      while not eof(t1) do begin
        readln(t1,line);
        writeln(t,line);
      end;
    close(t1);
  end;
end;

procedure WritePGPkey_header(var f:file);    { PGP-PUBLIC-KEY: ... erzeugen }
var kf  : file;
    dat : array[0..29] of byte;
    rr  : word;
    i,j : integer;
    s   : string;
    b64 : array[0..63] of char;

  procedure wrs(s:string);
  begin
    blockwrite(f,s[1],length(s));
  end;

begin
  UpdateKeyfile;
  if (savekey<>'') and exist(savekey) then
    assign(kf,savekey)
  else
    assign(kf,PGPkeyfile);
  if existf(kf) then begin
    wrs('PGP-PUBLIC-KEY: ');
    b64:='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    reset(kf,1);
    while not eof(kf) do begin
      fillchar(dat,sizeof(dat),0);
      blockread(kf,dat,30,rr);
      i:=0; j:=0;
      while (i<rr) do begin
        s[j+1]:=b64[dat[i] shr 2];
        s[j+2]:=b64[(dat[i] and 3) shl 4 + dat[i+1] shr 4];
        if (i+1<rr) then s[j+3]:=b64[(dat[i+1] and 15) shl 2 + dat[i+2] shr 6]
          else s[j+3]:='=';
        if (i+2<rr) then s[j+4]:=b64[dat[i+2] and 63]
          else s[j+4]:='=';
        inc(i,3);
        inc(j,4);
      end;
      s[0]:=chr(j);
      wrs(s)
    end;
    close(kf);
    wrs(#13#10)
  end
end;


procedure PGP_SendKey(empfaenger:string;bin:boolean);   { Antwort auf Key-Request senden }
var t   : text;
    tmp : string;
    hd  : string[12];
begin
  UpdateKeyfile;
  if not exist(PGPkeyfile) then exit;
  tmp:=TempS(4096);
  assign(t,tmp);
  rewrite(t);
  writeln(t);
  if not bin then begin
    if not exist(PGPkeyfileAscii) then begin
      close(t);
      if exist(tmp) then _era(tmp);
      tfehler(PGPkeyfileAscii+' nicht vorhanden',errortimeout);
      exit;
    end;
    WritePGPkey_body(t);
  end
  else begin
    writeln(t,getres2(3000,2));   { 'Der Header dieser Nachricht enth�lt den angeforderten PGP-Public-Key.' }
    writeln(t,getres2(3000,3));   { 'Diese Nachricht wurde von CrossPoint automatisch erzeugt.' }
  end;
  writeln(t);
  close(t);
  hd:='';
  if DoSend(true,tmp,empfaenger,getres2(3000,1),  { 'Antwort auf PGP-Key-Anforderung' }
            false,false,false,false,true,nil,
            hd,hd,SendPGPkey) then
    LogPGP(getreps2(3002,1,empfaenger));   { 'sende Public Key an %s' }
  if exist(tmp) then _era(tmp);
  freeres;
end;


{ Text aus 'source' codieren bzw. signieren und zusammen mit }
{ Header 'hd' in Datei 'fn' ablegen.                         }
{ Bei Fido-Nachrichten Origin abschneiden und nach Codierung }
{ / Signierung wieder anh�ngen.                              }

procedure PGP_EncodeFile(var source:file; var hd:xp0.header;
                         fn,UserID:string; encode,sign:boolean;
                         var fido_origin:string);
var tmp  : string;
    f,f2 : file;
    b    : byte;
    nt   : longint;
    t    : string[20];
    uid  : string[80];
    _source: string;

  procedure StripOrigin;
  begin
    reset(source,1);
    seek(source,filesize(source)-length(fido_origin)-2);
    truncate(source);
    close(source);
  end;

  procedure AddOrigin;
  var f : file;
      s : string;
  begin
    assign(f,tmp);
    if existf(f) then begin
      reset(f,1);
      seek(f,filesize(f));
      s:=fido_origin+#13#10;
      blockwrite(f,s[1],length(s));
      close(f)
    end
  end;

begin
  if (UserID='') then                     { User-ID ermitteln }
    UserID:=hd.empfaenger;
  if (pos('/',UserID)>0) then UserID:=''; { Empfaenger ist Brett }

  fm_ro; reset(source,1); fm_rw;
  tmp:=TempS(filesize(source)*2);         { Temp-Dateinamen erzeugen }
  close(source);

  if (fido_origin<>'') then StripOrigin;
  if (PGPVersion=GPG1) then
    t:=iifs(hd.typ='T','a','')
  else if (PGPVersion=PGP2) then
    t:=iifs(hd.typ='T','t',' +textmode=off')
  else
    t:=iifs(hd.typ='T','-t','');

  if (PGP_UserID<>'') then
    uid:=' -u '+IDform(PGP_UserID)
  else
    uid:='';

  { --- codieren --- }
  if encode and not sign then begin
    if (PGPVersion=PGP2) then
      RunPGP('-ea'+t+' '+filename(source)+' '+IDform(UserID)+' -o '+tmp)
    else if (PGPVersion=PGP5) then
      RunPGP5('PGPE.EXE','-a '+t+' '+filename(source)+' -r '+IDform(UserID)+' -o '+tmp)
    else if (PGPVersion=GPG1) then
      RunGPG1('-e'+t+' -o '+tmp+' -r '+IDform(UserID)+' '+PGP_GPGEncodingOptions+' '+filename(source))
    else begin
      { Sourcefile xxxx.TMP nach xxxx kopieren }
      _source:=GetFileDir(filename(source))+GetBareFileName(filename(source));
      copyfile(filename(source),_source);
      { Ausgabedateiname ist _source'.asc' }
      RunPGP('-e -a '+t+' '+_source+' '+IDform(UserID));
      ExErase(tmp);         { xxxx wieder loeschen }
      tmp:=_source+'.asc'
    end;

  { --- signieren --- }
  end else if sign and not encode then begin
    if (PGPVersion=PGP2) then
      RunPGP('-sa'+t+' '+filename(source)+uid+' -o '+tmp )
    else if (PGPVersion=PGP5) then
      RunPGP5('PGPS.EXE','-a '+t+' '+filename(source)+uid+' -o '+tmp)
    else if (PGPVersion=GPG1) then
      RunGPG1(iifs(hd.typ='T','--clearsign','-s')+' --force-v3-sigs -o '+tmp+' -u '+uid+' '+filename(source))
    else begin
      { Sourcefile xxxx.TMP nach xxxx kopieren }
      _source:=GetFileDir(filename(source))+GetBareFileName(filename(source));
      copyfile(filename(source),_source);
      ExErase(filename(source));
      { Ausgabedateiname ist _source'.asc' }
      RunPGP('-s -a '+t+' '+_source+' '+IDform(UserID)+uid);
      ExErase(getbarefilename(tmp));  { Tempor�rdatei l�schen }
      ExErase(_source);
      ExErase(tmp);                   { xxxx wieder loeschen }
      tmp:=_source+'.asc'
    end;

  { --- codieren+signieren --- }
  end else begin
    if (PGPVersion=PGP2) then
      RunPGP('-esa'+t+' '+filename(source)+' '+IDform(UserID)+uid+' -o '+tmp)
    else if (PGPVersion=PGP5) then
      RunPGP5('PGPE.EXE','-sa '+t+' '+filename(source)
              +' -r '+IDform(UserID)+uid+' -o '+tmp)
    else if (PGPVersion=GPG1) then
      RunGPG1('-es'+t+' --force-v3-sigs -o '+tmp+' -u '+uid
              +' -r '+IDform(UserID)+' '+PGP_GPGEncodingOptions
              +' '+filename(source))
    else begin
      { Sourcefile xxxx.TMP nach xxxx kopieren }
      _source:=GetFileDir(filename(source))+GetBareFileName(filename(source));
      copyfile(filename(source),_source);
      { Ausgabedateiname ist _source'.asc' }
      RunPGP('-e -s -a '+t+' '+_source+' '+IDform(UserID)+uid);
      ExErase(tmp);         { xxxx wieder loeschen }
      tmp:=_source+'.asc'
    end
  end;

  if (fido_origin<>'') then AddOrigin;

  if exist(tmp) then begin
    hd.groesse:=_filesize(tmp);               { Gr��e anpassen }
    hd.crypttyp:=hd.typ; hd.typ:='T';         { Typ anpassen   }
    hd.ccharset:=hd.charset; hd.charset:='';  { Charset anpassen }
    hd.ckomlen:=hd.komlen; hd.komlen:=0;      { KOM anpassen   }
    if encode then inc(hd.pgpflags,fPGP_encoded);
    if sign then inc(hd.pgpflags,iif(encode,fPGP_signed,fPGP_clearsig));
    assign(f,fn);
    rewrite(f,1);
    WriteHeader(hd,f,_ref6list);          { neuen Header erzeugen }
    assign(f2,tmp);
    reset(f2,1);
    fmove(f2,f);                          { ... und codierte Datei dranh�ngen }
    close(f2);
    close(f);
    ExErase(tmp);         { Tempor�rdatei l�schen }
    if encode then begin
      dbReadN(mbase,mb_unversandt,b);
      b:=b or 4;                            { 'c'-Kennzeichnung }
      dbWriteN(mbase,mb_unversandt,b)
    end;
    if sign then begin
      dbReadN(mbase,mb_netztyp,nt);
      nt:=nt or $4000;                      { 's'-Kennzeichnung }
      dbWriteN(mbase,mb_netztyp,nt)
    end
  end else
    rfehler(3002)      { 'PGP-Codierung ist fehlgeschlagen.' }
end;


procedure PGP_RequestKey;
var user : string[AdrLen];
    x,y  : byte;
    brk  : boolean;
    tmp  : string;
    t    : text;
    hd   : string[12];
    ok   : boolean;
    nt   : byte;
begin
  case aktdispmode of
    1..4   : if dbEOF(ubase) or dbBOF(ubase) then
               user:=''
             else
               user:=dbReadStr(ubase,'username');
    10..19 : if dbEOF(mbase) or dbBOF(mbase) then
               user:=''
             else
               user:=dbReadStr(mbase,'absender');
    else     user:='';
  end;
  dialog(58,3,getres2(3001,1),x,y);   { 'PGP-Key anfordern bei ...' }
  maddstring(3,2,'',user,52,AdrLen,''); mhnr(93);
  mappcustomsel(seluser,false);
  ccte_nobrett:=true;
  msetvfunc(cc_testempf);
  ok := false; { mk 12/99 }
  repeat
    readmask(brk);
    if not brk then begin
      dbSeek(ubase,uiName,ustr(user));
      nt:=ntBoxNetztyp(dbReadStr(ubase,'pollbox'));
      ok:=not dbFound or ntPGP(nt);
      if not ok then
        rfehler1(3003,ntname(nt));   { 'Beim Netztyp %s wird PGP nicht unterst�tzt.' }
      end;
  until brk or ok;
  ccte_nobrett:=false;
  closemask;
  closebox;
  if not brk then begin
    tmp:=TempS(1024);
    assign(t,tmp);
    rewrite(t);
    writeln(t);
    if (nt in [nt_PPP,nt_UUCP]) then begin
      writeln(t,getres2(3001,7)); { 'Wenn sie diese Nachricht erhalten und Ihre Software so konfiguriert' }
      writeln(t,getres2(3001,8)); { 'haben, da� Sie auf dem Betreff: "PGP-Keyanforderung", wie in CrossPoint' }
      writeln(t,getres2(3001,9)); { '�blich, daraufhin mit dem Versenden des Public Key antwortet, brauchen' }
      writeln(t,getres2(3001,10));{ 'Sie nichts weiter zu tun.' }
    end else begin
      writeln(t,getres2(3001,3));  { 'Falls Ihre Software PGP nach dem ZCONNECT-Standard unterst�tzt,' }
      writeln(t,getres2(3001,4));  { 'sollte sie auf diese Nachricht mit dem Verschicken Ihres PGP' }
      writeln(t,getres2(3001,5));  { 'Public Key antworten.' }
    end;
    writeln(t);
    writeln(t,getres2(3001,6));  { '- automatisch erzeugte Nachricht -' }
    writeln(t);
    close(t);
    hd:='';
    if DoSend(true,tmp,user,getres2(3001,2),  { 'PGP-Keyanforderung' }
              false,false,false,false,true,nil,
              hd,hd,SendPGPreq) then;
    ExErase(tmp)
  end;
  freeres
end;


function IsBinaryFile(fn:string):boolean;
const bufs  = 2048;                      {         Steuerzeichen }
var   f     : file;
      isbin : boolean;
      buf   : charrp;
      rr    : word;
begin
  assign(f,fn);
  reset(f,1);
  getmem(buf,bufs);
  isbin:=false;
  while not isbin and not eof(f) do begin
    blockread(f,buf^,bufs,rr);
    if (rr>0) then
      isbin:=testbin(buf^,rr);
  end;
  close(f);
  freemem(buf,bufs);
  IsBinaryFile:=isbin
end;


procedure PGP_DecodeMessage(hdp:headerp; sigtest:boolean);
var tmp,tmp2 : string;
    _source  : string;
    f,f2     : file;
    orgsize  : longint;
    b        : byte;
    l        : longint;
    pass     : string;

  procedure WrSigflag(n:byte);
  var l : longint;
  begin
    dbReadN(mbase,mb_flags,l);
    l:=l or n;
    dbWriteN(mbase,mb_flags,l);
  end;

begin
  tmp:=TempS(dbReadInt(mbase,'groesse'));
  assign(f,tmp);
  rewrite(f,1);
  XreadF(dbReadInt(mbase,'msgsize')-dbReadInt(mbase,'groesse'),f);
  close(f);
  tmp2:=TempS(dbReadInt(mbase,'groesse'));

  if sigtest then
    PGP_WaitKey:=true;

  pass:='';
  if (PGPVersion=PGP2) then begin
    { Passphrase nicht bei Signaturtest }
    if not sigtest then begin
      if (getPGPPassphrase(true)) then pass:='"'+PGP_Passphrase+'"';
    end;
    RunPGP(tmp+' '+pass+' -o '+tmp2)
    
    { erwartet passphrase im Environment: }
    { #### RunPGP(tmp+' -o '+tmp2) }
    
  end else if (PGPVersion=PGP5) then
    RunPGP5('PGPV.EXE', tmp+' -o '+tmp2)
  else if (PGPVersion=GPG1) then
    RunGPG1('-o '+tmp2+' '+tmp)
  else begin { PGP 6.* }
    { Sourcefile xxxx.TMP nach xxxx kopieren }
    _source:=GetFileDir(tmp)+GetBareFileName(tmp)+'.asc';
    copyfile(tmp,_source);
    { Ausgabedateiname = tmp ohne ext }
    RunPGP(_source+' '+tmp2);
    tmp2:=GetFileDir(tmp2)+GetBareFileName(_source);
  end;

  if sigtest then begin
    PGP_WaitKey:=false;
    ExErase(tmp);
    ExErase(_source)
  end;
  
  if not exist(tmp2) then begin { Oops, keine Ausgabedatei: }
    { Signaturtest-Fehler }
    if sigtest then begin
      if (errorlevel=18) then begin
        trfehler(3007,errortimeout_short);  { 'PGP meldet ung�ltige Signatur!' }
        WrSigflag(flag_PGPSigErr);      { Signatur fehlerhaft }
      end else
        trfehler(3007,errortimeout_short)   { '�berpr�fung der PGP-Signatur ist fehlgeschlagen' }
    { Dekodierungs-Fehler }
    end else
      trfehler(3004,errortimeout_short);     { 'PGP-Decodierung ist fehlgeschlagen.' }
  
  end else begin { Ausgabedatei korrekt geschrieben: }
    if not SigTest then begin
      PGP_BeginSavekey;
      orgsize:=hdp^.groesse;
      hdp^.groesse:=_filesize(tmp2);
      hdp^.komlen:=hdp^.ckomlen; hdp^.ckomlen:=0;
      hdp^.typ:=iifc(IsBinaryFile(tmp2),'B','T'); hdp^.crypttyp:='';
      hdp^.pgpflags:=hdp^.pgpflags and (not (fPGP_encoded+fPGP_signed+fPGP_clearsig));
      if (hdp^.ccharset<>'') then begin
        hdp^.charset:=ustr(hdp^.ccharset);
        hdp^.ccharset:=''
      end
    end;
    
    { Signaturtest oder Fehler: }
    if sigtest or (errorlevel=18) then begin
      { Fehler: }
      if (errorlevel<>0) then begin
        hdp^.pgpflags := hdp^.pgpflags or fPGP_sigerr;
        WrSigflag(flag_PGPSigErr);
      end else begin
        hdp^.pgpflags := hdp^.pgpflags or fPGP_sigok;
        WrSigflag(flag_PGPSigOk);
      end
    end;
    
    if sigtest then begin
      dbReadN(mbase,mb_netztyp,l);
      l:=l or $4000;                      { Flag f�r 'Signatur vorhanden' }
      dbWriteN(mbase,mb_netztyp,l)
    end else begin
      rewrite(f,1);          { alte Datei �berschreiben }
      WriteHeader(hdp^,f,reflist); { Header erstellen f�r tmp }
      assign(f2,tmp2);
      reset(f2,1);
      fmove(f2,f);           { PGP Ausgabe an tmp anh�ngen }
      close(f2);
      close(f);
      ExWipe(tmp2);          { PGP Ausgabe l�schen }
      Xwrite(tmp);           { tmp -> puffer }
      wrkilled;
      dbWriteN(mbase,mb_typ,hdp^.typ[1]);
      dbWriteN(mbase,mb_groesse,hdp^.groesse);
      dbReadN(mbase,mb_unversandt,b);
      b:=b or 4;                          { "c"-Flag }
      dbWriteN(mbase,mb_unversandt,b);
      hdp^.groesse:=orgsize;
      PGP_EndSavekey
    end
  end;
  { Aufr�umen: }
  ExWipe(tmp);
  ExWipe(tmp2);
  ExErase(_source)
end;


procedure PGP_DecodeMsg(sigtest:boolean);
var hdp : headerp;
    hds : longint;
begin
  new(hdp);
  ReadHeader(hdp^,hds,true);
  PGP_DecodeMessage(hdp,sigtest);
  dispose(hdp);
  aufbau:=true
end;


{ Key aus ZCONNECT-Header auslesen und in Bin�rdatei speichern }

procedure PGP_DecodeKey(source,dest:string);
const b64tab : array[43..122] of byte =         (63, 0, 0, 0,64,
                53,54,55,56,57,58,59,60,61,62, 0, 0, 0, 0, 0, 0,
                 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,
                16,17,18,19,20,21,22,23,24,25,26, 0, 0, 0, 0, 0,
                 0,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                42,43,44,45,46,47,48,49,50,51,52);
var t     : text;
    f     : file;
    p,n   : integer;
    dec   : array[0..29] of byte;
    s     : string;
    found : boolean;
    b1,b2,
    b3,b4 : byte;
    eob   : byte;

  function getbyte:byte;
  var c  : char;
  begin
    c:=s[p];
    inc(p);
    if (p>length(s)) then begin
      if eoln(t) then s:=''
      else read(t,s);
      p:=1;
      end;
    if (c='=') then inc(eob);
    if (c<'+') or (c>'z') or (b64tab[ord(c)]=0) then
      getbyte:=0
    else
      getbyte:=b64tab[ord(c)]-1
  end;

begin
  assign(t,source);
  if not existf(t) then exit;
  reset(t);
  repeat
    read(t,s);
    found:=(left(lstr(s),15)='pgp-public-key:');
    if not found then readln(t);
  until found or eof(t);
  if found then begin
    assign(f,dest);
    rewrite(f,1);
    s:=trim(mid(s,16));
    p:=1;
    n:=0;
    eob:=0;
    repeat
      b1:=getbyte; b2:=getbyte; b3:=getbyte; b4:=getbyte;
      dec[n]:=b1 shl 2 + b2 shr 4;
      dec[n+1]:=(b2 and 15) shl 4 + b3 shr 2;
      dec[n+2]:=(b3 and 3) shl 6 + b4;
      inc(n,3-eob);
      if (n=30) then begin
        blockwrite(f,dec,30);
        n:=0
      end
    until (p>length(s));
    if n>0 then blockwrite(f,dec,n);
    close(f)
  end;
  close(t)
end;


procedure PGP_ImportKey(auto:boolean);
var hdp      : headerp;
    hds      : longint;
    tmp,tmp2 : string;
    mk       : boolean;
begin
  tmp:=TempS(dbReadInt(mbase,'msgsize'));
  new(hdp);
  ReadHeader(hdp^,hds,true);
  if (hdp^.pgpflags and fPGP_haskey = 0) then
    extract_msg(xTractMsg,'',tmp,false,0)
  else begin
    tmp2:=TempS(dbReadInt(mbase,'msgsize'));
    extract_msg(xTractPuf,'',tmp2,false,0);
    PGP_DecodeKey(tmp2,tmp);
    if exist(tmp2) then _era(tmp2);
  end;
  if not exist(tmp) then
    rfehler(3005)         { 'Fehler beim Auslesen des PGP-Keys' }
  else begin
    if auto then          { 'lese Key aus Nachricht %s von %s ein' }
      LogPGP(reps(getreps2(3002,3,'<'+hdp^.msgid+'>'),hdp^.absender));
    mk:=PGP_WaitKey;
    if not auto then PGP_WaitKey:=true;
    
    if (PGPVersion=GPG1) then
      RunGPG1('--import '+tmp)
    else if (PGPVersion=PGP5) then
      RunPGP5('PGPK.EXE','-a '+tmp)
    else
      RunPGP('-ka '+tmp);

    PGP_WaitKey:=mk;
    if exist(tmp) then _era(tmp);
  end;
  dispose(hdp);
end;


procedure PGP_EditKey;
var bm : boolean;
begin
  bm:=PGPBatchMode;
  PGPBatchMode:=false;
  if (PGPVersion=PGP5) then
    RunPGP5('PGPK.EXE','-e '+IDform(PGP_UserID))
  else if (PGPVersion=GPG1) then
    RunGPG1('--edit-key '+IDform(PGP_UserID))
  else 
    RunPGP('-ke '+IDform(PGP_UserID));
  PGPBatchMode:=bm;
end;


procedure PGP_RemoveID;
var bm : boolean;
begin
  bm:=PGPBatchMode;
  PGPBatchMode:=false;
  if (PGPVersion=GPG1) then
    RunGPG1('--delete-key '+IDform(PGP_UserID))
  else if (PGPVersion=PGP5) then
    RunPGP5('PGPK.EXE','-ru '+IDform(PGP_UserID))
  else
    RunPGP('-kr '+IDform(PGP_UserID));

  PGPBatchMode:=bm
end;


procedure PGP_BeginSavekey;      { Key aus ZCONNECT-Header tempor�r sichern }
var hdp : headerp;
    hds : longint;
    tmp : string;
begin
  new(hdp);
  ReadHeader(hdp^,hds,false);
  if (hdp^.pgpflags and fPGP_haskey<>0) then begin
    tmp:=TempS(dbReadInt(mbase,'msgsize'));
    extract_msg(xTractPuf,'',tmp,false,0);
    savekey:=TempS(hds);
    PGP_DecodeKey(tmp,savekey);
    if exist(tmp) then _era(tmp)
  end;
  dispose(hdp)
end;


procedure PGP_EndSavekey;
begin
  if (savekey<>'') and exist(savekey) then
    _era(savekey);
  savekey:=''
end;


end.
{
  $Log: xp_pgp.pas,v $
  Revision 1.20  2001/06/18 20:10:04  oh
  OH: GPG-Fixes (von Malte Kiesel), Sign All geht jetzt wieder

  Revision 1.19  2001/04/04 19:57:04  oh
  -Timeouts konfigurierbar

  Revision 1.18  2001/03/22 16:56:02  oh
  - PGP cleanup

  Revision 1.17  2000/11/11 15:06:23  oh
  -Source verschoenert

  Revision 1.16  2000/11/09 22:05:58  oh
  -First try with GnuPG - please test it!

  Revision 1.15  2000/10/15 09:14:39  oh
  -PGP-Anpassung

  Revision 1.14  2000/10/14 10:04:40  oh
  -PGP-Update, PGPPASS nach PGP-Aufruf loeschen

  Revision 1.13  2000/10/13 20:35:11  oh
  -PGP Update

  Revision 1.12  2000/10/12 21:44:43  oh
  -PGP-Passphrase merken + Screenshot-File-Verkleinerung

  Revision 1.11  2000/07/30 16:14:50  MH
  RFC/PGP: Jetzt auch im PGP-Men�

  Revision 1.10  2000/07/28 17:27:05  MH
  RFC/PPP/UUCP:
  - PGP-Key kann angefordert und automatisch versendet werden
    (Entsprechende Schalter noch nicht implementiert)

  Revision 1.9  2000/07/28 14:54:51  MH
  Inkonstistenz beseitigt und Header ausgetauscht

  Revision 1.8  2000/07/09 08:45:55  MH
  Fehlermeldungsnummer korrigiert

  Revision 1.7  2000/05/12 19:44:27  oh
  -PGP und Feldtausch komplett

  Revision 1.5  2000/04/17 12:30:54  oh
  - PGP 2.6.x, 5.x, 6.5.x jetzt komplett

  Revision 1.13  2000/04/04 21:01:24  mk
  - Bugfixes f�r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.12  2000/03/24 15:41:02  mk
  - FPC Spezifische Liste der benutzten ASM-Register eingeklammert

  Revision 1.11  2000/03/24 04:15:22  oh
  - PGP 6.5.x Unterstuetzung

  Revision 1.10  2000/03/19 12:05:42  oh
  + Flags c und s werden korrekt gesetzt
  + 2.6.x/5.x: Signatur pr�fen/Nachricht dekodieren �ber N/G/(S/d).
  + Bug behoben: es wurde kodiert/signiert statt signiert und umgekehrt.

  Revision 1.9  2000/03/17 11:16:34  mk
  - Benutzte Register in 32 Bit ASM-Routinen angegeben, Bugfixes

  Revision 1.8  2000/03/14 15:15:41  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.7  2000/03/06 13:48:38  oh
  - PGP-Fixes

  Revision 1.6  2000/02/19 11:40:08  mk
  - Code aufgeraeumt und z.T. portiert

  Revision 1.5  2000/02/15 20:43:37  mk
  - Aktualisierung auf Stand 15.02.2000

}
