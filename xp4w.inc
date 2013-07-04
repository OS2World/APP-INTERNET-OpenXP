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
{ $Id: xp4w.inc,v 1.40 2001/07/19 14:14:29 MH Exp $ }

{ --- User bearbeiten ---------------------------------- }

procedure gochange;
var n : integer;
begin
  disprec[1]:=dbRecno(dispdat); p:=1;
  dbFlushClose(dispdat);
  setall;
  GoPos(1);
  n:=1;
  repeat
    dbSkip(dispdat,-1);
    if not dbBOF(dispdat) and not wrongline then begin
      disprec[1]:=dbRecno(dispdat); inc(p);
    end;
    inc(n);
  until (n=10) or dbBOF(dispdat) or wrongline;
  aufbau:=true;
end;

procedure UserSwitch;
var n  : string[AdrLen];
    ab : byte;
begin
  if dispmode<3 then
    dispmode:=3-dispmode
    else dispmode:=7-dispmode;
  dbGo(ubase,disprec[1]);
  if not empty then begin
    if (dispmode=2) or (dispmode=4) then begin
      dbSkip(ubase,-1);
      if dbBOF(ubase) then dbGoTop(ubase);
      dbReadN(ubase,ub_adrbuch,ab);
      if ab=0 then begin
        disprec[1]:=0;   { war der erste User mit AB-Flag }
        setall;
        aufbau:=true;
        exit;
        end
      else begin
        dbSkip(ubase,1);
        if dbEOF(ubase) then dbGoTop(ubase);
        end;
      end;
    dbReadN(ubase,ub_username,n);
    setall;
    if (dispmode=1) or (dispmode=3) then begin    { Adre·buch }
      dbSeek(ubase,uiAdrbuch,#1+ustr(n));
      if dbEOF(ubase) then disprec[1]:=0
      else disprec[1]:=dbRecno(ubase);
      end;
    aufbau:=true;
    end;
end;

procedure gethdat(abhzeit:integer);
var t,m,j,dow : rtlword;
    tt        : integer;
begin
  if abhzeit=0 then
    abhdatum:=0
  else begin
    getdate(j,m,t,dow); tt:=t;
    dec(tt,abhzeit-1);
    while tt<1 do begin
      dec(m);
      if m=0 then begin
        m:=12; dec(j);
        end;
      inc(tt,monat[m].zahl);
      end;
    abhdatum:=ixdat(formi(j mod 100,2)+formi(m,2)+formi(tt,2)+'0000');
    end;
end;

procedure usermsg_window;      { Userliste -> TO-Brett }
var mhd    : longint;
    halten : integer16;
    p2     : integer;
    bgr    : longint;
    rec    : longint;
begin
  GoP;
  rec:=disprec[p];
  dispspec:='U'+left(dbReadStr(ubase,'username'),40);  { nur fÅr Anzeige }
  _dispspec:=mbrettd('U',ubase);                       { abschneiden     }
  mhd:=abhdatum;
  dbReadN(ubase,ub_haltezeit,halten);
  gethdat(halten);
  bgr:=brettgruppe;
  brettgruppe:=NetzGruppe;
  selcall(10,gl-1);
  brettgruppe:=bgr;
  abhdatum:=mhd;
  if not kb_ctrl and userweiter and not dbDeleted(ubase,rec) then begin
    dbGo(ubase,rec);
    if Forth then begin
      p2:=p+1;
      if not dbEOF(dispdat) then
        if p2<=gl then p:=p2
        else begin
          disprec[1]:=dbRecno(dispdat);
          p:=1;
          aufbau:=true;
        end
      else begin
        t:=keyend;
        lastt:='';
      end;
    end;
  end;
end;

procedure change_adressbuch;
var ab        : byte;
    _brett,
    _mbrett   : string[5];
begin
  GoP;
  dbRead(ubase,'adrbuch',ab);
  _brett:=mbrettd('U',ubase);
  dbSeek(mbase,miBrett,_brett);
  if dbEOF(mbase) then _mbrett:=''
  else dbReadN(mbase,mb_brett,_mbrett);
  if (ab=1) and (_mbrett=_brett) then begin
    rfehler(416);  { 'Im Brett dieses Users sind noch Nachrichten vorhanden!' }
    exit;
    end;
  ab:=1-ab;
  dbWrite(ubase,'adrbuch',ab);
  dbFlushClose(ubase);
  if (ab=0) and (p=1) or (p=gl) then begin
    if p=1 then
      if disprec[2]=0 then dbGoTop(dispdat)
      else dbGo(dispdat,disprec[2]);
    aufbau:=true;
    end;
  RedispLine;
end;

procedure neuer_user;
begin
  if newuser then   { in xp4e }
    gochange;
end;

procedure user_aendern(msgbrett:boolean);
begin
  GoP;
  if modiuser(msgbrett) then
    RedispLine;
end;

procedure udelete;
begin
  dbDelete(ubase);
  if p=1 then DispRec[1]:=0;
  aufbau:=true; xaufbau:=true;
end;

procedure loeschuser;
var _user,_brett : string[5];
begin
  GoP;
  _user:=mbrettd('U',ubase);
  dbSeek(mbase,miBrett,_user);
  if not dbEOF(mbase) then
    dbRead(mbase,'Brett',_brett);
  if not dbEOF(mbase) and (_user=_brett) then
    rfehler(416)
  else
    udelete;
end;

procedure edit_password(msgbrett:boolean);
begin
  GoP;
  editpass(msgbrett);      { in xp4e }
  RedispLine;
end;

procedure user_suche;
var su  : boolean;
    rec : longint;
begin
  GoPos(1);
  su:=UserMarkSuche(dispmode=2);
  rec:=dbRecno(ubase);
  if su then UserSwitch;
  disprec[1]:=rec;
end;

procedure neuer_verteiler;
begin
  if newverteiler then
    gochange;
end;

procedure verteiler_aendern;
begin
  GoP;
  if modiverteiler then
    RedispLine;
end;

procedure edverteiler;
var anz : integer;
    brk : boolean;
    rec : longint;
    p2  : integer;
begin
  GoP;
  rec:=disprec[p];
  edit_verteiler(vert_name(dbReadStr(ubase,'username')),anz,brk);
  if not brk then begin
    dbGo(ubase,rec);
    dbWriteN(ubase,ub_haltezeit,anz);
  end;
  setall;
  if not kb_ctrl and userweiter and not dbDeleted(ubase,rec) then begin
    dbGo(ubase,rec);
    if Forth then begin
      p2:=p+1;
      if not dbEOF(dispdat) then
        if p2<=gl then p:=p2
        else begin
          disprec[1]:=dbRecno(dispdat);
          p:=1;
        end
      else begin
        t:=keyend;
        lastt:='';
      end;
    end;
  end;
  aufbau:=true; xaufbau:=true;
end;

procedure verteiler_loeschen;
var name : string[AdrLen];
begin
  GoP;
  dbReadN(ubase,ub_username,name);
  name:=vert_name(name);
  if ReadJN(getreps(418,name),true) then begin   { 'Verteiler %s lîschen' }
    del_verteiler(name);
    udelete;
    end;
end;

function isverteiler:boolean;
begin
  GoP;
  isverteiler:=(dbReadInt(ubase,'userflags') and 4<>0);
end;

function keinverteiler:boolean;
begin
  if isverteiler then begin
    rfehler(417);   { 'Bei Verteilern nicht mîglich!' }
    keinverteiler:=false;
    end
  else
    keinverteiler:=true;
end;

procedure usersprung(vor:boolean);   { zum nÑchsten/letzten markierten User }
var rec,n : longint;
  procedure incn;
  begin
    inc(n);
    if n=gl then rmessage(432);
  end;
begin
  GoP;
  n:=0;
  if vor then
    repeat
      dbNext(ubase);
      incn;
    until dbEOF(ubase) or UBmarked(dbRecno(ubase))
  else
    repeat
      dbSkip(ubase,-1);
      incn;
    until dbBOF(ubase) or ((dispmode=1) and even(dbReadInt(ubase,'adrbuch')))
          or UBmarked(dbRecno(ubase));
  if n>=gl then closebox;
  rec:=dbRecno(ubase);
  if UBmarked(rec) then begin
    p:=gl;
    while (p>0) and (disprec[p]<>rec) do dec(p);
    if p=0 then begin
      disprec[1]:=rec;
      { dbGo(ubase,rec); }
      p:=1;
      aufbau:=true;
      end;
    end;
end;


{ --- Nachrichten bearbeiten --------------------------- }

procedure to_window;           { Nachrichten-Fenster -> TO-Brett }
var s      : string[adrlen];
    d1     : longint;
    oldds  : specstr;
    _oldds : string[5];
    mhd    : longint;
    halten : integer16;
    size   : smallword;
    hdp    : headerp;
    hds    : longint;

  procedure makeuser;
  var
    pollbox  : string[BoxNameLen];
  begin
    dbSeek(bbase,biIntnr,copy(dbReadStr(mbase,'brett'),2,4));
    if dbFound then       { mÅ·te IMMER true sein }
      dbReadN(bbase,bb_pollbox,pollbox)
    else
      pollbox:=DefaultBox;
    ReplaceVertreterbox(pollbox,true);
    xp3.makeuser(s,pollbox);
  end;

begin
  d1:=disprec[1];             { Mu· gesichert werden, da Zielfenster }
  GoP;
  if left(dbReadStr(mbase,'brett'),1)='U' then
    fehler('In diesem Brett nicht mîglich.')
  else begin
    new(hdp);
    ReadHeader(hdp^,hds,false);
    s:='';
    if hdp^.PmReplyTo<>'' then begin
      dbSeek(ubase,uiName,ustr(hdp^.PmReplyTo));
      if dbFound then
        if ReadJN(getres(2742),true) then { 'Vertreter der Nachricht aufsuchen' }
      s:=hdp^.PmReplyTo;
    end;
    if s='' then
      dbReadN(mbase,mb_absender,s);   { auch auf mbase arbeitet.     }
    dispose(hdp);
    dbSeek(ubase,uiName,ustr(s));
    if not dbFound then
      rfehler(444)  { 'User nicht erfa·t' }
    else begin
      if dbXsize(ubase,'adresse')>0 then begin  { Vertreteradresse? }
        size:=0;
        dbReadX(ubase,'adresse',size,s);
        dbSeek(ubase,uiName,ustr(s));
        if not dbFound then
          if ReadJN(getres(2738),true) then   { 'Vertreter nicht in der Datenbank - neu anlegen' }
            makeuser else
          begin
            dbReadN(mbase,mb_absender,s);
            dbSeek(ubase,uiName,ustr(s));
          end       { 'Vertreter des Users aufsuchen' }
        else if not ReadJN(getres(2741),true) then begin
          dbReadN(mbase,mb_absender,s);
          dbSeek(ubase,uiName,ustr(s));
        end;
      end;
      dbGo(ubase,dbRecno(ubase));
      oldds:=dispspec;
      _oldds:=_dispspec;
      dispspec:='U'+left(s,40);
      _dispspec:=mbrettd('U',ubase);
      mhd:=abhdatum;
      dbReadN(ubase,ub_haltezeit,halten);
      gethdat(halten);
      selcall(10,gl);
      abhdatum:=mhd;
      dispspec:=oldds;
      _dispspec:=_oldds;
      disprec[1]:=d1;
      aufbau:=true;
      end;
    end;
end;


procedure SetKomOfs1;
begin
  if dispmode<>12 then exit;
  komofs:=0;
  while (komofs<komanz) and (kombaum^[komofs].msgpos<>dbRecno(mbase)) do
    inc(komofs);
  if komofs>=komanz then begin
    write(#7); komofs:=0; end;
end;

procedure GoDown(first:boolean);
begin
  if p<gl then begin
    t:=keydown; lastt:=''; end
  else
    if Forth then begin
      {Back;}
      disprec[1]:=dbRecno(mbase);
      SetKomOfs1;
      if (dispmode in [10..12]) {and (rdmode=rmUngelesen)} and first then p:=1
        else p:=2;
      aufbau:=true;
    end;
end;


procedure GrabP;
begin
  p:=1;
  while (disprec[p]<>0) and (p<=gl) and (disprec[p]<>dbRecno(mbase)) do
    inc(p);
  if (disprec[p]=0) or (p>gl) then begin
    disprec[1]:=dbRecno(mbase);
    SetKomOfs1;
    aufbau:=true;
    p:=1;
  end
  else
    GoP;
end;

procedure _BezSeek(back:boolean);   { Nachricht mit gleichem Bezug suchen }
begin
  GoP;
  if BezSeek(back) then
    GrabP;
end;

procedure _BezSeekBezug;
begin
  GoP;
  if BezSeekBezug then
    GrabP;
end;

procedure _BezSeekKommentar;
begin
  GoP;
  if BezSeekKommentar then
    GrabP;
end;


{ art: 0=normal, 1=Rot13, 2=HexDump }
{ mp:  0=kein Multipart, 1=Auto, 2=Multipart }

{ Viewer-PrioritÑt:    1. Viewer fÅr passenden MIME-Typ }
{                      2. interner Archiv-Viewer        }
{                      3. externer Viewer fÅr */*       }
{                      4. Lister                        }

procedure read_msg(art,mp:byte);
var fn     : pathstr;
    fn2    : pathstr;
    typ    : char;
    arc    : shortint;
    _down  : boolean;
    nw     : boolean;
    lres   : shortint;
    ende   : boolean;
    pushed : boolean;
    first  : boolean;
    pt     : scrptr;
    lksave : boolean;
    netztyp: shortint;
    ldisp  : string[brettlen{40}];
    sbrett : string[brettlen];
    l,r,o,u: boolean;
    sm2t   : boolean;
    skeydisp : boolean;
    {dp,}dpp : longint;    { disprec[p] bei Prozedurstart } { !! }
    kk     : boolean;    { Kommentarverkettung benutzt }
    d1_0   : boolean;
    FileAttach : boolean;
    brk    : boolean;
    abs    : string[AdrLen];
    miso   : boolean;
    rec    : longint;
    multipart : boolean;
    mpdata : multi_part;
    mpselect : boolean;
    lastmpsel: boolean;
    mpart_nr : integer;    { anzuzeigender Nachrichtenteil }
    poppush  : boolean;
    mimetyp  : string[30];
    viewer   : ViewInfo;

  procedure CopyMsg;
  var f1,f2 : file;
  begin
    assign(f1,fn);
    if existf(f1) then begin
      assign(f2,fn2);
      rewrite(f2,1);
      reset(f1,1);
      seek(f1,extheadersize);
      fmove(f1,f2);
      close(f1);
      close(f2);
      end;
  end;

  procedure SetGelesen;
  var b     : byte;
      brett : string[5];
      nt    : byte;
      flags : byte;
      rflag : boolean;
      rec,
      rec2  : longint;
      crc   : string[4];
      mi    : shortint;
  begin
    if dbEOF(mbase) then exit;
    dbReadN(mbase,mb_gelesen,b);
    nt:=mbNetztyp;
    dbReadN(mbase,mb_unversandt,flags);
    rflag:=false;
    if (b=0) or ((nt=nt_Maus) and (flags and 32<>0)) then begin
      dbReadN(mbase,mb_brett,brett);       { ^^ Maus-zurÅckgestellt }
      if (nt=nt_Maus) and MausLeseBest and ((brett[1]='1') or (brett[1]='U'))
      then
        if briefsent then begin
          flags:=flags and (not 32);
          dbWriteN(mbase,mb_unversandt,flags);
          rflag:=true;
        end
        else
          rflag:=MausBestPM
      else
        rflag:=true;
      if rflag then begin
        b:=1;
        dbWriteN(mbase,mb_gelesen,b);
        if dbReadInt(mbase,'netztyp') shr 24<>0 then begin  { Crossposting }
          rec:=dbRecno(mbase);
          crc:=left(dbReadStr(mbase,'msgid'),4);
          mi:=dbGetIndex(bezbase); dbSetIndex(bezbase,beiMsgID);
          dbSeek(bezbase,beiMsgID,crc);     { alle Kopien auf 'gelesen' }
          if dbFound then begin
            while not dbEOF(bezbase) and (dbLongStr(dbReadInt(bezbase,'msgid'))=crc)
            do begin
              dbReadN(bezbase,bezb_msgpos,rec2);
              if (rec2<>rec) and not dbDeleted(mbase,rec2) then begin
                dbGo(mbase,rec2);
                b:=1;
                dbWriteN(mbase,mb_gelesen,b);
                dbReadN(mbase,mb_brett,brett);
                dbSeek(mbase,miGelesen,brett+#0);
                if not dbEOF(mbase) and
                   ((dbReadStr(mbase,'brett')<>brett) or (dbReadInt(mbase,'gelesen')<>0))
                then begin
                  dbSeek(bbase,biIntnr,mid(brett,2));
                  if dbFound then begin
                    dbReadN(bbase,bb_flags,b);
                    b:=b and (not 2);   { keine ungelesenen Nachrichten mehr }
                    dbWriteN(bbase,bb_flags,b);
                  end;
                end;
              end;
              dbNext(bezbase);
            end;
            dbGo(mbase,rec);
          end;
          dbSetIndex(bezbase,mi);
        end;
        U_read:=true;
      end;
    end;
    dispbuf[p]^[2]:=' ';
  end;

  procedure GoMsgBack;    { '-' -> zurÅck }
  begin
    SetGelesen;
    if multipart and not mpdata.alternative and (mpart_nr>1) then begin
      dec(mpart_nr);
      ende:=false;
    end
    else
    if p>1 then {begin}
      if disprec[p-1]<>0 then begin
        dec(p); ende:=false;
        mpart_nr:=maxint;
      end
      else
    else begin
      GoP;
      {GoPos(1);}
      if Back then begin
        scrolldown(false);
        disprec[1]:=dbRecno(dispdat);
        write_disp_line(1,p,false);
        if dispmode=12 then dec(komofs);
        mpart_nr:=maxint;
        ende:=false;
      end;
    end;
    {aufbau:=true;}
    mdisplay:=true;
  end;

  procedure GoMsgForth;       { '+' -> vorwÑrts }
  begin
    SetGelesen;
    if multipart and not mpdata.alternative and
       (mpart_nr>0) and (mpart_nr<mpdata.parts)
    then begin
      inc(mpart_nr);
      ende:=false;
    end
    else
    (*   mAx: kann bei disprec[p]=0 zum Absturz fÅhren
    if (p<gl) and (disprec[p+1]<>0) then begin
      inc(p);
      ende:=false;
      mpart_nr:=1;
    end
    *)
    if (p<gl) then
      if disprec[p+1]<>0 then begin
        inc(p); ende:=false; mpart_nr:=1;
      end
      else
    else begin
      GoP;
      if Forth then begin
        scrollup(false);
        disprec[gl]:=dbRecno(dispdat);
        write_disp_line(gl,p,false);
        if dispmode=12 then inc(komofs);
        mpart_nr:=1;
        ende:=false;
      end;
    end;
    {aufbau:=true;}
    mdisplay:=true;
  end;

  procedure SetKK;
  begin
    if kk then
      disprec[p]:=dpp{aktdisprec{dp};
    kk:=false;
    {GoP;}
  end;

  procedure ExtractKom(fn:pathstr);
  var hdp : headerp;
      hds : longint;
      f   : file;
  begin
    new(hdp);
    ReadHeader(hdp^,hds,true);
    assign(f,fn);
    rewrite(f,1);
    XreadIsoDecode:=true;
    Xreadf(hds,f);
    seek(f,hdp^.komlen);
    if hdp^.komlen>0 then truncate(f);
    close(f);
    dispose(hdp);
  end;

  function GetMsgFilename:string;
  var hdp : headerp;
      hds : longint;
  begin
    new(hdp);
    ReadHeader(hdp^,hds,false);
    GetMsgFilename:=hdp^.datei;
    dispose(hdp);
  end;

  function getsbrett:string;
  var hdp : headerp;
      hds : longint;
  begin
    new(hdp);
    ReadHeader(hdp^,hds,false);
    getsbrett:=hdp^.empfaenger;
    dispose(hdp);
  end;

label ende0,nextmsg;

begin
  pushed:=false;
  first:=true;
  kk:=false;
{  dp:=disprec[p]; { !! }
{  dpp:=dp;        { !! }
  dpp:=disprec[p];
  d1_0:=false;
  briefsent:=false;
  mpselect:=true;
  mpart_nr:=1;
  poppush:=true;

  repeat                { +/- - Schleife }
    ende:=true;
    GoP;
    aktdisprec:=dbRecno(mbase);

    dpp:=aktdisprec;

    { FileAttach -> Abfrage, ob Datei oder Text angezeigt werden soll }

    FileAttach:=(dbReadInt(mbase,'netztyp') and $200)<>0;
    if FileAttach then begin
      fn:=Readmsg_GetFilename;
      if not exist(fn) then
        FileAttach:=false
      else if dbReadInt(mbase,'groesse')>4 then begin
        pushhp(81);
        brk:=false;
        FileAttach:=ReadJNesc(getres(430),false,brk);   { 'Dateiinhalt anzeigen' }
        pophp;
        if brk then goto ende0;
      end;
    end;

    { Im folgenden Block werden die Variablen fn2, arc, typ, mpdata,    }
    { mpart_nr und viewer entsprechend der gewÑhlten Nachricht gesetzt: }

    if FileAttach then begin
      fn2:=fn;
      GetExtViewer(fn2,viewer);
      if viewer.prog<>'' then arc:=0
      else begin
        arc:=ArcType(fn);
        if ArcRestricted(arc) then arc:=0;
      end;
      typ:='B';
      fillchar(mpdata,sizeof(mpdata),0);
      mpart_nr:=1;
    end

    else begin
      fn:=TempS(dbReadInt(mbase,'msgsize')+5000);
      dbReadN(mbase,mb_typ,typ);
      if (typ='B') and (art<>2) and (dbReadInt(mbase,'netztyp') and $8000<>0) and
         ReadJN(getres(433),false) then begin     { 'Kommentar anzeigen' }
        ExtractKom(fn);
        if listfile(fn,'Kommentar',true,false,0)=0 then;
        _era(fn);
        goto ende0;
      end;

      dbReadN(mbase,mb_mimetyp,mimetyp);
      if (mimetyp='') and (mp<>0) and
         ((dbReadInt(mbase,'flags') and 4<>0) or (mp=2)) then
        mimetyp:='multipart/mixed';
      GetMimeViewer(mimetyp,viewer);

      multipart:=(viewer.prog='') and   { multipart -> *interner* Mulitpart-Viewer }
                 ( (mp=2) or (left(mimetyp,10)='multipart/') or
                   ((mp=1) and (dbReadInt(mbase,'flags') and 4<>0)) ) and
                 (mp<>0);
     if multipart then
      begin
        pushhp(94);
        if mpselect and pushed and poppush then begin
          holen(pt); sichern(pt);
        end;
        SelectMultiPart(mpselect,mpart_nr,mp=2,mpdata,brk);
        pophp;
        if brk then goto nextmsg;
        mpart_nr:=mpdata.part;
        if mpdata.startline>0 then begin
          if mpdata.typ<>'' then
            mimetyp:=compmimetyp(mpdata.typ+'/'+mpdata.subtyp)
          else
            mimetyp:='text/plain';
          GetMimeViewer(mimetyp,viewer);
          if viewer.prog<>'' then viewer.fn:=mpdata.fname;
        end;
      end
      else begin
        fillchar(mpdata,sizeof(mpdata),0);
        mpart_nr:=1;
      end;

      poppush:=true;
      ExtractSetMpdata(@mpdata);
      extract_msg(iif(art=2,xTractDump,xTractHead),'',fn,false,iif(art=1,-1,1));
      if mpdata.code=mcodeBase64 then
        typ:='B';

      if (typ='B') and (art<>2) and (dbReadInt(mbase,'unversandt') and 2=0)
         and (viewer.prog='') then begin       { keine BinÑr-Versandmeldung }
        fn2:=TempS(_filesize(fn)+5000);
        CopyMsg;
        GetExtViewer(GetMsgFilename,viewer);
        if viewer.prog='' then
          TestGifLbmEtc(fn2,true,viewer);   { fÅr Z3.8, MaggiPoll etc. }
        if viewer.prog='' then begin
          arc:=ArcType(fn2);
          if ArcRestricted(arc) then arc:=0;
        end;
      end
      else begin
        fn2:='';
        arc:=0;
      end;

      if (viewer.prog='') and (arc=0) then begin
        if mimetyp='' then
          GetMimeViewer('text/plain',viewer);
        if (viewer.prog='') and (mimetyp<>'') then
          GetDefaultViewer(mimetyp,viewer);   { Viewer fÅr */* }
      end;

    end;      { of not FileAttach }
    { Nachricht anzeigen }

    nw:=NachWeiter;   { kann vom Lister verÑndert werden }
    netztyp:=dbReadInt(mbase,'netztyp') and $ff;
    if viewer.prog='*intern*' then viewer.prog:='';
    if viewer.prog<>'' then begin      { externer Viewer }
      if fn2='' then begin
        fn2:=TempS(_filesize(fn)+5000);
        CopyMsg;
      end;
      if (viewer.fn='') then viewer.fn:=GetMsgFilename;
      ViewFile(fn2,viewer,fileattach);
      lres:=0;
    end
    else
      if arc=0 then begin              { Lister }
        if (dbReadInt(mbase,'netztyp') and $ff in [nt_Fido,nt_QWK]) then begin
          fnproc[0,3]:=Fido_Msgrequest;
          dbReadN(mbase,mb_absender,abs);
          FMsgReqnode:=mid(abs,cpos('@',abs)+1);
        end;
        if not pushed then begin
          if first then showline(p,0);
          first:=false;
          sichern(pt);
          pushed:=true;
        end; { Statuszeile: Brett im Lister NetztypabhÑngig fÅttern }
        if (dispmode in [10..12]) then begin
          if dispmode in [11,12] then
            sbrett:=getsbrett
          else
            sbrett:=dispspec;
          if pos('FIDO/', sbrett)<>0 then
            sbrett:=copy(sbrett,pos('FIDO/', sbrett)+4,length(sbrett)-5);
          ldisp:=right(rfcbrett(sbrett),40);
        end
          else ldisp:='';
        if (dispmode<>11) and KomArrows and ntKomkette(netztyp) then begin
          GetKomflags(l,r,o,u);
{          ldisp:=iifc(l,#27,' ')+iifc(o,#24,' ')+iifc(u,#25,' ')+iifc(r,#26,' ')
                 +' '+right(sp(40)+ldisp,35);}
          ldisp:=iifc(l,iifc(r,#29,#27),iifc(r,#26,' '))+iifc(o,iifc(u,#18,#24),iifc(u,#25,' '))
                 +'  '+right(sp(40)+ldisp,36);
        end;
        lksave:=listkommentar;
        listkommentar:=ntKomkette(netztyp);
        miso:=ConvIso;
        if dbReadInt(mbase,'netztyp') and $2000<>0   { CHARSET: ISO1 }
          then ConvIso:=false;
        lres:=Listfile(fn,ldisp,false,true,1+iif(art<>2,2,0));
        ConvIso:=miso;
        listkommentar:=lksave;
        fnproc[0,3]:=dummyFN;
      end
      else begin    { arc <> 0 }       { interner Archiv-Viewer }
        if pushed then begin
          holen(pt);
          pushed:=false;
        end;
        lres:=ViewArchive(fn2,arc);
        setall;
      end;

    { aufrÑumen ... }

    if not FileAttach then begin
      if fn2<>'' then _era(fn2);    { Temp-Dateien lîschen }
      if exist(fn) then _era(fn);
    end;
    lastmpsel:=mpselect;
    mpselect:=false;
    _down:=NachWeiter;
    dbFlush(mbase);

    { Je nach Lister/Viewer-Ergebnis Funktion beenden oder zu    }
    { einer anderen Nachricht oder einem anderen Nachrichtenteil }
    { springen:                                                  }

    if lres=4 then begin
      sm2t:=m2t; m2t:=false;
      skeydisp:=keydisp; keydisp:=false;
      rec:=dbRecno(mbase);
      spush(disprec,sizeof(disprec));
      qmpdata:=@mpdata;
      _brief_senden(listkey[1]);

      {if (dispmode=10) and (rdmode=1) then aufbau:=false;}

      qmpdata:=nil;
      if disprec[p]=0 then      { s. xp4.pm_archiv (auto-Archiv) }
        d1_0:=true;
      spop(disprec);
      dbGo(mbase,rec);
      if ListQuoteMsg<>'' then begin
        if exist(ListQuoteMsg) then _era(ListQuoteMsg);
        ListQuoteMsg:='';
      end;
      keydisp:=skeydisp;
      m2t:=sm2t;
      if disprec[p]=0 then begin    { s. xp4.pm_archiv (auto-Archiv) }
        disprec[p]:=dbRecno(mbase);
        d1_0:=true;
      end;
      mpselect:=lastmpsel; poppush:=false;
      ende:=false;
    end
    else begin
     {  if (dispmode=10) and (rdmode=1) and not ntKomKette(netztyp) then
        lres:=0;  { !! ungelesen-Mode }
      if (dispmode<>11) and ntKomkette(netztyp) and (lres<>0) then begin
        if lres<6 then SetGelesen;
        case lres of
          -1 : if BezSeekBezug then ende:=false;         { - }
           1 : if BezSeekKommentar then ende:=false;     { + }
           2 : if BezSeek(true) then ende:=false;        { links }
           3 : if BezSeek(false) then ende:=false;       { rechts }
           5 : begin dbGo(mbase,dpp); ende:=false; end;  { !! }
           6 : begin                                     { ^PgUp }
                 SetKK; GrabP; GoMsgBack; dpp:=dbRecno(mbase); { !! }
                 {GoP;} { !! }
                 ende:=false;
               end;
           7 : begin                                     { ^PgDn }
                 SetKK; {if disprec[p+1]<>0 then} GoMsgForth; dpp:=dbRecno(mbase); { !! }
                 {else begin
                   disprec[p]:=dbRecno(mbase);
                   kk:=true; SetKK;
                   if disprec[p+1]<>0 then GoMsgForth;
                 end;}

                 {GoP;} { !! }
                 ende:=false;
               end;
        end;
        if lres<6 then
          if not ende then begin
            {GrabP;} kk:=true;
            disprec[p]:=dbRecno(mbase);
            mpart_nr:=1;
            if u_read then aufbau:=true;
          end
          else begin
            errsound;
            ende:=false;
          end;
      end
      else
        case lres of
          0 : if lastmpsel and multipart and (mpdata.parts>1) and
                 not mpdata.alternative
              then begin
                dbGo(mbase,dpp);
                SetGelesen;
                if (mpart_nr>0) and (mpart_nr<mpdata.parts) then
                  inc(mpart_nr);
                mpselect:=true;
                ende:=false;
              end
              else begin
                dbGo(mbase,dpp);
                SetGelesen;
              nextmsg:
                SetKK;
                if not aufbau then write_disp_line(p,0,true);
                if _down {and ((rdmode<>1) or ende)} then
                  GoDown(true);
                {if (dispmode in [10..12]) and (rdmode<>1) then aufbau:=true; { !! }
                {if not u_read and (dispmode=10) and (rdmode=1) then t:='';} { !! }
                NachWeiter:=nw;
              end;
         -1,6 : GoMsgBack;
          1,7 : {if disprec[p+1]<>0 then} GoMsgForth;
        end;
      end;

  until ende;    { Ende +/- - Schleife }

ende0:
  {freeres;}
  {disprec[p]:=dp;}
  if pushed then holen(pt);
  if d1_0 then disprec[1]:=0;
end;

procedure setmstat(newstat:byte);
var b         : byte;
begin
  GoP;
  dbRead(dispdat,'HalteFlags',b);
  if b=newstat then newstat:=0;
  dbWrite(dispdat,'HalteFlags',newstat);
  if newstat<>1 then mailreq; { Bei TopOfMail Requester starten }
  reread_line;
  GoDown(false);
end;

procedure _mark_;
var msgs : boolean;
begin
  msgs:=(dispmode>=10) and (dispmode<=19);
  GoP;
  if markflag[p]<>0 then begin
    if msgs then
      MsgUnmark
    else
      UBUnmark(disprec[p]);
    markflag[p]:=0;
    if (dispmode<1) or (dispmode>9) then dispbuf[p]^[1]:=' ';
    end
  else
    if iif(msgs,markanz,bmarkanz)=iif(msgs,maxmark,maxbmark) then
      fehler(getreps(iif(msgs,419,420),strs(iif(msgs,maxmark,maxbmark))))
    else begin
      if msgs then
        MsgAddmark
      else
        UBAddMark(disprec[p]);
      markflag[p]:=1;
      if (dispmode<1) or (dispmode>9) then dispbuf[p]^[1]:=suchch;
      end;
  showline(p,p);
  t:=keydown; lastt:='';
end;

procedure MarkedUnmark;
begin
  GoP;
  MsgUnmark;
  aufbau:=true;
  if p=1 then begin
    if markpos=markanz then begin
      markpos:=max(0,markpos-gl);
      p:=min(gl,markanz);
    end;
    disprec[1]:=iif(markanz=0,0,marked^[markpos].recno);
  end;
end;

procedure _mark_group;
var grnr : longint;
begin
  moment;
  GoP;
  dbRead(dispdat,'gruppe',grnr);
  dbGoTop(dispdat);
  while (bmarkanz<maxbmark) and not dbEOF(dispdat) do begin
    if dbReadInt(dispdat,'gruppe')=grnr then
      UBAddMark(dbRecno(dispdat));
    dbSkip(dispdat,1);
  end;
  if bmarkanz=maxbmark then
    fehler(getreps(420,strs(maxbmark)));
  aufbau:=true;
  closebox;
end;

procedure _unmark_;
begin
  if (dispmode>=10) and (dispmode<=19) then markanz:=0
  else bmarkanz:=0;
  aufbau:=true;
end;

procedure killit(ask:boolean);
var gel : byte;
begin
  GoP;
  mailreq;     { Bei TopOfMail Requester starten }
  reread_line;
  dbReadN(mbase,mb_gelesen,gel);
  if _killit(ask) then begin
    if gel=0 then U_read:=true;
    if p=1 then DispRec[1]:=0;   { nicht := DispRec[2] !! }
  end;
end;

procedure show_info;
var s : string[80];
    {b : byte;}
    sbrett:string[brettlen];
begin
  attrtxt(col.colmsgsinfo);
  if dispmode=11 then
    mwrt(1,4,forms(getreps(421,strs(markanz)),80))  { 'markierte Nachrichten' }
  else if dispmode=12 then
    mwrt(1,4,forms(getreps(422,bezbetr)        { ' Bezugsnachrichten zu "%s"' }
                   +' ('+strs(komanz)+'/'+strs(maxebene)+')',80))
  else begin
    case rdmode of
      0 : s:='';
      1 : s:='  -  '+getres(423);   { 'ungelesene Nachrichten' }
      2 : s:=iifs(length(dispspec)<38,'  -  ',' - ')+getres(424);
                               { 'Nachrichten seit dem letzten Netcall' }
    else
      s:='  -  '+getreps(425,fdat(longdat(readdate)));  { 'Nachrichten seit dem %s' }
    end;
    {
    if UserSlash or (left(dispspec,1)>='A') or (copy(dispspec,2,1)<>'/') then
      b:=2
    else b:=3;    { Brett netztypabhÑngig anzeigen }
    sbrett:=rfcbrett(dispspec);
    if pos('FIDO/', sbrett)<>0 then
      sbrett:=copy(sbrett,pos('/', sbrett)+1,80);
    mwrt(1,4,' '+forms(sbrett+s,79));
    {mwrt(1,4,' '+forms(copy(rfcbrett(dispspec),b,80)+s,79));}
  end;
end;

procedure weiterleit_info;
var s : string[80];
begin
  attrtxt(col.colBretterHi);
  if ArchivWeiterleiten then
    s:=getres(426)      { ' Archivbrett wÑhlen:' }
  else
    if dispmode=-1 then
      s:=getres(427)    { ' Zielbrett wÑhlen' }
    else
      s:=getres(428);   { ' EmpfÑnger wÑhlen' }
  mwrt(1,4,forms(s,80));
end;

procedure all_mode;
begin
  if readmode>0 then begin
    if rdmode=readmode then rdmode:=0
    else rdmode:=readmode;
    setall;
    gostart;
    show_info;
    end;
end;

procedure testsuche(t:taste);
begin
  if (t='/') or (t='.') then begin
    suchen:=true;
    if dispmode<1 then suchst:='/'
    else suchst:='';
    end;
end;

procedure suchchar(ch:char);
var s       : string[90];
    adrb,pp : byte;
    newsuch : string[maxsuch];

  procedure suchok;
  begin
    suchst:=newsuch;
    disprec[1]:=dbRecno(dispdat);
    p:=1;
    aufbau:=true;
  end;

begin
  newsuch:=suchst;
  if ch=keybs then
    if newsuch='' then begin
      errsound; exit; end
    else dellast(newsuch)
  else
    if length(newsuch)=maxsuch then begin
      errsound; exit; end
    else
      if (dispmode>0) or (ch<>'/') then
        newsuch:=newsuch+UpCase(ch);

  if (dispmode<1) then begin
    dbSeek(bbase,biBrett,'A'+ustr(newsuch));
    if not dbEOF(bbase) then begin
      dbReadN(bbase,bb_brettname,s);
      delfirst(s);
      if ustr(left(s,length(newsuch)))<>ustr(newsuch) then
        errsound
      else if ch<>'/' then
        suchok
      else begin
        pp:=pos('/',mid(s,length(newsuch)+1));
        if pp=0 then begin
          dbSeek(bbase,biBrett,'A'+ustr(s)+'/');
          if not dbEOF(bbase) and (left(dbReadStr(bbase,'brettname'),length(s)+2)='A'+s+'/')
          then begin
            newsuch:=s+'/';
            suchok;
            end
          else
            errsound;
          end
        else begin
          newsuch:=left(s,pp+length(newsuch));
          suchok;
          end;
        end
      end
    end
  else begin
    if (dispmode=1) or (dispmode=3) then
      dbSeek(ubase,uiAdrbuch,#1+ustr(newsuch))
    else
      dbSeek(ubase,uiName,ustr(newsuch));
    if not dbEOF(ubase) then begin
      dbReadN(ubase,ub_username,s);
      dbReadN(ubase,ub_adrbuch,adrb);
      if (((dispmode=1) or (dispmode=3)) and (adrb=0)) or
         (left(ustr(s),length(newsuch))<>ustr(newsuch)) then
        errsound
      else
        suchok;
      end;
    end;
end;

procedure SwitchDatum;
begin
  ShowMsgDatum:=not ShowMsgDatum;
  aufbau:=true;
end;

procedure spezialmenue;
begin
  if empty then
    rfehler(418)    { 'keine Nachrichten vorhanden' }
  else begin
    Smenu(t);
    c:=UpCase(t[1]);
    end;
end;


procedure wiedervorlage;
var wvdat : longint;
    flags : byte;
begin
  GoP;
{   if left(dbReadStr(mbase,'brett'),1)='U' then
    fehler('Wiedervorlage hier nicht mîglich!') }
  dbReadN(mbase,mb_unversandt,flags);
  if flags and 8 = 0 then begin
    dbReadN(mbase,mb_empfdatum,wvdat);
    dbWriteN(mbase,mb_wvdatum,wvdat);
    wvdat:=ixDat('2712310000');
    dbWriteN(mbase,mb_empfdatum,wvdat);
    end
  else begin
    dbReadN(mbase,mb_wvdatum,wvdat);
    dbWriteN(mbase,mb_empfdatum,wvdat);
    end;
  flags:=flags xor 8;
  dbWriteN(mbase,mb_unversandt,flags);
  if left(dbReadStr(mbase,'brett'),1)<>'U' then
    RereadBrettdatum(dbReadStr(mbase,'brett'));
  aufbau:=true;
  if (dispmode<>11) and (dispmode<>12) and (p=1) and (disprec[2]<>0) then
    disprec[1]:=disprec[2];
end;


{ --- Bretter bearbeiten ------------------------------- }

procedure msg_window(alle:boolean);   { BrettÅbersicht->Nachrichtenfenster }
var dat    : longint;
    p2     : integer;
    mdr    : dispra;
    flags  : byte;
    halten : integer16;
    mhd    : longint;
    _brett : string[5];
    weiter : boolean;

  procedure mw1;   { Aufteilung zum Stack-Platz-sparen }
  begin
    dbReadN(bbase,bb_brettname,dispspec);
    _brett:=mbrettd(dispspec[1],bbase);
    _dispspec:=_brett;
    mhd:=abhdatum;
    if odd(dbReadInt(bbase,'flags')) then
      abhdatum:=0     { Haltezeit in #Nachrichten }
    else begin
      dbReadN(bbase,bb_haltezeit,halten);
      gethdat(halten);
      end;
    dbReadN(bbase,bb_gruppe,brettgruppe);
    if alle then set_allmode:=true;
    U_read:=false;
    SetBrettGelesen(_brett);
  end;

  procedure mw2;
  var
    btyp : string[brettlen];
  begin
    if U_read then begin                   { Brett-Ungelesen-Flag ÅberprÅfen }
      dbSeek(mbase,miGelesen,_brett+#0);
      if not dbEOF(mbase) then begin
        flags:=iif(dbReadInt(mbase,'gelesen')=1,0,2) +
               (dbReadInt(bbase,'flags') and not 2);
        if flags<>dbReadInt(bbase,'flags') then begin
          dbWriteN(bbase,bb_flags,flags);
          weiter:=brettall or dispext or (p=1);
        end;
      end;
    end;            { BrettModus "Alle" oder Brett passt nicht mehr }
    if brettweiter and ((readmode=0) or (not brettall and wrongline)) then begin
      btyp:='';     { dann Cursor nicht weiterschalten }
      p2:=p;
      repeat        { keine Trennzeile anspringen }
        inc(p);
        GoP;
        if not dbBOF(bbase) then dbReadN(bbase,bb_brettname,btyp);
      until dbBOF(bbase) or (left(btyp,3)<>'$/T');
      if (readmode>0) then dec(p);
      if dbBOF(bbase) then begin
        p:=p2;
        GoP;
      end;
      if p>=gl then begin
        disprec[1]:=dbrecno(bbase);
        p:=1;
        aufbau:=true;
      end;
    end
    else
    if not kb_ctrl and weiter and Forth then begin
      p2:=p;
      if not dispext and (readmode>0) and not alle and brettweiter then
      begin
        if readmode=1 then
          repeat
            inc(p2);
            dbRead(dispdat,'flags',flags);
          until (flags and 2<>0) or not Forth
        else
          repeat
            inc(p2);
            dbRead(dispdat,'LDatum',dat);
          until not smdl(dat,readdate) or not Forth;
      end
      else
        inc(p2);
      if not brettall and (readmode=1) and setbrettgelesen(_dispspec) then dec(p2);
      if not dbEOF(dispdat) then
        if p2<=gl then p:=p2
        else begin
          disprec[1]:=dbRecno(dispdat);
          p:=1;
        end
        else begin
          t:=keyend;
          lastt:='';
        end;
      aufbau:=true;
    end;
  end;

begin
  mdr:=disprec;
  GoP;
  mw1;
  selcall(10,gl-1);
  abhdatum:=mhd;
  if quit then exit;
  disprec:=mdr;
  if dbDeleted(dispdat,disprec[p]) then   { nach Brettreorg }
    aufbau:=true
  else begin
    GoP;
    weiter:=true;
    mw2;
  end;
end;

procedure _msg_window;
begin
  GoP;
  msg_window(dispext or ((ArchivBretter<>'') and
    (ustr(copy(dbReadStr(bbase,'brettname'),2,length(ArchivBretter)))=ArchivBretter)));
end;

procedure _verknuepfen(bretter:boolean);
begin
  GoP;
  if bretter then
    Bverknuepfen
  else
    Uverknuepfen;
  setall;
end;

procedure loeschbrett;
var brett          : string[BrettLen];
    _brett,_brett2 : string[5];
begin
  GoP;
  dbRead(bbase,'Brettname',brett);
  _brett:=mbrettd(brett[1],bbase);
  dbSeek(mbase,miBrett,_brett);
  if not dbEOF(mbase) then
    dbRead(mbase,'Brett',_brett2);
  if not dbEOF(mbase) and (_brett=_brett2) then
    rfehler(419)    { 'Brett ist nicht leer' }
  else begin
    dbDelete(bbase);
    if p=1 then DispRec[1]:=0;
    aufbau:=true; xaufbau:=true;
    end;
end;

procedure neues_brett;
begin
  if newbrett then   { xp4e }
    gochange;
end;

procedure brett_aendern;
begin
  GoP;
  if modibrett then
    RedispLine;
end;

procedure brett_aendern2;
begin
  GoP;
  if modibrett2 then
    RedispLine;
end;

procedure multiedit(user:boolean);
begin
  GoP;
  _multiedit(user);
end;

procedure multiloesch(user:boolean);
begin
  _multiloesch(user);
  if dbDeleted(dispdat,disprec[1]) then
    disprec[1]:=0;
end;

procedure add_haltezeit(ofs:shortint);
var halten : integer16;
begin
  CondClearKeybuf;
  GoP;
  dbRead(dispdat,'haltezeit',halten);
  halten:=max(0,min(halten+ofs,9999));
  dbWrite(dispdat,'haltezeit',halten);
  RedispLine;
end;

procedure bezuege;
var i,j : longint;
    pp  : shortint;
    brk : boolean;
label found;
begin
  if markaktiv then begin
    errsound; exit;
    end;
  GoP;
  write_disp_line(p,0,true);
  bezuege_suchen(brk);
  if markanz=0 then begin
    if not brk then errsound;
    end
  else begin
    pp:=0;
    i:=0;
    while i<markanz do begin
      for j:=1 to gl do
        if disprec[j]=marked^[i].recno then begin
          pp:=j; goto found;
          end;
      inc(i);
      end;
  found:
    if pp>0 then p:=pp
    else begin
      if rdmode>0 then all_mode;
      disprec[1]:=marked^[0].recno; p:=1;
      end;
    end;
  aufbau:=true;
end;

procedure switch_weiterschalt;
begin
  NachWeiter:=not NachWeiter;
  attrtxt(col.colmenu[0]);
  mwrt(69,1,iifc(NachWeiter,' ','W'));
end;

procedure seek_brett(fwd:boolean);
var i   : integer;
    rec : longint;
begin
  GoP;
  write_disp_line(p,0,true);
  do_bseek(fwd);
  if not (dbEOF(bbase) or dbBOF(bbase)) then begin
    rec:=dbRecno(bbase);
    i:=1;
    while (i<=gl) and (rec<>disprec[i]) do inc(i);
    if i<=gl then
      p:=i
    else begin
      dbSkip(bbase,-1);
      p:=2;
      if dbBOF(bbase) then begin
        dbGoTop(bbase);
        p:=1;
        end;
      disprec[1]:=dbRecno(bbase);
      aufbau:=true;
      end;
    end;
end;

procedure disprecno;
begin
  message(getres(429)+strs(dbRecno(dispdat)));   { 'Satznummer: ' }
  wait(curoff);
  closebox;
end;

{
  $Log: xp4w.inc,v $
  Revision 1.40  2001/07/19 14:14:29  MH
  - Ungelesen-Fixes wieder mi·lungen - Neuaufbau bei
    neuen KopienempfÑngern notwendig!

  Revision 1.38  2001/07/12 10:47:08  MH
  - Weiteres Problem beim Weiterschalten aus Nachrichten im UngelesenMode
    beseitigt - besonders dann, wenn man auf diese antwortet

  Revision 1.37  2001/07/11 09:36:23  MH
  - UKAD-Parameter korrigiert (news)

  Revision 1.36  2001/07/04 22:05:46  MH
  - Fixversuch-Nachrichtenweiterschaltung: Beim scrollen in jedem LeseMode
    sprang der CursorBalken auf die erste Position, aber auf die falsche
    Nachricht (!Back! in GoDown() auskommentiert)

  Revision 1.35  2001/07/04 14:05:20  MH
  - ÅberflÅssiges entfernt (xtended.15 / extended)

  Revision 1.34  2001/07/03 23:26:45  MH
  - ÅberflÅssiges entfernt (xtended.15 / extended)

  Revision 1.33  2001/07/02 11:45:42  MH
  - Im Brettmodus 'Alle' und Brettweiter Trennzeilen Åberspringen
    (Jochen hat Brettweiter vergessen)

  Revision 1.32  2001/07/02 11:06:05  MH
  - Im Brettmodus 'Alle' und Brettweiter Trennzeilen Åberspringen
  - Bei Userweiter auch Verteiler berÅcksichtigen

  Revision 1.31  2001/06/30 23:23:46  MH
  - ListerBrettAnzeige: Praevention bei Datenbankzugriff

  Revision 1.29  2001/06/28 17:16:45  MH
  -.-

  Revision 1.28  2001/06/28 15:42:26  MH
  - ListerBrettAnzeige nochmal korrigiert

  Revision 1.27  2001/06/27 01:54:54  MH
  - Brettanzeige jetzt NachrichtenabhÑngig
    (/FIDO/-Brettebene wird entfernt)

  Revision 1.26  2001/06/26 23:17:18  MH
  - Brettanzeige (auch im Lister) auch RFC-Konform anzeigen

  Revision 1.25  2001/06/20 21:49:49  MH
  - Fixversuch: Absturz bei Betreffsuche in allen Brettern

  Revision 1.24  2001/06/18 20:17:32  oh
  Teames -> Teams

  Revision 1.23  2001/01/06 11:41:11  MH
  Fix bei PageDown:
  - Nach KK die richtige Nachricht wieder laden
  - PageDown klemmte nach 20 Nachrichten
  - PageUp klemmte nach KK
  - PageDown klemmt noch nach KK !!

  Revision 1.22  2001/01/06 00:40:15  MH
  Fix bei PageDown:
  - Absturz, wenn im DispMode=10 Nachrichten geqoutet werden und
    anschlie·end Åber PageDown am Ende angelangt (DispRec=0)

  Revision 1.21  2000/12/30 02:56:52  MH
  Fix (Versuch 3):
  - ungelesenmode erst mal ausklammern (Nebenefekte)

  Revision 1.20  2000/12/30 02:12:32  MH
  Fix (weiterer Versuch):
  - doppelte bzw. falsche Nachrichtenanzeige nach verlassen
    von einer Nachricht, bei der +/- Tasten verwendet wurden

  Revision 1.19  2000/12/28 11:42:53  MH
  Fixversuch:
  - Probleme bei ^PgDown und ShowHeader innerhalb einer Nachricht

  Revision 1.18  2000/11/18 22:55:16  MH
  Ungelesen Mode Fix:
  - Sprang immer an die zweite Stelle der NachrichtenÅbersicht, wenn
    die letzte in der öbersicht verlassen wurde und noch weitere folgen

  Revision 1.17  2000/11/12 12:24:13  MH
  Userswitch Åberarbeitet

  Revision 1.16  2000/11/10 19:52:06  rb
  Schînheitsfixes am Kommentarbaum

  Revision 1.15  2000/11/09 18:47:54  MH
  Fix-2: DBEOF - > Userswitch nach Vertreteradresse

  Revision 1.14  2000/11/09 17:14:45  MH
  Fix: DBEOF - > Userswitch nach Vertreteradresse

  Revision 1.13  2000/11/04 23:36:05  MH
  Weiteres BrettGelesen Problem beseitigt
  - Wiedervorlage

  Revision 1.12  2000/10/01 09:38:08  MH
  HDO-Requester starten wenn: 'L' oder 'K' auf einer TopOfMail verwendet wird

  Revision 1.11  2000/09/03 18:45:28  MH
  UngelesenBugfix:
  Bei Brettanzeige 'Alle' und Nachrichten Ungelesen-Mode
  wurde bei verlassen des Brettes, in dem auch keine un-
  gelesenen Nachrichten mehr enthalten waren, der Cursor-
  balken immer um ein Brett zu frÅh gesetzt.

  Revision 1.10  2000/08/13 00:05:15  MH
  Weiterschaltung im UngelesenMode korrigiert

  Revision 1.9  2000/08/10 17:31:36  MH
  JG: SetBrettGelesen-Routine fÅr Ungelesen-Bug

  Revision 1.8  2000/07/12 15:54:42  MH
  Sourceheader ausgetauscht

  Revision 1.7  2000/07/01 15:16:04  MH
  - RTE 201 beseitigt

  Revision 1.6  2000/06/22 03:47:08  rb
  Haltezeit-Bug bei ver32 gefixt

  Revision 1.5  2000/05/25 23:19:51  rb
  Loginfos hinzugefÅgt

}
