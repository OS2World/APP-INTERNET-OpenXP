{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams.  }
{ Aenderungen des Sources, die vom OpenXP Team getaetigt wurden,  }
{ unterliegen den Rechten, die bis zum 09.04.2000 fuer das OpenXP }
{ Team gueltig waren.                                             }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: fileio.pas,v 1.20 2001/12/30 11:50:56 mm Exp $ }


{ File-I/O, Locking und Dateinamenbearbeitung }

{$I XPDEFINE.INC }

unit fileio;

interface

uses
  xpglobal,
{$IFDEF Ver32 }
  sysutils,
{$ENDIF }
{$ifdef vp }
  vpusrlow,
{$endif}
 {$IFDEF Win32 }
  windows,
 {$ENDIF }
{$IFDEF OS2}
  os2base,os2def,
{$ENDIF}
  dos, typeform;

{$ifdef vp }
const FMRead       = fmOpenRead;     { Konstanten fÅr Filemode }
      FMWrite      = fmOpenWrite;
      FMRW         = fmOpenReadWrite;
      FMDenyNone   = fmShareDenyNone;
      FMDenyRead   = fmShareDenyRead;
      FMDenyWrite  = fmShareDenyWrite;
      FMDenyBoth   = fmShareExclusive;
      FMCompatible = fmShareCompat;
{$else}
const FMRead       = $00;     { Konstanten fÅr Filemode }
      FMWrite      = $01;
      FMRW         = $02;
      FMDenyNone   = $40;
      FMDenyRead   = $30;
      FMDenyWrite  = $20;
      FMDenyBoth   = $10;
      FMCompatible = $00;
{$endif}

type  TExeType = (ET_Unknown, ET_DOS, ET_Win16, ET_Win32,
                  ET_OS2_16, ET_OS2_32);


Function  exist(n:string):boolean;              { Datei vorhanden ?       }
Function  existf(var f):boolean;                { Datei vorhanden ?       }
Function  existrf(var f):boolean;               { D.v. (auch hidden etc.) }
Function  ValidFileName(name:PathStr):boolean;  { gÅltiger Dateiname ?    }
Function  IsPath(name:PathStr):boolean;         { Pfad vorhanden ?        }
function  TempFile(path:pathstr):pathstr;       { TMP-Namen erzeugen      }
function  TempExtFile(path,ld,ext:pathstr):pathstr; { Ext-Namen erzeugen }
function  _filesize(fn:pathstr):longint;        { Dateigrî·e in Bytes     }
function  filetime(fn:pathstr):longint;         { Datei-Timestamp         }
procedure setfiletime(fn:pathstr; newtime:longint);  { Dateidatum setzen  }
procedure setfileattr(fn:pathstr; attr:word);   { Dateiattribute setzen   }
function  copyfile(srcfn, destfn:pathstr):boolean; { Datei kopieren }
Procedure era(s:string);                        { Datei lîschen           }
procedure erase_mask(s:string);                 { Datei(en) lîschen       }
Procedure erase_all(path:pathstr);              { Lîschen mit Subdirs     }
function  _rename(n1,n2:pathstr):boolean;       { Lîschen mit $I-         }
procedure move_mask(source,dest:pathstr; var res:integer);
Function  ReadOnlyHidden(name:PathStr):boolean; { Datei Read Only ?       }
Procedure MakeBak(n,newext:string);             { sik anlegen             }
procedure MakeFile(fn:pathstr);                 { Leerdatei erzeugen      }
procedure mklongdir(path:pathstr; var res:integer);  { mehrere Verz. anl. }
(*
function  textfilesize(var t:text):longint;     { Grî·e v. offener Textdatei }
*)
{$IFDEF BP }
function  diskfree(drive:byte):longint;         { 2-GB-Problem umgehen    }
{$ENDIF }
function  exetype(fn:pathstr):TExeType;

procedure fm_ro;                                { Filemode ReadOnly       }
procedure fm_rw;                                { Filemode Read/Write     }
procedure fm_all;                               { Deny none               }
procedure resetfm(var f:file; fm:byte);         { mit spez. Filemode îffn.}
function  ShareLoaded:boolean;                  { Locking verfÅgbar       }
function  lock(var datei:file; from,size:longint):boolean;
procedure unlock(var datei:file; from,size:longint);
function  lockfile(var datei:file):boolean;
procedure unlockfile(var datei:file);

