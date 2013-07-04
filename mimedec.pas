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
{ $Id: mimedec.pas,v 1.12 2002/04/18 23:36:59 rb Exp $ }

{$I XPDEFINE.INC }
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

UNIT mimedec;


INTERFACE

uses xpglobal,typeform;


const
  cs_iso8859_1  =    1;
  cs_iso8859_15 =   15;
  cs_win1252    = 1252;


procedure IBM2ISO(var s:string);
procedure IBMToIso1(var data; size:word);
procedure ISO2IBM(var s:string; const charset: word);
procedure Iso1ToIBM(var data; size:word);
procedure Mac2IBM(var data; size:word);
procedure UTF8ToIBM(var s:string);
procedure UTF7ToIBM(var s:string);
procedure convert_cs (var charset: string);
procedure CharsetToIBM(charset:string; var s:string);

procedure DecodeBase64(var s:string);

procedure UnQuotePrintable(var s:string; qprint,b64,add_cr_lf:boolean);
procedure MimeIsoDecode(var ss:string; maxlen:integer);

IMPLEMENTATION


const IBM2ISOtab : array[0..255] of byte =
      ( 32, 32, 32, 32, 32, 32, 32, 32, 32,  9, 10, 32, 12, 13, 32, 42,
        62, 60, 32, 33, 32,167, 95, 32, 32, 32, 32, 32, 32, 32, 32, 32,
        32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
        64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
        80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
        96, 97, 98, 99,100,101,102,103,104,105,106,107,108,109,110,111,
       112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,

       199,252,233,226,228,224,229,231,234,235,232,239,238,236,196,197,
       201,230,198,244,246,242,251,249,255,214,220,162,163,165, 80, 32,
       225,237,243,250,241,209,170,186,191, 43,172,189,188,161,171,187,
        32, 32, 32,124, 43, 43, 43, 43, 43, 43,124, 43, 43, 43, 43, 43,
        43, 43, 43, 43, 45, 43, 43, 43, 43, 43, 43, 43, 43, 45, 43, 43,
        43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 32, 32, 32, 32, 32,
        97,223, 71,182, 83,115,181,110,111, 79, 79,100,111,248, 69, 32,
        61,177, 62, 60,124,124,247, 61,176,183,183, 32,179,178,183, 32);

      ISO1_2IBMtab : array[128..255] of byte =
{128} (128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,
{144}  144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,
{160}   32,173,155,156,120,157,124, 21, 34, 67,166,174,170, 45, 82,223,
{176}  248,241,253,252, 39,230,227,249, 44, 49,167,175,172,171, 47,168,
{192}  133,160,131, 65,142,143,146,128,138,144,136,137,141,161,140,139,
{208}   68,165,149,162,147,111,153,120,237,151,163,150,154,121, 80,225,
{224}  133,160,131, 97,132,134,145,135,138,130,136,137,141,161,140,139,
{240}  100,164,149,162,147,111,148,246,237,151,163,150,129,121,112,152);

      ISO15_2IBMtab : array[128..255] of byte =  {164 = EUR}
{128} (128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,
{144}  144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,
{160}   32,173,155,156,164,157, 83, 21,115, 67,166,174,170, 45, 82,223,
{176}  248,241,253,252, 90,230,227,249,122, 49,167,175, 79,111, 89,168,
{192}  133,160,131, 65,142,143,146,128,138,144,136,137,141,161,140,139,
{208}   68,165,149,162,147,111,153,120,237,151,163,150,154,121, 80,225,
{224}  133,160,131, 97,132,134,145,135,138,130,136,137,141,161,140,139,
{240}  100,164,149,162,147,111,148,246,237,151,163,150,129,121,112,152);

      WIN1252_2IBMtab : array[128..255] of byte =  {128 = EUR}
{128} (128,129, 39,159, 34,133,134,135, 94,137, 83, 60,140,141, 90,143,
{144}  144, 39, 39, 34, 34,254, 45, 45,126,153,115, 62,156,157,122, 89,
{160}   32,173,155,156,120,157,124, 21, 34, 67,166,174,170, 45, 82,223,
{176}  248,241,253,252, 39,230,227,249, 44, 49,167,175,172,171, 47,168,
{192}  133,160,131, 65,142,143,146,128,138,144,136,137,141,161,140,139,
{208}   68,165,149,162,147,111,153,120,237,151,163,150,154,121, 80,225,
{224}  133,160,131, 97,132,134,145,135,138,130,136,137,141,161,140,139,
{240}  100,164,149,162,147,111,148,246,237,151,163,150,129,121,112,152);


     { Mac: éèÄê•ôö†ÖÉÑaÜáÇä àâ°çåã§¢ïìîo£óñÅ +¯õú˘·RCt'"!íO
             ÏÒÛÚùÎ‰„Ù„aoÍ_Ì  ®≠™˚ü˜^ÆØ__AAOOo --,"`'ˆ˛òY/x<>__
             +˙,"_AEAEEIIIIOO _OUUUi^~-_˙¯,",_
       fehlt: BE, DE, DF }
      Mac2IBMtab : array[128..255] of byte =
      (142,143,128,144,165,153,154,160,133,131,132, 97,134,135,130,138,
       136,137,161,141,140,139,164,162,149,147,148,111,163,151,150,129,
        43,248,155,156, 21,249, 20,225, 82, 67,116, 39, 34, 33,146, 79,
       236,241,243,242,157,230,235,228,227,227,244, 97,111,234, 32,237,
       168,173,170,251,159,247, 94,174,175, 32, 32, 65, 65, 79, 79,111,
        45, 45, 44, 32, 96, 39,246,254,152, 89, 47,120, 60, 62, 32, 32,
        43,250, 44, 32, 32, 65, 69, 65, 69, 69, 73, 73, 73, 73, 79, 79,
        32, 79, 85, 85, 85,105, 94,126, 45, 32,250,248, 44, 34, 44, 32);


