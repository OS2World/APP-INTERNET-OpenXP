{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.2 $    $Date: 2002/01/02 23:16:47 $    $Author: MH $ }
{                                                                             }
{ Network News Transfer Protocol (NNTP) client class (RFC 977)                }
{ (extensions from 'draft-ietf-nntpext-imp-03.txt')                           }

{ $Id: aslnntpclient.pas,v 1.2 2002/01/02 23:16:47 MH Exp $ }

UNIT aslNNTPClient;

{$I aslDefine.Inc}

INTERFACE

USES Classes, SysUtils, aslAbsSocket, aslTCPSocket, aslAbsClient;

TYPE
  EAbsNNTPClient = class(EaslException);
  TAbsNNTPClient = CLASS(TAbsClient)
  PUBLIC
    CONSTRUCTOR Create;
    DESTRUCTOR Destroy; // OVERRIDE;
    PROCEDURE Connect(Host: STRING); OVERRIDE;
    PROCEDURE Disconnect; OVERRIDE;

{ RFC 977 commands }
    PROCEDURE ArticleById(Id: STRING; Article: TStringList);
    PROCEDURE ArticleByNo(No: Integer; Article: TStringList);
    PROCEDURE HeadById(Id: STRING; Head: TStringList);
    PROCEDURE HeadByNo(No: Integer; Head: TStringList);
    PROCEDURE BodyById(Id: STRING; Body: TStringList);
    PROCEDURE BodyByNo(No: Integer; Body: TStringList);
    PROCEDURE StatById(Id: STRING);
    PROCEDURE StatByNo(No: Integer);
    FUNCTION  Group(GroupName: STRING): Boolean; VIRTUAL;
    PROCEDURE Help(HelpText: TStringList);
    PROCEDURE IHave(Id: STRING; Article: TStringList);
    PROCEDURE Last;
    PROCEDURE List(Dest: TStringList);
    PROCEDURE NewGroups(DateTime: TDateTime; GMT: Boolean; Distributions: STRING; Groups: TStringList);
    PROCEDURE NewNews(NewsGroups: STRING; DateTime: TDateTime; GMT: Boolean; Distributions: STRING; Articles: TStringList);
    PROCEDURE Next;
    PROCEDURE Post(Article: TStringList);
    PROCEDURE Quit;
    PROCEDURE Slave;

{ Extensions -->
    PROCEDURE XHdrById(HeaderField: STRING; Id: STRING; Headers: TStringList);
    PROCEDURE XHdrByNo(HeaderField: STRING; No: STRING; Headers: TStringList);
 Extensions <-- }
 END;

  TNNTPClient = CLASS(TAbsNNTPClient)
  PRIVATE
    FPostingPermitted : Boolean;
    FGroupName        : STRING;

    PROCEDURE DecodeGroupResponse;
  PUBLIC
    CONSTRUCTOR Create;
    PROCEDURE Connect(Host: STRING); OVERRIDE;
    PROCEDURE Disconnect; OVERRIDE;
    FUNCTION  Group(GroupName: STRING): Boolean; OVERRIDE;

    PROPERTY PostingPermitted: Boolean     READ FPostingPermitted;
    PROPERTY GroupName: STRING             READ FGroupName WRITE Group;
  END;

