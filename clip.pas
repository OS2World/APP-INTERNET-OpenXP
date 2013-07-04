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
{ $Id: clip.pas,v 1.11 2001/06/18 20:17:15 oh Exp $ }

(***********************************************************)
(*                                                         *)
(*                       UNIT clip                         *)
(*                                                         *)
(*           Schnittstelle zum Windows-Clipboard           *)
(*                     + Smartdrive                        *)
(*                                         PM 11/92, 05/93 *)
(***********************************************************)

{$I XPDEFINE.INC }
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit clip;

interface

uses xpglobal, dos, typeform;

const     cf_Text      = 1;            { Clipboard-Datenformate }
          cf_Bitmap    = 2;
          cf_Oemtext   = 7;
          cf_Dsptext   = $81;
          cf_DspBitmap = $82;
          useclipwin : boolean = false;

function  WinVersion:smallword;                 { Windows >= 3.0      }

function ClipAvailable:boolean;                 { Clipboard verfÅgbar }
function ClipOpen:boolean;                      { Clipboard îffnen    }
function ClipClose:boolean;                     { Clipboard schlie·en }
function ClipEmpty:boolean;                     { Clipboard lîschen   }
function ClipCompact(desired:longint):longint;  { freien Platz ermitteln }
function ClipWrite(format:word; size:longint; var data):boolean;
function ClipGetDatasize(format:word):longint;
function ClipRead(format:word; var ldata):boolean;   { Daten lesen }
function Clip2String(maxlen,oneline:byte):string;  { Clipboardinhalt als String }

Procedure String2Clip(var ldata);                  { String ins Clipboard}

procedure FileToClip(fn:pathstr);
procedure ClipToFile(fn:pathstr);

{ procedure ClipTest; }                         {JG: Ausgeklammert }

{$IFDEF BP }
function  SmartInstalled:boolean;
function  SmartCache(drive:byte):byte;          { 0=nope, 1=read, 2=write }
function  SmartSetCache(drive,b:byte):boolean;  { 0=nope, 1=read, 2=write }
procedure SmartResetCache;
procedure SmartFlushCache;
{$ENDIF }

implementation  { ---------------------------------------------------- }

const
{$IFDEF BP }
  Multiplex = $2f;
{$ENDIF }
  maxfile   = 65520;

type  ca  = array[0..65530] of char;
      cap = ^ca;

{$IFDEF ver32}
function WinVersion:smallword;
begin
  {Unter Win32 ist das immer richtig }
{$IFDEF Win32 }
  WinVersion := 3;
{$ELSE }
  WinVersion := 0;
{$ENDIF }
end;     { Windows-Version abfragen }

{$IFDEF FPC }
  {$HINTS OFF }
{$ENDIF }

function ClipAvailable:boolean;
begin
  ClipAvailable := false;
end;     { wird Clipboard unterstÅtzt? }

function ClipOpen:boolean;
begin
  ClipOpen := false;
end;     { Clipboard îffnen }

function ClipClose:boolean;
begin
  ClipClose := true;
end;     { Clipboard schlie·en }

function ClipEmpty:boolean;
begin
  ClipEmpty := true;
end;     { Clipboard lîschen }

function ClipCompact(desired:longint):longint;
begin
  ClipCompact := 0;
end;  { Platz ermitteln }

function ClipWrite2(format:word; size:longint; var data):boolean;
begin
  ClipWrite2 := false;
end;
function ClipGetDatasize(format:word):longint;
begin
  ClipGetDataSize := 0;
end;

function ClipRead(format:word; var ldata):boolean;
begin
  ClipRead := false;
end;   { Daten lesen }

function Clip2String(maxlen,oneline:byte):string;
begin
  Clip2String := '';
end;  { Clipboardinhalt als String }

Procedure String2Clip(var ldata);                  { String ins Clipboard}
begin
end;

{$IFDEF FPC }
  {$HINTS ON }
{$ENDIF }

{$ELSE}

{JG:03.02.00 -  CLIP.ASM als Inline ASM Integriert }

function WinVersion:smallword;assembler;      { Windows-Version abfragen }
asm
              mov    ax,1600h
              int    Multiplex
              cmp    al,0
              jz     @NoWin
              cmp    al,20
              ja     @NoWin
              cmp    al,1
              jz     @Win386
              cmp    al,0ffh
              jz     @Win386
              xchg   al,ah
              jmp    @WinOk
@Win386:      mov    ax,200h
              jmp    @WinOk
@NoWin:       xor    ax,ax
@WinOk:
end;


