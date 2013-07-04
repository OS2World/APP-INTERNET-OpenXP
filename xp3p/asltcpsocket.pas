{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.4 $    $Date: 2002/01/02 23:16:48 $    $Author: MH $ }
{                                                                             }
{ OO interface to TCP sockets                                                 }

{ $Id: asltcpsocket.pas,v 1.4 2002/01/02 23:16:48 MH Exp $ }

UNIT aslTCPSocket;

{$I aslDefine.Inc}

INTERFACE

USES SysUtils, VPUtils, CTypes, aslSocket, aslAbsSocket,
{$IFDEF OS2}
     OS2Socket, NetDB, SockIn, Utils;
{$ELSE}
     Winsock;
{$ENDIF}

CONST
  BufSize = 4096;

TYPE
  ETCPSocket = CLASS(EaslException);
  ETCPClientSocket = CLASS(EaslException);
  EBufTCPClientSocket = CLASS(EaslException);
  ETCPServerSocket = CLASS(EaslException);

  TTCPSocket = CLASS(TAbsSocket)
  PRIVATE
    FPeerIP    : STRING;
    FPeerName  : STRING;
  PUBLIC
    CONSTRUCTOR Create;

    PROPERTY PeerIP: STRING             READ FPeerIP;
    PROPERTY PeerName: STRING           READ FPeerName;
  END;

  TTCPClientSocket = CLASS(TTCPSocket)
  PUBLIC
    PROCEDURE Connect(adr: STRING; PORT: STRING);
    PROCEDURE WaitForData; VIRTUAL;
    FUNCTION WaitForDataTime(Timeout: Word): Integer; VIRTUAL;
    FUNCTION Read(VAR Buf; len: Word): Word; VIRTUAL;
    FUNCTION ReadLn(VAR S: STRING): Word; VIRTUAL;
    FUNCTION Write(VAR Buf; len: Word): Word;
    FUNCTION WriteLn(S: STRING): Word;
  END;

  TBufTCPClientSocket = CLASS(TTCPClientSocket)
  PRIVATE
    FReadBuf : ARRAY[0..BufSize] OF Char;
    FBufPos  : Integer;
    FBufEnd  : Integer;
  PUBLIC
    CONSTRUCTOR Create;
    PROCEDURE WaitForData; OVERRIDE;
    FUNCTION WaitForDataTime(Timeout: Word): Integer; OVERRIDE;
    FUNCTION Read(VAR Buf; len: Word): Word; OVERRIDE;
    FUNCTION ReadLn(VAR S: STRING): Word; OVERRIDE;
  END;

  TTCPServerSocket = CLASS(TTCPSocket)
  PUBLIC
    CONSTRUCTOR Create(PORT: STRING);
    PROCEDURE Listen;
    PROCEDURE WaitForConnection;
    FUNCTION AcceptConnection: TTCPClientSocket;
  END;

IMPLEMENTATION

{ TTCPSocket }

  CONSTRUCTOR TTCPSocket.Create;
  BEGIN
    INHERITED Create;
    Protocol:='tcp';
    FPeerName:='';
    FPeerIP:='';
  END;


