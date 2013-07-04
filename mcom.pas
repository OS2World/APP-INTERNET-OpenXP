UNIT mCom;


{-----------------------------------------------------------------------------}
{       mCom/2 Pascal Unit fuer Virtual Pascal - Lizenshinweis !!!            }
{-----------------------------------------------------------------------------}
{                                                                             }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.                           }
{ (c) 1997-2000 Torsten W.Jaehnigen                                           }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.                 }
{                                                                             }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der             }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.               }

{ $Id: mcom.pas,v 1.2 2000/05/25 23:07:56 rb Exp $ }


{
        Autor Urversion       : Torsten JÑhnigen
        Autor letzte énderung : Torsten JÑhnigen
        Datum                 : 20.05.1997
        letzte énderung       : 08.01.2000
        Hinweis               : H_RING funktioniert _nicht_ in
                                Verbindung mit cFOS oder aktiven
                                ISDN GerÑten, wie das Elsa Mirco-
                                link TL/v34. Ausnahmen bestÑtigen
                                die Regel ;-)
        Bemerkung             : Portiert von Speedpascal auf Virtual Pascal
                                fuer die Portation von XP auf OS/2....
}


interface

         function  com_open  (port : byte) : boolean;
         procedure com_close;
         procedure set_bps   (bps : longint);
         procedure set_handle(databits,parity,stopbits : byte);
         procedure com_write (ch : char);
         procedure set_rts (bool : boolean);
         procedure set_dtr (bool : boolean);
         procedure dump;
         function  com_read  : pchar;
         function  com_empty : boolean;
         function  get_bps   : longint;
         function  carrier   : boolean;
         function  h_ring    : boolean;
         function  dsr       : boolean;
         function  cts       : boolean;
         function  get_dtr   : boolean;
         function  get_rts   : boolean;



implementation

uses dos,os2base,os2def;

const
     ComFlags=OPEN_ACCESS_READWRITE+OPEN_SHARE_DENYREADWRITE+OPEN_FLAGS_FAIL_ON_ERROR;

type
    TFixedBaud = RECORD
                 Baud     : LONGINT;
                 Fraction : BYTE;
    end;

type
    TLineCtrl  = RECORD
                 DataBits    : BYTE;
                 Parity      : BYTE;
                 StopBits    : BYTE;
                 TransBreak  : BYTE;
    end;

type
    TQueueCount = RECORD
                  Count,
                  Size   :WORD;
    end;

type
    TFixedBaudInfo=RECORD
                   Current,
                   Minimum,
                   Maximum   : TFixedBaud;
    end;

var
   s         : string;
   cstr      : PCHAR;
   ComHandle : LHandle;
   action    : LONGINT;
   i         : integer;

function com_open (port : byte) : boolean;

begin
      com_open:=true;
      str(Port,s);
      s:='COM'+s;
      for i:=1 to length(s) do
        cstr[i]:=s[i];
      cstr[i+1]:=#0;
      IF DosOpen(cstr,             // Dateiname
                 ComHandle,        // Dateihandle fÅr spÑtere Zugriffe
                 action,           // Dateiaktion, die geschehen ist
                 0,                // keine Dateigrî·e
                 0,                // und keine Attribute setzen
                 FILE_OPEN,        // Datei nur îffnen
                 ComFlags,         // Flags siehe oben
                 nil)>0            // keine EAs
      THEN com_open:=false;
end; {com_open}

{Das erhaltene ComHandle wird fÅr den weiteren Zugriff benîtigt, und sollte daher gut
 gesichert werden (z.B. in einer globalen Variable).

 Bemerkung: Das ComHandle wurde exklusiv geîffnet (OPEN_SHARE_DENYREADWRITE).
 Deshalb darf dieser COM-Port kein zweites mal geîffnet werden. Man sollte also einen
 COM-Port erst unmittelbar vor einer (erwarteten) DatenÅbertragung îffnen und sofort danach
 wieder schlie·en. OS/2 ist ein Multitasking-Betriebsystem.
 Der User kînnte also - wÑhrend ihre Anwendung lÑuft - ein anderes Programm starten,
 welches den selben COM-Port benîtigt * , den ihre Anwendung gerade unnîtig blockiert!   }

