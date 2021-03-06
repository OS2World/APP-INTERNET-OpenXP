{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: maske.pas,v 1.3 2000/05/25 23:07:55 rb Exp $ }

{ Maskeneditor; V1.1 08/91, 05/92 PM }

{$I XPDEFINE.INC }
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit  maske;

interface

uses  xpglobal, crt,typeform,keys,inout,maus2,winxp,montage, clip; {JG:+CLIP}

const digits : string[12] = '-0123456789 ';
      allchar = ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXY'+
                'Z[\]^_`abcdefghijklmnopqrstuvwxyz{|}~�����������������������'+
                '��������������������������������������������������������';
      hexchar = '<0123456789abcdef';

      mtString   = 1;
      mtShortint = 2;
      mtByte     = 3;
      mtInteger  = 4;
      mtWord     = 5;
      mtLongint  = 6;

type  colrec   =  record              { 0 = keine spezielle Farbe }
                    ColBack,          { Hintergrund & Rahmen  }
                    ColFeldName,      { Feldnamen             }
                    ColDisabled,      { ausgeschalteter Name  }
                    ColFeldNorm,      { Feldinhalt Anzeige    }
                    ColFeldInput,     { Eingabefeld           }
                    ColFeldActive,    { aktives Eingabefeld   }
                    ColFeldMarked,    { markierter Feldinhalt }
                    ColArrows,        { Pfeile bei Scrollfeld }
                    ColHelpTxt,       { Hilfszeile            }
                    ColFnInfo,        { Info-Text f�r SekKey  }
                    ColFnFill,        { kein Info-Text...     }
                    ColSelBox,        { Auswahlbox            }
                    ColSelBar,        { Auswahlbalken A.-Box  }
                    ColButtons: byte; { Check/Radio-Buttons   }
                  end;

      customrec = record
                    acol : colrec;    { aktuelle Farben }
                    x,y  : byte;      { aktuelle Pos. des Feldinhalts }
                    fpos : integer;   { akt. Feldnummer }
                    s    : string;    { var: Feldinhalt }
                    brk  : boolean;   { var }
                  end;

      testfunc    = function(var inhalt:string):boolean;
      testproc    = procedure(var inhalt:string);
      customsel   = procedure(var cr:customrec);
      quitfunc    = function(brk,modif:boolean):boolean;
      userdproc   = procedure;

      wrapmodes   = (dont_wrap,do_wrap,endonlast);


{-------------- allgemeine Funktionen -------------}

procedure openmask(l,r,o,u:byte; pushit:boolean);   { neue Maske �ffnen }
procedure readmask(var brk:boolean);                { *** Einlesen ***  }
procedure readHmask(mhelpnr:word; var brk:boolean); { .. mit Hilfsseiten }
function  mmodified:boolean;                        { Inhalt ge�ndert   }
procedure closemask;                                { Maske schlie�en   }
procedure readstring(x,y:byte; text:string; var s:string; displ,maxl:byte;
                     chml:string; var brk:boolean);
procedure mbeep;
procedure DefaultColor(var col:colrec);             { col <- Default    }
procedure masklanguage(_yesno:string);              { 'JN'              }

procedure mdummyp(var inhalt:string);               { Dummy f�r Test0   }
function  mdummyf(var inhalt:string):boolean;       { Dummy f�r Test1/2 }
function  qdummyf(brk,modif:boolean):boolean;       { Dummy f�r QuitFN  }


{--------------- Masken-Einstellungen -------------}
{ beziehen sich auf die jeweils aktuelle Maske und }
{ werden in amaskp^.stat abgelegt                  }

procedure maskcol(cols:colrec);              { Farben der akt. Maske setzen }
procedure maskrahmen(rtyp,l,r,o,u:byte);     { Rahmentyp setzen }
procedure masksetstat(keepon_esc,autosel:boolean; selkey:taste);
procedure masksetfillchar(c:char);           { F�llzeichen setzen }
procedure masksethelp(hx,hy,hl:byte; center:boolean);   { Hilfszeile einst. }
procedure masksetfninfo(x,y:byte; text:string; fillc:char);
procedure masksetwrapmode(wm:wrapmodes);
procedure masksetautojump(aj:byte);     { Sprungweite bei cr am unteren Rand }
procedure masksetqfunc(qfunc:quitfunc);
procedure masksetarrowspace(aas:boolean);
procedure masksetmausarrows(ma:boolean);
procedure masksetautohigh(ah:boolean);  { Felder automatisch selektieren }
procedure maskdontclear;
procedure maskcheckbuttons;
procedure maskselcursor(cur:curtype);
procedure maskUpDownArrows(x1,y1,x2,y2:byte; fill:char; col:byte);


{------------ Felder anlegen ------------}
{ werden an die aktuelle Maske angeh�ngt }

{ Integer-Typen: 2 = ShortInt, 3 = Byte, 4 = Integer, 5 = Word, 6 = LongInt }

procedure Maddtext(x,y:byte; text:string; att:byte);   { Anzeigetext anf�gen }
procedure Maddstring(x,y:byte; text:string; var s:string; displ,maxl:byte;
                     chml:string);
