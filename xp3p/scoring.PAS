{ $Id: scoring.PAS,v 1.1 2001/07/11 19:47:18 rb Exp $ }

unit scoring;

{$i asldefine.inc}

interface

uses classes;

type tscsettings = record
                     makereport,
                     expire      : boolean;
                   end;
     tscaction = (tscnone, tscskip, tschdronly);

procedure prepare_header (dest, source: tstringlist);

function init_score (mypath, scorefile: string; settings: tscsettings): boolean;
procedure done_score;

function score_message (msghdr: tstringlist; var scaction: tscaction;
                        var addhdr: string): integer;

implementation

uses sysutils, dos, calendar, wildcard, misc, strings;

{
uses crt, dos, calendar, unixdate, hex, inifile, wildcard, misc, strings,
     vpsyslow;
}

const crlf      : string [2] = #13#10;

      tempn        : string [12] = 'XPSCORE$.TMP';
      bakn         : string [12] = 'XPSCORE$.BAK';
      scoren       : string = 'XPSCORE.SC';

      x_xp_halten      = 1;
      x_xp_loeschen    = 2;
      x_xp_gelesen     = 4;
      x_xp_hervorheben = 8;

      err_nodate   =  4;
      err_nogroup  =  7;
      err_noscore  =  8;
      err_nofilt   =  9;
      err_namewosc = 10;
      err_cfg      = 11;

{
      err_nofile   =  1;
      err_noxppath =  2;
      err_noxp     =  3;
      err_nomem    =  6;
      err_nopuf    = 13;
      err_badsw    = 14;
      err_errsw    = 15;
      err_nospace  = 16;
}

type tcmp = (nequs, nequi, equs, ltequ, gtequ, lt, gt, equi, cnone);
const cmpo: array [tcmp] of string =
              ('!==', '!=', '==', '<=', '>=', '<', '>', '=', '');
      { Achtung! Operatoren, die in anderen enthalten sein kînnen,
        mÅssen weiter hinten stehen!
        Also '!=' nach '!=='
              '=' nach '!=', '!==', '<=', '>=' und '=='
             '==' nach '!=='
              '<' nach '<='
              '>' nach '>='
               '' am Schlu· }

type torder   = (vorn, hinten, ascending, descending);
     tdtyp    = (ger, usa);
     taction  = (tskip, thdronly, tfdel, tfhold, tfread, tfemph);
     tloglev  = (tlmin, tlnorm, tlmax);

     ptxt     = ^ttxt;
     ttxt     = record
                  txt      : pstring;
                  next     : ptxt;
                end;

     phdr     = ^thdr;
     thdr     = record
                  hdef,
                  htxt     : pchar;
                  next     : phdr;
                end;

     pentry   = ^tentry;
     tentry   = record
                  keyword,
                  expression : pchar;
                  operator   : tcmp;
                  match      : boolean;
                  next       : pentry;
                end;

     pblock   = ^tblock;
     tblock   = record
                  score    : longint;
                  expires  : datetyp;
                  use_or,
                  leave,
                  match    : boolean;
                  mname    : pchar;
                  matches  : longint;
                  entry    : pentry;
                  next     : pblock;
                end;

     pfilt    = ^tfilt;
     tfilt    = record
                  area     : ptxt;
                  reverse  : boolean;
                  block    : pblock;
                  next     : pfilt;
                end;

     pact     = ^tact;
     tact    = record
                  fromscore,
                  toscore    : longint;
                  action     : taction;
                  next       : pact;
                end;

var
    my_path,
    zlast      : string;
    filtliste  : pfilt;
    actliste   : pact;
    repliste   : ptxt;
    heute      : datetyp;
    znr        : word;
    makereport : boolean;

{
var xp_path,
    p_path,
    puffern,
    runerrstr,
    proz,
    takt       : string;
    loglevel   : tloglev;

    SaveExit: Pointer;
}

