{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams.  }
{ Aenderungen des Sources, die vom OpenXP Team getaetigt wurden,  }
{ unterliegen den Rechten, die bis zum 09.04.2000 fuer das OpenXP }
{ Team gueltig waren.                                             }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: help.pas,v 1.6 2001/12/30 11:50:56 mm Exp $ }

(***********************************************************)
(*                                                         *)
(*                        UNIT help                        *)
(*                                                         *)
(*                    Interface f�r IHS                    *)
(*                                                         *)
(***********************************************************)

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }



UNIT help;

{  ==================  Interface-Teil  ===================  }

INTERFACE

uses xpglobal, crt,dos,typeform,keys,fileio,inout,winxp,mouse,maus2,printerx;

const maxpages = 1200;
      maxqvw   = 200;
      maxlines = 250;   { max. Zeilen pro Hilfsseite }

      HBlocksatz     = true;
      HKeinBlocksatz = false;
      HInvers        = true;
      HNichtInvers   = false;
      HHeadHigh      = true;
      HHeadNotHigh   = false;

procedure sethelpcol(col,colhi,colqvw,colselqvw:byte);
function  inithelp(name:pathstr; xh,yh:byte;
                   invers,blocksatz,headline:boolean):boolean;
procedure sethelppos(_x,_y,height:byte);
procedure help_printable(printchar:taste; pinit,pexit:string);

procedure IHS(page:word);
procedure releasehelp;


{ ================= Implementation-Teil ==================  }

IMPLEMENTATION

type  stringp = ^string;

const maxpst  = 20;
      init    : boolean = false;
      loaded  : boolean = false;
      colinit : boolean = false;
      _a      : integer = 0;

      printch : taste   = '';
      _pinit  : stringp = nil;
      _pexit  : stringp = nil;


type pageadr = array[1..maxpages] of packed record
                                       nr  : smallword;
                                       adr : longint;
                                     end;
     qvt     = array[1..maxqvw] of packed record
                                     y,x,l : byte;
                                     xout  : byte;  { Anzeige-Position }
                                     nn    : smallword;
                                   end;
     zt      = array[1..maxlines] of stringp;

var f         : file;
    x,y       : byte;
    pages,
    ixp,ap,
    illp      : word;
    noheader  : boolean;
    tabmode   : boolean;

    pa        : ^pageadr;
    blocksatz,
    dodecode,
    headhigh  : boolean;

    last,next : word;
    qvws      : byte;
    qvw       : ^qvt;
    lines     : byte;
    _lines    : byte;   { iif(noheader,lines,lines-1) }
    z         : ^zt;
    zlen      : array[1..maxlines] of byte;
    wdt,hgh   : byte;

    pst       : array[1..maxpst] of word;
    qst       : array[1..maxpst] of byte;
    ast       : array[1..maxpst] of integer;
    pstp      : byte;

    NormColor,HighColor,QvwColor,QvwSelColor : byte;


procedure sethelpcol(col,colhi,colqvw,colselqvw:byte);
begin
  NormColor:=col;
  HighColor:=colhi;
  QvwColor:=colqvw;
  QvwSelColor:=colselqvw;
  colinit:=true;
end;


procedure testio;
begin
  if ioresult<>0 then begin
    attrtxt(7);
    writeln;
    writeln('<HELP> Fehler: Hilfsdatei '+ustr(filename(f))+' ist besch�digt.');
    halt(1);
    end;
end;


function blockrb:byte;
var b : byte;
begin
  blockread(f,b,1);
  testio;
  blockrb:=b;
end;


function blockrw:smallword;
var w : smallword;
begin
  blockread(f,w,2);
  testio;
  blockrw:=w;
end;


function blockrl:longint;
var l : longint;
begin
  blockread(f,l,4);
  testio;
  blockrl:=l;
end;


function inithelp(name:pathstr; xh,yh:byte;
                  invers,blocksatz,headline:boolean):boolean;

var ixadr : longint;
    fm      : byte;