procedure Maddint(x,y:byte; text:string; var int; ityp,displ:byte;
                     imin,imax:longint);
procedure Maddreal(x,y:byte; text:string; var r:real; displ,rnk : byte;
                     rmin,rmax : real);
procedure Maddbool(x,y:byte; text:string; var b:boolean);
procedure Maddform(x,y:byte; text:string; var s:string; form,chml:string);
procedure Madddate(x,y:byte; text:string; var d:string; long,mbempty:boolean);
procedure Maddtime(x,y:byte; text:string; var t:string; long:boolean);
procedure Maddcustomsel(x,y:byte; text:string; var s:string; displ:byte;
                        cp:customsel);


{----------------- Feld-Einstellungen ----------------}
{ beziehen ich auf das jeweils zuletzt angelegte Feld }

procedure MSetProcs(p0,p3:testProc);
procedure MSet0Proc(p0:testproc);        { bei Feldeintritt     }
procedure MSet1Func(p1:testfunc);        { bei jeder �nderung   }
procedure MSetVFunc(p2:testfunc);        { vor Verlassen        }
procedure MSet3Proc(p3:testProc);        { bei Verlassen        }
procedure MSetUserDisp(ud:userdproc);    { bei Komplett-Neuanzeige }

procedure MDisable;                           { Feld deaktivieren }
procedure MDisabledNodisplay;                 { deaktiviert nicht anzeigen }
procedure MH(text:string);                    { Hilfszeile setzen }
procedure MHnr(helpnr:word);                  { Hilfsseiten-Nr. setzen }
procedure MSelHnr(helpnr:word);               { Hilfsseite f�r <F2> }
procedure MSetSel(sx,sy,slen:byte);           { Abmessungen der SelListe }
procedure MAppSel(force:boolean; s:string);   { SelBox aufbauen }
procedure Mappcustomsel(cp:customsel; nedit:boolean);
procedure Mnotrim;                            { kein autotrim }
procedure Malltrim;                           { rtrim/ltrim }
procedure Mspecialcol(attr:byte);             { spez. Farbe f�r Feldname }
procedure MSetAutoHigh(ah:boolean);           { automat. selektieren }



{----------------- Externe Funktionen --------------}
{ dienen zum Zugriff von externen (Test-)Funktionen }
{ auf Inhalte der momentan editierten Maske         }

procedure setfield(nr:word; newcont:string);
function  getfield(nr:word):string;
function  fieldpos:integer;         { akt.FeldNr, auch w�hrend Maskenaufbau! }
procedure setfieldenable(nr:word; eflag:boolean);   { Feld (de)aktivieren }
function  mask_helpnr:word;
function  readmask_active:boolean;
procedure set_chml(nr:word; chml:string);
procedure setfieldtext(nr:word; newtxt:string);
function  mtextpos:pointer;
procedure settexttext(p:pointer; newtxt:string);
procedure mclearsel(nr:word);
procedure mappendsel(nr:word; force:boolean; s:string);


implementation  {---------------------------------------------------------}

const maxmask   = 10;                { max. gleichzeitig offene Masken }
      maxfields = 140;               { max. Felder pro Maske           }

      insert_mode : boolean = true;
      help_page   : word = 0;        { Helpnr des Eingabefeldes }
      yesno       : string[2] = 'JN';

