{ ------------------------------------------------------------------------- }
{        Konverter fuer den Datenaustausch zwischen UUZ <-> VSOUP           }
{                                                                           }
{            weitere Informationen siehe beiliegende README                 }
{ ------------------------------------------------------------------------- }


{ $Id: xp2soup.pas,v 1.2 2000/06/01 21:01:55 tj Exp $ }


program xp2soup_prg;

{$I xpdefine.inc}

{$IFNDEF Ver32 }
{$M $8000,0,$10000}
{$ENDIF }

{==================================================================

   xp2soup 1.1.0 source code

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version
   2 of the License, or (at your option) any later version.

   Soll heissen: Macht damit, was ihr wollt, lasst bloss meinen
   Namen drin stehen.

   Autor: Torben Weibert <torben@weibert.com>


   xp2soup 1.1.1: bugfix by Robert Boeck
   xp2soup 1.1.2: 32Bit Port by XP2 Team

===================================================================}

uses dos,
{$IFDEF Ver32 }
     SysUtils,
{$ENDIF }
     textfile;

type ByteArray=array[0..0] of byte;

const version='1.1.2';
{$IFDEF OS2 }
const twj_plattform='OS/2';
{$ENDIF }
{$IFDEF Win32 }
const twj_plattform='Win32';
{$ENDIF }
{$IFDEF BP }
const twj_plattform='DOS';
{$ENDIF }

var TempDir:string;
    TempCounter:longint;
    FromName:string;

const hexChars:array[0..$F] of Char='0123456789ABCDEF';

function hex(w:word):string;
var s:string;
begin
  s:=hexChars[Hi(w) shr 4]
     +hexChars[Hi(w) and $F]
     +hexChars[Lo(w) shr 4]
     +hexChars[Lo(w) and $F];
  hex:=s;
end;

function  HexL(x:longint):string;
var xw:array[0..1] of word absolute x;
begin
  HexL:=hex(xw[1])+hex(xw[0]);
end;

function  exist(s:string):boolean;
var sr:searchrec;
begin
  dos.findfirst(s,anyfile-directory,sr);
  exist:=doserror=0;
{$IFDEF Ver32 }
  dos.Findclose(sr);
{$ENDIF }
end;

function  str2(l:longint):string;
var s:string;
begin
  system.str(l,s);
  str2:=s;
end;

function num2str (num: longint; base, width: byte): string; { by Robert Boeck }
  var s: string;
  begin
    s := '';
    repeat
      s := hexChars [num mod base] + s;
      num := num div base;
      if width > 0 then dec (width);
    until (width = 0) and (num = 0);
    num2str := s;
  end;

function  Min(a,b:longint):longint;
begin
        Min:=a*ord(a<b)+b*ord(b<=a);
end;

function  filecopy(s1,s2:string):boolean;
var FromF, ToF: file;
{$IFNDEF Ver32 }
    NumRead, NumWritten: Word;
{$ELSE }
    NumRead, NumWritten: LongInt;
{$ENDIF }
    buf:array[1..2048] of char;
    buf2,BufPtr:pointer;
    BufSize:word;
    x:longint;
begin
  FileCopy:=false;
  {$i-}
  assign(FromF,s1);
  reset(FromF,1);
  if IOResult<>0 then exit;
  if (maxAvail>FileSize(FromF)) and (maxAvail>SizeOf(buf)) then
  begin
    BufSize:=min(min(maxAvail,FileSize(FromF)),$ffff);
    GetMem(buf2,BufSize);
    BufPtr:=buf2;
  end
  else
  begin
    bufPtr:=@buf;
    BufSize:=SizeOf(buf);
    buf2:=nil;
  end;
  assign(ToF,s2);
  rewrite(ToF,1);
  if IOResult<>0 then exit;
  repeat
    blockRead(FromF,bufPtr^,BufSize,NumRead);
    if IOResult<>0 then exit;
    BlockWrite(ToF,BufPtr^,NumRead,NumWritten);
    if IOResult<>0 then exit;
  until (NumRead=0) or (NumWritten<>NumRead);
  getftime(fromf,x);
  setftime(tof,x);
  close(FromF);
  close(ToF);
  if Buf2<>nil then FreeMem(buf2,BufSize);
  FileCopy:=true;