type
  tCSRec = record
             MIMEName: string [40];
             Aliases: string [140];
           end;

const
  nr_charsets = 25;
  cs_aliases: array [1..nr_charsets] of tCSRec =
   (
(MIMEName: 'us-ascii';
 Aliases:  ';ansi_x3.4-1968;iso-ir-6;ansi_x3.4-1986;iso_646.irv:1991;ascii;iso646-us;us-ascii;us;ibm367;cp367;csascii;'),
(MIMEName: 'iso-8859-1';
 Aliases:  ';iso_8859-1:1987;iso-ir-100;iso_8859-1;iso-8859-1;latin1;l1;ibm819;cp819;csisolatin1;'),
(MIMEName: 'iso-8859-2';
 Aliases:  ';iso_8859-2:1987;iso-ir-101;iso_8859-2;iso-8859-2;latin2;l2;csisolatin2;'),
(MIMEName: 'iso-8859-3';
 Aliases:  ';iso_8859-3:1988;iso-ir-109;iso_8859-3;iso-8859-3;latin3;l3;csisolatin3;'),
(MIMEName: 'iso-8859-4';
 Aliases:  ';iso_8859-4:1988;iso-ir-110;iso_8859-4;iso-8859-4;latin4;l4;csisolatin4;'),
(MIMEName: 'iso-8859-6';
 Aliases:  ';iso_8859-6:1987;iso-ir-127;iso_8859-6;iso-8859-6;ecma-114;asmo-708;arabic;csisolatinarabic;'),
(MIMEName: 'iso-8859-6-e';
 Aliases:  ';iso_8859-6-e;csiso88596e;iso-8859-6-e;'),
(MIMEName: 'iso-8859-6-i';
 Aliases:  ';iso_8859-6-i;csiso88596i;iso-8859-6-i;'),
(MIMEName: 'iso-8859-7';
 Aliases:  ';iso_8859-7:1987;iso-ir-126;iso_8859-7;iso-8859-7;elot_928;ecma-118;greek;greek8;csisolatingreek;'),
(MIMEName: 'iso-8859-8';
 Aliases:  ';iso_8859-8:1988;iso-ir-138;iso_8859-8;iso-8859-8;hebrew;csisolatinhebrew;'),
(MIMEName: 'iso-8859-8-e';
 Aliases:  ';iso_8859-8-e;csiso88598e;iso-8859-8-e;'),
(MIMEName: 'iso-8859-8-i';
 Aliases:  ';iso_8859-8-i;csiso88598i;iso-8859-8-i;'),
(MIMEName: 'iso-8859-5';
 Aliases:  ';iso_8859-5:1988;iso-ir-144;iso_8859-5;iso-8859-5;cyrillic;csisolatincyrillic;'),
(MIMEName: 'iso-8859-9';
 Aliases:  ';iso_8859-9:1989;iso-ir-148;iso_8859-9;iso-8859-9;latin5;l5;csisolatin5;'),
(MIMEName: 'iso_8859-supp';
 Aliases:  ';iso_8859-supp;iso-ir-154;latin1-2-5;csiso8859supp;'),
(MIMEName: 'iso-8859-10';
 Aliases:  ';iso-8859-10;iso-ir-157;l6;iso_8859-10:1992;csisolatin6;latin6;'),
(MIMEName: 'macintosh';
 Aliases:  ';macintosh;mac;csmacintosh;'),
(MIMEName: 'ibm437';
 Aliases:  ';ibm437;cp437;437;cspc8codepage437;'),
(MIMEName: 'ibm850';
 Aliases:  ';ibm850;cp850;850;cspc850multilingual;'),
(MIMEName: 'iso-8859-14';
 Aliases:  ';iso-8859-14;iso-ir-199;iso_8859-14:1998;iso_8859-14;latin8;iso-celtic;l8;'),
(MIMEName: 'iso-8859-15';
 Aliases:  ';iso-8859-15;iso_8859-15;'),
(MIMEName: 'iso-8859-1-windows-3.0-latin-1';
 Aliases:  ';iso-8859-1-windows-3.0-latin-1;cswindows30latin1;'),
(MIMEName: 'iso-8859-1-windows-3.1-latin-1';
 Aliases:  ';iso-8859-1-windows-3.1-latin-1;cswindows31latin1;'),
(MIMEName: 'iso-8859-2-windows-latin-2';
 Aliases:  ';iso-8859-2-windows-latin-2;cswindows31latin2;'),
(MIMEName: 'iso-8859-9-windows-latin-5';
 Aliases:  ';iso-8859-9-windows-latin-5;cswindows31latin5;')
   );