begin
  if pos('.',getfilename(name))=0 then name:=name+'.HLP';
  assign(f,name);
  fm:=filemode; filemode:=0;
  reset(f,1);
  if ioresult<>0 then begin
    filemode:=fm;
    inithelp:=false;
    end
  else begin
    filemode:=fm;
    seek(f,130);
    wdt:=blockrb;
    hgh:=blockrb; dec(hgh,3);
    pages:=blockrw;
    ixp:=blockrw;
    illp:=blockrw;
    ixadr:=blockrl;
    noheader:=boolean(blockrb);
    tabmode:=boolean(blockrb);
    dodecode:=not boolean(blockrb);

    getmem(pa,6*pages);
    seek(f,ixadr);
    blockread(f,pa^,6*pages);
    testio;

    x:=xh; y:=yh;
    help.blocksatz:=blocksatz;
    headhigh:=headline;
    ap:=0;
    pstp:=0;
    inithelp:=true; init:=true;

    if not colinit then begin
      if invers then NormColor:=InvAttr
      else NormColor:=Normattr;
      HighColor:=iif(color,15,iif(textattr < $70,1,NormColor and 15))
                 +NormColor and $70;
      QvwColor:=iif(invers,iif(color,invattr and $70 + iif(cga,red,yellow),
                                     normattr),highattr);
      QvwSelColor:=iif(invers,iif(color,$10+yellow,9),invattr);
      end;
    end;
end;


procedure releasehelp;
begin
  if init then begin
    close(f);
    init:=false;
    freemem(pa,6*pages);
    end;
end;


procedure sethelppos(_x,_y,height:byte);
begin
  x:=_x; y:=_y; hgh:=height;
end;

{ MK 06.01.2000 Von Inline in ASM 16 und 32 Bit konvertiert }
procedure decode(buf:pointer; size:word); assembler; {&uses ebx}
{$IFDEF Ver32 }
asm
        mov ecx, size
        mov ebx, buf
        mov al, 7
@lp:    xor [ebx], al
        add al, 125
        inc ebx
        loop @lp;
{$IFDEF FPC }
end ['EAX', 'EBX', 'ECX'];
{$ELSE }
end;
{$ENDIF }
{$ELSE }
asm
        mov cx, size
        les bx, buf
        mov al, 7
@lp:    xor es:[bx], al
        add al, 125
        inc bx
        loop @lp;
end;
{$ENDIF }

procedure loadpage(nr:word; pstentry:boolean);
type buft    = array[1..30000] of byte;
var  size    : word;
     buf     : ^buft;
     i,sl,ps : byte;
     p,p1    : word;
     s       : string;
     l,r,m   : word;
     lc      : char;
     res     : integer;
     wd      : byte;
label laden;

   procedure insqvw(y1,x1:byte; add:shortint);
   var i : byte;
   begin
     for i:=1 to qvws do
       with qvw^[i] do
         if (x>=x1) and (y=y1) then inc(x,add);
   end;

   procedure addqvwout(y1,x1:byte; add:shortint);
   var i : byte;
   begin
     for i:=1 to qvws do
       with qvw^[i] do
         if (x>=x1) and (y=y1) then inc(xout,add);
   end;

begin
  if ap<>nr then begin
    if loaded then
      for i:=1 to lines do
        freemem(z^[i],zlen[i]);
    ap:=nr;
    if pstentry then begin
      inc(pstp);
      if pstp>maxpst then begin
        FastMove(pst[2],pst[1],maxpst*sizeof(pst[1]));
        dec(pstp);
        end;
      pst[pstp]:=nr;
      qst[pstp]:=1;
      ast[pstp]:=0;
      end;
    _a:=ast[pstp];
    end;
