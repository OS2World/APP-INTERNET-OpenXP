{ ------------------------------------------------------------------------- }
{                     benoetigte Unit fuer XP2SOUP                          }
{                                                                           }
{            weitere Informationen siehe beiliegende README                 }
{ ------------------------------------------------------------------------- }

{ $Id: textfile.pas,v 1.2 2000/06/01 21:01:39 tj Exp $ }


unit textfile;

{$I xpdefine.inc}

interface

{$I-}

uses crt,strings,hex;

const BufSize=$4000;

type pchararray = ^chararray;
     chararray = array[0..BufSize] of char;

     pfile =^tfile;
     tfile = object
       {private} f   :file;
               buf :pchararray;
               pos :word;
{$IFDEF Ver32 }
               left:longint;
{$ELSE }
               left:word;
{$ENDIF }
               ef :boolean;
               filename:string;
               procedure ReadNextBlock;
               procedure NextChar;
       constructor Assign(name:string);
       destructor Close;
       procedure Reset;
       procedure ReadString(var s:string);
       procedure ReadPChar(pc:pchar);
{$IFDEF DOS }
       procedure BlockRead(p:pointer; size:word);
{$ELSE }
       procedure BlockRead(p:pointer; size:longint);
{$ENDIF }
       procedure Seek(p:longint);
       procedure Erase;
       procedure Rename(name:string);
       function EoF:boolean;
       function FileSize:longint;
     end;

{----------------------------------------------------------------------------}
implementation
{----------------------------------------------------------------------------}

constructor tfile.Assign;
begin
  system.assign(f,name);
  filename := name;
  getmem(buf,BufSize);
  fillchar(buf^,BufSize,#0);
  pos := 0;
end;

destructor tfile.close;
begin
  system.close(f);
  freemem(buf,BufSize);
end;

procedure tfile.Reset;
begin
  system.reset(f,1);
  pos := 0;
  ReadNextBlock;
end;

procedure tfile.ReadString;
var c:string;
begin
  s := '';
  while not (buf^[pos] in [#10,#13]) and
        (s[0] < #255) and
        not eof do begin
    s[ord(s[0])+1] := buf^[pos];
    inc(s[0]);                        {add char}
    NextChar;
  end;
  c:=buf^[pos];
  if not eof then NextChar;
  if (c=#13) and not eof and (buf^[pos] = #10) then NextChar;
end;

procedure tfile.ReadPChar;
var p:pchararray;
    x:word;
begin
  p := pchararray(pc);
  p^[0] := #0;
  x := 0;
  {writeln('pchar request: '+hw(pos)+'  left: '+hw(left));}
  while not (buf^[pos] in [#10,#13])and         (x < $f000) and
        not eof do begin
    if left = 0 then ReadNextBlock;
    if not eof then begin
      p^[x] := buf^[pos];
      inc(x);
      NextChar;
    end;
  end;
  if not eof then NextChar;
  if not eof and (buf^[pos] = #10) then NextChar;
  p^[x] := #0;
  {writeln('pchar done:    '+hw(pos)+'  left: '+hw(left));}
  {writeln(copy(Strpas(pchar(p)),1,30));}
end;


procedure tfile.BlockRead;
var pa:pchararray;
    x:word;
begin
  if size = 0 then exit;
  pa := pchararray(p);
  {writeln(filename);
  writeln('block request: '+hw(size)+'  pos: '+hw(pos)+'  left: '+hw(left));}
  if size <= left then begin
    {writeln('block ',hw(pos),'  ',hw(pos+size));}
    move(buf^[pos],p^,size);
    dec(left,size);
    inc(pos,size);
  end
  else begin
    x := 0;
    while (x < size) and not eof do begin
      if left <= (size-x) then begin
        {writeln('block ',hw(pos),'  ',hw(pos+left));}
        move(buf^[pos],pa^[x],left);
        inc(x,left);
        ReadNextBlock;
      end
      else begin
        {writeln('block ',hw(pos),'  ',hw(pos+size-x));}
        move(buf^[pos],pa^[x],(size-x));
        dec(left,size-x);
        inc(pos,size-x);
        inc(x,size-x);
      end;
    end;
  end;
  {writeln('block done:    '+hw(size)+'  pos: '+hw(pos)+'  left: '+hw(left));}
end;

procedure tfile.Erase;
begin
  system.erase(f);
end;

procedure tfile.Rename;
begin
  system.rename(f,name);
end;

procedure tfile.Seek;
begin
  system.seek(f,p);
  ReadNextBlock;
end;

function tfile.eof;
begin
  eof := ef;
end;

function tfile.filesize;
begin
  filesize := system.filesize(f);
end;

procedure tfile.NextChar;
begin
  if left <> 0 then begin
    inc(pos);
    dec(left);
  end;
  if left = 0 then ReadNextBlock;
  if left = 0 then ef := true;
end;

procedure tfile.ReadNextBlock;
begin
  {writeln('read block:    '+'  pos: '+hw(pos)+'  left: '+hw(left));}
  system.blockread(f,buf^,BufSize,left);
  pos := 0;
  ef := left=0;
end;

end.

{
$Log: textfile.pas,v $
Revision 1.2  2000/06/01 21:01:39  tj
kann nun compiliert werden :-)

Revision 1.1  2000/05/31 21:08:31  tj
auf dem CVS aufgespielt

}
