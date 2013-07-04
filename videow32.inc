{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams.  }
{ Aenderungen des Sources, die vom OpenXP Teams getaetigt wurden, }
{ unterliegen den Rechten, die bis zum 09.04.2000 fuer das OpenXP }
{ Team gueltig waren.                                             }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: videow32.inc,v 1.5 2001/07/31 17:16:43 mm Exp $ }

{  ==================  Interface-Teil  ===================  }

INTERFACE

uses  xpglobal, windows
      {$IFDEF VirtualPascal }
      ,vputils
      {$ENDIF }
      ;

const DPMS_On       = 0;    { Monitor an }        { ÅberflÅssig, das Åbernimmt das OS }
      DPMS_Standby  = 1;    { Stromsparstufe 1 }
      DPMS_Suspend  = 2;    { Stromsparstufe 2 }
      DPMS_Off      = 4;    { Monitor aus }
      
      vrows  : word = 80;                  { Anzahl Bildspalten  }
      vrows2 : word = 160;                 { Bytes / Zeile       }
      vlines : word = 25;                  { Anzahl Bildzeilen   }

var   vtype  : byte;
      Outhandle : THandle;

function  VideoType:byte;                  { 0=Herc, 1=CGA, 2=EGA, 3=VGA }
function  GetVideoMode:byte;
procedure SetVideoMode(mode:byte);

function  SetVesaDpms(mode:byte):boolean;

function  GetScreenLines:byte;
procedure SetScreenLines(lines:byte);
function  GetScreenWidth:byte;
procedure SetScreenWidth(width:byte);
procedure SetScreenSize;


{ ================= Implementation-Teil ==================  }

IMPLEMENTATION

procedure GetVideotype;
begin
  vtype:=4;
end;

function GetVideoMode;
begin
  GetVideoMode:= 3;
end;

function  VideoType:byte;
begin
  VideoType := vtype;
end;

procedure SetVideoMode(mode:byte);
begin
end;

procedure SetScreenSize;
var
  ScreenBufferSize: TCoord;
  Console:          TSmallRect;
begin
  Console.Left := 0; Console.Right  := vrows-1;
  Console.Top  := 0; Console.Bottom := vlines-1;
  SetConsoleWindowInfo(OutHandle, True, Console);
  ScreenBufferSize.X := vrows;
  ScreenBufferSize.Y := vlines;
  SetConsoleScreenBufferSize(OutHandle, ScreenBufferSize);
end;

procedure SetScreenLines(lines:byte);
begin
  vlines:=Max(lines,25);
  if (lines<>GetScreenLines) then SetScreenSize;
end;

procedure SetScreenWidth(width:byte);
begin
  vrows:=Max(width,80); vrows2:=Max(width*2,160);
  if (width<>GetScreenWidth) then SetScreenSize;
end;

function GetScreenLines:byte;
var
  csbi: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenbufferInfo(OutHandle, csbi);
  GetScreenLines := Max(csbi.srwindow.bottom+1, 25);
end;

function GetScreenWidth:byte;
var
  csbi: TConsoleScreenBufferInfo;
begin
  GetConsoleScreenbufferInfo(OutHandle, csbi);
  GetScreenWidth := Max(csbi.srwindow.right+1, 80);
end;

function SetVesaDpms(mode:byte):boolean;  { Bildschirm-Stromsparmodus }
begin
end;

begin
  GetVideoType;
  OutHandle := GetStdHandle(STD_OUTPUT_HANDLE);
{
  $Log: videow32.inc,v $
  Revision 1.5  2001/07/31 17:16:43  mm
  - Support fuer breitere Consolen
  - Consolengroesse nur noch neusetzen, wenn notwendig

  Revision 1.4  2001/07/25 19:55:09  mm
  no message

  Revision 1.3  2001/07/25 19:53:07  mm
  - in Win32-Version erst mal nur die ConsolenModes auswaehlbar welche 
    wirklich sauber funktionieren (auch im Fullscreen): 80*25/43/50

  Revision 1.2  2001/07/23 13:38:46  mm
  no message

  Revision 1.1  2001/07/23 12:43:27  mm
  - erste, notduerftige Win32-Portierung:
    Zeilenanzahl kann jetzt wieder wie in DOS-Version geaendert werden

}
