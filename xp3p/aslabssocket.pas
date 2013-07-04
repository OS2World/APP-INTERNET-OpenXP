{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.2 $    $Date: 2001/12/31 12:38:33 $    $Author: MH $ }
{                                                                             }
{ Abstract sockets class                                                      }

{ $Id: aslabssocket.pas,v 1.2 2001/12/31 12:38:33 MH Exp $ }

UNIT aslAbsSocket;

{$I aslDefine.Inc}

INTERFACE

USES SysUtils, CTypes, aslSocket,
{$IFDEF OS2}
     OS2Def, OS2Socket, NetDB, Utils, ioctl;
{$ELSE}
     Winsock;
{$ENDIF}


CONST
  INVALID_SOCKET = -1;

TYPE
  TOnLogLineProc = PROCEDURE(Msg: STRING) OF OBJECT;

  EaslException = CLASS(Exception)
    CONSTRUCTOR Create(CONST Where, ErrCode: STRING);
  END;

  EAbsSocket = CLASS(EaslException);

  TAbsSocket = CLASS
  PRIVATE
    FSocketHandle : Integer;
    FBlocking     : Boolean;
    FProtocol     : STRING;
    FPortN        : Integer;
    FOnLogLine    : TOnLogLineProc;

    PROCEDURE SetBlocking(Blocking: boolean);
    FUNCTION  GetBytesAvail: Integer;

    PROCEDURE SetBroadcast(Broadcast: Boolean);
    FUNCTION  GetBroadcast: Boolean;
    PROCEDURE SetReuseAddr(Reuse: Boolean);
    FUNCTION  GetReuseAddr: Boolean;
  PROTECTED
    PROCEDURE LogLine(Msg: STRING);

  PUBLIC
    CONSTRUCTOR Create;
    DESTRUCTOR Destroy;
    PROCEDURE Disconnect; VIRTUAL;
    FUNCTION ResolvePort(Port: STRING): ushort;


    FUNCTION Accept(var name: sockaddr; var namelen: Integer): Integer;
    FUNCTION Bind(var name: sockaddr; namelen: Integer): Integer;
    FUNCTION Connect(var name: sockaddr; namelen: Integer): Integer;
//  FUNCTION GetHostId: Integer;
    FUNCTION GetPeerName(var name: sockaddr; namelen: Integer): Integer;
    FUNCTION GetSockName(var name: sockaddr; namelen: Integer): Integer;
    FUNCTION GetSockOpt(level: Integer; optname: Integer; var optval; var optlen: Integer): Integer;
    FUNCTION IOCtl(cmd: Integer; var data; datalen: Integer): Integer;
    FUNCTION Listen(backlog: Integer): Integer;
{$IFDEF OS2}
    FUNCTION RecvMsg(var msg: msghdr; flags: Integer): Integer;
{$ENDIF}
    FUNCTION Recv(var buf; len: Integer; flags: Integer): Integer;
    FUNCTION RecvFrom(var buf; len: Integer; flags: Integer; var name: sockaddr; var namelen: Integer): Integer;
    FUNCTION Select(s: pointer; noreads: int; nowrites: int; noexcepts: int; timeout: long): Integer;
    FUNCTION Send(var buf; len: Integer; flags: Integer): Integer;
{$IFDEF OS2}
    FUNCTION SendMsg(var msg: msghdr; flags: Integer): Integer;
{$ENDIF}
    FUNCTION SendTo(var buf; len: Integer; flags: Integer; var name: sockaddr; namelen: Integer): Integer;
    FUNCTION SetSockOpt(level: Integer; optname: Integer; var optval; optlen: Integer): Integer;
//  FUNCTION sock_init: Integer;
    FUNCTION SockErrNo: Integer;
