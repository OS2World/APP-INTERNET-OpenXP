{ $Id: xp3pmisc.pas,v 1.3 2002/01/02 23:16:49 MH Exp $ }

unit xp3pmisc;

{$i asldefine.inc}

interface

const secsperday = 24 * 60 * 60;

function exist (d: string): boolean;
function exist_wild (d: string): boolean;
function dir_exist (d: string): boolean;
procedure errorhalt (s: string; errlev: byte);
procedure delspace (var s: string);
function firstchar (const s: string): char;
function lastchar (const s: string): char;
function num2str (num: longint; base, width: byte): string;
procedure appendtofile (n, s: string);
procedure logtofile (n, s: string);
procedure lostr (var s: shortstring);
procedure upstr (var s: shortstring);
function parcount (const s: string): integer;
function parstr (const s: string; nr: integer): string;
procedure writexy (x, y: integer; s: string);
function min (a, b: integer): integer;
function max (a, b: integer): integer;
function reps (c: char; n: integer): string;
procedure truncs (var s: string; n: integer);
function i1024 (n: integer): string;
function balkens (p, b: integer): string;
function getsecs: integer;
function testbool (s: string): boolean;

implementation

uses crt, dos;

function exist (d: string): boolean;
  var f: file;
  begin
    assign (f, d);
    {$i-} reset(f); {$i+}
    if ioresult = 0 then begin
      close (f);
      exist := true;
    end
    else exist := false;
  end;

function exist_wild (d: string): boolean;
  var sr: searchrec;
  begin
//    findfirst (d, readonly + hidden + sysfile + archive, sr);
    findfirst (d, archive, sr);
    exist_wild := doserror = 0;
    findclose (sr);
  end;