function ClipAvailable:boolean; assembler;    { wird Clipboard unterstÅtzt? }
asm
              mov    ax,1700h
              int    multiplex
              sub    ax,1700h
              jz     @ca1
              mov    al,1
@ca1:
end;


function ClipOpen:boolean; assembler;         { Clipboard îffnen }
asm
              mov    ax,1701h
              int    multiplex
              or     ax,ax
              jz     @c1
              mov    ax,1
@c1:
end;


function ClipClose:boolean; assembler;        { Clipboard schlie·en }
asm
              mov    ax,1708h
              int    multiplex
              or     ax,ax
              jz     @c1
              mov    ax,1
@c1:
end;


function ClipEmpty:boolean; assembler;       { Clipboard lîschen }
asm
              mov    ax,1702h
              int    multiplex
              or     ax,ax
              jz     @c1
              mov    ax,1
@c1:
end;


function ClipCompact(desired:longint):longint; assembler;     { Platz ermitteln }
asm
              mov    ax,1709h
              mov    cx,word ptr desired
              mov    si,word ptr desired+2
              int    multiplex               { Ergebnis in DX:AX }
end;


function ClipWrite2(format:word; lsize:longint; var ldata):boolean; near; assembler;
asm
              mov    ax,1703h
              mov    dx,format
              mov    si,word ptr lsize+2
              mov    cx,word ptr lsize
              les    bx,ldata

              cmp    cx,0ffffh
              jne    @1
              dec    cx
@1:
              mov    di,cx
              mov    byte ptr es:[bx+di],0
              inc    cx

              int    multiplex
              or     ax,ax
              jz     @cw1
              mov    ax,1
@cw1:
end;



function ClipGetDatasize(format:word):longint; assembler;
asm
              mov    ax,1704h
              mov    dx,format
              int    multiplex         { liefert Ergebnis in DX:AX }
end;


function ClipRead(format:word; var ldata):boolean; assembler;   { Daten lesen }
asm
              mov    ax,1705h
              mov    dx,format
              les    bx,ldata
              int    multiplex
              or     ax,ax
              jz     @cr1
              mov    ax,1
@cr1:
end;


function Clip2String(maxlen,oneline:byte):String; assembler;  {JG:06.02.00 Jetzt String!}
{ JG: 3.2.00   Text aus Clipboard direkt als Pascal String uebergeben                    }
{              Maximallaenge, Einzeilig ( <>0: CR/LF wird in Space umgewandelt)  }

asm           les bx,@result
              mov word ptr es:[bx],0              { leerstring bei Fehler }

              mov ax,1700h                        { Clipboard verfuegbar ? }
              int multiplex
              cmp ax,1700h
              mov di,0                            { Clipb. nicht schliessen, wenn nicht da.}
              je @nope

              mov ax,1701h                        { Clipboard îffnen }
              int multiplex
              push ax                             { Aktuellen Clipboardstatus merken }

              mov ax,1704h                        { Datengroesse Ermitteln }
              mov dx,cf_Oemtext
              int multiplex                       { DX:AX }
              pop di                              { Clipboardstatus }

              cmp al,0                            { Abbruch bei }
              je @nope                            { leerem Testclipboard }
              or dl,ah
              cmp dx,0                            { oder mehr als 256 Zeichen }
              jne @nope

              les bx,@result
              inc bx
              push ax                             { Textlaenge, Start und   }
              push bx                             { Clipboardstatus sichern }
              push di

              mov ax,1705h                        { Text aus Clipboard anhaengen }
              mov dx,cf_Oemtext
              int multiplex

              pop di
              pop si                              { SI= Textstart }
              pop bx
              mov bh,0                            { BX=Textlaenge laut Windows }
              inc bx                              { ( gerundet auf 32Byte )    }

@@1:          dec bx
              cmp byte ptr es:[si+bx-1],' '       { Ab Textende Rueckwaerts }
              jb @@1                              { Fuell-Nullen und Steuerzeichen loeschen }

              cmp bl,maxlen                       { Stringlaenge auf Maximallaenge kuerzen }
              jna @1
              mov bl,maxlen
@1:           mov es:[si-1],bl

              cmp oneline,0                       { Wenn alles in eine Zeile soll... }
              je @bye
@@2:          cmp byte ptr es:[si+bx],' '         { Steuerzeichen in Spaces Umwandeln }
              jnb @@3
              mov byte ptr es:[si+bx],' '
@@3:          dec bx
              jns @@2
              jmp @bye

@nope:        mov ah,2                            { Fehler: }
              mov dl,7                            { BEEP }
              int 21h

@Bye:         cmp di,0                            { Wenn clipboard nicht auf war }
              je @jup
              mov ax,1708h                        { wieder schliessen }
              int multiplex
