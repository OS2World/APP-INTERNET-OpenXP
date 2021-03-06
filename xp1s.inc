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
{ $Id: xp1s.inc,v 1.19 2001/12/22 14:35:55 mm Exp $ }

{ DOS-Shell }

function repfile(var prog,name:string):string;
var p : byte;
begin
  p:=pos('$FILE',ustr(prog));
  if p>0 then
    repfile:=left(prog,p-1)+name+copy(prog,p+5,127)
  else
    repfile:=prog+' '+name;
end;


procedure Resiprog; {$IFNDEF Ver32 } far; {$ENDIF }
begin
  if ExecTestres then
    interr(getres(109));  { Residentes Programm geladen! CrossPoint wird beendet.. }
end;


procedure resetvideo; forward;

{ prog:  Programmname. Falls nicht per PATH erreichbar, dann wird
         ein COMMAND /C gestartet
  space: ben�tigter Speicherplatz in KByte (wenn weniger Platz ist,
         wird aber auch nur weniger freigemacht..). 640 -> Maximum.
  cls:   0 = nicht l�schen;
         1 = l�schen,
         2 = l�schen+Hinweis
         3 = Mitte l�schen
         -1= l�schen/25 Zeilen
         4 = l�schen/nicht sichern,
         5 = nicht l�schen/nicht sichern
         6 = Mitte l�schen und benutzerdefinierte Zeilenanzahl }

const trackpath : boolean = false;


procedure shell(prog:string; space:word; cls:shortint);  { Externer Aufruf }
var sm2t     : boolean;
    _xp_     : string[4];
    maussave : mausstat;
    sp       : scrptr;
    de       : integer;
    savesl   : byte; { sichert f. MailerShell ScreenLines }
    scrmode  : byte; { Temp f�r NewScreenlines            }

  procedure ShowPar;
  var w1,w2    : word;
      x,y,p,p2 : byte;
  begin
    savecursor;
    cursor(curoff);
    w1:=windmin; w2:=windmax;
    window(1,1,80,25);
    if length(prog)<=74 then
      message(prog)
    else begin
      msgbox(76,4,'',x,y);
      p:=blankposx(prog);
      p2:=71;
      while prog[p2]<>' ' do dec(p2);
      mwrt(x+3,y+1,left(prog,p2-1));
      mwrt(x+3+p,y+2,mid(prog,p2+1));
      end;
    wkey(15,false);
    windmin:=w1; windmax:=w2;
    closebox;
    restcursor;
  end;

  procedure getscrmode(scrlines:byte);
  begin
    case scrlines of
      25 : ScrMode:=1;
      26 : ScrMode:=2;
      28 : ScrMode:=3;
      30 : ScrMode:=4;
      33 : ScrMode:=5;
      36 : ScrMode:=6;
      40 : ScrMode:=7;
      44 : ScrMode:=8;
      50 : ScrMode:=9;
    else   ScrMode:=0;
    end;
  end;

