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
{ $Id: xp3o.inc,v 1.92 2002/01/07 08:09:15 mm Exp $ }

{.$DEFINE DBG}     { File: Mu· fÅr folgende Zeilen aktiviert werden! }
{.$DEFINE DBGHDO}  { HeaderOnly: OnwPath+'HDO.DBG' }
{.$DEFINE DBGIMP}  { IMP: OwnPath+'IMPORT.DBG'     }

procedure readpuffer;
var x,y   : byte;
    s     : pathstr;
    brk   : boolean;
    ed,pb : boolean;
    ebest : boolean;
    read  : boolean;
    useclip: boolean;
begin
  s:='*.*';
  useclip:=true;
  if ReadFilename(getres2(330,1),s,true,useclip) then   { 'Puffer einlesen' }
    if not exist(s) then
      rfehler(304)   { 'Datei nicht vorhanden!' }
    else if pos(ustr(AblagenFile),ustr(s))>0 then
      rfehler(305)   { 'Interne Ablage - bitte erst umbenennen!' }
    else begin
      dialog(46,6,fitpath(s,38),x,y);
      ed:=false; pb:=true;
      ebest:=false; read:=false;
      maddbool(3,2,getres2(330,2),ed); mhnr(101);   { 'Empfangsdatum = Erstellungsdatum' }
      maddbool(3,3,getres2(330,3),pb);     { 'Server aus Pfad Åbernehmen' }
      maddbool(3,4,getres2(330,4),ebest);  { 'EmpfangsbestÑtigungen versenden' }
      maddbool(3,5,getres2(330,5),read);   { 'Nachrichten als "gelesen" markieren' }
      readmask(brk);
      closemask;
      closebox;
      if not brk then
        if puffereinlesen(s,iifs(pb,'',DefaultBox),ed,false,ebest,
                          iif(read,pe_gelesen,0)) then
          signal;
      if useclip then _era(s);
      end;
  freeres;
end;


{ Pollbox='' -> Pollbox wird aus Pfad Åbernommen, falls vor-  }
{               handen, sonst aus DefaultBox                  }
{ Replace-ED :  Empfangsdatum durch Erstellungsdatum ersetzen }

function  PufferEinlesen(puffer:pathstr; pollbox:string; replace_ed,
                         sendbuf,ebest:boolean; pflags:word):boolean;

const
{$IFDEF BP }
  bufsize  = 32768;
{$ELSE }
  bufsize  = 262144; { 256kb Puffer unter 32 Bit ist ok }
{$ENDIF }
  maxll    = 64;

