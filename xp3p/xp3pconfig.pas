{ $Id: xp3pconfig.pas,v 1.11 2002/01/06 19:34:49 MH Exp $ }

unit xp3pconfig;

{$i asldefine.inc}

interface

uses sysutils;

type exp3pconfigerror = class (exception);

     txp3pconfig = class

     protected
       fpop3server          : string;
       fpop3port            : string;
       fpop3user            : string;
       fpop3pass            : string;
       fpop3auth            : string;
       fpop3envelope        : string;
       fpop3useenvelope     : string;
       fpop3keep            : string;
       fpop3spool           : string;
       fpop3timeout         : string;
       fpop3maxlen          : integer;

       fsmtpserver          : string;
       fsmtpport            : string;
       fsmtpuser            : string;
       fsmtppass            : string;
       fsmtpenvelope        : string;
       fsmtpafterpop        : boolean;
       fsmtpafterpoptimeout : string;
       fsmtpafterpopdelay   : integer;
       fsmtpspool           : string;
       fsmtptimeout         : string;
       fsmtpauth            : string;

       fnntpserver          : string;
       fnntpfallback        : string;
       fnntpport            : string;
       fnntpuser            : string;
       fnntppass            : string;
       fnntplist            : boolean;
       fnntptimeout         : integer;
       fnntpspool           : string;
       fnntpmaxlen          : integer;
       fnntpnewmax          : integer;
       fnntpdupesize        : integer;
       fnntprescan          : boolean;
       fnntpqueue           : integer;

       freplaceown          : boolean;
       fuuzspool            : string;
       fppp_boxpakete       : string;
       fppp_killfile        : string;

       fscoreaktiv          : boolean;
       fscorefile           : string;

     public
       constructor create (path: string);
       destructor destroy; override;

       property pop3server:          string  read fpop3server;
       property pop3port:            string  read fpop3port;
       property pop3user:            string  read fpop3user;
       property pop3pass:            string  read fpop3pass;
       property pop3auth:            string  read fpop3auth;
       property pop3envelope:        string  read fpop3envelope write fpop3envelope;
       property pop3useenvelope:     string  read fpop3useenvelope;
       property pop3keep:            string  read fpop3keep;
       property pop3spool:           string  read fpop3spool write fpop3spool;
       property pop3timeout:         string  read fpop3timeout;
       property pop3maxlen:          integer read fpop3maxlen;

       property smtpserver:          string  read fsmtpserver;
       property smtpport:            string  read fsmtpport;
       property smtpuser:            string  read fsmtpuser;
       property smtppass:            string  read fsmtppass;
       property smtpenvelope:        string  read fsmtpenvelope;
       property smtpafterpop:        boolean read fsmtpafterpop;
       property smtpafterpoptimeout: string  read fsmtpafterpoptimeout;
       property smtpafterpopdelay:   integer read fsmtpafterpopdelay;
       property smtpspool:           string  read fsmtpspool write fsmtpspool;
       property smtptimeout:         string  read fsmtptimeout;
       property smtpauth:            string  read fsmtpauth write fsmtpauth;

       property nntpserver:          string  read fnntpserver;
       property nntpfallback:        string  read fnntpfallback;
       property nntpport:            string  read fnntpport;
       property nntpuser:            string  read fnntpuser;
       property nntppass:            string  read fnntppass;
       property nntplist:            boolean read fnntplist;
       property nntptimeout:         integer read fnntptimeout;
       property nntpspool:           string  read fnntpspool write fnntpspool;
       property nntpmaxlen:          integer read fnntpmaxlen;
       property nntpnewmax:          integer read fnntpnewmax;
       property nntpdupesize:        integer read fnntpdupesize;
       property nntprescan:          boolean read fnntprescan;
       property nntpqueue:           integer read fnntpqueue;

       property replaceown:          boolean read freplaceown;
       property uuzspool:            string  read fuuzspool write fuuzspool;
       property ppp_boxpakete:       string  read fppp_boxpakete;
       property ppp_killfile:        string  read fppp_killfile;

       property scoreaktiv:          boolean read fscoreaktiv write fscoreaktiv;
       property scorefile:           string  read fscorefile;

     end;

implementation

uses xp3pmisc;

function getstr (s, s1: string; p: integer; var value: string): boolean;
  var v: string;
  begin
    getstr := false;
    if p = 0 then exit;
    v := s;
    s := copy (s, 1, p - 1);
    delete (v, 1, p);
    delspace (s);
    delspace (v);
    s := uppercase (s);
    if s = s1 then begin
      value := v;
      getstr := true;
    end;
  end;

function getbool (s, s1: string; p: integer; var value: boolean): boolean;
  var v: string;
  begin
    if getstr (s, s1, p, v) then begin
      v := uppercase (v);
      value := (v = 'ENABLED') or (v = 'J') or (v = 'JA') or
               (v = 'Y') or (v = 'YES');
      getbool := true;
    end
    else getbool := false;
  end;

