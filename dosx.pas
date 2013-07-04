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
{ $Id: dosx.pas,v 1.13 2001/12/30 11:50:56 mm Exp $ }

(***********************************************************)
(*                                                         *)
(*                       UNIT dosx                         *)
(*                                                         *)
(*        Erweiterungen von DOS; BIOS-Schnittstelle        *)
(*                                                         *)
(***********************************************************)

UNIT dosx;

{$I XPDEFINE.INC}


{  ==================  Interface-Teil  ===================  }

INTERFACE

uses xpglobal
{$IFDEF OS2}
     ,os2def, os2base
{$ENDIF}
     ,crt, dos, typeform
{$ifdef vp}
     ,vputils
{$endif}
     ;

function  GetDrive:char;
function  dospath(d:byte):pathstr;
procedure GoDir(path:pathstr);
function  DriveType(drive:char):byte;       { 0=nix, 1=Disk, 2=RAM, 3=Subst }
                                            { 4=Device, 5=Netz              }
function  alldrives:string;

function  OutputRedirected:boolean;
{$IFDEF BP }
function  ConfigFILES:byte;                  { FILES= .. }
function  FreeFILES(maxfiles:byte):word;     { freie Files; max. 255 }
{$ENDIF }
{$IFDEF OS2}
function  ConfigFILES:byte;                  { FILES= .. }
function  FreeFILES(maxfiles:byte):word;     { freie Files; max. 255 }
{$ENDIF}
function  IsDevice(fn:pathstr):boolean;

{$IFDEF BP }
procedure XIntr(intno:byte; var regs:registers);   { DPMI-kompatibler Intr }
function  DPMIallocDOSmem(paras:word; var segment:word):word;
procedure DPMIfreeDOSmem(selector:word);
{$ENDIF }


{ ================= Implementation-Teil ==================  }

implementation

{$IFDEF Ver32 }
uses
  {$ifdef vp }
  vpsyslow,
  {$endif}
  {$IFDEF Win32 }
  windows,
  {$ENDIF }
  sysutils;
{$ENDIF }


{$IFDEF BP }
const DPMI   = $31;
{$ENDIF }

function GetDrive:char;
{$IFDEF BP }
var regs : registers;
begin
  with regs do begin
    ax:=$1900;
    msdos(regs);
    getdrive:=chr(al+65);
  end;
{$ELSE  }                    {TJ 110400 - sollte es Probleme unter OS/2 geben, DosQueryCurrentDisk verwenden}
var
  s: String;
begin
  s := GetCurrentDir;
  GetDrive := s[1];
{$ENDIF }
end; {GetDrive}

{ 0=aktuell, 1=A, .. }

function dospath(d:byte):pathstr;
var s : string;
begin
  getdir(d,s);
  dospath:=s;
end;

procedure SetDrive(drive:char);
{$IFDEF BP }
var regs : registers;
begin
  with regs do begin
    ah:=$e;
    dl:=ord(UpCase(drive))-65;
    msdos(regs);
    end;
{$ELSE }                          {TJ 110400 - sollte es unter OS/2 Probleme geben, DosSetDefaultDisk verwenden}
begin
  SetCurrentDir(Drive + ':');
{$ENDIF }
end; {SetDrive}

