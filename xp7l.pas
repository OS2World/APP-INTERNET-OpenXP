{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xp7l.pas,v 1.7 2001/04/04 19:57:02 oh Exp $ }

{ lokale Deklarationen zu XP7.PAS }

{$i xpdefine.inc}

unit  xp7l;

interface

uses  xpglobal,typeform,xp0;

const MaggiFehler = 1;
      IdleTimeout = 5;
      nlfile      = 'netlog.tmp';

      forcepoll   : boolean = false;   { Ausschlu·zeiten ignorieren }

type NCstat = record
                datum              : string[DateLen];
                box                : string[BoxNameLen];
                starttime,conntime : DateTimeSt;
                conndate           : DateTimeSt;
                connsecs           : integer;
                connstr            : string[60];
                addconnects        : word;      { bei mehreren Fido- }
                logtime,waittime   : integer;   {    Anwahlversuchen }
                hanguptime         : integer;
                sendtime,rectime   : longint;
                sendbuf,sendpack   : longint;
                recbuf,recpack     : longint;
                endtime            : DateTimeSt;
                kosten             : real;
                abbruch            : boolean;
                telefon            : string[40];
              end;
     NCSptr = ^NCstat;

var  comnr     : byte;     { COM-Nummer; wg. Geschwindigkeit im Datensegment }
     NC        : NCSptr;
     ConnTicks : longint;
     outmsgs   : longint;  { Anzahl versandter Nachrichten }
     outemsgs  : longint;  { Anzahl mitgeschickter EPP-Nachrichten }
     outpmsgs  : longint;
     outepmsgs : longint;
     wahlcnt   : integer;  { Anwahlversuche }
     bimodem   : boolean;
     SysopMode : boolean;
     komment   : string[35];
     fidologfile: string[12];
     RfcLogFile: string[79];
    _turbo     : boolean;
    _uucp      : boolean;
    _ppp       : boolean;
    netlog     : textp;
    logopen    : boolean;
    in7e1,out7e1 : boolean;   { UUCP: Parity-Bit strippen/erzeugen }


implementation

end.

{
  $Log: xp7l.pas,v $
  Revision 1.7  2001/04/04 19:57:02  oh
  -Timeouts konfigurierbar

  Revision 1.6  2000/06/26 17:37:05  MH
  RFC/PPP: Pakete mitsenden:
  - Nicht versendete Nachrichten bleiben auf Unversandt und
    der Puffer wird entsprechend angepasst, falls einige
    Nachrichten versendet werden konnten
  - Netzanrufbericht sollte nun auch zusÑtzlich entstehendes
    Mailaufkommen berÅcksichtigen

  Revision 1.5  2000/06/18 08:31:44  MH
  RFC/PPP: LogFile kann vom Client f. Bericht beschrieben werden

  Revision 1.4  2000/06/02 10:08:12  MH
  RFC/PPP: LoginTyp hergestellt

  Revision 1.3  2000/05/25 23:26:27  rb
  Loginfos hinzugefÅgt

}