type  stringp  = ^string;

      { Achtung! Pointer in MaskStat m�ssen in OpenMask }
      {          gesondert behandelt werden!            }

      maskstat = record
                   col         : colrec;
                   rahmentyp   : byte;     { 0=keiner, 1/2/3, 4=wechselnd }
                   rl,rr,ro,ru : byte;     { Rahmen-Koordinaten }
                   hpx,hpy,hpl : byte;     { Position/Len Hilfstexte }
                   hcenter     : boolean;  { Hilfstexte zentrieren }
                   keeponesc   : boolean;  { Eingaben trotz Esc behalten }
                   autoselbox  : boolean;  { Auswahlbox automatisch �ffnen }
                   fillchar    : char;     { F�llzeichen bei Eingabe }
                   selboxkey   : taste;    { '' -> keine SelBox; Def: F2 }
                   fnix,fniy   : byte;     { Position der FNKey-Info }
                   fnkeyinfo   : stringp;
                   fnkeyfill   : char;
                   wrapmode    : wrapmodes;
                   autojump    : byte;    { Zeilensprung bei verl.d.Fensters }
                   quitfn      : quitfunc;
                   arrowspace  : boolean;  { Leerzeichen vor/hinter Feld }
                   mausarrows  : boolean;
                   fautohigh   : boolean;  { Felder automat. selektieren }
                   dontclear   : boolean;  { Fenster nicht l�schen }
                   checkbutts  : boolean;
                   Userdisp    : userdproc;  { bei Bild-Neuaufbau          }
                   selcursor   : boolean;
                 end;

      udarec   = record
                   x1,y1,x2,y2 : byte;
                   fillc       : char;
                   color       : byte;
                 end;

      selnodep = ^selnode;
      selnode  = record                    { Knoten f�r Select-Liste }
                   next        : selnodep;
                   el          : stringp;
                 end;

      textnodep= ^textnode;
      textnode = record                    { Knoten f�r Anzeigetext-Liste }
                   next        : textnodep;
                   txt         : stringp;
                   xx,yy,attr  : byte;
                 end;

      feldrec  = record
                   enabled     : boolean;
                   disnodisp   : boolean;
                   txt         : stringp;  { Feld-Text }
                   typ         : byte;     { Feldtyp }
                   variable    : pointer;  { Adresse der Variablen }
                   xx,yy,len   : byte;     { Position, Anzeigel�nge }
                   yy0,xx2     : byte;     { Position des Inhalts }
                   maxlen      : byte;     { maximale L�nge des Inhalts }
                   cont        : stringp;  { Feldinhalt }
                   allowed     : stringp;  { erlaubte Zeichen }
                   mask        : string[20];  { Masken-String }
                   autoup,
                   autodown,
                   topcase     : boolean;    { automatische Gro�/Kleinschr.}
                   convcolon   : boolean;    { automatisch "," -> "." }
                   _min,_max   : longint;
                   _rmin,_rmax : real;
                   nk          : byte;       { Nachkommastellen bei Real   }
                   test0       : testproc;   { vor jedem Editieren         }
                   test1       : testfunc;   { bei jeder �ndernden Eingabe }
                   test2       : testfunc;   { vor Verlassen des Feldes    }
                   test3       : testproc;   { bei Verlassen des Feldes    }
                   hpline      : stringp;
                   helpnr      : word;       { Hilfsseiten-Nr. }
                   selhelpnr   : word;       { Hilfsseite bei <F2> }
                   selliste    : selnodep;
                   hassel      : boolean;
                   slx,sly,sll : byte;       { SListen-Position/L�nge }
                   slmin       : byte;       { minimale Listenl�nge }
                   noslpos     : boolean;    { slx..sll noch nicht gesetzt }
                   forcesll    : boolean;
                   pempty      : boolean; { Formatierter Str. darf leer sein }
                   custom      : customsel;  { eigene Select-Prozedur }
                   nonedit     : boolean;    { Feld nicht editierbar }
                   autotrim    : byte;       { 0=nein, 1=r, 2=r+l }
                   owncol      : boolean;    { spezielle Farbe f�r Feldname }
                   ownattr     : byte;
                   autohigh    : boolean;    { Feld autom. selektieren }
                   counter     : byte;       { 1/2 -> "+"/"-" bei Datum/Zeit }
                   checkbutt   : boolean;    { Check-Button }
                 end;
      feldp    = ^feldrec;

      masktyp  = record
                   stat        : maskstat;
                   li,re,ob,un : byte;        { Arbeitsbereich }
                   dopush      : boolean;     { Inhalt sichern }
                   felder      : byte;        { Anzahl Felder  }
                   fld         : array[1..maxfields] of feldp;
                   mtxt        : textnodep;
                   maxyy0      : byte;        { gr��ter Y-Wert }
                   yp,a        : integer;     { akt. Feldnr./Offset }
                   modified    : boolean;     { Inhalt ge�ndert }
                   editing     : boolean;     { Editieren aktiv }
                   uda         : udarec;     { Pfeile bei scrollbaren Masken }
                 end;
      maskp    = ^masktyp;


var   mask    : array[0..maxmask] of maskp;
      masks   : byte;
      amask   : byte;       { aktuelle Maske, z.Zt. immer = masks! }
      amaskp  : maskp;      { mask[amask] }
      lastfld : feldp;      { aktuelles Feld w�hrend des Maskenaufbaus }

      redispfields : boolean;
      redisptext   : boolean;


{ Feldtypen:   1=String, 2=Short, 3=Byte, 4=Integer, 5=Word, 6=Long,
               7=Real, 8=Datum (tt.mm.jj oder tt.mm.jjjj),
               9=Uhrzeit (hh:mm oder hh:mm:ss), 10=Boolean (J/N)  }


procedure error(txt:string);
begin
  writeln('MASK: ',txt);
  halt(1);
end;

procedure mbeep;
begin
{$IFDEF VP }
  Playsound(600, 20);
{$ELSE }
  sound(600);
  delay(20);
  nosound;
{$ENDIF }
end;

{$IFDEF FPC }
  {$HINTS OFF }
{$ENDIF }

procedure mdummyp(var inhalt:string);
begin
end;

function mdummyf(var inhalt:string):boolean;
begin
  mdummyf:=true;
end;

function qdummyf(brk,modif:boolean):boolean;
begin
  qdummyf:=true;
end;

{$IFDEF FPC }
  {$HINTS ON }
{$ENDIF }


{--------------------- Maske anlegen/bearbeiten ------------------}

procedure testfield(nr:integer); forward;


procedure spcopy(p1:stringp; var p2:stringp);
begin
  if p1=nil then p2:=nil
  else begin
    getmem(p2,length(p1^)+1);
    p2^:=p1^;
    end;
