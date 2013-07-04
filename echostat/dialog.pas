{******************************************************************************
                         Dialogunit fÅr ECHOSTAT  V1.41
                        (c) Hilmar Buchta, April 1996
******************************************************************************}

{ $Id: dialog.pas,v 1.2 2001/01/22 19:31:27 MH Exp $ }

unit dialog;
{.$I-,X+,G+}
{$I XPDEFINE.INC}

interface
uses crt;

type tcolors=array[0..16] of byte;

const
 def_color:tcolors=
 ($70,     {  0: normaler Text }
  $70,     {  1: Dialogfeldrahmen }
  $71,     {  2: hervorgehobener Text: $7e=gelb <-> $71=blau }
  $1e,     {  3: Eingabefeld }
  $7f,     {  4: Anfangsbuchstaben }
  $1a,     {  5: Pfeile im Eingabefeld }
  $30,     {  6: Auswahlliste }
  $07,     {  7: Balken in der Auswahlliste }
  $6f,     {  8: Schalter }
  $70,     {  9: Eingabebox: Gesamtfarbe }
  $70,     { 10: Eingabebox: Rahmen }
  $31,     { 11: Eingabebox: Bildlaufleiste }
  $7f,     { 12: Eingabebox: Markierter Eintrag }
  $17,     { 13: Eingabebox: Markierungsbalken }
  $1f,     { 14: Eingabebox: Markierter Text unter Markierungsbalken }
  $67,     { 15: Schalter }
  $30);    { 16: ungÅltig }

 def_monochrome:tcolors=
 ($70,     {  0: normaler Text }
  $70,     {  1: Dialogfeldrahmen }
  $79,     {  2: hervorgehobener Text }
  $07,     {  3: Eingabefeld }
  $70,     {  4: Anfangsbuchstaben }
  $07,     {  5: Pfeile im Eingabefeld }
  $70,     {  6: Auswahlliste }
  $70,     {  7: Balken in der Auswahlliste }
  $70,     {  8: Schalter }
  $70,     {  9: Eingabebox: Gesamtfarbe }
  $70,     { 10: Eingabebox: Rahmen }
  $07,     { 11: Eingabebox: Bildlaufleiste }
  $79,     { 12: Eingabebox: Markierter Eintrag }
  $07,     { 13: Eingabebox: Markierungsbalken }
  $09,     { 14: Eingabebox: Markierter Text unter Markierungsbalken }
  $07,     { 15: Schalter }
  $00);    { 16: ungÅltig }

  vidstart:word=$b800;
  helpencode:string=#19#240#241#198#77#89#144#199;

type
   pstring=^string;
   tevent=record
     typ:integer;      {0:Tastatur, 1:Maus}
     w1,w2,w3:word;    {Zusatzinfos, z.B. w1=gedrÅckte Taste}
   end;

   tvalidate=function(var s:string):boolean;   { Zur Kontrolle von Eingaben }


{ Grundobjekte }

   pchain=^tchain;                 { verkettete Liste von Objekten }
   pdialog=^tdialog;               { Dialogobjekt }
   pacc=^tacc;                     { Liste fÅr Kurztasten }
   pstrlist=^tstrlist;             { Liste von Strings fÅr plistbox }

   pstatic=^tstatic;               { Basisobjekt fÅr statische Bildelemente }
   pstatictext=^tstatictext;       { Text }
   pstaticframe=^tstaticframe;     { Rahmen }

   pdynamic=^tdynamic;             { Basisobjekt fÅr dynamische Bildelemente }
   plistbox=^tlistbox;             { Auswahlbox (Liste von Strings) }
   psubbox=^tsubbox;               { Untergeordnete Auswahlbox fÅr Eingabe }
   phelpbox=^thelpbox;             { Listbox zur Anzeige von Hilfeinformationen }
   pinput=^tinput;                 { Eingabefeld }
   pbutton=^tbutton;               { Druckknopf }
   pswitch=^tswitch;               { Schalter }
   pradio=^tradio;                 { Radioknopf (mu· gruppiert werden) }

   phelpindex=^thelpindex;         { Hilfeindexliste }

   tchain=object
     next:pchain;
     destructor done; virtual;
   end;

   tstatic=object(tchain)
     x,y:integer;
     constructor init(p:pdialog; ax,ay:integer);
     procedure paint; virtual;
   end;

   tdynamic=object(tchain)
     x,y,dx,dy:integer;
     mydiag:pdialog;
     valid:boolean;
     help_id:string[20];
     constructor init(p:pdialog; ax,ay,adx,ady:integer);
     destructor done; virtual;
     procedure keypress(var w:word); virtual;
     procedure getfocus; virtual;
     function loosefocus:boolean; virtual;
     procedure paint(focused:boolean); virtual;
     procedure leftdown; virtual;
     procedure leftup; virtual;
     procedure mousemove; virtual;
     procedure setvalid(b:boolean);
   end;

   tacc=record
     key,send:word;
     obj:pdynamic;
     next:pacc;
   end;

   thelpindex=record
     id:string[40];
     position:longint;
     next:phelpindex;
   end;

{ Abgeleitete Objekte }

   tstatictext=object(tstatic)
     t:string;
     highlight,markable:boolean;
     procedure settext(s:string);
     constructor init(p:pdialog; ax,ay:integer; s:string);
     procedure paint; virtual;
   end;


   tstaticframe=object(tstatic)
     name:string;
     dx,dy:integer;
     col:byte;
     constructor init(p:pdialog; ax,ay,adx,ady:integer);
     procedure paint; virtual;
   end;


   tstrlist=record
     s:pstring;
     marked:boolean;
     next:pstrlist;
   end;


   tlistbox=object(tdynamic)
     lst:pstrlist;
     max,top:word;
     cursor:word;
     name:string;
     pulling:boolean;
     inpbox:pinput;
     frametyp:byte;
     constructor init(p:pdialog; ax,ay,adx,ady:integer; acc:word);
     destructor done; virtual;
     procedure paint(focused:boolean); virtual;
     procedure showlistentries(focused:boolean); virtual;
     procedure add(s:string); virtual;
     procedure keypress(var w:word); virtual;
     function getlstptr(n:word):pstrlist; virtual;
     procedure leftdown; virtual;
     procedure mousemove; virtual;
     procedure leftup; virtual;
   end;

   tsubbox=object(tlistbox)
     bkg:pointer;
     status:integer; {0:eingeklappt, 1:ausgeklappt}
     constructor init(p:pinput; ady:integer);
     procedure keypress(var w:word); virtual;
     procedure openbox; virtual;
     procedure closebox; virtual;
     function loosefocus:boolean; virtual;
     procedure leftdown; virtual;
   end;

   thelpbox=object(tlistbox)
     bkg:pointer;
     constructor init(ax,ay,adx,ady:integer; topic: string);
     destructor done; virtual;
     procedure showlistentries(focused:boolean); virtual;
     procedure keypress(var w:word); virtual;
     procedure leftdown; virtual;
     function loadhelpentry(topic:string):boolean; virtual;
   end;

   tinput=object(tdynamic)
     s,format:string;
     lst:psubbox;
     cursor,left,maxlen:integer;
     myswitch:pswitch;  { wird markiert, kann auch pradio sein }
     validate:tvalidate;
     changed:boolean;
     constructor init(p:pdialog; ax,ay,adx:integer; acc:word);
     procedure paint(focused:boolean); virtual;
     procedure settext(txt:string); virtual;
     procedure getfocus; virtual;
     function loosefocus:boolean; virtual;
     procedure keypress(var w:word); virtual;
     procedure leftdown; virtual;
   end;

   tbutton=object(tdynamic)
     name:string;
     waspressed:boolean;
     constructor init(p:pdialog; ax,ay,adx:integer; bname:string; acc:word);
     procedure paint(focused:boolean); virtual;
     procedure keypress(var w:word); virtual;
     procedure leftdown; virtual;
     procedure leftup; virtual;
   end;


   tswitch=object(tdynamic)
     status:boolean;
     caption:string;
     constructor init(p:pdialog; ax,ay:integer; acc:word; cap:string);
     procedure paint(focused:boolean); virtual;
     procedure getfocus; virtual;
     function loosefocus:boolean; virtual;
     procedure settrue; virtual;
     procedure keypress(var w:word); virtual;
     procedure leftdown; virtual;
   end;

   tradio=object(tswitch)
     nradio:pradio;
     constructor init(p:pdialog; ax,ay:integer; acc:word; cap:string);
     procedure paint(focused:boolean); virtual;
     procedure getfocus; virtual;
     function loosefocus:boolean; virtual;
     procedure settrue; virtual;
     procedure keypress(var w:word); virtual;
     procedure leftdown; virtual;
   end;


   tdialog=object
     x,y,dx,dy:integer;
     cursorx,cursory:word;
     name:string;
     bk:pointer;
     static:pstatic;
     dynamic:pdynamic;
     acc:pacc;
     thefocus:pdynamic;
     help_id:string[20];
     mystatus:integer;   { siehe dg_xxx Konstanten }
     constructor init(posx,posy,posdx,posdy:integer; safebk:boolean);
     destructor done;
     procedure paint; virtual;
     procedure nextfocus; virtual;
     procedure lastfocus; virtual;
     procedure keypress(var w:word); virtual;
     procedure handleevent(event:tevent); virtual;
     function rundialog(b_ok,b_esc:pbutton):integer; virtual; { siehe dg_xxx Konstanten }
     procedure addacc(k1,k2:word; p:pdynamic);
     function setfocus(p:pdynamic):boolean;
   end;