begin
  de:=0;
  if (ParDebFlags and 1<>0) or ShellShowpar then
    ShowPar;
  if maxavail<$4000 then
    rfehler(7)  { Zu wenig freier Speicher f�r externen Programmaufruf! }
  else begin
    { trackpath:=(dospath(0)+'\'=OwnPath) or (dospath(0)=shellpath); }
    getmaus(maussave);  { <- mu� f�r VER32 noch portiert werden }
    {$IFDEF VER32}
    maussave.x:=1;
    maussave.y:=1;
    {$ENDIF}
    xp_maus_aus;
    if (cls<>4) and (cls<>5) then begin
      sichern(sp);
      savecursor;
    end;
    TempClose;
    freehelp;

    { -> evtl. normaler Video-Mode }
    sm2t:=m2t;
    attrtxt(7);
    case abs(cls) of
      1,2,4 : begin
                clrscr;
                m2t:=false;
              end;
      3     : begin
                clwin(1,80,4,screenlines-2);
                gotoxy(1,5);
              end;
      { benutzerdefinierte Zeilenanzahl in der MailerShell (TG) }
      6     : begin
                if MailerShell <> screenlines then begin
                  savesl:=screenlines;
                  getscrmode(mailershell);
                  if ScrMode <> 0 then begin
                    NewScreenlines(ScrMode);
                    showscreen(false);
                    showlastkeys;
                  end
                  else
                    clwin(1,80,4,screenlines-2);
                end
                else
                  clwin(1,80,4,screenlines-2);
                gotoxy(1,5);                 { Cursor f�r Clients setzen }
              end;
     end;
     if (cls=2) or (cls=-1) then begin
       if shell25 and (screenlines>25) then
         setvideomode(3);
       if cls=2 then writeln(getres(113));  { Mit EXIT geht''s zur�ck zu CrossPoint. }
     end;
    cursor(curon);

    if (getenv('XPSWAP')<>'') and validfilename(getenv('XPSWAP')) then
      ExecSwapfile:=getenv('XPSWAP')
    else
      ExecSwapfile:=TempPath+SwapFileName;

    ExecTestres:=ParTestres;
    _xp_:='[XP]';
    ExecDeutsch:=deutsch;

    ExecResident:=resiprog;
{$IFDEF BP }
    ExecUseEms:=SwapToEms;
    ExecUseXms:=SwapToXms;
{$ENDIF }
    case Xec(prog,space,envspace,_xp_,errorlevel) of
      ExecSwaperr : begin
                      tfehler(ioerror(ioresult,getres(110)),60);  { Fehler beim Speicherauslagern! }
                      doserror:=0;
                    end;
      ExecSwapweg : interr(getres(111));  { SWAP-File nicht mehr vorhanden! }
      ExecSwapre  : interr(ioerror(ioresult,getres(112)));  { Fehler beim Lesen des SWAP-Files }
    end;

    de:=doserror;

    if shellkey or (ParDebFlags and 2<>0) or ShellWaitkey then begin
      if deutsch and (random<0.02) then write('Pressen Sie einen Schl�ssel ...')
      else write(getres(12));  { Taste dr�cken ... }
      m2t:=false;
      pushhp(51);
      clearkeybuf;
      wait(curon);
      pophp;
      m2t:=true;
      shellkey:=false;
    end;

    { Screenlines wieder grob restaurieren ... }
    if (cls=6) and (mailershell<>savesl) then begin
      getscrmode(savesl);
      if ScrMode <> 0 then begin
        NewScreenlines(ScrMode);
        ShowScreen(false);
      end;
    end;

    resetvideo;
    cursor(curoff);
    if (cls<>4) and (cls<>5) then holen(sp);
    m2t:=sm2t;
    Disp_DT;
    if (cls<>4) and (cls<>5) then restcursor;
    xp_maus_an(maussave.x,maussave.y);
    if (de<>0) and (de<>4) then
      fehler(ioerror(de,getres(115)));
  end;                            { Fehler bei Programm-Aufruf }

  if trackpath then
    getdir(0,shellpath);
  if dospath(0)<>OwnPath then
    GoDir(OwnPath);
  TempOpen;
end;

{$IFDEF BP }
Function DosStartSession(Var Data:TStartData):Word; Assembler;
 Asm
        mov     ah, $64
        mov     bx, $0025
        mov     cx, $636C
        push    ds
        lds     si, Data
        int     $21
        pop     ds
 End;

Procedure Start_OS2(Programm,Parameter,Title:String);
Var StartData:TStartData;
    Temp:String;
    PrgName,PrgParam,PrgTitle:PChar;
Begin
  GetMem(PrgName,256);
  GetMem(PrgParam,256);
  GetMem(PrgTitle,256);
  Temp:='CMD.EXE';
  StrPCopy(PrgName,Temp);
  Temp:='/C'+' '+Programm+' '+Parameter;
  StrPCopy(PrgParam,Temp);
  StrPCopy(PrgTitle,Title);
  With StartData Do Begin
    Length:=SizeOf(TStartData);
    Related:=1;
    FgBg:=0;
    TraceOpt:=0;
    PgmTitle:=PrgTitle;
    PgmName:=PrgName;
    PgmInputs:=PrgParam;
    TermQ:=Nil;
    Environment:=Nil;
    InheritOpt:=0;
    SessionType:=2;
    IconFile:=Nil;
    PgmHandle:=0;
    PgmControl:=0;
    InitXPos:=0;
    InitYPos:=0;
    InitXSize:=0;
    InitYSize:=0;
    Reserved:=0;
    ObjectBuffer:=Nil;
    ObjectBuffLen:=0;
  End;

  DosStartSession(StartData);
  FreeMem(PrgTitle,256);
  FreeMem(PrgParam,256);
  FreeMem(PrgName,256);
End;
{$ENDIF }

function listcolor(var s:string; line:longint):byte; {$IFNDEF Ver32 } far; {$ENDIF }
var p,p0,ml : byte;
    qn,pdiff: integer;
begin
  listhicol:=col.collisthigh;
  if line<=exthdlines then
    listcolor:=col.collistheader
  else if s='' then
    listcolor:=0
  else if s[1]<=^c then
    listcolor:=iif((length(s)>1) and kludges,col.collistmarked,$ff)
  else begin
    p:=1;
    ml:=min(length(s),6);
    while (p<=ml) and ((s[p]=' ') or (s[p]=^I)) do
      inc(p);
    p0:=p;
    qn:=0;
    repeat
       while (p<=length(s)) and (p-p0<6) and
       (
         (s[p]<>'>') and
         (not OtherQuoteChars or not (s[p] in QuoteCharSet))
       )
       do inc(p);
      pdiff:=p-p0;

      if (p<=length(s)) and (s[p]='>') or
         (OtherQuoteChars and (s[p] in QuoteCharSet)) then
      begin
        inc(qn);
        p0:=p;
      end;
      inc(p);
    until (p>length(s)) or (pdiff=6);
    if qn<1 then
      listcolor:=0
    else begin
      listcolor:=col.collistquote[min(qn,iif(QuoteColors,9,1))];
      listhicol:=col.collistqhigh[min(qn,iif(QuoteColors,9,1))]
      end;
    end;
end;


{ 0=normal, -1=Minus, 1=Plus, 2=links, 3=rechts, 4=P/B/^P/^B (ListKey),
  5="0", 6=PgUp, 7=PgDn }

function listfile(name,header:string; savescr,listmsg:boolean;
                  cols:shortint):shortint; { Lister }
var brk    : boolean;
    p      : scrptr;
    oldm   : byte;
    msg    : boolean;
    lf     : pathstr;
    pp     : byte;
    lt     : byte;
    lfirst : byte;     { Startzeile Lister }
    lofs   : word;     { Ladeposition Datei }
    dphb   : byte;     { Uhr Hintergrundfarbe Backup }

  procedure ShowMsgHead;
  var t : text;
      s : string;
      i : integer;
  begin
    assign(t,name); reset(t);
    attrtxt(col.collistheader);
    for i:=1 to exthdlines do begin
      readln(t,s);
      if (i=1) and listuhr
        then if length(s)>70 then s:=forms(left(s,70),length(s));
      if s[1]<>'-' then mwrt(1,lfirst,' '+forms(s,79))
      else mwrt(1,lfirst,dup(80,'�'));
      inc(lfirst);
      inc(lofs,length(s)+2);
      end;
    close(t);
    exthdlines:=0;
    lfirst:=min(lfirst,screenlines-5);
  end;

begin
  listexit:=0;
  if varlister<>'' then begin
    lf:=repfile(VarLister,name);
    pp:=pos('$TYPE',ustr(lf));
    if pp>0 then begin
      lt:=iif(listmsg,iif(listkommentar,2,1),0);
      lf:=left(lf,pp-1)+strs(lt)+mid(lf,pp+5);
      end;
    shell(lf,ListerKB,1);
    if errorlevel in [100..110] then ExtListKeys;
    end
  else begin
    if savescr then sichern(p);
    lfirst:=iif(listvollbild,1,4); lofs:=0;
    if listvollbild then begin                      { Bei Vollbild-lister : }
      if {not listmsg or} not listuhr then m2t:=false { Uhr nur im Message Lister... }
      else begin
        dphb:=dphback;
        if ListFixedhead then                      {   Wenn fester Header }
          dphback:=col.collistheader               {   dann Uhr aktiv mit Headerfarbe }
        else begin
          dphback:=col.colliststatus;              {   bei freiem Header }
          timey:=1;                                {   Uhr in Zeile 1 und Statuszeilenfarbe}
          end;
        end;
      end;
    if ListMsg and ListFixedHead then
      ShowMsgHead;
    openlist(1,iif(_maus and listscroller,79,80),lfirst,
             iif(listvollbild,screenlines,screenlines-fnkeylines-1),
             iif(listvollbild,1,4),'/F1/MS/S/APGD/'+iifs(listendcr,'CR/','')+
             iifs(_maus and ListScroller,'VSC:080/','')+
             iifs(listmsg,'ROT/',''));
    if listwrap {or listkommentar} then
      lister.listwrap(iif(_maus and listscroller,78,80));
    if listmsg and ConvIso then list_convert(ISO_conv);
    if not ListAutoscroll then listNoAutoscroll;
    msg:=(_filesize(name)>1024*100);
    if msg then rmessage(130);    { 'Lade Datei ...' }
    list_readfile(name,lofs);
    if msg then closebox;
    listheader(header);
    listTp(listExt);   llh:=listmsg;
    oldm:=ListMakros;
    if listmsg then ListMakros:=8;
    if cols<>0 then begin
      listCFunc(listColor);
      if cols and 2<>0 then begin
        listDLproc(listDisplay);
        xp1o.ListXHighlight:=ListHighlight;
        end;
      end;
    pushhp(39);
    if _maus and listscroller and listvollbild then begin
      attrtxt(col.colliststatus);
      mwrt(1,lfirst,sp(80));
      end;
    list(brk);
    pophp;
    ListMakros:=oldm;
    if listvollbild and listuhr {and ListMsg} then begin
     dphback:=dphb;                        { Uhrfarbe resetten }
     if not Listfixedhead then timey:=1;   { Und evtl. Position }
     end;
   m2t:=true;
    if savescr then holen(p);
    closelist;
    end;
  exthdlines:=0;
  llh:=false;
  if listexit<>4 then               { Wenn nicht Editor gestartet wird... }
    otherquotechars:=otherqcback;   { Status der Quotechars '|' und ':' reseten }
  if (listexit<>-4) and (ListWrapToggle) then
  begin
    ListWrap:=ListWrapBack;         { Status Wortumbruch resetten }
    ListWrapToggle:=false;
  end;
  listfile:=listexit;
end;


procedure RemoveEOF(fn:pathstr);
var f : file;
    b : byte;
begin
  assign(f,fn);
  reset(f,1);
  if ioresult<>0 then exit;    { Datei nicht gesichert }
  if filesize(f)>0 then begin
    seek(f,filesize(f)-1);
    blockread(f,b,1);
    if b=26 then begin
      seek(f,filesize(f)-1);
      truncate(f);
      end;
    end;
  close(f);
end;


{ reedit: Nachbearbeiten einer XP-erzeugten-Nachricht - }
{         TED-Softreturns zur�ckwandeln                 }

procedure editfile(name:pathstr; nachricht,reedit:boolean; keeplines:byte;
                   ed_ukonv:boolean);
var p,p1: byte;
    bak : string[3];
    ms  : boolean;
begin
  if ((exteditor=3) or ((exteditor=2) and nachricht) or
     (_filesize(name)*1.2>memavail-16383)) and (VarEditor<>'')
     and (VarEditor[1]<>'*') then begin
    ms:=shell25; shell25:=edit25;
    shell(repfile(VarEditor,name),EditorKB,-1);
    shell25:=ms;
    removeeof(name);
    bak:=BAKext;
    end
  else begin
    if nachricht then pushhp(54);
    TED(name,reedit,keeplines,ed_ukonv);
    if nachricht then pophp;
    if nachricht and (left(VarEditor,1)='*') then begin
      delfirst(VarEditor);
      shell(repfile(VarEditor,name),EditorKB,3);
      insert('*',VarEditor,1);
      end;
    bak:='BAK';
    end;
  if bak<>'' then begin
    p:=rightpos('.',name);
    p1:=rightpos('\',name);
    if p1<>0 then
      if (p<>0) and (p>p1) then
        name:=left(name,p)+bak
      else
        name:=name+'.'+bak
    else
      if p=0 then
        name:=name+'.'+bak
      else
        name:=left(name,p)+bak;
    if exist(name) then _era(name);      { .BAK l�schen }
    end;
end;


{ Achtung! ShellPath kann mit oder ohne '\' am Ende sein! }

procedure dosshell;
{$IFDEF DPMI }
const ShellBatch = 'DPMISHELL.BAT';
{$ENDIF }
var t : text;

  {$IFNDEF DPMI}
  function environment:string;
  begin
    if envspace=0 then environment:=''
    else environment:=' /E:'+strs(envspace);
  end;
  {$ENDIF }

begin
  if DisableDos then
    fehler(getres(116))   { DOS-Shell hier nicht m�glich }
  else begin
    GoDir(ShellPath);
    if ioresult<>0 then GoDir(ownpath);
    trackpath:=true;
    {$IFDEF DPMI}
      assign(t,TempPath+ShellBatch);
      rewrite(t);
      writeln(t,'@set prompt=[XP] '+getenv('PROMPT'));
      writeln(t,'@',getenv('COMSPEC'));
      close(t);
      shell(TempPath+ShellBatch,620,2);
      _era(TempPath+ShellBatch);
    {$ELSE}
      shell(getenv('COMSPEC')+environment,640,2);
    {$ENDIF}
    trackpath:=false;
    end;
end;
{
  $Log: xp1s.inc,v $
  Revision 1.19  2001/12/22 14:35:55  mm
  - ListWrapToggle: mittels Ctrl-W kann im Lister und Archiv-Viewer der
    automatische Wortumbruch nicht-permanent umgeschaltet werden
    (Dank an Michael Heydekamp)

  Revision 1.18  2001/07/21 10:17:50  MH
  - letzten Fix weiter abgesichert

  Revision 1.17  2001/07/20 22:33:11  MH
  - Fixes in 'BAK-Files l�schen'

  Revision 1.16  2001/07/12 01:52:56  MH
  - MailerShell nochmals optimiert

  Revision 1.15  2001/07/11 23:27:25  MH
  - MailerShell �berarbeitet: nochmal, weil es so sch�n war!

  Revision 1.14  2001/07/11 18:55:02  MH
  - MailerShell �berarbeitet

  Revision 1.13  2001/07/11 18:32:53  tj
  range check error fix in 'shell'

  Revision 1.12  2001/06/26 23:17:31  MH
  - Uhr auch bei ShowHeader anzeigen

  Revision 1.11  2001/06/18 20:17:25  oh
  Teames -> Teams

  Revision 1.10  2001/03/24 10:00:20  tg
  MailerShell

  Revision 1.9  2001/03/23 15:49:27  tg
  Maus/Netcall-Fix

  Revision 1.8  2001/03/21 23:36:56  tj
  einfacher Bugfix

  Revision 1.7  2001/03/20 18:58:14  tg
  MailerShell

  Revision 1.6  2000/11/09 00:17:40  rb
  Fix f�r Uhr im Lister bei feststehendem Kopf

  Revision 1.5  2000/06/23 14:41:43  tg
  Uhr im Lister vernuenftig integriert

  Revision 1.4  2000/04/09 18:21:30  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.18  2000/04/01 07:41:38  jg
  - "Q" im Lister schaltet otherquotechars (benutzen von | und :) um.
    neue Einstellung wird dann auch beim Quoten verwendet
  - Hilfe aktualisiert, und Englische Hilfe fuer
    Config/Optionen/Allgemeines auf Stand gebracht.

  - Externe-Viewer (Windows): "START" als Allroundviewer
    funktioniert jetzt auch mit der Loeschbatch-Variante
  - Text fuer MIME-Auswahl in englische Resource eingebaut

  Revision 1.17  2000/03/25 11:46:10  jg
  - Lister: Uhr wird jetzt auch bei freiem Nachrichtenkopf eingeblendet
  - Config/Optionen/Lister: Schalter ListUhr zum (de)aktivieren der Uhr

  Revision 1.16  2000/03/23 15:47:23  jg
  - Uhr im Vollbildlister aktiv
    (belegt jetzt 7 Byte (leerzeichen vorne und hinten)

  Revision 1.15  2000/03/14 15:15:38  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.14  2000/03/09 23:39:33  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.13  2000/03/08 22:13:31  rb
  nicht mehr ben�tigte Routinen f�r OS/2 Programmaufruf entfernt

  Revision 1.12  2000/03/06 08:51:04  mk
  - OpenXP/32 ist jetzt Realitaet

  Revision 1.11  2000/03/06 05:14:15  jg
  Sch�nheitsfix f�r Lister : Uhr bei riesigen Nachrichten rechtzeitig abschalten

  Revision 1.10  2000/03/02 21:19:51  jg
  - Uhr beim verlassen des Nachrichtenheaders eleganter deaktiviert

  Revision 1.9  2000/02/27 08:24:57  jg
  -Strings.StrPCopy wird wieder benutzt...

  Revision 1.8  2000/02/26 18:14:47  jg
  - StrPCopy in Xp1s.inc integriert
  - Suche aus Archivviewer wieder zugelassen
    (zwecks Headereintregsuche im "O" Fenster)

  Revision 1.7  2000/02/24 23:50:11  rb
  Aufruf externer Viewer bei OS/2 einigermassen sauber implementiert

  Revision 1.6  2000/02/21 22:48:01  mk
  MK: * Code weiter gesaeubert

  Revision 1.5  2000/02/19 11:40:08  mk
  Code aufgeraeumt und z.T. portiert

}
