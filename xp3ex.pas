{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xp3ex.pas,v 1.16 2002/02/20 19:56:03 rb Exp $ }

{ Nachricht extrahieren }

{$I XPDEFINE.INC }
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp3ex;

interface

uses  xpglobal, crt,dos,typeform,fileio,inout,database,resource,stack,
  xp0,xp1;

const xTractMsg   = 0;
      xTractHead  = 1;
      xTractPuf   = 2;
      xTractQuote = 3;
      xTractDump  = 4;

      ExtCliptearline : boolean = true;
      ExtChgtearline  : boolean = false;

procedure rps(var s:string; s1,s2:string);
procedure rpsuser(var s:string; name:string; var realname:string);
procedure rpsdate(var s:string);
procedure ExtractSetMpdata(mpdata:pointer);
procedure extract_msg(art:byte; schablone:pathstr; name:pathstr;
                      append:boolean; decode:shortint);


implementation  { ---------------------------------------------------- }

uses xp1o,xp3,xp_des,xpnt,xpfido,xpmime,mimedec;

var  ex_mpdata : pmpdata;


procedure rps(var s:string; s1,s2:string);
var p : byte;
begin
  repeat
    p:=pos(s1,ustr(s));
    if p>0 then
      s:=copy(s,1,p-1)+s2+copy(s,p+length(s1),255);
  until p=0;
end;

procedure rpsuser(var s:string; name:string; var realname:string);
var p,p2 : byte;
    komm : string[40];
    vorn : boolean;
begin
{ if _unescape(name) then; }
  vorn:=false;
  p:=pos('$PSEUDO',ustr(s));
  if p=0 then begin
    vorn:=true;
    p:=pos('$VPSEUDO',ustr(s));
    end;
  if p>0 then begin
    dbSeek(ubase,uiName,ustr(name));
    if not dbFound then komm:=''
    else dbReadN(ubase,ub_kommentar,komm);
    p2:=pos('P:',ustr(komm));
    if p2=0 then begin
      s:=copy(s,1,p-1)+iifs(vorn,'$VORNAME','$TUSER')+copy(s,p+iif(vorn,8,7),255);
    end else
      s:=copy(s,1,p-1)+trim(mid(komm,p2+2))+copy(s,p+iif(vorn,8,7),255);
    end;
  name:=vert_name(name);
  rps(s,'$USER',name);
  rps(s,'$NAME',name);
  if realname<>'' then begin
    p:=blankpos(realname);
    if p=0 then rps(s,'$VORNAME',realname)
      else rps(s,'$VORNAME',left(realname,p-1));
    if p=0 then rps(s,'$FIRSTNAME',realname)
      else rps(s,'$FIRSTNAME',left(realname,p-1));
  end else begin
    p:=blankpos(name);
    if p>0 then rps(s,'$VORNAME',left(name,p-1))
    else if cpos('@',name)=0 then
      rps(s,'$VORNAME',TopAllStr(name))
    else rps(s,'$VORNAME',TopAllStr(left(name,cpos('@',name)-1)));
    if p>0 then rps(s,'$FIRSTNAME',left(name,p-1))
    else if cpos('@',name)=0 then
      rps(s,'$FIRSTNAME',TopAllStr(name))
      else rps(s,'$FIRSTNAME',TopAllStr(left(name,cpos('@',name)-1)));
  end;
  p:=pos('%',name);
  if p=0 then p:=pos('@',name);
  if p>0 then begin
    rps(s,'$MUSER',left(name,p-1));
    rps(s,'$TUSER',TopAllStr(left(name,p-1)));
    if ustr(right(name,4))='.ZER' then
      dec(byte(name[0]),4);
    rps(s,'$BOX',mid(name,p+1));
    end
  else begin
    rps(s,'$MUSER',name);
    rps(s,'$TUSER',TopAllStr(name));
    rps(s,'$BOX','');
    end;
end;

procedure rpsdat(var s:string; txt:string; d:datetimest);
begin
  rps(s,txt,left(d,2)+' '+copy('JanFebMarAprMayJunJulAugSepOctNovDec',
            ival(copy(d,4,2))*3-2,3)+' '+right(d,2));
end;

procedure rpsdate(var s:string);
begin
  rps(s,'$DATUM',left(date,6)+right(date,2));
  rps(s,'$EUDATE',left(date,6)+right(date,2));
  if pos('$DATE',s)>0 then
    rpsdat(s,'$DATE',date);
  if pos('$USDATE',s)>0 then
    rpsdat(s,'$USDATE',date);
  rps(s,'$UHRZEIT',left(time,5));
  rps(s,'$TIME',left(time,5));
  rps(s,'$TAG2',left(zdow(zdate),2));
  rps(s,'$SHORTDAY',left(zdow(zdate),2));
  rps(s,'$TAG',zdow(zdate));
  rps(s,'$DAY',zdow(zdate));
end;


procedure ExtractSetMpdata(mpdata:pointer);
begin
  ex_mpdata:=pmpdata(mpdata);
end;


{ Aktuelle Nachricht in Tempfile extrahieren       }
{ art: 0=ohne Kopf, 1=mit Kopf, 2=Puffer, 3=Quote  }
{      4=Hex-Dump                                  }
{ decode: 0=nicht, -1=Rot13, 1=Betreff analysieren }

procedure extract_msg(art:byte; schablone:pathstr; name:pathstr;
                      append:boolean; decode:shortint);
