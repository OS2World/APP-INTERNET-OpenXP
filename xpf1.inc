{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xpf1.inc,v 1.5 2000/06/22 03:47:10 rb Exp $ }

{ XPFIDO - Nodeliste auslesen/abfragen }


procedure ReadNData(nfile:byte; adr:longint; var ni:NodeInfo);
var s  : ^string;
    rr : word;

  procedure SetInfo;
  var p : byte;
      x : string[10];
    function getstr:string;
    var b: byte;
    begin
      p:=cpos(',',s^);
      if p=0 then getstr:=''
      else begin

      for b:=1 to p-1 do
        if s^[b]='_' then s^[b]:=' ';

        getstr:=copy(s^,1,p-1);
        delete(s^,1,p);
        end;
    end;
  begin
    with ni do begin
      if s^[length(s^)]<>',' then s^:=s^+',';
     { for p:=1 to length(s^) do       nach GetStr verschoben, damit im
        if s^[p]='_' then s^[p]:=' ';  String FFlags '_' erhalten bleibt }
      status:=getstr;
      p:=cpos(',',s^);
      if p>0 then begin
        if status='' then
          status:=iifs(ispoint,'Point','Node');
        delete(s^,1,p);    { Nodenummer }
        boxname:=getstr;
        standort:=getstr;
        sysop:=getstr;
        telefon:=getstr;
        baud:=minmax(ival(getstr),110,65535);
        fflags:=s^;
        dellast(fflags);    { Komma entfernen }
        repeat
          x:=getstr;
          if x='V32B' then flags:=flags or nfV32b else
          if x='V32' then flags:=flags or nfV32 else
          if (x='HST') or (x='H14') then flags:=flags or nfHST else
          if x='PEP' then flags:=flags or nfPEP else
          if x='ZYX' then flags:=flags or nfZYXEL else
          if x='H16' then flags:=flags or nfHST16 else
          if pos('ISDN',x)>0 then flags:=flags or nfISDN else
          { MK 01/00 Zeile eingef�gt, erkennt jetzt ISDN-Boxen richtig }
          if (x='X75') then flags:=flags or nfISDN else
          if (x='VFC') then flags:=flags or nfVFC else
          if (x='V32T') then flags:=flags or nfTerbo else
          if (x='V34') then flags:=flags or nfV34 else
          if x='CM' then flags:=flags or nfCM else
          if x='XA' then request:=rfWaZOO+rfUpWaz+rfBark+rfUpBark else
          if x='XB' then request:=rfBark+rfUpBark+rfWaZOO else
          if x='XC' then request:=rfBark+rfWaZOO+rfUpWaz else
          if x='XP' then request:=rfBark+rfUpBark else
          if x='XR' then request:=rfBark+rfWaZOO else
          if x='XW' then request:=rfWaZOO else
          if x='XX' then request:=rfWaZOO+rfUpWaz else
          if x='MN' then flags:=flags and (not nfComp);
        until x='';
        end;
      end;
  end;