function dir_exist (d: string): boolean;
  var home: string;
  begin
    getdir (0, home);
    if (length (d) > 0) and (d [length (d)] = '\')
      then delete (d, length (d), 1);
    {$i-} chdir(d); {$i+}
    dir_exist := (ioresult = 0);
    chdir (home);
  end;

procedure errorhalt (s: string; errlev: byte);
  begin
    writeln (s);
    delay (1000);
    halt (errlev);
  end;

procedure delspace (var s: string);
  begin
    while (length (s) > 0) and ((s [1] = ' ') or (s [1] = #9))
      do delete (s, 1, 1);
    while (length(s) > 0) and ((s [length (s)] = ' ') or (s [length (s)] = #9))
      do delete(s, length (s), 1);
  end;

function firstchar (const s: string): char;
  begin
    if length (s) > 0 then firstchar := s [1] else firstchar := char (0);
  end;

function lastchar (const s: string): char;
  begin
    if length (s) > 0 then lastchar := s [length (s)] else lastchar := char (0);
  end;

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

procedure appendtofile (n, s: string);
  var f: text;
  begin
    assign (f, n);
    if exist (n) then append (f) else rewrite (f);
    writeln (f, s);
    flush (f);
    close (f);
  end;

procedure logtofile (n, s: string);
  var hr, mn, sec, sh,
      yr, mo, day, dow: word;
  begin
    gettime (hr, mn, sec, sh);
    getdate (yr, mo, day, dow);
    s := num2str (day, 10, 2) + '.' +
         num2str (mo, 10, 2) + '.' +
         num2str (yr, 10, 4) + ' ' +
         num2str (hr, 10, 2) + ':' +
         num2str (mn, 10, 2) + ':' +
         num2str (sec, 10, 2) + ' ' + s;
    appendtofile (n, s);
  end;

procedure lostr (var s: shortstring); {&uses ebx,edi} assembler;
  asm
    mov ebx,s
    movzx ecx,byte ptr [ebx]
    jecxz @lostr_ende
    mov edi,ecx
  @lostr_next:
    mov al,byte ptr [ebx+edi]
    cmp al,'A'
    jnae @lostr_weiter
    cmp al,'Z'
    jnbe @lostr_auml
    add byte ptr [ebx+edi],32
    jmp @lostr_weiter
  @lostr_auml:
    cmp al,'é'
    jne @lostr_ouml
    mov byte ptr [ebx+edi],'Ñ'
    jmp @lostr_weiter
  @lostr_ouml:
    cmp al,'ô'
    jne @lostr_uuml
    mov byte ptr [ebx+edi],'î'
    jmp @lostr_weiter
  @lostr_uuml:
    cmp al,'ö'
    jne @lostr_eacute
    mov byte ptr [ebx+edi],'Å'
    jmp @lostr_weiter
  @lostr_eacute:
    cmp al,'ê'
    jne @lostr_aring
    mov byte ptr [ebx+edi],'Ç'
    jmp @lostr_weiter
  @lostr_aring:
    cmp al,'è'
    jne @lostr_aelig
    mov byte ptr [ebx+edi],'Ü'
    jmp @lostr_weiter
  @lostr_aelig:
    cmp al,'í'
    jne @lostr_ntilde
    mov byte ptr [ebx+edi],'ë'
    jmp @lostr_weiter
  @lostr_ntilde:
    cmp al,'•'
    jne @lostr_ccedil
    mov byte ptr [ebx+edi],'§'
    jmp @lostr_weiter
  @lostr_ccedil:
    cmp al,'Ä'
    jne @lostr_weiter
    mov byte ptr [ebx+edi],'á'
  @lostr_weiter:
    dec edi
    jnz @lostr_next
  @lostr_ende:
  end;

procedure upstr (var s: shortstring); {&uses ebx,edi} assembler;
  asm
    mov ebx,s
    movzx ecx,byte ptr [ebx]
    jecxz @upstr_ende
    mov edi,ecx
  @upstr_next:
    mov al,byte ptr [ebx+edi]
    cmp al,'a'
    jnae @upstr_weiter
    cmp al,'z'
    jnbe @upstr_auml
    sub byte ptr [ebx+edi],32
    jmp @upstr_weiter
  @upstr_auml:
    cmp al,'Ñ'
    jne @upstr_ouml
    mov byte ptr [ebx+edi],'é'
    jmp @upstr_weiter
  @upstr_ouml:
    cmp al,'î'
    jne @upstr_uuml
    mov byte ptr [ebx+edi],'ô'
    jmp @upstr_weiter
  @upstr_uuml:
    cmp al,'Å'
    jne @upstr_eacute
    mov byte ptr [ebx+edi],'ö'
    jmp @upstr_weiter
  @upstr_eacute:
    cmp al,'Ç'
    jne @upstr_aring
    mov byte ptr [ebx+edi],'ê'
    jmp @upstr_weiter
  @upstr_aring:
    cmp al,'Ü'
    jne @upstr_aelig
    mov byte ptr [ebx+edi],'è'
    jmp @upstr_weiter
  @upstr_aelig:
    cmp al,'ë'
    jne @upstr_ntilde
    mov byte ptr [ebx+edi],'í'
    jmp @upstr_weiter
  @upstr_ntilde:
    cmp al,'§'
    jne @upstr_ccedil
    mov byte ptr [ebx+edi],'•'
    jmp @upstr_weiter
  @upstr_ccedil:
    cmp al,'á'
    jne @upstr_weiter
    mov byte ptr [ebx+edi],'Ä'
  @upstr_weiter:
    dec edi
    jnz @upstr_next
  @upstr_ende:
  end;

function parcount (const s: string): integer;
  var i, count: integer;
  begin
    count := 0;
    i := 1;
    repeat
      while (i <= length (s)) and (s [i] = ' ') do inc (i);
      if i <= length (s) then inc (count);
      while (i <= length (s)) and (s [i] <> ' ') do inc (i);
    until i > length (s);
    parcount := count;
  end;

function parstr (const s: string; nr: integer): string;
  var i, count: integer;
  begin
    parstr := '';
    if nr = 0 then exit;
    if nr > parcount (s) then nr := 1;
    count := 0;
    i := 1;
    repeat
      while (i <= length (s)) and (s [i] = ' ') do inc (i);
      if i <= length (s) then inc (count);
      if count = nr then break;
      while (i <= length (s)) and (s [i] <> ' ') do inc (i);
    until i > length (s);
    if count = nr then begin
      count := i;
      while (i <= length (s)) and (s [i] <> ' ') do inc (i);
      parstr := copy (s, count, i - count);
    end;
  end;

procedure writexy (x, y: integer; s: string);
  begin
    gotoxy (x, y);
    write (s);
  end;

function min (a, b: integer): integer;
  begin
    if a < b then min := a else min := b;
  end;

function max (a, b: integer): integer;
  begin
    if a > b then max := a else max := b;
  end;

function reps (c: char; n: integer): string;
  var s: string;
  begin
    n := min (n, 255);
    setlength (s, n);
    fillchar (s [1], n, c);
    reps := s;
  end;

procedure truncs (var s: string; n: integer);
  begin
    if length (s) > n then s := copy (s, 1, n);
  end;

function i1024 (n: integer): string;
  const vstr: array [0 .. 4] of char = ' KMGT';
  var i, j: integer;
      s: string;
  begin
    i := 0;
    j := 0;
    while n >= 1024 do begin
      inc (i);
      j := n mod 1024;
      n := n div 1024;
    end;
    if (i > 0)
      then if (n < 10)
        then s := ',' + num2str (j * 100 div 1024, 10, 1)
        else if (n < 100)
          then s := ',' + num2str (j * 10 div 1024, 10, 1)
          else s := ''
      else s := '';
    if i > 0 then i1024 := num2str (n, 10, 1) + s + vstr [i]
             else i1024 := num2str (n, 10, 1) + s;
  end;

function balkens (p, b: integer): string;
  begin
    balkens := reps ('€', b * p div 100) +
               reps ('∞', b - (b * p div 100));
  end;

function getsecs: integer;
  var h, m, s, s100: word;
  begin
    gettime (h, m, s, s100);
    getsecs := h * (60 * 60) + m * 60 + s;
  end;

function testbool (s: string): boolean;
  var v: shortstring;
  begin
    v := s;
    upstr (v);
    testbool := (v = 'ENABLED') or (v = 'J') or (v = 'JA') or
                (v = 'Y') or (v = 'YES');
  end;


end.


{
  $Log: xp3pmisc.pas,v $
  Revision 1.3  2002/01/02 23:16:49  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.2  2001/08/15 19:23:25  rb
  mm: Cursor verstecken, Anpassung an Parameterformat in BFG-Datei

  Revision 1.1  2001/07/11 19:47:20  rb
  checkin


}