function sKB(zahl:longint):string;
  var s:string;
  begin
    str(zahl/1024:1:1,s);
    sKB:=s+' KB';
  end;

function newtxt(txt:string):ptxt;
  var p:ptxt;
      t:ttxt;
  begin
    t.txt:=newstr(shortstring(txt));
    t.next:=nil;
    new(p);
    p^:=t;
    newtxt:=p;
  end;

procedure disposetxt(p:ptxt);
  begin
    if p=nil then exit;
    disposestr(p^.txt);
    dispose(p);
    p:=nil;
  end;

procedure insert_txt(var l,p:ptxt;order:torder);
  var ph:ptxt;
  begin
    if order=vorn then begin
      p^.next:=l;
      l:=p;
    end
    else if order=hinten then begin
      if l=nil then l:=p
      else begin
        ph:=l;
        while ph^.next<>nil do ph:=ph^.next;
        ph^.next:=p;
      end;
    end;
  end;

procedure done_txt(var l:ptxt);
  var ph:ptxt;
  begin
    while l<>nil do begin
      ph:=l^.next;
      disposetxt(l);
      l:=ph;
    end;
  end;

procedure insert_liste(var l:ptxt;s:string;order:torder);
  var pt:ptxt;
  begin
    pt:=newtxt(s);
    insert_txt(l,pt,order);
  end;

procedure add_liste(var l:ptxt;s:string;order:torder);
  begin
    insert_liste(l,s,order);
  end;

function newhdr (hdef, htxt: pchar): phdr;
  var p:phdr;
      t:thdr;
  begin
    t.hdef:=mystrnew(hdef);
    t.htxt:=mystrnew(htxt);
    t.next:=nil;
    new(p);
    p^:=t;
    newhdr:=p;
  end;

procedure disposehdr (p: phdr);
  begin
    if p = nil then exit;
    strdispose (p^.htxt);
    strdispose (p^.hdef);
    dispose (p);
    p := nil;
  end;

procedure insert_hdr (var l, p: phdr; order: torder);
  var ph:phdr;
  begin
    if order = vorn then begin
      p^.next := l;
      l := p;
    end
    else if order = hinten then begin
      if l = nil then l := p
      else begin
        ph := l;
        while ph^.next <> nil do ph := ph^.next;
        ph^.next := p;
      end;
    end;
  end;

procedure done_hdr (var l:phdr);
  var ph:phdr;
  begin
    while l <> nil do begin
      ph := l^.next;
      disposehdr (l);
      l := ph;
    end;
  end;

function newentry (keyw, expr: pchar; operat: tcmp): pentry;
  var p: pentry;
      t: tentry;
  begin
    t.keyword := mystrnew (keyw);
    t.expression := mystrnew (expr);
    t.operator := operat;
    t.match := false;
    t.next := nil;
    new (p);
    p^ := t;
    newentry := p;
  end;

procedure disposeentry (p: pentry);
  begin
    if p = nil then exit;
    strdispose (p^.expression);
    strdispose (p^.keyword);
    dispose (p);
    p := nil;
  end;

procedure insert_entry (var l, p: pentry; order: torder);
  var ph: pentry;
  begin
    if order = vorn then begin
      p^.next := l;
      l := p;
    end
    else if order = hinten then begin
      if l = nil then l := p
      else begin
        ph := l;
        while ph^.next <> nil do ph := ph^.next;
        ph^.next := p;
      end;
    end;
  end;

procedure done_entry (var l: pentry);
  var ph: pentry;
  begin
    while l <> nil do begin
      ph := l^.next;
      disposeentry (l);
      l := ph;
    end;
  end;

function newblock (score: longint; expires: datetyp;
                   use_or, leave: boolean): pblock;
  var p: pblock;
      t: tblock;
  begin
    t.score := score;
    t.expires := expires;
    t.use_or := use_or;
    t.leave := leave;
    t.match := false;
    t.mname := nil;
    t.matches := 0;
    t.entry := nil;
    t.next := nil;
    new (p);
    p^ := t;
    newblock := p;
  end;