var size   : longint;
    f,decf : file;
    hdp    : headerp;
    hds    : longint;
    edat   : longint;
    tmp    : pathstr;
    t      : text;
    s      : string;
    hs     : string[25];
    i,hdln : integer;
    p      : byte;
    _brett : string[5];
    extpos : longint;
    wempf  : string;
    ni     : NodeInfo;
    hdlines: longint;
    mstatus: string[80];
    pnt    : empfnodep;
    mailerflag : boolean;
    iso1   : boolean;    { charset: ISO1 }
    lasttrenn : boolean;
    mpdata : multi_part;
    multipart : boolean;
    sizepos : longint;
    mpsize  : longint;
    mehdl, mehds : integer;

  procedure wrs(s:string);
  begin
    s:=left(s,iif((_maus and listscroller) and not listfixedhead,zpz-2,zpz))+#13#10;
    blockwrite(f,s[1],length(s));
    inc(hdlines);
    if left(s,5)<>'-----' then lasttrenn:=false;
  end;

  procedure wrslong(s:string);
  begin
    s:=s+#13#10;
    blockwrite(f,s[1],length(s));
    inc(hdlines);
    if left(s,5)<>'-----' then lasttrenn:=false;
  end;

  { dtyp: -1=Rot13, 1=QPC, 2=DES }

  procedure do_decode(dtyp:shortint; ofs:longint);
  var p     : pointer;
      ps: word;
      rr: word;
      fp    : longint;
      pw    : string;
      coder : byte;
      siz0  : smallword;
      passpos : smallword;
      show  : boolean;
      x,y   : byte;
      _off  : longint;
      total : longint;
  begin
    if size>0 then begin
      if (dtyp>=1) then begin
        if left(_brett,1)<>'U' then
          dbSeek(ubase,uiName,ustr(hdp^.absender))
        else
          dbSeek(ubase,uiName,ustr(hdp^.empfaenger));   { Nachricht in PM-Brett }
        if not dbFound or (dbXsize(ubase,'passwort')=0) then begin
          rfehler(308);   { 'Nachricht ist codiert, aber Pa�wort fehlt!' }
          exit;
          end;
        dbRead(ubase,'codierer',coder);
        if coder<>dtyp then begin
          if dtyp=1 then
            rfehler(309)  { 'Nachricht ist QPC-codiert, aber es ist ein DES-Pa�wort eingetragen!' }
          else
            rfehler(310);  { 'Nachricht ist DES-codiert, aber es ist ein QPC-Pa�wort eingetragen!' }
          exit;
          end;
        siz0:=0;
        dbReadX(ubase,'passwort',siz0,pw);
        end;

      ps:=(min(memavail-10000,20000) shr 3) shl 3;  { abrunden wg. DES }
      getmem(p,ps);
      seek(decf,ofs);
      passpos:=1;
      total:=filesize(decf)-ofs;
      show:=(dtyp=2) and (total>=2000);
      x:=0;
      if dtyp=2 then begin
        DES_PW(pw);
        if show then begin
          rmessage(360);   { 'DES-Decodierung...     %' }
          x:=wherex-5; y:=wherey;
          end;
        end;
      _off:=0;
      repeat
        fp:=filepos(decf);
        blockread(decf,p^,ps,rr);
        case dtyp of
         -1 : Rot13(p^,rr);
          1 : QPC(true,p^,rr,@pw,passpos);
          2 : DES_code(true,p^,_off,total,rr,x,y);
        end;
        if (dtyp<>0) and (hdp^.charset='iso1') then
          Iso1ToIBM(p^,rr);
        seek(decf,fp);
        blockwrite(decf,p^,rr);
        inc(_off,rr);
      until eof(decf);
      if show then closebox;
      freemem(p,ps);
      end;
  end;

  procedure DumpMsg;
  const hc : array[0..15] of char = '0123456789ABCDEF';
  var s   : string;
      i   : integer;
      rr  : word;
      buf : array[0..15] of byte;
      adr : word;
      p,b : byte;
      s68 : atext;
  begin
    moment;
    adr:=0;
    s68:=sp(68);
    repeat
      blockread(decf,buf,16,rr);
      dec(rr);
      s:=hex(adr,4)+s68;
      p:=7;
      for i:=0 to min(15,rr) do begin
        b:=buf[i];
        s[p]:=hc[b shr 4];
        s[p+1]:=hc[b and 15];
        inc(p,3);
        if i=7 then inc(p);
        if b<32 then
          s[i+57]:='�'
        else
          s[i+57]:=chr(b);
        end;
      wrslong(s);
      inc(adr,16);
    until eof(decf) or (adr>$ffe0) or (ioresult<>0);
    closebox;
  end;

  procedure SetQC(netztyp:byte);
  var p,p2,n  : byte;
      empty   : boolean;
      ac      : set of char;
      qs      : string[80];
  begin
    qchar:=QuoteChar;

    { 31.01.2000 robo }
    p:=cpos('&',qchar);
    p2:=cpos('#',hdp^.absender);
    if p>0 then qchar[p]:='$';