{$IFDEF Ver32 } { MK 26.01.2000 Anpassungen an 32 Bit }
procedure IBM2ISO(var s:string); assembler; {&uses ebx, esi}
asm
     cld
     mov   ebx,offset IBM2ISOtab
     mov   esi,s
     lodsb                           { StringlÑnge }
     movzx ecx,al
     jecxz  @@2
@@1: lodsb
     xlat
     mov   [esi-1],al
     loop  @@1
@@2:
{$IFDEF FPC }
end ['EAX', 'EBX', 'ECX', 'ESI'];
{$ELSE }
end;
{$ENDIF }

{$ELSE }

procedure IBM2ISO(var s:string); assembler;
asm
     push  es
     cld
     mov   bx,offset IBM2ISOtab
     les   si,s
     segES lodsb                     { StringlÑnge }
     mov   cl,al
     xor   ch,ch
     jcxz  @@2
@@1: segES lodsb
     xlat
     mov   es:[si-1],al
     loop  @@1
@@2: pop   es
end;
{$ENDIF }


{$IFDEF ver32 }
procedure IBMToIso1(var data; size:word); assembler; {&uses ebx, edi}
asm
          mov    ecx,size
          jecxz  @noconv2
          mov    edi,data
          mov    ebx,offset IBM2ISOtab
          cld
@isolp2:  mov    al,[edi]
          xlatb
          stosb
          loop   @isolp2
@noconv2:
{$IFDEF FPC }
end ['EAX', 'EBX', 'ECX', 'EDI'];
{$ELSE }
end;
{$ENDIF }

{$ELSE }

procedure IBMToIso1(var data; size:word); assembler;
asm
          mov    cx,size
          jcxz   @noconv2
          les    di,data
          mov    bx,offset IBM2ISOtab
          cld
@isolp2:  mov    al,es:[di]
          xlat
          stosb
          loop   @isolp2
