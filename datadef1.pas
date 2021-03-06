{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams.  }
{ Aenderungen des Sources, die vom OpenXP Team getaetigt wurden,  }
{ unterliegen den Rechten, die bis zum 09.04.2000 fuer das OpenXP }
{ Team gueltig waren.                                             }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: datadef1.pas,v 1.6 2002/01/05 09:13:29 mm Exp $ }

{ DATABASE.PAS - lokale Deklarationen }

{$I XPDEFINE.INC }

unit datadef1;

interface

uses xpglobal, dos, typeform, datadef;

const   db_magic  = 'DB1'^Z;
        eb_magic  = 'EB1'^Z;
        ix_magic  = 'IX1'^Z;
        nomagic   = #0#0#0#0;

        rflagDeleted = 1;     { Datensatz-Flag f�r gel�schten Satz }

        maxifelder= 7;        { maximale Anzahl Felder in einem Ind.-Key }
                              { f�r mehr ist Schl�ssel-Funktion n�tig    }
        dbdMaxSize= 51;
{$IFDEF Ver32 }
        maxcache  = 150;      { maximale Index-Cacheseiten }
{$ELSE }
        maxcache  = 60;
{$ENDIF }


type    proctype  = procedure;
        magictype = array[0..3] of char;
        barr      = array[0..32767] of byte;
        barrp     = ^barr;

        dbheader  = packed record
                      magic     : magictype;
                      recs      : longint;   { Anzahl phys. Datens�tze      }
                      nextinr   : longint;   { n�chste INT_NR               }
                      firstfree : longint;   { Nr. des ersten freien Satzes }
                      userflags : array[1..8] of smallword;
                      felder    : smallword; { Anzahl Datenfelder           }
                      recsize   : smallword; { phys. Record-Gr��e           }
                      hdsize    : smallword; { Header-Gr��e in Bytes        }
                      reccount  : longint;   { Anzahl Datens�tze            }
                      fill      : array[1..22] of byte;
                    end;

        dbfeld    = packed record          { Feld, physikalisch }
                      name      : dbFeldStr;
                      fill1     : array[1..5] of byte;
                      feldsize  : smallword;  { physikalisch in Bytes }
                      feldtyp   : byte;
                      nlen,nk   : byte;  { f�r numerische Werte/Formatierung }
                      fill2     : array[1..11] of byte;
                    end;

        ixheader  = packed record
                      magic     : magictype;
                      indizes   : smallword;
                      ixversion : byte;
                      fillbyte  : byte;
                      userflags : array[1..4] of smallword;
                      hdsize    : smallword;
                      fill      : array[1..14] of byte;
                    end;

        ixfeld    = packed record           { physikalischer Header-Eintrag }
                      feldanz   : byte;     { Anzahl der indizierten Felder }
                      fill1     : byte;     { +$80 -> Index-Funktion        }
                      ifeldnr   : array[1..maxifelder] of smallword; { +$8000 -> UStr! }
                      nn        : byte;     { Schl�ssel pro Knoten }
                      keysize   : byte;     { Schl�ssell�nge o. L�ngenbyte }
                      irecsize  : smallword;{ Knotengr��e          }
                      firstfree : longint;  { Datei-Offset         }
                      rootrec   : longint;
                      ifunc     : dbIndexFunc;  { intern: Index-Funktion }
                    end;

        ixfeldlist= array[1..1000] of ixfeld;
        ixfp      = ^ixfeldlist;

        { Achtung! Bei �nderungen an inodekey/indexnode auch    }
        { entsprechend in DATABASE.ASM und allocnode() �ndern!! }

        inodekey  = packed record
                      data    : longint;     { die zugeh�rige Satznr.   }
                      ref     : longint;     { Zeiger auf n�chsten Node }
                      keystr  : string[127]; { der Schl�ssel            }
                    end;
        indexnode = packed record           { logischer Index-Knoten   }
                      memsize  : smallword; { Gr�sse, f�r FreeMem      }
                      ksize,nk : byte;      { Schl�sselgr�sse/Anzahl   }
                      irsize   : smallword; { Index-Recordgr�sse, "    }
                      db_p     : DB;        { zugeh�rige DB, "         }
                      filepos  : longint;
                      anzahl   : integer16; { Anzahl eingetragener Schl�ssel }
                      key      : array[0..4] of inodekey;
                    end;
        inodep    = ^indexnode;

        { Achtung!! �nderungen an cachepage auch in DATABASE.ASM �ndern!! }

        cachepage = packed record
                      used     : boolean;  { 0 }
                      dbp      : DB;       { 1 }
                      ofs      : longint;  { 5 }
                      lasttick : longint;  { 9 }
                      page     : array[0..264*4+10] of byte;
                    end;
        icache    = array[0..maxcache-1] of cachepage;
        icachep   = ^icache;


        dbdheader = packed record
                      magic     : magictype;
                      hdsize    : smallword;
                      userflags : array[1..5] of smallword;
                      fill1     : array[1..16] of byte;
                      freelist  : array[0..dbdMaxSize] of longint;
                      fill2     : array[1..16] of byte;
                    end;

        dbrec     = record
                      fname     : dbFileName;
                      f1,fi,fe  : file;
                      hd        : dbheader;     { LAN: evtl. kritisch  }
                      hdupdate  : boolean;      { Header immer schreiben }
                      feldp     : dbFLP;        { Feldliste            }
                      recbuf,                   { Record-Buffer        }
                      orecbuf   : barrp;        { original-Inhalt      }
                      ixhd      : ixheader;
                      index     : ixfp;         { Liste der Indizes    }
                      xflag     : boolean;      { externe Datei vorh.  }
                      dbdhd     : dbdheader;
                      flindex   : boolean;      { Datenbank indiziert  }
                      flushed,
                      newrec    : boolean;
                      dEOF,dBOF : boolean;
                      recno     : longint;      { akt. Datensatz, ab 1 }
                      actindex  : smallword;
                      lastindex : smallword;    { wird bei dbSeek gesetzt }
                      tiefe     : byte;         { .. zum schrittweisen }
                      vpos      : array[1..20] of longint;   { Bewegen }
                      vx        : array[1..20] of integer8;
                      tempclosed: boolean;
                    end;
        dp        = ^dbrec;


const   lastioerror : integer = 0;
        mustfind    : boolean = true;
        cacheanz    : word    = 0;
        dl          : boolean = false;
        indexver    : byte    = 0;

var     ICP       : dbIndexCProc;     { Index-Kontrollprozedur     }
        found     : boolean;          { Ergebnis der letzten Suche }
        cache     : icachep;
        bb        : byte;             { lokal dbReadN/dbWriteN     }
        dblogfile : text;             { DB-Logfile                 }
        oldexit   : pointer;


function  iohandler:boolean;
procedure error(txt:string);
procedure writeinf(dbp:DB);
procedure writehd(dpb:DB);


implementation

uses database;


function iohandler:boolean;
begin
  lastioerror:=ioresult;
  if lastioerror<>0 then begin
    iohandler:=false;
    writeln('<DB> I/O-Fehler '+strs(lastioerror));
    halt(1);
    end;
  iohandler:=true;
end;


{ interner Fehler }

procedure error(txt:string);
begin
  writeln;
  writeln('<DB> interner Fehler: ',txt);
  if dbInterrProc<>nil then
    proctype(dbInterrProc);
  halt(1);
end;


procedure writeinf(dbp:DB);
begin
  with dp(dbp)^ do
    with hd do
      writeln('Satznr.: ',recno,'   Satzgr��e: ',recsize,'   S�tze: ',recs,
              '   Header: ',hdsize,'   Dateigr��e: ',filesize(f1));
end;


procedure writehd(dpb:DB);
begin
  with dp(dpb)^ do begin
    seek(f1,0);
    blockwrite(f1,hd,sizeof(hd));
    end;
end;

end.
{
  $Log: datadef1.pas,v $
  Revision 1.6  2002/01/05 09:13:29  mm
  - maxcache/IndexCache fuer 32Bit erhoeht
    (warum nich, vieleicht bringts ja was ;-) )
  - Sourceheader

  Revision 1.5  2000/04/10 22:13:04  rb
  Code aufger�umt

  Revision 1.4  2000/04/09 18:04:19  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.6  2000/03/17 11:16:33  mk
  - Benutzte Register in 32 Bit ASM-Routinen angegeben, Bugfixes

  Revision 1.5  2000/03/09 23:39:32  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.4  2000/03/06 08:51:04  mk
  - OpenXP/32 ist jetzt Realitaet

  Revision 1.3  2000/02/17 16:14:19  mk
  MK: * ein paar Loginfos hinzugefuegt

}