var x,y,fm   : byte;
    f,pfile  : file;
    llbuf    : array[1..maxll] of longint;
    llanz    : integer;
    padr,size: longint;
    ablage   : byte;
    abadd    : byte;
    p        : charrp;
    adr,fs,l : longint;
    hdp      : headerp;
    i        : integer;
    hdsize   : longint;
    rr       : word;
    dat      : string[11];
    tobrett  : boolean;
    typ1     : char;
    ok       : boolean;
    name     : string[AdrLen];
    adrbuch  : byte;
    flags,atp: byte;
    pb       : string[20];
    grnr     : longint;
    _brett   : string[5];
    ld       : longint;
    uflags   : byte;
    aufnehmen: boolean;
    diff     : integer;
    d        : DB;
    haltezeit: integer16;
    MsgCount : longint;
    {$IFDEF DBG}
    dbg,  { DebugCode! }
    {$ENDIF}
    hdo,                      { HDOKILL.NOW }
    brettlog,
    userlog  : text;
    _datum   : longint;
    mapsname : string[20];
    check    : boolean;
    seekbr   : string[BrettLen];
    p0       : byte;
    zconnect : boolean;
    pm       : boolean;
    mnt      : longint;       { Netztyp-Feld fÅr mbase }
    msgid2   : string[19];    { gekÅrzte MsgID (FormMsgid) fÅr mbase }
    _msgid   : string[midlen];
    today    : longint;
    empfnr   : integer;
    junk     : boolean;
    msgsent  : boolean;
    amvertreter,
    pmvertreter : string[BoxnameLen];
    forcepfadbox: boolean;
    sysbetreff  : string[50];  { Betreff von Changesys/getsys }
    IsGelesen   : boolean;
    cancelfile  : text;
    cancels     : integer;
    orgempf  : string[AdrLen];
    mbflags  : longint;
    abs      : string[80];
    scrflag  : byte;
    nt       : byte;
    hdorec   : longint;
    haskill  : boolean;
    svpollbox: string[BoxNameLen];
    fqdn_    : string[60];
    repown   : boolean;

  procedure KillHdrOnly(msgid:string;rec:longint;delflag:boolean);
  var
    delpos     : longint;
    hdp        : headerp;
    hds,flags  : longint;
    mrec       : longint;
    brec       : longint;
    mi         : shortint;
    bi         : word;
    stop       : boolean;
    replown    : boolean;
    {exmore     : boolean;}
    wvl,_wvl   : byte;
    hflags     : byte;
    wvdat      : longint;

    function Oki:boolean;
    begin
      dbReadN(mbase,mb_flags,flags); { Flags holen }
      {dbReadN(mbase,mb_unversandt,wvl);}
      Oki:=((hdp^.msgid=msgid) and ((UStr(hdp^.xpmode)='HDRONLY') or
           (UStr(hdp^.xpmode)='TOPOFMAIL')) and
           (hdp^.groesse=0) and (flags and 128<>0)) or { R-Flag }
           ((hdp^.msgid=msgid) and replown {and exmore} and
           (ustr(hdp^.xpmode)<>'REPLACEOWN') and (flags and 256<>0));
           {(ustr(hdp^.xpmsg)='MYMAIL') and (wvl and 8=0));}
    end;
    (*
    function existmore:boolean;
    var i       : integer;
        replpos : longint;
    begin
      i:=0;
      dbSeek(bezbase,beiMsgid,dbLongStr(MsgidIndex(msgid)));
      if dbFound then begin
        repeat
          dbReadN(bezbase,bezb_msgpos,replpos);
          if not dbDeleted(mbase,replpos) then begin
            dbGo(mbase,replpos);
            {dbReadN(mbase,mb_unversandt,wvl);
            if (wvl and 8=0) then} inc(i);
            dbNext(bezbase);
          end;
        until dbEOF(bezbase) or
              (dbReadInt(bezbase,'msgid')<>MsgidIndex(msgid));
        dbGoTop(mbase);
        dbGoTop(bezbase);
      end;
      if i>1 then existmore:=true else
      existmore:=false;
    end;
    *)
  begin
   {$IFDEF DBGHDO}
     writeln(dbg,msgid+' -:- '+strs(rec));
   {$ENDIF}
    brec:=dbRecno(bezbase);
    mrec:=dbRecno(mbase);
    bi:=dbGetIndex(bezbase);
    dbSetIndex(bezbase,beiMsgID);
    mi:=dbGetIndex(mbase);
    dbSetIndex(mbase,0);
    dbGoTop(mbase);
    dbGoTop(bezbase);
    replown:=(pos('REPLACE:',msgid)=1);
    if (pos('REQUEST:',msgid)=1) or replown then
      msgid:=copy(msgid,9,length(msgid)-8);
    {if replown then exmore:=existmore;}
    new(hdp);
    stop:=false;
    dbSeek(bezbase,beiMsgID,dbLongStr(MsgidIndex(msgid)));
    if dbFound then begin
      repeat
        dbReadN(bezbase,bezb_msgpos,delpos);
        if dbDeleted(mbase,delpos) then stop:=true
        else begin
          dbGo(mbase,delpos);
          readheader(hdp^,hds,false);
          if (hdp^.msgid<>msgid) or not Oki then begin
            dbNext(bezbase);
            stop:=dbEOF(bezbase) or
            (dbReadInt(bezbase,'msgid')<>MsgidIndex(msgid));
          end;
        end;
      until stop or Oki;
    end else delpos:=0;
    if (delpos<>0) and Oki then begin
      if msgmarked then msgUnmark;
      if delflag then begin
        flags:=flags or 64;
        flags:=flags and (not 128);
        dbWriteN(mbase,mb_flags,flags);       { H-Flag setzen    }
      end else
      if rec<>0 then begin
      {$IFDEF DBGHDO}
        writeln(dbg,'KILL erfolgreich...');
      {$ENDIF}
        haskill:=true;
        dbReadN(mbase,mb_halteflags,hflags);
        dbReadN(mbase,mb_unversandt,wvl);
        wrkilled;
        DelBezug;
        dbDelete(mbase);
        dbGo(mbase,rec);
        dbWriteN(mbase,mb_halteflags,hflags);
        wvl:=wvl and (4+8+64+128); { Bin, Crash usw. zurÅcksetzen }
        dbReadN(mbase,mb_unversandt,_wvl);
        wvl:=wvl or _wvl;
        if wvl and 8 <> 0 then begin
          dbReadN(mbase,mb_empfdatum,wvdat);
          dbWriteN(mbase,mb_wvdatum,wvdat);
          wvdat:=ixDat('2712310000');
          dbWriteN(mbase,mb_empfdatum,wvdat);
        end;
        dbWriteN(mbase,mb_unversandt,wvl);
      end;
    end;
    dispose(hdp);
    dbGo(bezbase,brec);
    dbSetIndex(bezbase,bi);
    dbGo(mbase,mrec);
    dbSetIndex(mbase,mi);
    {dbFlushClose(mbase);
    BezugNeuaufbau;
    aufbau:=true;
    xaufbau:=true;}
  end;

  procedure rfdelaktive(msgid:string);
  var
    i          : integer;
  begin
    reqfname:=ownpath+midreqfile;
    if exist(reqfname) then begin
      assign(reqfile,reqfname);
      reset(reqfile);
      if (pos('REQUEST:',msgid)=1) or (pos('REPLACE:',msgid)=1) then
        msgid:=copy(msgid,9,length(msgid)-8);
      for i:=1 to filesize(reqfile) do begin
        read(reqfile,midrec);
        if ((midrec.mid='<'+msgid+'>') and (midrec.zustand in [PPP_AnzReq,255])) then begin
          { bis 199 Versuche, den Artikel gibt es nicht mehr }
          if (midrec.zustand>=PPP_AnzReq) and (midrec.zustand<200) then begin
            close(reqfile); { Flags invertieren }
            KillHdrOnly(copy(midrec.mid,2,length(midrec.mid)-2),0,true);
            reset(reqfile);
            seek(reqfile,i-1);
            read(reqfile,midrec);
          end;
          midrec.zustand:=0;
          midrec.aktiv:=0;
          midrec.mid:='';
          midrec.box:='';
          seek(reqfile,i-1);
          write(reqfile,midrec);
          break;
        end;
      end;
      close(reqfile);
    end;
  end;

  procedure packrfcmsgidfile;
  var
      i,j         : integer;
  begin
    reqfname:=ownpath+midreqfile;
    if not exist(reqfname) then exit;
    assign(reqfile,reqfname);
    reset(reqfile);
    j:=0;
    for i:=1 to filesize(reqfile) do begin
      read(reqfile,midrec);
      if (midrec.zustand>=PPP_AnzReq) and (midrec.zustand<200) then begin { bis 199 Versuche, den Artikel gibt es nicht mehr }
        close(reqfile);
        KillHdrOnly(copy(midrec.mid,2,length(midrec.mid)-2),0,true); { Flags invertieren }
        rfdelaktive(copy(midrec.mid,2,length(midrec.mid)-2));      { und Satz lîschen  }
        reset(reqfile);
        seek(reqfile,i-1);
        read(reqfile,midrec);
      end;
      if midrec.zustand=255 then begin { dÅrfte eigentlich nicht auftreten }
        close(reqfile);
        rfdelaktive(copy(midrec.mid,2,length(midrec.mid)-2)); { Satz lîschen }
        reset(reqfile);
        seek(reqfile,i-1);
        read(reqfile,midrec);
      end;
      if midrec.aktiv<>0 then begin
        inc(j);
        if i<>j then begin
          seek(reqfile,j-1);
          write(reqfile,midrec);
          seek(reqfile,i);
        end;
      end;
    end;
    if j<>filesize(reqfile) then begin
      seek(reqfile,j);
      truncate(reqfile);
    end;
    close(reqfile);
  end;

  function puffer_ok:boolean;
  var ok : boolean;
  begin
    moff;
    writeln;
    write(getres(331));    { 'Puffer ÅberprÅfen...' }
    mon;
    MsgCount:=0; adr:=0;
    repeat
      inc(MsgCount);
      if MsgCount mod 10=0 then
      begin
        moff;
{$IFDEF BP }
        write(MsgCount:6,#8#8#8#8#8#8);
{$ELSE }
        FWrt(WhereX+5, WhereY+5, StrS(MsgCount));
{$ENDIF }
        mon;
      end;
      seek(f,adr);
      makeheader(zconnect,f,0,0,hdsize,hdp^,ok,true);
      inc(adr,hdsize+hdp^.groesse);
    until not ok or (adr>=fs-3);     { Der Puffer kann maximal 3 zusÑtzliche }
    moff;
    if MsgCount>1 then writeln(MsgCount:6)     { Zeichen enthalten, die      }
    else writeln;                              { weggeschluckt werden.       }
    mon;
    puffer_ok:=ok and (adr<=fs+8);
    diff:=min(maxint,max(0,fs-adr));
  end;

{
  procedure writemsg;
  var size : longint;
      rr   : word;
  begin
    dbWriteN(mbase,mb_ablage,ablage);
    dbWriteN(mbase,mb_adresse,padr);
    size:=hdp^.groesse+hdsize;
    dbWriteN(mbase,mb_msgsize,size);
    blockwrite(pfile,p^,min(readfirst,hdsize+hdp^.groesse));
    dec(size,readfirst);
    if size>0 then begin
      repeat
        blockread(f,p^,min(bufsize,size),rr);
        blockwrite(pfile,p^,rr);
        dec(size,rr);
      until size=0;
    end;
    inc(padr,hdp^.groesse+hdsize);
  end;
}

  function pollbox_str(zconnect,user:boolean):string;
  begin
    if not user and (amvertreter<>'') then
      pollbox_str:=amvertreter
    else if user and (pmvertreter<>'') then
      pollbox_str:=pmvertreter
    else if not forcepfadbox and (pollbox<>'') then
      pollbox_str:=pollbox
    else if trim(hdp^.pfad)='' then
      pollbox_str:=DefaultBox
    else
      pollbox_str:=pfadbox(zconnect,hdp^.pfad);
  end;

  function adrok(var s:string):boolean;
  begin
    adrok:=(useraufnahme=0) or
           ((useraufnahme=1) and (pm or ((pos('%',s)=0) and (pos(':',s)=0)))) or
           ((useraufnahme=3) and pm);
  end;

  procedure showbetreff;
  begin
    mwrt(52,wherey,forms(hdp^.betreff,23));
  end;

  procedure wwin;
  begin
    window(x+2,y+1,x+screenwidth-4,y+screenlines-8);
  end;

  function isl(s:string):boolean;
  begin
    isl:=left(hdp^.betreff,length(s))=s;
  end;

  procedure w0;
  begin
    savecursor;
    window(1,1,80,25);
  end;

  procedure w1;
  begin
    wwin;
    restcursor;
  end;

  function LeftAbsender(s:string):boolean;
  begin
    LeftAbsender:=(left(lstr(hdp^.absender),length(s)+1+length(pollbox))=lstr(s+'@'+pollbox));
  end;

  procedure CancelMsg(var id,abs:string);
  var crc  : longint;
      hdp2 : headerp;
      hds  : longint;
      rec  : longint;
      mrec : longint;
      supersedes: boolean;

    procedure DelMsg;
(*
 8. HalteFlags  Byte             0=normal, 1=halten, 2=lîschen
 9. gelesen     Byte        i    1=gelesen
10. unversandt  Byte             Flags: 1=unversandt, 2=BinÑrmeldung, 4=pmCrypt
                                        8=Wiedervorlage, 16=Crash, 32=zurÅckgest.
                                        64=interne Nachricht - keine Statusabfrage
                                        128=gecancelt
*)
    var b1,b2 : byte;
    begin
      if allowcancel=4 then exit;                  { canceln nicht erlaubt }
      dbReadN(mbase,mb_halteflags,b1);
      dbReadN(mbase,mb_unversandt,b2);
      if ((allowcancel and 1)=1) and ((b1 and 1)=1) then exit;
                                                { nicht canceln bei halten }
      if ((allowcancel and 2)=2) and ((b2 and 8)=8) then exit;
                                         { nicht canceln bei Wiedervorlage }
      b1:=1;  dbWriteN(mbase,mb_gelesen,b1);
      b1:=2;  dbWriteN(mbase,mb_halteflags,b1);   { gelîscht }
      dbReadN(mbase,mb_unversandt,b1);
      b1:=b1 or 128;   { gecancelt }
      dbWriteN(mbase,mb_unversandt,b1);
    end;

  begin

    { Ralph Babel Filter. Fremdcancels von Ralph Babel unterbinden }

    if (pos(reverse('nolybab!'),hdp^.pfad)>0) or
       (pos(reverse('lebabr!'),hdp^.pfad)>0) then
      exit;

    if cpos('@',id)=0 then exit;
    supersedes:=left(id,2)='s ';
    delfirst(id);
    delfirst(id);
    if left(id,1)='<' then delfirst(id);
    if right(id,1)='>' then dellast(id);
    crc:=MsgidIndex(id);
    dbSeek(bezbase,beiMsgId,dbLongStr(crc));
    if dbFound then begin
      new(hdp2);
      hdp2^.msgid:='';
      mrec:=dbRecno(mbase);
      repeat
        rec:=dbReadInt(bezbase,'MsgPos');
        if not dbDeleted(mbase,rec) then begin   { sicher ist sicher.. }
          dbGo(mbase,rec);
          Readheader(hdp2^,hds,false);
        end;
        if (hdp2^.msgid=id) and (hdp2^.absender=abs) then DelMsg;
        dbNext(bezbase);
      until dbEOF(bezbase) or (dbReadInt(bezbase,'msgid')<>crc);
      dbGo(mbase,mrec);
      dispose(hdp2);
    end;
    if not supersedes then DelMsg;   { Cancel-Nachricht auf 'gelesen' / 'lîschen' }
  end;

  procedure cancelmsgs;
  var id : string[MidLen];
      abs: string[AdrLen];
      n  : longint;
      rec: longint;
  begin
    moff; writeln; mon;
    reset(cancelfile);
    n:=0;
    while not eof(cancelfile) do begin
      inc(n);
      moff;
      write(#13,getres(341),n);
      mon;
      readln(cancelfile,rec);
      dbGo(mbase,rec);
      readln(cancelfile,id);
      readln(cancelfile,abs);
      CancelMsg(id,abs);
      end;
    close(cancelfile);
    moff; writeln; mon;
  end;

  function IsCancelMsg:boolean;
  begin
    with hdp^ do
      IsCancelMsg:=(attrib and attrControl<>0) and (lstr(left(betreff,7))='cancel ');
  end;

  function IsSupersedesMsg:boolean;
  begin
    with hdp^ do
      IsSupersedesMsg:=ersetzt<>'';
  end;

  function IsSupportCfg:boolean;

    function NameOk:boolean;
    begin
      NameOk:=stricmp(hdp^.realname,inout.pm) or
              (pos(lstr(inout.pm),lstr(hdp^.absender))>0);
    end;

    function XPctlOk:boolean;
    var sum : longint;
        i   : integer;
    begin
      with hdp^ do begin
        sum:=0;
        for i:=1 to length(datum) do
          inc(sum,ord(datum[i])*7);
        for i:=1 to length(msgid) do
          inc(sum,ord(msgid[i])*3);
        XpCtlOk:=(sum=XpointCtl div 1000);
        end;
    end;

  begin
    with hdp^ do
      IsSupportCfg:=
        (ntXPctl(netztyp) and NameOk and XPctlOk) or
        ((netztyp=nt_Maus) and (absender=inout.pm+'@LU') and
         (left(betreff,11)=SupportCfg));
  end;

  procedure TestControlMessage;
  var box    : string[20];
      fstype : byte;
  begin
    automessaging:=true;
    with hdp^ do begin
      if aufnehmen and
        ( ((left(ustr(betreff),7)='BRETTER') or
           (pos('your list',lstr(betreff))>0))
         and
         stricmp(left(absender,length(mapsname)),mapsname) and
         (empfaenger[1]='1') )
      or
         ((left(absender,7)='SYSTEM@') and
          ((left(ustr(betreff),11)='NETZBRETTER') or  { QuickMail }
           (ustr(betreff)='BESTELLBARE BRETTER')  or  { G & S     }
           (pos('BRETTLISTE',ustr(betreff))>0)))      { TurboBox, ZQWK }
          then begin
        showbetreff;
        w0;
        MapsReadList;
        w1;
        end;

      if (left(ustr(betreff),6)='FILES.') and (cpos('@',absender)>0) and
         (typ='T') then
      begin
        box:=copy(absender,cpos('@',absender)+1,20);
        if cpos('.',box)>0 then begin
          box:=left(box,cpos('.',box)-1);
          if IsServer(box,fstype) and (fstype<>3) then begin
            showbetreff;
            w0;
            FS_Readlist(true);
            w1;
            end;
          end;
        end;

      if (empfaenger[1]='1') { PM } and empfbest and ebest and
         (((attrib and attrReqEB<>0) and (attrib and attrIsEB=0)) or
          ((empfbkennung<>'') and (isl(empfbkennung) or
            isl(QPC_ID+empfbkennung) or isl(DES_ID+empfbkennung)))) then
      begin
        showbetreff;
        w0;
        empfang_bestaetigen(pollbox);
        w1;
        end;

      if (sysbetreff<>'') and (empfaenger[1]='1') and (lstr(betreff)=sysbetreff) and
         (LeftAbsender('changesys') or LeftAbsender('news') or
          LeftAbsender('postmaster') or LeftAbsender('root')) then
      begin
        showbetreff;
        w0;
        GetSysfile;
        w1;
        end;

      if UsePGP and (empfaenger[1]='1') { PM } then begin
        if (hdp^.netztyp in [nt_PPP,nt_UUCP]) and
           (hdp^.betreff=getres2(3001,2)) and { 'PGP-Keyanforderung' }
           (hdp^.refanz=0) and (PGP_RFC) then
        begin
          if pollbox<>'' then
            xp6.forcebox:=pollbox;
          xp6._bezug:=msgid;
          xp6._beznet:=netztyp;
          w0;
          PGP_SendKey(absender,false);
          w1;
          xp6.forcebox:='';
        end else
        if (pgpflags and fPGP_request<>0) and ebest then begin
          if pollbox<>'' then
            xp6.forcebox:=pollbox
          else
            xp6.forcebox:=pfadbox(true,pfad);
          xp6._bezug:=msgid;
          xp6._beznet:=netztyp;
          w0;
          PGP_SendKey(iifs(pgp_uid='',absender,pgp_uid),true);
          w1;
          xp6.forcebox:='';
        end;
        freeres;
      end;

      if IsCancelMsg or IsSupersedesMsg then begin
        attrtxt(col.colmboxchigh);
        showbetreff;
        attrtxt(col.colmbox);
        w0;
        writeln(cancelfile,dbRecno(mbase));
        if IsCancelMsg then
          writeln(cancelfile,'c '+trim(mid(betreff,8)))
        else
          writeln(cancelfile,'s '+ersetzt);
        writeln(cancelfile,absender);
        inc(cancels);
        w1;
        end;

      if IsSupportCFG then begin
        showbetreff;
        w0;
        XRead(SupportCfg,false);
        w1;
        end;
      end;
    automessaging:=false;
  end;

  function logstr(s:string):string;
  begin
    logstr:=left(date,6)+right(date,2)+' '+left(time,5)+' '+s;
  end;

  procedure pmCryptDecode;
  var passwd,s : string;
      size     : smallword;
      codierer : byte;
      f,f2     : file;
      tmp      : pathstr;
      uncfile  : pathstr;
      uvs      : byte;
      hdp2     : headerp;
      hds2     : longint;
      ok       : boolean;
      orgsize  : longint;
      orgempf  : AdrStr;
  begin
    size:=0;
    dbSeek(ubase,uiName,ustr(hdp^.absender));
    if not dbFound then exit;
    dbReadX(ubase,'passwort',size,passwd);
    dbRead(ubase,'codierer',codierer);
    if (passwd='') or (codierer<3) or (codierer>2+maxpmc) or
      (TempFree<2*dbReadInt(mbase,'msgsize')) then exit;
    new(hdp2);
    ReadHeader(hdp2^,hds2,true);
    assign(f,temppath+cryptedfile);
    rewrite(f,1);
    XreadF(dbReadInt(mbase,'msgsize')-dbReadInt(mbase,'groesse'),f);
    close(f);
    uncfile:=temppath+uncryptedfile;
    s:=pmcrypt[codierer-2].decode;
    rps(s,'$KEY',passwd);
    rps(s,'$INFILE',temppath+cryptedfile);
    rps(s,'$OUTFILE',uncfile);
    rps(s,'$USER',hdp^.absender);
    if exist(uncfile) then _era(uncfile);
    savecursor;
    window(1,1,80,25);
    shell(s,600,3);                     { Nachricht decodieren }
    if existf(f) then erase(f);       { codierte Msg lîschen, falls noch da }
    if not exist(uncfile) then
      trfehler(306,errortimeout_mini)         { 'Fehler beim Decodieren' }
    else begin
      assign(f,uncfile);
      reset(f,1);
      makeheader(false,f,0,0,hds2,hdp2^,ok,false);
      close(f);
      if not ok then
        trfehler(306,errortimeout_mini)       { 'Fehler beim Decodieren' }
      else begin
        reset(f,1);   { uncfile }
        hdp^.betreff:=hdp2^.betreff;
        hdp^.typ:=hdp2^.typ;
        orgsize:=hdp^.groesse;     hdp^.groesse:=filesize(f)-hds2;  { = hdp2^.groesse }
        orgempf:=hdp^.empfaenger;  hdp^.empfaenger:=hdp2^.empfaenger;
        tmp:=TempS(hdp^.groesse+2048);
        assign(f2,tmp);
        rewrite(f2,1);
        ClearPGPflags(hdp);
        WriteHeader(hdp^,f2,reflist);    { neuer Header }
        seek(f,hds2);
        fmove(f,f2);                     { + decodierter Text }
        close(f); close(f2);
        erase(f);   { uncfile }
        Xwrite(tmp);
        wrkilled;
        _era(tmp);
        dbWriteN(mbase,mb_betreff,hdp2^.betreff);
        dbWriteN(mbase,mb_typ,hdp2^.typ[1]);
        dbWriteN(mbase,mb_groesse,hdp^.groesse);
        dbReadN(mbase,mb_unversandt,uvs);
        uvs:=uvs or 4;                        { "c"-Flag }
        dbWriteN(mbase,mb_unversandt,uvs);
        hdp^.groesse:=orgsize;
        hdp^.empfaenger:=orgempf;
        end;
      end;
    wwin;
    restcursor;
    dispose(hdp2);
  end;

  procedure DecPGP;
  var s : string[AdrLen];
  begin
    s:=hdp^.empfaenger;
    hdp^.empfaenger:=orgempf;
    attrtxt(col.colmboxehigh);
    showbetreff;
    savecursor;
    window(1,1,80,25);
    LogPGP(getreps2(3002,2,hdp^.absender));  { 'decodiere Nachricht von %s' }
    PGP_DecodeMessage(hdp,false);
    wwin;
    restcursor;
    hdp^.empfaenger:=s;
  end;

  procedure wrp;
  var ps : string[3];
  begin
    ps:=strs(inmsgs*100 div msgcount);
    moff;
    FWrt(x+73-length(ps), y, ' ' + ps + '% ');
    mon;
  end;

  procedure Bezugsverkettung;
  var n,nbez : longint;
      c1,c2  : longint;
      ll     : record
                 l   : longint;
                 dat : longint;
               end;
      empfnr : integer;
      xx     : byte;
  begin
    moff;
    writeln;
    write(getres(332));   { 'Bezugsverkettung...' }
    xx:=wherex+1;
    mon;
    reset(f,1);
    fs:=filesize(f);
    adr:=0; n:=0; nbez:=0;
    dbStopHU(bezbase);
    seek(pfile,0);
    repeat
      empfnr:=1;
      inc(n);
      repeat
        seek(f,adr);
        makeheader(zconnect,f,empfnr,0,hdsize,hdp^,ok,true);
        { 20.01.2000 robo - Schalter maildelxpost beachten }
{        if hdp^.empfanz>maxcrosspost then begin }
        if (hdp^.empfanz>maxcrosspost)
        and ((cpos('@',hdp^.empfaenger)=0) or maildelxpost) then begin
        { /robo }
          empfnr:=hdp^.empfanz+1;                { Crossposting-Filter }
          continue;
          end;
        blockread(pfile,ll,8);
        if (ll.l<>0) and ntKomkette(hdp^.netztyp) and (hdp^.msgid<>'') then begin
          inc(nbez);
          c1:=MsgidIndex(hdp^.msgid);
          if hdp^.ref='' then c2:=0
          else c2:=MsgidIndex(hdp^.ref);
          dbAppend(bezbase);
          dbWriteN(bezbase,bezb_msgpos,ll.l);
          dbWriteN(bezbase,bezb_msgid,c1);
          dbWriteN(bezbase,bezb_ref,c2);
          dbWriteN(bezbase,bezb_datum,ll.dat);
          end;
        inc(empfnr);
      until empfnr>hdp^.empfanz;
{$IFDEF BP }
      gotoxy(xx,wherey);
      moff;
      write(nbez,' (',n*100 div msgcount,'%) ');
{$ELSE }
      moff;
      FWrt(xx+2, wherey+5, ' ('+ StrS(n*100 div msgcount) + '%) ');
{$ENDIF }
      mon;
      inc(adr,hdp^.groesse+hdsize);
    until adr>=fs-3;     { 3 Byte Toleranz }
    dbRestartHU(bezbase);
    dbFlush(bezbase);
    close(f);
    writeln;
  end;

  procedure wrll(l:longint);
  begin
    inc(llanz);
    llbuf[llanz]:=l;
    if llanz=maxll then begin
      blockwrite(pfile,llbuf,sizeof(llbuf));
      llanz:=0;
      end;
  end;

  function IsOwnDomain(dom:string):boolean;
  var p : DomainNodep;
      apos,ppos: integer;
  begin
    if cpos('@',dom)=0 then
      IsOwnDomain:=false
    else begin
      apos:=cpos('@',dom);
      ppos:=cpos('.',dom);
      if (ppos<apos) and (ppos>0) then apos:=ppos;
      delete(dom,1,apos);
      LoString(dom);
      p:=DomainList;
      while (p<>nil) and (p^.domain^<>dom) do
        if dom<p^.domain^ then p:=p^.left
        else p:=p^.right;
      IsOwnDomain:=(p<>nil);
    end;
  end;

  procedure FlushLL;
  begin
    if llanz>0 then begin
      blockwrite(pfile,llbuf,llanz*4);
      llanz:=0;
      end;
  end;

  function GetPntAnz:byte;
  var
    pnt,p : byte;
  begin
    pnt:=0; p:=0;
    if fqdn_[1]='.' then begin
      GetPntAnz:=pnt;
      exit;
    end;
    while (p<length(fqdn_)) do begin
      if fqdn_[p+1]='.' then inc(pnt);
      inc(p);
    end;
    GetPntAnz:=pnt;
  end;

  procedure setverpollbox;
  var
    svboxpar : boxptr;
  begin
    if pollbox='' then begin
      mapsname:='MAPS'; amvertreter:=''; pmvertreter:='';
      sysbetreff:=''; abs:=''; fqdn_:=''; repown:=false;
      end
    else begin
      dbOpen(d,BoxenFile,1);
      dbSeek(d,boiName,ustr(pollbox));
      if not dbFound then begin
        mapsname:=''; amvertreter:=''; pmvertreter:='';
        sysbetreff:=''; abs:=''; fqdn_:=''; repown:=false;
      end
      else begin
        dbRead(d,'nameomaps',mapsname);
        dbRead(d,'AVertreter',AMvertreter);
        dbRead(d,'PVertreter',PMvertreter);
        dbSeek(d,boiName,ustr(amvertreter));
        if not dbFound then amvertreter:='';
        dbSeek(d,boiName,ustr(pmvertreter));
        if not dbFound then pmvertreter:='';
        dbSeek(d,boiname,ustr(pollbox));
        dbRead(d,'netztyp',nt);
        {$IFDEF DBGHDO}
          writeln(dbg,strs(nt));
        {$ENDIF}
        if nt<>nt_Fido then begin
          w0;
          svboxpar:=boxpar;
          new(boxpar);
          ReadBoxPar(nt,pollbox);
          repown:=boxpar^.replaceown;
        {$IFDEF DBGHDO}
          writeln(dbg,pollbox+' -:- RÅcklÑufer ersetzen: '+iifs(repown,'Ja','Nein'));
        {$ENDIF}
          dbRead(d,'domain',boxpar^._domain);
          if nt in [nt_PPP,nt_ZConnect,nt_UUCP] then
            dbRead(d,'fqdn',fqdn_) else fqdn_:='';
          if fqdn_<>'' then begin
            if ((nt in [nt_PPP,nt_UUCP]) and not boxpar^.mailerdaemon) or
                (nt=nt_ZConnect) then
            if (getpntanz<2) and (pos('@',fqdn_)=0) then fqdn_:='';
          end;
          dbRead(d,'script',scrflag);
          with boxpar^ do begin
            case ntDomainType(nt) of
              0 : abs:=username+'@'+iifs((scrflag and 4<>0),pointname,boxname)+'.ZER';
              1 : abs:=username+'@'+iifs((scrflag and 4<>0),boxname,pointname);
              2 : abs:=username+'@'+pointname;
              3 : abs:=username+'@'+boxname;
              {4 : abs:=username+'@'+boxname+'.'+pointname;}
              5 : abs:=username+'@'+iifs((scrflag and 4<>0),pointname,boxname)+_domain;
              6 : abs:=username+'@'+iifs((scrflag and 4<>0),boxname,pointname)+_domain;
              7 : abs:=username+'@'+boxname+';'+pointname;
              8 : abs:=username+'@'+pointname+_domain;
            end;
            {$IFDEF DBGHDO}
              writeln(dbg,abs+' -:- '+username);
            {$ENDIF}
            if username='' then abs:='';
          end;
          if nt=nt_UUCP then
            sysbetreff:=lstr(boxpar^.chsysbetr);
          dispose(boxpar);
          boxpar:=svboxpar;
          w1;
        end;
      end;
      dbClose(d);
    end;
  end;

begin
  inmsgs:=0;
  puffereinlesen:=false;
  svpollbox:=pollbox;
  forcepfadbox:=(pflags and pe_ForcePfadbox<>0);
  msgbox(78,screenlines-6,getres(333),x,y);    { 'Puffer einlesen' }
  wwin;
  attrtxt(col.colmbox);
  zconnect:=ZC_puffer(puffer);
  assign(f,puffer);
  reset(f,1);
  fs:=filesize(f);
  if fs<16 then begin
    close(f);
    moff;
    writeln(#10,getres(334));    { 'leerer Puffer' }
    mon;
    wkey(1,false);
    closebox;
    puffereinlesen:=true;
    exit;
    end;
  check:=(fs*1.3<diskfree(0));

  getmem(p,bufsize);
  new(hdp);
  if check and puffer_ok then begin
    abadd:=iif(zconnect,10,0);
    l:=ablsize[1+abadd]; ablage:=1+abadd;   { 0/10 = PM-Ablage }
    for i:=2+abadd to 9+abadd do
      if ablsize[i]<l then begin
        ablage:=i; l:=ablsize[i];
        end;

    assign(brettlog,logpath+brettLogfile);
    if existf(brettlog) then append(brettlog)
    else rewrite(brettlog);
    assign(userlog,logpath+userLogfile);
    if existf(userlog) then append(userlog)
    else rewrite(userlog);

(*
    if pollbox='' then begin
      mapsname:='MAPS'; amvertreter:=''; pmvertreter:='';
      sysbetreff:=''; abs:='';
      end
    else begin
      dbOpen(d,BoxenFile,1);
      dbSeek(d,boiName,ustr(pollbox));
      if not dbFound then begin
        mapsname:=''; amvertreter:=''; pmvertreter:='';
        sysbetreff:=''; abs:='';
      end
      else begin
        dbRead(d,'nameomaps',mapsname);
        dbRead(d,'AVertreter',AMvertreter);
        dbRead(d,'PVertreter',PMvertreter);
        dbSeek(d,boiName,ustr(amvertreter));
        if not dbFound then amvertreter:='';
        dbSeek(d,boiName,ustr(pmvertreter));
        if not dbFound then pmvertreter:='';
        dbSeek(d,boiname,ustr(pollbox));
        dbRead(d,'netztyp',nt);
        if nt<>nt_Fido then begin
          window(1,1,80,screenlines);
          ReadBoxPar(nt,pollbox);
          wwin;
          GotoXY(WhereX,WhereY+2);
          dbRead(d,'domain',boxpar^._domain);
          if nt in [nt_PPP,nt_ZConnect,nt_UUCP] then
            dbRead(d,'fqdn',boxpar^._fqdn) else boxpar^._fqdn:='';
          if boxpar^._fqdn<>'' then begin
            if ((nt in [nt_PPP,nt_UUCP]) and not boxpar^.mailerdaemon) or
                (nt=nt_ZConnect) then
            if (getpntanz<2) and (pos('@',boxpar^._fqdn)=0) then boxpar^._fqdn:='';
          end;
          dbRead(d,'script',scrflag);
          with boxpar^ do begin
            case ntDomainType(nt) of
              0 : abs:=username+'@'+iifs((scrflag and 4<>0),pointname,boxname)+'.ZER';
              1 : abs:=username+'@'+iifs((scrflag and 4<>0),boxname,pointname);
              2 : abs:=username+'@'+pointname;
              3 : abs:=username+'@'+boxname;
              {4 : abs:=username+'@'+boxname+'.'+pointname;}
              5 : abs:=username+'@'+iifs((scrflag and 4<>0),pointname,boxname)+_domain;
              6 : abs:=username+'@'+iifs((scrflag and 4<>0),boxname,pointname)+_domain;
              7 : abs:=username+'@'+boxname+';'+pointname;
              8 : abs:=username+'@'+pointname+_domain;
            end;
            if username='' then abs:='';
          end;
          if {dbReadInt(d,'netztyp')} nt=nt_UUCP then
         {begin
            ReadBoxPar(nt_UUCP,pollbox);}
            sysbetreff:=lstr(boxpar^.chsysbetr);
         {end;}
        end;
      end;
      dbClose(d);
    end;
*)

    {$IFDEF DBGIMP}
      assign(dbg,ownpath+'IMPORT.DBG');
    {$ENDIF}
    {$IFDEF DBGHDO}
      assign(dbg,ownpath+'HDO.DBG');
    {$ENDIF}
    {$IFDEF DBG}
      rewrite(dbg);
    {$ENDIF}

    setverpollbox;

    moff; writeln(getres(335)); mon;    { 'Puffer kopieren...' }
    assign(pfile,aFile(ablage));        { Puffer in die kleinste }
    if existf(pfile) then begin         { Ablage kopieren ..     }
      reset(pfile,1);
      padr:=filesize(pfile);
      seek(pfile,padr);
      end
    else begin
      rewrite(pfile,1);
      padr:=0;
      end;
    seek(f,0);
    size:=filesize(f)-diff;
    repeat
      blockread(f,p^,bufsize,rr);
      blockwrite(pfile,p^,rr);
      dec(size,rr);
    until eof(f);
    close(pfile);

    assign(pfile,TempS(msgcount*8+2048));
    rewrite(pfile,1);
    llanz:=0;
    seek(f,0);
    assign(cancelfile,TempS(msgcount*40+2048));
    rewrite(cancelfile);
    cancels:=0;

    assign(hdo,temppath+'HDOKILL.NOW');
    rewrite(hdo);
    haskill:=false;

    adr:=0;
    dat:=Zdate;
    today:=ixDat(dat);
    dbStopHU(mbase);
    repeat
      empfnr:=1;
      junk:=false;
      msgsent:=false;       { true -> Nachricht wurde in mind. einem Brett gespeichert }
      repeat       { Cross-Postings bearbeiten }
        seek(f,adr);
        makeheader(zconnect,f,empfnr,0,hdsize,hdp^,ok,true);

        {$IFDEF DBGIMP}
        writeln(dbg,'PBOX (1):  '+pollbox);
        {$ENDIF}
        if (hdp^.netztyp=nt_PPP) and (hdp^.real_box<>'') and
           (lstr(pollbox)<>lstr(hdp^.real_box)) then begin
          pollbox:=hdp^.real_box;
          setverpollbox;
        end;
        {$IFDEF DBGIMP}
        writeln(dbg,'X-NTP: '+strs(hdp^.netztyp));
        writeln(dbg,'X-BOX: '+hdp^.real_box);
        writeln(dbg,'PBOX (2):  '+pollbox);
        {$ENDIF}

        orgempf:=hdp^.empfaenger;
        { 20.01.2000 robo - Schalter maildelxpost beachten }
{        if hdp^.empfanz>maxcrosspost then begin }
        if (hdp^.empfanz>maxcrosspost)
        and ((cpos('@',hdp^.empfaenger)=0) or maildelxpost) then begin
        { /robo }
          empfnr:=hdp^.empfanz+1;                { Crossposting-Filter }
          continue;
          end;
        if junk then begin
          hdp^.empfanz:=1;
          hdp^.empfaenger:='/ØJunk'
          end;
        if grosswandeln and not zconnect then begin
          UpString(hdp^.absender);
          UpString(hdp^.empfaenger);
          end;
        pm:=false;
        with hdp^ do begin
          if replace_ed then dat:=datum;
          _datum:=ixdat(dat);
          if replace_ed and smdl(today,_datum) then begin
            dat:=zdate;
            _datum:=today;
            end;
          tobrett:=archive or (copy(empfaenger,1,TO_len)=TO_ID);
          atp:=pos('@',empfaenger);
          if sendbuf then begin   { pollbox <> '' !  }
            if (left(empfaenger,1)<>'/') and (cpos('@',empfaenger)=0) then
              empfaenger:=empfaenger+'@'+pollbox+'.ZER';
            if cpos('@',empfaenger)>0 then
              if tobrett then
                empfaenger:='U'+mid(empfaenger,iif(archive,1,length(TO_ID)+1))
              else begin
                empfaenger:='U'+empfaenger;
                tobrett:=true;
                end
            else
              empfaenger:='A'+empfaenger;
            end
          else     { not sendbuf }
            if tobrett then
              if (copy(empfaenger,1,9)<>'/'#0#0#8#8'TO:/') or (atp>0) then
                empfaenger:='U'+copy(empfaenger,iif(archive,1,9),79)
              else begin
                while empfaenger[10]=#255 do  { wg. #255#255'Netzanruf' }
                  delete(empfaenger,10,1);
                empfaenger:='$/Ø'+copy(empfaenger,10,255);
                end
            else
              if empfaenger[2]='Ø' then
                empfaenger:='$'+empfaenger
              else
                if (atp=0) and (left(empfaenger,1)='/') then
                  empfaenger:='A'+empfaenger
                else begin
                  if atp=0 then empfaenger:='1/'+empfaenger
                  else
                    if UserBoxname then
                      empfaenger:='1/'+left(empfaenger,atp-1)+'/'+mid(empfaenger,atp+1)
                    else
                      empfaenger:='1/'+left(empfaenger,atp-1);
                  pm:=true;
                  end;
          moff;
{$IFDEF BP }
          writeln;
          if empfaenger[1]='U' then begin
            write('AN:'); fm:=24; end
          else
            fm:=27;
          write(forms(copy(empfaenger,2,40),fm),' ',forms(absender,22),' ',forms(betreff,23));
{$ELSE }
          writeln;
          if empfaenger[1]='U' then
          begin
            fm:=24; FWrt(WhereX+3, WhereY+4, 'AN:')
          end else
            fm:=27;
          FWrt(WhereX+fm+3-27, WhereY+4, forms(copy(empfaenger,2,40),fm) + ' ' + forms(absender,22) + ' ' + forms(betreff,23));
{$ENDIF }
          mon;
          multi2(curoff); initscs;

          attrtxt(col.colmboxhigh);
          dbSeek(ubase,uiName,ustr(absender));
          if not dbFound and (length(absender)<eAdrLen) then begin          { neuen User anlegen }
            if adrok(absender) then begin
              mwrt(29,wherey,forms(absender,22));
              dbAppend(ubase);
              dbWrite(ubase,'username',absender);
              pb:=pollbox_str(zconnect,true);

              {$IFDEF DBGIMP}
              writeln(dbg,'Vertreter: '+pb);
              writeln(dbg,'Netztyp:   '+strs(netztyp));
              {$ENDIF}

              dbWrite(ubase,'pollbox',pb);
              dbWrite(ubase,'haltezeit',stduhaltezeit);
              flags:=1+iif(newuseribm {ntUserIBMchar(netztyp)},0,8);  { aufnehmen / Umlaute }
              dbWrite(ubase,'userflags',flags);
              writeln(userlog,logstr(absender));
              end;
            aufnehmen:=true;
            end
          else
            if empfaenger[1]<>'A' then
              aufnehmen:=true
                         { not developer or
                         ((pos('@mips.pfalz.de',absender)=0) and
                          (pos('news@pythia.lunetix.de',absender)=0) and
                          (pos('news@dfki.uni-sb.de',absender)=0)) }
            else begin
              dbReadN(ubase,ub_userflags,uflags);
              aufnehmen:=odd(uflags);
              end;
          if left(empfaenger,1)<>'U' then begin
            dbSeek(bbase,biBrett,ustr(empfaenger));
            if not dbFound then begin
              if (empfanz>1) or (attrib and AttrControl<>0) then
                aufnehmen:=false
              else if aufnehmen then begin          { neues Brett anlegen }
                mwrt(1,wherey,forms(copy(empfaenger,2,27),27));
                if left(empfaenger,1)<>'A' then grnr:=IntGruppe
                else begin
                  seekbr:=empfaenger;
                  p0:=posn('/',seekbr,3);
                  if p0>0 then begin
                    seekbr:=left(seekbr,p0-1);
                    if dbEOF(bbase) or
                       (left(dbReadStr(bbase,'brettname'),length(seekbr))<>seekbr) then
                      dbSeek(bbase,biBrett,ustr(seekbr));
                    end;
                  if dbEOF(bbase) then dbGoEnd(bbase);
                  if dbEOF(bbase) then grnr:=NetzGruppe
                  else dbReadN(bbase,bb_gruppe,grnr);
                  if grnr=IntGruppe then grnr:=NetzGruppe;
                  end;
                if left(empfaenger,1)='1' then
                  haltezeit:=0
                else begin
                  dbOpen(d,GruppenFile,1);
                  dbSeek(d,giIntnr,dbLongStr(grnr));
                  if not dbFound then haltezeit:=stdhaltezeit
                  else dbRead(d,'haltezeit',haltezeit);
                  dbClose(d);
                  end;
                dbAppend(bbase);
                dbWriteN(bbase,bb_brettname,empfaenger);
                pb:=pollbox_str(zconnect,false);

                {$IFDEF DBGIMP}
                writeln(dbg,'Vertreter: '+pb);
                writeln(dbg,'Netztyp:   '+strs(netztyp));
                {$ENDIF}

                dbWriteN(bbase,bb_pollbox,pb);
                dbWriteN(bbase,bb_haltezeit,haltezeit);
                dbWriteN(bbase,bb_gruppe,grnr);
                flags:=iif((netztyp=nt_UUCP) or (netztyp=nt_PPP),16,0);
                dbWriteN(bbase,bb_flags,flags);
                if newbrettende then
                  SetBrettindexEnde
                else begin
                  w0;
                  SetBrettindex;
                  w1;
                  end;
                writeln(brettlog,logstr(copy(empfaenger,2,255)));
                end;   { aufnehmen }
              end    { not dbFound }
            else
              if dbReadInt(bbase,'flags') and 4<>0 then aufnehmen:=true;
            if aufnehmen then
              _brett:=mbrettd(empfaenger[1],bbase);
            end;
          { hier kein adrok: TO-User werden immer aufgenommen! }
          if left(empfaenger,1)='U' then begin
            dbSeek(ubase,uiName,ustr(copy(empfaenger,2,80))); {Adre·buch-Eintrag}
            if not dbFound then begin
              dbAppend(ubase);
              name:=copy(empfaenger,2,79);
              pb:=pollbox_str(zconnect,true);
              if pos('@',name)=0 then name:=left(name+'@'+pb+'.ZER',79);
              dbWriteN(ubase,ub_username,name);
              dbWriteN(ubase,ub_pollbox,pb);
              dbWriteN(ubase,ub_haltezeit,stduhaltezeit);
              flags:=1+iif(newuseribm,0,8);  { aufnehmen / Umlaute }
              dbWrite(ubase,'userflags',flags);
              adrbuch:=1;
              dbWriteN(ubase,ub_adrbuch,adrbuch);
              end
            else begin
              dbReadN(ubase,ub_adrbuch,adrbuch);
              if adrbuch=0 then begin
                adrbuch:=1;
                dbWriteN(ubase,ub_adrbuch,adrbuch);
                end;
              end;
            _brett:=mbrettd('U',ubase);
            end;

          IsGelesen:=ParGelesen or sendbuf or
                     ((netztyp=nt_Maus) and (left(pm_bstat,1)='G')) or
                     (filterattr and fattrGelesen<>0) or
                     (pflags and pe_gelesen<>0) or
                     (((ustr(hdp^.XpMode)='REPLACEOWN') or
                     (ustr(hdp^.absender)=ustr(abs)) or
                     (pos(lstr(fqdn_),lstr(hdp^.msgid))<>0)) and
                     (RepOwn));

          if aufnehmen then begin
            if left(empfaenger,1)<>'U' then begin
              dbReadN(bbase,bb_flags,flags);
              if not IsGelesen and (flags and 2 = 0) then
              begin
                inc(flags,2);                 { ungelesene Nachricht(en) }
                dbWriteN(bbase,bb_flags,flags);
              end;
              if smdl(dbReadInt(bbase,'ldatum'),_datum) then
                dbWriteN(bbase,bb_ldatum,_datum);      { Datum der neuesten Msg }
            end;
            dbAppend(mbase);
            mnt:=netztyp;
            if ref<>'' then inc(mnt,$100);
            if attrib and attrFile<>0 then inc(mnt,$200);
            if pm_reply then inc(mnt,$400);
            if (wab<>'') or (oem<>'') then inc(mnt,$800);
            if empfanz>1 then inc(mnt,longint(empfnr) shl 24);
            if ((empfaenger[1]='A') and ntDomainReply(netztyp) and
              IsOwnDomain(ref)) or (filterattr and fattrHilite<>0)
            then begin
              attrtxt(col.colmboxehigh);
              showbetreff;
              attrtxt(col.colmbox);
              inc(mnt,$1000);        { Antwort auf eigene Nachricht }
            end;
            if charset='iso1' then inc(mnt,$2000);
            if komlen>0 then inc(mnt,$8000);
            dbWriteN(mbase,mb_netztyp,mnt);
            dbWriteN(mbase,mb_betreff,betreff);
            dbWriteN(mbase,mb_absender,absender);
            ld:=ixdat(datum);
            dbWriteN(mbase,mb_origdatum,ld);
            ld:=ixdat(dat);
            dbWriteN(mbase,mb_empfdatum,ld);
            dbWriteN(mbase,mb_groesse,groesse);
            typ1:=UpCase(typ[1]);
            if (typ1<=' ') or (typ1>#126) then typ1:='?';
            dbWriteN(mbase,mb_typ,typ1);
            dbWriteN(mbase,mb_mimetyp,mimetyp);
            dbWriteN(mbase,mb_brett,_brett);
            dbWriteN(mbase,mb_ablage,ablage);
            dbWriteN(mbase,mb_adresse,padr);
            size:=groesse+hdsize;
            dbWriteN(mbase,mb_msgsize,size);
            msgid2:=FormMsgid(msgid);
            dbWriteN(mbase,mb_msgid,msgid2);
            if ntEditBrettempf(netztyp) then   { Fido, QWK }
              dbWriteN(mbase,mb_name,fido_to)
            else
              dbWriteN(mbase,mb_name,realname);
            if IsGelesen then begin
              flags:=1;
              dbWriteN(mbase,mb_gelesen,flags);
              if sendbuf then dbWriteN(mbase,mb_unversandt,flags);
              end;
            flags:=0;
            if filterattr and fattrLoeschen<>0 then flags:=2;
            if filterattr and fattrHalten<>0 then flags:=1;
            dbWriteN(mbase,mb_halteflags,flags);

            { Nachricht mit Priority hevorheben }
            {dbReadN(mbase, mb_prioflags, mnt);}
            {if (hdp^.Priority in [1,2,4,5]) or
            (FilterAttr and FattrPrio1 <> 0) or
            (FilterAttr and FattrPrio2 <> 0) or
            (FilterAttr and FattrPrio4 <> 0) or
            (FilterAttr and FattrPrio5 <> 0)  }
              if (hdp^.Priority in [1,2,4,5]) then begin
                Attrtxt(Col.ColMboxPhigh);
                ShowBetreff;
                Attrtxt(Col.ColMbox);
                  case hdp^.Priority of  { PrioritÑten in anderer Farbe.... }
                    1:  mbflags := 8;    { Hîchste    }
                    2:  mbflags := 16;   { Hoch       }
                    4:  mbflags := 24;   { Niedrig    }
                    5:  mbflags := 32;   { Niedrigste }
                  end;
                {inc(mnt, $1000);}
              end else
            {dbWriteN(mbase, mb_prioflags, mnt);}
            if ZConnect and (hdp^.Prio > 0) then     { und fÅr Zconnect .... }
              if hdp^.Prio = 10 then mbflags := 16   { Hoch    }
              else mbflags := 8                      { Hîchste }
            else mbflags := 0;


            { HeaderOnly-Flag setzen }
            if ((ustr(hdp^.xpmode)='HDRONLY') or
               (ustr(hdp^.xpmode)='TOPOFMAIL')) and (hdp^.groesse=0) then
              mbflags:=mbflags or 64;

            mbflags := mbflags or iif(boundary<>'',4,0);

            dbWriteN(mbase,mb_flags,mbflags);

            if (ustr(hdp^.XpMode)='MESSAGE-ID REQUEST') then begin
              writeln(hdo,'REQUEST:'+hdp^.msgid);
              writeln(hdo,dbRecno(mbase));
              {$IFDEF DBGHDO}
                writeln(dbg,'REQUEST:'+hdp^.msgid+' -:- '+strs(dbRecno(mbase)));
              {$ENDIF}
            end else
            if ((ustr(hdp^.XpMode)='REPLACEOWN') or
               (ustr(hdp^.absender)=ustr(abs)) or
               (pos(lstr(fqdn_),lstr(hdp^.msgid))<>0)) and
               (RepOwn) then
            begin
              writeln(hdo,'REPLACE:'+hdp^.msgid);
              {flags:=1;
              if haltown then dbWriteN(mbase,mb_HalteFlags,flags);}
              writeln(hdo,dbRecno(mbase));
              {$IFDEF DBGHDO}
                writeln(dbg,hdp^.XpMode+' -:- '+hdp^.absender+' -:- '+abs+' -:- '+fqdn_);
                writeln(dbg,'REPLACE:'+hdp^.msgid+' -:- '+strs(dbRecno(mbase)));
            end else
                writeln(dbg,hdp^.XpMode+' -:- '+hdp^.msgid+' -:- '+hdp^.absender+' -:- '+abs+' -:- '+fqdn_);
              {$ELSE}
            end;
              {$ENDIF}

            wrll(dbRecno(mbase));     { fÅr Bezugsverkettung merken }
            l:=ixdat(datum) and $fffffff0;
            if empfanz>1 then
              inc(l,iif(msgsent,2,1));
            wrll(l);

            if UsePGP and (pgpflags and fPGP_haskey<>0) and
               ((PGP_AutoAM and (firstchar(empfaenger)='A')) or
                (PGP_AutoPM and (firstchar(empfaenger)='1')))
            then begin
              attrtxt(col.colmboxehigh);
              showbetreff;
              savecursor;
              window(1,1,80,25);
              PGP_ImportKey(true);
              wwin;
              restcursor;
              end;
            if (firstchar(empfaenger)='1') and UsePGP and
               (pgpflags and fPGP_encoded<>0) then
              DecPGP else
            if (firstchar(empfaenger)='1') and
               (left(betreff,length(PMC_ID))=PMC_ID) then begin
              attrtxt(col.colmboxehigh);
              showbetreff;
              pmCryptDecode;
              attrtxt(col.colmboxehigh);
              showbetreff;
              end;

            msgsent:=true;
            end
          else begin   { nicht aufnehmen }
            wrll(0);
            wrll(0);
            gotoxy(wherex,wherey-1);
            end;

          inc(empfnr);
          end;           { with hdp^ }
        if msgsent then begin
          attrtxt(col.colmboxhigh);
          TestControlMessage;
          end;
        attrtxt(col.colmbox);
        if (hdp^.empfanz>1) and (empfnr>hdp^.empfanz) and not msgsent and
           not IsCancelMsg and not IsSupersedesMsg then begin
          { Nachricht nach /Junk }
          junk:=true;
          empfnr:=1;            { kein passendes Brett fÅr Crossposting }
          FlushLL;
          seek(pfile,filesize(pfile)-8);
        { seek(pfile,filesize(pfile)-8*hdp^.empfanz); }
        { seek(pfile,filesize(pfile)-4*max(0,2*hdp^.empfanz-llanz));
          llanz:=max(0,llanz-2*hdp^.empfanz); }
          end;
    (*  else
          if junk then begin
            FlushLL;
            seek(pfile,sizeof(pfile));   { 0/0-EintrÑge fÅr nicht einsor- }
            end;                         { tierte Xpostings Åberspringen  } *)
      until empfnr>hdp^.empfanz;
      inc(adr,hdp^.groesse+hdsize);
      inc(padr,hdp^.groesse+hdsize);
      inc(inmsgs);
      wrp;
    until adr>=fs-3;     { 3 Byte Toleranz }
    dbrestartHU(mbase);
    dbFlush(mbase);
    close(f);
    inc(ablsize[ablage],fs);

    moff;
    writeln;
    if not aufnehmen then writeln;
    mon;
    FlushLL;
    if zconnect then
      Bezugsverkettung;
    close(pfile);
    erase(pfile);
    close(cancelfile);
    if cancels>0 then
      CancelMsgs;
    erase(cancelfile);

    if not replace_ed then write_lastcall(dat);
    FlushClose;
    close(brettlog);
    close(userlog);

    flush(hdo);
    close(hdo);
    if (_filesize(temppath+'HDOKILL.NOW')>0) then begin
      moff;
      writeln;
      write('HDO-Nachrichten ersetzen...');
      x:=wherex+1;
      mon;
      reset(hdo);
      msgcount:=1;
      while not eof(hdo) do begin
{$IFDEF BP }
        gotoxy(x,wherey);
        moff;
        write(' ('+strs(msgcount)+')');
{$ELSE }
        moff;
        FWrt(x+2, wherey+5, ' ('+strs(msgcount)+')');
{$ENDIF }
        mon;
        inc(msgcount);
        readln(hdo,_msgid);
        readln(hdo,hdorec);
        KillHdrOnly(_msgid,hdorec,false);
        rfdelaktive(_msgid);
      end;
      close(hdo);
      if haskill then begin
        window(1,1,80,25);
        rmessage(485);  { 'Nachrichten wurden ersetzt' }
        wkey(1,false);
        closebox;
      end;
    end;
    erase(hdo);
    packrfcmsgidfile;
    if exist(ownpath+midreqfile) and (_filesize(ownpath+midreqfile)=0) then
      _era(ownpath+midreqfile);

    {$IFDEF DBG}
    flush(dbg);
    close(dbg);
    {$ENDIF}

    puffereinlesen:=true;
    end   { if Puffer_ok }

  else begin
    close(f);
    moff;
    writeln;
    attrtxt(col.colmboxhigh);
    writeln(getres2(336,1));    { 'ACHTUNG !!!' }
    writeln;
    if check then
      writeln(getres2(336,2)+ustr(puffer))   { 'Fehlerhafte Pufferdatei:  ' }
    else
      writeln(getres2(336,3));    { 'Zu wenig Platz auf der Festplatte.' }
    writeln(getres2(336,4));      { 'Puffer wurde NICHT eingelesen!' }
    if pflags and pe_Bad<>0 then begin
      MoveToBad(puffer);
      writeln;
      writeln(getres2(336,5));    { 'Datei wurde im Unterverzeichnis BAD abgelegt.' }
      logerror(getres2(336,6));   { 'Fehlerhafter Netcallpuffer wurde im Unterverzeichnis BAD abgelegt.' }
      end
    else
      logerror(getres2(336,8)+puffer);   { 'Netcallpuffer wurde nicht eingelesen: ' }
    attrtxt(col.colmbox);
    writeln;
    mon;
    errsound;
    moff;
    write(getres(12));   { 'Taste drÅcken ...' }
    mon;
    errsound;
    cursor(curon);
    wkey(180,true);    { max. 3 Minuten }
    cursor(curoff);
    freeres;
    end;

  pollbox:=svpollbox;
  dispose(hdp);
  freemem(p,bufsize);
  window(1,1,80,25);
  closebox;
  aufbau:=true; xaufbau:=true;
end;


{ Datei fn ins Unterverzeichnis BAD\ verschieben; ggf. umbenennen }
{ Die Datei befindet sich normalerweise im XP- oder im SPOOL-     }
{ Verzeichnis.                                                    }

procedure MoveToBad(fn:pathstr);
var
    dir  : dirstr;
    name : namestr;
    ext  : extstr;
    f    : file;
begin
  fsplit(fn,dir,name,ext);
  ustr(ext);
  if (ext='D*.OUT') or (ext='X*.OUT') or (ext='C*.OUT') then exit;   { UUCP: ausgehende Nachrichten }
  if ext='' then
    ext:='.001'
  else
    while exist(BadDir+name+ext) and (ext<>'.999') do
      ext:='.'+formi(ival(mid(ext,2))+1,3);
  if exist(BadDir+name+ext) then
    _era(BadDir+name+ext);
  if not exist(BadDir+name+ext) then begin
    assign(f,fn);
    rename(f,BadDir+name+ext);
    if ioresult<>0 then;
    end;
end;
{
  $Log: xp3o.inc,v $
  Revision 1.92  2002/01/07 08:09:15  mm
  Log (bloedes WinCVS)

  Revision 1.91  2002/01/06 22:10:15  mm
  Nachrichtenauflistung beim Puffereinlesen nutzte in der 32Bit-Version nicht 
  alle zur Verfuegung stehenden Zeilen

  Revision 1.90  2001/09/30 09:58:19  MH
  - Fix: Debugcode hat zu spÑt die Datei geîffnet

  Revision 1.89  2001/09/25 10:28:11  MH
  - DebugCode fÅr HDO hinzugefÅgt
  - repown wurde nicht immer initialisiert

  Revision 1.88  2001/09/22 12:17:15  MH
  - DebugCode fÅr HDO hinzugefÅgt
  - fqdn_ wurde nicht immer initialisiert

  Revision 1.87  2001/09/08 10:25:59  MH
  Bei gro·en Puffern kann man den Eindruck gewinnen, das sich nichts mehr tut:
  - HDO-Ersetzung optisch anzeigen
  - Spooldir lîschen optisch anzeigen

  Revision 1.86  2001/09/02 11:42:35  MH
  - Fix: Absturz beim Anlegen von zu langen Absendern

  Revision 1.85  2001/07/16 10:02:37  MH
  - Farbsetup erweitert:
    Beim 'Puffereinlesen' werden eigene Nachrichten, Cancel/Supersedes usw.
    in verschiedenen Farben im Betreff angeszeigt

  Revision 1.84  2001/07/14 11:05:48  MH
  - Multiboxbetrieb beachtet beim Puffereinlesen Vertreter der jeweiligen Box

  Revision 1.83  2001/06/18 20:17:28  oh
  Teames -> Teams

  Revision 1.82  2001/04/04 19:57:01  oh
  -Timeouts konfigurierbar

  Revision 1.81  2001/03/22 16:56:02  oh
  - PGP cleanup

  Revision 1.80  2001/03/22 02:45:31  oh
  -Tempfile werden im Temp-Verzeichnis angelegt

  Revision 1.79  2000/12/31 11:43:11  MH
  Fix FidoNetcall-Anrufbericht:
  - Bei Fido (Crash) wurden falsche Boxparas verwendet

  Revision 1.78  2000/12/25 17:13:38  MH
  - NewUserIBM bei Useraufnahme ergÑnzt
  - Fix: Archivierung von PMs (Alt+P)

  Revision 1.77  2000/11/09 15:50:23  MH
  Eigene Nachrichten hervorheben auch beim neuem FQDN-Format

  Revision 1.76  2000/11/07 19:15:28  MH
  Fix: Optik

  Revision 1.75  2000/11/04 10:26:43  MH
  FQDN: Auswahl fÅr ISP (automatische Generrierung)
  - erweiterte FQDN mîglich: name@domain.tld
  - nur UUCP und PPP

  Revision 1.74  2000/11/01 16:24:37  MH
  ReplaceOwn: FQDN-Abfrage erweitert

  Revision 1.73  2000/10/27 11:38:59  MH
  RFC/PPP: Kleiner Umbau des BoxmenÅs

  - ReplaceOwn bei weiteren Boxen hinzugefÅgt

  Revision 1.72  2000/10/26 14:49:03  MH
  ReplOwn: Nur dann 'gelesen' setzen, wenn ReplOwn aktiviert wurde

  Revision 1.71  2000/10/14 14:27:38  MH
  Schalter ReplaceOwn wurde nicht immer beachtet...

  Revision 1.70  2000/10/14 10:33:09  MH
  HDO: Panne gefixed...

  Revision 1.69  2000/10/14 10:31:50  MH
  HDO: Panne gefixed...

  Revision 1.68  2000/10/13 14:27:28  MH
  Replace:
  - wvl: Datum entsprechend setzen

  Revision 1.67  2000/10/13 14:00:18  MH
  Replace:
  - Wir verabschieden uns von X-XP-MSG und setzen nun die Datenbank ein

  Revision 1.66  2000/10/13 12:39:26  MH
  HDO/Replace:
  Meldung erscheint nur dann, wenn auch gekillt wurde

  Revision 1.65  2000/10/13 12:30:25  MH
  HDO/Replace:
  Einige Bits ausmaskiert, da sich der Status Ñndern kann

  Revision 1.64  2000/10/13 11:14:49  MH
  Weitere Teile rendundanten Codes auskommentiert
  - Das mÅsste sich nun auch beschleunigt auswirken

  Revision 1.63  2000/10/13 11:05:07  MH
  Teile meines rendundanten Codes auskommentiert

  Revision 1.62  2000/10/13 10:50:57  MH
  HDO/Replace:
  - Es werden die Flags Åbernommen, die beim Original gÅltig waren

  Revision 1.61  2000/10/13 00:42:07  rb
  Feineinstellung fÅr Cancel- und Supersedes-Verarbeitung

  Revision 1.60  2000/10/12 10:04:08  MH
  RFC/PPP: E-Mailadresse immer aus 'username@pointname.domain' bilden

  Revision 1.59  2000/10/11 14:09:14  MH
  ReplaceOwn:
  - Fix: DupeCheck konnte evtl. undefiniert sein

  Revision 1.58  2000/10/11 14:00:23  MH
  ReplaceOwn:
  - Es mÅssen sich wenigstens zwei '.' (Punkte) in der FQDN befinden
    ABER nur, wenn MailerDaemon nicht aktiv ist

  Revision 1.57  2000/10/11 13:02:27  MH
  FQDN:
  - Darf bei RFC/PPP nicht leer sein
  - An erster Stelle darf kein Sonderzeichen verwendet werden

  ReplaceOwn:
  - Es mÅssen sich wenigstens zwei '.' (Punkte) in der FQDN befinden

  Revision 1.56  2000/10/11 10:54:49  MH
  ReplOwn: Pollbox-FQDN lîst ihn ebenso aus

  Revision 1.55  2000/10/11 10:13:01  MH
  ReplOwn: 'Eigene Nachrichten halten' wird Åbernommen

  Revision 1.54  2000/10/11 09:16:02  MH
  HDO-Kill beachtet WVL...

  Revision 1.53  2000/10/10 17:50:06  MH
  Alle RÅcklÑufer auf ungelesen setzen

  Revision 1.52  2000/10/10 15:28:30  MH
  ReplaceOwn nun Client- und Netz unabhÑngig...

  Revision 1.51  2000/10/10 13:35:17  MH
  HdrOnlyKill: Fix: Manchmal landete man nach dem
               Pufereinlesen im Netzanrufbericht

  Revision 1.50  2000/10/10 12:28:39  MH
  Repl.Own Fix: Manchmal konnte es vorkommen, da·
                der RÅcklÑufer gekillt wurde

  Revision 1.49  2000/10/10 11:26:12  MH
  Weitere öberarbeitungen...

  Revision 1.48  2000/10/10 02:04:49  MH
  ReplaceOwn Åberarbeitet

  Revision 1.47  2000/10/09 12:01:47  MH
  *** empty log message ***

  Revision 1.46  2000/10/09 11:43:28  MH
  ReplaceOwn: Genaueren Abs. der Pollbox ermitteln

  Revision 1.45  2000/10/09 10:53:12  MH
  ReplaceOwn: RÅcklÑufer als gelesen setzen

  Revision 1.44  2000/10/09 10:41:52  MH
  ReplaceOwn: Es wird die Option: Eigene Nachrichten halten beachtet

  Revision 1.43  2000/10/09 10:09:33  MH
  ReplaceOwn: Sollte nun fÅr alle PollBox-Typen funktionieren

  Revision 1.42  2000/10/07 14:51:38  MH
  HDO: Verwaltung der ZustÑnde abgesichert

  Revision 1.41  2000/10/07 10:08:44  MH
  HDO: Im MenÅ Config/Optionen/Netze/RFC...
  Anzahl der Versuche zur Requestanforderung einstellen

  Revision 1.40  2000/10/06 20:46:17  MH
  HDO-Fix: NntpReplaceOwn hat das packen verhindert

  Revision 1.39  2000/10/06 17:25:06  MH
  RFC/PPP: NntpReplaceOwn ersetzt Originalmsg

  Revision 1.38  2000/10/05 21:03:50  rb
  Kommentar hinzugefÅgt

  Revision 1.37  2000/10/05 18:27:21  rb
  Bugfix fÅr Crosspost-Cancels und -Supersedes

  Revision 1.36  2000/10/01 15:55:43  MH
  HDO: Meldung war verschoben...

  Revision 1.35  2000/10/01 15:23:37  MH
  HDO: Kleinere Detailverbesserungen:
  - Meldungen kînnen vor Zeitablauf durch Tastendruck
    abgebrochen werden

  Revision 1.34  2000/09/30 10:12:28  MH
  HDO:
  - Zur Unterscheidung von Mail: TopOfMail hinzugefÅgt

  Revision 1.33  2000/09/29 11:47:04  MH
  HDO:
  - Filename nun in XP0 definiert

  Revision 1.32  2000/09/29 00:01:59  rb
  Supersedes-Support fÅr incoming

  Revision 1.31  2000/09/28 21:22:29  MH
  HDO:
  - Mail-Request hinzugefÅgt
  - Neuer Filename: REQUEST.ID (gilt fÅr Mail und News)

  Revision 1.30  2000/09/26 14:48:14  MH
  HDO:
  - Noch eine Sicherheit fÅr HDO-Kill hinzugefÅgt (R-Flag wird geprÅft)

  Revision 1.29  2000/09/26 00:15:54  MH
  HDO:
  - Header wird nun auch auf Grî·e '0' abgefragt
  - Ab jetzt gilt nur noch aktuelle Cursor-Position,
    Markierungen haben keinen Einflu· mehr

  Revision 1.28  2000/09/25 16:19:08  MH
  HDO: Lîschflag wird nun nicht mehr gesetzt

  Revision 1.27  2000/09/24 11:44:59  MH
  HDO: Zustandsbyte wird nun beachtet, auch dann, wenn nur gepackt wird

  Revision 1.26  2000/09/24 11:39:19  MH
  HDO: Zustandsbyte wird nun beachtet

  Revision 1.25  2000/09/24 00:52:06  MH
  Fix: Wenn NEWS.ID nicht existiert, gab es eine Fehlermeldung

  Revision 1.24  2000/09/23 21:00:43  MH
  HdrOnly und MsgID-Request:
  - beide im neuen Format: NEWS.ID
  - HdrOnly kann mit F3 ohne Boxauswahl bestellt und abbestellt werden
  - MsgID kann mit F3 ohne Boxauswahl bestellt werden
  - Shift+F3 = Boxauswahl

  Revision 1.23  2000/09/21 17:28:24  MH
  HdrOnlyKill jetzt direkt in Puffereinlesen integriert

  Revision 1.22  2000/09/03 10:02:09  MH
  Sichere Erkennung HeaderOnly-Flag im Header

  Revision 1.21  2000/09/02 20:33:24  MH
  HeaderOnly-Request: Nachtrichten mit 'X-XP-Mode: HdrOnly'
  erhalten in der NachrichtenÅbersicht ein 'H' voran gestellt

  Revision 1.20  2000/07/30 20:03:32  MH
  RFC/PGP: Auch in der englischen Version

  Revision 1.19  2000/07/30 16:14:51  MH
  RFC/PGP: Jetzt auch im PGP-MenÅ

  Revision 1.18  2000/07/29 09:05:05  MH
  PGP - RFC/PPP/UUCP: Nur wenn keine BezÅge vorhanden sind,
  wird ein Key auf Anforderung versendet

  Revision 1.17  2000/07/28 22:31:17  MH
  PGP: Bezug bleibt auch bei RFC erhalten

  Revision 1.16  2000/07/28 17:27:06  MH
  RFC/PPP/UUCP:
  - PGP-Key kann angefordert und automatisch versendet werden
    (Entsprechende Schalter noch nicht implementiert)

  Revision 1.15  2000/07/05 09:06:26  MH
  - Priority Filteratrribut deaktiviert

  Revision 1.14  2000/06/24 08:48:24  tg
  Source-Header neu und Filename auf CVS korrigiert

  Revision 1.13  2000/06/23 14:42:50  tg
  Junk-Brett nennt sich nun wieder Junk

  Revision 1.12  2000/06/22 03:47:06  rb
  Haltezeit-Bug bei ver32 gefixt

  Revision 1.11  2000/06/09 16:43:01  MH
  RFC/PPP: Puffersicherung bei Fehler verbessert

  Revision 1.10  2000/06/08 20:06:20  MH
  Teamname geandert

  Revision 1.9  2000/06/07 15:08:08  MH
  RFC/PPP: Einige Anpassungen korrigiert

  Revision 1.8  2000/06/02 09:46:07  MH
  RFC/PPP: Weitere Anpassungen

  Revision 1.6  2000/04/30 11:34:43  MH
  Altes Datenbankformat wieder hergestellt

  Revision 1.4  2000/04/09 18:23:40  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.9  2000/03/17 13:11:23  mk
  - Testpuffer einlesen jetzt ca. 4x schneller

  Revision 1.8  2000/03/16 10:14:24  mk
  - Ver32: Tickerabfrage optimiert
  - Ver32: Buffergroessen f¸r Ein-/Ausgabe vergroessert
  - Ver32: Keypressed-Routine laeuft nach der letzen ƒnderung wieder

  Revision 1.7  2000/03/14 15:15:39  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.6  2000/02/21 22:48:01  mk
  MK: * Code weiter gesaeubert

  Revision 1.5  2000/02/21 19:25:07  mk
  MH: Bugfix fuer Priority hervorheben

  Revision 1.4  2000/02/21 18:51:47  mk
  MH: Nachrichten mit Prioritaet ab High hervorheben

  Revision 1.3  2000/02/15 20:43:36  mk
  MK: Aktualisierung auf Stand 15.02.2000

}
