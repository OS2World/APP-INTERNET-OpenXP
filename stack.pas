{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: stack.pas,v 1.5 2000/04/10 22:13:06 rb Exp $ }

{ Allgemeiner Stapel }

{$I XPDEFINE.INC }

unit stack;

interface

uses xpglobal;

procedure spush(var x; size:word);
procedure spop(var x);


implementation

uses TypeForm;

type  stp = ^ste;
      ste = record
              inhalt : pointer;
              groesse: word;
              adr    : pointer;    { fÅr IntegritÑts-Test }
              next   : stp;
              last   : stp;
            end;

const tail : stp = nil;


procedure error(txt:string);
begin
  writeln('<Stack> ',txt);
  halt(1);
end;


procedure spush(var x; size:word);
var p : stp;
begin
  if maxavail<size+128 then
    error('Memory Overflow');
  new(p);
  if tail=nil then begin
    tail:=p;
    p^.next:=nil; p^.last:=nil;
    end
  else begin
    p^.last:=tail;
    p^.next:=nil;
    tail:=p;
    end;
  getmem(p^.inhalt,size);
  FastMove(x,p^.inhalt^,size);
  p^.groesse:=size;
  p^.adr:=@x
end;


procedure spop(var x);
var p : stp;
begin
  if tail=nil then
    error('Underflow');
  if @x<>tail^.adr then
    error('var mismatch');
  FastMove(tail^.inhalt^,x,tail^.groesse);
  freemem(tail^.inhalt,tail^.groesse);
  p:=tail;
  tail:=tail^.last;
  dispose(p);
end;


end.
{
  $Log: stack.pas,v $
  Revision 1.5  2000/04/10 22:13:06  rb
  Code aufgerÑumt

  Revision 1.4  2000/04/09 18:15:06  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.3  2000/02/19 11:40:07  mk
  Code aufgeraeumt und z.T. portiert

}