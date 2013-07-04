{ $Id: hex.pas,v 1.1 2001/07/11 21:18:54 rb Exp $ }

unit hex;

interface


{$ifdef virtualpascal}

{$h-}

type  integer      = longint;
      word         = longint;

{$endif}


function hexb (b: byte): string;
function hexw (w: word): string;
function hexl (l: longint): string;

implementation

function hexb (b: byte): string;
  const digit: array [0..15] of char = '0123456789ABCDEF';
  begin
    hexb := digit [b shr 4] + digit [b and $f];
  end;

function hexw (w: word): string;
  begin
    hexw := hexb (w shr 8) + hexb (w and $ff);
  end;

function hexl (l: longint): string;
  begin
    hexl := hexw (l shr 16) + hexw (l and $ffff);
  end;

end.


{
  $Log: hex.pas,v $
  Revision 1.1  2001/07/11 21:18:54  rb
  checkin


}
