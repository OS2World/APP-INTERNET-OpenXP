{ ------------------------------------------------------------------------- }
{                     benoetigte Unit fuer XP2SOUP                          }
{                                                                           }
{            weitere Informationen siehe beiliegende README                 }
{ ------------------------------------------------------------------------- }


{ $Id: hex.pas,v 1.2 2000/06/01 21:01:07 tj Exp $ }

unit hex;

interface

function hb(b:byte):string;
function hw(w:word):string;
function hl(l:longint):string;
function hp(p:pointer):string;
function ha(var a):string;

implementation

function hb;
const h : string[16] = '0123456789abcdef';
var   s : string[2];
begin
        s[0]:=#2;
        s[1]:=h[b shr 4  +1];
        s[2]:=H[B and $f  +1];
        hb:=s
end;

function hw(w:word):string;
var s,t:string[2];
begin
  s := hb(w shr 8);
  t := hb(w and $ff);
  hw := s+t;
end;

function hl(l:longint):string;
var s,t:string[4];
begin
  s := hw(l shr 16);
  t := hw(l and $FFFF);
        hl:= s+t;
end;

function hp;
begin
  hp := hl(longint(p));
end;

function ha;
begin
  Ha := hw(seg(a))+':'+hw(ofs(a));
end;

end.

{
$Log: hex.pas,v $
Revision 1.2  2000/06/01 21:01:07  tj
kann nun compiliert werden :-)

Revision 1.1  2000/05/31 21:07:42  tj
auf dem CVS aufgespielt

}