end;


{ neue Maske �ffnen, falls noch Handles frei   }
{ der Maskenstatus wird von mask[0] �bernommen }

procedure openmask(l,r,o,u:byte; pushit:boolean);
begin
  if masks=maxmask then error('Overflow');
  inc(masks);
  amask:=masks;
  new(mask[amask]);
  amaskp:=mask[amask];
  with amaskp^ do begin
    stat:=mask[0]^.stat;
    spcopy(mask[0]^.stat.fnkeyinfo,stat.fnkeyinfo);
    uda:=mask[0]^.uda;
    li:=l; re:=r; ob:=o; un:=u;
    felder:=0; maxyy0:=0;
    dopush:=pushit;
    mtxt:=nil;
    editing:=false;
    end;
  lastfld:=nil;
end;


procedure mclearsel(nr:word);
var p1,p2 : selnodep;
begin
  testfield(nr);
  with amaskp^.fld[nr]^ do begin
    p1:=selliste;
    while p1<>nil do begin       { Selliste freigeben }
      p2:=p1^.next;
      freemem(p1^.el,length(p1^.el^)+1);
      dispose(p1);
      p1:=p2;
      end;
    selliste:=nil;
    end;
end;


{ aktuelle (oberste) Maske schlie�en }

procedure closemask;
var i     : integer;
    t1,t2 : textnodep;
begin
  if masks=0 then error('Underflow');
  with amaskp^ do begin
    for i:=1 to felder do begin
      with fld[i]^ do begin
        freemem(txt,length(txt^)+1);
        freemem(cont,maxlen+1);
        if allowed<>nil then freemem(allowed,length(allowed^)+1);
        if hpline<>nil then  freemem(hpline,length(hpline^)+1);
        mclearsel(i);
        end;
      dispose(fld[i]);
      end;
    with stat do
      if fnkeyinfo<>nil then freemem(fnkeyinfo,length(fnkeyinfo^)+1);
    t1:=mtxt;
    while t1<>nil do begin           { Textliste freigeben }
      t2:=t1^.next;
      freemem(t1^.txt,length(t1^.txt^)+1);
      dispose(t1);
      t1:=t2;
      end;
    end;
  dispose(amaskp);
  dec(masks);
  amask:=masks;
  amaskp:=mask[masks];
end;


{ neue Farben einstellen }

procedure maskcol(cols:colrec);
begin
  amaskp^.stat.col:=cols;
end;


{ neuen Rahmentyp einstellen
  0 = kein Rahmen
  1/2/3 = einfach/doppelt/spezial
  4 = automatisch �ndern beim durchscrollen }

procedure maskrahmen(rtyp,l,r,o,u:byte);
begin
  with amaskp^.stat do begin
    rahmentyp:=rtyp;
    rl:=l; rr:=r; ro:=o; ru:=u;
    end;
end;


{ diverse Status-Flags setzen                       }
{ keepon_esc:  Feldinhalt auch bei 'brk' �bernehmen }
{ autosel:     SelListen automatisch �ffnen   (nni) }
{ selkey:      Taste f�r SelListen                  }

procedure masksetstat(keepon_esc,autosel:boolean; selkey:taste);
begin
  with amaskp^.stat do begin
    keeponesc:=keepon_esc;
    autoselbox:=autosel;
    selboxkey:=selkey;
    end;
end;


{ F�llzeichen f�r Rest der Zeile setzen }

procedure masksetfillchar(c:char);
begin
  amaskp^.stat.fillchar:=c;
end;


{ Hilfszeile einstellen      }
{ hx = 0 -> keine Hilfszeile }

procedure masksethelp(hx,hy,hl:byte; center:boolean);
begin
  with amaskp^.stat do begin
    hpx:=hx;
    hpy:=hy;
    hpl:=hl;
    hcenter:=center;
    end;
end;


{ Info-Text f�r SelKey einstellen }

procedure masksetfninfo(x,y:byte; text:string; fillc:char);
begin
  with amaskp^.stat do begin
    fnix:=x; fniy:=y;
    getmem(fnkeyinfo,length(text)+1);
    fnkeyinfo^:=text;
    fnkeyfill:=fillc;
    end;
end;


{ Wrap-Mode einstellen                          }
{ dont_wrap:  bei 1. und letztem Feld anhalten  }
{ do_wrap:    bei 1. und letztem Feld wrappen   }
{ endonlast:  bei 1. Feld anhalten, beim letzen }
{             Ctrl-Enter ausf�hren              }

procedure masksetwrapmode(wm:wrapmodes);
begin
  amaskp^.stat.wrapmode:=wm;
end;


{ AutoJump gibt an, um wieviele Zeilen die Maske }
{ automatisch weiterspringen soll, wenn sie nach }
{ unten mit Return verlassen wird.               }

procedure masksetautojump(aj:byte);
begin
  amaskp^.stat.autojump:=aj;
end;


{ Masken-Fenster  wird zu Beginn nicht gel�scht }

procedure maskdontclear;
begin
  amaskp^.stat.dontclear:=true;
end;