begin
  ni.found:=false;
  if (nfile<1) or (nfile>NL_anz) then exit;
  new(s);
  new(nodelf);
  assign(nodelf^,FidoDir+NLfilename(nfile));
  resetfm(nodelf^,fmRead);
  if ioresult=0 then begin
    { reset(nodelf^,1);  !?!? }
    seek(nodelf^,adr);
    blockread(nodelf^,s^[1],255,rr);
    s^[0]:=chr(rr);
    s^[0]:=chr(cpos(#13,s^)-1);
    SetInfo;
    ni.found:=true;
    close(nodelf^);
    end;
  dispose(nodelf);
  dispose(s);
end;


{ Pointtyp: 0=nur Node, 1=Point/Node, 2=bei nicht gef. Point wiederholen }

procedure GetNodeinfo(adr:string; var ni:nodeinfo; pointtyp:shortint);
var fa     : fidoadr;
    i,netp : integer;
    bp     : ^netrecl;
    banz   : word;
    nanz   : word;
    nadr,l : longint;
    nfile  : byte;
    np     : ^nodea;
    found  : boolean;
    _adr   : longint;
    points : integer16;
    pp     : ^pointa;

label again;

begin
  fillchar(ni,sizeof(ni),0);
  if not nodeopen then exit;
  splitfido(adr,fa,2);
  if pointtyp=0 then fa.ispoint:=false;
  if not nodelistopen then begin
    reset(nodef,1);
    if ioresult<>0 then exit;
    end;
again:
  i:=bereiche;
  while (i>0) and ((berliste^[i].fromzone>fa.zone) or
                   ((berliste^[i].fromzone=fa.zone) and
                    (berliste^[i].fromnet>fa.net))) do
    dec(i);
  fillchar(ni,sizeof(ni),0);
  if i>0 then begin
    new(bp);
    seek(nodef,NX_adrnetx+berliste^[i].adr);
    banz:=berliste^[i].anz;
    if banz>bersize then
      writeln(getres(2121),#7);   { 'Fehler in Nodelisten-Index!' }
    blockread(nodef,bp^,banz*sizeof(netrec));
    l:=$10000*fa.zone+fa.net;
    {$R-}
    netp:=1;
    while (netp<=banz) and (bp^[netp].sortl<l) do
      inc(netp);
    repeat
      found:=(netp<=banz) and (bp^[netp].sortl=l);
      if found then begin
        nanz:=bp^[netp].anz;
        nadr:=bp^[netp].adr;
        nfile:=bp^[netp].fnr;
        ni.datei:=nfile;
        end;
      if found and (fa.ispoint=odd(bp^[netp].flags)) then begin
        getmem(np,nanz*sizeof(noderec));
        seek(nodef,nadr);
        blockread(nodef,np^,nanz*sizeof(noderec));
        i:=0;
        while (i<nanz) and (np^[i].node<fa.node) do
          inc(i);
{$IFDEF Debug }
  {$R+}
{$ENDIF }
        if (i<nanz) and (np^[i].node=fa.node) then
          _adr:=np^[i].adr
        else
          _adr:=-1;
        freemem(np,nanz*sizeof(noderec));
        if (_adr>=0) and fa.ispoint then begin
          seek(nodef,_adr);
          blockread(nodef,points,2);
          getmem(pp,points*sizeof(pointrec));
          blockread(nodef,pp^,points*sizeof(pointrec));
          i:=0;
          while (i<points) and (pp^[i].point<fa.point) do
            inc(i);
          if (i<points) and (pp^[i].point=fa.point) then
            _adr:=pp^[i].adr
          else
            _adr:=-1;
          freemem(pp,points*sizeof(pointrec));
          end;
        if _adr>=0 then begin
          ni.ispoint:=fa.ispoint;
          ReadNData(nfile,_adr,ni);
          end;
        end;
      inc(netp);
    until not found or ni.found;
    dispose(bp);
    end;
  if (pointtyp=2) and not ni.found and fa.ispoint then begin
    fa.ispoint:=false;
    goto again;
    end;
  ni.ispoint:=fa.ispoint;
  if not nodelistopen then
    close(nodef);
end;


function IsFidoNode(adr:string):boolean;
var ni : NodeInfo;
begin
  GetNodeInfo(adr,ni,1);
  IsFidoNode:=ni.found;
end;


procedure GetNodeuserInfo(var fa:FidoAdr; var ni:NodeInfo);
type ubufa  = array[0..blocksize-1] of byte;
var  f     : file;
     name  : string[MaxNamelen];
     vname : string[MaxNamelen];
     p,x,y : byte;
     buf   : ^ubufa;
     bufp  : word;
     l,r,m : longint;
     user  : UserRec;
     last  : boolean;
     anz   : longint;
     s     : string[80];
     brk   : boolean;
     height: word;

label ende;

  function getbyte:byte;
  begin
    getbyte:=buf^[bufp];
    inc(bufp);
  end;

  procedure GetNextUser;
  var flags,b : byte;
      not0    : boolean;        { User nicht aus Nodeliste 0 }
      adr3    : boolean;        { 3-Byte-Dateioffset }
  begin
    with user do begin
      name[0]:=chr(getbyte);    { n Zeichen �bernehmen }
      flags:=getbyte;
      b:=getbyte;
      not0:=(b and $40)=0;
      adr3:=(b and $80)<>0;
      b:=b and $3f;
      if b>0 then begin            { restlichen Namen kopieren }
        if b+length(name)>MaxNameLen then begin
          rfehler(2120);   { 'Fehler im Nodelisten-Userindex' }
          b:=MaxNameLen-length(name);
          end;
        FastMove(buf^[bufp],name[length(name)+1],b);
        inc(byte(name[0]),b);
        inc(bufp,b);
        end;
      adr[0]:=flags shr 4;         { Adresse ermitteln }
      if adr[0]=0 then begin
        adr[0]:=getbyte;        { getrennte Auswertung, wegen umgekehrter }
        inc(adr[0],256*getbyte);    { Auswertung durch Compiler! }
        end;
      adr[1]:=getbyte;
      if not odd(flags) then inc(adr[1],256*getbyte);
      adr[2]:=getbyte;
      if flags and 2=0 then inc(adr[2],256*getbyte);
      if flags and 4<>0 then
        adr[3]:=0
      else begin
        adr[3]:=getbyte;
        if flags and 8=0 then inc(adr[3],256*getbyte);
        end;
      if not0 then fnr:=getbyte    { Datei-Nummer }
      else fnr:=0;
      b:=iif(adr3,3,4);            { Datei-Offset }
      fadr:=0;
      FastMove(buf^[bufp],fadr,b);
      inc(bufp,b);
      last:=buf^[bufp]=$ff;
      end;
  end;

  procedure GetFirstUser;
  begin
    bufp:=0;
    user.name:='';
    GetNextUser;
  end;

  procedure ReadBlock(nr:longint);
  begin
    seek(f,nr*BlockSize);
    blockread(f,buf^,BlockSize);
    GetFirstUser;
    vname:=left(user.name,length(name));
  end;

begin
  fillchar(ni,sizeof(ni),0);
  if UserBlocks=0 then exit;    { keien Nodelisten -> leerer Index }
  with fa do begin
    p:=cpos(',',username);         { Name formatieren }
    if p>0 then
      name:=left(username,p-1)+' '+trim(mid(username,p+1))
    else begin
      p:=length(username);
      while (p>1) and (username[p]<>' ') do dec(p);
      if p>1 then name:=mid(username,p+1)+' '+left(username,p-1)
      else name:=username;
      end;
    end;
  name:=trim(name);
  if name='' then exit;
  UpString(name);
  assign(f,UserIndexF);
  reset(f,1);
  new(buf);
  l:=1; r:=UserBlocks;
  repeat
    m:=(l+r)div 2;
    ReadBlock(m);
    if vname<name then l:=m
    else r:=m;
  until (r-l<2) or (vname=name);
  if (name<>vname) and (l<m) then ReadBlock(l)
  else l:=m;
  if name<vname then goto ende;
  while (name=vname) and (l>1) do begin
    dec(l);
    ReadBlock(l);
    end;
  repeat
    while not last and (user.name<name) do
      GetNextUser;
    if (user.name<name) and (l<userblocks) then begin
      inc(l);
      ReadBlock(l);
      end;
  until last or (left(user.name,length(name))>=name);
  if (left(user.name,length(name))=name) then begin
    openlist(2,78,10,11,0,'/NS/SB/NLR/DM/APGD/');
    anz:=0;
    repeat
      with user do begin
        ReadNdata(fnr,fadr,ni);
       app_l(' '+forms(TopAllStr(user.name),22)+'  '+
              forms(strs(adr[0])+':'+strs(adr[1])+'/'+strs(adr[2])+
              iifs(adr[3]=0,'','.'+strs(adr[3])),15)+' '+
              forms(iifs(adr[3]=0,ni.boxname+', '+ni.standort,ni.standort),32));
        inc(anz);
        if not last then
          GetNextUser
        else begin
          inc(l);
          if l<=userblocks then
            ReadBlock(l);
          end;
        end;
    until (left(user.name,length(name))<>name) or (l>userblocks);
    if anz>0 then begin
      if anz=1 then
        s:=first_line
      else begin
        selbox(76,min(anz+2,screenlines-6),'',x,y,true);
        height:=min(anz+2,screenlines-6)-2;
        SetListsize(x+1,x+74,y+1,y+height);
        listarrows(x,y+1,y+height,col.colselbox,col.colselbox,'�');
        listboxcol;
        pushhp(80);
        list(brk);
        pophp;
        closebox;
        if brk then s:=''
        else s:=get_selection;
        end;
      if s<>'' then begin
        SplitFido(trim(copy(s,26,15)),fa,DefaultZone);
        GetNodeinfo(trim(copy(s,26,15)),ni,1);
        end
      else
        ni.found:=false;
      end;
    closelist;
  end;

ende:
  close(f);
  dispose(buf);
end;


procedure NodelistSeek;
const active : boolean = false;
var x,y,b: byte;
    brk  : boolean;
    ni   : ^NodeInfo;
    adr  : string[30];
    fa   : fidoadr;
    first: boolean;
begin
  if active or not TestNodelist or DisableAltN then exit;
  new(ni);
  active:=true;
{ MH: AltN-Screen zur besseren Lesbarkeit verbreitert }
  diabox(77,11,getres2(2100,1),x,y);    { Node-Infos abfragen }
  if MainNodelist>0 then begin
    attrtxt(col.coldiarahmen);
    mwrt(x+70,y,' '+formi(nodelist^[MainNodelist].number,3)+' ');
    attrtxt(col.coldialog);
    end; { MH: Aufbau ge�ndert, damit m�glichst viel angezeigt werden kann }
  mwrt(x+3, y+2, GetRes2( 2100, 2));     { Box   }          { MH 03.02.2000 }
  mwrt(x+3, y+3, GetRes2( 2100, 4));     { Sysop }
  mwrt(x+3, y+4, GetRes2( 2100, 5));     { TelNr }
  mwrt(x+3, y+5, GetRes2( 2100, 6));     { Flags }
  mwrt(x+3, y+7, GetRes2( 2100, 3));     { ~���į [                    ] }
  mwrt(x+35, y+7, GetRes2( 2100, 10));   { eMAiL }
  mwrt(x+35, y+8, GetRes2( 2100, 9));    { Status }
  mwrt(x+55, y+8, GetRes2( 2100, 8));    { Datei }
  adr:='';
  first:=true;
  TempOpen;
  repeat
    if first and (aktdispmode in [10..19]) then begin
      dbGo(mbase,AktDisprec);
      if not dbEOF(mbase) and not dbBOF(mbase) and (mbNetztyp=nt_Fido) then begin
        splitfido(dbReadStr(mbase,'absender'),fa,DefaultZone);
        adr:=MakeFidoAdr(fa,false);
        brk:=false;
        end;
      end;
    if not first or (adr='') then begin
      pushhp(750);
      ReadString(x+3, y+8, Forms(GetRes2( 2100, 7), 6), adr, 20, 20, '', brk);
      pophp;                   { AKA�į }
      end;
    first:=false;
    if not brk then begin
      if not isNodeAddress(adr) then begin
        fa.username:=adr;
        getNodeUserInfo(fa,ni^);
        end
      else begin
        splitfido(adr,fa,DefaultZone);
        adr:=MakeFidoAdr(fa,true);
        GetNodeinfo(adr,ni^,1);
        end;
      attrtxt(col.coldialog);
      moff;
    { MH: Fenster putzen }
    clwin(x+10, x+75, y+2, y+5); { Oberer Block }
     clwin(x+43, x+51, y+8, y+8); { Status      }
      clwin(x+62, x+73, y+8, y+8); { Datei      }
       clwin(x+11, x+30, y+7, y+7); { AKA [ ]   }
        clwin(x+43, x+75, y+7, y+7); { eMAiL    }
      if ni^.found then with ni^ do begin
        attrtxt(col.coldiahigh);    { MH: 42 -> 65 }
        wrt(x+10, y+2, left(BoxName + ', ' + Standort,65));
        wrt(x+10, y+3, Sysop);
        wrt(x+10, y+4, Telefon);
        wrt(x+10, y+5, copy(MailString(FFlags, True),1,65)); { eMail l�schen }
        wrt(x+11, y+7, MakeFidoAdr(fa, True));
        b := cpos('@', FFlags);
        if b = 0 then FFlags := '';
        wrt(x+43, y+7, MailString(FFlags, False)); { eMail extrahieren }
        wrt(x+43, y+8, Status);
        wrt(x+62, y+8, NLfilename(datei));
        end;
      mon;
      end;
  until brk;
  freeres;
  closebox;
  dispose(ni);
  active:=false;
end;


{ --- Nodelist-Browser ---------------------------------------------- }

var  rdispx,rdispy : byte;

procedure ShowRQ(s:string); { MH: Liste angepasst }
var ni  : NodeInfo;
    add : byte;
begin
  GetNodeinfo(copy(s,39,17),ni,1);
  add:=max(length(getres2(2131,30)),length(getres2(2131,32)));
  attrtxt(col.colselbox);
  if ni.ispoint then begin
    mwrt(rdispx,rdispy,getres2(2131,33));    { 'Sysop' }
    mwrt(rdispx+54-length(getres2(2131,34)),rdispy-1,getres2(2131,34));
    end                                      { 'Pointliste' }
  else begin
    mwrt(rdispx,rdispy,getres2(2131,30));    { 'Sysop' }
    mwrt(rdispx+54-length(getres2(2131,31)),rdispy-1,getres2(2131,31));
    end;                                     { 'Nodeliste' }
  mwrt(rdispx,rdispy+1,getres2(2131,32));    { 'Flags' }
  mwrt(rdispx,rdispy-1,getres2(2131,35));    { 'Status' }
  attrtxt(col.colselhigh);
  if ni.found then begin
    mwrt(rdispx+add+2,rdispy,forms(iifs(ni.ispoint,ni.boxname,ni.sysop),33));
    mwrt(rdispx+55,rdispy-1,forms(NLfilename(ni.datei),12));
    mwrt(rdispx+add+2,rdispy+1,forms(ni.fflags,65)); { MH: 40 -> 65 }
    mwrt(rdispx+7,rdispy-1,forms(ni.status,12));
    end
  else begin
    mwrt(rdispx+add+2,rdispy,sp(33));
    mwrt(rdispx+55,rdispy-1,sp(12));
    mwrt(rdispx+add+2,rdispy+1,sp(65)); { MH: 40 -> 65 }
    mwrt(rdispx+7,rdispy-1,sp(12));
    end;
end;


procedure NodelistBrowser;

const orflags  = 10;
      andflags = 5;

type NodeBrec = record
                  nodeadr : string[20];
                  sysop   : string[30];
                  boxname : string[30];
                  standort: string[30];
                  telefon : string[20];
                  flags   : string[80]; { MH: 40 -> 80 }
                  fnl,snl,
                  pl      : boolean;
                end;
     NodeBRP  = ^NodeBrec;

const NB_data : NodeBRP = nil;
      bufsize = 2048;

var   x,y,h   : byte;
      brk     : boolean;
      flag    : array[1..orflags,1..andflags] of string[12];
      flaganz : array[1..orflags] of byte;
      flags   : byte;     { Anzahl or-Flags }
      i       : integer;
      t       : text;
      s,ss    : string;
      buf     : pointer;
      found,n : longint;
      k       : string[10];
      p       : byte;
      nn      : word;
      azone,                   { aktuelle Nodeadresse beim Suchen }
      anet,
      anode,
      apoint  : word;
      lastnet : word;
      sphone  : string[30];    { in Nodelistenformat konvertierte Tel.Nr. }
      skip    : boolean;
      ni      : nodeinfo;
      adr     : string[adrlen];
      d       : DB;

label again, NewStart;

  procedure ParseFlags;
  var s,s2 : string[80]; { MH: 40 -> 65 }
      p    : byte;
  begin
    flags:=0;
    s:=nb_data^.flags;
    while (s<>'') and (flags<orflags) do begin
      inc(flags);
      flaganz[flags]:=0;
      p:=blankposx(s);
      s2:=left(s,p-1);
      while s2<>'' do begin
        if flaganz[flags]<andflags then begin
          inc(flaganz[flags]);
          flag[flags,flaganz[flags]]:=','+left(s2,cposx(',',s2)-1)+',';
          end;
        delete(s2,1,cposx(',',s2));
        end;
      s:=trim(mid(s,p+1));
      end;
  end;

  procedure GetAddress(format:shortint; var skip:boolean);
  var p  : byte;
      fa : FidoAdr;
  begin
    skip:=false;
    case format of
      nlNodelist,
      nl4Dpointlist: if k='ZONE' then begin
                       azone:=nn; anet:=nn; anode:=nn;
                       skip:=(format=nl4Dpointlist);
                       end
                     else if (k='HOST') or (k='REGION') then begin
                       anet:=nn; anode:=0;
                       skip:=(format=nl4Dpointlist);
                       end
                     else if k='POINT' then
                       apoint:=nn
                     else begin
                       anode:=nn;
                       skip:=(format=nl4Dpointlist);
                       end;

      nlPoints24   : if k='HOST' then begin
                       ss:=left(ss,cposx(',',ss)-1);  { Nodeadresse isolieren }
                       p:=cpos('/',ss);
                       if p>0 then begin
                         anet:=ival(left(ss,p-1));
                         anode:=ival(mid(ss,p+1));
                         end;
                       skip:=true;
                       end
                     else if (k='') or (k='PVT') then
                       apoint:=nn;

      nlFDpointlist: if k='BOSS' then begin
                       ss:=left(ss,cposx(',',ss)-1);
                       splitfido(ss,fa,azone);
                       azone:=fa.zone; anet:=fa.net; anode:=fa.node;
                       skip:=true;
                       end
                     else if (k='') or (k='PVT') then
                       apoint:=nn;

      nlNode      : if (k='') or (k='PVT') then apoint:=nn;

    end;  { case }
  end;

  function ntest(ts:string):boolean;
  var p : byte;
  begin
    UpString(ts);
    p:=cposx(',',ss);
    ntest:=(ts='') or (pos(ts,left(ss,p-1))>0);
    delete(ss,1,p);
  end;

  function gets:string;
  var p : byte;
  begin
    p:=cposx(',',s);
    gets:=left(s,p-1);
    delete(s,1,p);
  end;

  function testphone:boolean;
  begin
    testphone:=(left(GetToken(ss,','),length(sphone))=sphone);
  end;

  function node_str:string;
  begin
    if apoint=0 then
      node_str:=strs(azone)+':'+strs(anet)+'/'+strs(anode)
    else
      node_str:=strs(azone)+':'+strs(anet)+'/'+strs(anode)+'.'+strs(apoint);
  end;

  function testaddress(var s:string):boolean;
  begin
    if s='' then
      testaddress:=true
    else
      testaddress:=(pos(s,node_str)>0);
  end;

  function testflags:boolean;
  var i,j   : integer;
      _s    : string;
  begin
    _s:=','+ss+',';
    if flags=0 then
      testflags:=true
    else begin
      i:=0;
      repeat
        inc(i);
        j:=1;
        while (j<=flaganz[i]) and (pos(flag[i,j],_s)>0) do
          inc(j);
      until (i>flags) or (j>flaganz[i]);
      testflags:=(i<=flags) and (j>flaganz[i]);
      end;
  end;

begin
  if not TestNodelist then exit;
  if not assigned(NB_Data) then begin
    new(NB_data);
    fillchar(NB_data^,sizeof(NB_Data^),0);
    NB_data^.fnl:=true; NB_data^.snl:=true;
    end;

again:
  dialog(ival(getres2(2131,0)),17,getres2(2131,1),x,y); { 'Nodelisten durchsuchen' }
  with NB_Data^ do begin
    maddstring(3,2,getres2(2131,2),sysop,30,30,'');     { 'Sysop' }
      mhnr(950);
      mnotrim;
    maddstring(3,3,getres2(2131,3),standort,30,30,'');  { 'Standort' }
      mnotrim;
    maddstring(3,4,getres2(2131,4),boxname,30,30,'');   { 'Boxname' }
      mnotrim;
    maddstring(3,6,getres2(2131,5),nodeadr,20,20,'0123456789:/.'); { 'Nodeadresse' }
    maddstring(3,7,getres2(2131,6),telefon,20,20,'0123456789-');   { 'Telefon' }
    maddstring(3,9,getres2(2131,8),flags,30,65,'>');  {MH: 40>65}  { 'Flags' }
    maddbool (3,11,getres2(2131,9),fnl);   { 'FidoNet-Nodeliste durchsuchen' }
    maddbool (3,12,getres2(2131,10),snl);  { 'sonstige Nodelisten durchsuchen' }
      mhnr(956);
    maddbool (3,13,getres2(2131,11),pl);   { 'Pointlisten durchsuchen' }
      mhnr(956);
    readmask(brk);
    closemask;
    end;
  if brk then begin
    closebox;
    freeres;
    exit;
    end;

  sphone:=NB_Data^.telefon;    { Telefon in Nodelistenformat konvertieren }
  if (IntVorwahl<>'') and (left(sphone,length(IntVorwahl))=IntVorwahl) then
    delete(sphone,1,length(IntVorwahl))
  else if (NatVorwahl<>'') and (left(sphone,length(NatVorwahl))=NatVorwahl) then
    sphone:=left(Vorwahl,cpos('-',vorwahl))+mid(sphone,length(NatVorwahl)+1);
  ParseFlags;

  getmem(buf,bufsize);
  attrtxt(col.coldialog);
  mwrt(x+2,y+14,getres2(2131,20));   { 'Datei:' }
  mwrt(x+2,y+15,getres2(2131,21));   { 'Netz:'  }
  mwrt(x+28,y+14,getres2(2131,22));  { 'Eintr�ge:' }
  mwrt(x+28,y+15,getres2(2131,23));  { 'passend:' }
  openlist(2,78,10,11,0,'/NS/SB/NLR/DM/');  { Koordinaten beliebig }
{$IFDEF BP }
  ListInitEMS(2048);   { 2 MB EMS reservieren }
{$ENDIF}
  found:=0; n:=0;
  for i:=1 to NL_anz do
    with Nodelist^[i],NB_Data^ do
      if ((fnl and (listfile='NODELIST.###') and (format=nlNodelist)) or
          (snl and (listfile<>'NODELIST.###') and (format=nlNodelist)) or
          (pl and (format<>nlNodelist))) and
         exist(FidoDir+NLfilename(i))
      then begin
        attrtxt(col.coldiahigh);
        mwrt(x+10,y+14,forms(NLfilename(i),12));
        assign(t,FidoDir+NLfilename(i));
        settextbuf(t,buf^,bufsize);
        reset(t);
        if zone<>0 then azone:=zone   { Start-Nodeadresse setzen }
        else azone:=DefaultZone;
        apoint:=0;
        if format=nlNode then begin
          anet:=net; anode:=node;
          end
        else begin
          anet:=0; anode:=0;
          end;
        lastnet:=65535;
        while not eof(t) and not brk do begin
          readln(t,s);
          if (s<>'') and (s[1]<>';') and (cpos(',',s)>0) then begin
            inc(n);
            ss:=ustr(s);
            while cpos('_',ss)>0 do ss[cpos('_',ss)]:=' ';
            k:=left(ss,cpos(',',ss)-1);
            delete(ss,1,cpos(',',ss));
            if k<>'BOSS' then begin
              p:=cposx(',',ss);
              nn:=minmax(ival(left(ss,p-1)),0,65535);
              delete(ss,1,p);
              end;
            GetAddress(format,skip);     { akt. Adresse ermitteln }
            if anet<>lastnet then
              mwrt(x+10,y+15,forms(strs(azone)+':'+strs(anet),15));
            lastnet:=anet;
            if n mod 100=0 then
              mwrt(x+38,y+14,strsn(n,7));
            if not skip and
               ntest(boxname) and
               ntest(standort) and
               ntest(sysop) and
               testphone and
               testaddress(nodeadr) and
               testflags
            then begin
              inc(found);
              mwrt(x+38,y+15,strsn(found,7));
              gets; gets;  { Nodetyp und -nummer �berlesen }
              while cpos('_',s)>0 do s[cpos('_',s)]:=' ';
              ni.boxname:=gets; ni.standort:=gets;
              ni.sysop:=gets; ni.telefon:=gets;
              with ni do
                app_l(' '+forms(iifs(apoint<>0,sysop,boxname)+', '+standort,35)+
                      '  '+forms(node_str,17)+' '+FormFidoPhone(telefon));
              end;
            end;
          testbrk(brk);
          end;   { not eof }
        close(t);
        end;
  freemem(buf,bufsize);
  closebox;

  if found=0 then
  begin
    closelist;
    if not brk then
    begin
      rfehler(2126);        { 'Es wurden keine passenden Eintr�ge gefunden.' }
      goto again;
    end;
  end;

  if found>0 then begin
    signal;
    h:=min(found+6,screenlines-6);
    selbox(76,h,'',x,y,true);
    dec(h,5);
    rdispx:=x+2; rdispy:=y+h+2;
    attrtxt(col.colselrahmen);
    mwrt(x,rdispy-2,hbar(76));       { MH: rdispy-1 -> rdispy-2 }
    SetListsize(x+1,x+74,y+1,y+h-1); { MH: h -> h-1             }
    listboxcol;                      { MH: Liste angepasst      }
    listarrows(x,y+1,y+h,col.colselrahmen,col.colselrahmen,'�');
    listDp(ShowRQ);
    listTp(listext); listmakros:=0;
    repeat
NewStart:                  { nach Break im AltN-Screen hier einspringen }
      pushhp(958);
      list(brk);
      pophp;
      n:=0;
      if not brk then begin
        GetNodeInfo(copy(get_selection,39,18),ni,2);
        if not ni.found then
          errsound
        else begin
          adr:=ni.sysop + ' @ ' +trim(copy(get_selection,39,18));
          if ni.ispoint then s:=adr
          else s:=ni.boxname + ', ' +adr;
          pushhp(959);
          n:=ReadIt(max(length(s)-4,length(getres(2132)))+11,s,
             getres(2132),    { ' ^Nachricht , ^Request , ^Info , ^Zur�ck ' }
             1,brk);          { ^Info Taste hinzugef�gt                     }
          pophp;
          brk:=false;
          end;
        end;
    until brk or (n=1) or (n=2) or (n=3);

      if n<>3 then begin  { Break aus AltN-Screen hier nicht zulassen }
        closelist;
        closebox;
      end;

    if not brk then
      case n of
        1 : begin
              _keyboard(adr+keycr);
              dbOpen(d,BoxenFile,0);
              if dbRecCount(d)>1 then _keyboard(DefFidoBox+keycr);
              dbClose(d);
              msgdirect;
            end;
        2 : begin
              _keyboard(keycr);
              AutoCrash:=FidoRequest(trim(mid(adr,cpos('@',adr)+1)),'');
            end;

        3 : begin   { AltN-Screen aufrufen und Aka �bergeben }
              _keyboard(trim(copy(get_selection,39,18))+keycr);
                NodeListSeek;          { AltN-Screen starten }
              goto newstart;           { Zur�ck zur Liste    }
            end;

      end;
    end;

  freeres;
end;
{
  $Log: xpf1.inc,v $
  Revision 1.5  2000/06/22 03:47:10  rb
  Haltezeit-Bug bei ver32 gefixt

  Revision 1.4  2000/04/09 18:29:56  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.6  2000/02/21 15:07:55  mk
  MH: * Anzeige der eMail beim Nodelistbrowsen

  Revision 1.5  2000/02/19 11:40:09  mk
  Code aufgeraeumt und z.T. portiert

}