laden:
  repeat
    l:=1; r:=pages;
    while (pa^[l].nr<>nr) and (r-l>1) do begin
      m:=(r+l)div 2;
      if pa^[m].nr>nr then r:=m
      else l:=m;
      end;
    p:=iif(pa^[l].nr=nr,l,r);
    if pa^[p].nr<>nr then nr:=illp;
  until pa^[p].nr=nr;
  seek(f,pa^[p].adr+2);
  last:=blockrw; next:=blockrw;
  size:=blockrw;
  qvws:=blockrb;
  for i:=1 to qvws do
    with qvw^[i] do begin
      y:=blockrb; x:=blockrb; l:=blockrb;
      nn:=blockrw;
      xout:=x;
      end;
  lines:=1; fillchar(z^,sizeof(z^),0);
  if memavail<2*size then exit;
  getmem(buf,size);
  blockread(f,buf^,size);
  testio;
  if dodecode then decode(buf,size);
  p:=1; sl:=0;
  while p<=size do begin
    if buf^[p]>=32 then begin
      p1:=p;
      while buf^[p]>=32 do inc(p);
      FastMove(buf^[p1],s[sl+1],p-p1);
      inc(sl,p-p1);
      end;
    if buf^[p]=7 then begin
      s[0]:=chr(sl);
      zlen[lines]:=length(s)+1;
      getmem(z^[lines],zlen[lines]);
      z^[lines]^:=s;
      inc(lines);
      sl:=0;
      end
    else
      if buf^[p]=$1a then begin
        inc(p);
        s[0]:=chr(sl);
        s:=s+sp(buf^[p]);
        inc(sl,buf^[p]);
        end
      else begin
        inc(sl);
        s[sl]:=char(buf^[p]);
        end;
    inc(p);
    end;
  dec(lines);
  _lines:=iif(noheader,lines,lines-1);
  if copy(z^[1]^,1,2)='^^' then begin
    val(mid(z^[1]^,3),nr,res);
    if pstentry then pst[pstp]:=nr;
    goto laden;
    end;
  for i:=iif(NoHeader,1,2) to lines do begin
    s:=z^[i]^;
    randseed:=100;
    wd:=wdt;
    p:=pos('<<',s);
    while p>0 do begin
      inc(wd,4);
      addqvwout(i,p,-4);
      p1:=pos('<<',copy(s,p+2,80));
      if p1>0 then p:=p+p1+1 else p:=0;
      end;
    if blocksatz and (length(s)>wd div 3) then begin
      if pos('@',s)>0 then lc:=s[pos('@',s)-1]
      else lc:=s[length(s)];
      if pos('#',s)>0 then lc:='#';
      if pos(lc,'#.?!:')=0 then begin
        while length(s)<wd do begin
          ps:=random(length(s)-2)+1;
          while (ps<=length(s)) and (s[ps]<>' ') do inc(ps);
          if ps<=length(s) then insert(' ',s,ps);
          insqvw(i,ps,1);
          end;
        end;
      end;
    ps:=pos('#',s);
    if ps>0 then begin
      if s[ps-1]='\' then dec(ps);   { ord(\) = 92 > length(s) }
      delete(s,ps,1);
      insqvw(i,ps,-1);
      end;
    z^[i]^:=s;
    end;
  freemem(buf,size);
  loaded:=true;
end;


procedure dispqvw(n:byte);
begin
  with qvw^[n] do
    mwrt(xout+help.x-1,help.y+y-_a+iif(NoHeader,-1,1),copy(z^[y]^,x,l));
end;


procedure disppage(qvp:byte);
var i,p,p2 : integer;
    pgp    : string[11];
    s      : string;
    add    : integer;
    yy     : byte;
