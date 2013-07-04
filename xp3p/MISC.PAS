{ Unit MISC, (C) 1993,94 by Robert B”ck }

{ Funktion: verschiedene Routinen }
{ Autor: Robert B”ck }
{ geschrieben am:  25.04.1993 }
{ letzte Žnderung: ********** }
{ Sprache: Turbo Pascal 6.0 & VP}

{ $Id: MISC.PAS,v 1.1 2001/07/11 19:47:17 rb Exp $ }

unit misc;

{$i asldefine.inc}

interface

type pstring  = ^shortstring;
     tcharset = set of char;

const ch_ziffern : tcharset = ['0'..'9'];
      ch_alle    : tcharset = [#32..#255];

{
function bitrev(w,a:word):word;
}
{
function minw(a,b:word):word;
}

function num2str (num: longint; base, width: byte): string;
function wordstr(w:word;basis,laenge:byte):string;
function l2str (num: longint; width: byte): string;
function r2str (num: real; ges, nach: byte): string;

{
function compare(var v1,v2;vs:word):boolean;
}
{
function smsw:word;
}
{
function stringof(c:char;anz:byte):string;
}
function exist(d:string):boolean;
function dir_exist(d:string):boolean;
procedure errorhalt(s:string;errlev:byte);

{
function upcase(c:char):char;
}

procedure upstr (var s: shortstring);

{
function sortstr(s:string):string;
}
function upstrf(s:shortstring):string;
procedure delspace(var s:string);
procedure delspace_end(var s:string);

function strdelspace(p:pchar):pchar;

{
function stringtolong(var s:string):longint;
}
{
procedure newdelay(time:longint);
}
{
procedure mutate_fname(var p:string);
}
{
function ja_nein(s:string):boolean;
}
{
function getscancode:word;
}
{
function keypressed:boolean;
}

procedure clear_kbd_buffer;
function newstr(s: shortstring): pstring;
procedure disposestr(p: pstring);

{
procedure prop;
}
{
procedure xprop;
}

{$ifndef virtualpascal}
procedure get_os(var major,minor,oem:byte);
{$endif}

function get_os_string:string;

{$ifndef virtualpascal}
procedure idle(method:byte);
procedure os_idle;
{$endif}

{
procedure input(var s:string;z:tcharset;l:byte);
}

function warte(s:string;ticks:word;z:tcharset):char;

{
function get_crt_lines:byte;
}
{
function seconds_since_midnight:longint;
}

function whereami:string;

{
procedure getcursor(var a,e:byte);
}
{
procedure setcursor(a,e:byte);
}

{$ifndef virtualpascal}
var os2_aktiv:boolean;
{$endif}

implementation uses dos,hex,strings
{$ifdef virtualpascal}
,crt
{$endif}
;


const props     : array[0..3] of char = '-\|/';
      propp     : byte = 0;

{$ifndef virtualpascal}
var os_maj,os_min,os_oem:byte;
{$endif}

{
function bitrev(w,a:word):word; assembler;
  asm
    mov ax,word ptr [w]
    mov cx,word ptr [a]
    xor dx,dx
  @@bit1:
    rcr ax,1
    rcl dx,1
    loop @@bit1
    mov ax,dx
  end;

}
{

function minw(a,b:word):word; assembler;
  asm
    mov ax,[a]
    cmp ax,[b]
    jbe @@fertig
    mov ax,[b]
  @@fertig:
  end;
}


function num2str (num: longint; base, width: byte): string;
  const digit: array [0..15] of char = '0123456789ABCDEF';
  var s: string;
  begin
    s := '';
    repeat
      s := digit [num mod base] + s;
      num := num div base;
      if width > 0 then dec (width);
    until (width = 0) and (num = 0);
    num2str := s;
  end;

function wordstr(w:word;basis,laenge:byte):string;
  begin
    wordstr:=num2str(w,basis,laenge);
  end;

function l2str (num: longint; width: byte): string;
  var s: string;
  begin
    str(num:width,s);
    l2str:=s;
  end;

function r2str (num: real; ges, nach: byte): string;
  var s: string;
  begin
    str(num:ges:nach,s);
    r2str:=s;
  end;

{

function compare(var v1,v2;vs:word):boolean; assembler;
  asm
    push ds
    lds si,[v1]
    les di,[v2]
    mov cx,[vs]
    cld
    repe cmpsb
    jne @@1
    mov ax,1
    jmp @@2
@@1:
    xor ax,ax
@@2:
    pop ds
  end;
}
(*

function smsw:word; assembler;
  asm
    {$g+}
    smsw ax    { Store Machine Status Word in AX }
               { Bit 0=0 -> real mode, Bit 0=1 -> virtual mode }
  end;
*)
{

function stringof(c:char;anz:byte):string;
  var dummy:string;
  begin
    fillchar(dummy[1],anz,c);
    dummy[0]:=char(anz);
    stringof:=dummy;
  end;
}

function exist(d:string):boolean;
  var f:file;
  begin
    assign(f,d);
    {$i-} reset(f); {$i+}
    if ioresult=0 then begin
      close(f);
      exist:=true;
    end
    else exist:=false;
  end;

function dir_exist(d:string):boolean;
  var home:string;
  begin
    getdir(0,home);
    if (length(d)>0) and (d[length(d)]='\') then delete(d,length(d),1);
    {$i-} chdir(d); {$i+}
    dir_exist:=(ioresult=0);
    chdir(home);
  end;

procedure errorhalt(s:string;errlev:byte);
  begin
    writeln(s);
    warte('Weiter mit Return ...',546,[#13]);
    halt(errlev);
  end;

{

function upcase(c:char):char;
  begin
    if c='„' then upcase:='Ž'
    else if c='”' then upcase:='™'
    else if c='' then upcase:='š'
    else upcase:=system.upcase(c);
  end;
}
{
procedure upstr(var s:string);
  var i:word;
  begin
    for i:=1 to length(s) do s[i]:=upcase(s[i]);
  end;
}

{$ifdef virtualpascal}

procedure upstr (var s: shortstring); {&uses ebx,edi} assembler;
  asm
    mov ebx,s
    xor ecx,ecx
    mov cl,[ebx]
    jecxz @upstr_ende
    mov edi,ecx
  @upstr_next:
    cmp byte ptr [ebx+edi],'a'
    jnae @upstr_weiter
    cmp byte ptr [ebx+edi],'z'
    jnbe @upstr_uml_ae
    sub byte ptr [ebx+edi],32
    jmp @upstr_weiter
  @upstr_uml_ae:
    cmp byte ptr [ebx+edi],'„'
    jne @upstr_uml_oe
    mov byte ptr [ebx+edi],'Ž'
  @upstr_uml_oe:
    cmp byte ptr [ebx+edi],'”'
    jne @upstr_uml_ue
    mov byte ptr [ebx+edi],'™'
  @upstr_uml_ue:
    cmp byte ptr [ebx+edi],''
    jne @upstr_weiter
    mov byte ptr [ebx+edi],'š'
  @upstr_weiter:
    dec edi
    or edi,edi
    jnz @upstr_next
  @upstr_ende:
  end;

{$else}

procedure upstr (var s: shortstring); assembler;
  asm
    les bx,[s[0]]
    mov cl,es:[bx]
    xor ch,ch
    jcxz @upstr_ende
    mov di,cx
  @upstr_next:
    cmp byte ptr es:[bx+di],'a'
    jnae @upstr_weiter
    cmp byte ptr es:[bx+di],'z'
    jnbe @upstr_uml_ae
    sub byte ptr es:[bx+di],32
    jmp @upstr_weiter
  @upstr_uml_ae:
    cmp byte ptr es:[bx+di],'„'
    jne @upstr_uml_oe
    mov byte ptr es:[bx+di],'Ž'
  @upstr_uml_oe:
    cmp byte ptr es:[bx+di],'”'
    jne @upstr_uml_ue
    mov byte ptr es:[bx+di],'™'
  @upstr_uml_ue:
    cmp byte ptr es:[bx+di],''
    jne @upstr_weiter
    mov byte ptr es:[bx+di],'š'
  @upstr_weiter:
    dec di
    or di,di
    jnz @upstr_next
  @upstr_ende:
  end;

{$endif}

function upstrf(s:shortstring):string;
 begin
   upstr(s);
   upstrf:=s;
 end;

{

function sortstr(s:string):string;
  var i:word;
  begin
    upstr(s);
    i:=pos('Ž',s);
    while i>0 do begin
      delete(s,i,1);
      insert('AE',s,i);
      i:=pos('Ž',s);
    end;
    i:=pos('™',s);
    while i>0 do begin
      delete(s,i,1);
      insert('OE',s,i);
      i:=pos('™',s);
    end;
    i:=pos('š',s);
    while i>0 do begin
      delete(s,i,1);
      insert('UE',s,i);
      i:=pos('š',s);
    end;
    i:=pos('á',s);
    while i>0 do begin
      delete(s,i,1);
      insert('SS',s,i);
      i:=pos('á',s);
    end;
    sortstr:=s;
  end;
}

procedure delspace(var s:string);
  begin
    while (length(s)>0) and ((s[1]=' ') or (s[1]=#9)) do delete(s,1,1);
    while (length(s)>0) and ((s[length(s)]=' ') or (s[length(s)]=#9))
      do delete(s,length(s),1);
  end;

procedure delspace_end(var s:string);
  begin
    while (length(s)>0) and ((s[length(s)]=' ') or (s[length(s)]=#9))
      do delete(s,length(s),1);
  end;

function strdelspace(p:pchar):pchar;
  var q:pchar;
  begin
    q:=p;
    while ((q^=' ') or (q^=#9)) and (q^<>#0) do inc(q);
    strcopy(p,q);
    q:=strend(p);
    dec(q);
    while (q>=p) and ((q^=' ') or (q^=#9)) do dec(q);
    if q>=p then (q+1)^:=#0;
    strdelspace:=p;
  end;

{

function stringtolong(var s:string):longint;
  var l:longint;
      sign:boolean;
  begin
    delspace(s);
    l:=0;
    if (length(s)>0) and (s[1]='-') then begin
      sign:=true;
      delete(s,1,1);
    end
    else sign:=false;
    while (length(s)>0) and (s[1]>='0') and (s[1]<='9') do begin
      l:=10*l+(byte(s[1])-byte('0'));
      delete(s,1,1);
    end;
    if sign then l:=-l;
    stringtolong:=l;
  end;
}
{

procedure newdelay (time: longint); assembler;
  asm
    mov ax, 8301h
    int 15h
    mov ax, 8600h
    mov cx, word ptr [time+2]
    mov dx, word ptr [time]
    int 15h
  end;
}
{

procedure mutate_fname(var p:string);
  var d:dirstr;
      n:namestr;
      e:extstr;
      i:word;
  begin
    fsplit(p,d,n,e);
    i:=length(n);
    if i=0 then exit;
    i:=random(i)+1;
    n[i]:=char(random(26)+byte('A'));
    p:=d+n+e;
  end;
}
{

function ja_nein(s:string):boolean;
  var c:char;
  begin
    write(s);
    repeat
      c:=upcase(char(lo(getscancode)));
    until (c='J') or (c='N');
    write(c);
    ja_nein:=(c='J');
  end;
}

{$ifndef virtualpascal}
function getscancode:word; assembler;
  asm
    xor ah,ah
    int 16h
  end;

function keypressed:boolean; assembler;
  asm
    mov ah,1
    int 16h
    mov al,false
    jz @keypressed_end
    mov al,true
  @keypressed_end:
  end;
{$endif}

procedure clear_kbd_buffer;
  begin
{$ifdef virtualpascal}
    while keypressed do readkey;
{$else}
    while keypressed do getscancode;
{$endif}
  end;

function newstr(s: shortstring): pstring;
  var p: pstring;
  begin
    getmem(p, length(s) + 1);
    p^ := s;
    newstr := p;
  end;

procedure disposestr(p: pstring);
  begin
    if p <> nil then freemem(p, length(p^) + 1);
  end;

{

procedure prop;
  begin
    write(#8,props[propp]);
    propp:=(propp+1) and 3;
  end;
}
{

procedure xprop;
  begin
    if propp and 7=0 then write(#8,props[propp shr 3]);
    propp:=(propp+1) and 31;
  end;
}

{$ifndef virtualpascal}
procedure get_os(var major,minor,oem:byte); assembler;
  asm
    mov ax,3000h
    int 21h
    les di,[major]
    stosb
    les di,[minor]
    mov al,ah
    stosb
    les di,[oem]
    mov al,bh
    stosb
  end;
{$endif}

function get_os_string:string;
{$ifdef virtualpascal}
  begin
  {$ifdef os2}
    get_os_string:='OS/2';
  {$else}
   {$ifdef win32}
     get_os_string:='Win32';
   {$else}
    {$ifdef dpmi32}
      get_os_string:='DPMI32';
    {$else}
      get_os_string:='???';
    {$endif}
   {$endif}
  {$endif}
  end;
{$else}
  var major,minor,oem:byte;
      maj_str,min_str,oem_str:string;
  begin
    get_os(major,minor,oem);
    str(major,maj_str);
    str(minor,min_str);
    case oem of
      $00: oem_str:='IBM DOS';
      $01: oem_str:='Compaq DOS';
      $02: oem_str:='MS Packaged Product';
      $04: oem_str:='AT&T DOS';
      $05: oem_str:='ZDS (Zenith Electronics) DOS';
      $06: oem_str:='Hewlett-Packard DOS';
      $07: oem_str:='ZDS (Groupe Bull) DOS';
      $0D: oem_str:='Packard-Bell DOS';
      $16: oem_str:='DEC DOS';
      $23: oem_str:='Olivetti DOS';
      $28: oem_str:='Texas Instruments DOS';
      $29: oem_str:='Toshiba DOS';
      $33: oem_str:='Novell (Windows/386 device IDs only)';
      $34: oem_str:='MS Multimedia Systems (Windows/386 device IDs only)';
      $35: oem_str:='MS Multimedia Systems (Windows/386 device IDs only)';
      $4D: oem_str:='Hewlett-Packard DOS';
      $5E: oem_str:='RxDOS';
      $66: oem_str:='PhysTechSoft (PTS-DOS)';
      $99: oem_str:='General Software''s Embedded DOS';
      $EE: oem_str:='DR-DOS';
      $EF: oem_str:='Novell DOS';
      $FF: oem_str:='MS-DOS';
      else oem_str:='unknown OS (OEM ID='+num2str(oem,16,2)+'h)';
    end;
    if (major=10) and (oem=0) then
     get_os_string:='IBM OS/2 v1.'+min_str
    else if (major=20) and (minor<30) and (oem=0) then
     get_os_string:='IBM OS/2 v2.'+min_str
    else if (major=20) and (minor=30) and (oem=0) then
     get_os_string:='IBM OS/2 Warp 3'
    else if (major=20) and (minor=40) and (oem=0) then
     get_os_string:='IBM OS/2 Warp 4'
    else if (major=20) and (minor>40) and (oem=0) then
     get_os_string:='IBM OS/2 v'+maj_str+'.'+min_str
    else if (major=6) and (minor=0) and (oem=0) then
     get_os_string:='IBM DOS 6.1'
    else if (major=7) and (minor=0) and (oem=$FF) then
     get_os_string:='Win95'
    else if (major=7) and (minor=1) and (oem=$FF) then
     get_os_string:='Win95B oder Win98'
    else if (major=7) and (minor>1) and (oem=$FF) then
     get_os_string:='Win9x v'+maj_str+'.'+min_str
    else if (major=0) then
     get_os_string:='MS-DOS 1.'+min_str
    else
     get_os_string:=oem_str+' v'+maj_str+'.'+min_str;
  end;
{$endif}

{

INT 21 - DOS 2+ - GET DOS VERSION
        AH = 30h
---DOS 5+ ---
        AL = what to return in BH
            00h OEM number (as for DOS 2.0-4.0x)
            01h version flag
Return: AL = major version number (00h if DOS 1.x)
        AH = minor version number
        BL:CX = 24-bit user serial number (most versions do not use this)
---if DOS <5 or AL=00h---
        BH = MS-DOS OEM number (see #0619)
---if DOS 5+ and AL=01h---
        BH = version flag
            bit 3: DOS is in ROM
            other: reserved (0)
Notes:  the OS/2 v1.x Compatibility Box returns major version 0Ah (10)
        the OS/2 v2.x Compatibility Box returns major version 14h (20)
        OS/2 Warp 3.0 Virtual DOS Machines report v20.30.
        the Windows/NT DOS box returns version 5.00, subject to SETVER
        DOS 4.01 and 4.02 identify themselves as version 4.00; use
          INT 21/AH=87h to distinguish between the original European MS-DOS 4.0
          and the later PC-DOS 4.0x and MS-DOS 4.0x
        IBM DOS 6.1 reports its version as 6.00; use the OEM number to
          distinguish between MS-DOS 6.00 and IBM DOS 6.1 (there was never an
          IBM DOS 6.0)
        MS-DOS 6.21 reports its version as 6.20; version 6.22 returns the
          correct value
        the "Chicago" beta returns version 7.00 (reported in
          _Microsoft_Systems_Journal_, August 1994).
        DR-DOS 5.0 and 6.0 report version 3.31; Novell DOS 7 reports IBM v6.00,
          which some software displays as IBM DOS v6.10 (because of the version
          mismatch in true IBM DOS, as mentioned above)
        generic MS-DOS 3.30, Compaq MS-DOS 3.31, and others identify themselves
          as PC-DOS by returning OEM number 00h
        the version returned under DOS 4.0x may be modified by entries in
          the special program list (see #0874 at AH=52h); the version returned
          under DOS 5+ may be modified by SETVER--use AX=3306h to get the true
          version number
SeeAlso: AX=3000h/BX=3000h,AX=3306h,AX=4452h,AH=87h,INT 15/AX=4900h
SeeAlso: INT 2F/AX=122Fh,INT 2F/AX=4010h,INT 2F/AX=E002h

(Table 0619)
Values for DOS OEM number:
 00h    IBM
 01h    Compaq
 02h    MS Packaged Product
 04h    AT&T
 05h    ZDS (Zenith Electronics)
 06h    Hewlett-Packard
 07h    ZDS (Groupe Bull)
 0Dh    Packard-Bell
 16h    DEC
 23h    Olivetti
 28h    Texas Instruments
 29h    Toshiba
 33h    Novell (Windows/386 device IDs only)
 34h    MS Multimedia Systems (Windows/386 device IDs only)
 35h    MS Multimedia Systems (Windows/386 device IDs only)
 4Dh    Hewlett-Packard
 5Eh    RxDOS
 66h    PhysTechSoft (PTS-DOS)
 99h    General Software's Embedded DOS
 EEh    DR-DOS
 EFh    Novell DOS
 FFh    Microsoft, Phoenix

}

{$ifndef virtualpascal}
procedure idle(method:byte);
  begin
    case method of
      1 : asm                { /OS2a } { BIOS-WAIT Funktion mit 1 æs }
            mov ah,086h
            xor cx,cx
            mov dx,1
            int 015h
          end;
      2 : asm                { /OS2b }
            int 028h
          end;
      3 : inline($b8/$00/$00/$99/$fb/$f4/$35/$ca/$90);   { /OS2c }
      4 : asm                { /OS2d }
            mov ax,01680h
            int 02fh
          end;
     10 : asm                { DesqView }
            mov ax,01000h
            int 015h
          end;
    end;
  end;
{$endif}

{

INT 2F - MS Windows, DPMI, various - RELEASE CURRENT VIRTUAL MACHINE TIME-SLICE
        AX = 1680h
Return: AL = status
            00h if the call is supported
            80h (unchanged) if the call is not supported
Notes:  programs can use this function in idle loops to enhance performance
          under multitaskers; this call is supported by MS Windows 3.0, DOS 5+,
          DPMI 1.0+, and in OS/2 2.0+ for multitasking DOS applications
        does not block the program; it just gives up the remainder of the time
          slice
        should not be used by Windows-specific programs
        when called very often without intermediate screen output under WIN 3+,
          the VM will go into an idle-state and will not receive the next slice
          before 8 seconds. This time can be changed in SYSTEM.INI through
          "IdleVMWakeUpTime=<seconds>". Setting to zero results in a long wait.
SeeAlso: INT 15/AX=1000h,INT 15/AX=5305h,INT 21/AH=89h,INT 7A/BX=000Ah

}

{$ifndef virtualpascal}
procedure os_idle;
  begin
    if os2_aktiv then begin
      if os_min=30 then idle(3)
      else if os_min=40 then idle(4)
      else idle(1);
    end;
  end;
{$endif}

{

procedure input(var s:string;z:tcharset;l:byte);
  var sh,sl:byte;
      sc:word absolute sl;
  begin
    write(s);
    repeat
      sc:=getscancode;
      if sl>0 then begin
        if char(sl) in z then begin
          if length(s)<l then begin
            s:=s+char(sl);
            write(char(sl));
          end;
        end
        else if sl=8 then begin
          if length(s)>0 then begin
            dec(s[0]);
            write(^h' '^h);
          end;
        end;
      end;
    until sl=13;
  end;
}

{$ifndef virtualpascal}
var timeout:word;
    old1c:pointer;

procedure new_int1c; interrupt; assembler;
  asm
    pushf
    call dword ptr [old1c]
    cmp [timeout],0
    jz @new1c_end
    dec [timeout]
  @new1c_end:
  end;
{$endif}

function warte(s:string;ticks:word;z:tcharset):char;
{$ifdef virtualpascal}
  var rest,arest:longint;
      ch:char;
  begin
    clear_kbd_buffer;
    ch:=#0;
    arest:=ticks*55;
    repeat
      rest:=arest div 1000;
      write(#13,s,' [',wordstr(rest div 60,10,2),':',
            wordstr(rest mod 60,10,2),'] ');
      delay(1000);
      dec(arest,1000);
      if keypressed then ch:=readkey;
      if not (ch in z) then ch:=#0 else if ch>=#32 then write(ch);
    until (ch<>#0) or (arest<1000);
    clear_kbd_buffer;
    warte:=ch;
  end;
{$else}
  var rest,arest:longint;
      ch:char;
  begin
    getintvec($1c,old1c);
    setintvec($1c,@new_int1c);
    timeout:=ticks;
    clear_kbd_buffer;
    ch:=#0;
    arest:=0;
    repeat
      repeat
        rest:=trunc((longint(timeout+17) * 100) div 1820);
        os_idle;
      until (rest<>arest) or keypressed;
      arest:=rest;
      write(#13,s,' [',wordstr(rest div 60,10,2),':',
            wordstr(rest mod 60,10,2),'] ');
      if keypressed then ch:=char(lo(getscancode));
      if not (ch in z) then ch:=#0 else if ch>=#32 then write(ch);
      os_idle;
    until (ch<>#0) or (timeout=0);
    clear_kbd_buffer;
    warte:=ch;
    setintvec($1c,old1c);
  end;
{$endif}

(*

function get_crt_lines:byte;
  var monit:byte absolute $40:$88;
      graka:byte absolute $40:$a8;
      zeil:byte;
  begin
    if (monit=249) and (graka<>0) then begin
      asm
        mov ah,11h
        mov al,30h
        mov bl,00h
        push bp
        int 10h
        pop bp
      { mov [zeichenhoehe],cx }
        inc dl
        mov [zeil],dl
      end;
    end
    else zeil:=25;
    get_crt_lines:=zeil;
  end;
*)
(*

function seconds_since_midnight:longint;
  var bios_ticker:longint absolute $0040:$006C;
  const ticks_per_day  = $1800b0  {=1573040} div 80;
        seconds_per_day= 24*60*60 {=  86400} div 80;
  begin
    seconds_since_midnight:=
     bios_ticker*seconds_per_day div ticks_per_day;
  end;
*)

function whereami:string; { far; }
{$ifdef virtualpascal}
  var wadr:longint;
  begin
    asm
      mov eax,[ebp+4]
      mov wadr,eax
    end;
    whereami:=hexl(wadr);
  end;
{$else}
  var wseg,wofs:word;
  begin
    asm
      mov ax,[bp+2]
      mov bx,[bp+4]
      mov wofs,ax
      mov wseg,bx
    end;
    whereami:=hexw(wseg-prefixseg-$10)+':'+hexw(wofs);
  end;
{$endif}
{

procedure getcursor(var a,e:byte); assembler;
  asm
    mov ah,3
    xor bh,bh
    int 10h
    les bx,[a]
    mov es:[bx],ch
    les bx,[e]
    mov es:[bx],cl
  end;
}
{

procedure setcursor(a,e:byte); assembler;
  asm
    mov ah,1
    mov ch,[a]
    mov cl,[e]
    int 10h
  end;
}

{$ifndef virtualpascal}
begin
  randomize;
  get_os(os_maj,os_min,os_oem);
  os2_aktiv:=((os_maj=20) or (os_maj=10)) and (os_oem=0);
{$endif}
end.


{
  $Log: MISC.PAS,v $
  Revision 1.1  2001/07/11 19:47:17  rb
  checkin


}
