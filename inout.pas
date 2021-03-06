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
{ $Id: inout.pas,v 1.11 2001/08/15 13:06:18 mm Exp $ }

(***********************************************************)
(*                                                         *)
(*                       UNIT inout                        *)
(*                                                         *)
(*             Routinen f�r Ein- und Ausgabe               *)
(*                                                         *)
(***********************************************************)


UNIT inout;

{$I XPDEFINE.INC }

{$IFDEF BP }
  {$O-,F+}
{$ENDIF }

{  ==================  Interface-Teil  ===================  }

INTERFACE

uses xpglobal,
{$IFDEF Win32 }
  windows,
{$ENDIF  }
{$ifdef vp }
  vpsyslow,vputils,
{$endif}
  dos, crt, keys, typeform, mouse, xp0;

const  lastkey   : taste = '';

       pm      : string[15] = 'Peter Mandrella';

       CapsLock   : boolean = false;
       NumLock    : boolean = false;
       ScrollLock : boolean = false;
       CapsEnable : boolean = true;
       NumEnable  : boolean = true;
       ScrollEnable:boolean = true;


       lScrollLock = $10;    { Konstanten f�r mem[$40:$17] }
       lNumLock    = $20;
       lCapsLock   = $40;

       fndeflen = 40;
       maxalt   = 10;

       maxzaehler   = 5;
       TickFreq     = 18.206512451;


type   CurType   = (curnorm,curoff,cureinf,curnone);
       EditType  = (editread,editedit,editbreak,edittabelle);
       EndeEdTyp = (enlinks,enrechts,enoben,enunten,enreturn,enno,enabbr,
                    enctrly,enctrln,enctrld,enchome,encend,enpgdn);

       slcttyp  = record
                    el : string[60];             { Auswahl-Position         }
                    zu : boolean;                { zugelassen ?             }
                    nu : longint;                { Benutzer                 }
                  end;
       slcta    = array[1..500] of slcttyp;
       pntslcta = ^slcta;
       testproc = procedure(var s:string; var ok:boolean);
       editproc = procedure(x,y:byte; var s:string; var p:shortint;
                            var en:endeedtyp);
                  { p=-1 -> nur anzeigen }
       nproc    = procedure;
       edits    = record
                    x,y,px,
                    len,art : shortint;
                    s       : string[78];
                    tproc   : testproc;
                    edproc  : editproc;
                  end;

const  fchar      : char     = '_';       { "Leerzeichen" bei ReadEd.      }
       rdedch     : taste    = '';        { ReadEdit Vorgabe f. 1. Zeichen }
       rdedactive : boolean  = false;     { ReadEdit aktiv                 }
       m2d        : boolean  = false;     { Datumsanzeige �ber multi2      }
       m2t        : boolean  = false;     { Zeitanzeige �ber multi2        }
       canf       : boolean  = true;      { Cursor bei Readedit an Anfang  }
       enlinksre  : boolean  = true;      { ReadEdit enlinks & enrechts    }
       rdedtrunc  : boolean  = true;      { Leerzeichem am Ende wegschneiden }
       esfx       : shortint = 8;         { X-Pos. f�r editsf              }
       esfy       : shortint = 9;         { Y-Pos. f�r editsf              }
       esfch      : char     = '>';       { Prompt f�r editsf              }
       curon      : curtype  = curnorm;   { Cursorform bei angesch. Cursor }
       lastcur    : curtype  = curoff;    { letzte Cursorform              }
       edm_str    : s20      = 'Monat: '; { Prompt-Text bei edmonth        }
       hotkeys    : boolean  = true;      { Hotkeys aktiviert              }
       retonfn    : taste    = '';        { liefert Get bei FN-Taste zur.  }
       readendeny : boolean  = false;     { RdEd-Ende mit ^N/^Y m�gl.      }
       einfueg    : boolean  = false;     { Einf�ge-Mode bei RdEd          }
       readblen   : byte     = 4;         { L�nge f�r readbescue           }
       key_pressed: boolean  = false;     { Taste wurde in Get gedr�ckt?   }

       mausl      : char     = #13;       { linke Maustaste                }
       mausr      : char     = #27;       { rechte Maustaste               }
       mausst     : word     = 3;         { Maske f�r Maustaste            }
       mauszuo    : boolean  = true;      { Fraigabe f�r Maus oben         }
       mauszuu    : boolean  = true;      { Freigabe f�r Maus unten        }
       mauszul    : boolean  = true;      { Freigabe f�r Maus links        }
       mauszur    : boolean  = true;      { Freigabe f�r Maus rechts       }
       mausfx     : shortint = 2;         { Maus-Faktor X                  }
       mausfy     : shortint = 1;         { Maus-Faktor Y                  }

       statposx   : shortint = 0;         { X-Pos. f�r Tast.-Stat-Anzeige  }
       statposy   : shortint = 0;         { Y-Pos. f�r Tast.-Stat-Anzeige  }
       scsavetime : integer  = 0;         { Screen-Saver Reload-Count      }
       scsavecnt  : integer  = 0;         { Screen-Saver Count             }
       dphback    : byte     = 7;         { Attribut f�r DispHard          }
       normattr   : byte     = 7;         { Screen-Attrib normtxt          }
       highattr   : byte     = 15;        { Screen-Attrib hightxt          }
       invattr    : byte     = $70;       { Screen-Attrib invtxt           }
       lowattr    : byte     = 0;         { Screen-Attrib lowtxt           }
       forcecolor : boolean  = false;     { Txt-Attribute blockieren       }

       zpz        : word     = 80;        { Zeichen pro Zeile              }
       iosclines  : byte     = 25;        { Bildschirm-Zeilen              }
       iomaus     : boolean  = true;      { wird mit mouse.maus verkn�pft  }
       UseMulti2  : boolean  = true;      { Tastatur-Warteschleife         }
       AutoUp     : boolean  = false;     { Get: automatisches KeyUp       }
       AutoDown   : boolean  = false;     { Get: automatisches KeyDown     }
       AutoupEnable   : boolean = true;
       AutodownEnable : boolean = true;
       AutoBremse : boolean  = false;     { eine Zeile pro Tick            }

       Int15Delay : byte     = 0;         { 1=int15, 2=int28, 3=HLT, 4=int2F }


var    chml : Array[1..5] of string[230];

       datex,datey,                    { Koordinaten f�r Datum und Uhrzeit }
       timex,timey  : shortint;
       fndef        : array[1..20] of string[fndeflen];
       fnproc       : array[0..3,1..10] of nproc;
       altproc      : array[1..maxalt] of record
                                            schluessel : taste;
                                            funktion   : procedure;
                                            aktiv      : boolean;
                                          end;

       base         : word;            { Screenbase                        }
       scsaveadr    : procedure;       { Screen-Saver Proc (muss alle Ak-  }
                                       { tionen selbst durchf�hren)        }
       lastattr     : byte;            { aktuelles Bildschirm-Attribut     }

       multi3       : procedure;       { Hintergrund-Proze�                }
       memerror     : nproc;           { ?!                                }
       editmsp      : integer;         { aktuelle editms-Zeile             }

       color,cga    : boolean;         { Grafik-detect                     }
       zaehler      : packed array[1..maxzaehler] of longint;
       zaehlproc    : packed array[1..maxzaehler] of procedure;


