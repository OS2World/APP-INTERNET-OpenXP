{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: videoos2.inc,v 1.4 2001/07/23 12:41:38 mm Exp $ }

(***********************************************************)
(*                                                         *)
(*                       UNIT video                        *)
(*                                                         *)
(*             Video-BIOS-Interface fuer OS/2              *)
(*  TJ 190200                                              *)
(***********************************************************)

{$O+,F+,A+}


{  ==================  Interface-Teil  ===================  }

INTERFACE

uses dos,crt,dosx,vputils,vpsyslow,os2def,os2base,xpglobal;

const DPMS_On       = 0;    { Monitor an }             {TJ 190200 - ohne Bedeutung, da DPMS vom BS}
      DPMS_Standby  = 1;    { Stromsparstufe 1 }       {wenn ueberhaupt uebernohmen wird}
      DPMS_Suspend  = 2;    { Stromsparstufe 2 }
      DPMS_Off      = 4;    { Monitor aus }

      vrows  : word = 80;                  { Anzahl Bildspalten  }
      vrows2 : word = 160;                 { Bytes / Zeile       }
      vlines : word = 25;                  { Anzahl Bildzeilen   }

var  vbase  : word;                        { Screen-Base-Adresse }


function  VideoType:byte;                  { 0=Herc, 1=CGA, 2=EGA, 3=VGA }
function  GetVideoPage:byte;               { aktuelle Video-Seite abfragen }

function  GetVideoMode:byte;
procedure SetVideoMode(mode:byte);
procedure SetVideoPage(page:byte);         { angezeigte Seite setzen }
procedure SetBorder64(color:byte);         { EGA-Rahmenfarbe einstellen }
procedure SetBorder16(color:byte);         { CGA-Rahmenfarbe einstellen }

function  SetVesaDpms(mode:byte):boolean;  { Bildschirm-Stromsparmodus }

procedure setcur(x,y:byte);                { Cursor positionieren }
procedure cur1;                            { Cursor an }
procedure cur0;                            { Cursor aus }

procedure SetBackIntensity(hell:boolean);  { heller Hintergrund oder Blinken }
function  GetBackIntensity:boolean;        { true = hell, false = blink }
procedure LoadFont(height:byte; var data); { neue EGA/VGA-Font laden }
procedure LoadFontFile(fn:pathstr);        { Font aus Datei laden }
function  GetScreenLines:byte;
procedure SetScreenLines(lines:byte);      { Bildschirmzeilen setzen }
function  GetScreenColoumns:byte;

procedure vsetclchar(c:char);              { Lîsch-Zeichen festlegen }
procedure vclwin(l,r,o,u,attr:word);       { Fenster lîschen         }
procedure vclrscr(attr:byte);              { Bildschirm lîschen      }
procedure vrahmen(l,r,o,u:word; typ,attr:byte; clr:boolean; head:string);
procedure vwrt(x,y:word; txt:String; attr:byte);


{ ================= Implementation-Teil ==================  }

IMPLEMENTATION


const clchar : char = ' ';
      rchar  : array[1..4,1..6] of char =
               ('⁄ƒø≥¿Ÿ','…Õª∫»º','’Õ∏≥‘æ','±±±±±±');

type ba  = array[0..65000] of byte;
     bp  = ^ba;

var vtype   : byte;
    sclines : word;                  { tatsÑchliche Bildzeilen }
    ca,ce   : byte;                  { Cursor-Werte }
    oldexit : pointer;
    p1,p2   : bp;                    { Zeiger fÅr Font-Generator }

{- BIOS-Routinen ----------------------------------------------}

function  videotype:byte;                  {TJ 130200}

var
   rc      : ApiRet;
   adapinf : VioConfigInfo;