@noconv2:
end;
{$ENDIF }


{$IFDEF Ver32 } { MK 26.01.2000 Anpassungen an 32 Bit }
procedure ISO2IBM(var s:string; const charset: word); assembler; {&uses ebx, esi}
asm
     cld
     mov   eax,charset
     cmp   eax,cs_iso8859_15
     jne   @@cs1
     mov   ebx,offset ISO15_2IBMtab - 128
     jmp   @@cs99
@@cs1:
     cmp   eax,cs_win1252
     jne   @@cs2
     mov   ebx,offset WIN1252_2IBMtab - 128
     jmp   @@cs99
@@cs2:
     mov   ebx,offset ISO1_2IBMtab - 128
@@cs99:
     mov   esi,s
     lodsb                           { StringlÑnge }
     movzx ecx,al
     jecxz  @@2
@@1: lodsb
     cmp   al,127
     jbe   @@3
     xlat
     mov   [esi-1],al
@@3: loop  @@1
@@2:
{$IFDEF FPC }
end ['EAX', 'EBX', 'ECX', 'ESI'];
{$ELSE }
end;
{$ENDIF }

{$ELSE }

procedure ISO2IBM(var s:string; const charset: word); assembler;
asm
     push  es
     cld
     mov   ax,charset
     cmp   ax,cs_iso8859_15
     jne   @@cs1
     mov   bx,offset ISO15_2IBMtab - 128
     jmp   @@cs99
@@cs1:
     cmp   ax,cs_win1252
     jne   @@cs2
     mov   bx,offset WIN1252_2IBMtab - 128
     jmp   @@cs99
@@cs2:
     mov   bx,offset ISO1_2IBMtab - 128
@@cs99:
     les   si,s
     segES lodsb                     { StringlÑnge }
     mov   cl,al
     xor   ch,ch
     jcxz  @@2
@@1: segES lodsb
     cmp   al,127
     jbe   @@3
     xlat
     mov   es:[si-1],al
@@3: loop  @@1
@@2: pop   es
end;
{$ENDIF }


{$IFDEF ver32 }
procedure Iso1ToIBM(var data; size:word); assembler; {&uses ebx, edi}
asm
          mov    ecx,size
          jecxz  @noconv1
          mov    edi,data
          mov    ebx,offset ISO1_2IBMtab - 128
          cld
@isolp1:  mov    al,[edi]
          or     al,al
          jns    @ii1
          xlatb
@ii1:     stosb
          loop   @isolp1
@noconv1:
{$IFDEF FPC }
end ['EAX', 'EBX', 'ECX', 'EDI'];
{$ELSE }
end;
{$ENDIF }

{$ELSE }

procedure Iso1ToIBM(var data; size:word); assembler;
asm
          mov    cx,size
          jcxz   @noconv1
          les    di,data
          mov    bx,offset ISO1_2IBMtab - 128
          cld
@isolp1:  mov    al,es:[di]
          or     al,al
          jns    @ii1
          xlat
@ii1:     stosb
          loop   @isolp1
@noconv1:
end;
{$ENDIF }

procedure Mac2IBM(var data; size:word); {&uses ebx, esi} assembler;
asm
{$IFNDEF Ver32 }
          mov    bx,offset Mac2IBMtab - 128
          les    si,data
          mov    cx,size
          jcxz   @xende
          jmp    @xloop
@xloop:   mov    al,es:[si]
          inc    si
          cmp    al,127
          ja     @trans
          loop   @xloop
          jmp    @xende
@trans:   xlat
          mov    es:[si-1],al
          loop   @xloop
{$ELSE}
          mov    ebx,offset Mac2IBMtab - 128
          mov    esi,data
          mov    ecx,size
          jecxz  @xende
          jmp    @xloop
@xloop:   mov    al,[esi]
          inc    esi
          cmp    al,127
          ja     @trans
          loop   @xloop
          jmp    @xende
@trans:   xlat
          mov    [esi-1],al
          loop   @xloop
{$ENDIF}
@xende:
end;