begin
  moff;
  attrtxt(NormColor);
  if tabmode then begin
    if (last=0) and (_a=0) then
      wrt(x-3,y-1,'�'+dup(wdt+3,'�')+'�')
    else
      wrt(x-3,y-1,'�'+dup(wdt+3,'�')+'�');
    if (next=0) and (_a+hgh>=_lines) then
      wrt(x-3,y+hgh+iif(noheader,0,3),'�'+dup(wdt+3,'�')+'�')
    else
      wrt(x-3,y+hgh+iif(noheader,0,3),'�'+dup(wdt+3,'�')+'�');
    end
  else begin
    if (last=0) and (_a=0) then
      if (next=0) and (_a+hgh>=_lines) then pgp:=dup(11,'�')
      else pgp:='����� PgDn '
    else
      if (next=0) and (_a+hgh>=_lines) then pgp:=' PgUp �����'
      else pgp:=' PgUp/PgDn ';
    wrt(x+wdt-10,y+hgh+iif(NoHeader,0,3),pgp);
    end;
  if not NoHeader then begin
    wrt(x,y,'Hilfe: ');
    if headhigh and color then textcolor(15);
    write(left(z^[1]^,wdt-7));
    attrtxt(NormColor);
    if length(z^[1]^)<wdt-7 then write(sp(wdt-7-length(z^[1]^)));
    wrt(x,y+1,dup(wdt,'�'));
    end;
  for i:=1 to hgh do begin
    if NoHeader then add:=_a else add:=1;
    if z^[i+add]=nil then s:=''
    else s:=z^[i+add]^;
    p:=pos('<<',s);
    yy:=y+i+iif(NoHeader,-1,2);
    if p=0 then begin
      fillchar(s[length(s)+1],80,32);
      s[0]:=chr(wdt);
      fwrt(x,yy,s);
  end
    else begin
      gotoxy(x,yy);
      while p>0 do begin
        write(left(s,p-1));
        p2:=pos('>>',s); if p2=0 then p2:=length(s)+1;
        attrtxt(HighColor);
        write(copy(s,p+2,p2-p-2));
        attrtxt(NormColor);
        s:=copy(s,p2+2,80);
        p:=pos('<<',s);
        end;
      write(forms(s,x+wdt-wherex));
      end;
    end;
  mon;
  attrtxt(QvwColor);
  for i:=1 to qvws do
    if (i<>qvp) and (qvw^[i].y>_a) and (qvw^[i].y<=_a+hgh) then
      dispqvw(i);
  normtxt;
end;


