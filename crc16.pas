{ $Id: crc16.pas,v 1.7 2002/01/24 21:41:07 mm Exp $ }

{$I XPDEFINE.INC }

{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

UNIT CRC16;


INTERFACE

uses xpglobal;
{ Note: Your crc variable must be initialized to 0, before       }
{       using tis routine.                                       }
{ Translated to Turbo Pascal (tm) V4.0 March, 1988 by J.R.Louvau }

{ crc auf 0 initialisieren! }

FUNCTION UpdCrc16(cp: BYTE; crc: smallWORD): smallWORD;
function _CRC16(var data; size:smallword):smallword;
{ Version f�r XP-FM.INC }
function _CRC16Ver2(var data; size:smallword):smallword;
function Crc16StrXP(s:string):smallword;
function Crc16Str(s:string):smallword;


IMPLEMENTATION

(* crctab calculated by Mark G. Mendel, Network Systems Corporation *)
CONST crctab: ARRAY[0..255] OF smallWORD = (
    $0000,  $1021,  $2042,  $3063,  $4084,  $50a5,  $60c6,  $70e7,
    $8108,  $9129,  $a14a,  $b16b,  $c18c,  $d1ad,  $e1ce,  $f1ef,
    $1231,  $0210,  $3273,  $2252,  $52b5,  $4294,  $72f7,  $62d6,
    $9339,  $8318,  $b37b,  $a35a,  $d3bd,  $c39c,  $f3ff,  $e3de,
    $2462,  $3443,  $0420,  $1401,  $64e6,  $74c7,  $44a4,  $5485,
    $a56a,  $b54b,  $8528,  $9509,  $e5ee,  $f5cf,  $c5ac,  $d58d,
    $3653,  $2672,  $1611,  $0630,  $76d7,  $66f6,  $5695,  $46b4,
    $b75b,  $a77a,  $9719,  $8738,  $f7df,  $e7fe,  $d79d,  $c7bc,
    $48c4,  $58e5,  $6886,  $78a7,  $0840,  $1861,  $2802,  $3823,
    $c9cc,  $d9ed,  $e98e,  $f9af,  $8948,  $9969,  $a90a,  $b92b,
    $5af5,  $4ad4,  $7ab7,  $6a96,  $1a71,  $0a50,  $3a33,  $2a12,
    $dbfd,  $cbdc,  $fbbf,  $eb9e,  $9b79,  $8b58,  $bb3b,  $ab1a,
    $6ca6,  $7c87,  $4ce4,  $5cc5,  $2c22,  $3c03,  $0c60,  $1c41,
    $edae,  $fd8f,  $cdec,  $ddcd,  $ad2a,  $bd0b,  $8d68,  $9d49,
    $7e97,  $6eb6,  $5ed5,  $4ef4,  $3e13,  $2e32,  $1e51,  $0e70,
    $ff9f,  $efbe,  $dfdd,  $cffc,  $bf1b,  $af3a,  $9f59,  $8f78,
    $9188,  $81a9,  $b1ca,  $a1eb,  $d10c,  $c12d,  $f14e,  $e16f,
    $1080,  $00a1,  $30c2,  $20e3,  $5004,  $4025,  $7046,  $6067,
    $83b9,  $9398,  $a3fb,  $b3da,  $c33d,  $d31c,  $e37f,  $f35e,
    $02b1,  $1290,  $22f3,  $32d2,  $4235,  $5214,  $6277,  $7256,
    $b5ea,  $a5cb,  $95a8,  $8589,  $f56e,  $e54f,  $d52c,  $c50d,
    $34e2,  $24c3,  $14a0,  $0481,  $7466,  $6447,  $5424,  $4405,
    $a7db,  $b7fa,  $8799,  $97b8,  $e75f,  $f77e,  $c71d,  $d73c,
    $26d3,  $36f2,  $0691,  $16b0,  $6657,  $7676,  $4615,  $5634,
    $d94c,  $c96d,  $f90e,  $e92f,  $99c8,  $89e9,  $b98a,  $a9ab,
    $5844,  $4865,  $7806,  $6827,  $18c0,  $08e1,  $3882,  $28a3,
    $cb7d,  $db5c,  $eb3f,  $fb1e,  $8bf9,  $9bd8,  $abbb,  $bb9a,
    $4a75,  $5a54,  $6a37,  $7a16,  $0af1,  $1ad0,  $2ab3,  $3a92,
    $fd2e,  $ed0f,  $dd6c,  $cd4d,  $bdaa,  $ad8b,  $9de8,  $8dc9,
    $7c26,  $6c07,  $5c64,  $4c45,  $3ca2,  $2c83,  $1ce0,  $0cc1,
    $ef1f,  $ff3e,  $cf5d,  $df7c,  $af9b,  $bfba,  $8fd9,  $9ff8,
    $6e17,  $7e36,  $4e55,  $5e74,  $2e93,  $3eb2,  $0ed1,  $1ef0
);

(*
 * updcrc derived from article Copyright (C) 1986 Stephen Satchell.
 *  NOTE: First argument must be in range 0 to 255.
 *        Second argument is referenced twice.
 *
 * Programmers may incorporate any or all code into their programs,
 * giving proper credit within the source. Publication of the
 * source routines is permitted so long as proper credit is given
 * to Stephen Satchell, Satchell Evaluations and Chuck Forsberg,
 * Omen Technology.
 *)

{$ifopt R+}
{$define rcheck}
{$R-}
{$else}
{$undef rcheck}
{$endif}

FUNCTION UpdCrc16(cp: BYTE; crc: smallWORD): smallWORD;
BEGIN { UpdCrc }
   UpdCrc16 := crctab[((crc SHR 8) AND 255)] XOR (crc SHL 8) XOR cp
END;


function _CRC16(var data; size:smallword):smallword;
type ba = array[0..65530] of byte;
var c16,i : smallword;
begin
  c16:=0;
  for i:=0 to size-1 do
    c16 := crctab[((c16 SHR 8) AND 255)] XOR (c16 SHL 8) XOR ba(data)[i];

  _CRC16:=c16;
end;

function _CRC16Ver2(var data; size:smallword):smallword;
type ba = array[0..65530] of byte;
var c16,i : smallword;
begin
  c16:=0;
  for i:=0 to size-1 do
    c16 := crctab[((c16 SHR 8) AND 255)] XOR (c16 SHL 8) XOR ba(data)[i];

  c16 := crctab[((c16 SHR 8) AND 255)] XOR (c16 SHL 8);
  c16 := crctab[((c16 SHR 8) AND 255)] XOR (c16 SHL 8);

  _CRC16Ver2:=c16;
end;

{$ifdef rcheck}
{$R+}
{$endif}

function Crc16StrXP(s:string):smallword;
begin
  Crc16StrXP:=_CRC16(s,length(s)+1);
end;

function Crc16Str(s:string):smallword;
begin
  Crc16Str:=_CRC16(s[1],length(s));
end;

end.
{
  $Log: crc16.pas,v $
  Revision 1.7  2002/01/24 21:41:07  mm
  Unit crc16 -> Overlay

  Revision 1.6  2000/12/01 00:09:36  rb
  VP $R+ Fix

  Revision 1.5  2000/05/25 23:33:39  rb
  Loginfos hinzugef�gt

  Revision 1.4  2000/04/09 18:02:00  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.5  2000/03/14 15:15:34  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.4  2000/03/07 23:41:06  mk
  Komplett neue 32 Bit Windows Screenroutinen und Bugfixes

  Revision 1.3  2000/02/17 16:14:19  mk
  MK: * ein paar Loginfos hinzugefuegt

}