procedure maskcheckbuttons;
begin
  amaskp^.stat.checkbutts:=true;
end;

procedure maskselcursor(cur:curtype);
begin
  amaskp^.stat.selcursor:=(cur=curon);
end;


procedure MaskUpDownArrows(x1,y1,x2,y2:byte; fill:char; col:byte);
begin
  amaskp^.uda.x1:=x1;
  amaskp^.uda.y1:=y1;
  amaskp^.uda.x2:=x2;
  amaskp^.uda.y2:=y2;
  amaskp^.uda.fillc:=fill;
  amaskp^.uda.color:=col;
end;


{ QFunc wird vor Beenden der Eingabe aufgerufen }
{ kann diese verhindern; �bergebene Parameter:  }
{ brk:    Beenden durch Esc-Taste               }
{ modif:  Feldinhalt wurde ge�ndert             }

procedure masksetqfunc(qfunc:quitfunc);
begin
  amaskp^.stat.quitfn:=qfunc;
end;


{ Anzeige eines Leezeichens vor/hinter den Eingabefeldern ein/ausschalten }

procedure masksetarrowspace(aas:boolean);
begin
  amaskp^.stat.arrowspace:=aas;
end;


{ Pfeil nach unten bei Auswahl-Liste }

procedure masksetmausarrows(ma:boolean);
begin
  amaskp^.stat.mausarrows:=ma;
end;


procedure masksetautohigh(ah:boolean);  { Felder automatisch selektieren }
begin
  amaskp^.stat.fautohigh:=ah;
end;


{----------------- Felder anf�gen -------------------}

{ reinen Anzeigetext anf�gen }
{ attr=0 -> ColFeldName      }

procedure Maddtext(x,y:byte; text:string; att:byte);
var p : textnodep;
begin
  with amaskp^ do begin
    new(p);
    with p^ do begin
      xx:=x+li-1;
      yy:=y;
      getmem(txt,length(text)+1);
      txt^:=text;
      if att=0 then attr:=stat.col.colfeldname
      else attr:=att;
      next:=mtxt;
      end;
    mtxt:=p;
    end;
end;


function mtextpos:pointer;
begin
  mtextpos:=amaskp^.mtxt;
end;


procedure setall(var text:string; x,y:byte; addblank:boolean);
begin
  with amaskp^ do
    if felder=maxfields then
      error('no more fields')
    else begin
      inc(felder);
      new(fld[felder]);
      lastfld:=fld[felder];
      fillchar(lastfld^,sizeof(feldrec),0);
      {:  autoup:=false; autodown:=false; topcase:=false;
          disnodisp:=false;
          convcolon:=false;
          hpline:=nil; selliste:=nil;
          hlpnr:=0;
          slx:=0; sly:=0; sll:=0;
          mask:='';
          nk:=0;
          pempty:=false;
          variable:=nil;
          custom:=nil; nonedit:=false;
          allowed:=nil; owncol:=false;
          @userdisp:=nil;
          arrowspace:=false;
          mausarrows:=false;
          counter:=0;
          checkbutt:=false;          :}

      with lastfld^ do begin
        enabled:=true;
        if text='' then addblank:=false;
        getmem(txt,length(text)+iif(addblank,2,1));
        txt^:=text+iifs(addblank,' ','');
        yy0:=y;
        maxyy0:=max(maxyy0,yy0);
        xx:=li+x-1; yy:=ob+y-1;
        xx2:=xx+length(text);
        if text<>'' then inc(xx2);
        test0:=mdummyp;
        test1:=mdummyf;
        test2:=mdummyf;
        test3:=mdummyp;
        noslpos:=true;
        forcesll:=true; slmin:=5;    { minimale SelListen-L�nge }
        autotrim:=1;
        autohigh:=stat.fautohigh;
        if (felder>1) and (fld[felder-1]^.helpnr>0) then
          helpnr:=fld[felder-1]^.helpnr+1;
        end;
      end;
end;


{ String anf�gen -----------------------------------------}
{ chml = ''  -> alle Zeichen erlaubt                      }
{ Das erste Zeichen von chml wird gesondert ausgewertet:  }
{ '>'  ->  automatische Umwandlung in Gro�buchstaben      }
{ '<'  ->  automatische Umwandlung in Kleinbuchstaben     }
{ '!'  ->  automatische Gro�schreibung des 1. Buchstabens }

procedure Maddstring(x,y:byte; text:string; var s:string; displ,maxl:byte;
                     chml:string);