procedure disposeblock (p: pblock);
  begin
    if p = nil then exit;
    done_entry (p^.entry);
    strdispose (p^.mname);
    dispose (p);
    p := nil;
  end;

procedure insert_block (var l, p: pblock; order: torder);
  var ph: pblock;
  begin
    if order = vorn then begin
      p^.next := l;
      l := p;
    end
    else if order = hinten then begin
      if l = nil then l := p
      else begin
        ph := l;
        while ph^.next <> nil do ph := ph^.next;
        ph^.next := p;
      end;
    end;
  end;

procedure done_block (var l: pblock);
  var ph: pblock;
  begin
    while l <> nil do begin
      ph := l^.next;
      disposeblock (l);
      l := ph;
    end;
  end;

function newfilt: pfilt;
  var p: pfilt;
      t: tfilt;
  begin
    t.area := nil;
    t.reverse := false;
    t.block := nil;
    t.next := nil;
    new (p);
    p^ := t;
    newfilt := p;
  end;

procedure disposefilt (p: pfilt);
  begin
    if p = nil then exit;
    done_block (p^.block);
    done_txt (p^.area);
    dispose (p);
    p := nil;
  end;

procedure insert_filt (var l, p: pfilt; order: torder);
  var ph: pfilt;
  begin
    if order = vorn then begin
      p^.next := l;
      l := p;
    end
    else if order = hinten then begin
      if l = nil then l := p
      else begin
        ph := l;
        while ph^.next <> nil do ph := ph^.next;
        ph^.next := p;
      end;
    end;
  end;

procedure done_filt (var l: pfilt);
  var ph: pfilt;
  begin
    while l <> nil do begin
      ph := l^.next;
      disposefilt (l);
      l := ph;
    end;
  end;

function newact (fscore, tscore: longint; act: taction): pact;
  var p: pact;
      t: tact;
  begin
    t.fromscore := fscore;
    t.toscore := tscore;
    t.action := act;
    t.next := nil;
    new (p);
    p^ := t;
    newact := p;
  end;

procedure disposeact (p: pact);
  begin
    if p = nil then exit;
    dispose (p);
    p := nil;
  end;

procedure insert_act (var l, p: pact; order: torder);
  var ph: pact;
  begin
    if order = vorn then begin
      p^.next := l;
      l := p;
    end
    else if order = hinten then begin
      if l = nil then l := p
      else begin
        ph := l;
        while ph^.next <> nil do ph := ph^.next;
        ph^.next := p;
      end;
    end;
  end;

procedure done_act (var l: pact);
  var ph: pact;
  begin
    while l <> nil do begin
      ph := l^.next;
      disposeact (l);
      l := ph;
    end;
  end;
