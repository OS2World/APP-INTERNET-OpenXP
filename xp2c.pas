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
{ $Id: xp2c.pas,v 1.39 2002/01/01 12:47:00 mm Exp $ }

{ CrossPoint - Config bearbeiten }

{$I XPDEFINE.INC }
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp2c;

interface

uses xpglobal, crt,dos,typeform,fileio,inout,winxp,win2,keys,maske,
     datadef,database,
{$IFDEF CAPI }
     capi,
{$ENDIF CAPI }
     printerx,mouse,maus2,uart,resource,lister,editor,video,
     xp0,xp1,xp1input,xpdatum;

procedure options;
procedure UI_options;
procedure msgoptions;
procedure adroptions;
procedure netcalloptions;
procedure listoptions;
procedure Xlistoptions;
procedure editoptions;
procedure shelloptions;
procedure brett_config;
procedure NachrichtenanzeigeCfg;
procedure MiscAnzeigeCfg;
procedure AccessibilityOptions;
procedure ModemConfig(nr:byte);
procedure path_config;
procedure ArcOptions;
procedure DruckConfig;
procedure pmcOptions;
procedure ViewerOptions;
procedure FidoOptions;
procedure NetOptions;
procedure SizeOptions;
procedure NetEnable;
procedure GebuehrOptions;
procedure TerminalOptions;
procedure PGP_Options;


{ Testfunktionen; m�ssen wg. Overlay im Interface-Teil stehen: }

function smalladr(var s:string):boolean;
function testbrett(var s:string):boolean;
function scstest(var s:string):boolean;
function formpath(var s:string):boolean;
function testexist(var s:string):boolean;
function testarc(var s:string):boolean;
function testenv(var s:string):boolean;
function testhayes(var s:string):boolean;
function testfifo(var s:string):boolean;
function testfossil(var s:string):boolean;
function testpostanschrift(var s:string):boolean;
function testurl(var s:string):boolean;
function testtimezone(var s:string):boolean;
function SetTimezone(var s:string):boolean;
function testpgpexe(var s:string):boolean;
function testxpgp(var s:string):boolean;
function dpmstest(var s:string):boolean;

procedure setvorwahl(var s:string);
procedure DispArcs;
procedure TestQC(var s:string);
{$IFDEF CAPI }
procedure TestCapiInt(var s:string);
procedure IsdnConfig;
{$ENDIF CAPI }


implementation  {----------------------------------------------------}

uses xp1o,xp2,xp4o2,xp9bp;

var hayes     : boolean;
    small     : boolean;
    oldfossil : char;
    tzfeld    : shortint;
{$IFDEF CAPI }
    isdnx,isdny : byte;   { x/y bei IsdnConfig }
{$ENDIF }
    GPGEncodingOptionsField: integer;


function testbrett(var s:string):boolean;
begin
  if (s<>'') and (s[1]<>'/') then
    insert('/',s,1);
  testbrett:=true;
end;

procedure TestQC(var s:string);
begin
  if trim(s)='' then s:='> ';
end;


{ Verschiedene Optionen }

procedure options;
var x,y : byte;
    brk : boolean;
    ua  : string[10];
    i   : integer;
