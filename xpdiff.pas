{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: xpdiff.pas,v 1.2 2000/05/25 23:26:28 rb Exp $ }

{ Product Code / Versionsnummer / Diverses }
{ f�r ZFIDO, XP-FM, XP7 und XP7T           }

{$I XPDEFINE.INC }

unit  xpdiff;

interface

uses xpglobal;

const prodcode : byte = $e9;
      version: smallword  = $0314;   { 3.20 }
      prodcodef= 'FIDO.PC';

      EL_ok     = 0;                    { XP-FM:                    }
      EL_recerr = 1;                    { ERRORLEVEL: Empf.-Fehler  }
      EL_senderr= 2;                    {             Sende-Fehler  }
      EL_noconn = 3;                    { keine Verbindung          }
      EL_nologin= 4;                    { Handshake-Fehler          }
      EL_break  = 5;                    { Abbruch vor Verbindung    }
      EL_carrier= 8;                    { Carrier bei Programmstart }
      EL_par    = 9;                    { Parameter-Fehler          }
      EL_max    = 9;

      tt_ok     = 0;                    { TurboBox-Transfer ok      }
      tt_recerr = 1;                    { Empfangsfehler            }
      tt_senderr= 2;                    { Sendefehler               }
      tt_snerr  = 3;                    { falsche Seriennummer      }
      tt_nospace= 4;                    { kein Platz auf Boxplatte  }


implementation

end.

{
  $Log: xpdiff.pas,v $
  Revision 1.2  2000/05/25 23:26:28  rb
  Loginfos hinzugef�gt

}