procedure com_close;

begin
     dosclose(comhandle);
end; {com_close}

procedure set_bps(bps : longint);

var
   ParamPaket  : TFixedBaud;
   R           : APIRET;

begin
      parampaket.fraction:=0;
      parampaket.baud:=bps;
      R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                     IOCTL_ASYNC,                 // Kategorie
                     $43,                         // Funktionsnummer
                     @ParamPaket,                 // Parameterpaket
                     SizeOf(ParamPaket),          // Grî·e des Parameterpaketes
                     NIL,
                     NIL,                         // Datenpaket
                     0,                           // Grî·e des Datenpaketes
                     NIL);
end; {set_bps}

procedure set_handle(databits,parity,stopbits : byte);

var
   ParamPaket : TLineCtrl;
   R          : APIRET;

begin
      parampaket.transbreak:=0;
      parampaket.databits:=databits;
      parampaket.parity:=parity;
      parampaket.stopbits:=stopbits;
      R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                     IOCTL_ASYNC,                 // Kategorie
                     ASYNC_SETLINECTRL,           // Funktionsnummer
                     @ParamPaket,                  // Parameterpaket
                     SizeOf(ParamPaket),          // Grî·e des Parameterpaketes
                     NIL,
                     NIL,                         // Datenpaket
                     0,                           // Grî·e des Datenpaketes
                     NIL);
end; {set_handle}

procedure com_write(ch : char);

var
   r       : APIRET;
   written : ulong;

begin
     r:=DosWrite (ComHandle, ch, 1, Written);
end; {com_write}

function com_read : pchar;

var
   r      : APIRET;
   read   : ulong;
   ch     : pchar;

begin
     ch:=#0;
     r:=DosRead (ComHandle, ch, 1, read);
     com_read:=ch;
end; {com_read}

function com_empty : boolean;

var
   DataPaket : TQueueCount;
   R         : APIRET;

begin
     R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                    IOCTL_ASYNC,                 // Kategorie
                    ASYNC_GETINQUECOUNT,         // Funktionsnummer
                    NIL,                         // Parameterpaket
                    0,                           // Grî·e des Parameterpaketes
                    NIL,
                    @DataPaket,                  // Datenpaket
                    SizeOf(DataPaket),           // Grî·e des Datenpaketes
                    NIL);
     if datapaket.count < 1 then com_empty:=true else com_empty:=false;
end; {com_empty}

function get_bps : longint;

var
   DataPaket   :  TFixedBaudInfo;
   R           :  APIRET;

begin
     R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                    IOCTL_ASYNC,                 // Kategorie
                    $63,                         // Funktionsnummer
                    NIL,                         // Parameterpaket
                    0,                           // Grî·e des Parameterpaketes
                    NIL,
                    @DataPaket,                  // Datenpaket
                    SizeOf(DataPaket),           // Grî·e des Datenpaketes
                    NIL);
     get_bps:=datapaket.current.baud;
end; {get_bps}

function carrier : boolean;

var
   datapaket : byte;
   r         : apiret;

begin
     R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                    IOCTL_ASYNC,                 // Kategorie
                    ASYNC_GETMODEMINPUT,         // Funktionsnummer
                    NIL,                         // Parameterpaket
                    0,                           // Grî·e des Parameterpaketes
                    NIL,
                    @DataPaket,                  // Datenpaket
                    SizeOf(DataPaket),           // Grî·e des Datenpaketes
                    NIL);
     carrier:=(datapaket and DCD_ON)<>0;
end; {carrier}

function cts : boolean;

var
   datapaket : byte;
   r         : apiret;

begin
     R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                    IOCTL_ASYNC,                 // Kategorie
                    ASYNC_GETMODEMINPUT,         // Funktionsnummer
                    NIL,                         // Parameterpaket
                    0,                           // Grî·e des Parameterpaketes
                    NIL,
                    @DataPaket,                  // Datenpaket
                    SizeOf(DataPaket),           // Grî·e des Datenpaketes
                    NIL);
     cts:=(datapaket and CTS_ON)<>0;
end; {cts}