procedure UTF8ToIBM(var s:string); { by robo; nach RFC 2279 }
  const sc_rest:string[6]='';
  var i,j,k:integer;
      sc:record case integer of
           0: (s:string[6]);
           1: (b:array[0..6] of byte);
         end;
      ucs:longint;
  begin
    if sc_rest<>'' then begin
      s:=sc_rest+s;
      sc_rest:='';
    end;
    for i:=1 to length(s) do if byte(s[i]) and $80=$80 then begin
      k:=0;
      for j:=0 to 7 do
        if byte(s[i]) and ($80 shr j)=($80 shr j) then inc(k) else break;
      sc.s:=copy(s,i,k);
      if length(sc.s)=k then begin
        delete(s,i,k-1);
        for j:=0 to k-1 do sc.b[1]:=sc.b[1] and not ($80 shr j);
        for j:=2 to k do sc.b[j]:=sc.b[j] and $3f;
        ucs:=0;
        for j:=0 to k-1 do ucs:=ucs or (longint(sc.b[k-j]) shl (j*6));
        if (ucs<$00000080) or (ucs>$000000ff) { nur Latin-1 }
          then s[i]:='?'
          else s[i]:=char(iso1_2ibmtab[byte(ucs)]);
      end
      else begin
        sc_rest:=sc.s;
        delete(s,i,length(sc.s));
        break;
      end;
    end;
  end;

procedure UTF7ToIBM(var s:string); { by robo; nach RFC 2152 }
  const b64alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  var i,j:integer;
      s1:string;
      ucs:smallword;
  begin
    i:=1;
    j:=posn('+',s,i);
    while j<>0 do begin
      i:=j;
      inc(j);
      while (j<=length(s)) and (pos(s[j],b64alphabet)<>0) do inc(j);
      if (j<=length(s)) and (s[j]='-') then inc(j);
      s1:=copy(s,i,j-i);
      delete(s,i,j-i);
      if s1='+-' then s1:='+'
      else begin
        if firstchar(s1)='+' then delfirst(s1);
        if lastchar(s1)='-' then dellast(s1);
        while (length(s1) mod 4<>0) do s1:=s1+'=';
        DecodeBase64(s1);
        if odd(length(s1)) then dellast(s1);
        j:=1;
        while length(s1)>j do begin
          ucs:=word(s1[j]) shl 8+word(s1[j+1]);
          if (ucs<$00000080)
            then s1[j]:=char(ucs)
            else if (ucs>$000000ff) { nur Latin-1 }
              then s1[j]:='?'
              else s1[j]:=char(iso1_2ibmtab[byte(ucs)]);
          inc(j);
          delete(s1,j,1);
        end;
      end;
      insert(s1,s,i);
      j:=posn('+',s,i+length(s1));
    end;
  end;

procedure convert_cs (var charset: string);
   var i: integer;
       cs: string;
   begin
     lostring (charset);
     cs := ';' + charset + ';';
     for i := 1 to nr_charsets do
       if pos (cs, cs_aliases [i].Aliases) > 0 then begin
         charset := cs_aliases [i].MIMEName;
         break;
       end;
   end;

procedure CharsetToIBM(charset:string; var s:string);
  begin
    convert_cs(charset);
    if charset='iso-8859-15' then ISO2IBM(s,cs_iso8859_15)
    else if left(charset,9)='iso-8859-' then ISO2IBM(s,cs_iso8859_1)
    else if charset='utf-8' then UTF8ToIBM(s)
    else if charset='utf-7' then UTF7ToIBM(s)
    else if charset='windows-1252' then ISO2IBM(s,cs_win1252)
    else if charset='' then ISO2IBM(s,cs_win1252);
  end;

procedure DecodeBase64(var s:string);
const b64tab : array[0..127] of byte =
               ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,63, 0, 0, 0,64,
                53,54,55,56,57,58,59,60,61,62, 0, 0, 0, 0, 0, 0,
                 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,
                16,17,18,19,20,21,22,23,24,25,26, 0, 0, 0, 0, 0,
                 0,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                42,43,44,45,46,47,48,49,50,51,52, 0, 0, 0, 0, 0);
      b64alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