procedure showhelp(topic:string);
procedure openhelpindex;

procedure hidecursor;
procedure showcursor;
procedure showmouse;
procedure hidemouse;
procedure waitleftrelease;
procedure criterror(err,errlog:string);
function initmouse:boolean;
procedure messagebox(caption,s:string);
procedure waitevent(var event:tevent);

function fstr(w:longint):string;
procedure initlogfile;
procedure logwrite(s:string);
procedure closelogfile;
procedure addstrlist(var lst:pstrlist; s:string);
procedure freestrlist(var lst:pstrlist);

function dumpvalidate(var s:string):boolean; far;

{************** Exportierte Variablen ****************}
var ccolor:byte;
    mouseok:boolean;
    mousex,mousey:word;
    mouse_left:boolean;
    cursorshape,origshape,overwriteshape:word;
    screen_y:word;
    logfilename:string;
    helpfile:string;
    helpfileheadersize:longint;
    colors:tcolors;
    overwrite:boolean;   { FÅr Eingabefeld }
    helpindex:phelpindex;
    helpenabled:boolean; { Hilfe aktiv oder nicht }
    debuglevel:integer;  { 0: nichts, 1: einfaches Log, 2: volles Log }


type wordarray=array[0..32000] of integer;


const
      { Tastaturkonstanten }
      kbf1=15104; kbf2=15360; kbf3=15616; kbf4=15872; kbf5=16128;
      kbf6=16384; kbf7=16640; kbf8=16896; kbf9=17152; kbf10=17408;
      kbshiftf1=21504; kbshiftf2=21760; kbshiftf3=22016;
      kbshiftf4=22272; kbshiftf5=22528; kbshiftf6=22784;
      kbshiftf7=23040; kbshiftf8=23296; kbshiftf9=23552;
      kbshiftf10=23808;
      kbctrlf1=24064; kbctrlf2=24320; kbctrlf3=24576;
      kbctrlf4=24832; kbctrlf5=25088; kbctrlf6=25344;
      kbctrlf7=25600; kbctrlf8=25856; kbctrlf9=26112;
      kbctrlf10=26368;
      kbctrlreturn=10;
      kbaltf1=26624; kbaltf2=26880; kbaltf3=27136;
      kbaltf4=27392; kbaltf5=27648; kbaltf6=27904;
      kbaltf7=28160; kbaltf8=28416; kbaltf9=28672;
      kbaltf10=28928;
      kbaltq=4096; kbaltw=4352; kbalte=4608; kbaltr=4864; kbaltt=5120;
      kbalty=5376; kbaltu=5632; kbalti=5888; kbalto=6144; kbaltp=6400;
      kbalta=7680; kbalts=7936; kbaltd=8192; kbaltf=8448; kbaltg=8704;
      kbalth=8960; kbaltj=9216; kbaltk=9472; kbaltl=9728; kbaltz=11264;
      kbaltx=11520; kbaltc=11776; kbaltv=12032; kbaltb=12288; kbaltn=12544;
      kbaltm=12800;
      kbUp=18432; kbDown=20480; kbRight=19712; kbLeft=19200;
      kbInsert=20992; kbHome=18176; kbPageUp=18688;
      kbDelete=21248; kbEnd=20224; kbPageDown=20736;
      kbReturn=13; kbEsc=27; kbTab=9; kbShiftTab=3840;
      kbBackspace=8; kbSpace=32;

      { Dialogkonstanten }
      dg_run=0; dg_ok=1; dg_exit=2;

implementation

const err_oem='Es steht nicht genÅgend'+#13+
 'Speicher zur VerfÅgung';

var  logfile:text;
     temp:word;

{***************************************************************************
*                                                                          *
*   Routinen zum Ansprechen der Maus                                       *
*                                                                          *
***************************************************************************}

function initmouse:boolean;
var temp:boolean;
begin
  asm
    xor ax,ax
    int 33h;
    mov temp,al
  end;
  mouseok:=temp; initmouse:=temp;
end;

procedure showmouse;
begin
  if mouseok then
    asm
      mov ax,1
      int 33h
    end;
end;

procedure hidemouse;
begin
  if mouseok then
    asm
      mov ax,2
      int 33h
    end;
end;


procedure mousepos(var x,y:word);
var sx,sy:word;
begin
  if mouseok then begin
    asm
      mov ax,3
      int 33h
      mov sx,cx
      mov sy,dx
    end;
    x:=sx; y:=sy;
  end
  else begin x:=0; y:=0; end;
end;

function leftbutton:boolean;
var temp:boolean;
begin
  if mouseok then begin
    asm
      mov ax,3
      int 33h;
      mov temp,bl
    end;
    leftbutton:=temp;
  end else leftbutton:=false;
end;

procedure waitleftrelease;
begin
  while leftbutton do ;
end;

function mouseinbox(x,y,dx,dy:integer):boolean;
begin
  mouseinbox:=(mousex>=x) and (mousex<x+dx) and (mousey>=y) and (mousey<y+dy);
end;


{***************************************************************************
*                                                                          *
*   Generelle Prozeduren und Funktionen                                    *
*                                                                          *
***************************************************************************}


procedure criterror(err,errlog:string);
begin
  logwrite('');
  logwrite('Kritischer Fehler: '+err);
  logwrite('Kommentar: '+errlog);
  logwrite('Freier Speicher: '+fstr(maxavail)+' Byte');
  messagebox('Fehler',err);
  halt(1);
end;