function h_ring : boolean;

var
   datapaket : byte;
   r         : apiret;

begin
     R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                    IOCTL_ASYNC,                 // Kategorie
                    ASYNC_GETMODEMINPUT,         // Funktionsnummer
                    NIL,                         // Parameterpaket
                    0,                           // Grî·e des Parameterpaketes
                    NIL,
                    @DataPaket,                  // Datenpaket
                    SizeOf(DataPaket),           // Grî·e des Datenpaketes
                    NIL);
     h_ring:=(datapaket and RI_ON)<>0;
end; {h_ring}

function dsr : boolean;

var
   datapaket : byte;
   r         : apiret;

begin
     R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                    IOCTL_ASYNC,                 // Kategorie
                    ASYNC_GETMODEMINPUT,         // Funktionsnummer
                    NIL,                         // Parameterpaket
                    0,                           // Grî·e des Parameterpaketes
                    NIL,
                    @DataPaket,                  // Datenpaket
                    SizeOf(DataPaket),           // Grî·e des Datenpaketes
                    NIL);
     dsr:=(datapaket and DSR_ON)<>0;
end; {dsr}

procedure dump;

begin
end; {dump}

function get_dtr : boolean;

var
   DataPaket : byte;
   R         : APIRET;

BEGIN
      R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                     IOCTL_ASYNC,                 // Kategorie
                     ASYNC_GETMODEMOUTPUT,        // Funktionsnummer
                     NIL,                         // Parameterpaket
                     0,                           // Grî·e des Parameterpaketes
                     NIL,
                     @DataPaket,                  // Datenpaket
                     SizeOf(DataPaket),           // Grî·e des Datenpaketes
                     NIL);
      get_dtr := (datapaket and $01) <>0;
end; {get_dtr}

function get_rts : boolean;

var
   DataPaket : byte;
   R         : APIRET;

BEGIN
      R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                     IOCTL_ASYNC,                 // Kategorie
                     ASYNC_GETMODEMOUTPUT,        // Funktionsnummer
                     NIL,                         // Parameterpaket
                     0,                           // Grî·e des Parameterpaketes
                     NIL,
                     @DataPaket,                  // Datenpaket
                     SizeOf(DataPaket),           // Grî·e des Datenpaketes
                     NIL);
      get_rts := (datapaket and $02) <>0;
end; {get_rts}

procedure set_dtr (bool : boolean);

var
   DataPaket  : byte;
   R          : APIRET;
   ms         : modemstatus;

begin
      ms.fbModemOn:=0;ms.fbModemOff:=0;
      if bool=true then ms.fbModemOn:=dtr_on;
      if bool=false then ms.fbModemOff:=dtr_off;
      R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                     IOCTL_ASYNC,                 // Kategorie
                     ASYNC_SETMODEMCTRL,          // Funktionsnummer
                     @ms,                         // Parameterpaket
                     SizeOf(ms),                  // Grî·e des Parameterpaketes
                     NIL,
                     @DataPaket,                  // Datenpaket
                     SizeOf(datapaket),           // Grî·e des Datenpaketes
                     NIL);
end; {set_dtr}

procedure set_rts (bool : boolean);

var
   DataPaket  : byte;
   R          : APIRET;
   ms         : modemstatus;

begin
      ms.fbModemOn:=0;ms.fbModemOff:=0;
      if bool=true then ms.fbModemOn:=rts_on;
      if bool=false then ms.fbModemOff:=rts_off;
      R:=DosDevIOCTL(ComHandle,                   // Dateihandle von DosOpen
                     IOCTL_ASYNC,                 // Kategorie
                     ASYNC_SETMODEMCTRL,          // Funktionsnummer
                     @ms,                         // Parameterpaket
                     SizeOf(ms),                  // Grî·e des Parameterpaketes
                     NIL,
                     @DataPaket,                  // Datenpaket
                     SizeOf(DataPaket),           // Grî·e des Datenpaketes
                     NIL);
end; {set_rts}

end. {mcom}

{
  $Log: mcom.pas,v $
  Revision 1.2  2000/05/25 23:07:56  rb
  Loginfos hinzugefÅgt

}