procedure GoDir(path:pathstr);
begin
  if path='' then exit;
  SetDrive(path[1]);
  if (length(path)>3) and (path[length(path)]='\') then
    dec(byte(path[0]));
  chdir(path);
end;


function OutputRedirected:boolean;
{$IFDEF ver32}
begin
  OutputRedirected := false;
  {$IFDEF VP}
  OutPutRedirected:=VPUtils.IsFileHandleConsole( SysFileStdOut );   {TJ 110400 - wenn doch da is}
  {$ENDIF}
end;
{$ELSE}
var regs : registers;
begin
  with regs do begin
    ax:=$4400;
    bx:=textrec(output).handle;
    intr($21,regs);
    OutputRedirected:=(flags and fcarry=0) and (dx and 128=0);
  end;
end;
{$ENDIF}

{ Buf sollte im Datensegment liegen }
{ benîtigt DOS ab Version 3.0       }
{ pro Handle wird 1 Byte benîtigt   }

{ 0=nix, 1=Disk, 2=RAM, 3=Subst, 4=Device, 5=Netz, 6=CD-ROM }

function DriveType(drive:char):byte;
{$IFDEF Ver32  }
const
  DriveStr: String = '?:\'+#0;
{$ifdef vp }
  var
    dt : TDriveType;
{$endif }
{$IFDEF OS2 }
    rc : ApiRet;
{$ENDIF }
begin
  {$IFDEF OS2 }
    { tj 011000 - hier schalte ich die Errormeldung aus... }
    rc := OS2Base.DosError(ferr_DisableHardErr);
    if rc <> No_Error then
    begin
      Writeln('DosError error: return code = ', rc);
      Halt(1);
    end;

    dt:=SysGetDriveType(drive);


    {tj 011000 - und hier wird die Meldung wieder eingeschaltet }

    rc := OS2Base.DosError(ferr_EnableHardErr);        // Re-enable error window
    if rc <> No_Error then
    begin
      Writeln('DosError error: return code = ', rc);
      Halt(1);
    end;

  {$ENDIF }
  {$ifdef vp }
  {$IFNDEF OS2 }
  dt:=SysGetDriveType(drive);
  {$ENDIF }

  case dt of
    dtFloppy,
    dtHDFAT,
    dtHDHPFS,
    dtHDNTFS,
    dtHDExt2     : DriveType:=1;
    dtTVFS       : DriveType:=3;
    dtNovellNet,
    dtLAN        : DriveType:=5;
    dtCDRom      : DriveType:=6;
    else           DriveType:=0;
  end;
  {$else}
    {$IFDEF Win32 }
      DriveStr[1] := Drive;
      case GetDriveType(@DriveStr[1]) of
        DRIVE_REMOVABLE,
        DRIVE_FIXED:     DriveType := 1;
        DRIVE_RAMDISK:   DriveType := 2;
        DRIVE_REMOTE:    DriveType := 5;
        DRIVE_CDROM:     DriveType := 6;
      else
        DriveType := 0;
      end;
    {$ELSE }
      DriveType := 1;
    {$ENDIF }
  {$endif}
end;
{$ELSE }

  function laufwerke:byte;
  var regs : registers;
  begin
    intr($11,regs);
    if not odd(regs.ax) then laufwerke:=0
    else laufwerke:=(regs.ax shr 6) and 3 + 1;
  end;

var regs : registers;
begin
  if (drive='B') and (laufwerke=1) then
    drivetype:=0
  else
    with regs do begin
      ax:=$4409;
      bl:=ord(drive)-64;
      msdos(regs);
      if flags and fcarry<>0 then
        drivetype:=0
      else
        if dx and $8000<>0 then drivetype:=3 else
        if dx and $1000<>0 then drivetype:=5 else
        if dx and $8ff=$800 then drivetype:=2 else
        if dx and $4000<>0 then drivetype:=4 else
        drivetype:=1;
    end;
end;
{$ENDIF }

function alldrives:string;

  {$IFDEF BP  }
  function GetMaxDrive:char;
  var regs : registers;
  begin
    with regs do begin
      ah:=$19;
      msdos(regs);        { aktuelles LW abfragen; 0=A, 1=B usw. }
      ah:=$e; dl:=al;
      msdos(regs);        { aktuelles LW setzen; liefert lastdrive in al }
      GetMaxDrive:=chr(al+64);
    end;
  end;
  {$ENDIF }

var b : byte;
    s : string;
    c : char;
{$IFDEF Ver32 }
    Drives: longint; { Bitmaske mit vorhandenen Laufwerken }
    i: integer;
{$ENDIF }
begin
  b:=0;
{$IFDEF BP }
  for c:='A' to GetMaxdrive do
    if drivetype(c)>0 then begin
      inc(b);
      s[b]:=c;
    end;
{$ELSE }
  {$IFDEF Vp }
    Drives:=SysGetValidDrives;
  {$ELSE }
    {$IFDEF Win32 }
      Drives := GetLogicalDrives;
    {$ELSE }
      Drives := 1 shl 27 - 1; {!!}
    {$ENDIF }
  {$ENDIF }
    for i := 0 to 25 do
      if (Drives and (1 shl i)) > 0 then
      begin
        inc(b);
        s[b] := Chr(i + 65);
      end;
{$ENDIF }
  s[0]:=chr(b);
  alldrives:=s;
end;

{$IFDEF OS2}
function ConfigFiles:byte;                {TJ 110400 - setzt die mal auf 255,
                                           sollte erstmal reichen}
var
        rc  : ApiRet;
begin
 rc := DosSetMaxFH(255);                  {TJ 110400 - ob 255 ausreichen ?
                                           OS/2 kann soviele Files
                                           oeffnen wie Speicher da is}
 if rc <> No_Error then                   { fuer XP solls reichen :))))... }
  begin
   WriteLn('DosSetMaxFH Error (DOSX.PAS): rc = ',rc);
   Halt(99);
  end; {if}
 ConfigFILES:=255;
