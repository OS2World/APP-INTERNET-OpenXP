{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ (c) 2000 XP2 Team                                               }
{     fuer weitere Informationen siehe http://www.xp2.de          }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: winxpos2.inc,v 1.6 2001/07/11 17:45:08 tj Exp $ }

(***********************************************************)
(*                                                         *)
(*                  UNIT-PART WINXP2                       *)
(*                                                         *)
(*            Window-Verwaltung & Datei-Auswahl            *)
(*                                                         *)
(***********************************************************)

{$I XPDEFINE.INC}
{$F+}

unit winxp;

{  ==========================  Interface-Teil  ==========================  }

INTERFACE

uses  crt,dos,keys,inout,maus2,typeform,xpglobal,os2base,vpsyslow;

const maxpull    = 30;
      maxpush    = 20;

      crline     : byte = 25;      { zeile fÅr Alt-F10-Copyright }
      shadowcol  : byte = 8;
      sc_mem_al  = 8191;           { TWJ 110701 - wieviel Speicher fuer den Screen allokieren }

type
      selproc    = procedure(var sel:slcttyp);
      twj_screen = array[1..$1fff] of byte;

var   wpstack    : array[1..maxpush] of word;
      wpp        : byte;
      warrows    : boolean;     { Pfeile bei wslct anzeigen }
      warrcol    : byte;        { Farbe fÅr Pfeile          }
      selp       : selproc;
      OS2ScrPtr  : Pointer;
      OS2ScrLen  : SmallWord;
      CopyScr    : ^twj_screen;

procedure normwin;
procedure clwin(l,r,o,u:word);

procedure rahmen1(li,re,ob,un:byte; txt:string);    { Rahmen ≥ zeichen       }
procedure rahmen2(li,re,ob,un:byte; txt:string);    { Rahmen ∫ zeichnen      }
procedure rahmen3(li,re,ob,un:byte; txt:string);    { Special-Rahmen         }
procedure rahmen1d(li,re,ob,m,un:byte; txt:string); { Doppelrahmen ≥ zeichen }
procedure rahmen2d(li,re,ob,m,un:byte; txt:string); { Doppelrahmen ∫ zeichnen}
procedure explode(l,r,o,u,typ,attr1,attr2:byte; msec:word; txt:string);
procedure wshadow(li,re,ob,un:word);                { 8-Schatten }

procedure setrahmen(n:shortint);                 { Rahmenart fÅr wpull setzen }
function  getrahmen:shortint;
procedure sort_list(pa:pointer; anz:integer);    { Liste nach 'el' sortieren }
procedure wpull(x1,x2,y1,y2:byte; text:string; var handle:word);
procedure wrest(handle:word);
procedure wslct(anz:integer; ta:pntslcta; handle,pos:word; abs1:boolean;
                var n:word; var brk:boolean);
procedure seldummy(var sel:slcttyp);
procedure wpush(x1,x2,y1,y2:byte; text:string);
procedure wpushs(x1,x2,y1,y2:byte; text:string);
procedure wpop;

procedure fwrt  (const x,y:word; const s:string);
procedure w_copyrght;

{ nachtraeglich eingebaut }

procedure wrt(const x,y : word; const txt:string);
procedure wrt2(const s:string);
procedure SDisp(const x,y:word; const s:string);
procedure ConsoleWrite(x,y:word; numn:dword);
procedure FillScreenLine(const x,y: Integer; const Chr: Char; const Count: Integer);
procedure ReadScreenRect(const l, r, o , u: integer; var Buffer);
procedure WriteScreenRect(const l, r, o, u: Integer; var Buffer);
procedure GetScreenChar(const x, y: Integer; var c: Char; var Attr: SmallWord);

{ ========================= Implementation-Teil =========================  }

IMPLEMENTATION

uses xp0;

const rchar : array[1..3,1..6] of char =
              ('⁄ƒø≥¿Ÿ','…Õª∫»º','’Õ∏≥‘æ');

      shad  : byte = 0;  { Zusatz-Fensterbreite/hîhe }

type memarr     = array[0..$1fff] of byte;

var pullw   : array[1..maxpull] of record
                                     l,r,o,u,wi : byte;
                                     ashad      : byte;
                                     savemem    : ^memarr;
                                     free       : boolean;
                                   end;
    rahmen  : shortint;

procedure qrahmen(l,r,o,u:word; typ,attr:byte; clr:boolean);
var
  i         : integer;
  SaveAttr  : Byte;
  outputstr : string;

begin
  outputstr:='';
  SaveAttr := TextAttr;
  TextAttr := Attr;
  outputstr:= rchar[typ,1] + Dup(r-l-1, rchar[typ, 2]) + rchar[typ,3];
  Fwrt(l, o, outputstr);
  outputstr:= rchar[typ,5] + Dup(r-l-1, rchar[typ, 2]) + rchar[typ,6];
  Fwrt(l, u, outputstr);

  { Wird benutzt, wenn Fenster im Rahmen gefÅllt werden soll }
  for i := o+1 to u -1 do
  begin
    outputstr:= rchar[typ, 4];
    FWrt(l, i, outputstr);
    outputstr:= rchar[typ, 4];
    FWrt(r, i, outputstr);
    if clr then
      FillScreenLine(l+1, i-1, ' ', r-l-2);
  end;
  TextAttr := SaveAttr;
end; {qrahmen}

procedure wshadow(li,re,ob,un:word);
var
  i      : Integer;
  c      : Char;
  Attr   : SmallWord;
  save   : byte;

begin
  moff;
  save := textattr;
  textattr := shadowcol;
  for i := ob to un do
  begin
    GetScreenChar(re, i, c, Attr);
    fwrt(re, i, c);
  end;
  for i := li to re do
  begin
    GetScreenChar(i, un, c, Attr);
    fwrt(i, un, c);
  end;
  textattr := save;
  mon;
end; {wshadow}

procedure clwin(l,r,o,u:word);
var
        i : integer;
begin
        For i:= o to u do
         FillScreenLine(l,i,' ',r-l+1);
end; {clwin}

procedure fwrt(const x,y:word; const s:string);
var
        str   : array[1..255] of char;
        i     : integer;
        pos1,
        pos2  : smallword;
begin
  VioGetCurPos(pos1,pos2,0);
  for i:=1 to length(s) do
   str[i]:=s[i];
  VioWrtCharStr(@str,length(s),y-1,x-1,0);
  VioWrtNAttr(textattr,length(s),y-1,x-1,0);
  VioSetCurPos(pos1,pos2,0);
end; {fwrt}

{ attr1 = Rahmen/Background; attr2 = Kopf }

procedure explode(l,r,o,u,typ,attr1,attr2:byte; msec:word; txt:string);
var la           : byte;
    ls,rs,os,us,
    i,nx,ny,del  : byte;
begin
  if odd(r-l) then begin
    ls:=(r+l)div 2-1; rs:=ls+3; nx:=(r-l-3)div 2;
    end
  else begin
    ls:=(r+l)div 2-1; rs:=ls+2; nx:=(r-l-2)div 2;
    end;
  if odd(u-o) then begin
    os:=(u+o)div 2-1; us:=os+3; ny:=(u-o-3)div 2;
    end
  else begin
    os:=(u+o)div 2-1; us:=os+2; ny:=(u-o-2)div 2;
    end;
  del:=msec div max(nx,ny);
  if nx>ny then
    for i:=0 to nx do begin
      moff;
      qrahmen(ls-i,rs+i,os-i*ny div nx,us+i*ny div nx,typ,attr1,true);
      mon;
   delay(del);
      end
  else
    for i:=0 to ny do begin
      moff;
      qrahmen(ls-i*nx div ny,rs+i*nx div ny,os-i,us+i,typ,attr1,true);
      mon;
   delay(del);
      end;
  if txt<>'' then begin
    moff;
    la:=lastattr;
    attrtxt(attr1);
    wrt((r+l+1)div 2-length(txt)div 2-2,o,' ');
    attrtxt(attr2); write(' ',txt,' ');
    attrtxt(attr1); write(' ');
    attrtxt(la);
    mon;
    end;
end;


procedure wrt(const x,y: word; const txt:string);
var
        str : array[1..255] of char;
        i   : integer;
begin
  for i:=1 to length(txt) do
   str[i]:=txt[i];
  VioWrtNAttr(lastattr,length(txt),y-1,x-1,0);
  VioWrtCharStr(@str,length(txt),y-1,x-1,0);
  gotoxy(x+length(txt),y);
end;


procedure normwin;
begin
  window(1,1,80,25);
end;


procedure rahmen1(li,re,ob,un:byte; txt:string);
var i : byte;
begin
  normtxt;
  moff;
  qrahmen(li,re,ob,un,1,iif(forcecolor,lastattr,normattr),false);
  if txt<>'' then
  begin
    wrt((re+li+1)div 2 - length(txt) div 2 - 2,ob,' ');
    invtxt; write(' ',txt,' '); normtxt; write(' ');
  end;
  mon;
end;


procedure rahmen2(li,re,ob,un:byte; txt:string);
var i : byte;
begin
  normtxt;
  moff;
  qrahmen(li,re,ob,un,2,iif(forcecolor,lastattr,normattr),false);
  if txt<>'' then begin
    wrt((re+li+1)div 2-length(txt)div 2-2,ob,' ');
    invtxt; write(' ',txt,' '); normtxt; write(' ');
    end;
  mon;
end;


procedure rahmen3(li,re,ob,un:byte; txt:string);
var i : byte;
begin
  normtxt;
  moff;
  qrahmen(li,re,ob,un,3,iif(forcecolor,lastattr,normattr),false);
  if txt<>'' then begin
    wrt((re+li+1)div 2-length(txt)div 2-2,ob,' ');
    invtxt; write(' ',txt,' '); normtxt; write(' ');
    end;
  mon;
end;


Procedure rahmen1d(li,re,ob,m,un:byte; txt:string);
begin
  rahmen1(li,re,ob,un,txt);
  mwrt(li,m,hbar(re-li+1));
end;


Procedure rahmen2d(li,re,ob,m,un:byte; txt:string);
begin
  rahmen2(li,re,ob,un,txt);
  mwrt(li,m,'Ã'+dup(re-li-1,'Õ')+'π');
end;


procedure setrahmen(n:shortint);
begin
  rahmen:=n;
end;

function getrahmen:shortint;
begin
  getrahmen:=rahmen;
end;


Procedure wpull(x1,x2,y1,y2:byte; text:string; var handle:word);
var     i        : byte;
        j        : integer;

begin
  if (x2-x1<1) or (y2-y1<1) then begin
    writeln('WPULL error');
    halt(1);
    end;
  savecursor;
  cursor(curoff);
  normwin;
  i:=1;
  while not pullw[i].free do
    inc(i);
  handle:=i;
  with pullw[i] do begin
    free:=false;
    l:=x1; r:=x2; o:=y1; u:=y2;
    ashad:=shad;
    wi:=(r-l+1+shad)*2;
    getmem(savemem,sc_mem_al);
    moff;
    ReadScreenRect(l, r+ashad, o, u+ashad, SaveMem^);
    mon;
    if rahmen=1 then rahmen1(l,r,o,u,text);
    if rahmen=2 then rahmen2(l,r,o,u,text);
    if rahmen>0 then clwin(l+1,r-1,o+1,u-1);
    if rahmen<0 then explode(l,r,o,u,abs(rahmen),normattr,invattr,100,text);
    end;
  restcursor;
end;


Procedure wrest(handle:word);
var i      : byte;
    twj_ok : boolean;
begin
  normwin;
  with pullw[handle] do begin
    moff;
    WriteScreenRect(l, r+ashad, o, u+ashad, SaveMem^);
    mon;
    freemem(savemem,wi*(u-o+ashad+1));
    free:=true;
    end;
end;


procedure sort_list(pa:pointer; anz:integer);    { Liste nach 'el' sortieren }
var i,j : word;
    xch : boolean;
    sa  : slcttyp;
    l   : pntslcta;
begin
  l:=pntslcta(pa);
  j:=anz-1;
  repeat
    xch:=false;
    for i:=1 to j do
      if UStr(l^[i].el)>UStr(l^[i+1].el) then begin
        sa:=l^[i];
        l^[i]:=l^[i+1];
        l^[i+1]:=sa;
        xch:=true;
        end;
  until not xch;
end;


Procedure wslct(anz:integer; ta:pntslcta; handle,pos:word; abs1:boolean;
                var n:word; var brk:boolean);

var z          : taste;
    i,po,pon   : integer;
    wsize      : word;
    pa,pan     : integer;
    ende       : boolean;
    ox         : integer;

Procedure dispage;
var i:integer;
begin
  moff;
  with pullw[handle] do begin
    for i:=1 to wsize do
      if i+pa<=anz then
        with ta^[i+pa] do begin
          if zu then normtxt else hightxt;
          wrt(l+2,ox+i,el);
          normtxt;
          end
      else
        wrt(l+2,ox+i,sp(r-l-3));
    if warrows then begin
      attrtxt(warrcol);
      wrt(l,o+1,iifc(pa>0,#30,#179));
      wrt(l,u-1,iifc(pa+wsize<anz,#31,#179));
      normtxt;
      end;
    end;
  mon;
end;

Procedure godown;
begin
  if (pan+pon<anz) then begin
    inc(pon);
    if pon>wsize then begin
      dec(pon); inc(pan);
      end;
    end;
end;

Procedure goup;
begin
  if pon+pan>1 then begin
    dec(pon);
    if pon=0 then begin
      dec(pan); pon:=1;
      end;
    end;
end;


begin    { of wslct }
  if anz=0 then begin
    brk:=true;
    exit;
    end;
  pos:=min(pos,anz);
  savecursor;
  cursor(curoff);
  normwin;
  ende:=false;
  with pullw[handle] do begin
    for i:=1 to anz do
      ta^[i].el:=forms(ta^[i].el,r-l-3);
    ox:=iif(abs1,o+1,o);
    wsize:=u-ox-1;
    if pos<=anz then begin
      pa:=0; po:=pos;
      end
    else begin
      pa:=pos-1; po:=1;
      end;
    if po>wsize then begin
      inc(pa,po-wsize);
      po:=wsize;
      end;
    dispage;
    mausiniti;
    repeat
      mauszuo:=(pa+po>1);
      mauszuu:=(pa+po<anz);
      invtxt;
      mwrt(l+2,ox+po,ta^[pa+po].el);
      selp(ta^[pa+po]);
      get(z,curoff);
      pan:=pa; pon:=po;
      if (z=keydown) or (z=keytab) or (z[1]='2') then
        godown
      else if (z=keyup) or (z=keystab) or (z[1]='8') then
        goup
      else if z=keyesc then begin
        brk:=true;
        ende:=true;
        end
      else if (z=keyhome) or (z[1]='7') then begin
        pon:=1;
        if not ta^[pan+pon].zu then godown;
        end
      else if (z=keyend) or (z[1]='1') then begin
        pon:=min(wsize,anz-pan);
        if not ta^[pan+pon].zu then goup;
        end
      else if (z=keypgup) or (z[1]='9') then begin
        if pan=0 then pon:=1
        else pan:=max(0,pan-wsize);
        end
      else if (z=keypgdn) or (z[1]='3') then begin
        if pan+wsize>=anz then pon:=anz-pan
        else pan:=min(anz-pon,pan+wsize);
        end
      else if (z=keycpgu) or (z=keychom) then begin
        pan:=0; pon:=1;
        end
      else if (z=keycpgd) or (z=keycend) then begin
        pan:=max(0,anz-wsize);
        pon:=anz-pan;
        end
      else if z=keycr then begin
        brk:=false;
        ende:=true;
        end;
      if pa<>pan then begin
        pa:=pan;
        po:=pon;
        dispage;
        end
      else begin
        normtxt;
        wrt(l+2,ox+po,ta^[pa+po].el);
        po:=pon;
        end;
    until ende;
    n:=po+pa;
    end;
  restcursor;
end;


procedure seldummy(var sel:slcttyp);
begin
end;


procedure w_copyrght;
var z        : taste;
    sd,st    : boolean;
    buf      : array[0..159] of byte;
    localbuf : twj_screen;

begin
  moff;
  VioGetBuf(OS2ScrPtr,OS2ScrLen,0);
  SelToFlat(OS2ScrPtr);
  move(OS2ScrPtr^,LocalBuf,OS2ScrLen);
  move(LocalBuf[(crline-1)*160],buf,160);
  mon;
  disphard(1,crline,dup(16,'∞')+' (c) by '+pm+' ∞∞∞∞∞∞ Tel. 02632/48651 '+
           dup(16,'∞'));
  sd:=m2d; st:=m2t;
  if datey=25 then m2d:=false;
  if timey=25 then m2t:=false;
  get(z,curoff);
  m2d:=sd; m2t:=st;
  Disp_DT;
  moff;
  move(buf,LocalBuf[(crline-1)*160],160);
  move(Localbuf,OS2ScrPtr^,OS2ScrLen);
  VioShowBuf(0,OS2ScrLen,0);
  mon;
end;

procedure wpush(x1,x2,y1,y2:byte; text:string);
var r   : byte;
    tx1 : char;
begin
  if wpp=maxpush then writeln('WPUSH error')
  else begin
    r:=rahmen;
    if (text='*') or (text='-') then begin
      setrahmen(0); text:='';
      tx1:=text[1];
      end
    else
      tx1:=' ';
    inc(wpp);
    wpull(x1,x2,y1,y2,text,wpstack[wpp]);
    if tx1='*' then clwin(x1,x2,y1,y2);
    setrahmen(r);
    end;
end;


procedure wpushs(x1,x2,y1,y2:byte; text:string);
begin
  shad:=1;
  wpush(x1,x2,y1,y2,text);
{  rahmen1(x1,x2,y1,y2,text);}
{  clwin(x1+1,x2-1,y1+1,y2-1); }
  wshadow(x1+1,x2+1,y1+1,y2+1);
  shad:=0;
end;

procedure wpop;
begin
  if wpp=0 then
{$IFDEF Debug }
  writeln('WPOP error')
{$ENDIF }
  else begin
    wrest(wpstack[wpp]);
    dec(wpp);
    Disp_DT;
    end;
end;

procedure wrt2(const s:string);
var
        str    : array[1..255] of char;
        i      : integer;
        pos1,
        pos2  : smallword;
begin
        VioGetCurPos(pos1,pos2,0);
        for i:=1 to length(s) do
         str[i]:=s[i];
        VioWrtCharStr(@str,length(s),pos1,pos2,0);
        VioSetCurPos(pos1,pos2,0);
end; {wrt2}

procedure SDisp(const x,y:word; const s:string);
var
        str : array[1..255] of char;
        i   : integer;
begin
        for i:=1 to length(s) do
         str[i]:=s[i];
        VioWrtCharStr(@str,length(s),y-1,x-1,0);
end; {SDisp}

procedure ConsoleWrite(x,y:word; numn:dword);
var
        str      : array[1..82] of char;
        i        : integer;
        twj_attr : byte;
begin
        for i:=1 to length(charbuf) do
         str[i]:=charbuf[i];
        twj_attr:=attrbuf[2];
        VioWrtNAttr(twj_attr,length(charbuf),y-1,x-1,0);
        VioWrtCharStr(@str,length(charbuf),y-1,x-1,0);
end; {ConsoleWrite}

procedure FillScreenLine(const x,y: Integer; const Chr: Char; const Count: Integer);
var
        twj_str : array[1..80] of char;
        i       : integer;
begin
        for i:=1 to count do twj_str[i]:=chr;
        VioWrtNAttr(textattr,count,y-1,x-1,0);
        VioWrtCharStr(@twj_str,count,y-1,x-1,0);
end; {FillScreenLine}

procedure ReadScreenRect(const l, r, o , u: integer; var Buffer);
{ TJ 100500 - speichert den ganzen Screen, da die Funktion momentan nur }
{             fuer den ganzen Screen benutzt wird, wenn Screenbereiche  }
{             gespeichert werden sollen, so ist wpush, wrest da         }
begin
{$R-}
    VioGetBuf(OS2ScrPtr,OS2ScrLen,0);
    SelToFlat(OS2ScrPtr);
    move(OS2ScrPtr^,Buffer,OS2ScrLen);
{$R+}
end; {ReadScreenRect}

procedure WriteScreenRect(const l, r, o, u: Integer; var Buffer);
begin
{$R-}
    move(Buffer,OS2ScrPtr^,OS2ScrLen);
    VioShowBuf(0,OS2ScrLen,0);
{$R+}
end; {WriteScreenRect}

procedure GetScreenChar(const x, y: Integer; var c: Char; var Attr: SmallWord);
begin
      c := SysReadCharAt(x-1, y-1);
      Attr := SmallWord(SysReadAttributesAt(x-1, y-1));
end; {GetScreenChar}


{ *** Unit-Init-Teil *** }

var i : byte;

begin
  for i:=1 to maxpull do
    pullw[i].free:=true;
  rahmen:=1;
  fnproc[3,10]:=w_copyrght;
  wpp:=0;
  warrows:=false;
  warrcol:=7;
  selp:=seldummy;
  getmem(CopyScr,sizeof(CopyScr^));

{
  $Log: winxpos2.inc,v $
  Revision 1.6  2001/07/11 17:45:08  tj
  - Allokierfehler behoben

  Revision 1.5  2000/06/01 23:48:28  tj
  behebt ein paar Darstellungsfehler unter OS/2

  Revision 1.4  2000/05/25 23:12:50  rb
  Loginfos hinzugefÅgt

}