var p : byte;
begin
  setall(text,x,y,true);
  with lastfld^ do begin
    typ:=1;
    variable:=@s;
    len:=displ; maxlen:=maxl;
    if maxlen=1 then autohigh:=false;
    getmem(cont,maxl+1);
    repeat
      p:=cpos(#7,s);
      if p=0 then p:=cpos(#8,s);
      if p>0 then s[p]:=' ';
    until p=0;
    cont^:=left(s,maxl);
    set_chml(amaskp^.felder,chml);
    end;
end;


{ Integer Anf�gen
  Typ 2 = ShortInt, 3 = Byte, 4 = Integer, 5 = Word, 6 = LongInt }

procedure Maddint(x,y:byte; text:string; var int; ityp,displ:byte;
                  imin,imax:longint);
var l : longint;
    s : s40;
begin
  if (ityp<2) or (ityp>6) then
    error('illegal Int type');

  setall(text,x,y,true);
  with lastfld^ do begin
    typ:=ityp;
    variable:=@int;
    len:=displ{+1}; maxlen:=displ;
    case ityp of
      2 : l:=shortint(int);
      3 : l:=byte(int);
      4 : l:=integer16(int);
      5 : l:=smallword(int);
    else
      l:=longint(int);
    end;
    _min:=imin; _max:=imax;
   { l:=min(max(l,imin),imax); }
    str(l:displ,s);
    getmem(cont,len+1);
    cont^:=s{+' '};
    getmem(allowed,length(digits)+1);
    allowed^:=digits;
    end;
end;


{ Real anf�gen }

procedure Maddreal(x,y:byte; text:string; var r:real; displ,rnk : byte;
                   rmin,rmax : real);
var s : s40;
begin
  setall(text,x,y,true);
  with lastfld^ do begin
    typ:=7;
    variable:=@r;
    len:=displ{+1}; maxlen:=displ;
    _rmin:=rmin; _rmax:=rmax;
  { r:=minr(maxr(r,rmin),rmax); }
    str(r:displ:rnk,s);
    nk:=rnk;
    getmem(cont,len+1);
    cont^:=s;
    convcolon:=true;
    getmem(allowed,length(digits)+2);
    allowed^:=digits+'.';
    end;
end;


{ Bool-Wert anf�gen }

procedure Maddbool(x,y:byte; text:string; var b:boolean);
begin
  if amaskp^.stat.checkbutts then begin
    text:=rtrim(text);
    if right(text,1)='?' then dellast(text);
    end;
  setall(text,x,y,not amaskp^.stat.checkbutts);
  with lastfld^ do begin
    checkbutt:=amaskp^.stat.checkbutts;
    if checkbutt then begin
      xx2:=xx;
      xx:=xx2+7;
      end;
    typ:=10;
    variable:=@b;
    len:=1; maxlen:=1;
    getmem(cont,2);
    cont^:=iifc(b,yesno[1],yesno[2]);
    autoup:=true;
    getmem(allowed,4);
    allowed^:='>'+yesno;
    autohigh:=false;
    end;
end;


{ Formatierten String anf�gen                               }
{ Eingaben k�nnen �berall erfolgen, wo im Format ' ' steht. }
{ Alle anderen Stellen werden aus dem Format �bernommen.    }
{ Wenn s='', dann wird s:=form gesetzt.                     }

procedure Maddform(x,y:byte; text:string; var s:string; form,chml:string);
begin
  if s='' then s:=form;
  MAddString(x,y,text,s,length(form),length(form),chml);
  with lastfld^ do begin
    mask:=form;
    autotrim:=0;
    autohigh:=false;
    end;
end;


{ Datum anf�gen               }
{ long -> langes Datumsformat }
{ mbempty -> may be empty     }

procedure Madddate(x,y:byte; text:string; var d:string; long,mbempty:boolean);
begin
  Maddform(x,y,text,d,iifs(long,'  .  .    ','  .  .  '),' 0123456789');
  with lastfld^ do begin
    typ:=8;
    pempty:=mbempty;
    counter:=1;
    end;
end;


{ Uhrzeit anf�gen }

procedure Maddtime(x,y:byte; text:string; var t:string; long:boolean);
begin
  Maddform(x,y,text,t,iifs(long,'  :  :  ','  :  '),'0123456789');
  lastfld^.typ:=9;
  lastfld^.counter:=2;
end;


{ Feld mit beliebiger eigener Select-Routine anf�gen  }
{ s : Feldinhalt zu Beginn; wird von cp �berschrieben }
{ displ : Anzeige-L�nge (wg. forms)                   }
{ Das Feld ist nicht mehr editierbar!                 }

procedure Maddcustomsel(x,y:byte; text:string; var s:string; displ:byte;
                        cp:customsel);
begin
  Maddstring(x,y,text,s,displ,displ,'');
  with lastfld^ do begin
    custom:=cp;
    nonedit:=true;
    hassel:=true;
    end;
end;


function testlast:boolean;
begin
  if lastfld=nil then begin
    error('Operation on non-existing field');
    testlast:=false;
    end
  else
    testlast:=true;
end;


procedure MDisable;
begin
  if testlast then
    lastfld^.enabled:=false;
end;


procedure MDisabledNodisplay;                 { deaktiviert nicht anzeigen }
begin
  if testlast then
    lastfld^.disnodisp:=true;
end;


procedure MSetProcs(p0,p3:testproc);
begin
  if testlast then
    with lastfld^ do begin
      test0:=p0;            { bei Feldeintritt }
      test3:=p3;            { bei Feldaustritt }
      end;
end;

procedure MSet0Proc(p0:testproc);
begin
  if testlast then
    lastfld^.test0:=p0;
end;

procedure MSet3Proc(p3:testproc);
begin
  if testlast then
    lastfld^.test3:=p3;
end;

procedure MSet1Func(p1:testfunc);
begin
  if testlast then
    lastfld^.test1:=p1;
end;


{ Valid-Fnuktion setzen }

procedure MSetVFunc(p2:testfunc);
begin
  if testlast then
    lastfld^.test2:=p2;
end;

procedure MSetUserDisp(ud:userdproc);    { bei Komplett-Neuanzeige }
begin
  amaskp^.stat.userdisp:=ud;
end;


{ Hilfszeile setzen }

procedure MH(text:string);
begin
  if testlast then
    with lastfld^ do begin
      getmem(hpline,length(text)+1);
      hpline^:=text;
      end;
end;


procedure MHnr(helpnr:word);
begin
  if testlast then
    lastfld^.helpnr:=helpnr;
end;


procedure MSelHnr(helpnr:word);
begin
  if testlast then
    lastfld^.selhelpnr:=helpnr;
end;


{ Position und L�nge (gl) der SelListe einstellen }
{ Ist xp=0, so wird die Position weiterhin automa-}
{ tisch eingestellt, weobei die Liste mindestens  }
{ len Zeilen lang ist.                            }

procedure MSetSel(sx,sy,slen:byte);
begin
  if testlast then
    with lastfld^ do begin
      slx:=sx;
      sly:=sy;
      if slx>0 then sll:=slen
      else slmin:=slen;
      noslpos:=(slx=0);
      end;
end;


{ Neue Zeilen an eine Select-Liste anh�ngen            }
{ s kann mehrere durch "�" getrennte Strings enthalten }
{ Ist force=true, so wird anhand der Listeneintr�ge    }
{ eine Valid-�berpr�fung durchgef�hrt. Force wird bei  }
{ jedem Aufruf �berschrieben; es ist also bei mehreren }
{ MAppSel und das letzte 'force' von Bedeutung.        }
{                                                      }
{ _mappsel:   interne Prozedur                         }
{ MappSel:    beim Maskenaufbau                        }
{ MAppendSel: nachtr�glich                             }


procedure _mappsel(feld:feldp; force:boolean; s:string);
var s1 : string[80];
    p  : byte;

  procedure app(var p:selnodep);
    procedure makenewel;
    begin
      new(p);
      p^.next:=nil;
      getmem(p^.el,length(s1)+1);
      p^.el^:=s1;
    end;
  begin
    if p<>nil then app(p^.next)
    else
      makenewel;     { getrennte Prozedur zur Stack-Entlastung }
  end;

begin
  with feld^ do begin
    while s<>'' do begin
      p:=pos('�',mid(s,2));
      if p=0 then p:=length(s)+1
      else inc(p);
      s1:=copy(s,1,p-1);
      if (typ>=2) and (typ<=6) then
        str(ival(s1):maxlen,s1)
      else if typ=7 then
        str(rval(s1):maxlen:nk,s1);
      s:=copy(s,p+1,255);
      app(selliste);
      end;
    forcesll:=force;
    hassel:=true;
    end;
end;


procedure mappendsel(nr:word; force:boolean; s:string);
begin
  testfield(nr);
  _mappsel(amaskp^.fld[nr],force,s);
end;


procedure MAppSel(force:boolean; s:string);
begin
  if testlast then
    _mappsel(lastfld,force,s);
end;


{ Eigene Select-Routine angeben }

procedure Mappcustomsel(cp:customsel; nedit:boolean);
begin
  if testlast then
    with lastfld^ do begin
      custom:=cp;
      nonedit:=nedit;
      hassel:=true;
      end;
end;


procedure Mnotrim;
begin
  if testlast then
    lastfld^.autotrim:=0;
end;

procedure Malltrim;
begin
  if testlast then
    lastfld^.autotrim:=2;
end;


{ spzeielle Farbe f�r Feldnamen einstellen }

procedure Mspecialcol(attr:byte);
begin
  if testlast then begin
    lastfld^.owncol:=true;
    lastfld^.ownattr:=attr;
    end;
end;


procedure MSetAutoHigh(ah:boolean);          { automat. selektieren }
begin
  if testlast then
    lastfld^.autohigh:=ah;
end;


{$I maske.inc}     { - Hauptprogramm - }


procedure readmask(var brk:boolean);
begin
  readhmask(0,brk);
end;

{ mask_helpnr = mhelpnr + afld^.helpnr }
function mask_helpnr:word;
begin
  mask_helpnr:=help_page;
end;

function readmask_active:boolean;
begin
  readmask_active:=(masks>0) and (amaskp^.editing);
end;


procedure readstring(x,y:byte; text:string; var s:string; displ,maxl:byte;
                     chml:string; var brk:boolean);
begin
  openmask(x,x+length(text)+displ+2,y,y,false);
  maskrahmen(0,0,0,0,0);
  maddstring(1,1,text,s,displ,maxl,chml);
  readmask(brk);
  closemask;
end;


function mmodified:boolean;
begin
  mmodified:=amaskp^.modified;
end;


{--------------- Externer Zugriff auf interne Felder ------------------}

procedure testfield(nr:integer);
begin
  with amaskp^ do
    if (nr<1) or (nr>felder) then
      error('illegal fieldpos: '+strs(nr));
end;


{ Inhalt eines Feldes direkt �ndern  }
{ Diese Prozedur ist f�r den Einsatz }
{ durch TEST-Prozeduren gedacht      }

procedure setfield(nr:word; newcont:string);
begin
  testfield(nr);
  with amaskp^ do begin
    with fld[nr]^ do
      cont^:=left(newcont,maxlen);
    redispfields:=true;
    modified:=true;
    end;
end;

procedure set_chml(nr:word; chml:string);
begin
  testfield(nr);
  with amaskp^.fld[nr]^ do begin
    if chml<>'' then begin
      autoup:=(chml[1]='>');
      autodown:=(chml[1]='<');
      topcase:=(chml[1]='!');
      if autoup or autodown or topcase then delete(chml,1,1);
      end
    else begin
      autoup:=false; autodown:=false; topcase:=false;
      end;
    if allowed<>nil then begin
      freemem(allowed,length(allowed^)+1);
      allowed:=nil;
      end;
    if chml<>'' then begin
      getmem(allowed,length(chml)+1);
      allowed^:=chml;
      end;
    end;
end;

{ Inhalt eines Feldes direkt abfragen }
{ siehe oben                          }

function getfield(nr:word):string;
begin
  testfield(nr);
  getfield:=amaskp^.fld[nr]^.cont^;
end;


{ W�hrend des Aufbaus einer Maske liefert fieldpos die Nummer des }
{ letzten (aktuellen) Feldes. W�hrend der Eingabe liefert es die  }
{ Nummer des aktiven Eingabefeldes, z.B. f�r F1-Hilfen.           }

function fieldpos:integer;
begin
  with amaskp^ do
    if not editing then fieldpos:=felder
    else fieldpos:=yp;
end;


{ Feld aktivieren/deaktivieren }

procedure setfieldenable(nr:word; eflag:boolean);
begin
  testfield(nr);
  with amaskp^ do
    with fld[nr]^ do
      if enabled<>eflag then begin
        enabled:=eflag;
        redispfields:=true;
        end;
end;


{ Feldbezeichnung �ndern }

procedure setfieldtext(nr:word; newtxt:string);
begin
  testfield(nr);
  with amaskp^.fld[nr]^ do begin
    freemem(txt,length(txt^)+1);
    getmem(txt,length(newtxt)+1);
    txt^:=newtxt;
    redispfields:=true;
    end;
end;


{ Textfeld �ndern }

procedure settexttext(p:pointer; newtxt:string);
begin
  with textnodep(p)^ do begin
    freemem(txt,length(txt^)+1);
    getmem(txt,length(newtxt)+1);
    txt^:=newtxt;
    redisptext:=true;
    end;
end;


procedure DefaultColor(var col:colrec);
begin
  with col do
    if color then begin
      ColBack:=7;
      ColFeldName:=3;
      ColDisabled:=8;
      ColFeldNorm:=7;
      ColFeldInput:=7;
      ColFeldActive:=$17;
      ColFeldMarked:=$20;
      ColArrows:=10;
      ColHelpTxt:=14;
      ColFnInfo:=3;
      ColFnFill:=3;
      ColSelBox:=$30;
      ColSelBar:=3;
      end
    else begin
      ColBack:=7;
      ColFeldName:=15;
      ColDisabled:=7;
      ColFeldNorm:=7;
      ColFeldInput:=7;
      ColFeldActive:=1;
      ColFeldMarked:=$70;
      ColArrows:=15;
      ColHelpTxt:=15;
      ColFnInfo:=7;
      ColFnFill:=7;
      ColSelBox:=$70;
      ColSelBar:=7;
      end;
end;


procedure masklanguage(_yesno:string);               { 'JN' }
begin
  yesno:=_yesno;
end;


{ Der Status der nullten Maske dient als Prototyp f�r alle }
{ weiteren Masken. Er kann daher zu Beginn - amask=0 -     }
{ �ber die maskset*-Funktionen eingestellt werden.         }

begin
  masks:=0; amask:=0;
  new(mask[0]);
  amaskp:=mask[0];
  with mask[0]^ do begin
    fillchar(stat,sizeof(stat),0);
    {: rahmentyp:=0;
       keeponesc:=false; autoselbox:=false;
       hpx:=0; hpy:=0; hpl:=0;
       fnix:=0; fniy:=0; fnkeyinfo:=nil;  :}
    with stat do begin
      selboxkey:=keyf2;
      fillchar:=' ';
      DefaultColor(col);
      wrapmode:=dont_wrap;
      autojump:=5;
      quitfn:=qdummyf;
      fautohigh:=true;
      end;
    fillchar(uda,sizeof(uda),0);
    end;
end.

{
  $Log: maske.pas,v $
  Revision 1.3  2000/05/25 23:07:55  rb
  Loginfos hinzugef�gt

}