end; {ConfigFiles}

function FreeFILES(maxfiles:byte):word;       {TJ 110400 - Ist zwar Evil... aber was solls...}
var f  : array[1..255] of ^file;
    i  : integer;
    fm : byte;
begin
  i:=0;
  fm:=filemode;
  filemode:=$40;
  repeat
    inc(i);
    new(f[i]);
    assign(f[i]^,'nul');
    reset(f[i]^,1);
  until (i=maxfiles) or (inoutres<>0);
  if ioresult<>0 then begin
    dispose(f[i]); dec(i); end;
  FreeFILES:=i;
  while i>0 do begin
    close(f[i]^);
    dispose(f[i]);
    dec(i);
  end;
  filemode:=fm;
end; {FreeFiles}
{$ENDIF}

{$IFDEF BP }
function ConfigFILES:byte;                  { FILES= .. - DOS >= 2.0! }
type wa   = array[0..2] of word;
var  regs : registers;
     wp   : ^wa;
     n    : word;
begin
  with regs do begin
    ah:=$52;             { Get List of Lists }
    msdos(regs);
    wp:=ptr(es,bx+4);
    wp:=ptr(wp^[1],wp^[0]);
    n:=0;
    while ofs(wp^)<>$ffff do begin
      inc(n,wp^[2]);
      wp:=ptr(wp^[1],wp^[0]);
    end;
    if n>255 then n:=255;
    ConfigFILES:=n;
  end;
end;
{$ENDIF }

{$IFDEF BP }
function FreeFILES(maxfiles:byte):word;
var f  : array[1..255] of ^file;
    i  : integer;
    fm : byte;
begin
  i:=0;
  fm:=filemode;
  filemode:=$40;
  repeat
    inc(i);
    new(f[i]);
    assign(f[i]^,'nul');
    reset(f[i]^,1);
  until (i=maxfiles) or (inoutres<>0);
  if ioresult<>0 then begin
    dispose(f[i]); dec(i); end;
  FreeFILES:=i;
  while i>0 do begin
    close(f[i]^);
    dispose(f[i]);
    dec(i);
  end;
  filemode:=fm;
end;
{$ENDIF}

{$IFDEF BP }
procedure XIntr(intno:byte; var regs:registers);   { DPMI-kompatibler Intr }
var dpmistruc : record
                  edi,esi,ebp,reserved : longint;
                  ebx,edx,ecx,eax      : longint;
                  flags,es,ds,fs,gs    : word;
                  ip,cs,sp,ss          : word;
                end;
    regs2     : registers;