procedure Disp_DT;                              { Datum/Uhrzeit anzeigen  }
procedure SetSeconds(sec,flash:boolean);        { Sekundenanzeige ein/aus }
Procedure multi2(cur:curtype);                  { vorgeg. Backgr.-Prozess }
Procedure initscs;                              { Screen-Saver init       }

procedure IoVideoInit;                       { nach Modewechsel aufrufen! }
Procedure window(l,o,r,u:byte);              { Statt CRT.WINDOW         }
Procedure Cursor(t:curtype);                 { Cursorschalter setzen    }
Procedure GetCur(var a,e,x,y:byte);          { Cursorbereich abfragen   }
Procedure SaveCursor;                        { Cursor retten            }
Procedure RestCursor;                        { Cursor wiederherstellen  }
Procedure Get(var z:taste; cur:curtype);     { Taste einlesen           }
Procedure testbrk(var brk:boolean);          { Test auf ESC             }
Procedure waitkey(x,y:byte);                 { Taste dr�cken            }
Procedure HighTxt;                           { Textfarbe hell           }
Procedure InvTxt;                            { Textfarbe invers         }
Procedure LowTxt;                            { Textfarbe schwarz        }
Procedure NormTxt;                           { Textfarbe normal         }
Procedure AttrTxt(attr:byte);                { Textfarbe nach Attr.     }
Procedure JN(VAR c:Char; default:Char);      { J/N-Abfrage (Esc = Def.) }
Procedure JNEsc(VAR c:Char; default:Char; var brk:boolean);
                                             { J/N-Abfrage mit Esc      }
Procedure clrscr;                            { statt CRT.clrscr         }
Procedure DispHard(x,y:byte; s:string);      { String ohne ber�cksicht. }
                                             { des akt. Windows ausgeb. }
Function  CopyChr(x,y:byte):char;            { Bildschirm-Inhalt ermitt.}
Function  memadr(x,y:byte):word;             { Bild-Speicheradresse     }
procedure DosOutput;                         { auf CON: umschalten      }
function  ticker:longint;                    { mem[Seg0040:$6c]         }

{     Haupt-String-Edit-Prozedur
      x,y : Koordinaten              txt : Prompt-Text
      s   : einzulesender String     ml  : max. L�nge
      li  : erlaubte Zeichen         px  : Startposition x
      art : Edittyp (edit-read, -edit, -break, -tabelle)
      enderded : EndeEdTyp (s.o.)                           }

Procedure ReadEdit(x,y: Byte; txt: atext; VAR s:string; ml:Byte;
                   li:string; VAR px : byte; art:edittype;
                   VAR enderded:endeedtyp);

{     String-Einlese-Prozeduren
      x,y : Koordinaten                txt : Prompt-Text
      s   : einzulesender String       ml  : max. L�nge
      li  : erlaubte Zeichen (chml)    brk : Abbruch        }

{ mit Esc }
Procedure bd(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint;
             VAR brk:Boolean);
{ ohne Esc }
Procedure ed(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint);
{ Return zum �bernehmen }
Procedure ld(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint;
             invers:boolean; VAR brk:Boolean);
{ ohne Esc; auf '' setzen }
Procedure rd(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint);
procedure bdchar(x,y:byte; txt:string; var c:char; li:string; var brk:boolean);

Procedure readb(x,y:byte; VAR b:Byte);       { Byte-Zahl einlesen       }
Procedure readbesc(x,y:Byte; VAR b:Byte; VAR brk:Boolean);
Procedure readbescue(x,y:byte; VAR b:byte; VAR brk:boolean);
Procedure readi(x,y:byte; VAR i:Integer);    { Integer-Zahl einlesen    }
Procedure readiesc(x,y:Byte; VAR i:Integer; VAR brk:Boolean);
Procedure readiescue(x,y:byte; var i:integer; var brk:boolean);
Procedure readw(x,y:byte; VAR w:word);       { Word-Zahl einlesen    }
Procedure readwesc(x,y:Byte; VAR w:word; VAR brk:Boolean);
Procedure readwescue(x,y:byte; var w:word; var brk:boolean);
Procedure readl(x,y:byte; VAR l:LongInt);    { Integer-Zahl einlesen    }
Procedure readlesc(x,y:Byte; VAR l:LongInt; VAR brk:Boolean);
Procedure readlescue(x,y:byte; var l:LongInt; var brk:boolean);
Procedure readr(x,y:byte; VAR r:Real);       { Real-Zahl einlesen       }
Procedure readresc(x,y:byte; VAR r:Real; VAR brk:Boolean);
Procedure readrescue(x,y:byte; VAR r:Real; VAR brk:Boolean);

{ Form-Editier-Funktionen
  art <> 0 : Tabelle (beenden durch o,u,l,r)     }

Procedure edform(cx,cy:byte; VAR dt:datetimest;
                 f1,f2: datetimest; VAR art:shortint);
Procedure eddate(x,y:byte; VAR d:datetimest; VAR art:shortint);
Procedure edmonth(x,y:byte; VAR m:datetimest; VAR defm,defj:word;
                   var art:shortint);
Procedure edtime(x,y:byte; VAR t:datetimest; VAR art:shortint);

{ Feld-Editier-Funktionen }

procedure editsf(liste:pntslcta; n:word; var brk:boolean);
procedure dummyproc(var s:string; var ok:boolean);
procedure dummyed(x,y:byte; var s:string; var p:shortint; var en:EndeEdTyp);
procedure editms(n:integer; var feld; eoben:boolean; var brk:boolean);

Procedure mausiniti;                 { Maus nach Bildschirmmitte             }
procedure dummyFN;
procedure mdelay(msec:word);


{ ================= Implementation-Teil ==================  }

IMPLEMENTATION


uses
  maus2, winxp;

const  maxsave     = 50;  { max. f�r savecursor }

      __st : string[8] = '  :  :  ';    { f�r M2T }
      __sd : string[8] = '  .  .  ';    { f�r M2D }
      timeflash : boolean = false;
      getactive : boolean = false;

type   editsa      = array[1..500] of edits;   { nur f�r Type Cast }

var    ca,ce,ii,jj : byte;
       sx,sy,sa,se,
       wl,wr,wo,wu : array[1..maxsave] of byte;
       mwl,mwo,
       mwr,mwu     : byte;
       cursp       : shortint;
       oldexit     : pointer;
       sec         : word;
       mx,my       : integer;      { Maus-Koordinaten }
       st1         : byte;
       fnpactive   : array[0..3,1..10] of boolean;
       istack      : array[1..maxalt] of byte;
       istackp     : integer;
       autolast    : longint;   { Get: Tick des letzten AutoUp/Down }

function ticker:longint;
{$IFDEF Ver32 }
var
  h, m, s, hund : rtlword;
{$ENDIF }
begin
{$IFDEF Ver32 }
  GetTime(h, m, s, hund);
  Ticker := system.round(((longint(h*60 + m)*60 + s) * TickFreq) +
    (hund / (100 / TickFreq)));
{$ELSE }
  ticker:=meml[Seg0040:$6c];
{$ENDIF}
end;

{ !! Diese Funktion lieft mit and $70 nur CAPSLock zur�ck,
  das kann nicht sinn der Sache sein. Mu� gepr�ft werden }
{$IFDEF BP }
Function kbstat:byte;     { lokal }
begin
  kbstat:=mem[Seg0040:$17] and $70;
end;
{$ENDIF }