procedure hidecursor; assembler;
asm
  mov ah,0fh
  int 10h
  mov ah,1h
  mov bh,0h
  mov cx,0100h
  int 10h
end;

procedure showcursor; assembler;
asm
  mov ah,0fh
  int 10h
  mov ah,1h
  mov bh,0h
  mov cx,[cursorshape]
  int 10h
end;


function saferect(x,y,dx,dy:integer):pointer;
var size,ps,k:word; p:^wordarray; a,b:integer;
begin
  hidemouse;
  saferect:=nil;
  size:=dx*dy shl 1+20;
  if memavail<size then criterror(err_oem,'saferect()');
  getmem(pointer(p),size);
  p^[0]:=dx; p^[1]:=dy;
  ps:=x shl 1+y*160; k:=2;
  for a:=1 to dy do begin
    for b:=1 to dx do begin
      p^[k]:=memw[vidstart:ps];
      inc(k); inc(ps,2);
    end;
    inc(ps,160-dx shl 1);
  end;
  saferect:=p;
  showmouse;
end;

procedure restorerect(x,y:integer; var p:pointer; freeptr:boolean);
var pw:^wordarray; k,ps,dx,dy:word; a,b:integer;
begin
  hidemouse;
  pw:=p; dx:=pw^[0]; dy:=pw^[1];
  ps:=x shl 1+ y*160; k:=2;
  for a:=1 to dy do begin
    for b:=1 to dx do begin
      memw[vidstart:ps]:=pw^[k];
      inc(k); inc(ps,2);
    end;
    inc(ps,160-dx shl 1);
  end;
  if freeptr then begin
    freemem(pointer(p), dx*dy shl 1+20);
    p:=nil;
  end;
  showmouse;
end;

procedure puttextxy(x,y:integer; s:string);
var a,ps:word;
begin
  hidemouse;
  ps:=x shl 1+y*160;
  for a:=1 to length(s) do begin
    mem[vidstart:ps]:=ord(s[a]);
    mem[vidstart:ps+1]:=ccolor;
    inc(ps,2);
  end;
  showmouse;
end;


procedure putcolortextxy(x,y:integer; s:string);
var a,ps:word; s1:string; oldcolor,lastcolor:word;
begin
  oldcolor:=ccolor; lastcolor:=ccolor;
  hidemouse;
  ps:=0; s1:='';
  for a:=1 to length(s) do begin
    if s[a]=#1 then begin
      if length(s1)>0 then puttextxy(x+ps,y,s1);
      ps:=ps+length(s1);
      s1:='';
      if oldcolor<>lastcolor then lastcolor:=oldcolor else lastcolor:=14+7*16;
      ccolor:=lastcolor;
    end
    else begin
      s1:=s1+s[a];
    end;
  end;
  if length(s1)>0 then puttextxy(x+ps,y,s1);
  showmouse;
  ccolor:=oldcolor;
end;


function textlength(s:string):integer;
var i,j:integer;
begin
  j:=0;
  for i:=1 to length(s) do if s[i]>#31 then inc(j);
  textlength:=j;
end;

procedure putmarktextxy(x,y:integer; s:string);
var a,ps,p:word;
begin
  hidemouse;
  p:=pos('&',s);
  if p>0 then s:=copy(s,1,p-1)+copy(s,p+1,255);
  ps:=x shl 1+y*160;
  for a:=1 to length(s) do begin
    mem[vidstart:ps]:=ord(s[a]);
    if a=p then mem[vidstart:ps+1]:=(ccolor and 240) or 15 else
    mem[vidstart:ps+1]:=ccolor;
    inc(ps,2);
  end;
  showmouse;
end;



procedure bar(x,y,dx,dy:word; col:byte; shadow:boolean);
var ps:word; a,b:integer; z:byte;
begin
  hidemouse;
  ps:=x shl 1+y *160;
  for a:=1 to dy do begin
    for b:=1 to dx do begin
      mem[vidstart:ps]:=32; mem[vidstart:ps+1]:=col;
      inc(ps,2);
    end;
    ps:=ps+160-dx shl 1;
  end;
  showmouse;
  if shadow then begin
    ps:=(x+dx) shl 1+ (y+1)*160+1;
    for a:=1 to dy do begin
      mem[vidstart:ps]:=$08;
      inc(ps,160);
    end;
    ps:=(x+1) shl 1+(y+dy)*160+1;
    for a:=1 to dx-1 do begin
      mem[vidstart:ps]:=$08;
      inc(ps,2);
    end;
  end;
end;

procedure frame(x,y,dx,dy:word; col,typ:byte; caption:string);
var ps,ps1:word; a:integer; s:string;
begin
  hidemouse;
  if typ=0 then s:='ƒ≥⁄ø¿Ÿ' else s:='Õ∫…ª»º';
  ps:=x shl 1+y*160+2; ps1:=x shl 1+(y+dy-1)*160+2;
  for a:=1 to dx-2 do begin
    mem[vidstart:ps]:=ord(s[1]);
    mem[vidstart:ps+1]:=col;
    mem[vidstart:ps1]:=ord(s[1]);
    mem[vidstart:ps1+1]:=col;
    inc(ps,2); inc(ps1,2);
  end;
  ps:=x shl 1+y*160+160; ps1:=(x+dx-1) shl 1+y*160+160;
  for a:=1 to dy-2 do begin
    mem[vidstart:ps]:=ord(s[2]);
    mem[vidstart:ps+1]:=col;
    mem[vidstart:ps1]:=ord(s[2]);
    mem[vidstart:ps1+1]:=col;
    inc(ps,160); inc(ps1,160);
  end;
  ps:=x shl 1+y*160;
  mem[vidstart:ps]:=ord(s[3]); mem[vidstart:ps+1]:=col;
  inc(ps,(dx-1) shl 1);
  mem[vidstart:ps]:=ord(s[4]); mem[vidstart:ps+1]:=col;
  inc(ps,(dy-1)*160);
  mem[vidstart:ps]:=ord(s[6]); mem[vidstart:ps+1]:=col;
  dec(ps,(dx-1) shl 1);
  mem[vidstart:ps]:=ord(s[5]); mem[vidstart:ps+1]:=col;
  ps:=length(caption);
  if ps>0 then begin
    if ps>dx-6 then ps:=dx-6;
    ccolor:=col;
    s:=' '+copy(caption,1,ps)+' ';
    putmarktextxy(2+x,y,s);
  end;
  showmouse;
end;



procedure showvrunbar(x,y,dy,position,max:integer);
var ps:word; a,b:integer;
begin
  hidemouse;
  ps:=x shl 1+y*160;
  mem[vidstart:ps]:=24; mem[vidstart:ps+1]:=colors[11];
  inc(ps,160);
  for a:=1 to dy-2 do begin
    mem[vidstart:ps]:=ord('∞'); mem[vidstart:ps+1]:=colors[11];
    inc(ps,160);
  end;
  mem[vidstart:ps]:=25; mem[vidstart:ps+1]:=colors[11];
  dec(dy,3); inc(y);
  if max>0 then b:=(dy*position) div max else b:=0;
  ps:=x shl 1+(y+b)*160;
  mem[vidstart:ps]:=ord('€'); {mem[vidstart:ps+1]:=colors[11];}
  showmouse;
end;

function readkeymap:word; assembler;
asm
  mov ah,1
  int $16
  jz @nokey
  xor ah,ah
  int $16
  or al,al
  jz @ende
  xor ah,ah
  jmp @ende
  @nokey:
  xor ax,ax
  @ende:
end;