var b1,b2,b3,b4 : byte;
    p1,p2,pad   : byte;
    i: integer;

  function nextbyte:byte;
  var p : byte;
  begin
    nextbyte:=0;
    if p1>length(s) then exit;
    repeat
      if s[p1]>#127 then p:=0
      else p:=b64tab[byte(s[p1])];
      inc(p1);
    until (p>0) or (p1>length(s));
    if p>0 then dec(p);
    nextbyte:=p;
  end;

begin
  if length(s)<4 then s:=''
  else begin
    for i:=1 to length(s) do if cpos(s[i],b64alphabet)=0 then exit;
    if s[length(s)]='=' then begin
      if s[length(s)-1]='=' then pad:=2
      else pad:=1;
      if length(s) mod 4<>0 then pad:=3;
    end
    else pad:=0;
    p1:=1; p2:=1;
    while p1<=length(s) do begin
      b1:=nextbyte; b2:=nextbyte; b3:=nextbyte; b4:=nextbyte;
      s[p2]:=chr(b1 shl 2 + b2 shr 4);
      s[p2+1]:=chr((b2 and 15) shl 4 + b3 shr 2);
      s[p2+2]:=chr((b3 and 3) shl 6 + b4);
      inc(p2,3);
    end;
    s[0]:=chr(p2-1-pad);
  end;
end;


procedure UnQuotePrintable(var s:string; qprint,b64,add_cr_lf:boolean);
                                       { MIME-quoted-printable/base64 -> 8bit }
var p,b     : byte;
    softbrk : boolean;

(*
  procedure AddCrlf; assembler; {&uses ebx}  { CR/LF an s anhÑngen }
  asm
{$IFNDEF Ver32 }
    mov bl,byte ptr s[0]
    mov bh,0
    cmp bx,255
    je  @@1
    inc bx
    mov byte ptr s[bx],13
    cmp bx,255
    je  @@1
    inc bx
    mov byte ptr s[bx],10
@@1:mov byte ptr s[0],bl
{$ELSE }
    movzx ebx,byte ptr s[0]
    cmp   ebx,255
    je    @@1
    inc   ebx
    mov   byte ptr s[ebx],13
    cmp   ebx,255
    je    @@1
    inc   ebx
    mov   byte ptr s[ebx],10
@@1:mov   byte ptr s[0],bl
{$ENDIF }
  end;
*)

begin
  if qprint then begin
    while (s<>'') and (s[length(s)]=' ') do    { rtrim }
      dec(byte(s[0]));
    softbrk:=(lastchar(s)='=');    { quoted-printable: soft line break }
    if softbrk then dellast(s);
    p:=cpos('=',s);
    if p>0 then
      while p<length(s)-1 do begin
        inc(p);
        b:=hexval(copy(s,p,2));
        if b>0 then begin
          s[p-1]:=chr(b);
          delete(s,p,2);
        end;
        while (p<length(s)) and (s[p]<>'=') do inc(p);
      end;
    if not softbrk then
      if add_cr_lf then {AddCrlf} s:=s+#13#10;
    end
  else if b64 then
    DecodeBase64(s)
  else
    if add_cr_lf then {AddCrlf} s:=s+#13#10;
end;

{ vollstÑndige RFC-1522-Decodierung }

procedure MimeIsoDecode(var ss:string; maxlen:integer);
var p1,p2,p,i : integer;
    lastEW,
    nextW     : integer;
    code      : char;
    s         : string;
    cset      : string[20];