Procedure window(l,o,r,u:byte);
begin
  mwl:=l; mwr:=r;
  mwo:=o; mwu:=u;
  crt.window(l,o,r,min(u,25));
  if (l=1) and (o=1) and (r=80) and (u=25) then
    crt.windmax:=zpz-1 {crt.windmax and $ff} + 256*iosclines
  else
    crt.windmax:=crt.windmax and $ff + 256*(u-1);
end;


{$IFDEF BP }
Procedure CurLen(a,e:byte); assembler;
asm
  mov ah, 1
  mov ch, a
  mov cl, e
  int $10
end;
{$ENDIF }

Procedure Cursor(t:curtype);
begin
{$IFDEF BP }
  case t of
    curnorm : curlen(ca,ce);
    curoff  : curlen(ca+$20,ce);
    cureinf : curlen(max(ca-4,1),ce);
  end;
{$ELSE }
  {$IFDEF FPC }
    case t of
      curnorm : CursorOn;
      curoff  : CursorOff;
      cureinf : CursorBig;
    end;
  {$ENDIF }
  {$IFDEF VP }
    case t of
      curnorm : showcursor;
      curoff  : hidecursor;
      cureinf : SetCursorSize( 8,15 );
    end;
  {$ENDIF }
{$ENDIF }
    lastcur:=t;
end;

{$IFDEF FPC }
  {$HINTS OFF }
{$ENDIF }

Procedure GetCur(var a,e,x,y:byte);
begin
{$IFDEF BP }
  asm
        mov ah, 3
        mov bh, 0
        int $10
        and ch, $7f
        les di, a
        mov es:[di], ch
        and cl, $7f
        les di, e
        mov es:[di], cl
  end;
{$ENDIF }
  x :=wherex; y:=wherey;
end;

{$IFDEF FPC }
  {$HINTS ON }
{$ENDIF }

Procedure SaveCursor;

begin
  inc(cursp);
  if cursp>maxsave then cursp:=1;
  getcur(sa[cursp],se[cursp],sx[cursp],sy[cursp]);
  wo[cursp]:=mwo; wu[cursp]:=mwu;
  wl[cursp]:=mwl; wr[cursp]:=mwr;
end;


Procedure RestCursor;
begin
  cursor(curoff);
  window(wl[cursp],wo[cursp],wr[cursp],wu[cursp]);
  gotoxy(sx[cursp],sy[cursp]);
{$IFDEF BP }
  curlen(sa[cursp],se[cursp]);
{$ENDIF }
  dec(cursp);
  if cursp<1 then cursp:=maxsave;
end;

Procedure cursoron;
begin
  exitproc:=oldexit;
  cursor(curon);
end;

procedure initscs;
begin
  scsavecnt:=scsavetime;
end;


procedure SetSeconds(sec,flash:boolean);          { Sekundenanzeige ein/aus }
begin
  if sec then __st:='  :  :  '
  else __st:='  :  ';
  timeflash:=flash;
end;


procedure disp_DT;
var h,m,s,s100 : rtlword;
    y,mo,d,dow : rtlword;
begin
  if UseMulti2 then begin
    if m2t then begin
      gettime(h,m,s,s100);
      __st[1]:=chr(h div 10+48);
      __st[2]:=chr(h mod 10+48);
      __st[4]:=chr(m div 10+48);
      __st[5]:=chr(m mod 10+48);
      if length(__st)>5 then begin
        __st[7]:=chr(s div 10+48);
        __st[8]:=chr(s mod 10+48);
        end
      else
        if timeflash then __st[3]:=iifc(odd(s),':',' ');
      disphard(timex,timey,' '+__st+' ');
      end;
    if m2d then begin
      getdate(y,mo,d,dow);
      y := y mod 100;                { Jahr-2000-Fix; 4.7.99 }
      __sd[1]:=chr(d div 10+48);
      __sd[2]:=chr(d mod 10+48);
      __sd[4]:=chr(mo div 10+48);
      __sd[5]:=chr(mo mod 10+48);
      __sd[7]:=chr(y div 10+48);
      __sd[8]:=chr(y mod 10+48);
      disphard(datex,datey,__sd);
      end;
    end;
end;

{&optimize-}
Procedure multi2;
var h,m,s,s100 : rtlword;
    i          : integer16;
    l          : longint;
begin
  gettime(h,m,s,s100);
  if s<>sec then begin
    disp_DT;
    sec:=s;
    if getactive and (scsavecnt<>0) then begin
      dec(scsavecnt);
      if (scsavecnt=0) and (@scsaveadr<>@dummyFN) then
        scsaveadr;
      end;
      for i:=1 to maxzaehler do
        if zaehler[i]>0 then
        begin
          dec(zaehler[i]);
          FastMove(Zaehlproc[i],l, 4);
          if (zaehler[i]=0) and (l <> 0) then
            Zaehlproc[i];
         end;
    end;
  multi3;
end;
{&optimize+}


procedure showstatus(do_rest:boolean);
{$IFDEF BP }

const stt : array[1..3] of string[8]  = (' CAPS ',' NUM ',' SCROLL ');
      stm : array[1..3] of string[16] = ('','','');

var   x   : boolean;

  procedure stput(pos,len,nr:byte);
  begin
    moff;
    FastMove(mem[base:memadr(statposx+pos,statposy)],stm[nr],len*2);
    SaveCursor;
    InvTxt;
    wrt(statposx+pos,statposy,stt[nr]);
    NormTxt;
    RestCursor;
    mon;
  end;

  procedure strest(pos,len,nr:byte);
  begin
    if do_rest then
      FastMove(stm[nr],mem[base:memadr(statposx+pos,statposy)],2*len)
    else
      FastMove(mem[base:memadr(statposx+pos,statposy)],stm[nr],2*len);
  end;

begin
  if (statposx=0) or (statposy=0) then exit;

  x:=(kbstat and $40)<>0;
  if CapsEnable and (CapsLock<>x) then begin
    CapsLock:=x;
    if CapsLock then stput(0,6,1) else strest(0,6,1);
    end;
  x:=(kbstat and $20)<>0;
  if NumEnable and (NumLock<>x) then begin
    NumLock:=x;
    if NumLock then stput(6,5,2) else strest(6,5,2);
    end;
  x:=(kbstat and $10)<>0;
  if ScrollEnable and (ScrollLock<>x) then begin
    ScrollLock:=x;
    if ScrollLock then stput(11,8,3) else strest(11,8,3);
    end;

  st1:=kbstat;
{$ELSE }
begin

{$ENDIF }
end;


procedure dummyFN;
begin
end;


Procedure Get(VAR z:taste; cur:curtype);
VAR c       : Char;
    i       : byte;
    mox,moy : integer;

  procedure dofunc(state,nr:byte);
  var p  : procedure;
      la : byte;
      r1 : taste;
  begin
    la:=lastattr; normtxt;
    p:=fnproc[state,nr];
    if (@p<>@dummyFN) and
       (not fnpactive[state,nr]) then begin
      fnpactive[state,nr]:=true;
      savecursor;
      window(1,1,80,25);
      r1:=retonfn; retonfn:='';
      p;
      retonfn:=r1;
      restcursor;
      fnpactive[state,nr]:=false;
      z:=retonfn;
      if z='' then z:='!!';
      end;
    attrtxt(la);
  end;

  procedure doaltfunc(i:byte);
  var p  : procedure;
      r1 : taste;
  begin
    inc(istackp);
    istack[istackp]:=i;
    p:=altproc[istack[istackp]].funktion;
    altproc[istack[istackp]].aktiv:=true;
    savecursor;
    window(1,1,80,25);
    r1:=retonfn; retonfn:='';
    p;
    retonfn:=r1;
    restcursor;
    altproc[istack[istackp]].aktiv:=false;
    dec(istackp);
    z:=retonfn;
    if z='' then z:='!!';
  end;