procedure waitevent(var event:tevent);
var w:word; px,py:word; b:boolean;
label 1;
  begin
  1:
    w:=readkeymap;
    if w<>0 then begin event.typ:=0; event.w1:=w; exit; end;
    mousepos(px,py); px:=px shr 3; py:=py shr 3;
    if (px<>mousex) or (py<>mousey) then begin
      event.typ:=1; mousex:=px; mousey:=py; exit;
    end;
    b:=leftbutton;
    if b and not mouse_left then begin
      mouse_left:=true; event.typ:=2; exit;
    end;
    if not b and mouse_left then begin
      mouse_left:=false; event.typ:=3; exit;
    end;
    goto 1;
end;



function fstr(w:longint):string;
var s:string;
begin
  str(w,s);
  fstr:=s;
end;


procedure initlogfile;
begin
  assign(logfile,logfilename);
  rewrite(logfile);
  close(logfile);
end;

procedure logwrite(s:string);
begin
  append(logfile);
  writeln(logfile,s);
  close(logfile);
end;

procedure closelogfile;
begin
  logwrite('--- LOGFILE ENDE ---');
  close(logfile);
end;


procedure freechain(p:pchain);
var p1:pchain;
begin
  while assigned(p) do begin
    p1:=p^.next; dispose(p,done); p:=p1;
  end;
end;

procedure addstrlist(var lst:pstrlist; s:string);
var p1:pstrlist; p2:^pointer;
begin
  p1:=lst; p2:=@lst;
  while assigned(p1) do begin
    p2:=@p1^.next; p1:=p1^.next;
  end;
  if maxavail<sizeof(p1) then criterror(err_oem,'addstrlist:'+s);
  new(p1); p1^.next:=nil;
  getmem(pointer(p1^.s),length(s)+4);
  p1^.s^:=s; p1^.marked:=false; p2^:=p1;
end;

procedure freestrlist(var lst:pstrlist);
var p1,p2:pstrlist;
begin
  p1:=lst;
  while assigned(p1) do begin
    p2:=p1^.next;
    dispose(pointer(p1^.s));
    dispose(pointer(p1));
    p1:=p2;
  end;
  lst:=nil;
end;


procedure messagememsize;
begin
  if debuglevel>0 then begin
    puttextxy(66,0,'             ');
    puttextxy(66,0,' Mem: '+fstr(memavail));
  end;
end;



{***************************************************************************
*                                                                          *
*   Methoden von TCHAIN                                                    *
*                                                                          *
***************************************************************************}

destructor tchain.done;
begin
end;



{***************************************************************************
*                                                                          *
*   Methoden von TSTATIC                                                   *
*                                                                          *
***************************************************************************}
constructor tstatic.init(p:pdialog; ax,ay:integer);
begin
  next:=p^.static; p^.static:=@self;
  x:=p^.x+ax; y:=p^.y+ay;
end;

procedure tstatic.paint;
begin
end;




{***************************************************************************
*                                                                          *
*   Methoden von TDYNAMIC                                                  *
*                                                                          *
***************************************************************************}
constructor tdynamic.init(p:pdialog; ax,ay,adx,ady:integer);
var p0:pdynamic;
begin
  help_id:='';
  if assigned(p) then begin
    p0:=p^.dynamic; next:=nil;
    if not assigned(p0) then
      p^.dynamic:=@self
    else begin
      while assigned(p0^.next) do p0:=pdynamic(p0^.next);
      p0^.next:=@self;
    end;
    x:=p^.x+ax; y:=p^.y+ay; dx:=adx; dy:=ady;
  end
  else begin
    x:=ax; y:=ay; dx:=adx; dy:=ady;
  end;
  valid:=true;
  mydiag:=p;
end;

destructor tdynamic.done;
begin
end;

procedure tdynamic.keypress(var w:word);
begin
  if (w=kbf1) then begin
    if help_id<>'' then
      showhelp(help_id)
    else if assigned(mydiag) and (mydiag^.help_id<>'') then
      showhelp(mydiag^.help_id);
    w:=0; exit;
  end;
  if not assigned(mydiag) then exit;
  if mydiag^.thefocus<>@self then begin
    if assigned(mydiag^.thefocus) then
      if mydiag^.thefocus^.loosefocus then begin
        mydiag^.thefocus:=@self; getfocus;
      end
      else exit;
  end;
  if w=0 then exit;
  if (w=kbdown) or (w=kbright) or (w=kbtab) then begin
    mydiag^.nextfocus; w:=0;
  end
  else if (w=kbup) or (w=kbleft) or (w=kbshifttab) then begin
    mydiag^.lastfocus; w:=0;
  end;
end;

procedure tdynamic.setvalid(b:boolean);
begin
  valid:=b;
  paint(mydiag^.thefocus=@self);
end;

procedure tdynamic.getfocus;
begin
  paint(true);
end;

function tdynamic.loosefocus;
begin
  paint(false); loosefocus:=true;
end;

procedure tdynamic.paint;
begin
end;

procedure tdynamic.leftdown;
begin
end;

procedure tdynamic.leftup;
begin
end;

procedure tdynamic.mousemove;
begin
end;


{***************************************************************************
*                                                                          *
*   Methoden von TDIALOG                                                   *
*                                                                          *
***************************************************************************}
constructor tdialog.init(posx,posy,posdx,posdy:integer; safebk:boolean);
begin
  cursorx:=Wherex; cursory:=WhereY;
  x:=posx; y:=posy; dx:=posdx; dy:=posdy; acc:=nil;
  static:=nil; dynamic:=nil; thefocus:=nil; mystatus:=dg_run;
  name:='Dialogfenster'; help_id:='';
  if safebk then begin
    bk:=saferect(posx,posy,posdx+1,posdy+1);
    if not assigned(bk) then criterror(err_oem,'tdialog.init()');
  end
  else bk:=nil;
end;

destructor tdialog.done;
var pd,pd1:pdynamic; ps,ps1:pstatic;
begin
  if assigned(bk) then restorerect(x,y,bk,true);
  freechain(dynamic);
  freechain(static);
  gotoxy(cursorx,cursory); showcursor;
  messagememsize;
end;


procedure tdialog.paint;
var p1:pstatic; p2:pdynamic; a,b:integer; ps,ps1:word; s:string;
    foc:boolean;
begin
  messagememsize;
  if not assigned(thefocus) then thefocus:=dynamic;
  hidecursor;
  bar(x,y,dx,dy,colors[0],true);
  frame(x,y,dx,dy,colors[1],1,name);
  p1:=static;
  while assigned(p1) do begin
    p1^.paint; p1:=pstatic(p1^.next);
  end;
  p2:=dynamic;
  while assigned(p2) do begin
    foc:=(thefocus=p2);
    p2^.paint(foc); p2:=pdynamic(p2^.next);
  end;
end;


function tdialog.setfocus(p:pdynamic):boolean;
begin
  if assigned(thefocus) then
    if not thefocus^.loosefocus then begin
      setfocus:=false; exit;
    end;
  thefocus:=p;
  if assigned(thefocus) then thefocus^.getfocus;
  setfocus:=true;
end;


procedure tdialog.nextfocus;
begin
  if not assigned(thefocus) then thefocus:=dynamic;
  if assigned(thefocus) then begin
    if not thefocus^.loosefocus then exit;
    if not assigned(thefocus^.next) then
      thefocus:=dynamic
    else
      thefocus:=pdynamic(thefocus^.next);
      thefocus^.getfocus;
   end;
end;