(*
function datumstr(dt:datetyp;dtyp:tdtyp):string;
  var s:string;
  begin
    if dtyp=ger then begin
      s:=wordstr(day(dt),10,2)+'.'+wordstr(month(dt),10,2)+'.';
      if year(dt)<>$ffff then s:=s+wordstr(year(dt),10,4);
    end
    else if dtyp=usa then begin
      s:=wordstr(month(dt),10,2)+'/'+wordstr(day(dt),10,2)+'/';
      if year(dt)<>$ffff then s:=s+wordstr(year(dt),10,4);
    end;
    datumstr:=s;
  end;

function zeitstr(h,m,s:word):string;
  begin
    zeitstr:=wordstr(h,10,2)+':'+wordstr(m,10,2)+':'+wordstr(s,10,2);
  end;

procedure log(n,ls:string);
  var lf:text;
      h,m,s,sh:word;
  begin

    while pos(' ',n)>0 do delete(n,pos(' ',n),1); { Spaces lîschen }
    gettime(h,m,s,sh);
    assign(lf,n);
    if exist(n) then append(lf) else rewrite(lf);
    writeln(lf,datumstr(heute,ger),' ',zeitstr(h,m,s),' ',ls);
    close(lf);
  end;

procedure xlog(n,ls:string);
  var lf:text;
  begin
    while pos(' ',n)>0 do delete(n,pos(' ',n),1); { Spaces lîschen }
    assign(lf,n);
    if exist(n) then append(lf) else rewrite(lf);
    writeln(lf,'                    ',ls);
    close(lf);
  end;

procedure do_report(p:ptxt;bodyn,n:string);
  begin
{
    do_liste(p,bodyn,n,rep_area,'XPScore');
}
  end;
*)
function getline(var f:text):string;
  var s:string;
  begin
    s:='';
    while (length(s)=0) and not eof(f) do begin
      readln(f,s);
      zlast:=s;
      inc(znr);
      while (length(s)>0) and ((s[1]=' ') or (s[1]=#9)) do delete(s,1,1);
      if length(s)>0 then if s[1]='#' then s:='';
      if length(s)>0 then if s[1]=';' then s:='';
    end;
    getline:=s;
  end;

function endf(var f:text;var s:string):boolean;
  begin
    endf:=eof(f) and (length(s)=0);
  end;

procedure get_scorefile(expire_scorefile:boolean);
  var f1,f2:text;
      pa:pact;
      pt:ptxt;
      pf:pfilt;
      pb:pblock;
      pe:pentry;
      order:torder;
      operat:tcmp;

      s,s1,su,area,keyw:string;
      p_keyw,p_expr,p_mname:pchar;
      lastcmd:char;
      p:word;
      score:longint;
      j,gcnt,scnt,excnt,fcnt:integer;
      expires:datetyp;
      use_or,leave,reverse:boolean;
      act:taction;
      fromsc,tosc:longint;

  procedure fehler(s:string;errlev:byte);
    begin
      close(f1);
      writeln;
      writeln;
      writeln('Fehler in Zeile ',znr,':');
      writeln(zlast);
      writeln;
      errorhalt(s,errlev);
    end;

  function getnext(var s:string):string;
    var p:word;
        s1:string;
    begin
      p:=pos(' ',s);
      if p=0 then p:=length(s);
      if p=0
      then fehler('Fehler in '+scoren+' bei '+whereami+': fehlerhafter Eintrag.',err_cfg);
      s1:=copy(s,1,p);
      delete(s,1,p);
      delspace(s);
      delspace(s1);
      if length(s1)=0
      then fehler('Fehler in '+scoren+' bei '+whereami+': fehlerhafter Eintrag.',err_cfg);
      getnext:=s1;
    end;

  function get_expires (var s: string): datetyp;
    var p, y, m, d: word;
        j: integer;
        exd: string;
    begin
      get_expires := packdate (9999, 12, 31);
      p := pos ('EXPIRES', s);
      if p > 0 then begin
        exd := s;
        delete (exd, 1, p - 1 + 7);
        delspace(exd);
        s := copy (s, 1, p - 1);
        delspace(s);
        p := pos ('-', exd);
        if p > 0 then begin
          val (copy (exd, 1, p - 1), y, j);
          if j <> 0
          then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                      err_nodate);
          delete (exd, 1, p);
          p := pos ('-', exd);
          if p = 0
          then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                      err_nodate);
          val (copy (exd, 1, p - 1), m, j);
          if j <> 0
          then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                      err_nodate);
          delete (exd, 1, p);
          val (exd, d, j);
          if j <> 0
          then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                      err_nodate);
        end
        else begin
          p := pos ('.', exd);
          if p > 0 then begin
            val (copy (exd, 1, p - 1), d, j);
            if j <> 0
            then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                        err_nodate);
            delete (exd, 1, p);
            p := pos ('.', exd);
            if p = 0
            then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                        err_nodate);
            val (copy (exd, 1, p - 1), m, j);
            if j <> 0
            then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                        err_nodate);
            delete (exd, 1, p);
            val (exd, y, j);
            if j <> 0
            then fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                        err_nodate);
          end
          else fehler('Fehler in '+scoren+' bei '+whereami+': expires: kein Datum.',
                      err_nodate);
        end;
        if (m<1) or (m>12) or (y<1700) or ((y>9999) and (y<>$ffff))
        or (d<1) or (d>dayspmonth(y,m))
        then fehler('Fehler in '+scoren+' bei '+whereami+': expires: Datum ungÅltig.',
                    err_nodate);
        get_expires := packdate (y, m, d);
      end;
    end;

  begin
    znr:=0;
    gcnt:=0;
    scnt:=0;
    excnt:=0;
    fcnt:=0;
    getmem(p_keyw,256);
    getmem(p_expr,256);
    getmem(p_mname,256);
    if expire_scorefile then begin
      if makereport then
       add_liste(repliste,'bereinige Scorefile: '+scoren,hinten);
      assign(f1,scoren);
      reset(f1);
      assign(f2,my_path+tempn);
      rewrite(f2);
      expires:=packdate(9999,12,31);
      while not eof(f1) do begin
        readln(f1,s);
        su:=s;
        su:=uppercase(su);
        delspace(su);

        if pos('AND ',su)=1 then delete(su,1,4)
        else if pos('OR ',su)=1 then delete(su,1,3);
        delspace(su);
        if pos('SCORE',su)=1 then begin
          expires:=get_expires(su);
          if expires<=heute then inc(excnt);
        end
        else if pos('[',su)=1 then expires:=packdate(9999,12,31);

        if expires>heute then writeln(f2,s);

      end;
      close(f2);
      close(f1);

      if exist (my_path + bakn) then begin
        assign (f1, my_path + bakn);
        erase (f1);
      end;

      assign (f1, scoren);
      rename (f1, my_path + bakn);
      rename (f2, scoren);

      if makereport then begin
        add_liste(repliste,num2str(excnt,10,1)+' Score(s) expired',hinten);
        add_liste(repliste,'',hinten);
      end;
    end;
    begin
      order:=hinten;
      if makereport then
       add_liste(repliste,'Scorefile: '+scoren,hinten);
      assign(f1,scoren);
      reset(f1);
      s:=getline(f1);
      while not endf(f1,s) and (s[1]<>'[') do begin
        s1:=getnext(s);
        val(s1,fromsc,j);
        if j<>0
        then fehler('Fehler in '+scoren+' bei '+whereami+': Zahl erwartet.',err_cfg);
        s1:=getnext(s);
        val(s1,tosc,j);
        if j<>0
        then fehler('Fehler in '+scoren+' bei '+whereami+': Zahl erwartet.',err_cfg);
        if fromsc>tosc
        then fehler('Fehler in '+scoren+' bei '+whereami+': kleinere Zahl zuerst!',err_cfg);
        s1:=uppercase(getnext(s));
        if (s1='KILL') or (s1='SKIP') then act:=tskip
        else if s1='HDRONLY' then act:=thdronly
        else if s1='FLAG_DEL' then act:=tfdel
        else if s1='FLAG_HOLD' then act:=tfhold
        else if s1='FLAG_READ' then act:=tfread
        else if s1='FLAG_EMPH' then act:=tfemph
        else fehler('Fehler in '+scoren+' bei '+whereami+': falsches Kommando: '+s1,err_cfg);
        pa:=newact(fromsc,tosc,act);
        insert_act(actliste,pa,order);
        s:=getline(f1);
      end;
      su:=uppercase(s);
      while not endf(f1,s) do begin
        if s[1]='[' then begin
          lastcmd:='G';
          reverse:=false;
          s:=uppercase(s);
          delete(s,1,1);
          delspace(s);
          if length(s)=0
          then fehler('Fehler in '+scoren+' bei '+whereami+': keine Gruppe.',
                      err_nogroup);
          if s[length(s)]<>']'
          then fehler('Fehler in '+scoren+' bei '+whereami+': keine Gruppe, '']'' erwartet.',
                      err_nogroup);
          delete(s,length(s),1);
          if length(s)=0
          then fehler('Fehler in '+scoren+' bei '+whereami+': keine Gruppe.',
                      err_nogroup);
          if s[1]='!' then begin
            reverse:=true;
            delete(s,1,1);
            delspace(s);
          end;
          if length(s)=0
          then fehler('Fehler in '+scoren+' bei '+whereami+': keine Gruppe.',
                      err_nogroup);
          pf:=newfilt;
          pf^.reverse:=reverse;
          repeat
            p:=pos(',',s);
            if p=0 then area:=s
            else begin
              area:=copy(s,1,p-1);
              delete(s,1,p);
            end;
            delspace(area);
            pt:=newtxt(area);
            insert_txt(pf^.area,pt,order);
            inc(gcnt);
          until p=0;
          insert_filt(filtliste,pf,order);
          s:=getline(f1);
          su:=uppercase(s);
          while not (endf(f1,s) or (s[1]='[')) do begin
            if (pos('AND ',su)=1)
            or (pos('OR ',su)=1)
            or (pos('SCORE',su)=1) then begin
              lastcmd:='S';
              s:=uppercase(s);
              use_or:=false;
              leave:=false;
              if pos('AND ',s)=1 then begin
                delete(s,1,4);
                delspace(s);
              end
              else if pos('OR ',s)=1 then begin
                delete(s,1,3);
                delspace(s);
                use_or:=true;
              end;
              if pos('SCORE',s)<>1
              then fehler('Fehler in '+scoren+' bei '+whereami+': kein Score.',
                          err_noscore);
              delete(s,1,5);
              delspace(s);
              if pos('=',s)=1 then begin
                delete(s,1,1);
                leave:=true;
              end;
              expires:=get_expires(s);
              val(s,score,j);
              if j<>0
              then fehler('Fehler in '+scoren+' bei '+whereami+': kein Score, Zahl erwartet',
                          err_noscore);
              if (expires>heute) then begin
                pb:=newblock(score,expires,use_or,leave);
                insert_block(pf^.block,pb,order);
                inc(scnt);
              end
              else inc(excnt);
              s:=getline(f1);
              su:=uppercase(s);
              while not (endf(f1,s) or (s[1]='[')
                         or (pos('AND ',su)=1)
                         or (pos('OR ',su)=1)
                         or (pos('SCORE',su)=1)) do begin
                if pos('NAME ',su)=1 then begin
                  if lastcmd<>'S'
                  then fehler('Fehler in '+scoren+' bei '+whereami+': Name ohne vorheriges SCORE.',
                              err_namewosc);
                  lastcmd:='N';
                  delete(s,1,5);
                  delspace(s);
                  s:='#'+num2str(scnt,10,1)+': '+s;
                  delspace(s);
                  strpcopy(p_mname,s);
                  pb^.mname:=mystrnew(p_mname);
                end
                else begin
                  if lastcmd='S' then begin
                    strpcopy(p_mname,'#'+num2str(scnt,10,1));
                    pb^.mname:=mystrnew(p_mname);
                  end;
                  lastcmd:='F';
                  operat:=nequs;
                  p:=0;
                  while (operat<cnone) and (p=0) do begin
                    p:=pos(cmpo[operat],s);
                    inc(operat);
                  end;
                  if p>0 then dec(operat);
                  if p=0
                  then fehler('Fehler in '+scoren+' bei '+whereami+': kein Filtereintrag.',
                              err_nofilt);
                  keyw:=copy(s,1,p-1);
                  keyw:=uppercase(keyw);
                  delete(s,1,p+length(cmpo[operat])-1);
                  if (operat<>nequs) and (operat<>equs) then s:=uppercase(s);
                  if length(s)=0
                  then fehler('Fehler in '+scoren+' bei '+whereami+': kein Filtereintrag.',
                              err_nofilt);
                  delspace(keyw);
                  if (expires>heute) then begin
                    strpcopy(p_keyw,keyw);
                    strpcopy(p_expr,s);
                    pe:=newentry(p_keyw,p_expr,operat);
                    insert_entry(pb^.entry,pe,order);
                    inc(fcnt);
                  end;
                end;
                s:=getline(f1);
                su:=uppercase(s);
              end;
            end
            else fehler('Fehler in '+scoren+' bei '+whereami+': kein Score.',
                        err_noscore);
          end;
        end
        else fehler('Fehler in '+scoren+' bei '+whereami+': keine Gruppe, ''['' erwartet.',
                    err_nogroup);
      end;
      close(f1);
      if makereport then begin
        add_liste(repliste,num2str(gcnt,10,1)+' Gruppe(n), '
                           +num2str(scnt,10,1)+' Score(s) (+'
                           +num2str(excnt,10,1)+' expired), '
                           +num2str(fcnt,10,1)+' Filterregel(n)',hinten);
        add_liste(repliste,'',hinten);
      end;
    end;
    freemem(p_mname,256);
    freemem(p_expr,256);
    freemem(p_keyw,256);
  end;