//  PROCEDURE psock_errno(error: pchar);
    FUNCTION Socket(domain: Integer; stype: Integer; protocol: Integer): Integer;
    FUNCTION Close: Integer;
    FUNCTION Abort: Integer;
    FUNCTION Cancel: Integer;
{$IFDEF OS2}
    FUNCTION ReadV(var iov; iovcnt: Integer): Integer;
    FUNCTION WriteV(var iov; iovcnt: Integer): Integer;
{$ENDIF}
    FUNCTION ShutDown(howto: Integer): Integer;

    PROCEDURE SetLinger(OnOff: Boolean; Secs: Integer);
    FUNCTION  GetLinger(VAR Secs: Integer): Boolean;


    PROPERTY SocketHandle: Integer      READ FSocketHandle WRITE FSocketHandle;
    PROPERTY Protocol: STRING           READ FProtocol     WRITE FProtocol;
    PROPERTY PortN: Integer             READ FPortN;
    PROPERTY OnLogLine: TOnLogLineProc  READ FOnLogLine    WRITE FOnLogLine;

    PROPERTY Blocking: Boolean          READ FBlocking     WRITE SetBlocking;
    PROPERTY Broadcast: Boolean         READ GetBroadcast  WRITE SetBroadCast;
    PROPERTY ReuseAddr: Boolean         READ GetReuseAddr  WRITE SetReuseAddr;
    PROPERTY BytesAvail: Integer        READ GetBytesAvail;
  END;

IMPLEMENTATION

{ EaslException }

  CONSTRUCTOR EaslException.Create(CONST Where, ErrCode: STRING);
  BEGIN
    INHERITED Create(Where+'. (Error='+ErrCode+')');
  END;


{ EAbsSocket }

  CONSTRUCTOR TAbsSocket.Create;
  BEGIN
    INHERITED Create;
    FSocketHandle:=INVALID_SOCKET;
    FBlocking:=True;
    FProtocol:='';
    FPortN:=0;
    FOnLogLine:=NIL;
  END;

  DESTRUCTOR TAbsSocket.Destroy;
  BEGIN
    IF FSocketHandle<>INVALID_SOCKET THEN Disconnect;
    INHERITED Destroy;
  END;

  PROCEDURE TAbsSocket.Disconnect;
  BEGIN
    LogLine(Format('Closing connection on socket %d...',[FSocketHandle]));
    IF (Close<0) or (SockErrNo<>0) THEN   // =-1
      RAISE EAbsSocket.Create('Disconnect', IntToStr(SockErrNo));
    FSocketHandle:=INVALID_SOCKET;
  END;

  FUNCTION TAbsSocket.ResolvePort(Port: STRING): ushort;
  VAR
    PSE   : PServEnt;
  BEGIN
    LogLine(Format('Resolving port name %s',[Port]));
    PSE:=SockGetServByName(PORT, Protocol);
    IF not Assigned(PSE) THEN
    BEGIN
      LogLine(Format('Cannot resolv; using port number %s',[Port]));
      Result:=bswap(StrToInt(PORT));
      FPortN:=StrToInt(PORT);
    END else
    BEGIN
      Result:=PSE.s_port;
      FPortN:=bswap(PSE^.s_port);
      LogLine(Format('Resolved; port number %d',[FPortN]));
    END;
  END;


  FUNCTION TAbsSocket.Accept(VAR Name: sockaddr; VAR NameLen: Integer): Integer;
  BEGIN
    Result:=SockAccept(FSocketHandle, Name, NameLen)
  END;

  FUNCTION TAbsSocket.Bind(VAR Name: sockaddr; NameLen: Integer): Integer;
  BEGIN
    Result:=SockBind(FSocketHandle, Name, NameLen);
  END;

  FUNCTION TAbsSocket.Connect(VAR Name: sockaddr; NameLen: Integer): Integer;
  BEGIN
    Result:=SockConnect(FSocketHandle, Name, NameLen);
  END;

  FUNCTION TAbsSocket.GetPeerName(VAR Name: sockaddr; NameLen: Integer): Integer;
  BEGIN
    Result:=SockGetPeerName(FSocketHandle, Name, NameLen);
  END;

  FUNCTION TAbsSocket.GetSockName(VAR Name: sockaddr; NameLen: Integer): Integer;
  BEGIN
    Result:=SockGetSockName(FSocketHandle, Name, NameLen);
  END;

  FUNCTION TAbsSocket.GetSockOpt(level: Integer; optname: Integer; var optval; var optlen: Integer): Integer;
  BEGIN
    Result:=SockGetSockOpt(FSocketHandle, Level, OptName, OptVal, OptLen);
  END;

  FUNCTION TAbsSocket.IOCtl(cmd: Integer; var data; datalen: Integer): Integer;
  BEGIN
    Result:=SockIOCtl(FSocketHandle, Cmd, Data, DataLen);
  END;

  FUNCTION TAbsSocket.Listen(backlog: Integer): Integer;
  BEGIN
    Result:=SockListen(FSocketHandle, BackLog)
  END;

