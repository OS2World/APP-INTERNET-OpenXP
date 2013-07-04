{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.2 $    $Date: 2002/01/01 22:25:41 $    $Author: MH $ }
{                                                                             }
{ Abstract Client class                                                       }

{ $Id: aslAbsClient.PAS,v 1.2 2002/01/01 22:25:41 MH Exp $ }

UNIT aslAbsClient;

{$I aslDefine.Inc}

INTERFACE

USES Classes, SysUtils, aslAbsSocket, aslTCPSocket;

TYPE
  EAbsClient = class(EaslException);

  TAbsClient = CLASS
  PRIVATE
    FSocket           : TTCPClientSocket;
    FHost             : STRING;
    FService          : STRING;
    FGreeting         : STRING;
    FLastResponse     : STRING;
    FLastResponseCode : Word;
    FOnLogLine        : TOnLogLineProc;

  PROTECTED
    PROCEDURE SendCommand(Cmd: STRING);
    PROCEDURE SendCommandEx(Cmd: STRING; Extra: TStringList);
    PROCEDURE GetResponse(Extra: TStringList); VIRTUAL;
    PROCEDURE GetMsgLines(StringList: TStringList);
    PROCEDURE SendMsgLines(StringList: TStringList);
    PROCEDURE GetLines(StringList: TStringList);
    PROCEDURE SendLines(StringList: TStringList);
    PROCEDURE LogLine(Msg: STRING);

  PUBLIC
    CONSTRUCTOR Create;
    DESTRUCTOR Destroy; OVERRIDE;
    PROCEDURE Connect(Host: STRING); VIRTUAL;
    PROCEDURE Disconnect; VIRTUAL;

    PROPERTY Socket: TTCPClientSocket      READ FSocket;
    PROPERTY Host: STRING                  READ FHost;
    PROPERTY Service: STRING               READ FService          WRITE FService;
    PROPERTY Greeting: STRING              READ FGreeting;
    PROPERTY LastResponse: STRING          READ FLastResponse     WRITE FLastResponse;
    PROPERTY LastResponseCode: Word        READ FLastResponseCode WRITE FLastResponseCode;
    PROPERTY OnLogLine: TOnLogLineProc     READ FOnLogLine        WRITE FOnLogLine;
  END;

IMPLEMENTATION

  CONSTRUCTOR TAbsClient.Create;
  BEGIN
    INHERITED Create;
    FSocket:=TBufTCPClientSocket.Create;
    FHost:='';
    FService:='';
    FGreeting:='';
    FLastResponse:='';
    FLastResponseCode:=0;
    FOnLogLine:=NIL;
  END;

  DESTRUCTOR TAbsClient.Destroy;
  BEGIN
    IF Assigned(FSocket) THEN
    BEGIN
      FSocket.Destroy;
    END;
    INHERITED Destroy;
  END;

  PROCEDURE TAbsClient.Connect(Host: STRING);
  BEGIN
    IF FService='' THEN
      RAISE EAbsClient.Create('Connect: No service specified', '');
    IF NOT Assigned(FSocket) THEN
      RAISE EAbsClient.Create('Connect: Socket is not initialized (Service='+FService+')', '');
    FHost:=Host;
    FSocket.Connect(FHost, FService);
    GetResponse(Nil);
    FGreeting:=FLastResponse;
  END;

  PROCEDURE TAbsClient.Disconnect;
  BEGIN
    FSocket.Disconnect;
    FHost:='';
    FService:='';
    FLastResponse:='';
    FLastResponseCode:=0;
  END;


  PROCEDURE TAbsClient.SendCommand(Cmd: STRING);
  BEGIN
    LogLine('<'+Cmd);
    FSocket.WriteLn(Cmd);
    GetResponse(Nil);
  END;

  PROCEDURE TAbsClient.SendCommandEx(Cmd: STRING; Extra: TStringList);
  BEGIN
    LogLine('<'+Cmd);
    FSocket.WriteLn(Cmd);
    GetResponse(Extra);
  END;

  PROCEDURE TAbsClient.GetResponse(Extra: TStringList);
  VAR
    Ok,i : Integer;
  BEGIN
    FSocket.ReadLn(FLastResponse);
    LogLine('>'+FLastResponse);
    (*
    while (length(FLastResponse) > 0) and
          ((FLastResponse[1] = ' ') or (FLastResponse[1] = #9))
      do delete(FLastResponse, 1, 1);
    *)
    Val(Copy(FLastResponse,1,3), FLastResponseCode, Ok);
    if Ok<>0 then FLastResponseCode:=0;
    WHILE Copy(FLastResponse,4,1)='-' DO
    BEGIN
      FSocket.ReadLn(FLastResponse);
      IF Extra<>nil THEN Extra.Add(Copy(FLastResponse,5,Length(FLastResponse)-4));
      LogLine('>'+FLastResponse);
    END;
  END;

  PROCEDURE TAbsClient.GetMsgLines(StringList: TStringList);
  VAR
    S, S1 : STRING;
  BEGIN
    REPEAT
      FSocket.ReadLn(S);
      S1:=S;
      IF (Length(S)>1) AND (Copy(S,1,1)='.') THEN S:=Copy(S, 2, Length(S)-1);
      IF (S1<>'.') AND Assigned(StringList) THEN StringList.Add(S);
    UNTIL S1='.';
  END;

  PROCEDURE TAbsClient.SendMsgLines(StringList: TStringList);
  VAR
    i : Integer;
  BEGIN
    IF Assigned(StringList) THEN
      FOR i:=0 TO StringList.Count-1 DO
        IF (StringList[i]<>'') AND (Copy(StringList[i],1,1)='.') THEN
          Socket.WriteLn('.'+StringList[i])
        ELSE
          Socket.WriteLn(StringList[i]);
  END;

  PROCEDURE TAbsClient.GetLines(StringList: TStringList);
  VAR
    S : STRING;
  BEGIN
    WHILE FSocket.WaitForDataTime(1000)>0 DO
    BEGIN
      FSocket.ReadLn(S);
      LogLine('>'+S);
      IF Assigned(StringList) THEN StringList.Add(S);
    END;
  END;

  PROCEDURE TAbsClient.SendLines(StringList: TStringList);
  VAR
    i : Integer;
  BEGIN
    IF Assigned(StringList) THEN
      FOR i:=0 TO StringList.Count-1 DO
      Socket.WriteLn(StringList[i]);
  END;

  PROCEDURE TAbsClient.LogLine(Msg: STRING);
  BEGIN
    IF Assigned(FOnLogLine) THEN FOnLogLine(Msg);
  END;

END.


{
  $Log: aslAbsClient.PAS,v $
  Revision 1.2  2002/01/01 22:25:41  MH
  - Vorsorgliche Fixes fuer AccessViolation (SockErrNo)

  Revision 1.1  2001/07/11 19:47:16  rb
  checkin


}