function init_score (mypath, scorefile: string; settings: tscsettings): boolean;
  begin
    makereport:=settings.makereport;

    filtliste:=nil;
    repliste:=nil;
    actliste:=nil;

    my_path:=mypath;
    scoren:=scorefile;

    heute:=today;

    get_scorefile(settings.expire);
    init_score:=true;
  end;

procedure done_score;
  begin
    done_act (actliste);
    done_filt (filtliste);
    done_txt (repliste);
  end;

function score_message (msghdr: tstringlist; var scaction: tscaction;
                        var addhdr: string): integer;
  const smax=1024;
  var i,score:integer;
      p_s,p_s1,p_p,p_hdef,p_htxt:pchar;
      header,ph1,ph2:phdr;
      hdef,htxt:string;
      pf:pfilt;
      pt:ptxt;
      pb:pblock;
      pe:pentry;
      pa:pact;
      match:boolean;
      axflags:word;

  label s_break;

  function s_match(s,ws:pchar;operat:tcmp):boolean;
    begin
      if operat=nequs then s_match:=not wildcardmatchex(ws,s,true)
      else if operat=nequi then s_match:=not wildcardmatchex(ws,s,false)
      else if operat=equs then s_match:=wildcardmatchex(ws,s,true)
      else if operat=ltequ then s_match:=not (strcomp(s,ws)>0)
      else if operat=gtequ then s_match:=not (strcomp(s,ws)<0)
      else if operat=lt then s_match:=strcomp(s,ws)<0
      else if operat=gt then s_match:=strcomp(s,ws)>0
      else if operat=equi then s_match:=wildcardmatchex(ws,s,false)
      else s_match:=false;
    end;

  begin
    scaction:=tscnone;
    addhdr:='';
    getmem(p_s,smax+1);
    getmem(p_s1,smax+1);
    getmem(p_hdef,smax+1);
    getmem(p_htxt,smax+1);
    header:=nil;
    for i:=0 to msghdr.count-1 do begin
      strlcopy(p_s,pchar(msghdr[i]),smax);
{
      p:=pos(':',s);
      if p=0
      then fehler(crlf+'Fehler bei '+whereami+': kein Puffer oder Header defekt',err_nopuf);
      hdef:=copy(s,1,p-1);
      upstr(hdef);
      delete(s,1,p);
      delspace(s);
      htxt:=s;
}
      p_p:=strpos(p_s,':');
{
      if p_p=nil
      then fehler(crlf+'Fehler bei '+whereami+': kein Puffer oder Header defekt',err_nopuf);
}
      strlcopy(p_hdef,p_s,p_p-p_s);
      strupper(p_hdef);
      inc(p_p);
      strcopy(p_htxt,p_p);
      strdelspace(p_htxt);

      strlcopy(p_s1,p_hdef,255);
      hdef:=strpas(p_s1);

      strlcopy(p_s1,p_htxt,255);
      htxt:=strpas(p_s1);

      ph1:=newhdr(p_hdef,p_htxt);
      insert_hdr(header,ph1,hinten);
    end;

    score:=0;

    pf:=filtliste;
    while pf<>nil do begin
      pt:=pf^.area;
      while pt<>nil do begin
        ph1:=header;
        while ph1<>nil do begin
          if strcomp(ph1^.hdef,'NEWSGROUPS')=0 then begin
            strpcopy(p_s,pt^.txt^);
            if wildcardmatchex(p_s,ph1^.htxt,false) xor pf^.reverse then begin
              pb:=pf^.block;
              while pb<>nil do begin
                pe:=pb^.entry;
                while pe<>nil do begin
                  ph2:=header;
                  while ph2<>nil do begin
                    if strcomp(ph2^.hdef,pe^.keyword)=0 then
                     pe^.match:=pe^.match or s_match(ph2^.htxt,pe^.expression,pe^.operator);
                    ph2:=ph2^.next;
                  end;
                  pe:=pe^.next;
                end;
                match:=not pb^.use_or;
                pe:=pb^.entry;
                while pe<>nil do begin
                  if pb^.use_or then match:=match or pe^.match
                                else match:=match and pe^.match;
                  pe^.match:=false;
                  pe:=pe^.next;
                end;
                if match then begin
                  if pb^.leave then begin
                    score:=pb^.score;
                    inc(pb^.matches);
                    goto s_break;
                  end
                  else pb^.match:=match;
                end;
                pb:=pb^.next;
              end;
            end;
          end;
          ph1:=ph1^.next;
        end;
        pt:=pt^.next;
      end;
      pb:=pf^.block;
      while pb<>nil do begin
        if pb^.match then begin
          inc(score,pb^.score);
          inc(pb^.matches);
          pb^.match:=false;
        end;
        pb:=pb^.next;
      end;
      pf:=pf^.next;
    end;

    s_break:

    done_hdr(header);

    pa:=actliste;
    axflags:=0;
    while pa<>nil do begin
      if (pa^.fromscore<=score) and (score<=pa^.toscore) then begin
        if pa^.action=tskip then scaction:=tscskip
        else if pa^.action=thdronly then scaction:=tschdronly
        else if pa^.action=tfhold then axflags:=axflags or 1
        else if pa^.action=tfdel then axflags:=axflags or 2
        else if pa^.action=tfread then axflags:=axflags or 4
        else if pa^.action=tfemph then axflags:=axflags or 8;
      end;
      pa:=pa^.next;
    end;

    freemem(p_htxt,smax+1);
    freemem(p_hdef,smax+1);
    freemem(p_s1,smax+1);
    freemem(p_s,smax+1);

    score_message:=score;
  end;


procedure prepare_header (dest, source: tstringlist);
  var i:integer;
      s:string;
  begin
    i:=0;
    while i<source.count do begin
      if i=0 then dest.add(source[i])
      else if (length(source[i])>0) and (source[i][1] in [#9,#32]) then begin
        s:=source[i];
        while (length(s)>0) and (s[1] in [#9,#32]) do delete(s,1,1);
        dest[dest.count-1]:=dest[dest.count-1]+' '+s;
      end
      else dest.add(source[i]);
      inc(i);
    end;
  end;


end.


{
  $Log: scoring.PAS,v $
  Revision 1.1  2001/07/11 19:47:18  rb
  checkin


}