{ TTCPClientSocket }

  PROCEDURE TTCPClientSocket.Connect(adr: STRING; PORT: STRING);
  VAR
    phe   : PHostEnt;
    sin   : sockaddr_in;
    PE    : PProtoEnt;
  BEGIN
    LogLine('Creating client socket...');

    PE:=SockGetProtoByName(Protocol);  // ERROR check
    INHERITED Socket(PF_INET, SOCK_STREAM, PE^.p_proto);
    IF SockErrNo<>0 THEN
      RAISE ETCPClientSocket.Create('Connect', IntToStr(SockErrNo));
    sin.sin_family:=AF_INET;
    sin.sin_port:=ResolvePort(Port);
    sin.sin_addr.s_addr:=SockInetAddr(Adr);
    IF sin.sin_addr.s_addr=INADDR_NONE THEN
    BEGIN
      LogLine(Format('%s does not look like ip. Trying to use it as host name ',[adr]));
      phe:=SockGetHostByName(adr);
      IF (not Assigned(phe)) or (SockErrNo<>0) THEN
        RAISE ETCPClientSocket.Create('Connect: Host name '+adr+' unknown.', IntToStr (SockErrNo));
      LogLine('resolved host name');
      Sin.sin_addr:=phe^.h_addr^^;
    END;
    LogLine(Format('trying to connect to %s:%s',[adr, PORT]));
    IF (INHERITED Connect(sockaddr(sin), SizeOf(sin))<0) or (SockErrNo<>0)  THEN
      RAISE ETCPSocket.Create('Connect: Cannot connect to '+adr+':'+Port, IntToStr (SockErrNo));
    FPeerName:=adr;
  END;

  PROCEDURE TTCPClientSocket.WaitForData;
  VAR
    Sock : Integer;
  BEGIN
    LogLine(Format('Waiting for data on socket %d',[SocketHandle]));
    Sock:=SocketHandle;
    IF (INHERITED Select(@Sock,1,0,0,-1)<0) or (SockErrNo<>0) THEN
      RAISE ETCPClientSocket.Create('WaitForData', IntToStr(SockErrNo));
  END;

  FUNCTION TTCPClientSocket.WaitForDataTime(Timeout: Word): Integer;
  VAR
    Sock : Integer;
  BEGIN
    LogLine(Format('Waiting for data on socket %d for %d microseconds',[SocketHandle, Timeout]));
    Sock:=SocketHandle;
    Result:=Select(@Sock,1,0,0,Timeout);
    IF (Result<0) or (SockErrNo<>0) THEN
      RAISE ETCPClientSocket.Create('WaitForDataTime', IntToStr(SockErrNo));
  END;

  FUNCTION TTCPClientSocket.Read;
  BEGIN
    LogLine(Format('Reading data on socket %d...',[SocketHandle]));
    Result:=Recv(buf,len,0);
    IF (Result<0) or (SockErrNo<>0) THEN
      RAISE ETCPClientSocket.Create('Read', IntToStr(SockErrNo));
  END;

  FUNCTION TTCPClientSocket.ReadLn;
  VAR
    c : Char;
  BEGIN
    LogLine(Format('Reading data on socket %d...',[SocketHandle]));
    S:='';
    REPEAT
      Result:=Recv(c, SizeOf(c), 0);
      IF (c<>#10) AND (c<>#13) THEN S:=S+c;
    UNTIL (c=#10) OR (Result<0);
    IF (Result<0) or (SockErrNo<>0) THEN
      RAISE ETCPClientSocket.Create('ReadLn', IntToStr(SockErrNo));
    Result:=Length(S);
  END;

  FUNCTION TTCPClientSocket.Write;
  BEGIN
    LogLine(Format('Writing data to socket %d...',[SocketHandle]));
    Result:=Send(Buf, Len, 0);
    IF (Result<0) or (SockErrNo<>0) THEN
      RAISE ETCPClientSocket.Create('Write', IntToStr(SockErrNo));
  END;

  FUNCTION TTCPClientSocket.WriteLn;
  BEGIN
    S:=S+#13#10;
    Result:=Write(S[1],Length(S));
  END;


{ TBufTCPClientSocket }

  CONSTRUCTOR TBufTCPClientSocket.Create;
  BEGIN
    INHERITED Create;
    FBufPos:=0; FBufEnd:=0;
  END;

  PROCEDURE TBufTCPClientSocket.WaitForData;
  BEGIN
    IF FBufPos=FBufEnd THEN INHERITED WaitForData;
  END;

  FUNCTION TBufTCPClientSocket.WaitForDataTime(Timeout: Word): Integer;
  BEGIN
    IF FBufPos=FBufEnd THEN Result:=INHERITED WaitForDataTime(Timeout) ELSE Result:=1;
  END;

  FUNCTION TBufTCPClientSocket.Read(VAR Buf; Len: Word): Word;
  BEGIN
    IF FBufPos=FBufEnd THEN
    BEGIN
      FBufEnd:=INHERITED Read(FReadBuf, BufSize);
      FBufPos:=0;
      IF FBufEnd<0 THEN
      BEGIN
        FBufEnd:=0;
        Result:=-1;
        Exit;
      END;
    END;

    Move(Buf, FReadBuf[FBufPos], Min(FBufEnd, Len));
    FBufPos:=Min(FBufEnd, Len);
    Result:=FBufEnd-FBufPos;
  END;

  FUNCTION TBufTCPClientSocket.ReadLn(VAR S: STRING): Word;
  VAR
    c : Char;
  BEGIN
    S:='';
    Result:=0;
    REPEAT
      IF FBufPos=FBufEnd THEN Result:=Read(c, 0);       // Just fill buffer
      c:=FReadBuf[FBufPos];
      Inc(FBufPos);
      IF (c<>#10) AND (c<>#13) AND (FBufEnd>0) THEN S:=S+c;
//sag      IF (c<>#10) AND (c<>#13) THEN S:=S+c;
    UNTIL (c=#10) OR (Result<0) OR (FBufEnd=0);
//sag    UNTIL (c=#10) OR (Result<0);
    IF (Result<0) or (SockErrNo<>0) THEN
      RAISE EBufTCPClientSocket.Create('ReadLn', IntToStr(SockErrNo));
    Result:=Length(S);
  END;


{ TTCPServerSocket }

  CONSTRUCTOR TTCPServerSocket.Create(PORT: STRING);
  VAR
    sn : SockAddr_In;
    PE : PProtoEnt;
  BEGIN
    INHERITED Create;
    LogLine(Format('Creating master socket on port %s',[Port]));
    PE:=SockGetProtoByName(Protocol);  // ERROR check
    Socket(PF_INET, SOCK_STREAM, PE^.p_proto);
    IF SockErrNo<>0 THEN
      RAISE ETCPServerSocket.Create('Create', IntToStr(SockErrNo));
    LogLine(Format('master socket: %d',[SocketHandle]));
    sn.sin_family := AF_INET;
    sn.sin_addr.s_addr := INADDR_ANY;
    sn.sin_port:=ResolvePort(Port);
    LogLine('Binding socket');
    (* Bind the socket to the port *)
    IF (bind(SockAddr(sn),SizeOf(sn))<0) or (SockErrNo<>0) THEN
      RAISE ETCPServerSocket.Create('Create', IntToStr(SockErrNo));
  END;

  PROCEDURE TTCPServerSocket.Listen;
  VAR
    rc : Integer;
  BEGIN
    LogLine(Format('Putting socket on port %d in listen state',[PortN]));
    rc:=SockListen(SocketHandle, 1);
    IF (rc<0) or (SockErrNo<>0) THEN
      RAISE ETCPServerSocket.Create('Listen', IntToStr(SockErrNo));
  END;

  PROCEDURE TTCPServerSocket.WaitForConnection;
  VAR
    Sock, rc : Integer;
  BEGIN
    Sock:=SocketHandle;
    rc:=Select(@Sock,1,0,0,-1);
    IF (rc<0) or (SockErrNo<>0) THEN
      RAISE ETCPServerSocket.Create('WaitForConnect', IntToStr(SockErrNo));
  END;

  FUNCTION TTCPServerSocket.AcceptConnection;
  VAR
    TmpSock: int;
    sad    : SockAddr_In;
    phe    : PHostEnt;
    TmpCs  : TTCPClientSocket;
    l      : ULong;
  BEGIN
    Result := nil;
    LogLine('Accepting connection...');
    l:=SizeOf(Sad);
    TmpSock:=accept(sockaddr(sad),l);
    IF (TmpSock=INVALID_SOCKET) or (SockErrNo<>0) THEN
      RAISE ETCPServerSocket.Create('AcceptConnection', IntToStr(SockErrNo));
    FPeerIP:=SockInetntoa(sad.sin_addr);
    phe:=GetHostByAddr(sad.sin_addr, SizeOf(sad.sin_addr), AF_INET);
    IF NOT Assigned(phe) THEN
    BEGIN
      LogLine(Format('TTCPServerSocket.AcceptConnection: gethostbyaddr() failed; error code %d',[SockErrNo]));
      FPeerName := '';
    END else
      FPeerName := StrPas(phe^.h_name);
    TmpCs:=TTCPClientSocket.Create;
    TmpCs.SocketHandle:=TmpSock;
    Result:=TmpCs;
  END;

END.


{
  $Log: asltcpsocket.pas,v $
  Revision 1.4  2002/01/02 23:16:48  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.3  2002/01/01 22:25:42  MH
  - Vorsorgliche Fixes fuer AccessViolation (SockErrNo)

  Revision 1.2  2001/12/30 10:59:53  MH
  - Fix fuer AccessViolation, wenn die Verbindung nicht hergestellt werden kann

  Revision 1.1  2001/07/11 19:47:17  rb
  checkin


}
