{ Programm: calendar.pas
  Funktion: Kalender-UNIT
  Sprache: Turbo Pascal 6.0
  DOS EXTRA 10'90, S.16 }

{ $Id: calendar.pas,v 1.1 2001/07/11 19:47:17 rb Exp $ }

{ $define debug}

{$ifndef debug}

unit calendar;

interface

{$endif}


{$ifdef virtualpascal}

{$h-}

type  integer      = longint;
      word         = longint;

{$endif}


type datetyp=longint;


const weekdayname:array[0..7] of string[10]=
                  ('??FEHLER','Montag',
                   'Dienstag','Mittwoch',
                   'Donnerstag','Freitag',
                   'Samstag','Sonntag');
      weekdayname_e:array[0..7] of string[9]=
                    ('??ERROR','Monday',
                     'Tuesday','Wednesday',
                     'Thursday','Friday',
                     'Saturday','Sunday');
      monthname:array[1..12] of string[9]=
                ('Januar','Februar',
                 'MÑrz','April','Mai',
                 'Juni','Juli','August',
                 'September','Oktober',
                 'November','Dezember');
      monthname_e:array[1..12] of string[9]=
                  ('January','February',
                   'March','April','May',
                   'June','July','August',
                   'September','October',
                   'November','December');
      zodiac:array[0..12] of string[10]=
             ('Fehler','Wassermann','Fische','Widder','Stier',
              'Zwillinge','Krebs','Lîwe','Jungfrau',
              'Waage','Skorpion','SchÅtze','Steinbock');
      zodiac_e:array[0..12] of string[11]=
               ('Error','Aquarius','Pisces','Aries','Taurus',
                'Gemini','Cancer','Leo','Virgo',
                'Libra','Scorpio','Sagittarius','Capricorn');

{$ifndef debug}

function leapyear(y:word):boolean;
function packdate(year:word;month,day:byte):datetyp;
function today:datetyp;
function dayspmonth(y:word;m:byte):byte;
function dateerror(dt:datetyp):boolean;
function day(dt:datetyp):byte;
function month(dt:datetyp):byte;
function year(dt:datetyp):word;
function dayofweek(dt:datetyp):byte;
function juldate(dt:datetyp):longint;
procedure incdate(var dt:datetyp);
procedure decdate(var dt:datetyp);
function adddate(dt:datetyp;n:longint):datetyp;
function diffdate_alt(d1,d2:datetyp):longint;
function diffdate(d1,d2:datetyp):longint;
function is_date(s:string):boolean;
function makedate(s:string;addrest:boolean):datetyp;
function easter(year:word):datetyp;
function sternzeichen(dt:datetyp):word;


function ostern(year:word):datetyp;

implementation

{$ifdef virtualpascal}
uses dos;
{$endif}

{$endif}


const ya=1700;
      ye=2199;


type hcon=array[1..12] of byte;
     htyp=record case byte of
            0: (date:datetyp);
            1: (d,m:system.byte;y:system.word);
          end;

(*
function leapyear(y:word):boolean;               { Schaltjahr }
  begin
    leapyear:=false;
    if (y and 3<>0) then exit
    else leapyear:=(y mod 100<>0) or (y mod 400=0);
  end;
*)

function leapyear(y:word):boolean;               { Schaltjahr }
  begin
    leapyear:=((y and 3)=0) and (((y mod 100)<>0) or ((y mod 400)=0));
  end;

function packdate(year:word;month,day:byte):datetyp;
  var h:htyp;
  begin
    with h do begin
      if year>=100 then y:=year else y:=1900+year;
      m:=month;
      d:=day;
      packdate:=date;
    end;
  end;

function day(dt:datetyp):byte;
  var h:htyp;
  begin
    with h do begin
      date:=dt;
      day:=d;
    end;
  end;

function month(dt:datetyp):byte;
  var h:htyp;
  begin
    with h do begin
      date:=dt;
      month:=m;
    end;
  end;

function year(dt:datetyp):word;
  var h:htyp;
  begin
    with h do begin
      date:=dt;
      year:=y;
    end;
  end;

{$ifdef virtualpascal}

function today:datetyp;
  var h:htyp;
      year,month,day,dow:word;
  begin
    with h do begin
      getdate(year,month,day,dow);
      y:=year;
      m:=month;
      d:=day;
      today:=date;
    end;
  end;

{$else}

function today:datetyp;
  var h:htyp;
  begin
    asm
      mov ah,2ah
      int 21h
      mov [h.d],dl
      mov [h.m],dh
      mov [h.y],cx
    end;
    today:=h.date;
  end;

{$endif}

function dayspmonth(y:word;m:byte):byte;
  const dpm:hcon=(31,28,31,30,31,30,31,31,30,31,30,31);
  begin
    dayspmonth:=dpm[m];
    if m<>2 then exit
    else if leapyear(y) then dayspmonth:=29;
  end;

function dateerror(dt:datetyp):boolean;
  var hdate:htyp;
  begin
    dateerror:=true;
    with hdate do begin
      date:=dt;
      if (m<1) or (m>12) or (y<ya) or ((y>ye) and (y<>$ffff))
      or (d<1) or (d>dayspmonth(y,m)) then exit
      else dateerror:=false;
    end;
  end;

function dayofweek(dt:datetyp):byte;
  const kenn:hcon=(8,9,2,3,3,4,4,5,6,6,7,7);
  var hdate:htyp;
      y1:word;
      n,m1:byte;
  begin
    if dateerror(dt) then dayofweek:=0
    else with hdate do begin
      date:=dt;
      m1:=m;
      y1:=y;
      if m<=2 then begin
        m1:=m+12;
        y1:=y-1;
      end;
      n:=(d+2*m1+kenn[m]+y1+(y1 div 4)-(y1 div 100)+(y1 div 400)+2) mod 7;
      if n>1 then dayofweek:=n-1 else dayofweek:=n+6;
    end;
  end;

function juldate(dt:datetyp):longint;
 { Berechnet die Julianische Kalenderzahl, Jahr muss incl. Jahrhundert
   angegeben werden }
var hdate:htyp;
    kyear,kmonth:integer;
    myresult:longint;

Begin
  with hdate do begin
    date:=dt;
    juldate:=-1;
    if y=0 then exit;
    if m<3 then begin
      kmonth:=m+12;
      kyear:=y-1;
    end
    else begin
      kmonth:=m;
      kyear:=y;
    end;
    inc(kmonth);
    myresult:=longint(kyear)*365+kyear div 4+(kmonth*306) div 10+d+1720995;

    { Am 5.10.1582 war die Gregorianische Kalenderreform }

    if myresult>2299170
    then myresult:=myresult-(kyear div 100)+(kyear div 400)+2
    else if myresult>2299160
    then myresult:=myresult-(kyear div 100)+(kyear div 400)+2+10;
    juldate:=myresult;
  end;
end;

{
Wenn Du die Julianische Kalenderzahl durch 7 teilst und den Rest nimmst
(=JulDate mod 7) hast Du den Wochentag, wobei Montag = 0, Sonntag = 6.

Beispiel: J. Seb. Bach, geb. 21.3.1685:  Jul. Zahl = 2336574, Wo.Tag = 2,
also Mittwoch.
}

{$ifdef virtualpascal}

procedure incdate(var dt:datetyp);
  var hdate:htyp;
  begin
    with hdate do begin
      date:=dt;
      if d<dayspmonth(y,m) then inc(d)
      else begin
        d:=1;
        if m<12 then inc(m)
        else begin
          m:=1;
          inc(y);
        end;
      end;
      dt:=date;
    end;
  end;

{$else}

procedure incdate(var dt:datetyp); assembler;
  asm
    les bx,dt
    les bx,es:[bx]
    mov dx,es
    mov ax,bx
    xor al,al
    xchg ah,al
    push bx
    push dx
    push dx
    push ax
    call dayspmonth
    pop dx
    pop bx
    cmp bl,al
    jnb @@w1
    inc bl
    jmp @@ende
@@w1:
    mov bl,1
    cmp bh,12
    jnb @@w2
    inc bh
    jmp @@ende
@@w2:
    mov bh,1
    inc dx
@@ende:
    les di,dt
    mov word ptr es:[di],bx
    mov word ptr es:[di+2],dx
  end;

{$endif}

procedure decdate(var dt:datetyp);
  var hdate:htyp;
  begin
    with hdate do begin
      date:=dt;
      if d>1 then dec(d)
      else begin
        if m>1 then dec(m)
        else begin
          m:=12;
          dec(y);
        end;
        d:=dayspmonth(y,m);
      end;
      dt:=date;
    end;
  end;

function adddate(dt:datetyp;n:longint):datetyp;
  var i:longint;
      hdt:datetyp;
  begin
    hdt:=dt;
    if n>0 then for i:=1 to n do incdate(hdt)
    else for i:=1 to -n do decdate(hdt);
    adddate:=hdt;
  end;

function diffdate_alt(d1,d2:datetyp):longint;
  var hd1,hd2:datetyp;
      n:longint;
      sign:shortint;
  begin
    if d2>=d1 then begin
      sign:=+1;
      hd1:=d1;
      hd2:=d2;
    end
    else begin
      sign:=-1;
      hd1:=d2;
      hd2:=d1;
    end;
    n:=0;
    while hd1<>hd2 do begin
      inc(n);
      incdate(hd1);
    end;
    diffdate_alt:=sign*n;
  end;

function diffdate(d1,d2:datetyp):longint;
  var hd1,hd2:datetyp;
  begin
    diffdate:=juldate(d2)-juldate(d1);
  end;

function is_date(s:string):boolean;
  var i:integer;
  begin
    is_date:=true;
    for i:=1 to length(s) do
    if not (s[i] in ['0'..'9','.','/','-']) then is_date:=false;
  end;

function makedate(s:string;addrest:boolean):datetyp;
  label l1;
  const endchr=#255;
  var i,j,len,p,y:word;
      n:array[1..3] of word;
      h0:htyp;
      m,d:byte;
      c:char;

  function next:char;
    begin
      inc(i);
      if i<=len then next:=s[i] else next:=endchr;
    end;

  function look:boolean;
    begin
      if i<len then look:=s[i+1] in ['0'..'9'] else look:=false;
    end;

  function number:word;
    var j,n:word;
    begin
      n:=0;
      for j:=1 to p do if look then n:=n*10+ord(next)-48;
      number:=n;
    end;

  begin
    len:=length(s);
    i:=0;
    for j:=1 to 3 do begin
      while not look do begin
        c:=next;
        if c=endchr then goto l1;
      end;
l1:   if j=3 then p:=4 else p:=2;
      n[j]:=number;
    end;
    h0.date:=today;
    if not addrest then begin
      h0.y:=$ffff;
      h0.m:=0;
    end;
    d:=n[1];
    m:=n[2];
    y:=n[3];
    if (y=0) and (m=0) and (d=0) then makedate:=h0.date
    else begin
      if (y=0) and (m>0) and (d>0) then y:=h0.y
      else if (y=0) and (m=0) and (d>0) then begin
        y:=h0.y;
        m:=h0.m;
      end;
      makedate:=packdate(y,m,d);
    end;
  end;

function easter(year:word):datetyp;              { Datum des Ostersonntags }
  var a,b,c,d,e,m,n:word;
      month,day:byte;
  begin
    if (year<ya) and (year>ye) then begin
      month:=0;
      day:=0;
      exit;
    end;
    case year div 100 of
      17:     begin m:=23;n:=3; end;
      18:     begin m:=23;n:=4; end;
      19, 20: begin m:=24;n:=5; end;
      21:     begin m:=24;n:=6; end;
    end;
    a:=year mod 19;
    b:=year mod 4;
    c:=year mod 7;
    d:=(19*a+m) mod 30;
    e:=(2*b+4*c+6*d+n) mod 7;
    day:=(22+d+e);
    month:=3;
    if day>31 then begin
      day:=(d+e-9);
      month:=4;
      if (day=26) then day:=19;
      if (d=28) and (e=6) and (a>10) then begin
        if (day=25) then day:=18;
      end;
    end;
    easter:=packdate(year,month,day);
  end;

function sternzeichen(dt:datetyp):word;
  { 21.01. - 18.02. Wassermann - Aquarius
    19.02. - 20.03. Fische     - Pisces
    21.03. - 20.04. Widder     - Aries
    21.04. - 20.05. Stier      - Taurus
    21.05. - 21.06. Zwillinge  - Gemini
    22.06. - 22.07. Krebs      - Cancer
    23.07. - 23.08. Lîwe       - Leo
    24.08. - 23.09. Jungfrau   - Virgo
    24.09. - 23.10. Waage      - Libra
    24.10. - 22.11. Skorpion   - Scorpio
    23.11. - 21.12. SchÅtze    - Sagittarius
    22.12. - 20.01. Steinbock  - Capricorn      }
  var i,j:word;
  begin
    i:=dt and $ffff;
    if (i>=$0115) and (i<=$0212) then j:=1
    else if (i>=$0213) and (i<=$0314) then j:=2
    else if (i>=$0315) and (i<=$0414) then j:=3
    else if (i>=$0415) and (i<=$0514) then j:=4
    else if (i>=$0515) and (i<=$0615) then j:=5
    else if (i>=$0616) and (i<=$0716) then j:=6
    else if (i>=$0717) and (i<=$0817) then j:=7
    else if (i>=$0818) and (i<=$0917) then j:=8
    else if (i>=$0918) and (i<=$0a17) then j:=9
    else if (i>=$0a18) and (i<=$0b16) then j:=10
    else if (i>=$0b17) and (i<=$0c15) then j:=11
    else if (i>=$0c16) or (i<=$0114) then j:=12
    else j:=0;
    sternzeichen:=j;
  end;

{ folgende Routinen siehe c't 15/1997 S. 312 ff }

function tagesnummer(dt:datetyp):word;
  var d,e:word;
  begin
    d:=(month(dt)+10) div 13;
    e:=day(dt)+(611*(month(dt)+2)) div 20-2*d-91;
    tagesnummer:=e+ord(leapyear(year(dt)))*d;
  end;

function monat_im_jahr(jahr,n:word):word;
  var a:word;
  begin
    a:=ord(leapyear(jahr));
    if (n>59+a) then inc(n,2-a);
    inc(n,91);
    monat_im_jahr:=(20*n) div 611-2;
  end;

function tag_im_monat(jahr,n:word):word;
  var a,m:word;
  begin
    a:=ord(leapyear(jahr));
    if (n>59+a) then inc(n,2-a);
    inc(n,91);
    m:=(20*n) div 611;
    tag_im_monat:=n-(611*m) div 20;
  end;

function wochentag(jahr,n:word):word;
  var j,c:word;
  begin
    j:=(jahr-1) mod 100;
    c:=(jahr-1) div 100;
    wochentag:=(28+j+n+(j div 4)+(c div 4)+5*c) mod 7;
  end;

function ostersonntag(jahr:word):word;
  var gz,jhd,ksj,korr,so,epakte,n:integer;
  begin
    gz:=(jahr mod 19)+1;
    jhd:=jahr div 100+1;
    ksj:=(3*jhd) div 4-12;
    korr:=(8*jhd+5) div 25-5;
    so:=(5*jahr) div 4-ksj-10;
    epakte:=(11*gz+20+korr-ksj) mod 30;
    if (((epakte=25) and (gz>11)) or (epakte=24)) then inc(epakte);
    n:=44-epakte;
    if (n<21) then inc(n,30);
    n:=n+7-(so+n) mod 7;
    inc(n,ord(leapyear(jahr)));
    ostersonntag:=n+59;
  end;

function ostern(year:word):datetyp;              { Datum des Ostersonntags }
  var n,month,day:word;
  begin
    n:=ostersonntag(year);
    month:=monat_im_jahr(year,n);
    day:=tag_im_monat(year,n);
    ostern:=packdate(year,month,day);
  end;


(*
/*
   Eingabe: Jahr
            Monat (1=Jan, 2=Feb, ... 12 = Dec)
            Tag   (1...31)
   Ausgabe: Julianisches Datum
            (Tage seit dem 1.1.4713 v.Chr.)
   Algorithmus von R. G. Tantzen
*/
long jdatum(int jahr, int monat, int tag)
{
   long c, y;
   if ( monat>2 )
   {
      monat -= 3;
   }
   else
   {
      monat += 9;
      jahr--;
   }
   tag += (153*monat+2)/5;
   c = (146097L*(((long)jahr) / 100L))/4L;
   y =   (1461L*(((long)jahr) % 100L))/4L;
   return c+y+(long)tag+1721119L;
}

/*
   Eingabe: Julianisches Datum
            (Tage seit dem 1.1.4713 v.Chr.)
   Ausgabe: Jahr
            Monat (1=Jan, 2=Feb, ... 12 = Dec)
            Tag   (1...31)
   Modifizierter Algorithmus von R. G. Tantzen
*/
void gdatum(long jd, int *jahr, int *monat, int *tag)
{
   long j,m,t;
   jd -= 1721119L;

   j  = (4L*jd-1L) / 146097L;
   jd = (4L*jd-1L) % 146097L;
   t  = jd/4L;

   jd = (4L*t+3L) / 1461L;
   t  = (4L*t+3L) % 1461L;
   t  = (t+4L)/4L;

   m  = (5L*t-3L) / 153L;
   t  = (5L*t-3L) % 153L;
   t  = (t+5L)/5L;

   j  = 100L*j + jd;
   if ( m < 10L )
   {
      m+=3;
   }
   else
   {
      m-=9;
      j++;
   }
   *jahr  = (int)j;
   *monat = (int)m;
   *tag   = (int)t;
}
*)

{$ifdef debug}

var i:word;o1,o2:datetyp;

begin
  writeln('.');
{
  for i:=ya to ye do if ostern(i)<>easter(i) then begin
    write(i,': ');
    o1:=easter(i);
    o2:=ostern(i);
    write(day(o1),'.',month(o1),'.',year(o1),' ');
    write(day(o2),'.',month(o2),'.',year(o2));
    writeln;
  end;
}
  o1:=packdate(1998,1,1);
  repeat
    writeln(day(o1),'.',month(o1),'. ',sternzeichen(o1));
    incdate(o1);
    if (day(o1)=1) or (day(o1)=15) then readln;
  until o1=packdate(1999,1,1);

{$endif}

end.


{
  $Log: calendar.pas,v $
  Revision 1.1  2001/07/11 19:47:17  rb
  checkin


}