begin
  for i:=1 to length(ss) do
    if ss[i]=#9 then ss[i]:=' ';

  cset:='';
  p1:=0;
  lastEW:=0;
  repeat
    repeat
      p1:=posn('=?',ss,p1+1);
      if p1>0 then begin
        p2:=p1+2;
        i:=0;
        while (i<3) and (p2<length(ss)) do begin
          if ss[p2]='?' then inc(i)
          else if ss[p2]=' ' then break;
          inc(p2);
        end;
        if (i<3) or (ss[p2]<>'=') then p2:=0 else dec(p2);
      end;
    until (p1=0) or (p2>0);

    if (p1>0) and (p2>0) then begin
      if (lastEW>0) and (lastEW<nextW) and (p1=nextW) then begin
        nextW:=nextW-lastEW;
        delete(ss,lastEW,nextW);
        dec(p1,nextW);
        dec(p2,nextW);
      end;
      s:=copy(ss,p1+2,p2-p1-2);
      delete(ss,p1,p2-p1+2);
      p:=cpos('?',s);
      if p>0 then begin
        cset:=lstr(left(s,p-1));
        delete(s,1,p);
        p:=cpos('?',s);
        if p=2 then begin
          code:=UpCase(s[1]);
          delete(s,1,2);
          case code of
            'Q' : begin
                    for i:=1 to length(s) do
                      if s[i]='_' then s[i]:=' ';
                    s:=s+'=';
                    UnquotePrintable(s,true,false,false);
                  end;
            'B' : UnquotePrintable(s,false,true,false);

          end;
        end;
      end;
      CharsetToIBM(cset,s);
      insert(s,ss,p1);
      lastEW:=p1+length(s);
      nextW:=lastEW;
      while (nextW<length(ss)) and (ss[nextW]=' ') do inc(nextW);
    end;
  until (p1=0) or (p2=0);

  if length(ss)>maxlen then ss[0]:=char(maxlen);
  if cset='' then CharsetToIBM('',ss);  { Default-decode wenn kein RFC1522 }
  for i:=1 to length(ss) do
    if ss[i]<' ' then ss[i]:=' ';
end;


end.

{
  $Log: mimedec.pas,v $
  Revision 1.12  2002/04/18 23:36:59  rb
  UnterstÅtzung fÅr IANA-Charset-Aliase

  Revision 1.11  2002/04/12 12:07:34  rb
  Default-Dekodierung von ISO-8859-1 auf Windows-1252 geÑndert

  Revision 1.10  2002/04/11 00:33:26  rb
  - Und noch ein MimeIsoDecode-Fix:
    Whitespace zwischen zwei direkt aufeinanderliegenden "encoded-word's"
    wird jetzt gemÑ· RFC 2047 entfernt.

  Revision 1.9  2002/04/10 22:46:25  rb
  - MimeIsoDecode abermals gefixt, kann jetzt beides dekodieren:
    Test =? RFC 1522 =?ISO-8859-1?Q?=E4=F6=FC?= hehe ?=
    wird zu
    Test =? RFC 1522 ÑîÅ hehe ?=
    und
    Test ?Q? =?ISO-8859-1?Q?=E4=F6=FC?= hoho
    wird zu
    Test ?Q? ÑîÅ hoho

  Revision 1.8  2002/03/20 23:10:26  rb
  Diverse Fixes fÅr DecodeBase64, teilweise von OpenXP Åbernommen

  Revision 1.7  2002/03/14 02:36:53  rb
  - Fix fÅr MimeIsoDecode:
    Test =? RFC 1522 =?ISO-8859-1?Q?=E4=F6=FC?= hehe ?=
    wurde nicht richtig dekodiert.
    Dekodiert sieht das so aus:
    Test =? RFC 1522 ÑîÅ hehe ?=

  Revision 1.6  2002/03/08 18:30:07  rb
  Fix fÅr UTF8-Dekodierung, wenn kodierter String umgebrochen ist. Idee: JG

  Revision 1.5  2002/03/08 17:42:26  rb
  Neue ZeichensÑtze: ISO-8859-15, Windows-1252

  Revision 1.4  2002/02/22 17:27:46  mm
  - MAC2IBM von ZFIDO nach Unit MIMEDEC verlagert

  Revision 1.3  2002/02/20 19:56:02  rb
  - MimeIsoDecode auch fÅr andere ZeichensÑtze
  - Iso1ToIBM und IBMToIso1 nach mimedec.pas verlagert
  - text/html wird von UUZ nicht mehr nach IBM konvertiert

  Revision 1.2  2002/02/19 12:38:22  mm
  Vertipper in ISO2IBM (Ver32) beseitigt: "exc -> ecx" ;-)

  Revision 1.1  2002/02/15 22:02:07  rb
  - einige Zeichenkonvertier- und Dekodierroutinen in neue Unit ausgelagert
  - RFC1522-Dekodierung fÅr Dateinamen von Attachments


}
