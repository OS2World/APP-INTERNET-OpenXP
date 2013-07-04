{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.15 $    $Date: 2002/01/12 16:17:13 $    $Author: MH $ }
{                                                                             }
{ Simple Mail Transfer Protocol (SMTP) client class (RFC 821)                 }
{ EHLO extension as per RFC 1869                                              }
{ SIZE extension as per RFC 1870                                              }
{ ETRN extension as per RFC 1985                                              }
{ Message format as per FRC 822                                               }
{                                                                             }
{ Parts copyright (c) Dwayne Heaton (dwayne@vmadd.demon.co.uk)                }

{ $Id: aslsmtpclient.pas,v 1.15 2002/01/12 16:17:13 MH Exp $ }

UNIT aslSMTPClient;

{$I aslDefine.Inc}

INTERFACE

USES Classes, SysUtils, aslAbsSocket, aslAbsClient, encoder, uMD5;

CONST
  SMTPDateTemplate = 'd mmm yyyy hh:nn:ss';

TYPE
  TSMTPMessage = CLASS;

  EAbsSMTPClient = CLASS(EaslException);

  TAbsSMTPClient = CLASS(TAbsClient)
  PUBLIC
    CONSTRUCTOR Create;
    DESTRUCTOR Destroy;
    PROCEDURE Connect(Host: STRING); OVERRIDE;

{ RFC 821 commands }
    PROCEDURE Helo(Domain: STRING);
    PROCEDURE Mail(From: STRING);
    PROCEDURE Send(From: STRING);
    PROCEDURE Soml(From: STRING);
    PROCEDURE Saml(From: STRING);
    PROCEDURE Rcpt(To_: STRING);
    PROCEDURE Data;
    PROCEDURE Rset;
    PROCEDURE Vrfy(User: STRING);
    PROCEDURE Expn(MailingList: STRING; Members: TStringList);
    PROCEDURE Help(Topic: STRING; HelpText: TStringList);
    PROCEDURE Noop;
    PROCEDURE Turn;
    PROCEDURE Quit;

{ Extensions }
    PROCEDURE Ehlo(Domain: STRING; ExtraCmds: TStringList; Art, Name, Pass: STRING);
  END;

  TSMTPClient = CLASS(TAbsSMTPClient)
  PRIVATE
    FDomain : STRING;
    FCmds   : TStringList;
  PUBLIC
    CONSTRUCTOR Create;
    PROCEDURE Connect(Host, Domain: STRING);
    PROCEDURE Disconnect; OVERRIDE;

    PROCEDURE SendMsg(Msg: TSMTPMessage);

    PROPERTY Domain: STRING     READ FDomain WRITE FDomain;
  END;

  TEncode = (encNone, enc64, encUU, encXX);
  PEncode = ^TEncode;
  TAttachments = CLASS
  PRIVATE
    FFiles  : TStringList;
    FEncode : Array[1..50] of PEncode;
    FNum    : LongInt;
  PUBLIC
    CONSTRUCTOR Create;
    DESTRUCTOR Destroy;

    PROCEDURE Add(Filename : String; Encode : TEncode);
    FUNCTION Count : LongInt;
    FUNCTION Get(Index : LongInt; Var Filename : String; Var Encode : TEncode) : Boolean;
  END;


  TSMTPMessage = CLASS
  PRIVATE
    FHeader       : BOOLEAN;

    FFrom         : STRING;
    FTo           : TStringList;
    FSubject      : STRING;
    FMessageID    : STRING;
    FDate         : STRING;
    FReplyTo      : STRING;

    FOrganisation : STRING;
    FMimeVersion  : STRING;
    FContentType  : STRING;
    FBoundary     : STRING;

//  FReturnPath : STRING;
//  MimeInfo ?????

//  FRestHeader: TStrings;
    FMsgBody   : TStringList;

//  FileAttaches TFileColl???
    FileAttaches : TAttachments;

  PUBLIC
    CONSTRUCTOR Create;
    DESTRUCTOR Destroy;
    PROCEDURE Clear;

    PROCEDURE AddTo(To_: STRING);
    PROCEDURE AddMsgBody(Line: STRING);
    PROCEDURE AddAttach(Filename: STRING; Encode: TEncode);