begin
 adapinf.cb:=sizeof(adapinf);
 videotype:=0;
 rc:=VioGetConfig(0,                       {current configuration}
                  adapinf,                 {beinhaltet benoetigte Info}
                  0);                      {da keine PM App, daher 0}
 if rc <> 0 then
  begin
   writeln('Fehler in VIDEO.PAS in der Funktion "Videotyp": ',rc);
   halt(99);
  end; {if}
 if adapinf.adapter=0 then videotype:=0;  {monochrome}
 if adapinf.adapter=1 then videotype:=1;  {CGA}
 if adapinf.adapter=2 then videotype:=2;  {EGA}
 if adapinf.adapter > 2 then videotype:=3;  {VGA und besser, XGA und so}
end; {videotype}

procedure setvideomode(mode : byte);           { BIOS-Mode-Nr. setzen }
                                               { TJ 280200 }
begin
  textmode(MONO);                             { TJ 280200 - Hier kann man sich streiten, was }
  if mode = 3 then textmode(CO80);            { man als Default bei einem missglueckten Mode }
  if mode = 7 then textmode(BW80);            { Uebergabe nimmt }
  if mode = 0 then textmode(BW40);            { TJ 290200 - Hoffe, das dies nie einer nutzt  }
  if mode = 1 then textmode(CO40);            {             - " - }
end; {setvideomode}

function  GetVideoPage:byte;      { aktuelle Video-Seite abfragen }
begin                             { TJ 290200 - Nach Grep wird das nicht gebraucht }
end; {GetVideoPage}

procedure setvideopage(page:byte);
begin                             { TJ 290200 - Nach Grep wird das nicht gebraucht }
end; {setvideopage}

procedure SetBorder64(color:byte);   { EGA-Rahmenfarbe einstellen }
begin                                {TJ 190200 - Dummy, da der Aufwand nicht lohnt}
end; {SetBorder64}

procedure SetBorder16(color:byte);   { CGA-Rahmenfarbe einstellen }
begin                                {TJ 190200 - Dummy, da der Aufwand nicht lohnt}
end; {SetBorder16}

procedure SetBackIntensity(hell:boolean);  { hellen Hintergr. akt. }

var
   state  : VioIntensity;
begin
 state.cb:=6;
 state.rType:=2;                           { TJ 010300 - Blink/Bold switch }
 if hell=true then state.fs:=1;            { TJ 010300 - Intensity on }
 if hell=false then state.fs:=0;           { TJ 010300 - Intensity off }
 VioSetState(state,0);                     { TJ 290200 }
end; {SetBackIntensity}

procedure setcur(x,y:byte);  { Cursor positionieren }  {TJ 160200}
begin
 VioSetCurPos(y,x,0);        {3. Parameter: 0 = Textmode App}
end; {setcur}

procedure cur1;       { Cursor an }       {TJ 120200}
begin
 showcursor;
end; {cur1}

procedure cur0;       { Cursor aus }      {TJ 120200}
begin
 hidecursor;
end; {cur0}

function SetVesaDpms(mode:byte):boolean;  { Bildschirm-Stromsparmodus }
begin                                     { TJ 190200 - ist Aufgabe des Betriebsystem}
 SetVesaDpms:=false;
end; {SetVesaDpms}

procedure LoadFont(height:byte; var data);
begin                                     { TJ 190200 - Loesung im VIO Mode nur mit grossen Einschraenkungen}
end; {LoadFont}                           { moeglich, daher vieleicht fuer die AVIO Version aufsparen}

procedure LoadFontFile(fn:pathstr);       { Font aus Datei laden }
begin                                     { TJ 190200 - siehe procedure vorher}
end; {LoadFontFile}

procedure SetScreenLines(lines:byte);     { TJ 190200 - ein Teil von der AVIO Funktion}
                                          { arbeitet noch nicht so wie sie soll crt Prob.}
Var
  vm     : VioModeInfo;
  Ergb   : boolean;

begin
  textmode($ff);                          { TJ 290200 - Tipp von Veit Kannegieser }
  vm.cb := 8;          { Size of structure }
  VioGetMode(vm, 0);
  vm.fbType := 1;      { Text mode }
  vm.Row := lines;
  vm.Col := 80;
  vm.Color := 4;       { 16 colors }
  Ergb := ( VioSetMode( vm, 0 ) = 0 );
  if Ergb=false then
   begin
    writeln('Fehler in Unit VIDEO.PAS (OS2) in Procedure SetScreenLines !');
    halt(99);
   end;
end; {SetScreenLines}

procedure vsetclchar(c:char);              { Lîsch-Zeichen festlegen }
begin
  clchar:=c;
end;

procedure vclwin(l,r,o,u,attr:word);  { TJ 010300 - Wird in XP laut Grep nicht benoetigt }
begin
 writeln('!!! Dummyfunktion !!! Diese Meldung duerfte nicht ausgegeben werden ! (VIDEO2.PAS)');
 writeln('---> vclwin');
end; {vclwin}

procedure vclrscr(attr:byte);         { TJ 010300 - Wird in XP laut Grep nicht benoetigt }
begin
 writeln('!!! Dummyfunktion !!! Diese Meldung duerfte nicht ausgegeben werden ! (VIDEO2.PAS)');
 writeln('---> vclrscr');
end; {vclrscr}

procedure vrahmen(l,r,o,u:word; typ,attr:byte; clr:boolean; head:string);
begin                                 { TJ 010300 - Wird in XP laut Grep nicht benoetigt }
 writeln('!!! Dummyfunktion !!! Diese Meldung duerfte nicht ausgegeben werden ! (VIDEO2.PAS)');
 writeln('---> vrahmen');
end; {vrahmen}

procedure vwrt(x,y:word; txt:String; attr:byte);
begin                                 { TJ 010300 - Wird in XP laut Grep nicht benoetigt }
 writeln('!!! Dummyfunktion !!! Diese Meldung duerfte nicht ausgegeben werden ! (VIDEO2.PAS)');
 writeln('---> vwrt');
end; {vwrt}

function getvideotype : byte;    {TJ 010300 - IMHO Bloedsinn, wird auch nur innerhalb der Unit benoetigt}
begin
 getvideotype:=0;
 getvideotype:=videotype;
end; {getvideotype}

procedure getcursor;                  { TJ 010300 - Wird in XP laut Grep nicht benoetigt }
begin
 writeln('!! Dummyfunktion !! Diese Meldung duerfte nicht ausgegeben werden ! (VIDEO2.PAS)');
 writeln('---> getcursor');
end; {getcursor}

function getvideomode:byte;

var
        size : PSysPoint;

begin
 size:=nil;
 getvideomode:=0;                        { TJ 010300 - BW40 }
 getvideomode:=SysTvGetScrMode(size);
end; {getvideomode}

function getscreenlines:byte;              {TJ 190200}

var
        cols,
        rows,
        colours  : word;
begin
  GetVideoModeInfo( Cols, Rows, Colours );
  GetScreenLines:=rows;
end; {getscreenlines}


function GetScreenColoumns:byte;           {TJ 190200}

var
        cols,
        rows,
        colours  : word;
begin
  GetVideoModeInfo( Cols, Rows, Colours );
  GetScreenColoumns:=Cols;
end; {getscreencoloumns}


function GetBackIntensity:boolean;        { true = hell, false = blink }
                                          {TJ 190200}
var
        state  : VioIntensity;
begin
  GetBackIntensity:=false;
  state.cb:=6;
  state.rtype:=2;
  VioGetState(state,0);
  if state.fs=1 then GetBackIntensity:=true else GetBackIntensity:=false;
end; {GetBackIntensity}

{$F+,S-}
procedure newexit;
begin
  exitproc:=oldexit;
  cur1;
end;


{Hauptroutine}
begin
  getvideotype;
  oldexit:=exitproc;
  exitproc:=@newexit;

{
  $Log: videoos2.inc,v $
  Revision 1.4  2001/07/23 12:41:38  mm
  - kleine Anpassung wegen Win32-Source-Einpflanzung

  Revision 1.3  2000/05/25 23:12:50  rb
  Loginfos hinzugefÅgt

}