begin
{$IFDEF OS2 }
  SetKbd_BinMode;
{$ENDIF }
  if autoup or autodown then begin
    if AutoBremse then
      repeat until autolast<>ticker;
    if autoup and autoupenable then z:=keyup
    else if autodown and autodownenable then z:=keydown
    else z:=#0#0;
    autolast:=ticker;
    exit;
    end;
  repeat
    cursor(cur);
    initscs;
    if UseMulti2 then begin
      repeat
        st1:=kbstat;
        mox:=mausx; moy:=mausy;
        while not keypressed and
              not (maus and iomaus and ((maust and mausst)<>0)) and not
              (maus and iomaus and ((mox-mx>=8*mausfx) or (mox<mx) or (moy-my>=8*mausfy) or (moy<my)))
              and not (kbstat<>st1) do begin
          getactive:=true;
          multi2(cur);
          getactive:=false;
          if maus and iomaus and ((mox<=8*mausfx-1) or (mox>=640-8*mausfx) or
                       (moy<=8*mausfy-1) or (moy>=200-8*mausfx)) then begin
            mausiniti;
            mox:=mx; moy:=my;
          end
          else begin
            mox:=mausx; moy:=mausy;
          end;
          if ParWintime>0 then mdelay(0);
        end;
        z:=#255;
        if maus and iomaus and (maust and mausst<>0) then begin
          while maust and mausst and 1=1 do z:=mausl;
          while maust and mausst and 2=2 do z:=mausr;
          exit;
          end;
        if maus and iomaus then begin
           if (mox-mx>=8*mausfx) or (mox<mx) or (moy-my>=8*mausfy) or (moy<my) then begin
            if mox-mx>=8*mausfx then begin
              inc(mx,8*mausfx);
              if mauszur then z:=keyrght;
              end else
            if mox<mx then begin
              dec(mx,8*mausfx);
              if mauszul then z:=keyleft;
              end else
            if moy-my>=8*mausfy then begin
              inc(my,8*mausfy);
              if mauszuu then z:=keydown;
              end else
            if moy<my then begin
              dec(my,8*mausfy);
              if mauszuo then z:=keyup;
              end;
            end
          end;
        if (kbstat<>st1) and (statposx<>0) then begin
          showstatus(true);
          z:=#0#0;
          exit;
          end;
      until (z<>#255) or keypressed;   { KEYS.keypressed! }
      key_pressed:=true;
      if not keypressed then begin
        cursor(curoff);
        exit;
        end;
      end
    else
      key_pressed:=true;
    c:=readkey;
    if c=#31 then
      z:='!!'   { s. MAUS2.mint }
    else begin
      z[1]:=c;
      IF (c<>#0) THEN
        z[0]:=#1
      ELSE begin
        c:=readkey;
        z[2]:=c;
        z[0]:=#2;
        end;
      end;
    cursor(curoff);
    lastkey:=z;
    if hotkeys then
      if (z>=keyf1)  and (z<=keyf10)  then dofunc(0,ord(z[2])-58) else
      if (z>=keysf1) and (z<=keyaf10) then
        dofunc((ord(z[2])-74) div 10,(ord(z[2])-84)mod 10+1)
      else
        for i:=1 to maxalt do
          if (@altproc[i].funktion<>@dummyFN) and (z=altproc[i].schluessel)
            and (not altproc[i].aktiv) then
              doaltfunc(i);
  until z<>'!!';
end;

{$IFDEF BP }
function BiosWord(off:word):word;
begin
  BiosWord:=memw[Seg0040:off];
end;
{$ENDIF}

Procedure testbrk(var brk:boolean);
{$IFDEF BP }
const k1     = $1a;
      k2     = $1c;
      bstart = $80;
      bend   = $82;
var   t      : taste;
      k      : word;
begin
  brk:=false;
  if BiosWord(k1)<>BiosWord(k2) then begin
    k:=BiosWord(k1);
    while (k<>BiosWord(k2)) and not brk do begin
      t:=chr(mem[Seg0040:k]);
    { if t=#0 then t:=t+chr(mem[$40:k+1]);  Sondertasten hier nicht n�tig }
      brk:=(t=keyesc);
      inc(k,2); if k>BiosWord(bend) then k:=BiosWord(bstart);
      end;
    if brk then clearkeybuf;
    end;
{$ELSE }
begin
  brk := false;
  if keypressed then brk := (readkey = keyesc);
{$ENDIF }
end;


Procedure AttrTxt(attr:byte);
begin
  if forcecolor then exit;
  textcolor(attr and $8f);
  textbackground((attr and $7f) shr 4);
  lastattr:=attr;
end;


Procedure InvTxt;
begin
  AttrTxt(invattr);
end;


Procedure NormTxt;
begin
  AttrTxt(normattr);
end;


Procedure LowTxt;
begin
  AttrTxt(LowAttr);
end;


Procedure HighTxt;
begin
  AttrTxt(HighAttr);
end;


Procedure clrscr;
{$ifndef ver32}
var regs : registers;
{$endif}
begin
  {$ifndef ver32}
  regs.ax:=$500;      { Video-Seite 0 setzen }
  intr($10,regs);
  {$endif}
  crt.clrscr;
end;


Procedure Wrt(x,y:byte; s:string);
begin
  gotoxy(x,y);
  write(s);
end;


Procedure disphard(x,y:byte; s:string);
var
{$IFDEF BP }
  offx : word;
  i    : byte;
  back : word;
{$ENDIF }
    TempAttr: Word;
begin
{$IFDEF Ver32 }
  TempAttr := TextAttr;
  TextAttr := dphback;
{$ENDIF }
  moff;
{$IFDEF BP }
  back:=dphback shl 8;
  offx:=memadr(x,y);
  for i:=1 to length(s) do begin
    memw[base:offx]:=byte(s[i])+back;
    inc(offx,2);
  end;
{$ELSE }
  FWrt(x, y, s);
  TextAttr := TempAttr;
{$ENDIF}
  mon;
end;


procedure jnread(var c:char);     { lokal }
var t : taste;
begin
  moff;
  Write(' (J/N) ? ',UpCase(c),#8);
  mon;
  repeat
    get(t,curon);
    c:=UpCase(t[1]);
  until c IN ['J','N',#13,#27];
  if (c<>#27) and (c<>#13) then begin
    moff; write(c); mon; end;
end;


Procedure JN(VAR c:Char; default:Char);
begin
  c:=default;
  jnread(c);
  if (c=#13) or (c=#27) then c:=default;
end;


Procedure JNEsc(VAR c:Char; default:Char; var brk:boolean);
begin
  c:=default;
  jnread(c);
  if c=#13 then c:=default;
  brk:=(c=#27);
end;


{ li = '>>...' : automatische Gro�schreibung }

Procedure ReadEdit(x,y: Byte; txt: atext; VAR s:string; ml:Byte;
                   li:string; VAR px : byte; art:edittype;
                   VAR enderded:endeedtyp);

const trennz  = [' ','&','('..'/',':'..'?','['..'`','{'..#127];

VAR   p: byte; { MK 02/00 Spart Vergleiche signed/unsigned }
      fnkn  : shortint;
      a       : taste;
      inss    : string[80];
      ste     : string;
      mlm,mrm : boolean;
      r1      : taste;
      autogr  : boolean;

begin
  rdedactive:=true;
  mlm:=mauszul; mrm:=mauszur;
  r1:=retonfn; retonfn:=#1#1;
  enderded:=enno;
  if left(li,2)='>>' then begin
    autogr:=true;
    delete(li,1,2);
    end
  else autogr:=false;
  mwrt(x,y,txt);
  x:=x+length(txt);
  IF art=editread then s:='' ELSE s:=Copy(s,1,ml);
  if art<>edittabelle then
    WHILE s[length(s)]=' ' DO dellast(s);
  p:=min(px,length(s));
  if not canf then
    IF art<>edittabelle THEN p:=p+length(s);
  REPEAT
    if readendeny then s:=forms(s,ml);
    if einfueg then
      curon:=cureinf
    else
      curon:=curnorm;
    mwrt(x,y,s+dup(ml-length(s),fchar));
    GotoXY(x+p,y);
    mauszul:=(p>0);
    mauszur:=(p<length(s)-1);
    if rdedch='' then
      Get(a,curon)
    else begin
      a:=rdedch; rdedch:='';
      end;
    IF (a=',') and (li=chml[3]) THEN a:='.';
    IF a=keybs   THEN begin
                   IF p>0 THEN begin
                     delete(s,p,1);
                     p:=pred(p);
                     end
                   ELSE
                     IF art=edittabelle THEN enderded:=enlinks
                   end;
    IF a=keyleft THEN begin
                   IF p>0 THEN p:=pred(p) ELSE
                   IF (art=edittabelle) and enlinksre THEN enderded:=enlinks
                   end ELSE
    IF a=keydel  THEN begin
                   if p<length(s) then delete(s,succ(p),1)
                   end ELSE
    if a=keyctt  then begin
                   if p<length(s) then begin
                     if s[succ(p)]=' ' then
                       while (s[succ(p)]=' ') and (p<length(s)) do
                         delete(s,p+1,1)
                     else
                     if s[succ(p)] in trennz then
                       delete(s,p+1,1)
                     else begin
                       while (not (s[succ(p)] in trennz)) and (p<length(s)) do
                         delete(s,p+1,1);
                       if p<length(s) then begin
                         if s[succ(p)]=' ' then
                           while (s[succ(p)]=' ') and (p<length(s)) do
                             delete(s,p+1,1)
                         else
                         if s[succ(p)] in trennz then
                           delete(s,p+1,1);
                         end;
                       end;
                     end;
                   end else
    IF a=keyrght THEN begin
                   IF p<length(s) THEN p:=succ(p) ELSE
                   if (art=edittabelle) and enlinksre then enderded:=enrechts;
                   IF (p=ml) AND (art=edittabelle) THEN enderded:=enrechts;
                   end ELSE
    IF a=keyclft THEN begin
                        if (p=0) then begin
                          if art=edittabelle then enderded:=enlinks;
                          end
                        else
                          repeat
                            dec(p);
                          until (p=0) or ((s[p+1]<>' ') and (s[p]=' '));
                      end ELSE
    IF a=keycrgt THEN begin
                        if (p=length(s)) then begin
                          if art=edittabelle then enderded:=enrechts;
                          end
                        else begin
                          repeat
                            inc(p);
                          until (p=length(s)) or ((s[p]=' ') and (s[p+1]<>' '));
                          IF (p=ml) AND (art=edittabelle) THEN enderded:=enrechts;
                          end;
                        end ELSE
    IF a=keyhome THEN p:=0 ELSE
    IF a=keyend  THEN begin
                        if (art=edittabelle) and (fchar=' ') then begin
                          p:=length(s);
                          while (p>0) and (s[p]=' ') do
                            dec(p);
                          end
                        else p:=length(s);
                      end ELSE
    IF a=keyesc  THEN begin
                   if art<>editread then enderded:=enabbr;
                   end ELSE
    IF a=keyup   THEN begin
                   IF art=edittabelle THEN enderded:=enoben;
                   end ELSE
    IF a=keydown THEN begin
                   IF art=edittabelle THEN enderded:=enunten;
                   end ELSE
    if (a=keypgdn) or (a=#10) then begin
                   if art=edittabelle then enderded:=enpgdn;
                   end else
    if a=keyins  then
                   einfueg:=not einfueg
                   else
    if ((a>=keyf1) and (a<=keyf10)) or
       ((a>=keysf1) and (a<=keysf10)) then begin
                   if a<=keyf10 then
                     fnkn:=ord(a[2])-58
                   else
                     fnkn:=ord(a[2])-73;
                   if fndef[fnkn]<>'' then begin
                     if right(fndef[fnkn],1)=';' then
                       inss:=left(fndef[fnkn],length(fndef[fnkn])-1)
                     else
                       inss:=fndef[fnkn];
                     if einfueg then
                       s:=left(left(s,p)+inss+copy(s,succ(p),255),ml)
                     else
                       s:=left(left(s,p)+
                               inss+copy(s,succ(p)+length(inss),255),ml);
                     p:=min(p+length(inss),length(s));
                     if right(fndef[fnkn],1)=';' then
                       a:=keycr;
                     end;
                 end else begin
      ste:=s; ste[succ(p)]:=' ';
      if autogr then a:=UStr(a);
      IF (POS(a,li)>0) AND (p<ml) AND
         (NOT ((li=chml[2]) AND (p>0) AND (a='-'))) AND
         (NOT ((li=chml[2]) AND (POS('.',ste)>0) AND (a='.'))) THEN begin
         p:=succ(p);
         if einfueg then begin
           ste:=s;
           insert(a,ste,p);
           s:=copy(ste,1,ml);
           end
         else
           if p>length(s) then
             s:=s+a
           else
             s[p]:=a[1];
         IF (p=ml) AND (art=edittabelle) THEN enderded:=enrechts;
         end;
       end;
    if (a=keyctn) and readendeny then enderded:=enctrln;
    if (a=keycty) then
      if readendeny then enderded:=enctrly
      else begin
        s:=''; p:=0;
        end;
    if (a=^D) and readendeny then enderded:=enctrld;
    if ((a=keychom) or (a=keypgup)) and readendeny then enderded:=enchome;
    if ((a=keycend) or (a=keypgdn)) and readendeny then enderded:=encend;
  UNTIL (a=keycr) OR (enderded<>enno);
  IF art=edittabelle THEN
    IF a=keycr THEN px:=0 ELSE px:=p;
  IF a=keycr THEN enderded:=enreturn;
  mwrt(x,y,s+sp(ml-length(s)));
  if (art<>edittabelle) and rdedtrunc then
    while s[length(s)]=' ' do dellast(s);
  curon:=curnorm;
  retonfn:=r1;
  mauszul:=mlm; mauszur:=mrm;
  rdedactive:=false;
end;


Procedure ed(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint);

VAR dummy:endeedtyp;
    px   :byte;

begin
  px:=0;
  ReadEdit(x,y,txt,s,ml,chml[li],px,editedit,dummy);
end;


Procedure rd(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint);

VAR dummy:endeedtyp;
    px   :byte;

begin
  px:=0;
  ReadEdit(x,y,txt,s,ml,chml[li],px,editread,dummy);
end;


Procedure bd(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint;
             VAR brk:Boolean);

VAR px      : byte;
    abbruch : endeedtyp;

begin
  px:=0;
  ReadEdit(x,y,txt,s,ml,chml[li],px,editbreak,abbruch);
  IF abbruch=enabbr THEN brk:=True ELSE brk:=False;
end;


Procedure ld(x,y:byte; txt:string; VAR s:string; ml:Byte; li:shortint;
             invers:boolean; VAR brk:Boolean);

VAR
    a      : taste;
    la  : byte;

begin
  brk:=false;
  moff;
  wrt(x,y,txt);
  la:=lastattr;
  if invers then InvTxt; write(s);
  if invers then AttrTxt(la);
  write(dup(ml-length(s),fchar));
  mon;
  gotoxy(x+length(txt),y);
  Get(a,curon);
  IF a<>keycr THEN begin
    IF a=keyesc THEN brk:=True ELSE begin
      rdedch:=a;
      if pos(a,chml[li])>0 then s:='';
      bd(x,y,txt,s,ml,li,brk);
      end;
    end
  ELSE
    mwrt(x,y,txt+s+sp(ml-length(s)));
end;


Procedure readi(x,y:byte; VAR i:Integer);

VAR res: Integer;
    s  : string;

begin
  repeat
    rd(x,y,'',s,5,3);
    if s='' then
      res:=0
    else
      val(trim(s),i,res);
  until res=0;
end;


Procedure readiesc(x,y:byte; VAR i:Integer; VAR brk:boolean);

VAR res: Integer;
    s  : string;

begin
  repeat
    s:='';
    bd(x,y,'',s,5,3,brk);
    if s='' then
      res:=0
    else
      val(trim(s),i,res);
  until res=0;
end;


Procedure readiescue(x,y:byte; VAR i:Integer; VAR brk:boolean);

VAR res: Integer;
    s  : string;

begin
  repeat
    str(i,s);
    bd(x,y,'',s,5,3,brk); if brk then exit;
    val(trim(s),i,res);
  until res=0;
end;


Procedure readw(x,y:byte; VAR w:word);
begin
  readi(x,y,integer(w));
end;


Procedure readwesc(x,y:Byte; VAR w:word; VAR brk:Boolean);
begin
  readiesc(x,y,integer(w),brk);
end;


Procedure readwescue(x,y:byte; var w:word; var brk:boolean);
begin
  readiescue(x,y,integer(w),brk);
end;


Procedure readl(x,y:byte; VAR l:LongInt);

VAR res: Integer;
    s  : string;

begin
  repeat
    rd(x,y,'',s,9,3);
    if s='' then
      res:=0
    else
      val(trim(s),l,res);
  until res=0;
end;


Procedure readlesc(x,y:byte; VAR l:LongInt; VAR brk:boolean);

VAR res: Integer;
    s  : string;

begin
  repeat
    s:='';
    bd(x,y,'',s,5,3,brk);
    if s='' then
      res:=0
    else
      val(trim(s),l,res);
  until res=0;
end;


Procedure readlescue(x,y:byte; VAR l:LongInt; VAR brk:boolean);

VAR res: Integer;
    s  : string;

begin
  repeat
    str(l,s);
    bd(x,y,'',s,5,3,brk); if brk then exit;
    val(trim(s),l,res);
  until res=0;
end;


Procedure readb(x,y:byte; VAR b:byte);

var i : integer;

begin
  i:=b;
  repeat
    readi(x,y,i);
  until (i>=0) and (i<=255);
  b:=i;
end;


Procedure readbesc(x,y:Byte; VAR b:Byte; VAR brk:Boolean);

var i : integer;

begin
  i:=b;
  repeat
    readiesc(x,y,i,brk);
    if brk then exit;
  until (i>=0) and (i<=255);
  b:=i;
end;


Procedure readbescue(x,y:byte; VAR b:byte; VAR brk:boolean);

VAR res,i: Integer;
    s    : string;

begin
  repeat
    str(b,s);
    bd(x,y,'',s,readblen,3,brk); if brk then exit;
    val(trim(s),i,res);
  until (res=0) and (i<=255);
  b:=i;
end;


Procedure readr(x,y:byte; VAR r:Real);

VAR res:Integer;
    s  :string;

begin
  repeat
    rd(x,y,'',s,9,2);
    if s='' then
      res:=0
    else
      val(trim(s),r,res);
  until res=0;
end;


Procedure readresc(x,y:byte; VAR r:Real; VAR brk:boolean);

VAR res:Integer;
    s  :string;

begin
  repeat
    s:='';
    bd(x,y,'',s,9,2,brk);
    if s='' then
      res:=0
    else
      val(trim(s),r,res);
  until res=0;
end;


Procedure readrescue(x,y:byte; VAR r:Real; VAR brk:boolean);

VAR res:Integer;
    s  :string;

begin
  repeat
    s:=strsr(r,5);
    while s[length(s)]='0' do
      dellast(s);
    if s[length(s)]='.' then dellast(s);
    while (s<>'') and (s[1]=' ') do
      delfirst(s);
    bd(x,y,'',s,9,2,brk);
    val(trim(s),r,res);
  until res=0;
end;


Procedure edform(cx,cy:byte; VAR dt:datetimest;
                 f1,f2: datetimest; VAR art:shortint);

VAR min1,min2,min3,max1,
    max2,max3               : String[4];
    endeed,ml,l,p,minpos,rl : Integer;
    a                       : taste;
    trz                     : Char;
    x                       : datetimest;

begin
  trz:=f1[3];
  if trz='/' then minpos:=3 else minpos:=0;
  rl:=length(f1)-minpos;
  ml:=length(f2);
  if trz=':' then begin
    dec(rl,3); dec(ml,3); end;
  l:=ml-6;
  min1:=Copy(f1,1,2); max1:=Copy(f2,1,2);
  min2:=Copy(f1,4,2); max2:=Copy(f2,4,2);
  min3:=Copy(f1,7,l); max3:=Copy(f2,7,l);
  p:=minpos; endeed:=0;
  REPEAT
    moff;
    GotoXY(cx,cy); Write(copy(dt,succ(minpos),rl)); GotoXY(cx+p-minpos,cy);
    mon;
    Get(a,curon);
    IF a=keyesc THEN
      endeed:=-1
    ELSE IF a=keyup THEN begin
      IF art>0 THEN endeed:=1;
      end
    ELSE IF a=keydown THEN begin
      IF art>0 THEN endeed:=2;
      end
    ELSE IF (a=keyleft) OR (a=keybs) THEN
      IF p>minpos THEN
        IF f1[p]=trz THEN p:=p-2 ELSE p:=pred(p)
      ELSE begin
        IF art>0 THEN endeed:=3;
        end
    ELSE IF a=keyrght THEN
      IF p<ml THEN
        IF (f1[p+2]=trz) and (p<pred(ml)) THEN p:=p+2 ELSE p:=succ(p)
      ELSE begin
        IF art>0 THEN endeed:=4;
        end
    ELSE IF a=keycr THEN
      endeed:=5  { 2 ? }
    ELSE IF a=keyhome THEN
      p:=minpos
    ELSE IF a=keyend THEN
      p:=ml
    ELSE if (a=keypgdn) and (art>0) then
      endeed:=6
    ELSE IF a[1]=trz THEN begin
      IF p<3 THEN p:=3 ELSE IF (p<6) and (6<ml) THEN p:=6;
      end
    ELSE begin
      IF (Pos(a,'0123456789')>0) AND (p<ml) THEN begin
        x:=dt;
        x[succ(p)]:=a[1];
        IF (x[1]>=f1[1]) AND (x[1]<=f2[1]) AND (x[4]>=f1[4]) AND
           (x[4]<=f2[4]) AND (x[7]>=f1[7]) AND (x[7]<=f2[7]) THEN begin
          IF Copy(x,1,2)<min1 THEN begin x[1]:=min1[1]; x[2]:=min1[2]; end;
          IF Copy(x,4,2)<min2 THEN begin x[4]:=min2[1]; x[5]:=min2[2]; end;
          IF Copy(x,7,l)<min3 THEN x:=Copy(x,1,6)+min3;
          IF Copy(x,1,2)>max1 THEN x[2]:='0';
          IF Copy(x,4,2)>max2 THEN x[5]:='0';
          IF Copy(x,7,l)>max3 THEN x:=Copy(x,1,7)+dup(pred(l),'0');
          dt:=x;
          IF (f1[p+2]=trz) and (p<pred(ml)) THEN p:=p+2 ELSE p:=succ(p);
          end;
        end;
      IF p>ml THEN endeed:=4;
    end;
  UNTIL endeed<>0;
  mwrt(cx,cy,copy(dt,succ(minpos),rl));
  IF art<>0 THEN art:=endeed ELSE
    IF endeed=-1 THEN art:=-1 ELSE art:=0;
end;


Procedure eddate(x,y:byte; VAR d:datetimest; VAR art:shortint);

begin
  IF d='' THEN d:=date;
  edform(x,y,d,'01.01.1000','31.12.2199',art);
end;



Procedure edtime(x,y:byte; VAR t:datetimest; VAR art:shortint);

begin
  IF t='' THEN t:=time;
  edform(x,y,t,'00:00:00','24:59:59',art);
end;


Procedure edmonth(x,y:byte; VAR m:datetimest; VAR defm,defj:word;
                  var art:shortint);

begin
  mwrt(x,y,edm_str);
  art:=0;
  m:='02/'+formi(defm,2)+'/'+formi(defj,4);
  edform(x+length(edm_str),y,m,'01/01/1000','31/12/2199',art);
  m:=Copy(m,4,7);
end;


procedure editsf(liste:pntslcta; n:word; var brk:boolean);

var px,ml,i : byte;
    en      : endeedtyp;
    p       : word;

  procedure clearout;
  var i,l : byte;
  begin
    for i:=esfy to esfy+n-1 do begin
      l:=liste^[i-esfy+1].nu;
      wrt(esfx,i,sp(l));
      end;
  end;

begin
  moff;
  clearout;
  for i:=1 to n do
    wrt(esfx,i+pred(esfy),iifs(esfch='*','',esfch+' ')+liste^[i].el);
  mon;
  px:=0; p:=1; brk:=false;
  repeat
    ml:=liste^[p].nu;
    readedit(esfx+iif(esfch='*',0,2),p+pred(esfy),'',liste^[p].el,
             ml,chml[1],px,edittabelle,en);
    case en of
      enlinks  : begin px:=60; dec(p); end;
      enrechts,
      enreturn : begin px:=0; inc(p); end;
      enoben   : dec(p);
      enunten  : inc(p);
      enabbr   : brk:=true;
      enpgdn   : p:=succ(n);
    end;
  until (p<1) or (p>n) or brk;
end;

{$IFDEF FPC }
  {$HINTS OFF }
{$ENDIF }

procedure dummyproc(var s:string; var ok:boolean);
begin
  ok:=true;
end;

procedure dummyed(x,y:byte; var s:string; var p:shortint; var en:endeedtyp);
begin
  en:=enabbr;
end;

{$IFDEF BP}
procedure dummy; interrupt;
begin
end;
{$ENDIF}

{$IFDEF FPC }
  {$HINTS ON }
{$ENDIF }


procedure editms(n:integer; var feld; eoben:boolean; var brk:boolean);

const m1 : shortint = -1;
var i,pl   : integer;
    en,en2 : endeedtyp;
    ok     : boolean;

{ art: 0 = links; 1 = fest/Feld; 2 = fest/insgesamt }

begin
  for i:=1 to n do
    with editsa(feld)[i] do
      px:=0;
  editmsp:=1; pl:=0; brk:=false;
  repeat
    moff;
    for i:=1 to n do
      with editsa(feld)[i] do
        if len>0 then wrt(x,y,forms(s,len))
        else if len=0 then edproc(x,y,s,m1,en2);
    mon;
    with editsa(feld)[editmsp] do begin
      case art of
        0 : px:=0;
        1 : px:=px;
        2 : px:=min(pl,length(s));
      end;
      if len=-1 then
        begin end          { �berspringen }
      else if len=0 then
        edproc(x,y,s,px,en)
      else begin
        readedit(x,y,'',s,len,chml[1],byte(px),edittabelle,en);
        while s[length(s)]=' ' do dellast(s);
        end;
      pl:=px;
      if en=enabbr then brk:=true else begin
        tproc(s,ok); if not ok then en:=enno;
        end;
      if (len=1) and (en=enrechts) and (lastkey<>keyrght) then en:=enno;
      if len>0 then mwrt(x,y,s)
      else edproc(x,y,s,m1,en2);
      case en of
        enlinks,
        enoben    : if editmsp>1 then dec(editmsp);
        enrechts,enunten,
        enreturn  : inc(editmsp);
        enpgdn    : editmsp:=succ(n);
      end;
    end;
    while (editmsp<=n) and (editmsp>1) and (editsa(feld)[editmsp].len=-1) do
      if (en=enlinks) or (en=enoben) then dec(editmsp)
      else inc(editmsp);
  until ((editmsp<1) and eoben) or (editmsp>n) or brk;
end;


Function chkn:longint;      { lokal }
begin
  chkn:=26690;
end;

procedure chalt;
{$IFDEF BP }
var x,y : byte;
    regs: registers;
    buf : array[1..512] of byte;
begin
  sound(9000);
  attrtxt(7);
  clrscr;
  cursor(curoff);
  checkbreak:=false;
  setintvec(9,@dummy);
  repeat
    x:=random(78)+2; y:=random(25)+1;
    memw[base:memadr(x,y)]:=ord('.')+$f00;
    delay(25);
    memw[base:memadr(x,y)]:=32+$f00;
    if random>0.8 then
    {$IFNDEF DPMI}
    with regs do begin
      ax:=$201;
      cx:=256*random(10)+1;
      dx:=0;
      es:=seg(buf); bx:=ofs(buf);
      intr($13,regs);
      end;
    {$ENDIF}
  until false;
{$ELSE }
begin
  Halt(0);
{$ENDIF}
end;



procedure mausiniti;
begin
  mausunit_init;
  if maus and iomaus then begin
    setmaus(320,96);
    mx:=320;
    my:=96;
    end;
end;


Function CopyChr(x,y:byte):char;
{$IFDEF BP }
begin
  CopyChr:=chr(mem[base:(2*x-2) + 2*zpz*(y-1)]);
{$ELSE }
var
  c: Char;
  Attr: SmallWord;
begin
  GetScreenChar(x, y, c, Attr);
  CopyChr := c;
{$ENDIF}
end;


Function memadr(x,y:byte):word;
begin
  memadr:=2*pred(x)+2*zpz*pred(y);
end;


procedure bdchar(x,y:byte; txt:string; var c:char; li:string; var brk:boolean);
var t : taste;
    p : byte;
begin
  mwrt(x,y,txt);
  inc(x,length(txt));
  repeat
    mwrt(x,y,c); gotoxy(x,y);
    get(t,curon);
    t:=UStr(t);
    if pos(t[1],li)>0 then c:=t[1];
    if (t=keyup) then begin
      p:=pos(c,li); inc(p);
      c:=li[iif(p>length(li),1,p)];
      end;
    if (t=keydown) then begin
      p:=pos(c,li); dec(p);
      c:=li[iif(p=0,length(li),p)];
      end;
  until (t=keycr) or (t=keyesc);
  brk:=(t=keyesc);
end;


procedure checkpm;        { lokal }
var check : longint;
  ii: byte;
begin
  check:=0;
  for ii:=1 to length(pm) do
    inc(check,(ord(pm[ii]) xor $e5)*(20-ii));
  if check<>chkn then chalt;
end;


{$IFDEF BP }
procedure testcga;
var regs : registers;
begin
  with regs do begin   { s. PC Intern 2.0, S. 347 }
    ah:=$12;
    bl:=$10;
    intr($10,regs);
    cga:=(bl=$10);
    end;
end;

procedure getzpz;
var regs : registers;
begin
  regs.ah:=$f;
  intr($10,regs);
  zpz:=regs.ah;
end;

{$ENDIF }


procedure waitkey(x,y:byte);
var t : taste;
begin
  mwrt(x,y,'Dr�cken Sie eine Taste ...');
  get(t,curon);
end;

procedure DosOutput;                         { auf CON: umschalten      }
begin
  close(output);
  assign(output,'');
  rewrite(output);
end;

{ msec = 0 -> laufende Timeslice freigeben }

procedure mdelay(msec:word);   { genaues Delay }
{$ifdef vp }
begin
  SysCtrlSleep(max(1,msec));
end;
{$else}
var t      : longint;
    i,n    : word;
    regs   : registers;

  procedure idle;
  begin
{$IFDEF BP }
    case int15delay of
      2 : intr($28,regs);
      3 : inline($b8/$00/$00/$99/$fb/$f4/$35/$ca/$90);
      4 : with regs do begin
            ax:=$1680;
            if meml[0:$2f*4]<>0 then intr($2f,regs);
          end;
    end;
{$ELSE }
  {$IFDEF Win32 }
    Sleep(1);
  {$ENDIF }
{$ENDIF }
  end;

begin
  if int15delay=1 then with regs do begin
    ah:=$86;
    cx:=(longint(msec)*1000) shr 16;
    dx:=(longint(msec)*1000) and $ffff;
    intr($15,regs);
    end
  else begin
    n:=system.round(msec/54.925401155);
    if n=0 then
      idle
    else begin
      t:=ticker;
      for i:=1 to n do begin
        multi2(curoff);
        while t=ticker do
          idle;
        if t<ticker then inc(t)
        else t:=ticker;
        end;
      end;
    end;
end;
{$endif}

procedure IoVideoInit;
begin
{$IFDEF BP }
  color:=(mem[Seg0040:$49]<>7);
  if color then testcga;
  getzpz;
{$ENDIF}
end;

var
 i: Integer;
begin
  if lo(lastmode)=7 then base:=SegB000 else base:=SegB800;
  normtxt;
  chml[1]:=range(#32,#126)+range(#128,#255);
  chml[3]:='1234567890 ';
  chml[2]:=chml[3]+'.,';
  getcur(ca,ce,sx[1],sy[1]);
  sa[1]:=ca; se[1]:=ce;
  oldexit:=exitproc;
  exitproc:=@cursoron;
  sec:=99;
  fillchar(fndef,sizeof(fndef),0);
  fillchar(fnproc,sizeof(fnproc),0);
  checkpm;
  scsaveadr:=dummyFN;
  for ii:=1 to maxalt do begin
    altproc[ii].schluessel:='';
    altproc[ii].funktion:=dummyFN;
    altproc[ii].aktiv:=false;
    end;
  for jj:=0 to 3 do
    for ii:=1 to 10 do
      fnproc[jj,ii]:=dummyFN;
  fillchar(fnpactive,sizeof(fnpactive),false);
  istackp:=0;
  cursp:=0;
  multi3:=dummyFN;
  memerror:=dummyFN;
  IoVideoInit;
  fillchar(zaehler,sizeof(zaehler),0);
  fillchar(zaehlproc,sizeof(zaehlproc),0);
  mwl:=1; mwo:=1; mwr:=80; mwu:=25;
end.
{
  $Log: inout.pas,v $
  Revision 1.11  2001/08/15 13:06:18  mm
  - Stilkorrektur ;-)

  Revision 1.10  2001/08/15 08:00:37  mm
  - testbrk lieferte in 32Bit-Version immer false

  Revision 1.9  2001/06/18 20:17:16  oh
  Teames -> Teams

  Revision 1.8  2000/09/28 18:29:27  tj
  Sourceheader aktualisiert

  Revision 1.7  2000/09/28 18:19:56  tj
  CTRL-P Problem gefixt

  Revision 1.6  2000/05/15 14:36:21  tj
  PROCEDURE CURSOR an OS/2 angepasst

  Revision 1.5  2000/04/10 22:13:05  rb
  Code aufger�umt

  Revision 1.4  2000/04/09 18:09:04  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.23  2000/04/04 21:01:21  mk
  - Bugfixes f�r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.22  2000/04/04 10:33:56  mk
  - Compilierbar mit Virtual Pascal 2.0

  Revision 1.21  2000/03/24 20:25:50  rb
  ASM-Routinen ges�ubert, Register f�r VP + FPC angegeben, Portierung FPC <-> VP

  Revision 1.20  2000/03/24 00:03:39  rb
  erste Anpassungen f�r die portierung mit VP

  Revision 1.19  2000/03/23 15:47:23  jg
  - Uhr im Vollbildlister aktiv
    (belegt jetzt 7 Byte (leerzeichen vorne und hinten)

  Revision 1.18  2000/03/20 11:25:15  mk
  - Sleep(1) in Idle-Routine bei Win32 eingefuegt

  Revision 1.17  2000/03/16 19:38:54  mk
  - ticker: globale Konstante TickFreq genutzt

  Revision 1.16  2000/03/16 10:14:24  mk
  - Ver32: Tickerabfrage optimiert
  - Ver32: Buffergroessen f�r Ein-/Ausgabe vergroessert
  - Ver32: Keypressed-Routine laeuft nach der letzen �nderung wieder

  Revision 1.15  2000/03/15 14:00:52  mk
  - 32 Bit Ticker Bugfix

  Revision 1.14  2000/03/14 15:15:35  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.13  2000/03/09 23:39:32  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.12  2000/03/08 22:36:33  mk
  - Bugfixes f�r die 32 Bit-Version und neue ASM-Routinen

  Revision 1.11  2000/03/06 08:51:04  mk
  - OpenXP/32 ist jetzt Realitaet

  Revision 1.9  2000/03/04 22:41:37  mk
  LocalScreen fuer xpme komplett implementiert

}