{    if netztyp=nt_UUCP then begin }
    if (netztyp in [nt_UUCP,nt_PPP]) or ((p>0) and (p2>0)) then begin
    { /robo}

      p:=cpos('@',qchar); if p>0 then delete(qchar,p,1);
      p:=cpos('$',qchar); if p>0 then delete(qchar,p,1);
      end;
    p:=cpos('@',qchar);
    empty:=false;
    if p=0 then begin
      p:=pos('$',qchar);
      empty:=true;
      end;
    if p>0 then with hdp^ do
      if ustr(left(absender,8))='ZU_LANG_' then
        delete(qchar,p,1)
      else begin
        if cpos(' ',realname)>1 then qs:=trim(realname)
        else qs:=absender;
        ac:=['A'..'Z','a'..'z','�','�','�','�','�','�','�','0'..'9'];
        delete(qchar,p,1);
        insert(qs[1],qchar,p); inc(p);
        p2:=2; n:=0;
        while (p2<=length(qs)) and (qs[p2]<>'@') and
              (qs[p2]<>'%') and (qs[p2]<>'#') do begin
          if (qs[p2] in ac) and not (qs[p2-1] in ac)
          then begin
            insert(qs[p2],qchar,p);
            inc(p); inc(n);
            end;
          inc(p2);
          end;
        if (n=0) and empty then delete(qchar,p-1,1);
        end;
  end;

  function mausname(s:string):string;
  var p : byte;
  begin
    p:=cpos('@',s);
    if (p=0) or ((hdp^.netztyp<>nt_Maus) and (hdp^.netztyp<>nt_Fido)) then
      mausname:=s
    else
      mausname:=trim(left(s,p-1))+' @ '+trim(mid(s,p+1));
  end;

  procedure Clip_Tearline;   { Fido - Tearline + Origin entfernen }
  var s  : string;           { s. auch XP6.Clip_Tearline!         }
      rr : word;
      p  : byte;
      l  : longint;
  begin
    l:=max(0,filesize(f)-200);
    seek(f,l);
    blockread(f,s[1],200,rr);
    s[0]:=chr(rr);
    p:=max(0,length(s)-20);
    while (p>0) and (copy(s,p,6)<>#13#10'--- ')
                and (copy(s,p,7)<>#13#10'---'#13#10) do
      dec(p);
{   p:=pos(#13#10+XP_origin,s); }
    if p>0 then begin
      seek(f,l+p-1);
      truncate(f);
      end;
  end;

  procedure Chg_Tearline;   { Fido - Tearline + Origin verfremden }
  const splus : string [1] = '+';
  var s  : string;
      rr : word;
      p  : byte;
      l  : longint;
  begin
    l:=max(0,filesize(f)-200);
    seek(f,l);
    blockread(f,s[1],200,rr);
    s[0]:=chr(rr);
    p:=max(0,length(s)-20);
    while (p>0) and (copy(s,p,6)<>#13#10'--- ')
                and (copy(s,p,7)<>#13#10'---'#13#10) do
      dec(p);
    if p>0 then begin
      seek(f,l+p+2);
      blockwrite(f,splus[1],1);
      while (p<length(s)-11) and (copy(s,p,13)<>#13#10' * Origin: ') do
        inc(p);
      if p<length(s)-13 then begin
        seek(f,l+p+2);
        blockwrite(f,splus[1],1);
      end;
    end;
  end;

  function mausstat(s:string):string;
  var dat: string[20];
  begin
    dat:=copy(s,8,2)+'.'+copy(s,6,2)+'.'+copy(s,2,4)+' um '+
         copy(s,10,2)+':'+copy(s,12,2);
    case s[1] of
      'N' : mausstat:='noch nicht gelesen';
      'Z' : mausstat:='zur�ckgestellt am '+dat;
      'B' : mausstat:='beantwortet am '+dat;
      'G' : mausstat:='erhalten/gelesen am '+dat;
      'W' : mausstat:='weitergeleitet am '+dat;
      'M' : mausstat:='im MausNet seit '+dat;
      'A' : mausstat:='angekommen am '+dat;
      'Y' : mausstat:='angekommen beim Gateway am '+dat;
      'T' : mausstat:='im Tausch seit '+dat;
    else    mausstat:='unbekannter Status '+s[1]+' ('+dat+')';
    end;
  end;

  function gr(nr:word):string;
  begin
    gr:=getres2(361,nr);
  end;

  function ddat:string;
  begin
    with hdp^ do
      if ddatum='' then
        ddat:=''
      else
        ddat:=', '+copy(ddatum,7,2)+'.'+copy(ddatum,5,2)+'.'+copy(ddatum,3,2)+
              ', '+copy(ddatum,9,2)+':'+copy(ddatum,11,2)+':'+copy(ddatum,13,2);
  end;

  procedure GetStatus;
  begin
    mstatus:='';
    with hdp^ do begin
      if attrib and attrCrash<>0 then mstatus:=mstatus+', Crash';
      if attrib and attrFile<>0  then mstatus:=mstatus+', File-Attach';
      if attrib and attrReqEB<>0 then mstatus:=mstatus+getres2(363,1);  { ' EB-Anforderung' }
      if attrib and attrIsEB<>0  then mstatus:=mstatus+getres2(363,2);  { ' Empfangsbest�tigung' }
      if attrib and attrControl<>0   then mstatus:=mstatus+getres2(363,3); { ' Steuernachricht' }
      freeres;
      delete(mstatus,1,2);
      end;
  end;

  procedure GetPgpStatus;
  var flags : longint;
  begin
    mstatus:='';
    dbReadN(mbase,mb_flags,flags);
    with hdp^ do begin
      if pgpflags and fPGP_avail<>0  then mstatus:=mstatus+getres2(363,4); { 'PGP-Key vorhanden' }
      if pgpflags and fPGP_haskey<>0 then mstatus:=mstatus+getres2(363,5); { 'Nachricht enth�lt PGP-Key' }
      if pgpflags and fPGP_request<>0 then mstatus:=mstatus+getres2(363,6); { 'PGP-Keyanforderung' }
      if pgpflags and (fPGP_signed+fPGP_clearsig)<>0 then
        mstatus:=mstatus+getres2(363,9);  { 'PGP-Signatur vorhanden' }
      if (pgpflags and fPGP_sigok<>0) or (flags and 1<>0) then
        mstatus:=mstatus+getres2(363,7);  { 'PGP-Signatur o.k.' }
      if (pgpflags and fPGP_sigerr<>0) or (flags and 2<>0) then
        mstatus:=mstatus+getres2(363,8);  { 'ung�ltige PGP-Signatur!' }
      freeres;
      delete(mstatus,1,2);
      end;
  end;

  procedure QuoteTtoF;
  var reads      : string[120];
      stmp       : string;
      lastqc     : string[20];
      qspaces    : string[QuoteLen];
      p,q        : integer;
      lastquote  : boolean;   { vorausgehende Zeile war gequotet }
      blanklines : longint;
      i          : longint;
      endspace   : boolean;
      { 03.02.2000 robo }
      qc         : char;
      { /robo }
      spaces     : integer;

    procedure FlushStmp;
    begin
      if stmp<>'' then begin
        wrslong(lastqc+stmp);
        stmp:='';
        end;
    end;

    function GetQCpos:byte;
    var p,q : integer;
    begin
      spaces:=0;
      p:=cpos('>',s);
      if p>5 then p:=0
      else if p>0 then begin
        repeat        { korrektes Ende des (mehrfach-?)Quotezeichens }
          q:=p+1;     { ermitteln                                    }
          while (q<=length(s)) and (q-p<=4) and (s[q]<>'>') do
            inc(q);
          if (q<=length(s)) and (s[q]='>') then p:=q;
        until q>p;
        while (p<length(s)) and (s[p+1]='>') do inc(p);
        q:=p;
        while (q<length(s)) and (s[q+1]=' ') do inc(q);
        spaces:=q-p;
      end;
      GetQCpos:=p;
    end;

(*
    function IniQuote:boolean;
    var i : byte;
    begin
      IniQuote:=false;
      if s[1]<>'<' then
        for i:=1 to {p}cpos('>',s)-1 do
          if s[i] in ['A'..'Z','a'..'z','0'..'9','�','�','�','�','�','�','�'] then
            IniQuote:=true;
    end;
*)

  begin
    qspaces:=sp(length(qchar)-length(ltrim(qchar)));
    stmp:='';
    lastquote:=false;
    blanklines:=0;
    while not eof(t) do begin
      read(t,reads);                         { max. 120 Zeichen einlesen }
      endspace:=(reads[length(reads)]=' ') or eoln(t);
      p:=length(reads);                      { rtrim, falls kein Leer-Quote }
      while (p>0) and (reads[p]=' ') do dec(p);
      s:=left(reads,p);
      if left(s,11)=' * Origin: ' then s[2]:='+'
      else if (left(s,4)='--- ') or (s='---') then s[2]:='+';
      if not iso1 and ConvIso and (s<>'') then
        ISO_conv(s[1],length(s));            { ISO-Konvertierung }
      if s=#3 then begin
        FlushStmp;                           { #3 -> Leerzeile einf�gen }
        wrslong('');
      end else
      if s='' then begin
        FlushStmp;
        if lastquote then                    { Leerzeile quoten }
          wrslong('')
        else
          inc(blanklines)
      end
      else begin
        p:=GetQCpos;
        if blanklines>0 then
          if (p=0) { or not IniQuote } then  { n�chste Zeile war nicht gequotet }
            for i:=1 to blanklines do    { -> Leerzeilen mitquoten          }
              wrslong(qchar)
          else
            wrslong('');                 { sonst Leerzeilen nicht quoten }
        blanklines:=0;
        if (p=0) { or not IniQuote } then begin
          insert(qchar,s,1); inc(p,length(qchar));
          lastquote:=false;
        end
        else begin                           { neues Quote-Zeichen einfg. }
          lastquote:=true;
          q:=0;
          while (s[q+1]=#9) or (s[q+1]=' ') do inc(q);
          delete(s,1,q); dec(p,q);
          q:=1;
          while s[q]<>'>' do inc(q);
          insert('>',s,q); inc(p);
          if qchar[length(qchar)]=' ' then begin    { BLA>Fasel -> BLA> Fasel }
            while (q<=length(s)) and (s[q]='>') do inc(q);
            if (q<=length(s)) and (s[q]<>' ') then begin
              insert(' ',s,q); inc(p);
            end;
          end;
          insert(qspaces,s,1); inc(p,length(qspaces));
        end;
        q:=1;
        while (s[q] in [' ','A'..'Z','a'..'z','0'..'9','�','�','�','�','�','�','�'])
          and (q<p) do inc(q);
        qc:=s[q];
        while q<p do begin
          if (s[q]=' ') and (s[q+1] in [' ',qc]) then begin
            delete(s,q,1);
            dec(p);
          end
          else inc(q);
        end;
        inc(p,spaces);
        if stmp<>'' then begin               { Rest von letzter Zeile }
          if left(s,length(lastqc))=lastqc then
            insert(stmp,s,p+1)               { einf�gen }
          else
            FlushStmp;
          stmp:='';
        end;
        LastQC:=left(s,p);
        if (length(s)>=QuoteBreak) and
           ((lastchar(s)<#176) or (lastchar(s)>#223))  { Balkengrafik }
        then
          while length(s)>=QuoteBreak do begin   { �berl�nge abschneiden }
            p:=QuoteBreak;
            while (p>0) and (s[p]<>' ') and (s[p]<>#9) do dec(p);
            if p<=QuoteBreak div 2 then p:=QuoteBreak;
            stmp:=mid(s,p+iif(s[p]<=' ',1,0))+iifs(endspace,' ','');
            TruncStr(s,p-1);
            while s[length(s)]=' ' do dec(byte(s[0]));   { rtrim(s) }
            if not eoln(t) and (length(stmp)+length(LastQC)<QuoteBreak) then begin
              read(t,reads);      { Rest der Zeile nachladen }
              endspace:=(reads[length(reads)]=' ') or eoln(t);
              if not iso1 and ConvIso and (reads<>'') then
                ISO_conv(reads[1],length(reads));    { ISO-Konvertierung }
              stmp:=stmp+rtrim(reads)+iifs(endspace,' ','');
            end;
            if length(stmp)+length(LastQC)>=QuoteBreak then begin
              wrslong(s);
              s:=LastQC+rtrim(stmp);
              stmp:='';
            end;
          end;
        while (s[length(s)]=' ') do dec(byte(s[0]));   { rtrim }
        wrslong(s);
      end;
      readln(t);
    end;
    FlushStmp;
    wrs('');
  end;

  function telestring(s:string):string;
  var ts    : string;
      tn,vs : string[40];
  begin
    s:='�'+s;
    if not testtelefon(s) then
      telestring:=s+getres2(361,50)    { ' [ung�ltiges Format]' }
    else begin
      ts:='';
      repeat
        tn:=ustr(GetToken(s,' '));
        vs:='';
        while (tn<>'') and (tn[1]>'9') do begin
          case tn[1] of
            'V' : vs:=vs+', '+getres2(361,51);  { 'Voice' }
            'F' : vs:=vs+', '+getres2(361,52);  { 'Fax' }
            'B' : vs:=vs+', '+getres2(361,53);  { 'Mailbox' }
            'P' : vs:=vs+', '+getres2(361,54);  { 'City-Ruf' }
          end;
          delfirst(tn);
          end;
        if lastchar(tn)='Q' then
          insert(' ',tn,length(tn));
        if cpos('-',vorwahl)>0 then
          if left(tn,cpos('-',tn))='+'+left(vorwahl,cposx('-',vorwahl)) then
            tn:=NatVorwahl+mid(tn,cpos('-',tn)+1)
          else
            if firstchar(tn)='+' then
              tn:=IntVorwahl+mid(tn,2);
        delete(vs,1,2);
        ts:=ts+', '+tn+iifs(vs<>'',' ('+vs+')','')
      until s='';
      telestring:=mid(ts,3);
      end;
  end;

  procedure TestSoftware;
  begin
    if not mailerflag then
      if not registriert.r2 and ntForceMailer(hdp^.netztyp)
         and (dbReadInt(mbase,'ablage')=10) then begin
        wrs(gr(20)+xp_xp+' '+verstr+' '+gr(60));   { '(unregistriert)' }
        mailerflag:=true;
        end;
  end;

  { 01/2000 oh }
  function ohfill(s:string;l:byte) : string;
  begin
    while (length(s)<l) do s:=s+#32;
    ohfill:=s;
  end;
  { /oh }

begin
  extheadersize:=0; exthdlines:=0; hdlines:=0;
  if ex_mpdata=nil then mpdata.startline:=0
  else mpdata:=ex_mpdata^;
  ex_mpdata:=nil;
  multipart:=(mpdata.startline>0);
  dbReadN(mbase,mb_brett,_brett);
  if art=xTractPuf then
    Xread(name,append)
  else begin
    ReadHeadEmpf:=1; ReadKoplist:=true;
    new(hdp);
    ReadHeader(hdp^,hds,true);
    assign(f,name);
    if hds=1 then begin
      rewrite(f,1);
      close(f);
      dispose(hdp);
      ExtCliptearline:=true;
      ExtChgtearline:=false;
      exit;
      end;
    if append then begin
      reset(f,1);
      if ioresult<>0 then rewrite(f,1)
      else seek(f,filesize(f));
      end
    else
      rewrite(f,1);
    extpos:=filepos(f);
    dbReadN(mbase,mb_EmpfDatum,edat);
    if smdl(IxDat('2712300000'),edat) then
      dbReadN(mbase,mb_wvdatum,edat);
    iso1:=(dbReadInt(mbase,'netztyp') and $2000)<>0;
    if (schablone<>'') and (exist(schablone)) then begin
      assign(t,ownpath+schablone);
      reset(t);
      while not eof(t) do with hdp^ do begin
        readln(t,s);
        wempf:=empfaenger;
        if cpos('�',wempf)>0 then begin
          delete(wempf,cpos('�',wempf),1);
          wempf:=wempf+getres2(361,1);   { '  (internes CrossPoint-Brett)' }
          end;
        if cpos('$',s)>0 then begin
          rps(s,'$BRETT',wempf);
          p:=length(wempf);
          while (p>0) and (wempf[p]<>'/') do dec(p);
          case firstchar(dbReadStr(mbase,'brett')) of
            '$'  : rps(s,'$AREA',trim(getres2(361,1)));  { '(internes CrossPoint-Brett)' }
            'A'  : rps(s,'$AREA',mid(wempf,p+1));
            else   rps(s,'$AREA',getres2(361,48));       { 'private Mail' }
          end;
          if wempf[1]='/' then delfirst(wempf);
          while cpos('/',wempf)>0 do wempf[cpos('/',wempf)]:='.';
          rps(s,'$NEWSGROUP',wempf);
          rpsuser(s,absender,realname);
          rps(s,'$RNAME',iifs(realname='','',realname+' '));
          rps(s,'$(RNAME)',iifs(realname='','','('+realname+') '));
          rps(s,'$FIDOEMPF',fido_to);
          rps(s,'$BETREFF',betreff);
          rps(s,'$SUBJECT',betreff);
          rps(s,'$ERSTELLT',fdat(datum));
          if pos('$MSGDATE',ustr(s))>0 then
            rpsdat(s,'$MSGDATE',fdat(datum));
          rps(s,'$ERSTZEIT',ftime(datum));
          rps(s,'$ERSTTAG2',left(zdow(datum),2));
          rps(s,'$ERSTTAG',zdow(datum));
          rps(s,'$ERHALTEN',fdat(longdat(edat)));
          rps(s,'$RECEIVED',fdat(longdat(edat)));
          rps(s,'$MSGID',msgid);
          rpsdate(s);
          if lastchar(s)=' ' then dellast(s);
          end;
        wrslong(s);
        end;
      close(t);
      end;

    sizepos:=-1;
    if (art=xTractHead) or (art=xTractDump) then begin
      mailerflag:=false;
      lasttrenn:=false;
      for hdln:=1 to HeaderLines do
        case ExtraktHeader[hdln] of

    hdf_Trenn :  if not lasttrenn then begin
                   if hdln=HeaderLines then TestSoftware;
                   wrs(dup(iif(art=xTractHead,70,72),'-'));    { Trennzeile }
                   lasttrenn:=true;
                 end;

    hdf_EMP   :  begin
                   if hdp^.fido_to<>'' then s:=' ('+hdp^.fido_to+')'
                   else s:='';
                   if hdp^.empfanz=1 then
                     if cpos('@',hdp^.empfaenger)>0 then
                       wrs(gr(2)+mausname(hdp^.empfaenger)+s)   { 'Empfaenger : ' }
                     else
                       wrs(gr(2)+hdp^.empfaenger+s)
                   else begin
                     s:=gr(2)+hdp^.empfaenger;     { 'Empfaenger : ' }
                     for i:=2 to hdp^.empfanz do begin
                       ReadHeadEmpf:=i;
                       spush(hdp^.kopien,sizeof(hdp^.kopien));
                       ReadHeader(hdp^,hds,false);
                       spop(hdp^.kopien);
                       if length(s)+length(hdp^.empfaenger)>iif(listscroller,76,77)
                       then begin
                         wrs(s); s:=gr(2{15});
                         end
                       else
                         s:=s+', ';
                       s:=s+hdp^.empfaenger;
                       end;
                     wrs(s);
                     end;
                 end;

    hdf_KOP   :  if Assigned(hdp^.kopien) then begin
                   s:=getres2(361,28)+hdp^.kopien^.empf;    { 'Kopien an  : ' }
                   pnt:=hdp^.kopien^.next;
                   while pnt<>nil do begin
                     if length(s)+length(pnt^.empf)>iif(listscroller,76,77)
                     then begin
                       wrs(s); s:=getres2(361,28);
                       end
                     else
                       s:=s+', ';
                     s:=s+pnt^.empf;
                     pnt:=pnt^.next;
                     end;
                   wrs(s);
                   end;

    hdf_DISK  :  if hdp^.AmReplyTo<>'' then
                   if hdp^.amrepanz=1 then
                     wrs(gr(3)+hdp^.amreplyto)           { 'Antwort in : ' }
                   else begin
                     s:=gr(3)+hdp^.amreplyto;
                     for i:=2 to hdp^.amrepanz do begin
                       ReadHeadDisk:=i;
                       spush(hdp^.kopien,sizeof(hdp^.kopien));
                       ReadHeader(hdp^,hds,false);
                       spop(hdp^.kopien);
                       if length(s)+length(hdp^.amreplyto)>iif(listscroller,76,77)
                       then begin
                         wrs(s); s:=gr(3{15});
                         end
                       else
                         s:=s+', ';
                       s:=s+hdp^.amreplyto;
                       end;
                     wrs(s);
                     end;

    hdf_ABS   :  begin
                   if ((hdp^.netztyp=nt_fido) or (hdp^.netztyp=nt_QWK)) and
                      (hdp^.realname='') and
                      (length(hdp^.absender)<54) and NodeOpen and
                      (pos(':',hdp^.absender)>0) then begin
                                  { sieht nach einer Fido-Adresse aus ... }
                     GetNodeinfo(hdp^.absender,ni,0);
                     if ni.found then begin
(*
                       hdp^.realname:=left(ni.boxname,60-length(hdp^.absender));
                       if length(hdp^.absender)+length(hdp^.realname)+length(ni.standort)<60
                       then
                         hdp^.realname:=hdp^.realname+', '+ni.standort;
*)
                       hdp^.realname:=ni.boxname+', '+ni.standort;
                     end;
                   end;
                   wrs(gr(6)+mausname(hdp^.absender)+      { 'Absender   : ' }
                       iifs(hdp^.realname<>'','  ('+hdp^.realname+')',''));
                 end;

    hdf_OEM    : if (hdp^.oem<>'') and (left(hdp^.oem,length(hdp^.empfaenger))
                     <>hdp^.empfaenger) then
                   wrs(gr(16)+hdp^.oem);         { 'Org.-Empf. : ' }
    hdf_OAB    : if hdp^.oab<>'' then            { 'Org.-Abs.  : ' }
                   wrs(gr(18)+hdp^.oab+iifs(hdp^.oar<>'','  ('+hdp^.oar+')',''));
    hdf_WAB    : if hdp^.wab<>'' then            { 'Weiterleit.: ' }
                   wrs(gr(17)+hdp^.wab+iifs(hdp^.war<>'','  ('+hdp^.war+')',''));
    hdf_ANTW   : if (hdp^.pmReplyTo<>'') and
                    ((ustr(hdp^.pmReplyTo)<>ustr(hdp^.absender))) then   { 'Antwort an : ' }
                   wrs(gr(27)+hdp^.pmReplyTo);

    hdf_BET    : wrs(gr(5)+hdp^.betreff);  { 'Betreff    : ' }
    hdf_ZUSF   : if hdp^.summary<>'' then        { 'Zus.fassung: ' }
                   wrs(gr(23)+hdp^.summary);
    hdf_STW    : if hdp^.keywords<>'' then       { 'Stichworte : ' }
                   wrs(gr(22)+hdp^.keywords);

    hdf_ROT    : if hdp^.pfad<>'' then begin
                   i:=iif((_maus and listscroller) and not listfixedhead,77,79);
                   s:=hdp^.pfad;
                   hs:=gr(7);                    { 'Pfad       : ' }
                   while s<>'' do begin
                     p:=length(s);
                     if p+length(hs)>i then begin
                       p:=i-length(hs);
                       while (p>30) and (s[p]<>'!') and (s[p]<>' ')
                             and (s[p]<>'.') do
                         dec(p);
                       if p=30 then p:=i-length(hs);
                       end;
                     wrs(hs+left(s,p));
                     delete(s,1,p);
                     hs:=gr(15);                 { sp(...) }
                     end;
                   end;

    hdf_MID    : if hdp^.msgid<>'' then
                   wrs(gr(8)+hdp^.msgid);        { 'Message-ID : ' }
    hdf_BEZ    : if hdp^.ref<>'' then            { 'Bezugs-ID  : ' }
                   wrs(gr(19)+hdp^.ref+iifs(hdp^.refanz=0,'',', ...'));

    hdf_EDA    : wrs(gr(9)+copy(zdow(hdp^.datum),1,2)+' '+fdat(hdp^.datum)+', '+  { 'Datum      : ' }
                     ftime(hdp^.datum)+iifs(hdp^.datum<>longdat(edat),'  ('+
                        gr(10)+fdat(longdat(edat))+')',''));   { 'erhalten: ' }

    hdf_LEN    : begin
                   sizepos:=filesize(f);
                   wrs(reps(gr(11),strs(hdp^.groesse)));  { 'Groesse    : %s Bytes' }
                 end;

    hdf_MAILER : if hdp^.programm<>'' then begin
                   wrs(gr(20)+hdp^.programm);    { 'Software   : ' }
                   mailerflag:=true;
                   end;

    hdf_ORG    : if hdp^.organisation<>'' then
                   wrs(gr(24)+hdp^.organisation);   { 'Organisat. : ' }
    hdf_POST   : if hdp^.postanschrift<>'' then
                   wrs(gr(25)+hdp^.postanschrift);  { 'Postadresse: ' }
    hdf_TEL    : if hdp^.telefon<>'' then
                   wrs(gr(26)+telestring(hdp^.telefon));  { 'Telefon    : ' }

    hdf_FILE   : if multipart and (mpdata.fname<>'') then
                   wrs(gr(12)+mpdata.fname)    { 'Dateiname  : ' }
                 else if hdp^.datei<>'' then
                   wrs(gr(12)+hdp^.datei+ddat);

    hdf_MSTAT  : if (hdp^.pm_bstat<>'') and (hdp^.pm_bstat[1]<>'N') then
                   wrs(gr(13)+mausstat(hdp^.pm_bstat));     { 'PM-Status  : ' }
    hdf_STAT   : begin
                   GetStatus;
                   if mstatus<>'' then wrs(gr(21)+mstatus);  { 'Status:    : ' }
                 end;
    hdf_PGPSTAT: begin
                   GetPgpStatus;
                   if mstatus<>'' then wrs(gr(29)+mstatus);  { 'PGP-Status : ' }
                 end;

    hdf_ERR    : if hdp^.error<>'' then
                   wrs(gr(14)+hdp^.error);                  { 'Fehler!    : ' }

    hdf_DIST   : if hdp^.distribution<>'' then
                   wrs(gr(31)+hdp^.distribution);           { 'Distribut. : ' }

    hdf_Homepage: if hdp^.homepage<>'' then
                    wrs(gr(32)+hdp^.homepage);              { 'Homepage   : ' }

    hdf_Part    : if multipart and (mpdata.part>0) then
                    wrs(gr(33)+strs(mpdata.part)+           { 'Teil       : ' }
                        gr(34)+strs(mpdata.parts));         { ' von ' }

    { 01/2000 oh}
    hdf_Cust1   : if mheadercustom[1]<>'' then if hdp^.Cust1<>'' then begin
                    wrs(ohfill(mheadercustom[1],11)+': '+hdp^.Cust1);
                  end;
    hdf_Cust2   : if mheadercustom[2]<>'' then if hdp^.Cust2<>'' then begin
                    wrs(ohfill(mheadercustom[2],11)+': '+hdp^.Cust2);
                  end;
    { /oh }

  { Priorit�t im Listenkopf anzeigen:                                     }
  { R�ckgabewert hinter dem PriorityFlag extrahieren und zuordnen         }

  hdf_Priority: if hdp^.Priority <> 0 then
       case hdp^.Priority of
         { Wert aus Header �bernehmen                                     }
         1: wrs(gr(35) + GetRes2(272, 1));     { 'Priorit�t  : H�chste'   }
         2: wrs(gr(35) + GetRes2(272, 2));     { 'Priorit�t  : Hoch'      }
         3: wrs(gr(35) + GetRes2(272, 3));     { 'Priorit�t  : Normal'    }
         4: wrs(gr(35) + GetRes2(272, 4));     { 'Priorit�t  : Niedrig'   }
         5: wrs(gr(35) + GetRes2(272, 5));     { 'Priorit�t  : Niedrigste'}
       end;

  { /Priorit�t im Listenkopf anzeigen                                     }

  end;

      TestSoftware;

      extheadersize:=filepos(f)-extpos;
      exthdlines:=min(hdlines,screenlines-5);
      end;
    dbReadN(mbase,mb_groesse,size);
    if (art<>xtractQuote) and (art<>xTractDump) then begin
      if multipart then begin
        mpsize:=filesize(f);
        close(f);
        mehdl:=exthdlines; mehds:=extheadersize;
        ExtractMultiPart(mpdata,name,true);    { rekursiver Aufruf von }
        exthdlines:=mehdl;                     { extact_msg!           }
        extheadersize:=mehds;
        reset(f,1);
        if sizepos>=0 then begin
          mpsize:=filesize(f)-mpsize;
          seek(f,sizepos);
          s:=reps(gr(11),strs(mpsize));
          blockwrite(f,s[1],length(s));
          end;
        seek(f,filesize(f));
        end
      else begin
        XReadIsoDecode:=true;
        XreadF(hds+iif(hdp^.typ='B',hdp^.komlen,0),f);
        end;
      if decode<>0 then begin
        FastMove(f,decf,sizeof(f));
        case decode of
         -1 : do_decode(-1,filesize(f)-size);      { Rot13 }
          1 : if IS_QPC(hdp^.betreff) then
                do_decode(1,filesize(f)-size)
              else
                if IS_DES(hdp^.betreff) then
                  do_decode(2,filesize(f)-size);
        end;
        end;
      end
    else begin                                     { Quote / Hex-Dump }
      tmp:=TempS(2000+dbReadInt(mbase,'msgsize')*iif(art=xTractQuote,1,4));
      if ListQuoteMsg<>'' then
        tmp:=ListQuoteMsg
      else begin
        XReadIsoDecode:=(art=xTractQuote);
        if multipart then ExtractMultipart(mpdata,tmp,false)
        else Xread(tmp,false);
        if decode<>0 then begin
          assign(decf,tmp);
          reset(decf,1);
          case decode of
           -1 : do_decode(-1,hds);
            1 : if IS_QPC(hdp^.betreff) then
                  do_decode(1,hds)
                else
                  if IS_DES(hdp^.betreff) then
                    do_decode(2,hds);
          end;
          close(decf);
          end;
        end;

      if art=xTractQuote then begin                { Quote }
        SetQC(hdp^.netztyp);
        assign(t,tmp);
        reset(t);
        if not multipart or (ListQuoteMsg<>'') then  { ZC-Header '�berlesen' }
          if ntZCablage(dbReadInt(mbase,'ablage')) then
            repeat
              readln(t,s)
            until (s='') or eof(t)
          else
            for i:=1 to 8 do readln(t);
        QuoteTtoF;
        close(t);
        erase(t);
        end
      else begin                                   { Hex-Dump }
        assign(decf,tmp);
        reset(decf,1);
        DumpMsg;
        close(decf);
        erase(decf);
        end;
      end;
    if (hdp^.netztyp=nt_Fido) and (art=xTractMsg)
      then if ExtCliptearline then Clip_Tearline
                              else if ExtChgTearline then Chg_Tearline;
    { Das Problem wird nun direkt im Lister gel�st...Zeile 1182!
    if (hdp^.groesse=0) and ListFixedHead then begin
      seek(f,filesize(f));
      fillchar(s,sizeof(s),' ');
      s[0]:=#255;
      blockwrite(f,s,2);
    end;
    }
    close(f);
    DisposeEmpflist(hdp^.kopien);
    dispose(hdp);
  end;
  freeres;
  ExtCliptearline:=true;
  ExtChgtearline:=false;
end;


end.
{
  $Log: xp3ex.pas,v $
  Revision 1.16  2002/02/20 19:56:03  rb
  - MimeIsoDecode auch f�r andere Zeichens�tze
  - Iso1ToIBM und IBMToIso1 nach mimedec.pas verlagert
  - text/html wird von UUZ nicht mehr nach IBM konvertiert

  Revision 1.15  2000/12/28 08:43:46  MH
  Fix:
  - Absturz bei Nachrichten, deren Gr��e 0 Byte ist:
    Trat nur bei Mausbedienung und feststehendem Kopf auf!

  Revision 1.14  2000/12/26 19:00:30  MH
  - Variable sauber f�r blockwrite vorbereiten

  Revision 1.13  2000/12/26 13:08:50  MH
  Fix:
  - Absturz bei Nachrichten, deren Gr��e 0 Byte ist:
    Trat nur bei Mausbedienung und feststehendem Kopf auf

  Revision 1.12  2000/12/05 21:21:17  rb
  'Tearline verfremden' �berarbeitet

  Revision 1.11  2000/11/01 03:24:03  rb
  Fido: Tearline+Origin bei Nachricht/Weiterleiten/Kopie&EditTo verfremden

  Revision 1.10  2000/10/25 09:53:44  rb
  Tearline und Origin beim Quoten von Echomail verfremden

  Revision 1.9  2000/10/05 20:09:03  rb
  div. Bugs bei der Kopfanzeige behoben

  Revision 1.8  2000/08/29 21:47:11  oh
  -Bug bei $VPSEUDO gefixt.

  Revision 1.7  2000/08/20 01:00:52  oh
  -Englische Makros eingebaut

  Revision 1.6  2000/06/06 07:59:52  MH
  RFC/PPP: Weitere Anpassungen und Fixes

  Revision 1.5  2000/05/25 19:28:38  rb
  Bugfix f�rs Quoten

  Revision 1.4  2000/04/09 18:23:27  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.12  2000/04/04 21:01:23  mk
  - Bugfixes f�r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.11  2000/03/09 23:39:33  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.10  2000/02/28 23:43:01  rb
  Grmpf, ich hatte vergessen, das nicht mehr ben�tigte 'IniQuote' auszukommentieren

  Revision 1.9  2000/02/28 23:38:12  rb
  Quoten von Leerzeilen verbessert

  Revision 1.8  2000/02/23 23:49:47  rb
  'Dummy' kommentiert, Bugfix beim Aufruf von ext. Win+OS/2 Viewern

  Revision 1.7  2000/02/21 14:55:43  mk
  MH: Prioritaetenbehandlung eingebaut

  Revision 1.6  2000/02/19 11:40:08  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.5  2000/02/17 08:40:29  mk
  RB: * Bug mit zurueckbleibenden Dummy-Header bei Quoten von Multipart beseitigt

}