begin
  {$IFNDEF DPMI}
    intr(intno,regs);
  {$ELSE}
    with dpmistruc do begin       { Register-Translation-Block aufbauen }
      edi:=regs.di; esi:=regs.si;
      ebp:=regs.bp; reserved:=0;
      ebx:=regs.bx; edx:=regs.dx;
      ecx:=regs.cx; eax:=regs.ax;
      flags:=$200;
      es:=regs.es; ds:=regs.ds;
      fs:=regs.es; gs:=regs.es; cs:=regs.es;
      sp:=0; ss:=0;      { neuen Real-Mode-Stack anlegen }
    end;
    with regs2 do begin           { Protected-Mode-Int aufrufen }
      ax:=$300;
      bx:=intno;
      cx:=0;
      es:=seg(dpmistruc);
      di:=ofs(dpmistruc);
      intr(DPMI,regs2);
    end;
    with dpmistruc do begin       { Real-Mode-Register zurÅckkopieren }
      regs.ax:=eax and $ffff; regs.bx:=ebx and $ffff;
      regs.cx:=ecx and $ffff; regs.dx:=edx and $ffff;
      regs.bp:=ebp and $ffff;
      regs.si:=esi and $ffff; regs.di:=edi and $ffff;
      regs.ds:=ds; regs.es:=es; regs.flags:=flags;
    end;
  {$ENDIF}
end;
{$ENDIF }

{$IFDEF BP }
function DPMIallocDOSmem(paras:word; var segment:word):word;
var regs : registers;
begin
  with regs do begin
    ax:=$100;
    bx:=paras;
    intr(DPMI,regs);
    if flags and fcarry<>0 then begin
      segment:=0;
      DPMIallocDOSmem:=0;
    end
    else begin
      segment:=regs.ax;
      DPMIallocDOSmem:=dx;
    end;
  end;
end;
{$ENDIF}

{$IFDEF BP }
procedure DPMIfreeDOSmem(selector:word);
var regs : registers;
begin
  regs.ax:=$101;
  regs.dx:=selector;
  intr(DPMI,regs);
end;
{$ENDIF }


function IsDevice(fn:pathstr):boolean;
{$IFDEF BP }
var f    : file;
    regs : registers;
begin
  assign(f,fn);
  reset(f);
  if ioresult<>0 then
    IsDevice:=false
  else begin
    with regs do begin
      ax:=$4400;        { IOCTL Get device data }
      bx:=filerec(f).handle;
      msdos(regs);
      IsDevice:=(flags and fcarry=0) and (dx and 128<>0);
      end;
    close(f);
    end;
{$ELSE }
begin
  { COMs sind Devices, der Rest nicht }
  IsDevice := Pos('COM', fn) = 1;              {TJ 110400 - da bin ich mir nicht sicher was MK da verzapft hat...}
{$ENDIF }
end;


end.
{
  $Log: dosx.pas,v $
  Revision 1.13  2001/12/30 11:50:56  mm
  - Sourceheader

  Revision 1.12  2001/06/18 20:17:16  oh
  Teames -> Teams

  Revision 1.11  2000/10/01 17:02:24  tj
  aktuellen Sourceheader eingefuegt

  Revision 1.10  2000/10/01 16:58:26  tj
  OS/2: Systemfehlermeldung Fehlendes Medium im Laufwerk wird nun zum Teil unterbunden

  Revision 1.9  2000/06/27 21:49:32  rb
  bedingte Kompilierung bei uses-Anweisung angepasst fÅr Win32

  Revision 1.8  2000/05/25 23:00:25  rb
  Loginfos hinzugefÅgt

  Revision 1.7  2000/04/19 23:18:56  tj
  jetzt compiliert es auch aus dem vpc heraus fehlerfrei

  Revision 1.6  2000/04/15 19:30:07  oh
  - zu lange Zeile umgebrochen, DOS-Version kompiliert jetzt durch :)

  Revision 1.5  2000/04/11 23:15:47  tj
  OS/2 Portierung in einigen Funktionen

  Revision 1.4  2000/04/09 18:05:03  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

----
  Sourcetree ab hier getrennt weiterentwickelt
----

  Revision 1.11  2000/03/25 00:29:22  mk
  - GetDriveType und AllDrives jetzt sauber portiert

  Revision 1.10  2000/03/24 23:11:16  rb
  VP Portierung

  Revision 1.9  2000/03/24 00:03:39  rb
  erste Anpassungen fÅr die portierung mit VP

  Revision 1.8  2000/03/14 15:15:35  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.7  2000/03/09 23:39:32  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.6  2000/02/19 11:40:06  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.5  2000/02/17 16:14:19  mk
  MK: * ein paar Loginfos hinzugefuegt

}