{$IFDEF OS2}
  FUNCTION TAbsSocket.RecvMsg(var msg: msghdr; flags: Integer): Integer;
  BEGIN
    Result:=SockRecvMsg(FSocketHandle, Msg, Flags);
  END;
{$ENDIF}

  FUNCTION TAbsSocket.Recv(var buf; len: Integer; flags: Integer): Integer;
  BEGIN
    Result:=SockRecv(FSocketHandle, Buf, Len, Flags);
  END;

  FUNCTION TAbsSocket.RecvFrom(var buf; len: Integer; flags: Integer; var name: sockaddr; var namelen: Integer): Integer;
  BEGIN
    Result:=SockRecvFrom(FSocketHandle, Buf, Len, Flags, Name, NameLen);
  END;

  FUNCTION TAbsSocket.Select(s: pointer; noreads: int; nowrites: int; noexcepts: int; timeout: long): Integer;
  BEGIN
    Result:=SockSelect(s, noreads, nowrites, noexcepts, timeout);
  END;

  FUNCTION TAbsSocket.Send(var buf; len: Integer; flags: Integer): Integer;
  BEGIN
    Result:=SockSend(FSocketHandle, Buf, Len, Flags);
  END;

{$IFDEF OS2}
  FUNCTION TAbsSocket.SendMsg(var msg: msghdr; flags: Integer): Integer;
  BEGIN
    Result:=SockSendMsg(FSocketHandle, Msg, Flags);
  END;
{$ENDIF}

  FUNCTION TAbsSocket.SendTo(var buf; len: Integer; flags: Integer; var name: sockaddr; namelen: Integer): Integer;
  BEGIN
    Result:=SockSendTo(FSocketHandle, Buf, Len, Flags, Name, NameLen);
  END;

  FUNCTION TAbsSocket.SetSockOpt(level: Integer; optname: Integer; var optval; optlen: Integer): Integer;
  BEGIN
    Result:=SockSetSockOpt(FSocketHandle, Level, OptName, OptVal, OptLen);
  END;

  FUNCTION TAbsSocket.SockErrNo: Integer;
  BEGIN
    Result:=aslSocket.SockErrNo;
  END;


  FUNCTION TAbsSocket.Socket(domain: Integer; stype: Integer; protocol: Integer): Integer;
  BEGIN
    Result:=SockSocket(Domain, SType, Protocol);
    FSocketHandle:=Result;
  END;

  FUNCTION TAbsSocket.Close: Integer;
  BEGIN
    Result:=SockClose(FSocketHandle);
  END;

  FUNCTION TAbsSocket.Abort: Integer;
  BEGIN
    Result:=SockAbort(FSocketHandle)
  END;

  FUNCTION TAbsSocket.Cancel: Integer;
  BEGIN
    Result:=SockCancel(FSocketHandle)
  END;