procedure tdialog.lastfocus;
var p:pdynamic;
begin
  if not assigned(thefocus) then thefocus:=dynamic;
  if not assigned(thefocus) then exit;
  if thefocus=dynamic then begin
    if not thefocus^.loosefocus then exit;
    p:=dynamic;
    while assigned(p^.next) do p:=pdynamic(p^.next);
    thefocus:=p; p^.getfocus;
  end
  else begin
    if not thefocus^.loosefocus then exit;
    p:=dynamic;
    while (pdynamic(p^.next)<>thefocus) do p:=pdynamic(p^.next);
    thefocus:=p; p^.getfocus;
  end;
end;


procedure tdialog.keypress(var w:word);
var p:pdynamic; pac:pacc;
begin
  pac:=acc;
{  if (w=kbf1) then begin
    if help_id<>'' then showhelp(help_id);
    w:=0; exit;
  end;}
  while assigned(pac) and (pac^.key<>w) do pac:=pac^.next;
  if assigned(pac) then begin
    w:=pac^.send;
    pac^.obj^.keypress(w);
    if w=0 then exit;
  end;
  if assigned(thefocus) then thefocus^.keypress(w);
  if w=0 then exit;
  case w of
    kbctrlreturn : begin mystatus:=dg_ok; exit; end;
    kbesc        : begin mystatus:=dg_exit; exit; end;
    else begin sound(440); delay(100); nosound; exit; end;
  end;
  w:=0;
end;


procedure handleevent(event:tevent; p:pdynamic);
begin
if event.typ=0 then begin p^.keypress(event.w1); exit; end;
{ Mouseevents bearbeiten: }
if assigned(p) then begin
 if mouseinbox(p^.x,p^.y,p^.dx,p^.dy) then begin
  case event.typ of
   1: p^.mousemove;
   2: begin
      p^.leftdown;
      end;
   3: p^.leftup;
  end;
 exit;
 end;
 end;
end;



procedure tdialog.handleevent(event:tevent);
var p:pdynamic;
begin
if event.typ=0 then begin keypress(event.w1); exit; end;
{ Mouseevents bearbeiten: }
p:=thefocus;
if assigned(p) then begin
 if mouseinbox(p^.x,p^.y,p^.dx,p^.dy) then begin
  case event.typ of
   1: p^.mousemove;
   2: begin
      if thefocus<>p then if not setfocus(p) then exit;
      p^.leftdown;
      end;
   3: p^.leftup;
  end;
 exit;
 end;
 end;
p:=dynamic;
while assigned(p) do begin
 if mouseinbox(p^.x,p^.y,p^.dx,p^.dy) then begin
  case event.typ of
   1: p^.mousemove;
   2: begin
      if thefocus<>p then if not setfocus(p) then exit;
      p^.leftdown;
      end;
   3: p^.leftup;
  end;
  exit;
  end;
 p:=pdynamic(p^.next);
 end;
end;


function tdialog.rundialog(b_ok,b_esc:pbutton):integer;
var event:tevent;
begin
  mystatus:=dg_run;
  repeat
    waitevent(event);
    handleevent(event);
    if assigned(b_ok) and (b_ok^.waspressed) then
      mystatus:=dg_ok
    else if assigned(b_esc) and (b_esc^.waspressed) then mystatus:=dg_exit;
  until (mystatus<>dg_run);
  rundialog:=mystatus;
  waitleftrelease;
end;

procedure tdialog.addacc(k1,k2:word; p:pdynamic);
var p1:pacc;
begin
  if maxavail<sizeof(p1) then criterror(err_oem,'tdialog.addacc()');
  new(p1);
  with p1^ do begin
    key:=k1; send:=k2; obj:=p; next:=acc;
  end;
  acc:=p1;
end;


{***************************************************************************
*                                                                          *
*   Methoden von TSTATICTEXT                                               *
*                                                                          *
***************************************************************************}

constructor tstatictext.init(p:pdialog; ax,ay:integer; s:string);
begin
  inherited init(p,ax,ay);
  t:=s; highlight:=false;
  markable:=true;
end;

procedure tstatictext.settext(s:string);
var ps:word; a:integer;
begin
  ps:=(x+length(s)) shl 1+y*160;
  for a:=length(s) to length(t) do begin
    mem[vidstart:ps]:=32;
    mem[vidstart:ps+1]:=colors[0];
    inc(ps,2);
  end;
  t:=s;
  paint;
end;


procedure tstatictext.paint;
var col:byte;
begin
  if highlight then col:=colors[2] else col:=colors[0];
  ccolor:=col;
  if markable then
    putmarktextxy(x,y,t)
  else
    puttextxy(x,y,t);
end;


{***************************************************************************
*                                                                          *
*   Methoden von TSTATICFRAME                                              *
*                                                                          *
***************************************************************************}

constructor tstaticframe.init(p:pdialog; ax,ay,adx,ady:integer);
begin
  inherited init(p,ax,ay);
  dx:=adx; dy:=ady;
  name:=''; col:=colors[1]
end;

procedure tstaticframe.paint;
begin
  frame(x,y,dx,dy,col,0,name);
end;





{***************************************************************************
*                                                                          *
*   Methoden von TLISTBOX                                                  *
*                                                                          *
***************************************************************************}
constructor tlistbox.init(p:pdialog; ax,ay,adx,ady:integer; acc:word);
begin
  inherited init(p,ax,ay,adx,ady);
  lst:=nil; top:=0; cursor:=0; max:=0; name:='';
  pulling:=false; inpbox:=nil;
  if acc<>0 then p^.addacc(acc,0,@self);
end;

destructor tlistbox.done;
var p,p1:pstrlist;
begin
  p:=lst;
  while assigned(p) do begin
    p1:=p^.next;
    dispose(pointer(p^.s));
    dispose(pointer(p)); p:=p1;
  end;
  lst:=nil;
end;

procedure tlistbox.paint(focused:boolean);
var ps:word; a:integer; plst:pstrlist; tp:integer;
begin
  bar(x,y,dx,dy,colors[9],false);
  if focused then
    tp:=1
  else
    tp:=0;
  frame(x,y,dx,dy,colors[10],0,name);
  ps:=(x+dx-1) shl 1+y*160+160;
  showlistentries(focused);
end;


procedure tlistbox.showlistentries(focused:boolean);
var plst:pstrlist; i:integer; s:string; ps:word;
begin
  plst:=getlstptr(top);
  if not assigned(plst) then plst:=lst;
  ps:=y+1;
  for i:=top to top+dy-3 do begin
    ccolor:=colors[9];
    if not assigned(plst) then
      s:=''
    else begin
      s:=plst^.s^;
      if (i=cursor) and focused then begin
        if plst^.marked then
          ccolor:=colors[14]
        else
          ccolor:=colors[13];
      end
      else if plst^.marked then ccolor:=colors[12]
    end;
    while length(s)<dx-2 do s:=s+' ';
    puttextxy(x+1,ps,copy(s,1,dx-2)); inc(ps);
    if assigned(plst) then plst:=plst^.next;
  end;
  showvrunbar(x+dx-1,y+1,dy-2,cursor,max-1);
end;



procedure tlistbox.add(s:string);
begin
  addstrlist(lst,s);
  inc(max);
end;

function tlistbox.getlstptr(n:word):pstrlist;
var p:pstrlist; k:word;
begin
  p:=lst; k:=1;
  while (k<=n) and assigned(p) do begin
    p:=p^.next; inc(k);
  end;
  getlstptr:=p;
end;