// FromFile
    PROPERTY Header: BOOLEAN       READ FHeader       WRITE FHeader;

    PROPERTY From: STRING          READ FFrom         WRITE FFrom;
    PROPERTY To_: TStringList      READ FTo           WRITE FTo;
    PROPERTY Subject: STRING       READ FSubject      WRITE FSubject;
    PROPERTY MessageID: STRING     READ FMessageID    WRITE FMessageID;
    PROPERTY Date: STRING          READ FDate         WRITE FDate;
    PROPERTY ReplyTo: STRING       READ FReplyTo      WRITE FReplyTo;

    PROPERTY Organisation: STRING  READ FOrganisation WRITE FOrganisation;
    PROPERTY MimeVersion: STRING   READ FMimeVersion  WRITE FMimeVersion;
    PROPERTY ContentType: STRING   READ FContentType  WRITE FContentType;
    PROPERTY Boundary: STRING      READ FBoundary     WRITE FBoundary;

    PROPERTY MsgBody: TStringList  READ FMsgBody      WRITE FMsgBody;
  END;

IMPLEMENTATION

USES aslEncode, aslMimeTypes;

{ TAbsSMTPClient }

  CONSTRUCTOR TAbsSMTPClient.Create;
  BEGIN
    INHERITED Create;
    Service:='smtp';
  END;

  DESTRUCTOR TAbsSMTPClient.Destroy;
  BEGIN
    IF Assigned(Socket) THEN Quit;
    INHERITED Destroy;
  END;

  PROCEDURE TAbsSMTPClient.Connect(Host: STRING);
  BEGIN
    INHERITED Connect(Host);
    IF LastResponseCode<>220 THEN
      RAISE EAbsSMTPClient.Create('Connect', LastResponse);
  END;


  PROCEDURE TAbsSMTPClient.Helo(Domain: STRING);
  BEGIN
    SendCommand('HELO '+Domain);
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Helo', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Mail(From: STRING);
  BEGIN
    SendCommand('MAIL FROM: <'+From+'>');
    IF LastResponseCode=451 THEN
      RAISE EAbsSMTPClient.Create('Smtp-Auth required', LastResponse)
    else
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Mail', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Send(From: STRING);
  BEGIN
    SendCommand('SEND FROM: <'+From+'>');
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Send', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Soml(From: STRING);
  BEGIN
    SendCommand('SOML FROM: <'+From+'>');
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Soml', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Saml(From: STRING);
  BEGIN
    SendCommand('SAML FROM: <'+From+'>');
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Saml', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Rcpt(To_: STRING);
  BEGIN
    SendCommand('RCPT TO: <'+To_+'>');
    IF (LastResponseCode<>250) AND (LastResponseCode<>251) THEN
      RAISE EAbsSMTPClient.Create('Rcpt', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Data;
  BEGIN
    SendCommand('DATA');
    IF LastResponseCode<>354 THEN
      RAISE EAbsSMTPClient.Create('Data', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Rset;
  BEGIN
    SendCommand('RSET');
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Rset', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Vrfy(User: STRING);
  BEGIN
    SendCommand('VRFY '+User);
    IF (LastResponseCode<>250) AND (LastResponseCode<>251) THEN
      RAISE EAbsSMTPClient.Create('Vrfy', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Expn(MailingList: STRING; Members: TStringList);
  BEGIN
    SendCommand('EXPN '+MailingList);
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Expn', LastResponse);
    IF Assigned(Members) THEN Members.Add(LastResponse);
    GetLines(Members);
  END;

  PROCEDURE TAbsSMTPClient.Help(Topic: STRING; HelpText: TStringList);
  BEGIN
    IF Topic<>'' THEN SendCommand('HELP '+Topic) ELSE SendCommand('HELP');
    IF (LastResponseCode<>211) AND (LastResponseCode<>214) THEN
      RAISE EAbsSMTPClient.Create('Help', LastResponse);
    IF Assigned(HelpText) THEN HelpText.Add(LastResponse);
    GetLines(HelpText);
  END;

  PROCEDURE TAbsSMTPClient.Noop;
  BEGIN
    SendCommand('NOOP');
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Noop', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Turn;
  BEGIN
    SendCommand('TURN');
    IF LastResponseCode<>250 THEN
      RAISE EAbsSMTPClient.Create('Turn', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Quit;
  BEGIN
    SendCommand('QUIT');
    IF (LastResponseCode<>221) THEN
      RAISE EAbsSMTPClient.Create('Quit', LastResponse);
  END;

  PROCEDURE TAbsSMTPClient.Ehlo(Domain: STRING; ExtraCmds: TStringList; Art, Name, Pass: STRING);
  var
      i: integer;
      t: byte;
      s: str90;
      b: tbytestream;
      i1,i2,i3,i4:integer;
  const
      v: array[0..3] of string[10] = ('CRAM-MD5', 'DIGEST-MD5',
                                      'PLAIN',    'LOGIN');
      auth: string[5] = 'AUTH ';
  BEGIN
    SendCommandEx('EHLO ' + Domain, ExtraCmds);
    IF LastResponseCode <> 250 THEN
      RAISE EAbsSMTPClient.Create ('Ehlo', LastResponse);
{    IF Socket.WaitForDataTime(1000)>0 THEN
    GetLines(ExtraCmds);}
    if assigned (ExtraCmds) then begin
      t := 0;
      for i := 0 to ExtraCmds.Count - 1 do begin
        if (pos (v[0], uppercase (ExtraCmds[i])) <> 0) and (t and 1 = 0) then t := t or 1;
        if (pos (v[1], uppercase (ExtraCmds[i])) <> 0) and (t and 2 = 0) then t := t or 2;
        if (pos (v[2], uppercase (ExtraCmds[i])) <> 0) and (t and 4 = 0) then t := t or 4;
        if (pos (v[3], uppercase (ExtraCmds[i])) <> 0) and (t and 8 = 0) then t := t or 8;
      end;
      if (Art = 'AUTO') then
        case t of
          1     : Art := v[0]; { derzeit niedrigste Prio }
          2,3   : Art := v[1];
          4..7  : Art := v[2];
          8..15 : Art := v[3]; { h”chste Prio: LOGIN     }
          else    Art := v[3];
        end;
      sendcommand (Auth + Art);
      if LastResponseCode <> 334 then
        raise EAbsSMTPClient.Create(Auth + Art, LastResponse);
      if Art = v[0] then begin { CRAM-MD5 / RFC 2095, RFC 2554 }
        s := copy (LastResponse, 5, length (LastResponse) - 4);
        decodebase64 (s);
        s := MD5ToHex (CRAM_MD5 (s, Pass));
        s := Name + ' ' + s;
        fillchar (b, sizeof (b), 0);
        for i := 0 to length (s) - 1 do
          b[i] := ord (s[i + 1]);
        encode_base64 (b, i, s);
        sendcommand (s);
        if LastResponseCode <> 235 then
          raise EAbsSMTPClient.Create(Auth + Art, LastResponse);
      end
      else if Art = v[1] then begin { DIGEST-MD5 }
        { mAx: funktioniert leider noch nicht - mehr input erwarten }
        s := copy (LastResponse, 5, length (LastResponse) - 4);
        decodebase64 (s);
        logline('1:'+s);
        i1:=pos('"', s)+1;
        i2:=pos(',',s)-1;
        i2:=length(s)-i2;
        i3:=length(s)-i1-i2;
        s := copy(s, i1, i3);
        logline('x:'+s);
        decodebase64(s);
        logline('2:'+s);
        s := MD5ToHex (MD5ofStr (Name + ' ' + Pass + s));
        logline('3:'+s);
        fillchar (b, sizeof (b), 0);
        for i := 0 to length (s) - 1 do
          b[i] := ord (s[i + 1]);
        encode_base64 (b, i, s);
        sendcommand (s);
        if LastResponseCode <> 235 then
          raise EAbsSMTPClient.Create(Auth + Art, LastResponse);
      end
      else if Art = v[2] then begin { PLAIN / RFC 2595 }
        fillchar (b, sizeof (b), 0);
        s := #0 + Name + #0 + Pass;
        for i := 0 to length (s) - 1 do
          b[i] := ord (s[i + 1]);
        encode_base64 (b, i, s);
        sendcommand (s);
        if LastResponseCode <> 235 then
          raise EAbsSMTPClient.Create(Auth + Art, LastResponse);
      end
      else if Art = v[3] then begin { LOGIN }
        fillchar (b, sizeof (b), 0);
        s := Name;
        for i := 0 to length (Name) - 1 do
          b[i] := ord (s[i + 1]);
        encode_base64 (b, i, s);
        sendcommand (s);
        if LastResponseCode <> 334 then
          raise EAbsSMTPClient.Create(Auth + Art, LastResponse);
        fillchar (b, sizeof (b), 0);
        s := Pass;
        for i := 0 to length (Pass) - 1 do
          b[i] := ord (s[i + 1]);
        encode_base64 (b, i, s);
        sendcommand (s);
        if LastResponseCode <> 235 then
          raise EAbsSMTPClient.Create(Auth + Art, LastResponse);
      end
        else raise EAbsSMTPClient.Create('Auth-Login-Method not understand', Auth + Art + ' not supported');
    end;
  END;


{ TSMTPClient }

  CONSTRUCTOR TSMTPClient.Create;
  BEGIN
    INHERITED Create;
    FDomain:='';
  END;

  PROCEDURE TSMTPClient.Connect(Host, Domain: STRING);
  BEGIN
    INHERITED Connect(Host);
    FDomain:=Domain;
    TRY
      Ehlo(FDomain, FCmds, '', '', '');
    EXCEPT
      ON EAbsSMTPClient DO Helo(FDomain);
    ELSE
      RAISE;
    END;
  END;

  PROCEDURE TSMTPClient.Disconnect;
  BEGIN
    Quit;
    INHERITED Disconnect;
    FDomain:='';
  END;

  PROCEDURE TSMTPClient.SendMsg(Msg: TSMTPMessage);
  VAR
    i : Integer;
    S : STRING;
    E : TEncode;
    Filename : STRING;
    Content  : STRING;
    Encode : TAbsEncode;
    Mime : TMimeMgr;
  BEGIN
    Mail(Msg.From);
    FOR i:=0 TO Msg.FTo.Count-1 DO
      Rcpt(Msg.FTo[i]);
    Data;

    IF Msg.Header THEN
    BEGIN
      Socket.WriteLn('From: '+Msg.From);
      S := 'To: ' + Msg.To_[0];
      FOR i:=1 TO Msg.To_.Count-1 DO S:=S+', '+Msg.To_[i];
      Socket.WriteLn(S);
      IF Msg.Subject<>'' THEN Socket.WriteLn('Subject: '+Msg.Subject);
      IF Msg.MessageID<>'' THEN Socket.WriteLn('Message-Id: '+Msg.MessageID);
      TimeSeparator:=':';
      IF Msg.Date<>'' THEN
        Socket.WriteLn('Date: '+Msg.Date)
      ELSE
        Socket.WriteLn('Date: '+FormatDateTime(SMTPDateTemplate, Now));
      IF Msg.ReplyTo<>'' THEN Socket.WriteLn('Reply-To: '+Msg.ReplyTo);
      IF Msg.Organisation<>'' THEN Socket.Writeln('Organisation: '+Msg.Organisation);
      IF Assigned(Msg.FileAttaches) THEN
      BEGIN
         Msg.MimeVersion:='1.0';
         Msg.ContentType:='multipart/mixed';
      END;
      Msg.Boundary:=aslEncode.MakeUniqueID;
      IF Msg.MimeVersion<>'' THEN Socket.Writeln('Mime-Version: '+Msg.MimeVersion);
      IF Msg.ContentType<>'' THEN Socket.Writeln('Content-Type: '+Msg.ContentType+'; boundary="'+Msg.Boundary+'"');
      Socket.WriteLn('');

      IF Assigned(Msg.FileAttaches) THEN
      BEGIN
        Socket.WriteLn('  This message is in MIME format.  The first part should be readable text,');
        Socket.WriteLn('  while the remaining parts are likely unreadable without MIME-aware tools.');
        Socket.WriteLn('  Send mail to mime@docserver.cac.washington.edu for more info.');
        Socket.WriteLn('');
        Socket.WriteLn('--'+Msg.Boundary);
        Socket.WriteLn('Content-Type: text/plain; charset="us-ascii"');
        Socket.WriteLn('');
      END;
    END;
    SendMsgLines(Msg.MsgBody);

    IF Assigned(Msg.FileAttaches) THEN
    BEGIN
      Mime := TMimeMgr.Create;
      Socket.WriteLn('');
      FOR i:=1 TO Msg.FileAttaches.Count DO
      BEGIN
        Socket.WriteLn('--'+Msg.Boundary);
        Msg.FileAttaches.Get(i, Filename, E);
        Content := Mime.MimeType(ExtractFilename(Filename));
        Socket.WriteLn('Content-Type: '+Content+'; name="'+ExtractFilename(Filename)+'"');
        Content := 'Content-Transfer-Encoding: ';
        CASE E OF
          encNone : Content := '';
          enc64   : Content := Content + 'base64';
          encUU   : Content := Content + 'x-uuencode';
          encXX   : Content := Content + 'x-xxencode';
        END;
        IF Content <> '' THEN Socket.WriteLn(Content);
        Socket.WriteLn('');
        CASE E OF
          enc64 : Encode := T64Encode.Create(Filename);
          encUU : Encode := TUUEncode.Create(Filename);
          encXX : Encode := TXXEncode.Create(Filename);
        END;
        WHILE NOT Encode.EncodeEof DO Socket.WriteLn(Encode.Encode);
        Encode.Destroy;
        Encode:=Nil;
        Socket.WriteLn('');
      END;
      Socket.WriteLn('--'+Msg.Boundary+'--');
      Mime.Destroy;
    END;
    Socket.WriteLn('.');

    GetResponse(Nil);
  END;

{ TAttachments }


  CONSTRUCTOR TAttachments.Create;
  BEGIN
    INHERITED Create;
    FFiles := TStringList.Create;
    FNum := 0;
  END;

  DESTRUCTOR TAttachments.Destroy;
  VAR
    i:Integer;
  BEGIN
    FOR i:=1 TO FNum DO FreeMem(FEncode[i], SizeOf(TEncode));
    FFiles.Destroy;
    INHERITED Destroy;
  END;

  PROCEDURE TAttachments.Add(Filename : String; Encode : TEncode);
  BEGIN
    FFiles.Add(Filename);
    Inc(FNum, 1);
    GetMem(FEncode[FNum], SizeOf(TEncode));
    FEncode[FNum]^ := Encode;
  END;

  FUNCTION TAttachments.Count : LongInt;
  BEGIN
    RESULT := FNum;
  END;

  FUNCTION TAttachments.Get(Index : LongInt; Var Filename : String; Var Encode : TEncode) : Boolean;
  BEGIN
    Result := False;
    Filename := '';
    Encode := encNone;
    IF (Index<1) OR (Index>FNum) Then Exit;
    Filename := FFiles[Index-1];
    Encode := FEncode[Index]^;
  END;

{ TSMTPMessage }

  CONSTRUCTOR TSMTPMessage.Create;
  BEGIN
    INHERITED Create;
    FHeader:=True;
    FFrom:='';
    FTo:=nil;
    FSubject:='';
    FMessageID:='';
    FDate:='';
    FReplyTo:='';
    FOrganisation:='';
    FMimeVersion:='';
    FContentType:='';
    FMsgBody:=Nil;
    FileAttaches:=Nil;
  END;

  DESTRUCTOR TSMTPMessage.Destroy;
  BEGIN
    IF Assigned(FTo) THEN FTo.Destroy;
    IF Assigned(FMsgBody) THEN FMsgBody.Destroy;
    IF Assigned(FileAttaches) THEN FileAttaches.Destroy;
    INHERITED Destroy;
  END;

  PROCEDURE TSMTPMessage.Clear;
  BEGIN
    IF Assigned(FTo) THEN FTo.Destroy;
    IF Assigned(FMsgBody) THEN FMsgBody.Destroy;
    IF Assigned(FileAttaches) THEN FileAttaches.Destroy;
    FHeader:=True;
    FFrom:='';
    FTo:=nil;
    FSubject:='';
    FMessageID:='';
    FDate:='';
    FReplyTo:='';
    FOrganisation:='';
    FMimeVersion:='';
    FContentType:='';
    FMsgBody:=Nil;
    FileAttaches:=Nil;
  END;

  PROCEDURE TSMTPMessage.AddTo(To_: STRING);
  BEGIN
    IF NOT Assigned(FTo) THEN FTo:=TStringList.Create;
    FTo.Add(To_);
  END;

  PROCEDURE TSMTPMessage.AddMsgBody(Line: STRING);
  BEGIN
    IF NOT Assigned(FMsgBody) THEN FMsgBody:=TStringList.Create;
    FMsgBody.Add(Line);
  END;

  PROCEDURE TSMTPMessage.AddAttach(Filename: STRING; Encode: TEncode);
  BEGIN
    IF NOT Assigned(FileAttaches) THEN FileAttaches:=TAttachments.Create;
    FileAttaches.Add(Filename, Encode);
  END;

END.


{
  $Log: aslsmtpclient.pas,v $
  Revision 1.15  2002/01/12 16:17:13  MH
  - AUTH DIGEST-MD5: Debugcode hinzugefuegt (immer noch keine Funktion)

  Revision 1.14  2002/01/12 11:05:05  MH
  - Informationen hinzugefuegt

  Revision 1.13  2002/01/12 10:36:21  MH
  - SMTP-AUTH CRAM-MD5 funktioniert nun ebenso

  Revision 1.12  2002/01/06 13:46:42  MH
  - Auth: Logic gefixt

  Revision 1.11  2002/01/06 11:40:52  MH
  - versehentlich weisse Zeichen Encodiert

  Revision 1.10  2002/01/06 10:02:08  MH
  - LastResponseCode fuer DIGEST- und CRAM-MD5 angepasst

  Revision 1.9  2002/01/06 09:52:28  MH
  - AUTH PLAIN funktioniert nun auch...;)

  Revision 1.8  2002/01/06 08:40:33  MH
  - kleine marginale Veraenderung: Man sollte eben doch so spaet niczts mehr tun!

  Revision 1.7  2002/01/06 00:17:42  MH
  - kleine marginale Veraenderung

  Revision 1.6  2002/01/05 21:15:45  MH
  - ueberfluessigen Code entfernt

  Revision 1.5  2002/01/05 19:53:29  MH
  - SmtpAuth: Weitere Methoden hinzugefuegt...
              - PLAIN
              - CRAM-MD5
              - MD5-DIGEST
    ...ob die auch funktionieren, kann nicht sicher gestellt werden.
    Bei CRAM-MD5 fehlt mir noch eine Information, um es zur Funktion zu bringen.
    Aber dafuer erhaelt man schon mal eine Fehlermeldung...;)

  Revision 1.4  2002/01/05 17:31:10  MH
  - SmtpAuth optimiert und ergaenzt

  Revision 1.3  2002/01/05 14:03:32  MH
  - Tippfehler beseitigt
  - SmtpAuth (LOGIN) implementiert
  - APOP optimiert (ueberfluessigen Code entfernt)

  Revision 1.2  2002/01/01 22:25:42  MH
  - Vorsorgliche Fixes fuer AccessViolation (SockErrNo)

  Revision 1.1  2001/07/11 19:47:16  rb
  checkin


}