IMPLEMENTATION

  CONSTRUCTOR TAbsNNTPClient.Create;
  BEGIN
    INHERITED Create;
    Service:='nntp';
  END;

  DESTRUCTOR TAbsNNTPClient.Destroy;
  BEGIN
    IF Assigned(Socket) THEN Quit;
    INHERITED Destroy;
  END;

  PROCEDURE TAbsNNTPClient.Connect(Host: STRING);
  BEGIN
    INHERITED Connect(Host);
    IF (LastResponseCode<>200) AND (LastResponseCode<>201) THEN
      RAISE EAbsNNTPClient.Create('Connect', LastResponse);
  END;

  PROCEDURE TAbsNNTPClient.Disconnect;
  BEGIN
    Quit;
    INHERITED Disconnect;
  END;


  PROCEDURE TAbsNNTPClient.ArticleById(Id: STRING; Article: TStringList);
  BEGIN
    SendCommand('ARTICLE <'+Id+'>');
    IF LastResponseCode<>220 THEN
      RAISE EAbsNNTPClient.Create('ArticleById', LastResponse);
    GetMsgLines(Article);
  END;

  PROCEDURE TAbsNNTPClient.ArticleByNo(No: Integer; Article: TStringList);
  BEGIN
    SendCommand('ARTICLE '+IntToStr(No));
    IF LastResponseCode<>220 THEN
      RAISE EAbsNNTPClient.Create('ArticleByNo', LastResponse);
    GetMsgLines(Article);
  END;

  PROCEDURE TAbsNNTPClient.HeadById(Id: STRING; Head: TStringList);
  BEGIN
    SendCommand('HEAD <'+Id+'>');
    IF LastResponseCode<>221 THEN
      RAISE EAbsNNTPClient.Create('HeadById', LastResponse);
    GetMsgLines(Head);
  END;

  PROCEDURE TAbsNNTPClient.HeadByNo(No: Integer; Head: TStringList);
  BEGIN
    SendCommand('HEAD '+IntToStr(No));
    IF LastResponseCode<>221 THEN
      RAISE EAbsNNTPClient.Create('HeadByNo', LastResponse);
    GetMsgLines(Head);
  END;

  PROCEDURE TAbsNNTPClient.BodyById(Id: STRING; Body: TStringList);
  BEGIN
    SendCommand('BODY <'+Id+'>');
    IF LastResponseCode<>222 THEN
      RAISE EAbsNNTPClient.Create('BodyById', LastResponse);
    GetMsgLines(Body);
  END;

  PROCEDURE TAbsNNTPClient.BodyByNo(No: Integer; Body: TStringList);
  BEGIN
    SendCommand('BODY '+IntToStr(No));
    IF LastResponseCode<>222 THEN
      RAISE EAbsNNTPClient.Create('BodyByNo', LastResponse);
    GetMsgLines(Body);
  END;

  PROCEDURE TAbsNNTPClient.StatById(Id: STRING);
  BEGIN
    SendCommand('STAT <'+Id+'>');
    IF LastResponseCode<>223 THEN
      RAISE EAbsNNTPClient.Create('StatById', LastResponse);
  END;

  PROCEDURE TAbsNNTPClient.StatByNo(No: Integer);
  BEGIN
    SendCommand('STAT '+IntToStr(No));
    IF LastResponseCode<>223 THEN
      RAISE EAbsNNTPClient.Create('StatByNo', LastResponse);
  END;

  FUNCTION TAbsNNTPClient.Group(GroupName: STRING): Boolean;
  BEGIN
    SendCommand('GROUP '+GroupName);
    IF (LastResponseCode<>211) AND (LastResponseCode<>411) THEN
      RAISE EAbsNNTPClient.Create('Group', LastResponse);
    Result:=(LastResponseCode=211);
  END;

  PROCEDURE TAbsNNTPClient.Help(HelpText: TStringList);
  BEGIN
    SendCommand('HELP');
    IF LastResponseCode<>100 THEN
      RAISE EAbsNNTPClient.Create('Help', LastResponse);
    GetMsgLines(HelpText);
  END;

  PROCEDURE TAbsNNTPClient.IHave(Id: STRING; Article: TStringList);
  VAR
    I : Integer;
  BEGIN
    SendCommand('IHAVE <'+Id+'>');
    IF LastResponseCode<>335 THEN
      RAISE EAbsNNTPClient.Create('IHave', LastResponse);
    FOR I:=0 TO Article.Count DO
    BEGIN
      IF Copy(Article[I],1,1)='.' THEN Article[I]:=Article[I]+'.';
      Socket.WriteLn(Article[I]);
    END;
    Socket.WriteLn('.');
    GetResponse(Nil);
    IF LastResponseCode<>235 THEN
      RAISE EAbsNNTPClient.Create('IHave: After transfer.', LastResponse);
  END;

  PROCEDURE TAbsNNTPClient.Last;
  BEGIN
    SendCommand('LAST');
    IF LastResponseCode<>223 THEN
      RAISE EAbsNNTPClient.Create('Last', LastResponse);
  END;

  PROCEDURE TAbsNNTPClient.List(Dest: TStringList);
  BEGIN
    SendCommand('LIST');
    IF LastResponseCode<>215 THEN
      RAISE EAbsNNTPClient.Create('List', LastResponse);
    GetMsgLines(Dest);
  END;

  FUNCTION IsGMT(GMT: Boolean): STRING;
  BEGIN
    IF GMT THEN Result:='GMT' ELSE Result:='';
  END;

  PROCEDURE TAbsNNTPClient.NewGroups(DateTime: TDateTime; GMT: Boolean; Distributions: STRING; Groups: TStringList);
  BEGIN
