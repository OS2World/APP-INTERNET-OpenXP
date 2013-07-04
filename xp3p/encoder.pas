{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1998, 2000 by Robert B”ck                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Compilerdirektiven fr CrossPoint (OpenXP)                      }
{ --------------------------------------------------------------- }
{ $Id: encoder.pas,v 1.3 2002/01/12 10:36:22 MH Exp $ }

{$B-,D+,H-,I+,J+,P-,Q-,R-,S-,T-,V-,W-,X+,Z-}
{&AlignCode+,AlignData+,AlignRec-,Asm-,Cdecl-,Comments-,Delphi+,Frame+,G3+}
{&G5-,LocInfo+,Open32-,Optimise-,OrgName-,SmartLink-,Speed+,Use32-,ZD+}
{$M 32768}

unit encoder;

interface

type str90=string[90];
     tbytestream=array[0..63] of byte;

procedure encode_base64(var bytestream:tbytestream;len:word;
                        var encoded:str90);

procedure DecodeBase64(var s:string);

procedure encode_UU(var bytestream:tbytestream;len:word;
                    var encoded:str90);

implementation

type tbase64alphabet=array[0..63] of char;

const cbase64alphabet:tbase64alphabet=
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

procedure encode_base64(var bytestream:tbytestream;len:word;
                        var encoded:str90);
  var i,j,l:word;
      b:array[0..3] of byte;
  begin
    encoded:='';
    if len=0 then exit;
    for i:=len to sizeof(tbytestream)-1 do bytestream[i]:=0;
    l:=0;
    for i:=0 to (len-1) div 3 do begin
      inc(l,3);
      if l>len then l:=len;
      b[0]:=(bytestream[i*3] and $fc) shr 2;
      b[1]:=((bytestream[i*3] and $03) shl 4)
            or ((bytestream[i*3+1] and $f0) shr 4);
      b[2]:=((bytestream[i*3+1] and $0f) shl 2)
            or ((bytestream[i*3+2] and $c0) shr 6);
      b[3]:=bytestream[i*3+2] and $3f;
      for j:=0 to (l-1) mod 3+1 do
       encoded:=encoded+cbase64alphabet[b[j]];
      for j:=1 to 2-(l-1) mod 3 do
       encoded:=encoded+'=';
    end;
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
var b1,b2,b3,b4 : byte;
    p1,p2,pad   : byte;

  function nextbyte:byte;
  var p : byte;
  begin
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
    if s[length(s)]='=' then
      if s[length(s)-1]='=' then pad:=2
      else pad:=1
    else pad:=0;
    p1:=1; p2:=1;
    while p1<=length(s) do begin
      b1:=nextbyte;
      b2:=nextbyte;
      b3:=nextbyte;
      b4:=nextbyte;
      s[p2]:=chr(b1 shl 2 + b2 shr 4);
      s[p2+1]:=chr((b2 and 15) shl 4 + b3 shr 2);
      s[p2+2]:=chr((b3 and 3) shl 6 + b4);
      inc(p2,3);
    end;
    s[0]:=chr(p2-1-pad);
  end;
end;


procedure encode_UU(var bytestream:tbytestream;len:word;
                    var encoded:str90);
  var i,j:word;
      b:array[0..3] of byte;
  begin
    encoded:='';
    if len=0 then exit;
    for i:=len to sizeof(tbytestream)-1 do bytestream[i]:=0;
    for i:=0 to (len-1) div 3 do begin
      b[0]:=(bytestream[i*3] and $fc) shr 2;
      b[1]:=((bytestream[i*3] and $03) shl 4)
            or ((bytestream[i*3+1] and $f0) shr 4);
      b[2]:=((bytestream[i*3+1] and $0f) shl 2)
            or ((bytestream[i*3+2] and $c0) shr 6);
      b[3]:=bytestream[i*3+2] and $3f;
      for j:=0 to 3 do begin
        if b[j]=0 then b[j]:=64;
        encoded:=encoded+char(b[j]+32);
      end;
    end;
    encoded:=char(len+32)+encoded;
  end;

end.

{
 $Log: encoder.pas,v $
 Revision 1.3  2002/01/12 10:36:22  MH
 - SMTP-AUTH CRAM-MD5 funktioniert nun ebenso

 Revision 1.2  2002/01/05 14:04:23  MH
 - Tippfehler beseitigt
 - SmtpAuth (LOGIN) implementiert
 - APOP optimiert (ueberfluessigen Code entfernt)

}