@jup:
end;



{JG:10.02.00 String ins Clipboard kopieren}

var dummystr:array[0..255] of char;

Procedure String2Clip(var ldata); assembler;
asm
              mov ax,1700h                        { Clipboard verfuegbar ? }
              int multiplex
              cmp ax,1700h
              je @end

              mov ax,1701h                        { Clipboard îffnen }
              int multiplex
              push ax                             { Aktuellen Clipboardstatus merken }

              mov ax,1702h
              int multiplex                       { Clipboard leeren}

              push ds
              push ds
              pop es
              mov di,offset dummystr
              lds si,ldata
              mov cl,ds:[si]
              xor ch,ch
              push cx              { StringlÑnge merken }
              inc si
              cld
              rep movsb            { String in Puffer kopieren ... }
              xor al,al
              stosb                { ... und #0 dranpappen }
              pop cx               { StringlÑnge restaurieren }
              pop ds

              push ds
              pop es
              mov bx,offset dummystr              {Textstart    -> es:bx}
              mov si,0                            {Stringlaenge -> si:cx}
              inc cx

              mov ax,1703h                        {String Ins Clipboard schreiben...}
              mov dx,cf_Oemtext                   {Als OEMTEXT}
              int multiplex

              pop ax
              or ax,ax                            { Wenn clipboard nicht auf war }
              je @end
              mov ax,1708h                        { wieder schliessen }
              int multiplex
@end:
end;

{$ENDIF}

{/JG}

function ClipWrite(format:word; size:longint; var data):boolean;  { Schreiben }
begin
  if ClipCompact(size)>=size then
    ClipWrite:=ClipWrite2(format,size,data)
  else
    ClipWrite:=false;
end;



procedure FileToClip(fn:pathstr);       { Dateiinhalt ins Windows-Clipboard schicken }
var f  : file;
    p  : pointer;
    bs : word;
    rr : word;
begin
  if ClipAvailable and ClipOpen then begin
    assign(f,fn);
    reset(f,1);
    if ioresult=0 then begin
      if maxavail>maxfile then bs:=maxfile
      else bs:=maxavail;
      getmem(p,bs);
      blockread(f,p^,bs,rr);
      close(f);
      if ClipEmpty then;
      if ClipWrite(cf_Oemtext,rr,p^) then;
      freemem(p,bs);
    end;
    if ClipClose then;
  end;
end;

procedure ClipToFile(fn:pathstr);       { Win-Clipboardinhalt als File speichern }
var f  : file;
    p  : cap;
    bs : longint;
    s  : string[40];
    bp : longint;
begin
  assign(f,fn);
  rewrite(f,1);
  if ioresult=0 then begin
    if ClipAvailable and ClipOpen then begin
      bs:=ClipGetDatasize(cf_OemText);
      if (bs>=maxfile) or (bs>=maxavail) then begin       { Passen wenn CLipboardinhalt }
        s:='Clipboard-Inhalt ist zu umfangreich'#13#10;   { groesser als Clipfile oder  }
        blockwrite(f,s[1],length(s));                     { freier Speicher ist         }
      end
      else if bs>0 then begin
        getmem(p,bs);
        if ClipRead(cf_Oemtext,p^) then begin
{
          bp:=bs;
          while (bp>0) and (p^[bp-1]=#0) do dec(bp);
}
          bp:=0;
          while (bp<bs) and (p^[bp]<>#0) do inc(bp);
          if (bp=bs) and (p^[bp]<>#0) then bp:=0;
          
          blockwrite(f,p^,bp);
        end;
        freemem(p,bs);
      end;
      if ClipClose then;
    end;
    close(f);
  end;
end;




{ JG:18.02.00 ausgeklammert, Prozedur wird nirgens benutzt.... }
(*
procedure ClipTest;
var s : string;

  procedure TestRead(ft:string; format:word);
  var l : longint;
      p : ^ca;
      i : integer;
  begin
    l:=ClipGetDatasize(format);
    if l>0 then begin
      writeln(ft,': ',l,' Bytes');
      if l<65530 then begin
        getmem(p,l);
        if ClipRead(format,p^) then
          for i:=0 to l-1 do
            write(p^[i]);
        freemem(p,l);
        end;
      writeln;
      end;
  end;

begin
  if not ClipAvailable then
    writeln('kein Clipboard vorhanden!')
  else
    repeat
      write('(l)esen, (s)chreiben, (d)atei-lesen, d(a)tei-schreiben, (e)nde >');
      readln(s);
      if s='l' then
        if ClipOpen then begin
          TestRead('Text',cf_Text);
          TestRead('Oemtext',cf_Oemtext);
          if ClipClose then;
          end
        else else
      if s='s' then begin
        write('Text> '); readln(s);
        if ClipOpen then begin
          if ClipEmpty then;
          if {ClipWrite(cf_Text,length(s),s[1]) and}
             ClipWrite(cf_Oemtext,length(s),s[1]) then;
          if ClipClose then;
          end
        end else
      if s='d' then begin
        write('Datei> '); readln(s);
        ClipToFile(s);
        end else
      if s='a' then begin
        write('Datei> '); readln(s);
        FileToClip(s);
        end;
    until s='e';
end;
*)

{$IFDEF BP }

{ Smartdrive vorhanden? }

function SmartInstalled:boolean;
var regs : registers;
begin
  with regs do begin
    ax:=$4a10;
    bx:=0;                { installation check }
    intr($2f,regs);
    SmartInstalled:=(ax=$BABE);
    end;
end;


{ Cache-Status abfragen }

function SmartCache(drive:byte):byte;          { 0=nope, 1=read, 2=write }
var regs : registers;
begin
  with regs do begin
    ax:=$4a10;
    bx:=3;
    bp:=drive;
    dl:=0;                { get status }
    intr($2f,regs);
    if (ax<>$BABE) or (dl=$ff) then
      SmartCache:=0
    else if dl and $40=0 then SmartCache:=2
    else if dl and $80=0 then SmartCache:=1
    else SmartCache:=0;
    end;
end;


{ Cache-Status setzen }

function SmartSetCache(drive,b:byte):boolean;  { 0=nope, 1=read, 2=write }
var regs : registers;
  procedure sfunc(nr:byte);
  begin
{$IFNDEF Ver32 }
    with regs do begin
      ax:=$4a10;
      bx:=3;
      bp:=drive;
      dl:=nr;
      intr($2f,regs);
      SmartSetcache:=(ax=$BABE) and (dl<>$ff);
      end;
{$ENDIF }
  end;
begin
  case b of
    0 : sfunc(2);          { turn off read cache }
    1 : begin
          sfunc(1);        { turn on read cache }
          sfunc(4);        { turn off write cache }
        end;
    2 : begin
          sfunc(1);        { turn on read cache }
          sfunc(3);        { turn on write cache }
        end;
  end;
end;


{ Schreib-Cache leeren }

procedure SmartResetCache; assembler;
asm
  mov ax, $4a10
  mov bx, 2
  int $2f
end;


{ Read-Cache-Inhalt verwerfen, Schreibcache leeren }

procedure SmartFlushCache; assembler;
asm
  mov ax, $4a10
  mov bx, 2
  int $2f
end;

{$ENDIF }

end.
{
  $Log: clip.pas,v $
  Revision 1.11  2001/06/18 20:17:15  oh
  Teames -> Teams

  Revision 1.10  2000/12/25 17:14:53  MH
  Fix Editor:
  - ^Kw F2 -> Clipboard funktionierte nicht

  Revision 1.9  2000/10/04 23:14:09  rb
  Bugfix

  Revision 1.8  2000/10/04 22:45:22  rb
  Bugfix

  Revision 1.7  2000/10/04 21:12:55  rb
  Bugfix

  Revision 1.6  2000/10/04 19:54:52  rb
  Bugfix

  Revision 1.5  2000/10/03 07:59:28  MH
  Clipboard angepasst

  Revision 1.4  2000/04/09 18:01:37  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.12  2000/03/14 15:15:34  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.11  2000/02/25 18:30:20  jg
  - Clip2string sauberer gemacht
  - Menues: STRG+A entfernt, STRG+V kann jetzt auch einfuegen

  Revision 1.10  2000/02/25 16:34:45  jg
  -Bugfix: Abbruch wenn Inhalt >64K, Clipboard schliessen

  Revision 1.9  2000/02/25 08:47:14  jg
  -Clip2String Bugfix zu rev1.8

  Revision 1.8  2000/02/25 07:55:35  jg
  -Clip2string konservativer geschrieben

  Revision 1.7  2000/02/24 16:21:52  jg
  -String2Clip konservativer geschrieben

  Revision 1.6  2000/02/18 18:39:03  jg
  Speichermannagementbugs in Clip.pas entschaerft
  Prozedur Cliptest in Clip.Pas ausgeklammert
  ROT13 aus Editor,Lister und XP3 entfernt und nach Typeform verlegt
  Lister.asm in Lister.pas integriert

  Revision 1.5  2000/02/17 16:14:19  mk
  MK: * ein paar Loginfos hinzugefuegt

}