//    SendCommand('NEWGROUPS '+FormatDateTime('yymmdd hhnnss',DateTime)+' '+IsGMT(GMT)+' ['+Distributions+']');
    if Distributions<>'' then Distributions:='['+Distributions+']';
    SendCommand('NEWGROUPS '+FormatDateTime('yymmdd hhnnss',DateTime)+' '+IsGMT(GMT)+' '+Distributions);
    IF LastResponseCode<>231 THEN
      RAISE EAbsNNTPClient.Create('NewGroups', LastResponse);
    GetMsgLines(Groups);
  END;

  PROCEDURE TAbsNNTPClient.NewNews(NewsGroups: STRING; DateTime: TDateTime; GMT: Boolean; Distributions: STRING; Articles: TStringList);
  BEGIN
    SendCommand('NEWNEWS '+NewsGroups+FormatDateTime(' yymmdd hhnnss',DateTime)+' '+IsGMT(GMT)+' ['+Distributions+']');
    IF LastResponseCode<>230 THEN
      RAISE EAbsNNTPClient.Create('NewNews', LastResponse);
    GetMsgLines(Articles);
  END;

  PROCEDURE TAbsNNTPClient.Next;
  BEGIN
    SendCommand('NEXT');
    IF LastResponseCode<>223 THEN
      RAISE EAbsNNTPClient.Create('Last', LastResponse);
  END;

  PROCEDURE TAbsNNTPClient.Post(Article: TStringList);
  VAR
    I : Integer;
  BEGIN
    SendCommand('POST');
    IF LastResponseCode<>340 THEN
      RAISE EAbsNNTPClient.Create('Post', LastResponse);
    FOR I:=0 TO Article.Count-1 DO
    BEGIN
      IF Copy(Article[I],1,1)='.' THEN Article[I]:='.'+Article[I];
      Socket.WriteLn(Article[I]);
    END;
    Socket.WriteLn('.');
    GetResponse(Nil);
    IF LastResponseCode<>240 THEN
      RAISE EAbsNNTPClient.Create('Post: After transfer', LastResponse);
  END;

  PROCEDURE TAbsNNTPClient.Quit;
  BEGIN
    SendCommand('QUIT');
    IF LastResponseCode<>205 THEN
      RAISE EAbsNNTPClient.Create('Quit', LastResponse);
  END;

  PROCEDURE TAbsNNTPClient.Slave;
  BEGIN
    SendCommand('SLAVE');
    IF LastResponseCode<>202 THEN
      RAISE EAbsNNTPClient.Create('Slave', LastResponse);
  END;

{ Extensions -->

  PROCEDURE TAbsNNTPClient.XHdrById(HeaderField: STRING; Id: STRING; Headers: TStringList);
  BEGIN
    SendCommand('XHDR <'+Id+'>');
    IF LastResponseCode<>221 THEN
      RAISE EAbsNNTPClient.Create('XHdrById: Error getting headers text.', LastResponse);
    GetMsgLines(Headers);
  END;

  PROCEDURE TAbsNNTPClient.XHdrByNo(HeaderField: STRING; No: STRING; Headers: TStringList);
  BEGIN
    SendCommand('XHDR '+No);
    IF LastResponseCode<>221 THEN
      RAISE EAbsNNTPClient.Create('XHdrByNo: Error getting headers text.', LastResponse);
    GetMsgLines(Headers);
  END;

  Extensions <-- }


  CONSTRUCTOR TNNTPClient.Create;
  BEGIN
    INHERITED Create;
    FPostingPermitted:=False;
    FGroupName:='';
  END;

  PROCEDURE TNNTPClient.Connect(Host: STRING);
  BEGIN
    INHERITED Connect(Host);
    FPostingPermitted:=(LastResponseCode=200)
  END;

  PROCEDURE TNNTPClient.Disconnect;
  BEGIN
    Quit;
    INHERITED Disconnect;
    FPostingPermitted:=False;
    FGroupName:='';
  END;

{ 211 n f l s group selected
          (n = estimated number of articles in group,
           f = first article number in the group,
           l = last article number in the group,
           s = name of the group.)}
  PROCEDURE TNNTPClient.DecodeGroupResponse;
  BEGIN

  END;

  FUNCTION TNNTPClient.Group(GroupName: STRING): Boolean;
  BEGIN
    IF INHERITED Group(GroupName) THEN FGroupName:=GroupName ELSE FGroupName:='';
//    DecodeGroupResponse(FLastResponse, FGrpNumArticle, FGrpFirstArticle, FGrpLastArticle, FGrpName)
  END;


END.


{
  $Log: aslnntpclient.pas,v $
  Revision 1.2  2002/01/02 23:16:47  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.1  2001/07/11 19:47:16  rb
  checkin


}