{$IFDEF OS2}
  FUNCTION TAbsSocket.ReadV(var iov; iovcnt: Integer): Integer;
  BEGIN
    Result:=SockReadV(FSocketHandle, iov, iovcnt);
  END;

  FUNCTION TAbsSocket.WriteV(var iov; iovcnt: Integer): Integer;
  BEGIN
    Result:=SockWriteV(FSocketHandle, iov, iovcnt)
  END;
{$ENDIF}

  FUNCTION TAbsSocket.ShutDown(Howto: Integer): Integer;
  BEGIN
    Result:=SockShutdown(FSocketHandle, Howto);
  END;

  PROCEDURE TAbsSocket.SetLinger(OnOff: Boolean; Secs: Integer);
  VAR
    l : Linger;
  BEGIN
    l.l_onoff:=Int(OnOff);
    l.l_linger:=Secs;
    IF (SetSockOpt(SOL_SOCKET, SO_LINGER, l, SizeOf(l))<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('SetLinger', IntToStr(SockErrNo));
  END;

  FUNCTION TAbsSocket.GetLinger(VAR Secs: Integer): Boolean;
  VAR
    l : Linger;
  BEGIN
    IF (SetSockOpt(SOL_SOCKET, SO_LINGER, l, SizeOf(l))<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('GetLinger', IntToStr(SockErrNo));
    GetLinger:=(l.l_onoff<>0);
    Secs:=l.l_linger;
  END;



  PROCEDURE TAbsSocket.LogLine(Msg: STRING);
  BEGIN
    IF Assigned(FOnLogLine) THEN FOnLogLine(Msg);
  END;



  PROCEDURE TAbsSocket.SetBlocking(Blocking: Boolean);
  VAR
    b: Integer;
  BEGIN
    b:=Integer(Blocking);
    IF (IOCtl(FIONBIO, b, SizeOf(b))<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('SetBlocking', IntToStr(SockErrNo));
    FBlocking:=Blocking;
  END;

  FUNCTION TAbsSocket.GetBytesAvail;
  VAR
    Bytes: Integer;
  BEGIN
    IF (IOCtl(FIONRead, Bytes, SizeOf(Bytes))<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('SetBlocking', IntToStr(SockErrNo));
    GetBytesAvail:=Bytes;
  END;

  PROCEDURE TAbsSocket.SetBroadcast(Broadcast: Boolean);
  VAR
    i : Integer;
  BEGIN
    i:=Int(Broadcast);
    IF (SetSockOpt(SOL_SOCKET, SO_BROADCAST, i, SizeOf(i))<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('SetBroadcast', IntToStr(SockErrNo));
  END;

  FUNCTION TAbsSocket.GetBroadcast: Boolean;
  VAR
    i, si: Integer;
  BEGIN
    si:=SizeOf(i);
    IF (GetSockOpt(SOL_SOCKET, SO_BROADCAST, i, si)<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('GetBroadcast', IntToStr(SockErrNo));
    GetBroadcast:=(i=1);
  END;

  PROCEDURE TAbsSocket.SetReuseAddr(Reuse: Boolean);
  VAR
    i : Integer;
  BEGIN
    i:=Int(Reuse);
    IF (SetSockOpt(SOL_SOCKET, SO_REUSEADDR, i, SizeOf(i))<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('SetReuseAddr', IntToStr(SockErrNo));
  END;

  FUNCTION TAbsSocket.GetReuseAddr: Boolean;
  VAR
    i, si: Integer;
  BEGIN
    si:=SizeOf(i);
    IF (GetSockOpt(SOL_SOCKET, SO_REUSEADDR, i, si)<0) or (SockErrNo<>0) THEN
      RAISE EAbsSocket.Create('GetReuseAddr', IntToStr(SockErrNo));
    GetReuseAddr:=(i=1);
  END;

END.


{
  $Log: aslabssocket.pas,v $
  Revision 1.2  2001/12/31 12:38:33  MH
  - Fix fuer AccessViolation, bei Verbindungstrennung mit fehlernder Quittierung
  - Vorsorglich auch die anderen Routinen abgesichert (SockErrNo)

  Revision 1.1  2001/07/11 19:47:16  rb
  checkin


}