begin
  dialog(56,17,getres2(250,1),x,y);    { 'allgemeine Optionen' }
  maddstring(3,2,getres2(250,2),QuoteChar,QuoteLen,QuoteLen,range(' ',#126));   { 'Quote-Zeichen ' }
  mset3proc(testqc);
  mnotrim; mhnr(210);
  maddint(3,3,getres2(250,3),QuoteBreak,3,5,40,119);  { 'Zeilenumbruch ' }
  ua:=aufnahme_string;
  maddstring(3,5,getres2(250,4),ua,7,7,'');           { 'User-Aufnahme ' }
  for i:=5 to 7 do
    mappsel(true,getres2(250,i));    { 'Alle�Z-Netz�PMs' }
  {$IFDEF DPMI}
    maddbool(32,2,getres2(250,10),AskQuit); mhnr(214);   { 'Fragen bei Quit' }
  {$ELSE}
    maddbool(32,2,getres2(250,11),SwapToEMS);   { 'Auslagern in EMS' }
    maddbool(32,3,getres2(250,18),SwapToXMS);   { 'Auslagern in XMS' }
      mhnr(213);
    maddbool(32,4,getres2(250,10),AskQuit);
  {$ENDIF}
  maddstring(3,7,getres2(250,12),archivbretter,35,BrettLen-1,'>'); mhnr(217);
  msetvfunc(testbrett);                                           { 'Archivbretter '                       }
  maddbool(3, 9,getres2(250,13),archivloesch);                    { 'archivierte Nachrichten l�schen'      }
  maddbool(3,10,getres2(250,22),archivtext);mhnr(225);            { 'Archivierungsvermerk erstellen'       }
  maddbool(3,11,getres2(250,14),newbrettende);mhnr(219);          { 'neue Bretter am Ende anh�ngen'        }
  maddbool(3,12,getres2(250,15),UserBoxname);                     { 'Boxname in PM-Brettern'               }
  maddbool(3,13,getres2(250,19),brettkomm);                       { 'Kommentare aus Brettliste �bernehmen' }
  maddbool(3,14,getres2(250,20),newuseribm);                      { 'Umlaute f�r neue User zulassen'       }
  maddbool(3,15,getres2(250,21),OtherQuoteChars);                 { 'Farbe auch f�r Quotezeichen : und |'  }
  maddint (3,17,getreps2(250,16,left(ownpath,2)),MinMB,5,3,1,999);{ 'minimaler Platz auf Laufwerk %s '     }
  maddtext(length(getres2(250,16))+11,17,getres2(250,17),0);      { 'MByte'                                }
  readmask(brk);
  if not brk and mmodified then begin
    if ustr(ua)=ustr(getres2(250,5)) then UserAufnahme:=0       { 'ALLE' }
    else if ustr(ua)=ustr(getres2(250,6)) then UserAufnahme:=1  { 'Z-NETZ' }
    else if ustr(ua)=ustr(getres2(250,7)) then UserAufnahme:=3; { 'PMS' }
    { else UserAufnahme:=2;  keine - gibt's nicht mehr }
{$IFDEF BP }
    ListUseXms:=SwapToXms;
{$ENDIF}
    GlobalModified;
    end;
  freeres;
  enddialog;
  menurestart:=brk;
end;

procedure UI_options;
var x,y  : byte;
    brk  : boolean;
    xa   : array[0..3] of string[15];
    lm   : array[0..3] of string[10];
    xas  : string[15];
    lms  : string[10];
    dbl  : array[0..2] of string[10];
    dbls : string[10];
    stp  : array[0..2] of string[15];
    save : string[15];
    i    : integer;
    oldm : boolean;

begin
  for i:=0 to 3 do
    xa[i]:=getres2(251,i);     { 'Text ohne Kopf' / 'Text mit Kopf' / 'Puffer' / 'Quote' }
  for i:=0 to 3 do
    lm[i]:=getres2(251,i+5);   { 'Alles' / 'Ungelesen' / 'Neues' / 'Heute' }
  for i:=0 to 2 do
    dbl[i]:=getres2(251,i+10); { 'langsam' / 'normal' / 'schnell' }
  for i:=0 to 2 do
    stp[i]:=getres2(251,i+40); { 'automatisch' / 'manuell' / 'R�ckfrage' }
  dialog(66,12,getres2(251,15),x,y);    { 'Bedienungs-Optionen' }
  maddbool(3,2,getres2(251,16),AAmsg);  mhnr(550);   { 'Nachr.-Weiterschalter' }
  maddbool(3,3,getres2(251,17),AAbrett);   { 'Brett-Weiterschalter' }
  maddbool(3,4,getres2(251,18),AAuser);    { 'User-Weiterschalter' }
  lms:=lm[DefReadMode];
  maddstring(3,6,getres2(251,19),lms,14,11,''); mhnr(554);   { 'Lese-Modus  ' }
  for i:=0 to 3 do mappsel(true,lm[i]);
  xas:=xa[defExtraktTyp];
  maddstring(3,7,getres2(251,20),xas,14,14,'');   { 'Extrakt als ' }
  for i:=0 to 3 do mappsel(true,xa[i]);
  save:=stp[SaveType];
  maddstring(3,8,getres2(251,26),save,14,14,'');  { 'Sichern ' }
  for i:=0 to 2 do mappsel(true,stp[i]); mhnr(586);
  maddbool(3,10,getres2(251,25),leaveconfig); mhnr(585);  { 'Config-Men� bei <Esc> vollst�ndig verlassen' }
  maddbool(3,11,getres2(251,27),msgbeep); mhnr(587);  { 'Tonsignal in Brett-, User- und Nachrichten�bersicht' }
  oldm:=_maus;
  maddbool(39,2,getres2(251,21),_maus); mhnr(556);       { 'Maus-Bedienung' }
  maddbool(39,3,getres2(251,22),SwapMausKeys);    { 'Tasten vertauschen' }
  maddbool(39,4,getres2(251,23),MausShInit);      { 'Initialisierung' }
  if MausDblClck>=mausdbl_slow then dbls:=dbl[0] else
  if MausDblClck>=mausdbl_norm then dbls:=dbl[1]
  else dbls:=dbl[2];
  maddstring(39,6,getres2(251,24),dbls,9,9,'<');  { 'Doppelklick ' }
  for i:=0 to 2 do mappsel(true,dbl[i]);
  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    for i:=0 to 3 do
      if lstr(xas)=lstr(xa[i]) then defExtraktTyp:=i;
    for i:=0 to 3 do
      if lstr(lms)=lstr(lm[i]) then DefReadMode:=i;
    for i:=0 to 2 do
      if lstr(save)=lstr(stp[i]) then SaveType:=i;
    for i:=0 to 2 do
      if dbls=dbl[i] then
        case i of
          0 : MausDblClck:=mausdbl_slow;
          1 : MausDblClck:=mausdbl_norm;
          2 : MausDblClck:=mausdbl_fast;
        end;
    maus_setdblspeed(MausDblClck);
    mausswapped:=SwapMausKeys;
    if _maus<>oldm then begin
      if _maus then begin
        mausinit;
        xp_maus_an(mausdefx,mausdefy);
      end
      else begin
        _maus:=true;
        xp_maus_aus;
        _maus:=false;
      end;
      SetMausEmu;
    end;
    nachweiter:=AAmsg; brettweiter:=AAbrett; userweiter:=AAuser;
    ExtraktTyp:=defExtraktTyp; checker[13]:=defExtraktTyp+1; SetExtraktMenu;
    {if (AktDispMode=10) then ReadMode:=DefReadMode;}
    GlobalModified;
  end;
  enddialog;
  menurestart:=brk;
end;


function testtimezone(var s:string):boolean;
var p   : byte;
    h,m : integer;    { W+00:00 }
begin
  p:=cpos(':',s);
  if p=0 then p:=length(s)+1;
  if pos(':',mid(s,p+1))>0 then
    testtimezone:=false       { mehrere ':' }
  else if (p<4) or (p>5) then
    testtimezone:=false       { : an falscher Stelle }
  else begin
    h:=ival(copy(s,3,p-3));
    if s[2]='-' then h:=-h;
    m:=ival(mid(s,p+1));
    testtimezone:=((length(s)>=3) and (s[1] in ['W','S']) and
                   (s[2] in ['+','-']) and (h>=-13) and (h<=13) and
                   (m in [0..59])) or (s='AUTO');
    end;
end;

function SetTimezone(var s:string):boolean;
begin
  setfieldenable(tzfeld,s=_jn_[2]);
  settimezone:=true;
end;

procedure msgoptions;
var x,y : byte;
    brk : boolean;
    xid : string[7];
    i   : byte;
    xnr : byte;
    xids: array[0..3] of string[6];
    scs : string[18];
    scss: array[0..4] of string[18];
    tz  : string[7];
begin
  for i:=0 to 3 do
    xids[i]:=getres2(252,i);   { 'nie','PMs','AMs','immer' }
  for i:=0 to 4 do
    scss[i]:=getres2(252,30+i);
    { 'immer','nicht halten','nicht Wdvlg.','nicht (h. od. Wv.)','nie' }
  dialog(59,22,getres2(252,5),x,y);   { 'Nachrichten-Optionen' }
  maddint (3, 2,getres2(252,6),maxbinsave,6,5,0,99999);       { 'max. Speichergr��e f�r Bin�rnachrichten: ' }
  maddtext(length(getres2(252,6))+12,2,getres2(252,7),col.coldialog); mhnr(240);   { 'KB' }
  maddint (3, 4,getres2(252,11),stdhaltezeit,4,4,0,9999);               { 'Standard-Bretthaltezeit:     ' }
  maddtext(length(getres2(252,11))+11,4,getres2(252,12),col.coldialog); { 'Tage' }
  maddint (3, 5,getres2(252,13),stduhaltezeit,4,4,0,9999);              { 'Standard-Userhaltezeit:      ' }
  maddtext(length(getres2(252,13))+11,5,getres2(252,12),col.coldialog); { 'Tage' }
  maddbool(3, 7,getres2(252,14),haltown);                               { 'Eigene Nachrichten halten' }
  maddbool(3, 8,getres2(252,35),haltownPM);mhnr(243);                   { 'Eigene PMs halten' }
  maddbool(3, 9,getres2(252,15),ReplaceEtime);                          { 'Erstellungszeit 00:00' }
  mset1func(SetTimezone);
  maddstring(38,7,getres2(252,23),TimeZone,7,7,'>SW+-0123456789:');mhnr(246); { 'Zeitzone  ' }
  mappsel(false,'W+1�S+2�AUTO'); tzfeld:=fieldpos;
  msetvfunc(testtimezone);
  if replaceetime then mdisable;
  xid:=xids[iif(XP_ID_PMs,1,0)+iif(XP_ID_AMs,2,0)];
  maddstring(38,9,'## XP ## ',xid,7,7,'');
  for i:=3 downto 0 do
    mappsel(true,xids[i]);                               { 'immer�AMs�PMs�nie' }
  maddbool(3,11,getres2(252,16),rehochn);mhnr(245);      { 'Re^n verwenden' }
  maddbool(3,12,getres2(252,17),SaveUVS);mhnr(248);      { 'unversandte Nachrichten nach /�Unversandt' }
  maddbool(3,13,getres2(252,18),EmpfBest);               { 'autom. Empfangsbest�tigungen versenden' }
  maddbool(3,14,getres2(252,19),AutoArchiv);             { 'automatische PM-Archivierung' }
  maddbool(3,15,getres2(252,26),DefaultNokop);           { 'ZCONNECT: NOKOP' }
  maddbool(3,16,getres2(252,28),askreplyto);             { 'fragen bei Antwort-an' }
  maddint (3,18,getres2(252,24),maxcrosspost,mtByte,2,3,99); { 'Crosspostings mit �ber ' }
  maddtext(9+length(getres2(252,24)),17,getres2(252,25),0);  { 'Empf�ngern l�schen' }
  maddbool(3,19,getres2(252,27),maildelxpost);           { 'bei Mail ebenso' }
  scs:=scss[allowcancel];
  maddstring(3,21,getres2(252,29),scs,18,18,''); { 'Supersedes/Cancel verarbeiten' }
  for i:=0 to 4 do
    mappsel(true,scss[i]);
    { 'immer�nicht halten�nicht Wdvlg.�nicht (h. od. Wv.)�nie' }
  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    xnr:=0;
    for i:=0 to 3 do
      if lstr(xid)=lstr(xids[i]) then xnr:=i;
    XP_ID_PMs:=(xnr=1) or (xnr=3) or not registriert.r2;
    XP_ID_AMs:=(xnr=2) or (xnr=3){ or not registriert.r2};
    for i:=0 to 4 do
      if lstr(scs)=lstr(scss[i]) then allowcancel:=i;
    if (timezone='AUTO') and not getTZ(tz) then hinweis(getres(226));
    GlobalModified;
    end;
  enddialog;
  menurestart:=brk;
end;


function testpostanschrift(var s:string):boolean;
var i : integer;
begin
  for i:=1 to length(s) do
    if s[i]=',' then s[i]:=';';
  testpostanschrift:=true;
end;

function testurl(var s:string):boolean;
begin
  if (s<>'') and (lstr(left(s,7))<>'http://') then begin
    rfehler(220);    { 'Geben Sie die vollst�ndige URL (http://do.main/...) an!' }
    testurl:=false;
    end
  else
    testurl:=true;
end;

procedure adroptions;
var x,y : byte;
    brk : boolean;
begin
  dialog(ival(getres2(252,100)),8,getres2(252,101),x,y);  { 'Adre�einstellungen (ZCONNECT / RFC)' }
  maddstring(3,2,getres2(252,102),orga^,47,OrgLen,'');    { 'Organisation  ' }
    mhnr(1040);
  maddstring(3,3,getres2(252,103),postadresse^,47,PostadrLen,'');   { 'Postanschrift ' }
  msetvfunc(TestPostanschrift);
  maddstring(3,4,getres2(252,104),telefonnr^,47,TeleLen,'>VFBQP +-0123456789');
  msetvfunc(TestTelefon);                                 { 'Telefon       ' }
  maddstring(3,5,getres2(252,105),wwwHomepage^,47,Homepagelen,range(' ','~'));
  msetvfunc(TestUrl);
  maddbool(3,7,getres2(252,109),adrpmonly);   { 'Adresse, Telefon und Homepage nur in PMs' }
  freeres;
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;


function smalladr(var s:string):boolean;
var x,y : byte;
    t   : taste;
    ok  : boolean;
begin
  if (s=_jn_[2]) or small then smalladr:=true
  else begin
    msgbox(69,7,getres2(253,5),x,y);    { 'ACHTUNG!' }
    mwrt(x+3,y+2,getres2(253,6));   { 'Im Z-Netz sind z.Zt. keine kleingeschriebenen Adressen erlaubt!' }
    mwrt(x+3,y+3,getres2(253,7));   { 'M�chten Sie diese Option wirklich einschalten?' }
    t:='';
    errsound; errsound;
    ok:=(readbutton(x+3,y+5,2,getres2(253,8),2,true,t)=1);  { '  ^Ja  , ^Nein ' }
    if ok then small:=true
    else s:=_jn_[2];
    smalladr:=ok;
    freeres;
    closebox;
    end;
end;

function testhayes(var s:string):boolean;
var x,y : byte;
    t   : taste;
    ok  : boolean;
begin
  if (s=_jn_[1]) or not hayes then testhayes:=true
  else begin
    msgbox(71,10,getres2(254,8),x,y);    { 'ACHTUNG!' }
    mwrt(x+3,y+2,getres2(254,9));   { 'Diese Option d�rfen Sie nur dann ausschalten, wenn Sie kein Modem' }
    mwrt(x+3,y+3,getres2(254,10));  { 'verwenden und die Verbindung auf andere Weise (z.B.Handwahl) her-' }
    mwrt(x+3,y+4,getres2(254,11));  { 'gestellt wird.' }
    mwrt(x+3,y+6,getres2(254,12));  { 'Hayes-Befehle wirklich abschalten?' }
    t:='';
    errsound; errsound;
    ok:=(readbutton(x+3,y+8,2,getres2(254,13),2,true,t)=1);  { '  ^Ja  , ^Nein ' }
    if ok then hayes:=false
    else s:=_jn_[1];
    testhayes:=ok;
    freeres;
    closebox;
    end;
end;

procedure netcalloptions;
var x,y : byte;
    brk : boolean;
begin
  dialog(59,10,getres2(254,1),x,y);     { 'Netcall-Optionen' }
  maddbool(3,2,getres2(254,2),ShowLogin); mhnr(560);   { 'Login-Bild zeigen' }
  maddbool(3,3,getres2(254,3),BreakLogin);   { 'Login-Bild abbrechen' }
  hayes:=hayescomm;
  maddbool(34,2,getres2(254,4),hayescomm);   { 'Hayes-Befehle' }
  msetvfunc(testhayes);
  { maddbool(34,3,getres2(254,5),RenCALLED);   { 'CALLED umbenennen' }
  maddbool(3,5,getres2(254,6),nDelPuffer);   { 'Nachrichtenpakete nach Einlesen l�schen' }
    mhnr(564);
  maddbool(3,6,getres2(254,7),grosswandeln);    { 'Z-Netz-Adressen in Gro�schreibung umwandeln' }
  maddbool(3,7,getres2(254,14),netcalllogfile); { 'vollst�ndiges Netcall-Logfile (NETCALL.LOG)' }
  maddbool(3,9,getres2(254,15),netcallunmark);  { 'Nachrichtenmarkierungen nach Netcall aufheben' }
  {maddbool(3,10,getres2(254,16),AutoDatumsBezuege);  { 'Datumsbez�ge nach Netcall anpassen' }
  freeres;       { AutoDatumsBezuege wird nicht mehr ben�tigt! }
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;

function testexist(var s:string):boolean;
var s2 : string;
begin
  s2:=trim(s);
  if left(s2,1)='*' then delfirst(s2);
  if cpos(' ',s2)>0 then s2:=copy(s2,1,cpos(' ',s)-1);
  if (s2='') or (FSearch(s2,GetEnv('PATH'))<>'') then
    testexist:=true
  else begin
    rfehler(206);   { 'Programm nicht erreichbar (Extension nicht vergessen!)' }
    testexist:=false;
    end;
end;

procedure listoptions;
var brk : boolean;
    x,y : byte;
begin
  dialog(ival(getres2(255,0)),18,getres2(255,1),x,y);    { 'Lister' }
  maddbool(3,2,getres2(255,4),listvollbild);   { 'interner Lister - Vollbild' }
    mhnr(232);
  maddbool(3,3,getres2(255,14),listuhr);        { 'interner Lister - Uhr bei Vollbild' }
    mhnr(8062);
  maddbool(3,4,getres2(255,5),listwrap);       { 'Wortumbruch in Spalte 80' }
    mhnr(233);
  maddbool(3,5,getres2(255,6),KomArrows);      { 'Kommentarpfeile anzeigen' }
  maddbool(3,6,getres2(255,7),ListFixedHead);  { 'feststehender Nachrichtenkopf' }
  maddbool(3,8,getres2(255,8),ConvISO);        { 'ISO-Umlaute konvertieren' }
  maddbool(3,9,getres2(255,9),ListHighlight);  { 'farbliche *Hervorhebungen*' }
  maddbool(3,10,getres2(255,12),QuoteColors);   { 'verschiedenfarbige Quoteebenen' }
    mhnr(8060);
  maddbool(3,12,getres2(255,10),ListScroller); { 'Rollbalken bei Mausbedienung' }
    mhnr(238);
  maddbool(3,13,getres2(255,11),ListAutoScroll);  { 'automatisches Rollen am Bildrand' }
  { 22.01.2000 robo }
  maddbool(3,15,getres2(255,13),ListEndCR);    { 'Lister mit <Return> verlassen' }
    mhnr(8061);
  { /robo }
  maddstring(3,17,getres2(255,15),DefaultSavefile,12,80,'');  { 'Default-Filename Speichern' }
    mhnr(8068);

  freeres;
  readmask(brk);
  if not brk and mmodified then
    ListWrapBack:=ListWrap;
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;


procedure Xlistoptions;
var brk : boolean;
    x,y : byte;
begin
  dialog(ival(getres2(255,20)),3,getres2(255,21),x,y);    { 'externer Lister' }
  maddstring(3,2,getres2(255,22),VarLister,21,40,''); mhnr(230);   { 'Lister ' }
  msetvfunc(testexist);
  maddint(37,2,getres2(255,23),ListerKB,5,3,50,500);   { 'KByte:' }
  freeres;
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;



procedure editoptions;
var brk   : boolean;
    x,y,i : byte;
    eds   : string[20];
    edtype: array[1..3] of string[17];
begin
  for i:=1 to 3 do
    edtype[i]:=getres2(256,i);  { 'gro�e Nachrichten','alle Nachrichten','alle Texte' }
  dialog(ival(getres2(256,0)),11,getres2(256,5),x,y);   { 'Editor' }
  maddstring(3,2,getres2(256,6),VarEditor,28,40,''); mhnr(300);  { 'Editor ' }
  msetvfunc(testexist);
  maddint(43,2,getres2(256,7),EditorKB,5,3,50,500);   { 'KByte:' }
  maddstring(3,4,getres2(256,8),BAKext,3,3,'>');      { 'Backup-Dateierweiterung  ' }
  eds:=edtype[exteditor];
  maddstring(3,6,getres2(256,9),eds,18,18,'');    { 'externen Editor verwenden f�r ' }
  for i:=1 to 3 do
    mappsel(true,edtype[i]);
  maddbool(3,8,getres2(256,10),autocpgd);      { 'automatisches <Ctrl PgDn>' }
{ maddbool(3,9,getres2(256,11),editvollbild);  { 'interner Editor - Vollbild' }
  maddbool(3,9,getres2(256,12),keepedname); mhnr(306);  { 'Edit/Text-Name beibehalten' }
  maddbool(3,10,getres2(256,13),edit25);       { '25 Bildzeilen bei ext. Editor' }
  freeres;
  readmask(brk);
  if not brk then
    for i:=1 to 3 do
      if ustr(eds)=ustr(edtype[i]) then
        exteditor:=i;
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;


function testenv(var s:string):boolean;
begin
  if (ival(s)>0) and (ival(s)<128) then begin
    rfehler(207);     { 'ung�ltige Eingabe - siehe Online-Hilfe' }
    testenv:=false;
    end
  else
    testenv:=true;
end;

procedure shelloptions;
var brk : boolean;
    x,y : byte;
begin
  dialog(ival(getres2(257,0)),8,getres2(257,1),x,y);    { 'Shell' }
  maddbool(3,2,getres2(257,2),shell25); mhnr(310);   { '25 Bildzeilen bei DOS-Shell' }
  maddint(3,4,getres2(257,3),envspace,4,4,0,9999);   { 'Environment-Gr��e:  ' }
  maddtext(length(getres2(257,3))+11,4,getres(13),0);   { 'Bytes' }
  maddbool(3,6,getres2(257,4),ShellShowpar);    { 'Parameterzeile anzeigen' }
  maddbool(3,7,getres2(257,5),ShellWaitkey);    { 'auf Tastendruck warten' }
  msetvfunc(testenv);
  freeres;
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;


{ Brettanzeige }

procedure brett_config;
var x,y   : byte;
    brk   : boolean;
    i     : integer;
    brett : string[11];
    tks   : string[10];

  function btyp(n:byte):string;
  begin
    btyp:=getres2(258,n+1);  { 'normal' / 'spezial' / 'klein' }
  end;

  function tk(n:byte):string;
  begin
    tk:=getres2(258,20+n);
  end;

begin
  dialog(ival(getres2(258,0)),8,getres2(258,5),x,y);   { 'Brettanzeige' }
  maddbool(3,2,getres2(258,6),UserSlash); mhnr(270);   { '"/" bei PM-Brettern' }
  maddbool(3,3,getres2(258,7),trennall);   { 'Trennzeilen bei "Alle"' }
  maddbool(3,4,getres2(258,9),NewsgroupDisp); mhnr(273);
  brett:=btyp(brettanzeige);
  maddstring(3,6,getres2(258,8),brett,7,7,'<'); mhnr(272);   { 'Brettanzeige ' }
  for i:=0 to 2 do mappsel(true,btyp(i));
  tks:=tk(trennkomm);
  maddstring(3,7,getres2(258,10),tks,7,10,''); mhnr(274);  { 'Trennzeilenkommentar' }
  for i:=1 to 3 do mappsel(true,tk(i));
  readmask(brk);
  if not brk and mmodified then begin
    for i:=0 to 2 do
      if lstr(brett)=lstr(btyp(i)) then brettanzeige:=i;
    for i:=1 to 3 do
      if stricmp(tks,tk(i)) then trennkomm:=i;
    aufbau:=true;
    GlobalModified;
    end;
  freeres;
  enddialog;
  menurestart:=brk;
end;


{ Nachrichtenanzeige }

procedure NachrichtenanzeigeCfg;
var x,y   : byte;
    brk   : boolean;
    i     : integer;
    sabs  : string[12];

  function abstyp(n:byte):string;
  begin                        { 'normal' / 'klein' / 'klein/Space'    }
    abstyp:=getres2(259,n);    { 'nur Name' / 'Name/klein' / 'Spalten' }
  end;                         { 'Splt./klein'                         }

begin
  dialog(65,11,getres2(259,10),x,y);   { 'Nachrichtenanzeige' }
  maddbool(3,2,getres2(259,11),ShowMsgDatum); mhnr(840);   { 'Nachrichten-Datum' }
  sabs:=abstyp(sabsender);
  maddstring(35,2,getres2(259,12),sabs,11,11,'');    { 'Absendernamen ' }
  for i:=0 to 6 do mappsel(true,abstyp(i));
  maddbool(3,4,getres2(259,13),BaumAdresse);     { 'vollst�ndige Adressen im Kommentarbaum' }
  maddbool(3,5,getres2(259,14),showrealnames);   { 'Realname anzeigen, falls vorhanden' }
  maddbool(3,6,getres2(259,15),showfidoempf);    { 'Empf�nger von Fido-Brettnachrichten anzeigen' }

  maddbool(3,8,getres2(259,16),hidere);        { 'Re: und AW: ausblenden' }
  maddbool(3,9,getres2(259,17),hidemlhead);    { 'Mailinglisten-Kopf ausblenden' }
  maddbool(3,10,getres2(259,18),longbetr);     { 'Betreff verl�ngern' }

{ maddstring(3,8,getres2(259,16),unescape,49,100,'>'); } { 'UnEscape ' }

  readmask(brk);
  if not brk and mmodified then begin
    for i:=0 to 6 do
      if lstr(sabs)=lstr(abstyp(i)) then sabsender:=i;
    KomShowadr:=BaumAdresse;
    aufbau:=true;
    GlobalModified;
    end;
  freeres;
  enddialog;
  menurestart:=brk;
end;


{ diverse Anzeige-Einstellungen }

function scstest(var s:string):boolean;
begin
  scstest:=(ival(s)=0) or (ival(s)>=5);
end;

function dpmstest(var s:string):boolean;
begin
  if (s=_jn_[2]) or SetVesaDpms(DPMS_On) then
    dpmstest:=true
  else begin
    rfehler(219);     { 'Ihre Grafikkarte unterst�tzt kein VESA-DPMS.' }
    dpmstest:=false;
    end;
end;

procedure MiscAnzeigeCfg;
var i,x,y    : byte;
    brk,du : boolean;
begin
  dialog(36,13,'',x,y);
  maddint(3,2,getres2(260,1),scrsaver,5,5,0,10000); mhnr(280);   { 'Screen-Saver (Sek.)  ' }
    msetvfunc(scstest);
  maddbool(3,4,getres2(260,2),softsaver);     { 'weich ausblenden' }
  maddbool(3,5,getres2(260,6),blacksaver);    { 'schwarzschalten' }
  maddbool(3,6,getres2(260,9),vesa_dpms);     { 'Stromsparmodus' }
    mset1func(dpmstest);
  maddbool(3,7,getres2(260,3),ss_passwort);   { 'Startpa�wort abfragen' }
  du:=dispusername;
  maddbool(3,9,getres2(260,4),dispusername);  { 'Username anzeigen' }

  maddstring(3,11,getres2(260,13),mheadercustom[1],19,19,''); { 'userdef. Kopfzeile 1' }
  maddstring(3,12,getres2(260,14),mheadercustom[2],19,19,''); { 'userdef. Kopfzeile 2' }

  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    scsavetime:=scrsaver;
    if dispusername<>du then showusername;

    for i:=1 to 2 do
      if mheadercustom[i][length(mheadercustom[i])]=':' then
        delete(mheadercustom[i],length(mheadercustom[i]),1);

    GlobalModified;
  end;
  enddialog;
  menurestart:=brk;
end;


{ Unterst�tzung f�r seh-/h�rbehinderte Anwender }

procedure AccessibilityOptions;
var x,y,i,j : byte;
    brk : boolean;
begin
  dialog(41,11,getres2(260,11),x,y);
  maddbool(3,2,getres2(260,5),auswahlcursor);{ 'Auswahlcursor in Men�s/Listen' }
    mhnr(1030);
  maddbool(3,3,getres2(260,8),blind);        { 'Fensterhintergrund ausblenden' }
  { 'Feldtausch in Nachrichten-Liste': }
  maddstring(3,5,getres2(260,15),MsgFeldTausch,MsgFelderMax,MsgFelderMax,
             MsgFeldDef+LStr(MsgFeldDef));
  { 'Feldtausch in Userliste': }
  maddstring(3,6,getres2(260,16),UsrFeldTausch,UsrFelderMax+1,UsrFelderMax,
             UsrFeldDef+LStr(UsrFeldDef));
  maddbool(3,8,getres2(260,10),termbios);    { 'BIOS-Ausgabe im Terminal' }
  maddbool(3,9,getres2(260,12),tonsignal);   { 'zus�tzliches Tonsignal' }
  maddbool(3,10,getres2(260,7),soundflash);   { 'optisches Tonsignal' }
  readmask(brk);
  if not brk and mmodified then begin
    if auswahlcursor then begin
      MaskSelcursor(curon);
      SetListCursor(curon);
      SetWinSelCursor(curon);
      EdSelcursor:=true;
    end else begin
      MaskSelcursor(curoff);
      SetListCursor(curoff);
      SetWinSelCursor(curoff);
      EdSelcursor:=false;
    end;
    aufbau:=true;
    GlobalModified;
    { Alle Buchstaben f�r den MsgFeldTausch vorhanden? }
    j:=0;
    { (F)lags m�ssen immer vorne stehen }
    i:=pos('F',MsgFeldTausch); if (i>1) then begin
      delete(MsgFeldTausch,i,1); MsgFeldTausch:='F'+MsgFeldTausch;
    end;
    for i := 1 to length(MsgFeldDef) do
      if (pos(copy(MsgFeldDef,i,1),MsgFeldTausch)>0) then inc(j);
    if (j<>MsgFelderMax) then MsgFeldTausch:=MsgFeldDef;
    { Alle Buchstaben f�r den UsrFeldTausch vorhanden? }
    j:=0;
    { (F)lags m�ssen immer vorne stehen }
    i:=pos('F',UsrFeldTausch); if (i>1) then begin
      delete(UsrFeldTausch,i,1); UsrFeldTausch:='F'+UsrFeldTausch;
    end;
    for i := 1 to length(UsrFeldDef) do
     if (pos(copy(UsrFeldDef,i,1),UsrFeldTausch)>0) then inc(j);
    if (j<>UsrFelderMax) then UsrFeldTausch:=UsrFeldDef;
  end;
  freeres;
  enddialog;
  menurestart:=brk;
end;


function testfossil(var s:string):boolean;
var p : scrptr;
    b : boolean;
begin
  if (oldfossil=_jn_[2]) and (s=_jn_[1]) then begin
    sichern(p);            { wegen BNU }
    b:=FOSSILdetect;
    holen(p);
    if not b then fehler(getres2(261,14));
    end
  else
    b:=true;
  testfossil:=b;
  b:=(s=_jn_[2]) or ((s=_jn_[1]) and not b);
  SetFieldEnable(2,b);
  SetFieldEnable(3,b);
  SetFieldEnable(10,b);
  SetFieldEnable(12,b);
  SetFieldEnable(13,b and (getfield(12)=_jn_[1]));
end;

function testfifo(var s:string):boolean;
begin
  ua[1]:=hexval(getfield(2));
  if (s=_jn_[2]) or (ComType(1)=Uart16550A) then
    testfifo:=true
  else begin
    errsound;
    testfifo:=ReadJn(getres2(261,12),false);   { 'Sicher? XP hat keinen 16550A erkannt!' }
    end;
end;

{ Prozedurvariable, s wird nicht ben�tigt }
function SetTrigger(var s:string):boolean;
begin
  SetFieldEnable(13,(getfield(1)=_jn_[2]) and (s=_jn_[1]));
end;

procedure ModemConfig(nr:byte);
var brk  : boolean;
    x,y  : byte;
    pstr : string[4];
    mi,me: string[200];
    md   : string[100];
begin
  with COMn[nr] do begin
    dialog(ival(getres2(261,0)),15,getreps2(261,1,strs(nr)),x,y);    { 'Konfiguration von COM%s' }
    if Cport<$1000 then
      pstr:=lstr(hex(Cport,3))
    else
      pstr:=lstr(hex(Cport,4));
    mi:=minit^; me:=mexit^; md:=mdial^;
    if not fossildetect then fossil:=false;
    maddbool  (3,2,getres2(261,13),fossil); mhnr(960);  { 'FOSSIL-Treiber verwenden' }
    oldfossil:=iifc(fossil,_jn_[1],_jn_[2]);
    mset1func(testfossil);
    maddstring(3,4,getres2(261,2),pstr,4,4,hexchar); mhnr(290);   { 'Port-Adresse (Hex) ' }
    mappsel(false,'3f8�2f8�3e8�2e8');
    if fossil then MDisable;
    maddint  (33,4,getres2(261,3),Cirq,3,2,0,15);    { 'IRQ-Nummer ' }
    if fossil then MDisable;
    maddstring(3,6,getres2(261,4),mi,32,200,'');     { 'Modem-Init ' }
    mappsel(false,'ATZ�AT&F�ATZ\\ATX3�ATZ\\AT S0=0 Q0 E1 M1 V1 X4 &C1');
    {Weitere Optionen eingefuegt MW 04/2000}
    maddstring(3,7,getres2(261,5),me,32,200,'');     { 'Modem-Exit ' }
    maddstring(3,8,getres2(261,15),md,32,100,'');    { 'W�hlbefehl ' }
    mappsel(false,'ATDT�ATDP�ATDT0W�ATDP0W');
    {Weitere Dialstrings eingefuegt (Telefonanlagen) MW 04/2000}
    maddbool (3,10,getres2(261,16),postsperre); { 'postkompatible W�hlpause' }
    maddbool (3,12,getres2(261,8),IgCD);             { 'CD ignorieren' }
    maddbool (3,13,getres2(261,9),IgCTS);            { 'CTS ignorieren' }
    maddbool (3,14,getres2(261,17),UseRTS);          { 'RTS verwenden'  }
    if fossil then mdisable;
    maddbool(28,12,getres2(261,10),Ring);            { 'RING-Erkennung' }
    maddbool(28,13,getres2(261,11),u16550);          { '16550A-FIFO'    }
      mhnr(961);
    mset1func(SetTrigger);
    msetvfunc(TestFifo);
    if fossil then mdisable;
    maddint (28,14,getres2(261,18),tlevel,3,2,2,14); { 'FIFO-Triggerlevel' }
    mappsel(true,'2�4�8�14');
    if fossil or not u16550 then MDisable;
    freeres;
    readmask(brk);
    if not brk and mmodified then begin
      Cport:=hexval(pstr);
      { if fossil then IgCTS := not foscts; ??? }
      freemem(MInit,length(MInit^)+1);
      getmem(MInit,length(mi)+1);
      MInit^:=mi;
      freemem(MExit,length(MExit^)+1);
      getmem(MExit,length(me)+1);
      MExit^:=me;
      freemem(MDial,length(MDial^)+1);
      getmem(MDial,length(md)+1);
      MDial^:=md;
      GlobalModified;
      end;
    enddialog;
    end;
  menurestart:=brk;
end;

{$IFDEF CAPI }
procedure TestCapiInt(var s:string);
begin
  CAPI_setint(hexval(s));
  attrtxt(col.coldialog);
  if not CAPI_installed then begin
    mwrt(isdnx+9,isdny+3,forms(getres2(269,10),40));  { 'nicht vorhanden' }
    mwrt(isdnx+9,isdny+4,sp(40));
    mwrt(isdnx+9,isdny+5,sp(40));
    end
  else begin
    mwrt(isdnx+9,isdny+3,forms(CAPI_Manufacturer,40));
    mwrt(isdnx+9,isdny+4,forms(CAPI_Version,40));
    mwrt(isdnx+9,isdny+5,forms(CAPI_Serial,40));
    end;
end;

procedure IsdnConfig;
var brk  : boolean;
    pstr : string[3];
    ints : string[2];
    eaz  : string[1];
begin
  dialog(50,6,getres2(269,1),isdnx,isdny);  { 'ISDN/CAPI-Konfiguration (1TR6/X.75)' }
  attrtxt(col.coldiarahmen);
  ints:=lstr(hex(ISDN_Int,2));
  maddstring(3,2,getres2(269,2),ints,2,2,'<0124567899abcdef');  { 'CAPI-Interrupt ' }
  mhnr(910);
  mset0proc(TestCapiInt); mset3proc(testcapiint);
  eaz:=ISDN_eaz;
  maddstring(30,2,getres2(269,3),eaz,1,1,'0123456789');  { 'EAZ ' }
  maddtext(3,4,'CAPI',col.coldiahigh);
  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    ISDN_Int:=hexval(ints);
    ISDN_EAZ:=eaz[1];
    GlobalModified;
    end;
  enddialog;
end;
{$ENDIF CAPI }

function formpath(var s:string):boolean;
var
    res : integer;
    s1  : string;
    p   : byte;
begin
  s:=ustr(FExpand(s));
  if (s<>'') and (right(s,1)<>'\') then s:=s+'\';
  p:=pos('\',s);
  s1:=copy(s,p+1,length(s)-p);
  while not (p=0) do begin
    if pos('\',s1)>9 then begin
      rfehler(221); { 'Mehr als acht Zeichen sind f�r Verzeichnisse nicht zul�ssig!' }
      formpath:=false;
      exit;
    end;
    p:=pos('\',s1);
    s1:=copy(s1,p+1,length(s1)-p);
  end;
  if not validfilename(s+'1$2$3.xxx') then
    if ReadJN(getres2(262,1),true) then   { 'Verzeichnis ist nicht vorhanden. Neu anlegen' }
    begin
      mklongdir(s,res);
      if res<0 then begin
        rfehler(208);      { 'Verzeichnis kann nicht angelegt werden!' }
        formpath:=false;
        end
      else
        formpath:=true
      end
    else
      formpath:=false
  else
    formpath:=true;
end;


procedure path_config;
var brk : boolean;
    x,y : byte;

  procedure freepath(var pp:pathptr);
  begin
    if assigned(pp) then begin
      freemem(pp,length(pp^)+1);
      pp:=nil;
      end;
  end;

begin
  delete_tempfiles;
  dialog(ival(getres2(262,0)),11,'',x,y);
  maddstring(3,2,getres2(262,2),temppath,31,79,''); mhnr(260);   { 'Tempor�r-Verzeichnis ' }
  if Assigned(EditTemppath) then
    setfield(fieldpos,EditTemppath^);
  msetVfunc(formpath);
  maddstring(3,4,getres2(262,3),extractpath,31,79,'');   { 'Extrakt-Verzeichnis  ' }
  if Assigned(EditExtpath) then
    setfield(fieldpos,EditExtpath^);
  msetVfunc(formpath);
  maddstring(3,6,getres2(262,4),sendpath,31,79,'');   { 'Sende-Verzeichnis    ' }
  if Assigned(EditSendpath) then
    setfield(fieldpos,EditSendpath^);
  msetVfunc(formpath);
  maddstring(3,8,getres2(262,5),logpath,31,79,'');    { 'Logfile-Verzeichnis  ' }
  if Assigned(EditLogpath) then
    setfield(fieldpos,EditLogpath^);
  msetVfunc(formpath);
  maddstring(3,10,getres2(262,6),filepath,31,79,'');  { 'FileReq-Verzeichnis  ' }
  msetVfunc(formpath);
  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    GlobalModified;
    freepath(EditTemppath);
    freepath(EditExtpath);
    freepath(EditSendpath);
    freepath(EditLogpath);
    end;
  enddialog;
  menurestart:=brk;
end;


var fy : byte;

function testarc(var s:string):boolean;
begin
  if (pos('$ARCHIV',ustr(s))=0) or (pos('$DATEI',ustr(s))=0) then begin
    rfehler(209);    { 'Die Packer-Angabe mu� $ARCHIV und $DATEI enthalten!' }
    testarc:=false;
    end
  else begin
    attrtxt(col.coldialog);
    wrt(64,fy+fieldpos*2-1,iifc(FileDa(s),#251,' '));
    testarc:=true;
    end;
end;

procedure DispArcs;
  procedure ww(y:byte; var p:string);
  begin
    wrt(64,fy+y,iifc(FileDa(p),#251,' '));
  end;
begin
  attrtxt(col.coldialog);
  with unpacker^ do begin
    ww(1,UnARC); ww(3,UnARJ); ww(5,UnLZH);
    ww(7,UnPAK); ww(9,UnRAR); ww(11,UnSQZ);
    ww(13,UnZIP); ww(15,UnZOO);
    end;
end;

procedure ArcOptions;
var x,y : byte;
    brk : boolean;
begin
  dialog(53,17,getres(263),x,y); fy:=y;   { 'Archiv-Entpacker f�r...' }
  with unpacker^ do begin
    maddstring(3,2,'ARC ',UnARC,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'pkxarc $ARCHIV $DATEI�pkunpak -e $ARCHIV $DATEI�arc e $ARCHIV $DATEI�arce $ARCHIV $DATEI');
    maddstring(3,4,'ARJ ',UnARJ,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'arj e $ARCHIV $DATEI');
    maddstring(3,6,'LZH ',UnLZH,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'lharc e $ARCHIV $DATEI�lha e $ARCHIV $DATEI');
    maddstring(3,8,'PAK ',UnPAK,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'pak e $ARCHIV $DATEI');
    maddstring(3,10,'RAR ',UnRAR,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'rar -std e $ARCHIV $DATEI');
    maddstring(3,12,'SQZ ',UnSQZ,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'sqz e $ARCHIV $DATEI');
    maddstring(3,14,'ZIP ',UnZIP,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'pkunzip $ARCHIV $DATEI�unzip $ARCHIV $DATEI');
    maddstring(3,16,'ZOO ',UnZOO,38,50,'');
      msetvfunc(testarc);
      mappsel(false,'zoo -e $ARCHIV $DATEI');
    end;
  MsetUserDisp(DispArcs);
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;


procedure DruckConfig;
const
{  lpts : array[1..5] of string[4] = ('LPT1','LPT2','LPT3','COM1','COM2');  }
  { MK 01/00 Das drucken auf COM-Ports wird im Moment nicht unterst�tzt }
  lpts : array[1..3] of string[4] = ('LPT1','LPT2','LPT3');
var x,y : byte;
    brk : boolean;
    lpt : string[4];
    i   : integer;
    allc: string;
begin
  dialog(ival(getres2(264,0)),11,getres2(264,1),x,y);   { 'Drucker-Optionen' }
  lpt:=lpts[DruckLPT];
  maddstring(3,2,getres2(264,2),lpt,4,4,'>'); mhnr(470);  { 'Schnittstelle ' }
  for i:=1 to high(lpts) do
    mappsel(true,lpts[i]);
  allc:=range(' ',#255);
  maddint(31,2,getres2(264,3),DruckFormLen,3,3,0,255);    { 'Seitenl�nge  ' }
  maddstring(3,4,getres2(264,4),DruckInit,30,80,allc);    { 'Drucker-Init  ' }
  maddstring(3,6,getres2(264,5),DruckExit,30,80,allc);    { 'Drucker-Exit  ' }
  maddstring(3,8,getres2(264,6),DruckFF,30,80,allc);      { 'Seitenvorschub' }
  maddint(3,10,getres2(264,7),Drucklira,3,2,0,50);        { 'linker Rand:  ' }
  maddtext(length(getres2(264,7))+10,10,getres2(264,8),col.coldialog);  { 'Zeichen' }
  readmask(brk);
  if not brk and mmodified then
  begin
    { MK 01/00 COM-Drucker wurden nicht selektiert }
    for i := 1 to high(lpts) do
      if lpt = lpts[i] then DruckLPT := i;
{    DruckLPT:=ival(lpt[4]); }
{$IFDEF BP }
    { !! Hier kracht es in der 32 Bit Version,
      das muss genauer untersucht werden }
    close(lst);
    assignlst(lst,DruckLPT-1);
    rewrite(lst);
{$ENDIF }
    GlobalModified;
  end;
  freeres;
  enddialog;
  menurestart:=brk;
end;


procedure pmcOptions;
var x,y  : byte;
    brk  : boolean;
    i    : integer;
    pchr : string;
begin
  dialog(77,3+2*maxpmc,getres2(265,1),x,y);   { 'externe Codierprogramme' }
  maddtext(10,2,getres2(265,2),0);   { 'Name          Codierer               Decodierer' }
  pchr:=without(allchar,'~');
  for i:=1 to maxpmc do
    with pmcrypt[i] do begin
      maddtext(3,(i+1)*2,'pmc-'+strs(i),0);
      maddstring(10,(i+1)*2,'',name,11,15,pchr);  { Name auf keinen Fall >15! }
      maddstring(24,(i+1)*2,'',encode,20,40,pchr);
      maddstring(47,(i+1)*2,'',decode,20,40,pchr);
      maddbool  (71,(i+1)*2,'',binary);
      end;
  freeres;
  pushhp(490);
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  pophp;
  enddialog;
  menurestart:=brk;
end;

procedure ViewerOptions;
var x,y : byte;
    brk : boolean;
    i   : integer;
begin
  dialog(58,2*maxviewers+1,getres(266),x,y);   { 'Anzeige-Programme f�r ...' }
  maddstring(3,2,'GIF       ',viewers^[1].prog,40,40,''); mhnr(820);
  mappsel(false,'VPIC.EXE $FILE�PICEM.EXE $FILE');
  maddstring(3,4,'IFF/ILMB  ',viewers^[2].prog,40,40,'');
  mappsel(false,'VPIC.EXE $FILE');
  maddstring(3,6,'PCX       ',viewers^[3].prog,40,40,'');
  mappsel(false,'VPIC.EXE $FILE�PICEM.EXE $FILE');
  for i:=defviewers+1 to maxviewers do begin
    maddstring(3,i*2,'',viewers^[i].ext,3,3,'>'+range('A','Z')+'_-$!~0123456789');
    mhnr(820);
    maddstring(14,i*2,'',viewers^[i].prog,40,40,''); mhnr(820);
    end;
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;


procedure setvorwahl(var s:string);
begin
  if cpos('-',s)=0 then s:='49-'+s;
end;

procedure FidoOptions;
var x,y : byte;
    brk : boolean;
    via : boolean;
begin
  dialog(ival(getres2(267,0)),14,getres2(267,1),x,y);   { 'Fido-Optionen' }
  maddstring(3,2,getres2(267,2),IntVorwahl,8,15,'0123456789-,@');   { 'internat. Vorwahl ' }
    mhnr(720);
  maddstring(3,3,getres2(267,3),NatVorwahl,8,10,'0123456789-,@');   { 'Ortsvorwahl       ' }
  maddstring(3,4,getres2(267,4),Vorwahl,8,15,'0123456789-,@');      { 'eigene Vorwahl    ' }
  mset3proc(setvorwahl);
  maddbool(3,6,getres2(267,7),AutoDiff); mhnr(725);  { 'Diffs automatisch einbinden' }
  maddbool(3,7,getres2(267,10),FidoDelEmpty);  { 'leere Nachrichten l�schen' }
  maddbool(3,8,getres2(267,12),AutoTIC);       { 'TIC-Files automatisch auswerten' }
  maddbool(3,9,getres2(267,13),KeepRequests);  { 'unerledigte Requests zur�ckstellen' }
  via:=not keepvia;
  maddbool(3,11,getres2(267,15),via); mhnr(718);   { 'Via-Zeilen l�schen' }
  maddstring(3,13,getres2(267,9),BrettAlle,ival(getres2(267,8)),20,'');
  msetvfunc(notempty); mhnr(729);              { 'Standard-Brettempf�nger  ' }
  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    keepvia:=not via;
    fidoto:=brettalle;
    GlobalModified;
    end;
  enddialog;
  menurestart:=brk;
end;

procedure netoptions;
var x,y   : byte;
    brk   : boolean;
    add   : byte;
    oldmv : boolean;    { save MaggiVerkettung }
    knoten: boolean;
begin
  dialog(57,iif(deutsch,21,14),getres2(253,1),x,y);        { 'netzspezifische Optionen' }
  maddtext(3,2,getres2(253,2),col.coldiahigh);   { 'Z-Netz' }
  maddbool(14,2,getres2(253,10),zc_iso); mhnr(790);      { 'ZCONNECT: ISO-Zeichensatz' }
  small:=smallnames;
  maddbool(14,3,getres2(253,3),smallnames);              { 'Z-Netz alt: kleine Usernamen' }
  msetvfunc(smalladr); mhnr(792);
  if deutsch then begin
    maddtext(3,5,'Maus',col.coldiahigh);
    maddbool(14,5,'OUTFILE-Gr��e begrenzen',MaxMaus); mhnr(793);
    maddbool(14,6,'R�ckfrage f�r Nachrichtenstatus',MausLeseBest);
    maddbool(14,7,'Bearbeitungsstatus anfordern',MausPSA);
    maddbool(14,8,'Bin�rnachrichten als "Attachments"',mausmpbin);
      mhnr(8102);
    add:=5;
  end else
    add:=0;
  maddtext(3,5+add,'RFC',col.coldiahigh);
  maddbool(14,5+add,getres2(253,9),NewsMIME); mhnr(796);   { 'MIME in News' }
  maddbool(14,6+add,getres2(253,11),MIMEqp); { 'MIME: "quoted-printable" verwenden' }
  maddbool(14,7+add,getres2(253,12),RFC1522);  { 'MIME in Headerzeilen (RFC 1522)' }
  maddbool(14,8+add,getres2(253,15),multipartbin);  { 'Bin�rnachrichten als "Attachments"' }
  maddbool(14,9+add,getres2(253,16),NoArchive); mhnr(803); { 'Archivierung unterbinden' }
  maddint(14,10+add,getres2(253,18),PPP_AnzReq,4,3,1,199); mhnr(810); { 'Anz. Versuche zur Artikelanforderung' }
  oldmv:=MaggiVerkettung;
  if deutsch then begin
    maddtext(3,12+add,'MagicNET',col.coldiahigh);     { 'Bezugsverkettung' }
    knoten:=deutsch and (random<0.05);
    maddbool(14,12+add,iifs(knoten,'Kommentarverknotung',getres2(253,14)),
                       MaggiVerkettung); mhnr(iif(knoten,8101,8100));
    inc(add,2);
  end;
  maddtext(3,12+add,'Fido',col.coldiahigh);
  maddbool(14,12+add,getres2(253,17),Magics); { Magics im <F3>-Request }
  mhnr(8103);
  maddbool(14,13+add,getres2(253,19),XP_ID_Fido); { 'CrossPoint' in der Tearline }
  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    if MaggiVerkettung<>oldmv then
      BezugNeuaufbau;
    GlobalModified;
    end;
  enddialog;
  menurestart:=brk;
end;

procedure SizeOptions;
var x,y   : byte;
    brk   : boolean;
    anz,i : byte;
  function sname(nr:byte):string;
  begin
    case nr of
      1 : sname:='Z-Netz';
      2 : sname:='Fido';
      3 : sname:='UUCP/RFC';
      4 : sname:='PPP/RFC';
      5 : sname:='MausTausch';
      6 : sname:='MagicNET';
      7 : sname:='QM/GS';
    end;
  end;
begin
  anz:=iif(deutsch,maxpmlimits,4);
  dialog(38,anz+4,getres2(268,1),x,y);   { 'Gr��enlimits' }
  maddtext(18,2,getres2(268,2),0);       { 'Netz'         }
  maddtext(29,2,getres2(268,3),0);       { 'lokal'        }
  for i:=1 to anz do begin
    maddint(3,i+3,forms(sname(i),13),pmlimits[i,1],6,6,0,999999); mhnr(870);
    maddint(28,i+3,'',pmlimits[i,2],6,6,0,999999); mhnr(870);
    end;
  freeres;
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  menurestart:=brk;
end;

procedure NetEnable;
begin
  menurestart:=true;
end;

procedure GebuehrOptions;
var x,y : byte;
    brk : boolean;
    r   : real;
begin
  dialog(ival(getres2(1023,0)),6,getres2(1023,1),x,y);  { 'Telefonkosten-Einstellungen' }
  r:=GebNoconn/100;
(*  maddreal(3,2,getres2(1023,2),r,8,2,0,99999);   { 'Kosten f�r nicht zustandegekommene Verbindung        ' }
    mhnr(970); *)
  maddbool(3,2,getres2(1023,5),autofeier);  { 'deutsche Feiertage ber�cksichtigen' }
    mhnr(971);
  maddbool(3,3,getres2(1023,4),gebCfos);    { 'Geb�hren�bernahme von cFos' }
  maddstring(3,5,getres2(1023,3),waehrung,5,5,'');   { 'W�hrung' }
    mhnr(973);
  freeres;
  readmask(brk);
  if not brk and mmodified then begin
    GebNoconn:=system.round(r*100);
    GlobalModified;
    end;
  enddialog;
  menurestart:=brk;
end;

procedure TerminalOptions;
var x,y : byte;
    brk : boolean;
    com : string[6];
    d   : DB;
    fn  : string[8];
begin
  dialog(ival(getres2(270,0)),10,getres2(270,1),x,y);  { 'Terminal-Einstellungen' }
  if (TermCOM=0) or (TermBaud=0) then begin
    dbOpen(d,BoxenFile,1);
    dbSeek(d,boiName,ustr(DefaultBox));
    dbRead(d,'dateiname',fn);
    dbClose(d);
    ReadBox(0,fn,boxpar);
    if TermCom=0 then TermCom:=boxpar^.bport;
    if TermBaud=0 then TermBaud:=boxpar^.baud;
    end;
  com:='COM'+strs(minmax(TermCOM,1,5));
   if TermCom=5 then com:='ISDN';
  maddstring(3,2,getres2(270,2),com,6,6,'');  { 'Schnittstelle    ' }
    mhnr(990);
{$IFDEF CAPI }
  mappsel(true,'COM1�COM2�COM3�COM4�ISDN');      { aus: XP9.INC    }
{$ELSE }
  mappsel(true,'COM1�COM2�COM3�COM4');           { aus: XP9.INC    }
{$ENDIF }
  maddint(3,3,getres2(270,3),TermBaud,6,6,150,115200);  { '�bertragungsrate ' }
  mappsel(false,'300�1200�2400�4800�9600�19200�38400�57600�115200');
  maddtext(14+length(getres2(270,3)),3,getres2(270,4),0);   { 'bps' }
  maddstring(3,5,getres2(270,5),TermInit,16,40,'');     { 'Modem-Init       ' }
  maddbool(3,7,getres2(270,6),AutoDownload);  { 'automatisches Zmodem-Download' }
  maddbool(3,8,getres2(270,7),AutoUpload);    { 'automatisches Zmodem-Upload'   }
  maddbool(3,9,getres2(270,8),TermStatus);    { 'Statuszeile' }
  freeres;
  readmask(brk);
  if not brk and mmodified then
  begin
{$IFDEF CAPI }
    if com='ISDN' then
      TermCOM:=5 { MH: hinzugef�gt }
    else
{$ENDIF }
    TermCOM:=ival(right(com,1));
    GlobalModified;
  end;
  enddialog;
  menurestart:=brk;
end;

function testpgpexe(var s:string):boolean;
begin
  if (s=_jn_[1]) and (fsearch('PGP.EXE',getenv('PGPPATH'))='') and
                     (fsearch('PGP.EXE',getenv('PATH'))='') then begin
    rfehler(217);    { 'PGP ist nicht vorhanden oder nicht per Pfad erreichbar.' }
    s:=_jn_[2];
    end;
end;

function testxpgp(var s:string):boolean;
begin
  if (s=_jn_[1]) and (getfield(2)=_jn_[2]) then begin
    rfehler(218);    { 'Aktivieren Sie zuerst die ZCONNECT-PGP-Unterst�tzung! }
    s:=_jn_[2];
  end;
end;

function setpgpdialog(var s:string):boolean;
begin
  SetFieldEnable(GPGEncodingOptionsField,s=GPG1);
  setpgpdialog:=true
end;

procedure PGP_Options;
var x,y : byte;
    brk : boolean;
    sall: boolean;
begin
  sall:=(ustr(GetRes2(29900,2))<>'N');
  dialog(ival(getres2(271,0)),iif(sall,17,16),getres2(271,1),x,y);  { 'PGP-Einstellungen' }
  maddstring(3,2,'PGP-Version ',PGPVersion,10,10,'');
  mappsel(false,PGP2+'�'+PGP5+'�'+PGP6+'�'+GPG1);
    mhnr(1010);
  maddbool(3,4,getres2(271,2),UsePGP);         { 'ZCONNECT-PGP-Unterst�tzung' }
  { mset1func(testpgpexe); }
  maddbool(3,5,getres2(271,3),PGPbatchmode);   { 'PGP-R�ckfragen �bergehen' }
  maddbool(3,6,getres2(271,4),PGPpassmemo);   { 'Passphrase bis Programmende merken' }
  maddbool(3,7,getres2(271,5),PGP_WaitKey);    { 'Warten auf Tastendruck nach PGP-Aufruf' }
  maddbool(3,8,getres2(271,9),PGP_log);        { 'Logfile f�r automatische Aktionen' }
  maddbool(3,10,getres2(271,6),PGP_AutoPM);     { 'Keys aus PMs automatisch einlesen' }
  maddbool(3,11,getres2(271,7),PGP_AutoAM);    { 'Keys aus AMs automatisch einlesen' }
  maddbool(3,12,getres2(271,11),PGP_RFC{UUCP});{ 'PGP auch f�r RFC verwenden' }
  mhnr(1018);
  mset1func(testxpgp);
  if sall then begin
    maddbool(3,13,getres2(271,10),PGP_signall);  { 'alle Nachrichten signieren' }
    mhnr(1025);
  end;  
  maddstring(3,iif(sall,15,14),getres2(271,8),PGP_UserID,31,80,'');   { 'User-ID' }
  mhnr(1019);
  maddstring(3,iif(sall,16,15),getres2(271,13),PGP_GPGEncodingOptions,31,120,''); { 'GPG-Optionen' }
  mhnr(1024);
  mappsel(false,'--rfc1991 --cipher-algo idea�--compress-algo 1 --cipher-algo cast5');
  GPGEncodingOptionsField:= fieldpos;

(*
  maddbool(3,13,getres2(271,12),PGP_Fido);       { 'PGP auch f�r Fido verwenden' }
  maddbool(3,12,getres2(271,11),PGP_RFC{UUCP});{ 'PGP auch f�r RFC verwenden' }
  mset1func(testxpgp);
*)
  readmask(brk);
  if not brk and mmodified then
    GlobalModified;
  enddialog;
  freeres;
  menurestart:=brk
end;


end.

{
  $Log: xp2c.pas,v $
  Revision 1.39  2002/01/01 12:47:00  mm
  - Fix: oops, versehentlich geloeschte Zeile wieder eingefuegt ;-)

  Revision 1.38  2002/01/01 12:13:17  mm
  - Automatisches Halten selbstgeschriebener PMs unter
    Config/Optionen/Nachrichten/"Eigene PMs halten" konfigurierbar
    (Jochen Gehring)

  Revision 1.37  2001/12/30 12:22:00  mm
  - Hilfe fuer Archivierungsvermerkschalter

  Revision 1.36  2001/12/30 12:01:55  mm
  - Archivierungsvermerk abschaltbar unter:
    Config/Optionen/Allgemeines/"Archivierungsvermerk erstellen"
    (Jochen Gehring)

  Revision 1.35  2001/12/22 14:35:55  mm
  - ListWrapToggle: mittels Ctrl-W kann im Lister und Archiv-Viewer der
    automatische Wortumbruch nicht-permanent umgeschaltet werden
    (Dank an Michael Heydekamp)

  Revision 1.34  2001/07/25 20:58:41  MH
  - RFC-PGP: Men� wieder aktiviert...

  Revision 1.33  2001/07/22 16:10:38  MH
  - PGP-Einstellungen optisch korrigiert

  Revision 1.32  2001/06/29 15:55:48  MH
  - AutoDatumsBezuege entfernt

  Revision 1.31  2001/06/18 20:10:04  oh
  OH: GPG-Fixes (von Malte Kiesel), Sign All geht jetzt wieder

  Revision 1.30  2000/11/25 20:44:20  MH
  MK: Weiterschalter nach �nderung im Bedienungsmen� sofort wirksam
  MH: Das selbe gilt auch f�r den Extrakttyp

  Revision 1.29  2000/11/11 14:12:48  MH
  Lange Betreffs f�r HideRe usw.

  Revision 1.28  2000/11/09 22:05:59  oh
  -First try with GnuPG - please test it!

  Revision 1.27  2000/11/02 23:52:26  rb
  Automatische Sommer-/Winterzeitumstellung bei korrekt gesetzter
  TZ-Umgebungsvariable

  Revision 1.26  2000/11/01 13:59:34  rb
  Tearline-Schalter

  Revision 1.25  2000/10/13 00:42:06  rb
  Feineinstellung f�r Cancel- und Supersedes-Verarbeitung

  Revision 1.24  2000/10/12 21:44:44  oh
  -PGP-Passphrase merken + Screenshot-File-Verkleinerung

  Revision 1.23  2000/10/07 10:08:43  MH
  HDO: Im Men� Config/Optionen/Netze/RFC...
  Anzahl der Versuche zur Requestanforderung einstellen

  Revision 1.22  2000/09/13 18:54:26  oh
  -Verschobene Hilfe korrigiert

  Revision 1.21  2000/09/13 18:41:43  oh
  Bugfixes

  Revision 1.20  2000/09/12 20:32:46  oh
  ML-Header-Filter eingebaut

  Revision 1.19  2000/09/11 22:26:26  oh
  -Re: und AW: ausblendbar

  Revision 1.18  2000/08/21 23:01:23  oh
  Defaultfile bei W im Lister

  Revision 1.17  2000/07/31 15:11:32  MH
  MAILER-DAEMON kann nun f�r jede Box separat konfiguriert werden

  Revision 1.16  2000/07/30 16:14:49  MH
  RFC/PGP: Jetzt auch im PGP-Men�

  Revision 1.15  2000/07/10 19:09:11  MH
  Sourceheader ausgetauscht

  Revision 1.14  2000/07/10 18:11:35  MH
  RTE 204 bei Sprachwechsel beseitigt

  Revision 1.13  2000/07/03 01:34:25  MH
  - Modeminit wieder auf den alten von Peter festgelegten
    Init gesetzt

  Revision 1.12  2000/07/02 22:02:12  MH
  - Modeminit: AT&F

  Revision 1.11  2000/06/25 07:40:57  MH
  - Feldtausch Men� �bersichtlicher aufgebaut

  Revision 1.10  2000/06/25 00:44:30  oh
  Fixes/Updates

  Revision 1.9  2000/06/20 18:58:07  MH
  Verzeichnisse werden auf max. 8 Zeichen gepr�ft

  Revision 1.8  2000/06/07 13:22:16  MH
  RFC/PPP: Englische Version des Resourcenfiles angepasst

  Revision 1.7  2000/05/25 23:18:05  rb
  Loginfos hinzugef�gt

}
