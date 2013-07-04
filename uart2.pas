unit uart2;

{
        Autor Urversion       : Torsten J„hnigen
        Autor letzte Žnderung : Torsten J„hnigen
        Datum                 : 09.01.2000
        letzte Žnderung       : 16.01.2000
        Bemerkung             : Schnittstelle zwischen mCom/2 und Uart
}

{ $Id: uart2.pas,v 1.2 2000/05/25 23:07:56 rb Exp $ }

interface

        uses mcom;

        procedure SetTriggerLevel(level:byte);
        procedure SetComParams(no:byte; UseFossil : boolean; adress:word; _irq:byte);
        function  ComType(no:byte):byte;           { Typ des UART-Chips ermitteln }
        function  FOSSILdetect:boolean;            { FOSSIL-Treiber geladen?      }
        procedure ReleaseCom(no:byte);             { Schnitte desakt., Puffer freig. }
        function  rring(no:byte):boolean;          { Telefon klingelt  }
        function  carrier(no:byte):boolean;        { Carrier vorhanden }
        function  GetCfosCharges(no:word):integer; { cFos: Gebhreneinheiten des lau- }
                                                   {       fenden oder letzten Anrufs }
        function  getCTS(no:byte):boolean;         { True = (cts=1)    }
        procedure AllocComBuffer(no:byte; buffersize:word);
        procedure FreeComBuffer(no:byte);
        function  BufferFull(no:byte):boolean;
        function  BufferEmpty(no:byte):boolean;


implementation

 const
        os2com     = 16; {hab schon Treiber fuer OS/2 gesehen, die mehr}
                         {koennen, sind aber sehr selten               }

 type
        bufft      = array [0..65534] of byte;

 var
        trigger    : byte;
        bufsize    : array [1..os2com] of word;
        buffer     : array [1..os2com] of ^bufft;
        bufi, bufo : array [1..os2com] of word;
        buflow     : array [1..os2com] of word;
        bufhigh    : array [1..os2com] of word;


 function ComType(no:byte):byte;     { Typ des UART-Chips ermitteln }

  begin
   ComType:=4;  {Uart 16550A}
   {Sollte in den Tiefen des Programmes wirklich danach gefragt werden, wird }
   {erstmal provisorisch ein Uart 16550A zurueckgegeben, was fuer die Art    }
   {und Weise, wie OS/2 mit den seriellen Schnittstellen umgeht, recht       }
   {Nahe kommt.                                                              }
  end; {ComTyp}

 function FOSSILdetect:boolean;      { FOSSIL-Treiber geladen?      }

  begin
   FOSSILdetect:=false;
   {unter OS/2 gibt es sowas wie einen Fossil nicht, nur auf DOS Emulation   }
   {Ebene exestiert ein virtuelle Fossilschnittstelle, wenn man SIO von      }
   {L.Gwinn einsetzt, da es sich hier aber um einen OS/2 Port handelt, kann  }
   {man pauschal von Wert "false" ausgehen.                                  }
  end; {FOSSILdetect}

 procedure SetTriggerLevel(level:byte);

  begin
   {
    fuer die mCom/2 Schnittstelle nicht relevant daher Standardwert
   }
   trigger:=$80;
  end; {SetTriggerLevel}

 procedure SetComParams(no:byte; UseFossil : boolean; adress:word; _irq:byte);

  begin
   {es wird nur der COMPort uebergeben, der Rest macht der Treiber, wo einem}
   {beliebigen Handle die jeweiligen Parameter wie IRQ & Adresse uebergeben }
   {werden, so kann der physikalische COM1 Comhandle COM16 sein. Siehe Doku }
   {SIO oder das jeweilige REDBOOK                                          }
   com_open(no);
  end; {SetComParams}

 procedure ReleaseCom(no:byte);

  begin
   {in der XP-UART Original Dokumentation steht zwar, das der ComPort nach}
   {beenden des Programmes freigegeben wird, unter OS/2 sollte man aber   }
   {sauber anhand dieser Funktion den ComHandle freigeben, da sonst die   }
   {Gefahr besteht, das das nachfolgende Programm nicht mehr auf den Port }
   {zugreifen kann.                                                       }
   com_close;
   {da mit dieser Unit nur ein ComHandle benutzt wird, entfaellt die      }
   {Angabe des ComPorts... It's OS/2 :)                                   }
  end; {ReleaseCom}


 function rring(no:byte):boolean;

  begin
   {Bemerkungen in der Unit mCom/2 beachten}
   rring:=false;
   rring:=h_ring;
  end; {rring}


 function carrier(no:byte):boolean;

  begin
   carrier:=false;
   carrier:=mcom.carrier;
  end; {carrier}


 function GetCfosCharges(no:word):integer;

  begin
   {unter OS/2 gibt es IMHO auch diese Funktion, da aber Anderes wichtiger ist}
   {im Moment, bleibt diese Funktion erstmal aussen vor...                    }
   GetCfosCharges:=0;
  end; {GetCfosCharges}


 function  getCTS(no:byte):boolean;

  begin
   getCTS:=cts;
  end; {getCTS}


 procedure AllocComBuffer(no:byte; buffersize:word);

  begin
   bufsize[no]:=buffersize;                 { Puffer anlegen }
   getmem(buffer[no],buffersize);
   bufi[no]:=0; bufo[no]:=0;
   fillchar(buffer[no]^,bufsize[no],0);
  end; {AllocComBuffer}


 procedure FreeComBuffer(no:byte);

  begin
   freemem(buffer[no],bufsize[no]);
  end; {FreeComBuffer}


 function BufferFull(no:byte):boolean;

  begin
   if bufi[no]>=bufo[no] then
    BufferFull:=(bufi[no]-bufo[no]) > bufhigh[no]
   else
    BufferFull:=(bufi[no]+bufsize[no]-bufo[no]) > bufhigh[no]
  end; {BufferFull}


 function BufferEmpty(no:byte):boolean;

  begin
   if bufi[no]>=bufo[no] then
    BufferEmpty:=(bufi[no]-bufo[no]) < buflow[no]
   else
    BufferEmpty:=(bufi[no]+bufsize[no]-bufo[no]) < buflow[no];
  end; {BufferEmpty}


end. {uart2}

{

VP Variabelgroesse

 +-----------+--------+--------+--------+
 | Type      | Use32+ | Use32- | signed |
 +-----------+--------+--------+--------+
 | integer   |     32 |     16 | yes    |
 | longint   |     32 |     32 | yes    |
 | word      |     32 |     16 | no*    |
 | SmallInt  |     16 |     16 | yes    |
 | SmallWord |     16 |     16 | no     |
 | byte      |      8 |      8 | no     |
 +-----------+--------+--------+--------+

 Hinweis:
          der SIO bzw. der von IBM mitgelieferte Treiber fuer die serielle
          Schnittstelle arbeitet mit einem internen Buffer. Daher sind die
          Funktionen der Einzel Byte Empfanges ein wenig hingezaubert...

}

{
  $Log: uart2.pas,v $
  Revision 1.2  2000/05/25 23:07:56  rb
  Loginfos hinzugefgt

}