procedure tlistbox.keypress(var w:word);
var p:pstrlist; nokey :boolean;
begin
  nokey:=false;
  case w of
    kbdown    : if cursor<max-1 then inc(cursor);
    kbup      : if cursor>0 then dec(cursor);
    kbpageup  : if cursor>=dy then dec(cursor,dy) else cursor:=0;
    kbpagedown: if cursor<max-dy-1 then inc(cursor,dy) else cursor:=max-1;
    kbspace,kbreturn
              : if assigned(inpbox) then begin
                  if assigned(inpbox^.myswitch) then inpbox^.myswitch^.settrue;
                  p:=getlstptr(cursor);
                  if assigned(p) then inpbox^.settext(p^.s^);
                end else
                  if w<>kbreturn then begin
                    p:=getlstptr(cursor);
                    if assigned(p) then p^.marked:=not p^.marked;
                    if cursor<max-1 then inc(cursor);
                  end;
    kbhome    : cursor:=0;
    kbend     : cursor:=max-1;
    else nokey:=true;
  end;
  if nokey then begin
    inherited keypress(w);
    exit;
  end;
  w:=0;
  if cursor>top+dy-3 then
    top:=cursor-dy+3
  else
    if cursor<top then top:=cursor;
  showlistentries(true);
end;


procedure tlistbox.leftdown;
var t:word; p:pstrlist; w:word;
begin
  if mouseinbox(x+1,y+1,dx-2,dy-2) then begin
    t:=mousey-y-1+top;
    p:=getlstptr(t);
    if assigned(p) then begin
     if assigned(inpbox) then
       inpbox^.settext(p^.s^)
    else
      p^.marked:=not p^.marked;
      cursor:=t; showlistentries(true);
    end;
    waitleftrelease;
    exit;
  end;
  if mousex<>x+dx-1 then exit;
  if mousey=y+1 then begin
    w:=kbup; keypress(w); waitleftrelease; exit;
  end;
  if mousey=y+dy-2 then begin
    w:=kbdown; keypress(w); waitleftrelease; exit;
  end;
  if max>1 then
    t:=((dy-5)*cursor) div (max-1)
  else
    t:=0;
  t:=t+y+2;
  if mousey<t then begin
    w:=kbpageup; keypress(w); waitleftrelease; exit;
  end;
  if mousey>t then begin
    w:=kbpagedown; keypress(w); waitleftrelease; exit;
  end;
  if mousey=t then pulling:=true;
end;

procedure tlistbox.mousemove;
var t:integer;
begin
  if not pulling or (mousex<>x+dx-1) then exit;
  t:=mousey-y-2;
  if (t<0) or (t>=dy-4) then exit;
  if max<2 then
    cursor:=0
  else
    cursor:=(t*(max-1)) div (dy-5);
  if cursor>top+dy-3 then
    top:=cursor-dy+3
  else
    if cursor<top then top:=cursor;
  showlistentries(true);
end;

procedure tlistbox.leftup;
begin
  pulling:=false;
end;



{***************************************************************************
*                                                                          *
*   Methoden von TSUBBOX                                                   *
*                                                                          *
***************************************************************************}
constructor tsubbox.init(p:pinput; ady:integer);
begin
  inherited init(nil,p^.x,0,p^.dx,ady,0); {y wird nachtrÑglich eingetragen}
  bkg:=nil; inpbox:=p; next:=nil; status:=0;
  p^.lst:=@self;
end;

procedure tsubbox.keypress(var w:word);
var w_old:word;
begin
  w_old:=w;
  inherited keypress(w);
  if (w_old=kbspace) or (w_old=kbreturn) or (w_old=kbleft) or (w_old=kbright)
    or (w_old=kbtab) or (w_old=kbshifttab) or (w_old=kbesc) then
    begin closebox; w:=0;
  end;
end;

procedure tsubbox.openbox;
var w1,w2:word;
begin
  w1:=screen_y-inpbox^.y; w2:=inpbox^.y-1;
  if dy<w1 then
    y:=inpbox^.y+1
  else if dy<w2 then
    y:=inpbox^.y-dy
  else
    if w1>w2 then begin
      y:=inpbox^.y+1; dy:=w1;
    end
    else begin
      y:=1; dy:=w2;
    end;
  bkg:=saferect(x,y,dx,dy);
  if not assigned(bkg) then criterror(err_oem,'tsubbox.openbox()');
  paint(true); inpbox^.mydiag^.setfocus(@self);
  status:=1;
end;

procedure tsubbox.closebox;
begin
  with inpbox^.mydiag^ do begin
    thefocus:=inpbox; thefocus^.getfocus;
  end;
  restorerect(x,y,bkg,true);
  status:=0;
end;

function tsubbox.loosefocus:boolean;
begin
  closebox; inpbox^.loosefocus;
  loosefocus:=true;
end;

procedure tsubbox.leftdown;
begin
  inherited leftdown;
  if mouseinbox(x+1,y+1,dx-2,dy-2) then closebox;
end;

{***************************************************************************
*                                                                          *
*   Methoden von THELPBOX                                                  *
*                                                                          *
***************************************************************************}

function upstring(s:string):string;
var i:integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  upstring:=s;
end;

procedure showhelp(topic:string);
var p:phelpbox; event:tevent;
begin
  if not helpenabled then exit;
  new(p,init(9,3,62,20,topic));
  p^.paint(true);
  repeat
    waitevent(event);
    if (event.typ=0) and (event.w1=kbEsc) then begin
      dispose(p,done);
      break;
    end;
    handleevent(event,p);
  until 1=0;
end;

procedure openhelpindex;
{ Variable helpfiledir mu· vorher auf den Pfad der Hilfedatei gesetzt werden }
type tindexentry=record
 id:string[40];
 position:longint;
 end;
var f:file of tindexentry; t:tindexentry; p:phelpindex; p1:^pointer; error:boolean;
label abortread;
begin
  helpenabled:=false;
  assign(f,helpfile);
  reset(f);
  if IOResult<>0 then begin
    error:=true;
    goto abortread;
  end;
  helpindex:=nil; p1:=@helpindex;
  error:=false;
  helpfileheadersize:=-1;
  while not eof(f) do begin
    read(f,t);
    if IOResult<>0 then begin
      error:=true;
      goto abortread;
    end;
    if t.id='' then begin
      helpfileheadersize:=filepos(f);
      goto abortread;
    end;
    new(p);
    p^.next:=nil; p1^:=p; p1:=@p^.next;
    p^.id:=t.id;
    p^.position:=t.position;
  end;
