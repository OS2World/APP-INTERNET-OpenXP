{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ (c) 2000 XP2 Team, weitere Informationen unter:                 }
{                   http://www.xp2.de                             }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xpcrc32.pas,v 1.6 2000/06/19 21:24:13 rb Exp $ }

{$I XPDEFINE.INC }

unit xpcrc32;

interface

uses xpglobal;

function crc32(st:string):longint;
function crc32block(var data; size:word):longint;
function crc32file(fn:string):longint;

implementation

VAR
   CRC_reg     : longint;

procedure CCITT_CRC32_calc_Block(var block; size: word);
                                {&uses ebx,esi,edi} assembler;  {  CRC-32  }
{$IFDEF BP }
asm
     mov bx, word ptr crc_reg
     mov dx, word ptr crc_reg+2
     les di, block
     mov si, size
     or si,si
     jz @u4
@u3: mov al, byte ptr es:[di]
     mov cx, 8
@u1: rcr al, 1
     rcr dx, 1
     rcr bx, 1
     jnc @u2
     xor bx, $8320
     xor dx, $edb8
@u2: loop @u1
     inc di
     dec si
     jnz @u3
     mov word ptr CRC_reg, bx
     mov word ptr CRC_reg+2, dx
@u4:
end;
{$ELSE }
asm
     mov ebx, crc_reg
     mov edi, block
     mov esi, size
     or esi,esi
     jz @u4
@u3: mov al, byte ptr [edi]
     mov ecx, 8
@u1: rcr al, 1
     rcr ebx, 1
     jnc @u2
     xor ebx, $edb88320
@u2: loop @u1
     inc edi
     dec esi
     jnz @u3
     mov CRC_reg, ebx
@u4:     
{$ifdef FPC }
end ['EAX', 'EBX', 'ECX', 'ESI', 'EDI'];
{$else}
end;
{$endif}
{$ENDIF }

function CRC32(st : string) : longint;
begin
  CRC_reg := 0;
  CCITT_CRC32_calc_Block(st[1], length(st));
  CRC32 := CRC_reg;
end;


function crc32block(var data; size:word):longint;
{type barr = array[0..65530] of byte;
var
  a : byte; }
begin
  CRC_reg := 0;
  CCITT_CRC32_calc_block(data, size);
  CRC32block := CRC_reg;
end;


function crc32file(fn:string):longint;
type barr = array[0..4095] of byte;
var
     f    : file;
     mfm  : byte;
     bp   : ^barr;
     rr : word;
begin
  assign(f,fn);
  mfm:=filemode; filemode:=$40;
  reset(f,1);
  filemode:=mfm;
  if ioresult<>0 then
    crc32file:=0
  else begin
    CRC_reg:=0;
    new(bp);
    while not eof(f) do
    begin
      blockread(f,bp^,sizeof(barr),rr);
      CCITT_CRC32_calc_block(bp^, rr)
    end;
    close(f);
    dispose(bp);
    CRC32file := CRC_reg;
  end;
end;


end.
{
  $Log: xpcrc32.pas,v $
  Revision 1.6  2000/06/19 21:24:13  rb
  Bugfixes, saubere 32 Bit Portierung

  Revision 1.5  2000/06/08 20:06:27  MH
  Teamname geandert

  Revision 1.4  2000/04/09 18:29:23  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.6  2000/03/24 20:25:50  rb
  ASM-Routinen gesÑubert, Register fÅr VP + FPC angegeben, Portierung FPC <-> VP

  Revision 1.5  2000/03/24 00:03:39  rb
  erste Anpassungen fÅr die portierung mit VP

  Revision 1.4  2000/03/17 11:16:34  mk
  - Benutzte Register in 32 Bit ASM-Routinen angegeben, Bugfixes

  Revision 1.3  2000/02/15 20:43:37  mk
  MK: Aktualisierung auf Stand 15.02.2000

}