procedure IHS(page:word);
var lp      : word;
    la,i    : integer;
    t       : taste;
    uc      : char;
    qvp,lqv : integer;
    qvj     : string;
    ml,mo,
    mu,mr   : boolean;

  procedure goleft;
  begin
    dec(qvp);
    if qvp<1 then qvp:=qvws;
  end;

  procedure goright;
  begin
    inc(qvp);
    if qvp>qvws then qvp:=1;
  end;

  function noother:boolean;
  var other : boolean;
      i     : byte;
  begin
    other:=false;
    for i:=1 to qvws do
      if qvw^[i].y<>qvw^[qvp].y then other:=true;
    noother:=not other;
  end;

  procedure searchsame(add:shortint; var nr:byte);
  begin
    nr:=qvp;
    repeat
      inc(nr,add);
      if nr<1 then nr:=qvws;
      if nr>qvws then nr:=1;
    until ((qvw^[nr].y<>qvw^[qvp].y) and (qvw^[nr].x=qvw^[qvp].x)) or (nr=qvp);
    if nr=qvp then nr:=0;
  end;

  procedure searchother(add:shortint; var nr:byte);
  begin
    nr:=qvp;
    repeat
      inc(nr,add);
      if nr<1 then nr:=qvws;
      if nr>qvws then nr:=1;
    until qvw^[nr].y<>qvw^[qvp].y;
  end;

  procedure searchlowdist(var nr:byte);
  var y,i : byte;
      d   : byte;
  begin
    y:=qvw^[nr].y;
    d:=99;
    for i:=1 to qvws do
      if (qvw^[i].y=y) and (abs(qvw^[i].x-qvw^[qvp].x)<d) then begin
        d:=abs(qvw^[i].x-qvw^[qvp].x);
        nr:=i;
        end;
  end;

  procedure goup;
  var nr : byte;
  begin
    if noother then goleft
    else begin
      searchsame(-1,nr);
      if nr=0 then searchother(-1,nr);
      searchlowdist(nr);
      qvp:=nr;
      end;
  end;

  procedure godown;
  var nr : byte;
  begin
    if noother then goright
    else begin
      searchsame(1,nr);
      if nr=0 then searchother(1,nr);
      searchlowdist(nr);
      qvp:=nr;
      end;
  end;

  function qvok:boolean;
  begin
    qvok:=(qvws>0) and (qvw^[qvp].y>_a) and (qvw^[qvp].y<=_a+hgh);
  end;

  procedure maus_bearbeiten;
  var mx,my : integer;
      inside: boolean;
  begin
    maus_gettext(mx,my);
    inside:=(mx>=x-1) and (mx<x+wdt+3) and
            (my>=y-1) and (my<=y+hgh+iif(noheader,0,3));
    if (t=mausunright) or ((t=mausunleft) and not inside) then
      t:=keyesc;
  end;

  procedure printit;
  var i : integer;

    procedure wrp(n:integer);
    var s1,s2 : string[120];
        p1,p2 : byte;
    begin
      s1:=z^[n]^; s2:='';
      while pos('<<',s1)>0 do begin
        p1:=pos('<<',s1);
        delete(s1,p1,2);
        p2:=pos('>>',s1);
        if p2=0 then p2:=length(s1)+1
        else delete(s2,p2,2);
        if p2<=p1 then exit;  { zur Sicherheit ... }
        s2:=forms(s1,p1-1)+copy(s1,p1,p2-p1);
        end;
      if s2='' then writeln(lst,s1)
      else writeln(lst,s1,#13,s2);
    end;

  begin
    checklst:=true;
    if _pinit<>nil then write(lst,_pinit^);
    if noheader then i:=1
    else begin
      wrp(1);
      writeln(lst,dup(wdt,'-'));
      writeln(lst);
      i:=2;
      end;
    while checklst and (i<=lines) do begin
      wrp(i);
      inc(i);
      end;
    if _pexit<>nil then write(lst,_pexit^);
    checklst:=true;
  end;

begin     { of IHS }
  if not init then exit;
  ml:=mauszul; mr:=mauszur; mo:=mauszuo; mu:=mauszuu;
  mauszul:=false; mauszur:=false; mauszuo:=false; mauszuu:=false;
  new(qvw); new(z); lqv := 0; { MK 02/00 Variable initialisieren }
  loaded:=false;
  if page<>0 then loadpage(page,true)
  else
    if pstp=0 then
      if ixp<>0 then loadpage(ixp,true)
      else exit
    else loadpage(pst[pstp],false);
  lp:=0; la:=_a;
  repeat
    ast[pstp]:=_a;
    if (lp<>ap) or (la<>_a) then begin
      if lp<>ap then begin
        qvp:=qst[pstp]; lqv:=qvp;
        end;
      if (qvws>0) and not qvok then begin
        if (la<_a) or (abs(_a-la)>=hgh) then begin
          for i:=qvws downto 1 do
            if (qvw^[i].y>_a) and (qvw^[i].y<=_a+hgh) then qvp:=i;
          end
        else
          for i:=1 to qvws do
            if (qvw^[i].y>_a) and (qvw^[i].y<=_a+hgh) then qvp:=i;
        lqv:=qvp;
        end;
      disppage(qvp);
      lp:=ap; la:=_a;
      qvj:='';
      for i:=1 to qvws do with qvw^[i] do
        qvj:=qvj+z^[y]^[x];
      qvj:=UStr(qvj);
      end;
    if qvok then begin
      attrtxt(QvwSelColor);
      dispqvw(qvp);
      normtxt;
      end;
    qst[pstp]:=qvp;
    get(t,curoff);
    if qvok then begin
      attrtxt(QvwColor);
      dispqvw(qvp);
      normtxt;
      end;
    if (t>=mausfirstkey) and (t<=mauslastkey) then maus_bearbeiten;
    if t=keypgup then
      if _a>0 then _a:=max(0,_a-hgh)
      else
        if last<>0 then begin
          pst[pstp]:=last;
          loadpage(last,false);
          qst[pstp]:=1;
          end;
    if t=keypgdn then
      if _a+hgh<_lines then
        _a:=min(_lines-hgh,_a+hgh)
      else
        if next<>0 then begin
          pst[pstp]:=next;
          loadpage(next,false);
          qst[pstp]:=1;
          end;
    if tabmode then begin
      if (t=keyup) and (_a>0) then dec(_a);
      if (t=keydown) and (_a+hgh<lines) then inc(_a);
      end;
    if (t=keyf1) and (ixp>0) then loadpage(ixp,true);
    if (t=keyaf1) and (pstp>1) then begin
      dec(pstp);
      loadpage(pst[pstp],false);
      qvp:=qst[pstp];
      end;
    if qvws>1 then begin
      if t=keyleft then goleft;
      if t=keyrght then goright;
      if not tabmode then begin
        if t=keyup then goup;
        if t=keydown then godown;
        end
      else begin
        if _lines<=hgh then begin
          if t=keyup then goup;
          if t=keydown then godown;
          end;
        if t=keytab then goright;
        if t=keystab then goleft;
        end;
      uc:=UpCase(t[1]);
      if pos(uc,mid(qvj,qvp+1))>0 then qvp:=pos(uc,mid(qvj,qvp+1))+qvp
      else
        if pos(uc,qvj)>0 then qvp:=pos(uc,qvj);
      end;
    if qvws>0 then begin
      if t=keyhome then qvp:=1;
      if t=keyend then qvp:=qvws;
      if t=keycpgu then _a:=0;
      if (t=keycpgd) and (_lines>hgh) then
        _a:=_lines-hgh;
      end
    else begin
      if t=keyhome then _a:=0;
      if (t=keyend) and (_lines>hgh) then
        _a:=_lines-hgh;
      end;
    if (t=keycr) and qvok then
      loadpage(qvw^[qvp].nn,true);
    if (printch<>'') and ((t=printch) or (ustr(t)=printch)) then
      printit;

    if lqv<>qvp then begin
      while qvw^[qvp].y<=_a do _a:=max(0,_a-hgh);
      while qvw^[qvp].y>_a+hgh do _a:=min(_lines-hgh,_a+hgh);
      lqv:=qvp;
      end;
  until t=keyesc;
  mauszul:=ml; mauszur:=mr; mauszuo:=mo; mauszuu:=mu;
  for i:=1 to lines do
    freemem(z^[i],zlen[i]);
  loaded:=false;
  dispose(z); dispose(qvw);
end;


procedure help_printable(printchar:taste; pinit,pexit:string);
begin
  printch:=printchar;
  if _pinit<>nil then freemem(_pinit,length(_pinit^)+1);
  if _pexit<>nil then freemem(_pexit,length(_pexit^)+1);
  if pinit<>'' then begin
    getmem(_pinit,length(pinit)+1);
    _pinit^:=pinit;
    end;
  if pexit<>'' then begin
    getmem(_pexit,length(pexit)+1);
    _pexit^:=pexit;
    end;
end;

end.
{
  $Log: help.pas,v $
  Revision 1.6  2001/12/30 11:50:56  mm
  - Sourceheader

  Revision 1.5  2000/06/08 20:04:32  MH
  Teamname geandert

  Revision 1.4  2000/04/09 18:08:15  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.9  2000/04/04 21:01:20  mk
  - Bugfixes f�r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.8  2000/03/24 15:41:01  mk
  - FPC Spezifische Liste der benutzten ASM-Register eingeklammert

  Revision 1.7  2000/03/17 11:16:34  mk
  - Benutzte Register in 32 Bit ASM-Routinen angegeben, Bugfixes

  Revision 1.6  2000/03/08 22:36:33  mk
  - Bugfixes f�r die 32 Bit-Version und neue ASM-Routinen

  Revision 1.5  2000/02/19 11:40:07  mk
  Code aufgeraeumt und z.T. portiert

}