abortread:
  close(f);
  if error then begin
    {messagebox('Echostat-Hilfe','Die Datei "echostat.hlp" konnte nicht gefunden werden.'#13' Hilfe ist nicht verfÅgbar');}
    exit;
  end;
  if helpfileheadersize<0 then begin
    {messagebox('Echostat-Hilfe','Die Datei "echostat.hlp" ist fehlerhaft'#13'Hilfe ist nicht verfÅgrbar');}
    exit;
  end;
  helpenabled:=true;
end;

constructor thelpbox.init(ax,ay,adx,ady:integer; topic:string);
begin
  inherited init(nil,ax,ay,adx,ady,0);
  if not loadhelpentry(topic) then exit;
  bkg:=saferect(ax,ay,adx,ady);
end;

function thelpbox.loadhelpentry(topic:string):boolean;
var p:phelpindex; f:file; b:array[0..2048] of char; sz:longint; wfill:word;
    position:longint; s:string; i:integer;
label loop1,label_ready;
begin
  p:=helpindex;
  lst:=nil;
  max:=0;
  topic:=upstring(topic);
  while assigned(p) do begin
    if p^.id=topic then break;
    p:=p^.next;
  end;
  if not assigned(p) then begin
    messagebox('Hilfedatei','Thema nicht gefunden');
    exit;
  end;
  assign(f,helpfile);
  reset(f,1);
  sz:=filesize(f);
  position:=p^.position; {+helpfileheadersize;}
  seek(f,position);
loop1:
  if (sz-position)>2048 then
    wfill:=2048
  else
    wfill:=(sz-position);
  s:='';
  blockread(f,b,wfill);
  for i:=0 to wfill-1 do begin
    { b[i]:=chr(ord(b[i]) xor ord(helpencode[(position+i) and 7]));}
    if b[i]=#13 then begin
      if s='<>' then goto label_ready;
      add(s); s:='';
    end else
      s:=s+b[i];
  end;
label_ready:
end;


procedure thelpbox.showlistentries(focused:boolean);
var plst:pstrlist; i:integer; s:string; ps:word;
begin
  plst:=getlstptr(top); if not assigned(plst) then plst:=lst;
  ps:=y+1;
  ccolor:=colors[9];
  for i:=top to top+dy-3 do begin
    if not assigned(plst) then
      s:=''
    else begin
      s:=plst^.s^;
    end;
    while textlength(s)<dx-2 do s:=s+' ';
    putcolortextxy(x+1,ps,copy(s,1,dx-2)); inc(ps);
    if assigned(plst) then plst:=plst^.next;
  end;
  showvrunbar(x+dx-1,y+1,dy-2,cursor,max-1);
end;

procedure thelpbox.keypress(var w:word);
begin
  if w<>kbSpace then inherited keypress(w);
end;

procedure thelpbox.leftdown;
begin
  inherited leftdown;
end;

destructor thelpbox.done;
begin
  restorerect(x,y,bkg,true);
  inherited done;
end;


{***************************************************************************
*                                                                          *
*   Methoden von TBUTTON                                                   *
*                                                                          *
***************************************************************************}
constructor tbutton.init(p:pdialog; ax,ay,adx:integer; bname:string; acc:word);
begin
  if adx=-1 then adx:=length(bname)+2;
  inherited init(p,ax,ay,adx,1);
  name:=bname; waspressed:=false;
  if acc<>0 then p^.addacc(acc,kbreturn,@self);
end;

procedure tbutton.paint(focused:boolean);
var p,col:integer; s:string;
begin
  if valid then col:=colors[15] else col:=colors[16];
  bar(x,y,dx,1,col,false);
  s:=name; p:=length(s); if pos('&',s)>0 then dec(p);
  ccolor:=col;
  putmarktextxy(x+(dx-p) shr 1,y,s);
  if focused then begin
    puttextxy(x,y,'Ø'); puttextxy(x+dx-1,y,'Æ');
  end;
  s:='';
  for p:=1 to dx do s:=s+'ﬂ';
  ccolor:=colors[0]; puttextxy(x+1,y+1,s);
  puttextxy(x+dx,y,'‹');
end;

procedure tbutton.keypress(var w:word);
begin
  inherited keypress(w);
  if w=0 then exit;
  if w=kbreturn then begin
    waspressed:=true; w:=0;
  end;
end;

procedure tbutton.leftdown;
begin
end;

procedure tbutton.leftup;
begin
  waspressed:=true;
  waitleftrelease;
end;


{***************************************************************************
*                                                                          *
*   Methoden von TSWITCH                                                   *
*                                                                          *
***************************************************************************}
constructor tswitch.init(p:pdialog; ax,ay:integer; acc:word; cap:string);
var l:integer;
begin
  l:=3;
  if length(cap)<>0 then l:=4+length(cap);
  inherited init(p,ax,ay,l,1);
  status:=false; caption:=cap;
  if acc<>0 then p^.addacc(acc,kbspace,@self);
end;

procedure tswitch.paint(focused:boolean);
var s:string; col:integer;
begin
  if valid then
    col:=colors[8]
  else
    col:=colors[16];
  s:='[ ]';
  if status then s[2]:='˛';
  ccolor:=col;
  puttextxy(x,y,s);
  ccolor:=colors[0];
  putmarktextxy(x+4,y,caption);
end;


procedure tswitch.settrue;
begin
 status:=not status;
 paint(true);
end;

procedure tswitch.keypress(var w:word);
begin
  inherited keypress(w);
  if w=0 then exit;
  if w=kbspace then begin
    status:=not status; paint(true); w:=0;
  end;
end;

procedure tswitch.leftdown;
var w:word;
begin
  w:=kbspace;
  keypress(w);
  waitleftrelease;
end;

procedure tswitch.getfocus;
begin
  gotoxy(x+2,y+1);
  showcursor;
end;

function tswitch.loosefocus:boolean;
begin
  hidecursor;
  loosefocus:=true;
end;


{***************************************************************************
*                                                                          *
*   Methoden von TRADIO                                                    *
*                                                                          *
***************************************************************************}

(*
 Radiobuttons mÅssen eine RingverknÅpfung enthalten. Sind r1,r2,r3 vom Typ
 pradio, so ist z.B. folgendes richtig:

 new(r1,init(diag,20,8));         { ersten Knopf ganz normal einrichten }
 new(r1^.nradio,init(diag,20,9)); { zweiten Knopf im nradio Feld des ersten }
 r2:=r1^.nradio;                  { Diesen will man auch direkt ansprechen }
 new(r2^.nradio,init(diag,20,10));{ dritten Knopf im nradio Feld des zweiten }
 r3:=r2^.nradio;                  { auch direkt ansprechbar }
 r3^.nradio:=r1;                  { RingverknÅpfung herstellen !!! }
 r1^.setradio;                    { ersten Knopf einschalten }
*)

constructor tradio.init(p:pdialog; ax,ay:integer; acc:word; cap:string);
begin
  inherited init(p,ax,ay,acc,cap);
  status:=false; nradio:=nil;
  if acc<>0 then p^.addacc(acc,kbspace,@self);
end;

procedure tradio.settrue;
var p:pradio;
begin
  p:=@self; p:=p^.nradio;
  while assigned(p) and (p<>@self) do begin
    p^.status:=false; p^.paint(false); p:=p^.nradio;
  end;
  status:=true; paint(true);
end;

procedure tradio.paint(focused:boolean);
var s:string;
begin
  s:='( )'; if status then s[2]:=#4;
  ccolor:=colors[8];
  puttextxy(x,y,s);
  ccolor:=colors[0];
  putmarktextxy(x+4,y,caption);
end;

procedure tradio.getfocus;
begin
  gotoxy(x+2,y+1);
  showcursor;
end;

function tradio.loosefocus:boolean;
begin
  hidecursor;
  loosefocus:=true;
end;

procedure tradio.keypress(var w:word);
begin
  if w=kbspace then begin
    settrue; w:=0; exit;
  end;
  inherited keypress(w);
end;

procedure tradio.leftdown;
begin
  settrue;
  waitleftrelease;
end;





{***************************************************************************
*                                                                          *
*   Methoden von TINPUT                                                    *
*                                                                          *
***************************************************************************}

function dumpvalidate(var s:string):boolean;
begin
  dumpvalidate:=true;
end;

constructor tinput.init(p:pdialog; ax,ay,adx:integer; acc:word);
begin
  inherited init(p,ax,ay,adx,1);
  myswitch:=nil;
  s:=''; format:=''; left:=1; cursor:=1;
  maxlen:=255; lst:=nil;
  if acc<>0 then p^.addacc(acc,0,@self);
  validate:=dumpvalidate; changed:=false;
end;

procedure tinput.paint(focused:boolean);
var ps,len:word; i:integer;
begin
  for i:=1 to length(format) do
    if format[i]<>' ' then s[i]:=format[i];
  if not assigned(lst) then
    len:=dx
  else
    len:=dx-1;
  if cursor>length(s)+1 then
    cursor:=length(s)+1
  else if cursor<1 then cursor:=1;
  if cursor>left+len-2 then left:=cursor-len+2;
  if cursor<left then left:=cursor;
  if valid then
    ccolor:=colors[3]
  else
    ccolor:=colors[16];
  bar(x,y,len,1,ccolor,false);
  puttextxy(x+1,y,copy(s,left,len-2));
  if valid then
    ccolor:=colors[5]
  else
    ccolor:=colors[16];
  if left>1 then puttextxy(x,y,#17);
  if length(s)-left>len-3 then puttextxy(x+len-1,y,#16);
  if valid then
    ccolor:=colors[1]
  else
    ccolor:=colors[16];
  if assigned(lst) then puttextxy(x+len,y,#25);
  if focused then begin
    if overwrite then
      cursorshape:=overwriteshape
    else
      cursorshape:=origshape;
    gotoxy(x+cursor+2-left,y+1); showcursor;
  end;
end;

procedure tinput.settext(txt:string);
begin
  s:=copy(txt,1,maxlen); left:=1;
  cursor:=length(s)+1;
  paint(false); changed:=true;
end;

procedure tinput.getfocus;
begin
  if overwrite then
    cursorshape:=overwriteshape
  else
    cursorshape:=origshape;
  gotoxy(x+cursor+2-left,y+1); showcursor;
  if assigned(lst) then begin
    ccolor:=colors[1];
    with mydiag^ do
      puttextxy(x+dx-7,y+dy-1,' F2 ');
  end;
end;

function tinput.loosefocus:boolean;
var b:boolean;
begin
  if changed then
    b:=validate(s)
  else
    b:=true;
  loosefocus:=b;
  changed:=false;
  if not b then begin
    paint(false); exit;
  end;
  hidecursor; cursorshape:=origshape;
  if assigned(lst) then begin
    ccolor:=colors[1];
    with mydiag^ do
      puttextxy(x+dx-7,y+dy-1,'ÕÕÕÕ');
  end;
  paint(false);
end;

procedure tinput.keypress(var w:word);
begin
  if (w<>kbright) and (w<>kbleft) then inherited keypress(w);
  if w=0 then exit;
  if (w=kbdown) or (w=kbreturn) then begin
    mydiag^.nextfocus; w:=0; exit;
  end;
  changed:=true;
  case w of
    kbinsert:
      begin
        overwrite:=not overwrite;
        if overwrite then
          cursorshape:=overwriteshape
        else
          cursorshape:=origshape;
        showcursor;
      end;
    kbf2:
      if assigned(lst) then begin
        if assigned(myswitch) then myswitch^.settrue;
        if lst^.status=0 then
          lst^.openbox
        else
          lst^.closebox;
      end;
    kbf4:
      settext('');
    kbhome:
      cursor:=1;
    kbend:
      cursor:=length(s)+1;
    kbleft:
      dec(cursor);
    kbright:
      inc(cursor);
    kbdelete:
      if length(s)>0 then
        s:=copy(s,1,cursor-1)+copy(s,cursor+1,255);
    kbbackspace:
      if cursor>1 then begin
        s:=copy(s,1,cursor-2)+copy(s,cursor,255);
        dec(cursor);
      end;
    kbup:
      begin
        mydiag^.lastfocus; w:=0; exit;
      end
    else
      if (w>=32) and (w<=255)  then begin
        if overwrite then begin
          if (cursor=length(s)+1) and (length(s)<maxlen) then
            s:=s+chr(w)
          else
            s[cursor]:=chr(w)
        end
        else
          if (length(s)<maxlen) then
            s:=copy(s,1,cursor-1)+chr(w)+copy(s,cursor,255)
          else
            exit;
       inc(cursor);
    end
    else
      exit;
  end;
  if (w<>kbf2) and assigned(myswitch) then myswitch^.settrue;
  w:=0;
  paint(true); gotoxy(x+cursor+2-left,y+1);
end;

procedure tinput.leftdown;
var t:integer; w,len:word;
begin
  if assigned(lst) then
    len:=dx-1
  else
    len:=dx;
  t:=mousex-x;
  if (t=0) then
    dec(cursor,10)
  else
   if (t=len-1) then
     inc(cursor,10)
   else
     if assigned(lst) and (t=dx-1) then
       begin w:=kbf2; keypress(w);
     end
     else
       cursor:=left+t-1;
  paint(true); gotoxy(x+cursor+2-left,y+1);
  waitleftrelease;
end;




{************************************************************************}


procedure messagebox(caption,s:string);
var w,l,i,p:integer; diag:pdialog; txt:pstatictext; b_ok:pbutton;
    s1:string;
begin
  l:=0; p:=1; w:=length(caption);
  s1:=s; s1:=s1+#13;
  for i:=1 to length(s1) do
    if s1[i]=#13 then begin
      inc(l); if (i-p)>w then w:=i-p;
      p:=i;
    end;
  inc(w,10);
  if maxavail<sizeof(diag) then criterror(err_oem,'');
  new(diag,init(40-(w shr 1),12-((l+6) shr 1),w,l+6,true));
  diag^.name:=caption;
  for i:=1 to l do begin
    p:=pos(#13,s1);
    if maxavail<sizeof(txt) then criterror(err_oem,'messagebox()');
    new(txt,init(diag,5,i+1,copy(s1,1,p-1)));
    s1:=copy(s1,p+1,255);
  end;
  if maxavail<sizeof(b_ok) then criterror(err_oem,'messagebox()');
  new(b_ok,init(diag,w div 2-7,l+3,14,'&Ok',kbalto));
  diag^.paint;
  diag^.rundialog(b_ok,nil);
  dispose(diag,done);
end;


begin
  asm
    mov  ah,03h
    mov  bh,0h
    int  10h
    mov  [origshape],cx
  end;
  cursorshape:=origshape;
  overwriteshape:=lo(cursorshape)+word(lo(cursorshape) shr 1) shl 8;
  overwrite:=false;
  mouseok:=false; mousex:=0; mousey:=0; mouse_left:=false;
  hidecursor;
  logfilename:='c:\logfile.log';
  if mem[$40:$49]=7 then begin
    vidstart:=$b000; colors:=def_monochrome;
  end
  else
    colors:=def_color;
  screen_y:=1; temp:=wherey;
  repeat
    inc(screen_y);
    gotoxy(1,screen_y);
  until wherey<>screen_y;
  dec(screen_y);
  gotoxy(1,temp);
  debuglevel:=0;
end.

{
  $Log: dialog.pas,v $
  Revision 1.2  2001/01/22 19:31:27  MH
  Erste Arbeiten an EchoStat:
  - /nomouse schaltet die Maus ab
  - divisions by zero fixed
  - Brettliste deaktiviert, da zum einen der Zeiger nicht sauber
    ist und zum anderen redudant (Bug mu· aber trotzdem beseitigt werden)
  - Farbe zur besseren lesbarkeit von Gelb auf Blau geÑndert

  Revision 1.1  2001/01/05 19:29:56  rb
  ECHOSTAT eingecheckt


}