function getint (s, s1: string; p: integer; var value: integer): boolean;
  var v: string;
  begin
    if getstr (s, s1, p, v) then begin
      value := strtoint (v);
      getint := true;
    end
    else getint := false;
  end;

constructor txp3pconfig.create (path: string);
  var t: text;
      p: integer;
      s: string;
  begin
    inherited create;
    fpop3server := '';
    fpop3port := '';
    fpop3user := '';
    fpop3pass := '';
    fpop3auth := 'N';
    fpop3envelope := '';
    fpop3useenvelope := 'N';
    fpop3keep := 'J';
    fpop3spool := '';
    fpop3timeout := '';
    fpop3maxlen := 1048576;  { 1024 * 1024 Bytes = 1MB }
    fsmtpserver := '';
    fsmtpport := '';
    fsmtpuser := '';
    fsmtppass := '';
    fsmtpenvelope := '';
    fsmtpafterpop := false;
    fsmtpafterpoptimeout := '';
    fsmtpafterpopdelay := 0;
    fsmtpspool := '';
    fsmtptimeout := '';
    fsmtpauth := '';
    fnntpserver := '';
    fnntpfallback := '';
    fnntpport := '';
    fnntpuser := '';
    fnntppass := '';
    fnntplist := false;
    fnntptimeout := 30;
    fnntpspool := '';
    fnntpmaxlen := 99999;
    fnntpnewmax := 2500;
    fnntpdupesize := 65536;  { 64 kB }
    fnntprescan := false;
    fnntpqueue := 10;
    freplaceown := false;
    fuuzspool := '';
    fppp_boxpakete := '';
    fppp_killfile := '';
    fscoreaktiv := false;
    fscorefile := '';
    assign (t, path);
    {$i-} reset (t); {$i+}
    if ioresult = 0 then
    try
      while not eof (t) do begin
        readln (t, s);
        if (s <> '') and (s [1] <> '#') then begin
          p := pos ('=', s);
          if (p = 0)
          then raise exp3pconfigerror.create ('Fehler in der Config-Datei')
          else begin
            if not getstr (s, 'POP3SERVER', p, fpop3server)
            then if not getstr (s, 'POP3PORT', p, fpop3port)
            then if not getstr (s, 'POP3USER', p, fpop3user)
            then if not getstr (s, 'POP3PASS', p, fpop3pass)
            then if not getstr (s, 'POP3AUTH', p, fpop3auth)
            then if not getstr (s, 'POP3ENVELOPE', p, fpop3envelope)
            then if not getstr (s, 'POP3USEENVELOPE', p, fpop3useenvelope)
            then if not getstr (s, 'POP3KEEP', p, fpop3keep)
            then if not getstr (s, 'POP3SPOOL', p, fpop3spool)
            then if not getstr (s, 'POP3TIMEOUT', p, fpop3timeout)
            then if not getint (s, 'POP3MAXLEN', p, fpop3maxlen)

            then if not getstr (s, 'SMTPSERVER', p, fsmtpserver)
            then if not getstr (s, 'SMTPPORT', p, fsmtpport)
            then if not getstr (s, 'SMTPUSER', p, fsmtpuser)
            then if not getstr (s, 'SMTPPASS', p, fsmtppass)
            then if not getstr (s, 'SMTPENVELOPE', p, fsmtpenvelope)
            then if not getbool (s, 'SMTPAFTERPOP', p, fsmtpafterpop)
            then if not getstr (s, 'SMTPAFTERPOPTIMEOUT', p, fsmtpafterpoptimeout)
            then if not getint (s, 'SMTPAFTERPOPDELAY', p, fsmtpafterpopdelay)
            then if not getstr (s, 'SMTPSPOOL', p, fsmtpspool)
            then if not getstr (s, 'SMTPTIMEOUT', p, fsmtptimeout)
            then if not getstr (s, 'SMTPAUTH', p, fsmtpauth)

            then if not getstr (s, 'NNTPSERVER', p, fnntpserver)
            then if not getstr (s, 'NNTPFALLBACK', p, fnntpfallback)
            then if not getstr (s, 'NNTPPORT', p, fnntpport)
            then if not getstr (s, 'NNTPUSER', p, fnntpuser)
            then if not getstr (s, 'NNTPPASS', p, fnntppass)
            then if not getbool (s, 'NNTPLIST', p, fnntplist)
            then if not getint (s, 'NNTPTIMEOUT', p, fnntptimeout)
            then if not getstr (s, 'NNTPSPOOL', p, fnntpspool)
            then if not getint (s, 'NNTPMAXLEN', p, fnntpmaxlen)
            then if not getint (s, 'NNTPNEWMAX', p, fnntpnewmax)
            then if not getint (s, 'NNTPDUPESIZE', p, fnntpdupesize)
            then if not getbool (s, 'NNTPRESCAN', p, fnntprescan)
            then if not getint (s, 'NNTPQUEUE', p, fnntpqueue)

            then if not getbool (s, 'NNTPREPLACEOWN', p, freplaceown)
            then if not getbool (s, 'REPLACEOWN', p, freplaceown)
            then if not getstr (s, 'PPP_UUZ_SPOOL', p, fuuzspool)
            then if not getstr (s, 'PPP_BOXPAKETE', p, fppp_boxpakete)
            then if not getstr (s, 'PPP_KILLFILE', p, fppp_killfile)

            then if not getbool (s, 'XPSCOREAKTIV', p, fscoreaktiv)
            then if not getstr (s, 'SCOREFILE', p, fscorefile)

            { UnterstÅtzung fÅr OpenXP }

           {$IFnDEF OS2}
            then if not getstr (s, 'CLIENT-ADDSERVERS', p, fppp_boxpakete)
            then if not getstr (s, 'CLIENT-SPOOL', p, fuuzspool)

            then if not getstr (s, 'CLIENT-MAILINSERVER', p, fpop3server)
            then if not getstr (s, 'CLIENT-MAILINENVELOPE', p, fpop3envelope)
            then if not getstr (s, 'CLIENT-MAILINUSER', p, fpop3user)
            then if not getstr (s, 'CLIENT-MAILINPASSWORD', p, fpop3pass)
            then if not getstr (s, 'CLIENT-MAILINPORT', p, fpop3port)
            then if not getstr (s, 'CLIENT-MAILINUSEENVTO', p, fpop3useenvelope)
            then if not getstr (s, 'CLIENT-MAILINKEEP', p, fpop3keep)
            then if not getstr (s, 'CLIENT-MAILINAPOP', p, fpop3auth)

            then if not getstr (s, 'CLIENT-MAILOUTSERVER', p, fsmtpserver)
            then if not getstr (s, 'CLIENT-MAILOUTENVELOPE', p, fsmtpenvelope)
            then if not getstr (s, 'CLIENT-MAILOUTUSER', p, fsmtpuser)
            then if not getstr (s, 'CLIENT-MAILOUTPASSWORD', p, fsmtppass)
            then if not getstr (s, 'CLIENT-MAILOUTPORT', p, fsmtpport)
            then if not getbool (s, 'CLIENT-MAILOUTSMTPAFTERPOP', p, fsmtpafterpop)
            then if not getstr (s, 'CLIENT-MAILOUTSMTPLOGIN', p, fsmtpauth)

            then if not getstr (s, 'CLIENT-NEWSSERVER', p, fnntpserver)
            then if not getstr (s, 'CLIENT-NEWSFALLBACK', p, fnntpfallback)
            then if not getstr (s, 'CLIENT-NEWSUSER', p, fnntpuser)
            then if not getstr (s, 'CLIENT-NEWSPASSWORD', p, fnntppass)
            then if not getstr (s, 'CLIENT-NEWSPORT', p, fnntpport)
            then if not getbool (s, 'CLIENT-NEWSLIST', p, fnntplist)
            then if not getint (s, 'CLIENT-NEWSMAXLEN', p, fnntpmaxlen)
            then if not getint (s, 'CLIENT-NEWSMAX', p, fnntpnewmax)
           {$ENDIF}

            then ;
          end;
        end;
      end;
    finally
      close (t);
    end
    else raise exp3pconfigerror.create ('Config-Datei ''' + path +
                                        ''' nicht gefunden');
  end;

destructor txp3pconfig.destroy;
  begin
    inherited destroy;
  end;

end.


{
  $Log: xp3pconfig.pas,v $
  Revision 1.11  2002/01/06 19:34:49  MH
  - Fix in OpenXP-Support

  Revision 1.10  2002/01/05 14:03:30  MH
  - Tippfehler beseitigt
  - SmtpAuth (LOGIN) implementiert
  - APOP optimiert (ueberfluessigen Code entfernt)

  Revision 1.9  2002/01/05 00:47:23  MH
  - Tippfehler beseitigt

  Revision 1.8  2002/01/04 19:04:10  MH
  - OpenXP-Unterstuetzung fuer W32-Version
  - Schalter hinzugefuegt: NntpFallback und SmtpAuth

  Revision 1.7  2002/01/02 23:16:49  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.6  2001/12/29 15:14:38  MH
  - Fix: (GetBool) korrigiert, da voellig korekt

  Revision 1.5  2001/12/28 06:55:07  MH
  - Fix: GetBool konnte unter Umstaenden immer true zurueckgeben

  Revision 1.4  2001/08/14 07:59:58  mm
  - Kommando zurueck... :-)

  Revision 1.2  2001/07/15 12:48:26  MH
  - Standardwerte angepasst (hat sich wohl wer vertippert)

  Revision 1.1  2001/07/11 19:47:20  rb
  checkin


}