end;

function  DeleteFile(s:string):boolean;
var sr:SearchRec;
    ds:dirstr;
    ns:namestr;
    es:extstr;
    f:file;
    i:integer;
begin
  FSplit(s,ds,ns,es);
  Dos.FindFirst(s,anyfile-directory,sr);
  if DosError<>0 then DeleteFile:=false else
  begin
    DeleteFile:=true;
    while doserror=0 do
    begin
      {$i-}
      assign(f,ds+sr.name);
      SetFAttr(f,0);
      erase(f);
      i:=IOResult;
      {$I+}
      dos.findnext(sr);
    end;
  end;
{$IFDEF Ver32 }
  dos.findclose(sr);
{$ENDIF }
end;

function trim(s:string):string;
var l2:byte absolute s;
begin
  while (l2>0) and (s[1]=' ') do delete(s,1,1);
  while (l2>0) and (s[l2]=' ') do dec(l2);
  trim:=s;
end;


function BigEndian(l:longint):longint;
begin
  BigEndian:=(l and $000000ff) shl 24+
             (l and $0000ff00) shl 8+
             (l and $00ff0000) shr 8+
             (l and $ff000000) shr 24;
end;

{$IFNDEF Ver32 }
procedure MkUpStr(var s:string); assembler;
asm
         xor  cx,cx
         les  di,s
         mov  cl,byte ptr es:di
         cmp  cl,0
         jz   @end
  @1:    inc  di
         mov  al,byte ptr es:[di]
  @up:   cmp  al,'a'
         jb   @loop
         cmp  al,'z'
         ja   @ae
         xor  al,20h
         jmp  @set
  @ae:   cmp  al,'Ñ'
         jne  @oe
         mov  al,'é'
         jmp  @set
  @oe:   cmp  al,'î'
         jne  @ue
         mov  al,'ô'
         jmp  @set
  @ue:   cmp  al,'Å'
         jne  @loop
         mov  al,'ö'
  @set:  mov  byte ptr es:[di],al
  @loop: loop @1
  @end:
end;
{$ENDIF }

function upstr(s:string):string;
begin
{$IFNDEF Ver32 }
  MkUpstr(s);
  upstr:=s;
{$ELSE }
  upstr:=UpperCase(s);
{$ENDIF }
end;

procedure FileAppend(s1,s2:string);
var FromF, ToF: file;
{$IFNDEF Ver32 }
    NumRead, NumWritten: Word;
{$ELSE }
    NumRead, NumWritten: longint;
{$ENDIF }
    buf: array[1..2048] of Char;
    x:longint;
begin
  assign(FromF,s1);
  reset(FromF,1);
  assign(ToF,s2);
  {$I-}
  reset(ToF,1);
  {$I+}
  if IOResult<>0 then rewrite(ToF,1);
  seek(ToF,filesize(ToF));
  repeat
    BlockRead(FromF,buf,SizeOf(buf),NumRead);
    BlockWrite(ToF,buf,NumRead,NumWritten);
  until (NumRead=0) or (NumWritten<>NumRead);
  Close(FromF);
  Close(ToF);
end;