procedure addext(var fn:pathstr; ext:extstr);
procedure adddir(var fn:pathstr; dir:dirstr);
function  GetFileDir(p:pathstr):dirstr;
function  GetFileName(p:pathstr):string;
function  GetBareFileName(p:pathstr):string;    { Filename ohne .ext }
function  GetFileExt(p:pathstr):string;         { Extension *ohne* "." }
procedure WildForm(var s: pathstr);              { * zu ??? erweitern }

function  ioerror(i:integer; otxt:atext):atext; { Fehler-Texte            }


implementation  { ------------------------------------------------------- }

{$ifdef linux}
uses
  linux;
{$endif}

var ShareDa : boolean;


Function exist(n:string):boolean;
{$IFDEF OS2-IS.NIT  }
begin
  Exist := FileExists(n); { funktioniert nicht mit Wildcards: Auch nicht unter OS/2 }
end;
{$ELSE }
var sr : searchrec;
    ex : boolean;
begin
  findfirst(n,anyfile-volumeid-directory,sr);
  ex:=(doserror=0);
  while not ex and (doserror=0) do begin
    findnext(sr);
    ex:=(doserror=0);
  end;
  {$IFDEF VP}
  FindClose(sr);
  {$ENDIF}
  exist:=ex;
end;
{$ENDIF }

Function existf(var f):Boolean;
var
  fm : byte;
begin
  fm:=filemode;
  filemode:=FMDenyNone;
  reset(file(f));
  existf:=(ioresult=0);
  close(file(f));
  filemode:=fm;
  if ioresult = 0 then ;
end;


Function existrf(var f):Boolean;
var a : rtlword;
    e : boolean;
begin
  getfattr(f,a);
  setfattr(f,archive);
  e:=existf(f);
  setfattr(f,a);
  a:=ioresult;
  existrf:=e;
end;

Function ValidFileName(name:PathStr):boolean;
var f : file;
begin
  if (name='') or multipos('*?/',name) then  { Fehler in DR-DOS 5.0 umgehen }
    ValidFileName:=false
  else begin
    assign(f,name);
    if existf(f) then ValidFileName:=true
    else begin
      rewrite(f);
      close(f);
      erase(f);
      ValidFileName:=(ioresult=0);
    end;
  end;
end;