procedure replace(var s:string; s1,s2:string);
var p:byte;
begin
  p:=pos(s1,s);
  while p>0 do
  begin
    delete(s,p,length(s1));
    insert(#1,s,p);
    p:=pos(s1,s);
  end;
  p:=pos(#1,s);
  while p>0 do
  begin
    delete(s,p,1);
    insert(s2,s,p);
    p:=pos(#1,s);
  end;
end;



function TempName:string;
var s:string;
begin
  repeat
    s:=TempDir+hexl(TempCounter)+'.UUZ';
    inc(TempCounter);
  until not exist(s);
  TempName:=s;
end;

function AddBackslash(s:string):string;
begin
  if (length(s)>3) and (s[length(s)]<>'\') then s:=s+'\';
  AddBackslash:=s;
end;

procedure ReadLine(var f:file; var s:string);
var old:longint;
    BytesRead:integer;
begin
  old:=FilePos(f);
  blockread(f,s[1],$ff,BytesRead);
  s[0]:=char(BytesRead);
  if pos(#10,s)>0 then
  begin
    s:=copy(s,1,pos(#10,s)-1);
    seek(f,old+length(s)+1);
  end;
end;

procedure BinaryNewsToUUZ(fn:string);
var FromFile,ToFile:file;
    len:longint;
    data:pointer;
    copied:longint;
{$IFNDEF Ver32 }
    BytesRead:word;
{$ELSE }
    BytesRead:longint;
{$ENDIF }
    header:string;
    count:longint;
begin
  count:=0;
  GetMem(data,4096);
  assign(FromFile,fn);
  reset(FromFile,1);
  assign(ToFile,TempName);
  rewrite(ToFile,1);
  while not eof(FromFile) do
  begin
    inc(count);
    blockread(FromFile,len,4);
    len:=BigEndian(len);
    if len>0 then
    begin
      header:='#! rnews '+str2(len)+#10;
      blockwrite(ToFile,header[1],length(header));
      copied:=0;
      while (copied<len) and (not eof(FromFile)) do
      begin
        blockread(FromFile,data^,min(len-copied,4096),BytesRead);
        blockwrite(ToFile,data^,BytesRead);
        inc(copied,BytesRead);
      end;
    end;
  end;
  close(ToFile);
  close(FromFile);
  FreeMem(data,4096);
  write(count,' Artikel.');
end;

procedure BinaryMailToUUZ(fn:string);
var FromFile,ToFile:file;
    len:longint;
    data:pointer;
    copied:longint;
{$IFNDEF Ver32 }
    BytesRead:word;
{$ELSE }
    BytesRead:longint;
{$ENDIF }
    header:string;
    count:longint;
begin
  count:=0;
  GetMem(data,4096);
  assign(FromFile,fn);
  reset(FromFile,1);
  while not eof(FromFile) do
  begin
    inc(count);
    blockread(FromFile,len,4);
    len:=BigEndian(len);
    if len>0 then
    begin
      assign(ToFile,TempName);
      rewrite(ToFile,1);
      header:='From xp2soup'#10;
      blockwrite(ToFile,header[1],length(header));
      copied:=0;
      while (copied<len) and (not eof(FromFile)) do
      begin
        blockread(FromFile,data^,min(len-copied,4096),BytesRead);
        blockwrite(ToFile,data^,BytesRead);
        inc(copied,BytesRead);
      end;
      close(ToFile);
    end;
  end;
  close(FromFile);
  FreeMem(data,4096);
  write(count,' Nachrichten.');
end;

procedure SplitPM(fn:string);
var InFile:TFile;
    OutFile:text;
    count:word;
    s:string;
begin
  count:=0;
  inFile.assign(fn);
  InFile.reset;
  while not InFile.eof do
  begin
    inFile.readString(s);
    if copy(s,1,5)='From ' then
    begin
      if count>0 then close(OutFile);
      inc(count);
      assign(OutFile,TempName);
      rewrite(OutFile);
      writeln(OutFile,s);
    end else write(OutFile,s,#10);
  end;
  if count>0 then close(OutFile);
  inFile.close;
  write(count,' Nachrichten.');
end;

procedure income(InDir,_TempDir:string);
var AreasFile,NewAreasFile:file;
    s:string;
    i:byte;
    FileName,AreaName,PacketType:string;
    NewAreas:boolean;
begin
  TempDir:=_TempDir;
  NewAreas:=false;
  assign(AreasFile,InDir+'AREAS');
  {$i-}
  reset(AreasFile,1);
  {$i+}
  if IOResult<>0 then writeln('Kann AREAS nicht îffnen.')
  else
  begin
    writeln('Bearbeite ',InDir,'AREAS ...');
    while not eof(AreasFile) do
    begin
      ReadLine(AreasFile,s);
      FileName:=copy(s,1,pos(#9,s)-1);
      s:=copy(s,pos(#9,s)+1,$ff);
      AreaName:=copy(s,1,pos(#9,s)-1);
      s:=copy(s,pos(#9,s)+1,$ff);
      if pos(#9,s)>0 then
        PacketType:=copy(s,1,pos(#9,s)-1)
      else
        PacketType:=s;
      write(InDir+FileName+'.MSG: ');
      if not exist(InDir+FileName+'.MSG') then
        write('Datei nicht vorhanden.')
      else
        for i:=1 to length(PacketType) do
          case PacketType[i] of
            'u': begin
                   write('Typ u, ');
                   FileCopy(InDir+FileName+'.MSG',TempName);
                   DeleteFile(InDir+FileName+'.MSG');
                   write('?? Artikel.');
                   break;
                 end;
            'm': begin
                   write('Typ m, ');
                   SplitPM(InDir+FileName+'.MSG');
                   DeleteFile(InDir+FileName+'.MSG');
                   break;
                 end;
            'b': begin
                   write('Typ b, ');
                   BinaryMailToUUZ(InDir+FileName+'.MSG');
                   DeleteFile(InDir+FileName+'.MSG');
                   break;
                 end;
            'B': begin
                   write('Typ B, ');
                   BinaryNewsToUUZ(InDir+FileName+'.MSG');
                   DeleteFile(InDir+FileName+'.MSG');
                   break;
                 end;
            else begin
                   write('Unbekanntes Format!');
                   if not NewAreas then
                   begin
                     NewAreas:=true;
                     assign(NewAreasFile,InDir+'AREAS.NEW');
                     rewrite(NewAreasFile,1);
                   end;
                   s:=s+#10;
                   blockwrite(NewAreasFile,s[1],length(s));
                   break;
                 end;
          end;
      writeln;
    end;
    close(AreasFile);
    erase(AreasFile);
    if NewAreas then
    begin
      close(NewAreasFile);
      FileCopy(InDir+'AREAS.NEW',InDir+'AREAS');
      DeleteFile(InDir+'AREAS.NEW');
    end;
  end;
end;

procedure xp2soup(sourceDir,destDir:string);
var sr:searchRec;
    NewsCount,MailCount,ArticleCount:word;
    f,RepliesFile:text;
    s:string;

function GetMessageName:string;
var l:longint;
begin
  l:=0;
  while exist(DestDir+'R'+copy(hexl(l),2,7)+'.MSG') do inc(l);
  GetMessageName:='R'+copy(hexl(l),2,7);
end;

procedure ConvertMail;
var FromF,ToF:file;
    data:^ByteArray;
    MailPos:word;
{$IFNDEF Ver32 }
    NumRead,NumWritten:word;
{$ELSE }
    NumRead, NumWritten:longint;
{$ENDIF }
    buf:pointer;
    l:longint;
    MessageName:string;
    i:integer;
begin
  MessageName:=GetMessageName;
  GetMem(buf,4096);
  GetMem(data,512);
  assign(FromF,SourceDir+sr.name);
  reset(FromF,1);
  blockread(FromF,data^,512,i);
  MailPos:=0;
  while (data^[MailPos]<>10) do inc(MailPos);
  inc(MailPos);
  seek(FromF,MailPos);
  assign(ToF,DestDir+MessageName+'.MSG');
  rewrite(ToF,1);
  l:=FileSize(FromF)-MailPos;
  l:=BigEndian(l);
  blockwrite(ToF,l,4);
  repeat
    BlockRead(FromF,buf^,4096,NumRead);
    BlockWrite(ToF,buf^,NumRead,NumWritten);
  until (NumRead=0) or (NumWritten<>NumRead);
  close(ToF);
  close(FromF);
  FreeMem(buf,4096);
  FreeMem(data,512);
  writeln(RepliesFile,MessageName,#9'mail'#9'bi');
end;

procedure ConvertNews;
var InFile:TFile;
    OutFile:text;
    f:file;
    s:string;
    count:byte;
    NewsName:string;
    ds:dirstr;
    ns:namestr;
    es:extstr;
    l:longint;
procedure CloseOutFile;
begin
  close(OutFile);
  assign(f,DestDir+NewsName+'.MSG');
  reset(f,1);
  l:=BigEndian(FileSize(f)-4);
  blockwrite(f,l,4);
  close(f);
  writeln(RepliesFile,newsName,#9'news'#9'Bi');
end;

begin
  count:=0;
  FSplit(sr.name,ds,ns,es);
  inFile.assign(SourceDir+sr.name);
  InFile.reset;
  while not InFile.eof do
  begin
    inFile.readString(s);
    if copy(s,1,8)='#! rnews' then
    begin
      if count>0 then CloseOutFile;
      inc(count);
      NewsName:=GetMessageName;
      assign(OutFile,DestDir+NewsName+'.MSG');
      rewrite(OutFile);
      write(OutFile,'tw97');
    end else write(OutFile,s,#10);
  end;
  if count>0 then CloseOutFile;
  inFile.close;
  inc(ArticleCount,count);
end;

begin
  sourceDir:=Upstr(SourceDir);
  DestDir:=UpStr(DestDir);
  NewsCount:=0;
  MailCount:=0;
  ArticleCount:=0;
  assign(RepliesFile,DestDir+'REPLIES');
  {$i-}
  append(RepliesFile);
  {$I+}
  if IOResult<>0 then rewrite(RepliesFile);
  Dos.FindFirst(SourceDir+'D-*.OUT',anyfile-directory,sr);
  while doserror=0 do
  begin
    assign(f,SourceDir+sr.name);
    reset(f);
    readln(f,s);
    close(f);
    if copy(s,1,5)='From ' then
    begin
      ConvertMail;
      inc(mailCount);
    end
    else
    if copy(s,1,8)='#! rnews' then
    begin
      ConvertNews;
      inc(newsCount);
    end;
    Dos.FindNext(sr);
  end;
  writeln('mail packets: ',mailCount);
  writeln('news packets: ',newsCount);
  writeln('news articles: ',articleCount);
{$IFDEF Ver32 }
  dos.findclose(sr);
{$ENDIF }
  close(RepliesFile);
end;

procedure GenerateBuffer(TempFile,OutFileName:string);
var puf:text;
    f:file;
    dt:DateTime;
{$IFDEF Ver32 }
    x:longint;
{$ELSE }
    x:word;
{$ENDIF }

begin
  assign(puf,OutFileName);
  {$i-}
  append(puf);
  {$i+}
  if IOResult<>0 then rewrite(puf);
  writeln(puf,'EMP: ',FromName);
  writeln(puf,'ABS: xp2soup@',copy(FromName,pos('@',FromName)+1,$ff));
  writeln(puf,'BET: xp2soup robot results');
  writeln(puf,'ROT: ');
  writeln(puf,'MID: ');
  GetDate(dt.year,dt.month,dt.day,x);
  GetTime(dt.hour,dt.min,dt.sec,x);
{
  with dt do
    writeln(puf,'EDA: ',year,month,day,hour,min,sec,'W+00');
}

{ bugfix by Robert Boeck }

with dt do
    writeln(puf,'EDA: ',num2str(year,10,4),
                        num2str(month,10,2),
                        num2str(day,10,2),
                        num2str(hour,10,2),
                        num2str(min,10,2),
                        num2str(sec,10,2),
                        'W+00');
  assign(f,TempFile);
  reset(f,1);
  writeln(puf,'LEN: ',FileSize(f));
  writeln(puf,'X-XP-NTP: 40');
  writeln(puf);
  close(f);
  close(puf);
  FileAppend(TempFile,OutFileName);
end;

procedure SendList(NewsRCFile,OutFileName:string);
var nrc:TFile;
    TempOutFile:text;
    s:string;
begin
  write('  generiere Newsgroup-Liste ...');
  nrc.assign(NewsRCFile);
  {$i-}
  nrc.reset;
  {$i+}
  if IOResult<>0 then writeln(' FEHLER! newsrc nicht gefunden!')
  else begin
    assign(TempOutFile,'TEMP.$$$');
    rewrite(TempOutFile);
    while not nrc.eof do begin
      nrc.ReadString(s);
      replace(s,'.','/');
      s:='/'+s;
      if pos('!',s)>0 then s:='N '+copy(s,1,pos('!',s)-1)
      else
      if pos(':',s)>0 then s:='J '+copy(s,1,pos(':',s)-1)
      else
      s:='? '+s;
      writeln(TempOutFile,s);
    end;
    close(TempOutFile);
    GenerateBuffer('TEMP.$$$',OutFileName);
    nrc.close;
    writeln(' ok.');
  end;
end;

procedure robot(ScanDir,NewsRCFile,OutFileName:string);
var ds:dirstr;
    ns:namestr;
    es:extstr;
    sr:SearchRec;
    MessageFileName:string;
    s:string;
    f:TFile;
    ForUs:boolean;
    subject:string[30];
begin
  writeln('Starte Newsgroup-Robot ...');
  dos.findFirst(ScanDir+'X-*.OUT',anyfile-directory,sr);
  while doserror=0 do begin
    f.assign(ScanDir+sr.name);
    f.reset;
    ForUs:=false;
    while not f.eof do begin
      f.readString(s);
      if copy(s,1,2)='F ' then MessageFileName:=copy(s,length(s)-3,4)
      else
      if upstr(copy(s,1,16))='C RMAIL XP2SOUP@' then ForUs:=true;
    end;
    f.close;
    if ForUs then begin
      f.assign(ScanDir+'D-'+MessageFileName+'.OUT');
      {$i-}
      f.reset;
      {$i+}
      s:='xxx';
      if IOResult=0 then begin
        subject:='';
        while not (f.eof or (s='')) do begin
          f.ReadString(s);
          if copy(s,1,9)='Subject: ' then subject:=copy(s,10,$ff)
          else
          if copy(s,1,6)='From: ' then begin
            FromName:=copy(s,7,$ff);
            if pos('(',FromName)>0 then FromName:=copy(FromName,1,pos('(',FromName)-1);
            FromName:=trim(FromName);
            writeln(FromName);
          end;
        end;
        if pos('LIST',subject)>0 then SendList(NewsRCFile,OutFileName);
        f.close;
        DeleteFile(ScanDir+'D-'+MessageFileName+'.OUT');
      end;
    end;
    dos.FindNext(sr);
  end;
{$IFDEF Ver32 }
  dos.findclose(sr);
{$ENDIF }
end;

var ds:DirStr;
    ns:namestr;
    es:extstr;

begin
  writeln('xp2soup v',version,' ',twj_plattform,' - CrossPoint to SOUP conversion utility');
  writeln('  written by Torben Weibert <torben@weibert.com>  Copyright 1997,98');
  writeln('  see http://www.weibert.com/software/xp2soup for further information');
  writeln('  ---');
  writeln('  32Bit Port: XP2 Team, see http://www.xp2.de');
  writeln;
  if (upstr(paramstr(1))='PREPARE') and (paramcount=3) then
    xp2soup(AddBackslash(FExpand(paramstr(2))),AddBackslash(FExpand(paramstr(3))))
  else
  if (upstr(paramstr(1))='INCOME') and (paramcount=3) then
    income(AddBackslash(FExpand(paramstr(2))),AddBackslash(FExpand(paramstr(3))))
  else
  if (upstr(paramstr(1))='ROBOT') and (paramcount=4) then
    robot(AddBackslash(FExpand(paramstr(2))),FExpand(paramstr(3)),FExpand(paramstr(4)))
  else
  begin
    writeln('usage: xp2soup.exe robot <input directory> <newsrc file> <output file>');
    writeln('       xp2soup.exe prepare <input directory> <output directory>');
    writeln('       xp2soup.exe income <input directory> <output directory>');
    writeln;
    writeln('see documentation for details.');
  end;
end.

{
$Log: xp2soup.pas,v $
Revision 1.2  2000/06/01 21:01:55  tj
kann nun compiliert werden :-)

Revision 1.1  2000/05/31 21:09:04  tj
auf dem CVS aufgespielt

}