Function IsPath(name:PathStr):boolean;         { Pfad vorhanden ? }
var sr : searchrec;
begin
  name:=trim(name);
  if multipos('?*',name) or (trim(name)='') then
    IsPath:=false
  else begin
    if (name='\') or (name[length(name)]=':') or (right(name,2)=':\')
    then begin
      findfirst(name+'*.*',AnyFile,sr);
      if doserror=0 then
        IsPath:=true
      else
        IsPath:=validfilename(name+'1$2$3.xx');
    end
    else begin
      if name[length(name)]='\' then
        dellast(name);
      findfirst(name,Directory,sr);
      IsPath:=(doserror=0) and (sr.attr and directory<>0);
    end;
    {$ifdef ver32 }
    findclose(sr);
    {$endif}
  end;
end;

function copyfile(srcfn, destfn:pathstr):boolean;  { Datei kopieren }
{ keine öberprÅfung, ob srcfn existiert oder destfn bereits existiert }
var bufs,rr:word;
    buf:pointer;
    f1,f2:file;
begin
  bufs:=min(maxavail,65520);
  getmem(buf,bufs);
  assign(f1,srcfn);
  assign(f2,destfn);
  reset(f1,1);
  rewrite(f2,1);
  while not eof(f1) and (inoutres=0) do begin
    blockread(f1,buf^,bufs,rr);
    blockwrite(f2,buf^,rr);
  end;
  close(f2);
  close(f1);
  copyfile:=(inoutres=0);
  if ioresult<>0 then ;
  freemem(buf,bufs);
end;

Procedure era(s:string);
var f : file;
begin
  assign(f,s);
  erase(f);
end;


procedure erase_mask(s:string);                 { Datei(en) lîschen }
var sr : searchrec;
begin
  findfirst(s,archive,sr);
  while doserror=0 do begin
    era(getfiledir(s)+sr.name);
    findnext(sr);
  end;
  {$IFDEF Ver32 }
  FindClose(sr);
  {$ENDIF}
end;

{ path: Pfad mit '\' am Ende! }

procedure erase_all(path:pathstr);
var sr : searchrec;
    f  : file;
begin
  findfirst(path+'*.*',anyfile {$ifndef os2} -VolumeID {$endif} ,sr);
  while doserror=0 do begin
    with sr do
      if (name[1]<>'.') then
        if attr and Directory<>0 then
          erase_all(path+name+'\')
        else begin
          assign(f,path+name);
          if attr and (ReadOnly+Hidden+Sysfile)<>0 then setfattr(f,0);
          erase(f);
        end;
    findnext(sr);
  end;
  {$IFDEF Ver32}
  FindClose(sr);
  {$ENDIF}
  if pos('\',path)<length(path) then begin
    dellast(path);
    rmdir(path);
  end;
end;

Function ReadOnlyHidden(name:PathStr):boolean;
var f    : file;
    attr : rtlword;
begin
  assign(f,name);
  if not existf(f) then ReadOnlyHidden:=false
  else begin
    getfattr(f,attr);
    ReadOnlyHidden:=(attr and (ReadOnly or Hidden))<>0;
  end;
end;

Procedure MakeBak(n,newext:string);
var bakname : string;
    f       : file;
    dir     : dirstr;
    name    : namestr;
    ext     : extstr;
begin
  assign(f,n);
  if not existrf(f) then exit;
  fsplit(n,dir,name,ext);
  bakname:=dir+name+'.'+newext;
  assign(f,bakname);
  if existrf(f) then begin
    setfattr(f,archive);
    erase(f);
  end;
  assign(f,n);
  setfattr(f,archive);
  rename(f,bakname);
  if ioresult<>0 then;
end;

function ioerror(i:integer; otxt:atext):atext;
begin
  case i of
      2 : ioerror:='Datei nicht gefunden';
      3 : ioerror:='ungÅltiges Verzeichnis';
      4 : ioerror:='zu viele Dateien geîffnet (bitte FILES erhîhen!)';
      5 : ioerror:='Zugriff verweigert';
      7 : ioerror:='Speicherverwaltung zerstîrt';
      8 : ioerror:='ungenÅgend Speicher';
     10 : ioerror:='ungÅltiges Environment';
     11 : ioerror:='ungÅltiges Aufruf-Format';
     15 : ioerror:='ungÅltige Laufwerksbezeichnung';
     16 : ioerror:='Verzeichnis kann nicht gelîscht werden';
     18 : ioerror:='Fehler bei Dateisuche';
    101 : ioerror:='Diskette/Platte voll';
    150 : ioerror:='Diskette ist schreibgeschÅtzt';
    152 : ioerror:='keine Diskette eingelegt';
154,156 : ioerror:='Lesefehler (Diskette/Platte defekt)';
157,158 : ioerror:='Diskette ist nicht korrekt formatiert';
    159 : ioerror:='Drucker ist nicht betriebsbereit';
    162 : ioerror:='Hardware-Fehler';
    209 : ioerror:='Fehler in .OVR-Datei';
  else
    ioerror:=otxt;
  end;
end;


{ res:  0 = Pfad bereits vorhanden }
{       1 = Pfad angelegt          }
{     < 0 = IO-Fehler              }

procedure mklongdir(path:pathstr; var res:integer);
const testfile = 'test0000.$$$';
var p : byte;
begin
  path:=trim(path);
  if path='' then begin
    res:=0;
    exit;
  end;
  if right(path,1)<>'\' then path:=path+'\';
  if validfilename(path+testfile) then
    res:=0
  else
    if pos('\',path)<=1 then begin
      mkdir(path);
      res:=-ioresult;
    end
    else begin
      p:=iif(path[1]='\',2,1);
      res:=0;
      while (p<=length(path)) do begin
        while (p<=length(path)) and (path[p]<>'\') do inc(p);
        if not IsPath(left(path,p)) then begin
          mkdir(left(path,p-1));
          if inoutres<>0 then begin
            res:=-ioresult;
            exit;
          end;
        end
        else
          res:=1;
        inc(p);
      end;
    end;
end;

function TempFile(path:pathstr):pathstr;       { TMP-Namen erzeugen }
var n : string[12];
begin
  repeat
    n:=formi(random(10000),4)+'.tmp'
  until not exist(path+n);
  TempFile:=path+n;
end;

function TempExtFile(path,ld,ext:pathstr):pathstr;  { Ext-Namen erzeugen }
{ ld max. 4 Zeichen, ext mit Punkt '.bat' }
var n : string[12];
begin
  repeat
    n:=ld+formi(random(10000),4)+ext
  until not exist(path+n);
  TempExtFile:=path+n;
end;


function _filesize(fn:pathstr):longint;
var sr : searchrec;
begin
  findfirst(fn,archive,sr);
  if doserror<>0 then
    _filesize:=0
  else
    _filesize:=sr.size;
  {$ifdef ver32 }
  findclose(sr);
  {$endif}
end;

procedure MakeFile(fn:pathstr);
var t : text;
begin
  assign(t,fn);
  rewrite(t);
  if ioresult=5 then
    setfattr(t,0)
  else
    close(t);
end;

function filetime(fn:pathstr):longint;
var sr : searchrec;
begin
  findfirst(fn,AnyFile,sr);
  if doserror=0 then
    filetime:=sr.time
  else
    filetime:=0;
  {$ifdef ver32 }
  findclose(sr);
  {$endif}
end;

procedure setfiletime(fn:pathstr; newtime:longint);  { Dateidatum setzen }
var f : file;
begin
  assign(f,fn);
  reset(f,1);
  setftime(f,newtime);
  close(f);
  if ioresult<>0 then;
end;

procedure setfileattr(fn:pathstr; attr:word);   { Dateiattribute setzen }
var f : file;
begin
  assign(f,fn);
  setfattr(f,attr);
  if ioresult<>0 then;
end;

function GetFileDir(p:pathstr):dirstr;
var d : dirstr;
    n : namestr;
    e : extstr;
begin
  fsplit(p,d,n,e);
  GetFileDir:=d;
end;

function GetFileName(p:pathstr):string;
var d : dirstr;
    n : namestr;
    e : extstr;
begin
  fsplit(p,d,n,e);
  GetFileName:=n+e;
end;

function GetBareFileName(p:pathstr):string;
var d : dirstr;
    n : namestr;
    e : extstr;
begin
  fsplit(p,d,n,e);
  GetBareFileName:=n;
end;

function GetFileExt(p:pathstr):string;
var d : dirstr;
    n : namestr;
    e : extstr;
begin
  fsplit(p,d,n,e);
  GetFileExt:=mid(e,2);
end;

function _rename(n1,n2:pathstr):boolean;
var f : file;
begin
  assign(f,n1);
  rename(f,n2);
  _rename:=(ioresult=0);
end;


procedure move_mask(source,dest:pathstr; var res:integer);
var sr : searchrec;
begin
  res:=0;
  if lastchar(dest)<>'\' then
    dest:=dest+'\';
  findfirst(source,archive,sr);
  while doserror=0 do begin
    if not _rename(getfiledir(source)+sr.name,dest+sr.name) then
      inc(res);
    findnext(sr);
  end;
  {$IFDEF Ver32}
  FindClose(sr);
  {$ENDIF}
end;

{ Extension anhÑngen, falls noch nicht vorhanden }

procedure addext(var fn:pathstr; ext:extstr);
var dir  : dirstr;
    name : namestr;
    _ext : extstr;
begin
  fsplit(fn,dir,name,_ext);
  if _ext='' then fn:=dir+name+'.'+ext;
end;

{ Verzeichnis einfÅgen, falls noch nicht vorhanden }

procedure adddir(var fn: pathstr; dir:dirstr);
var _dir : dirstr;
    name : namestr;
    ext  : extstr;
begin
  fsplit(fn,_dir,name,ext);
  if _dir='' then begin
    if dir[length(dir)]<>'\' then dir:=dir+'\';
    insert(dir,fn,1);
  end;
end;

procedure fm_ro;      { Filemode ReadOnly }
begin
  filemode:=fmRead;
end;

procedure fm_rw;      { Filemode Read/Write }
begin
  filemode:=fmRW;
end;

procedure fm_all;     { Filemode Read/Write }
begin
  filemode:=fmDenyNone+fmRW;
end;


function ShareLoaded:boolean;
begin
  ShareLoaded:=shareda;
end;

{$IFDEF FPC }
  { Wir wissen, was Hi/Lo bei Longint zurÅckliefert }
  {$WARNINGS OFF }
{$ENDIF }

function lock(var datei:file; from,size:longint):boolean;
{$IFDEF ver32 }
begin
  {$IFDEF VirtualPascal }
    {TJ 120400 - ich vertraue mal VP in dieser Sache... siehe unten MK Kommentar}
      lock:=SysLockFile(FileRec(datei).Handle,from,size)=0;   
  {$ELSE }
    {$IFDEF Win32 }
      lock:=Windows.LockFile(FileRec(Datei).Handle, Lo(From), 0, Lo(Size), 0);
    {$ENDIF }
    {$IFDEF LINUX }                           {ML 25.03.2000    Filelocking f¸r Linux }
      lock:=flock (datei, LOCK_SH);
    {$ENDIF }
  {$ENDIF}
{$ELSE }
var regs : registers;
begin
  if Shareda then with regs do begin
    ax:=$5c00;
    bx:=filerec(datei).handle;
    cx:=from shr 16; dx:=from and $ffff;
    si:=size shr 16; di:=size and $ffff;
    msdos(regs);
    lock:=flags and fcarry = 0;
  end
  else
    lock:=true;
{$ENDIF }
end;

procedure unlock(var datei:file; from,size:longint);
{$IFDEF Ver32 }
begin
  {$IFDEF VirtualPascal }
    if SysUnLockFile(FileRec(datei).Handle,from,size)=0 then ;
  {$ELSE }
    {$IFDEF Win32 }
      Windows.UnLockFile(FileRec(Datei).Handle, Lo(From), 0, Lo(Size), 0);
    {$ENDIF }
    {$IFDEF LINUX }                 { ML 25.03.2000    Filelocking f¸r Linux }
      flock(Datei, LOCK_UN);
    {$ENDIF }
  {$ENDIF }
{$ELSE }
var regs : registers;
begin
  if shareda then with regs do begin
    ax:=$5c01;
    bx:=filerec(datei).handle;
    cx:=from shr 16; dx:=from and $ffff;
    si:=size shr 16; di:=size and $ffff;
    msdos(regs);
  end;
{$ENDIF }
end;

{$IFDEF FPC }
  { Wir wissen, was Hi/Lo bei Longint zurÅckliefert }
  {$WARNINGS ON }
{$ENDIF }

function lockfile(var datei:file):boolean;
begin
  lockfile:=lock(datei,0,maxlongint);
end;

procedure unlockfile(var datei:file);
begin
  unlock(datei,0,maxlongint);
end;


procedure TestShare;
{$IFDEF Ver32 }
begin
 ShareDa:=true;                           {TJ 120400 - diese Funktion sollte unter 32Bit Systemen wohl Standard sein}
end;
{$ELSE}
var regs : registers;
begin
  fillchar(regs,sizeof(regs),0);
  { Multiplexer SHARE-Test: funktioniert eigentlich immer }
  with regs do begin
    ax:=$1000;
    intr($2f, regs);
    if al=$ff then ShareDa := true else
  { ansonsten nochmal hiermit, um auch die Exoten zu erwischen }
      with regs do begin
        ax:=$5c00;
        di:=1;
        msdos(regs);
        if flags and fcarry=0 then begin
          ax:=$5c01;
          msdos(regs);
        end;
        ShareDa:=(ax<>1);
      end;
  end;
end;
{$ENDIF}

procedure resetfm(var f:file; fm:byte);
var fm0 : byte;
begin
  fm0:=filemode;
  filemode:=fm;
  reset(f,1);
  filemode:=fm0;
end;


{ t mu· eine geîffnete Textdatei sein }
{$IFDEF BP}
function textfilesize(var t:text):longint;
var regs  : registers;
    fplow : word;           { alter Filepointer }
    fphigh: word;
begin
  with regs do begin
    ax:=$4201;              { File Pointer ermitteln }
    bx:=textrec(t).handle;
    cx:=0; dx:=0;
    msdos(regs);
    fphigh:=dx; fplow:=ax;
    ax:=$4202;              { Dateigrî·e ermitteln }
    cx:=0; dx:=0;
    msdos(regs);
    textfilesize:=$10000*dx+ax;
    ax:=$4200;              { alte Position wiederherstellen }
    cx:=fphigh; dx:=fplow;
    msdos(regs);
  end;
end;
{$ENDIF}

{$IFDEF OS2}
function textfilesize(var t:text):longint;
var
        thandle  : hfile;
        rc       : ApiRet;
        ulLocal  : ULong;
begin
 textfilesize:=0;                 {TJ080200 -  organisiert mir den benoetigten Textfilehandle}
 thandle:=textrec(t).handle;
 rc:=DosSetFilePtr(thandle,
                   0,             {Offset}
                   file_End,      {Move to EOF :))) somit haben wir ihn}
                   ulLocal);      {New location adress}
 if rc <> No_Error then
  begin
   writeln('DosSetFilePtr Fehler: ', rc);
   halt(99);
  end; {if}
 textfilesize:=ulLocal;           {in der Hoffnung, das dies die Position wiedergibt}
end; {textfilesize}
{$ENDIF}

procedure WildForm(var s: pathstr);
var dir : dirstr;
    name: namestr;
    ext : extstr;
    p   : byte;
begin
  fsplit(s,dir,name,ext);
  p:=cpos('*',name);
   if p>0 then name:=left(name,p-1)+typeform.dup(9-p,'?');
  p:=cpos('*',ext);
   if p>0 then ext:=left(ext,p-1)+typeform.dup(5-p,'?');
  s:=dir+name+ext;
end;

{ Zwei diskfree/disksize-Probleme umgehen:                   }
{                                                            }
{ - bei 2..4 GB liefern diskfree und disksize negative Werte }
{ - bei bestimmten Cluster/Sektorgrî·en-Kombinationen        }
{   liefern diskfree und disksize falsche Werte              }
{ Unter FPC gibt es eine gleichlautende Procedure in der Unit DOS }
{$IFDEF BP }
function diskfree(drive:byte):longint;
var l,ll : longint;
    regs : registers;
begin
  regs.ah := $36;
  regs.dl := drive;
  msdos(regs);
  if regs.ax=$ffff then
    l:=0
  else begin
    l:=longint(regs.ax)*regs.bx;   { Secs/Cluster * Free Clusters }
    if regs.cx>=512 then
      ll:=(l div 2)*(regs.cx div 512)
    else
      ll:=(l div 1024)*regs.cx;
    if ll>=2097152 then l:=maxlongint
    else l:=l*regs.cx;
  end;
  diskfree:=l;
end;
{$ENDIF}

function exetype(fn:pathstr):TExeType;
var f       : file;
    magic   : array[0..1] of char;
    hdadr   : longint;
    version : byte;
begin
  assign(f,fn);
  resetfm(f,FMDenyWrite);
  blockread(f,magic,2);
  seek(f,60);
  blockread(f,hdadr,4);
  if (ioresult<>0) or (magic<>'MZ') then
    exetype:=ET_Unknown
  else if odd(hdadr) then
    exetype:=ET_DOS
  else
  begin { MK 01/00 Fix fÅr LZEXE gepackte Dateien }
    if (hdadr > 0) and (hdadr < FileSize(f)-54) then
    begin
      seek(f,hdadr);
      blockread(f,magic,2);
      if ioresult<>0 then
        exetype:=ET_DOS
      else if magic='PE' then
        exetype:=ET_Win32
      else if magic='LX' then
        exetype:=ET_OS2_32
      else if magic<>'NE' then
        exetype:=ET_DOS
      else begin
        seek(f,hdadr+54);
        blockread(f,version,1);
        if version=2 then exetype:=ET_Win16
        else exetype:=ET_OS2_16;
      end;
    end else
      exetype := ET_DOS;
  end;
  close(f);
  if ioresult<>0 then;
end;

begin
  TestShare;
end.
{
  $Log: fileio.pas,v $
  Revision 1.20  2001/12/30 11:50:56  mm
  - Sourceheader

  Revision 1.19  2001/08/09 17:11:29  MH
  - Fileexist funktioniert nicht mit Wildcards

  Revision 1.18  2001/08/06 19:06:50  mm
  - lock/unlock: W32-API fuer andere Compiler nutzen

  Revision 1.17  2001/08/06 18:38:39  MH
  - Fix bei Sys-Un-LockFile: Es wird ein Handle erwartet
    (man sollte sich auch mal die RTL ansehen)

  Revision 1.16  2001/08/06 18:23:56  MH
  - Fix bei Sys-Un-LockFile: Es wird ein Handle erwartet
    (man sollte sich auch mal die RTL ansehen)

  Revision 1.15  2001/07/24 13:52:23  mm
  - Fix in lockfile und unlockfile fuer W9x/ME

  Revision 1.14  2001/07/22 17:36:42  MH
  - FileExist funzt nicht mit *.* unter W32

  Revision 1.13  2001/07/19 08:37:49  MH
  - oops...sorry: letzten co korrigiert

  Revision 1.12  2001/07/18 19:00:51  MH
  - Fixes: Compilation mit VP unter W32 wieder ermoeglicht

  Revision 1.11  2001/06/18 06:11:16  MH
  - SHARE-Test angepasst

  Revision 1.10  2000/08/24 21:45:39  rb
  FindFirst/FindClose-Fixes

  Revision 1.9  2000/06/08 20:04:24  MH
  Teamname geandert

  Revision 1.8  2000/05/25 23:03:02  rb
  Loginfos hinzugefÅgt

  Revision 1.7  2000/05/12 19:40:06  oh
  -PGP und Feldtausch komplett

  Revision 1.6  2000/04/13 12:33:47  tj
  kleine Schoenheitskorrektur

  Revision 1.5  2000/04/12 21:32:20  tj
  einige Funktionen auf OS/2 portiert

  Revision 1.4  2000/04/09 18:07:48  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.19  2000/03/28 08:38:28  mk
  - Debugcode in Testshare entfernt

  Revision 1.18  2000/03/26 09:41:12  mk
  - erweiterte Share-Erkennung

  Revision 1.17  2000/03/25 23:20:30  mk
  - LockFile geht unter Win9x nicht, wohl aber unter NT. Ausgeklammert

  Revision 1.16  2000/03/25 18:46:59  ml
  uuz lauff‰hig unter linux

  Revision 1.15  2000/03/24 23:11:17  rb
  VP Portierung

  Revision 1.14  2000/03/24 20:25:50  rb
  ASM-Routinen gesÑubert, Register fÅr VP + FPC angegeben, Portierung FPC <-> VP

  Revision 1.13  2000/03/24 04:16:21  oh
  - Function GetBareFileName() (Dateiname ohne EXT) fuer PGP 6.5.x

  Revision 1.12  2000/03/24 00:03:39  rb
  erste Anpassungen fÅr die portierung mit VP

  Revision 1.11  2000/03/16 19:25:10  mk
  - fileio.lock/unlock nach Win32 portiert
  - Bug in unlockfile behoben

  Revision 1.10  2000/03/09 23:39:32  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.9  2000/03/07 23:41:07  mk
  Komplett neue 32 Bit Windows Screenroutinen und Bugfixes

  Revision 1.8  2000/03/04 14:53:49  mk
  Zeichenausgabe geaendert und Winxp portiert

  Revision 1.7  2000/03/03 20:26:40  rb
  Aufruf externer MIME-Viewer (Win, OS/2) wieder geÑndert

  Revision 1.6  2000/02/23 23:49:47  rb
  'Dummy' kommentiert, Bugfix beim Aufruf von ext. Win+OS/2 Viewern

  Revision 1.5  2000/02/19 11:40:07  mk
  Code aufgeraeumt und z.T. portiert

}
