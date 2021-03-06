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
{ $Id: xp4o.pas,v 1.55 2001/12/26 09:21:54 MH Exp $ }

{ CrossPoint - Overlayroutinen, die von XP4 aufgerufen werden }

{$I XPDEFINE.INC }

{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp4o;

interface

uses xpglobal,
{$IFDEF virtualpascal}
     sysutils,
{$endif}
     crt,dos,dosx,typeform,fileio,inout,keys,montage,maske,datadef,database,
     lister,archive,maus2,winxp,printerx,resource,
     xp0,xp1,xp1o2,xp1help,xp1input;


var  such_brett  : string[5];    { f�r Suche im gew�hlten Brett }
     FMsgReqnode : string[BoxNameLen];    { F3 - Request - Nodenr. }

procedure msg_info;          { interpretierten Header anzeigen }
procedure ShowHeader;        { Original-Header anzeigen        }

function  Suche(anztxt,suchfeld,autosuche:string):boolean;
procedure betreffsuche;
procedure SucheWiedervorlage;
procedure BU_reorg(user,adrbuch:boolean);
procedure MsgReorgScan(_del,repair:boolean; var brk:boolean);
procedure MsgReorg;
procedure ImportBrettliste;
procedure ImportUserliste;
procedure ExportUB(user:boolean);

procedure ModiEmpfDatum;
procedure ModiBetreff;
procedure ModiText;
procedure ModiRot13;
procedure ModiTyp;
procedure ModiGelesen;
procedure ModiHighlite;

procedure zeige_unversandt;
function  ViewArchive(var fn:pathstr; typ:shortint):shortint;
procedure FileArcViewer(fn:pathstr);

procedure ShowArch(var fn:string);
function  a_getfilename(nr,nn:byte):pathstr;
procedure ArcSpecial(var t:taste);

procedure DupeKill(autodupekill:boolean);
procedure print_msg(initpr:boolean);
function  UserMarkSuche(allmode:boolean):boolean;
procedure BrettInfo;
procedure ntinfo;
procedure do_bseek(fwd:boolean);
procedure FidoMsgRequest(var nnode:string);
function  _killit(ask:boolean):boolean;
function  testbrettscope(var s:string):boolean;
procedure seek_cutspace(var s:string);

procedure ReverseHdo;
function rfcbrett(s:string):string;

implementation  {-----------------------------------------------------}
                                                {!!}
uses xpkeys,xpnt,xp1o,xp4,xp3,xp3o,xp3o2,xp3ex,{xp6,}xpfido,xpmaus,xpview,
     xp_pgp,xp9;

const max_arc = 3;   { maximale verschachtelte Archivdateien }
      suchlen = 73;  { maximale L�nge des Suchstrings        }

type arcbuf = record
                arcer_typ : shortint;
                arcname   : pathstr;
              end;
     arcbp  = ^arcbuf;

const arcbufp : byte = 0;
      suchopt : string[8] = 'au'; {'*';}

var  reobuf : array[0..ablagen-1] of boolean;
     bufsiz : array[0..ablagen-1] of longint;  { Gr��e nach Reorg }
     abuf   : array[1..max_arc+1] of arcbp;
     exdir  : pathstr;
     arctyp_save : shortint;
     mid_options       : byte;
     mid_bretter       : byte;  
     Mid_teilstring    : boolean;

function testbrettscope(var s:string):boolean;
var i : integer;
begin
  if (length(s)=1) and (lastkey<>keybs) then begin
    for i:=4 downto 0 do
      if upcase(s[1])=ustr(left(getres2(442,i),1)) then
        s:=getres2(442,i);
    freeres;
    if length(s)>1 then _keyboard(keyend);
    end;
  testbrettscope:=true;
end;

procedure seek_cutspace(var s:string);
begin
  if s=' ' then s:='';
end;

function mid_suchoption(var s:string):boolean;
begin
  setfieldenable(mid_options,s='J');
  if aktdispmode <> 11 then setfieldenable(mid_bretter,s='J');
  mid_suchoption:=true;
end;

{ Suchfeld:  '' (Volltext), '*' (Universal), 'Betreff', 'Absender', 'MsgID' }

function Suche(anztxt,suchfeld,autosuche:string):boolean;
type  suchrec    = record
                     betr,user,txt : string[SuchLen];
                     fidoempf,mid  : string[SuchLen];
                     nbetr,nuser   : Boolean;
                     nfidoempf     : Boolean;
                     vondat,bisdat : datetimest;
                     vonkb,biskb   : longint;
                     status        : string[10];
                     typ           : string[11];
                   end;

const srec       : ^suchrec = nil;
      history0   : string[Suchlen]='';
      history1   : string[Suchlen]='';
      history2   : string[Suchlen]='';

var x,y   : byte;
    brk   : boolean;
    n,nf  : longint;
    p     : pointer;
    psize : word;
    spez  : boolean;
    sst   : string[SuchLen];   { evtl. UpString von suchstring }
    i     : integer;
    brett : string[AdrLen];
    me,uu : boolean;
    hdp   : headerp;
    hds   : longint;
    bretter : string[8];
    box     : string[BoxNameLen];
    nt      : byte;

    suchstring      : string[SuchLen];
    typc{,c}        : char;
    statb           : byte;
    _vondat,_bisdat : longint;
    minsize,maxsize : longint;
    igcase{,sword}  : boolean;
    umlaut          : boolean;          {JG:15.02.00 Schalter zum Umlaute ignorieren}
    bereich         : shortint;
    _brett          : string[5];
    mi,add          : byte;
    bera            : array[0..4] of string[10];
    stata           : array[0..5] of string[10];
    typa            : array[0..6] of string[11];

    suchand           : boolean;
    seeklen,seekstart : array[0..9] of byte;
    seeknot           : array[0..9] of boolean;
    suchanz           : byte;
    seek              : string[suchlen];
    found             : boolean;
    check4date        : boolean;

label ende;

  function getbfn(bn:string):string;
  var
    d : db;
  begin
    dbOpen(d,BoxenFile,1);
    dbSeek(d,boiName,ustr(bn));
    if dbFound then begin
      getbfn:=dbReadStr(d,'dateiname');
      dbRead(d,'netztyp',nt);
    end else getbfn:=left(ustr(bn),8);
    dbClose(d);
  end;

{ Check_Seekmode:

  Wenn bei Normalsuche die Suchoptionen "ua&" fuer UND oder "o|" fuer ODER angegeben wurden,
  werden in den Arrays die Anfangs und End Offsets von bis zu 10 Teilsuchstrings gespeichert,
  und Suchanz auf die Anzahl der (durch Leerzeichen getrennten, bzw in Anfuehrungszeichen
  eingefassten) Teilsuchstrings gesetzt. Suchand ist "true" bei UND Verknuepfung und "false"
  bei ODER Verknuepfung.  Wurden keine Verknuepfungsoptionen angegeben, wird eine OR
  Verknuepfung durchgefuehrt, mit einem einzigen "Teilsuchstring", der die Ganze Laenge
  des Suchstring abdeckt
}
  procedure check_seekmode;           
  var   
  m,n,i   : byte;
  quotes  : boolean;
                                       
{$IFDEF Debug}                      { Zum Debuggen der Suchstringerkennung}
  Procedure Show_Seekstrings;
  var n,x,y:byte;
   begin
    if spez then x:=23 else x:=19;
    msgbox(70,x,'Suchstring-Check',x,y);
    attrtxt(col.colmbox);
    wrt(x+1,y+1,'Benutzte Teilstrings: '); write(suchanz);
    wrt(x+27,y+1,iifs(suchand,'AND','OR'));
    write('    Igcase='+iifs(igcase,'1','0')+'   Umlaut='+iifs(umlaut,'1','0')); 
    write(iifs(spez,'    SPEZIAL','')); 
    wrt(x+1,y+3,'Suchstring: '+chr($af)+iifs(spez,srec^.txt,suchstring)+chr($ae));
    wrt(x+1,y+4,'sst:        '+chr($af)+sst+chr($ae));
    for n:=0 to 9 do    
    begin
      wrt(x+1,y+6+n,'String'); write(n); write(': ');
      write(seekstart[n]:2); write(','); write(seeklen[n]:2);
      write(iifs(seeknot[n],' NOT ','     ')+chr($af)+left(mid(sst,seekstart[n]),seeklen[n])+chr($ae));
      end;
    wrt(x+1,y+17,'Length(sst)='); write(length(sst)); write('  i='); write(i);
    if spez then with srec^do 
    begin
      wrt(x+1,y+19,'Betr:     '+iifs(nbetr,' NOT ','     ')+chr($af)+betr+chr($ae));
      wrt(x+1,y+20,'User:     '+iifs(nuser,' NOT ','     ')+chr($af)+user+chr($ae));
      wrt(x+1,y+21,'Fidoempf: '+iifs(nfidoempf,' NOT ','     ')+chr($af)+fidoempf+chr($ae));
      end;
    wait(curoff);
    closebox;
   end;
{$ENDIF}

  begin
{$IFDEF Debug}
    for n:=0 to 9 do
      begin
        seekstart[n]:=0;
        seeklen[n]:=0;
        seeknot[n]:=false;
      end;
{$Endif}
    suchand:=cpos('o',lstr(suchopt))=0;                  { OR }
    if ((not suchand) or (cpos('a',lstr(suchopt))>0))    { oder AND ?}
       and (trim(sst)<>'') then                     { und nicht Leertext (Suche-Spezial)}
    begin
      n:=0;
      seek:=trim(sst);                              { Leerzeichen vorne und hinten, }
      i:=length(seek);
      while (seek[i]='"') and (i <> 0) do dec(i);   { Und Ausrufezeichen hinten abschneiden }
      truncstr(seek,i);
      if seek<>'' then begin
        i:=1;
        sst:=seek+'"';  quotes:=false;
        while (i<length(sst)) and (n<=9) do
        begin
          while sst[i]=' ' do inc(i);                  { Leerzeichen ueberspringen }
          if not quotes then
          begin
            seeknot[n]:=sst[i]='~';                    { NOT Flag setzen }
            while ((sst[i]='~') or (sst[i]=' '))
              do inc(i);                               { und evtl weitere ^ ueberspringen }
          end;
          quotes:=sst[i]='"';                          { Evtl. "- Modus aktivieren....}
          while sst[i]='"' do inc(i);                  { weitere " ueberspringen }
          seekstart[n]:=i;
          while (i<length(sst)) and not                { Weiterzaehlen bis Stringende      }
            ((not quotes and (sst[i]=' ')) or          { oder Space das nicht in " ist     }
            (sst[i]='"')) do inc(i);                   { oder das naechste " gefunden wird }
          seeklen[n]:=i-seekstart[n];
          quotes:=not quotes and (sst[i]='"');         { -"- Modus umschalten }
          if (not quotes) then inc(i);
          inc(n);
        end;
        if seeklen[n-1]=0 then dec(n);                 { Falls String mit > "< Endete... }
        {if n<=9 then suchanz:=n else suchanz:=9;}
        suchanz:=n;
      end;

      if suchanz=1 then suchand:=true;
      m:=0;
      for n:=0 to suchanz-1 do            { Teilstrings Umsortieren: NOT zuerst }
      begin
        if (seeknot[n]=true) and (seeklen[n]<>0) then
        begin
          i:=seekstart[m];    seekstart[m]:=seekstart[n];  seekstart[n]:=i;
          i:=seeklen[m];      seeklen[m]:=seeklen[n];      seeklen[n]:=i;
          quotes:=seeknot[m]; seeknot[m]:=seeknot[n];      seeknot[n]:=quotes;
          inc(m);
        end;
      end;
    end

    else begin
      suchand:=true;
      suchanz:=1;
      seekstart[0]:=1;
      seeklen[0]:=length(sst);
      seeknot[0]:=false;
    end;

{$IFDEF Debug}
    if cpos('c',lstr(suchopt))>0 then show_seekstrings; { "Writeln is der Beste debugger..." }
{$ENDIF}

  end;


  function InText(var key:string):boolean;
  var size : longint;
      ofs  : longint;
      wsize: word;
  begin
    dbReadN(mbase,mb_msgsize,size);
    if size=0 then begin   { leerer Datensatz - vermutlich durch RuntimeError }
      dbDelete(mbase);
      InText:=false;
    end
    else begin
      wsize:=min(size,psize);
      ofs:=dbReadInt(mbase,'msgsize')-dbReadInt(mbase,'groesse');
      if (ofs>0) and (ofs<wsize+1+length(key)) then begin
        dec(wsize,ofs);
        XmemRead(ofs,wsize,p^);
        if umlaut then upstring(key);          { Umlaut-Suche automatisch Case_insensitiv }
        Intext:=TxtSeek(p,wsize,key,igcase,umlaut);
      end
      else
        Intext:=false;
    end;
  end;


  function DateFit:boolean;
  var d : longint;
  begin
    dbReadN(mbase,mb_origdatum,d);
    DateFit:=not smdl(d,_vondat) and not smdl(_bisdat,d);
  end;

  function Sizefit:boolean;
  var s : longint;
  begin
    dbReadN(mbase,mb_groesse,s);
    sizefit:=(s>=minsize) and (s<=maxsize);
  end;

  function TypeFit:boolean;
  var t     : char;
      nt    : longint;
      flags : longint;
  begin
    if typc=' ' then typefit:=true
    else begin
      dbReadN(mbase,mb_typ,t);
      dbReadN(mbase,mb_netztyp,nt);
      dbReadN(mbase,mb_flags,flags);
      TypeFit:=((typc='F') and (nt and $200<>0)) or
               ((typc='M') and (flags and 4<>0)) or
               ((typc='H') and (flags and 64<>0)) or
               ((typc='R') and (flags and 128<>0)) or
               (t=typc);
    end;
  end;

  function StatOk:boolean;
  var flags : byte;
  begin
    dbReadN(mbase,mb_halteflags,flags);
    case statb of
       0 : StatOk:=true;
     1,2 : StatOK:=(statb=flags);
       3 : StatOK:=(flags=1) or (flags=2);
       4 : StatOK:=(dbReadInt(mbase,'gelesen')=0);
       5 : StatOK:=(dbReadInt(mbase,'gelesen')<>0);
    end;
  end;


  { Leerzeichen Links und rechts l�schen, Tilden links ebenfalls }
  { boolean setzen, wenn Tilde gefunden wurde }

  procedure Scantilde(var s:String; var suchnot:boolean);
  begin
    trim(s);
    if s='' then suchnot:=false else begin
      suchnot:=s[1]='~';
      i:=1;
      while ((s[i]='~') or (s[i]=' ')) do inc(i);
      s:=mid(s,i);
    end;
  end; 


{--Einzelne Nachricht mit Sucheingaben vergleichen--}

  procedure TestMsg;
  var betr2 : string[BetreffLen];
      user2 : string[AdrLen];
      realn : string[40];
      such  : string[81];
          j : byte;
          d : longint;
          b : byte;
      found_not : boolean;

{   Volltextcheck:

    Seekstart und Seeklen sind Zeiger auf Anfang und Ende der Teilsuchstrings
    innerhalb des Gesamtsuchstrings SST. Suchand ist "true" bei UND-Suche,
    und "false" bei ODER-Suche Der Textinhalt wird mit den  Teilsuchstrings verglichen,
    solange Suchand=1 (UND) und Found=0, bzw bis Suchand=0 (OR) und Found=1,
    wurde ein Teilsuchstring gefunden, obwol SeekNOT fuer ihn definiert ist, 
    wird die Suche beendet und Found nachtraeglich auf 0 gesetzt (Suche gescheitert).
    NOT-Suchstrings werden dabei aus der UND-Verknuepfung ausgeklammert.  
}
    procedure Volltextcheck;
    begin
      j:=0;
      repeat
        seek:=left(mid(sst,seekstart[j]),seeklen[j]);       
        found:=Intext(seek);
        found_not:=found and seeknot[j];
        if suchand and not found and seeknot[j] then found:=true;
        inc(j);
      until (j=suchanz) or (suchand xor found) or found_not;
      if found_not then found:=false;
    end;


  begin
    inc(n);
    if (n mod 10)=0 then begin
      moff;
      gotoxy(x+9,wherey); write(n:7);
      gotoxy(x+26,wherey); write(nf:5);
      mon;
    end;

{--Spezialsuche--}

    if spez then with srec^ do begin
      if DateFit and SizeFit and TypeFit and StatOk then begin
        dbReadN(mbase,mb_betreff,betr2);
        if (betr<>'') and (length(betr2)=40) then begin
          ReadHeader(hdp^,hds,false);
          if length(hdp^.betreff)>40 then
            betr2:=hdp^.betreff;
        end;
        dbReadN(mbase,mb_absender,user2);
        if not ntEditBrettEmpf(mbnetztyp) then { <> Fido, QWK }
          dbReadN(mbase,mb_name,realn)
        else
          realn:=#0;
        if fidoempf<>'' then
          if not ntBrettEmpf(mbnetztyp) then
            hdp^.fido_to:=''
          else
            ReadHeader(hdp^,hds,false);
        if umlaut then begin                    {JG: Umlaute anpassen}
          UkonvStr(betr2,high(betr2));
          UkonvStr(user2,high(user2));
          UkonvStr(realn,high(realn));
          UkonvStr(hdp^.fido_to,high(hdp^.fido_to));
        end;
        if igcase then begin                    {JG: Ignore Case}
          UpString(betr2);
          UpString(user2);
          UpString(realn);
          UpString(hdp^.fido_to);
        end;
        if ((betr='') or (pos(betr,betr2)>0) xor nbetr) and
           ((user='') or ((pos(user,user2)>0) or (pos(user,realn)>0)) xor nuser) and
           ((fidoempf='') or (pos(fidoempf,hdp^.fido_to)>0) xor nfidoempf) then
        begin
          if txt<>'' then volltextcheck;             { verknuepfte Volltextsuche (SST!) }
          if ((txt='') or found) then begin
            MsgAddmark;
            inc(nf);
          end;
        end;
      end;
    end

{--Normale Suche--}

    else begin

      if check4date and (readmode >0) then
      begin                                       { Suchen im akt. Lesemodus }
        if readmode=1 then begin
          dbReadN(mbase,mb_gelesen,b);
          if b>0 then exit;
        end
        else if aktdispmode <> 10 then begin
          dbReadN(mbase,mb_empfdatum,d);
          if smdl(d,readdate) then exit;
        end;
      end;
                                                  { Headereintragsuche }
      if suchfeld<>'' then begin
        dbRead(mbase,suchfeld,such);
        if stricmp(suchfeld,'betreff') and (length(such)=40) then begin
          ReadHeader(hdp^,hds,false);
          if length(hdp^.betreff)>40 then
            such:=hdp^.betreff;
        end;
        if suchfeld='MsgID' then begin
          ReadHeader(hdp^,hds,false);
          such:=hdp^.msgid;
        end;
        if umlaut then UkonvStr(such,high(such));
        j:=0;
        repeat
          seek:=left(mid(sst,seekstart[j]),seeklen[j]);      { Erklaerung siehe Volltextcheck }
          found:=((igcase and (pos(seek,UStr(such))>0)) or
           (not igcase and (pos(seek,such)>0)));
          found_not:=found and seeknot[j];
          if suchand and not found and seeknot[j] then found:=true;
          inc(j);
        until (j=suchanz) or (suchand xor found) or found_not;
        if found_not then found:=false;
        if Found then Begin
          MsgAddmark;
          inc(nf);
        end
        else
        if (suchfeld='Absender') and (not found_not) and not ntEditBrettEmpf(mbnetztyp) then
        begin
          dbReadN(mbase,mb_name,such); { Bei Usersuche auch Realname ansehen... }
          if umlaut then UkonvStr(such,high(such));
          j:=0;
          repeat
            seek:=left(mid(sst,seekstart[j]),seeklen[j]);     { Erklaerung siehe Volltextcheck }
            found:=((igcase and (pos(seek,UStr(such))>0)) or
            (not igcase and (pos(seek,such)>0)));
            found_not:=found and seeknot[j];
            if suchand and not found and seeknot[j] then found:=true;
            inc(j);
          until (j=suchanz) or (suchand xor found) or found_not;
          if found_not then found:=false;
          if Found then begin
            MsgAddmark;
            inc(nf);
          end
        end;
      end

      else begin                           { Volltextsuche }
        volltextcheck;
        if found then begin
          MsgAddmark;
          inc(nf);
        end;
      end;
    end;
  end;

  procedure TestBrett(_brett:string);
  begin
    if check4date and (aktdispmode=10) and (readmode>1)
      then dbSeek(mbase,miBrett,_brett+dbLongStr(readdate))
    else dbSeek(mbase,miBrett,_brett);
    while not dbEof(mbase) and (dbReadStr(mbase,'brett')=_brett) and not brk do
    begin
      TestMsg;
      dbNext(mbase);
      testbrk(brk);
    end;
  end;

  function userform(s:string):string;
  var p : byte;
  begin
    p:=cpos('@',s);
    if p=0 then userform:=s
    else userform:=trim(left(s,p-1))+'@'+trim(mid(s,p+1));
  end;



{--# Suche #--}

begin
  (*
  if suchopt[1]='*' then
  begin                              { Erste Suche seit Programmstart ? }
    if UStr(getres(1))='XP.HLP' then
      suchopt:='ai�'
    else                             { Dann Suchoptionen auf Deutsch/Englisch anpassen }
      suchopt:='ai';
  end;
  *)
  for i:=0 to 4 do bera[i]:=getres2(442,i);
  for i:=0 to 5 do stata[i]:=getres2(442,10+i);
  for i:=0 to 6 do typa[i]:=getres2(442,20+i);
  if srec=nil then begin
    new(srec);
    fillchar(srec^,sizeof(srec^),0);
    with srec^ do begin
      vondat:='01.01.80'; bisdat:='31.12.69';
      vonkb:=0; biskb:=maxlongint div 2048;
      typ:=typa[0]; status:=stata[0];
    end;
  end;
  spez:=(suchfeld='*');
  case aktdispmode of
    -1,0 : bretter:=bera[iif(bmarkanz>0,3,1)];
    1..4 : bretter:=bera[iif(bmarkanz>0,3,2)];
    10   : bretter:=bera[4];
  else     bretter:=bera[0];
  end;
  i:=0;
  while (i<=4) and (bretter<>bera[i]) do inc(i);
  if i>4 then bretter:=bera[0];


{-- Eingabemaske Normalsuche --}

  if not spez then begin
    add:=0;
(*  if autosuche='' then begin *)
      dialog(51,7,getreps2(441,1,anztxt),x,y);         { '%s-Suche' }
      if autosuche<>'' then suchstring:=autosuche
      else if suchfeld='Betreff' then suchstring:=srec^.betr
      else if suchfeld='Absender' then suchstring:=srec^.user
      else if suchfeld='MsgID' then suchstring:=srec^.mid       { MID Suche aus Menue }

      else suchstring:=srec^.txt;
      seek:=suchstring;
      maddstring(3,2,getres2(441,2),suchstring,32,SuchLen,range(' ',#255));
      mnotrim;
      if history0 <> '' then  { Bei Leerer Suchhistory kein Auswahlpfeil... }
      begin
        mappsel(false,history0);
        mappsel(false,history1);
        mappsel(false,history2);
      end;
      mset3proc(seek_cutspace);
      mhnr(530);                                       { 'Suchbegriff ' }
      maddstring(3,4,getres2(441,3),suchopt,8,8,'');   { 'Optionen    ' }
      mid_options:=fieldpos;
      maddstring(31,4,getres2(441,4),bretter,8,8,'');  { 'Bretter '     }
      mid_bretter:=fieldpos;
      if aktdispmode=11 then
        MDisable
      else begin
        for i:=0 to 4 do
          mappsel(true,bera[i]);    { Alle / Netz / User / markiert / gew�hlt }
        mset1func(testbrettscope);
      end;
      if autosuche<>'' then _keyboard(keypgdn);

      if suchfeld='MsgID' then
      begin
        Mid_teilstring:=false;
        Maddbool(3,6,getres2(442,27),Mid_teilstring);
        MSet1func(Mid_suchoption);
        if mid_suchoption(suchfeld) then;
      end;

      readmask(brk);
      closemask;
      if suchstring <> seek then
      begin
        if  (seek<>history0) and (seek<>history1) and (seek<>history2) then
        begin
          history2:=history1;
          history1:=history0;
          history0:=seek;
        end;
      end;
      if suchfeld='Betreff' then begin
        i:=ReCount(suchstring);         { JG:15.02.00 Re's wegschneiden }
        srec^.betr:=suchstring
      end

      else if suchfeld='Absender' then begin
        suchstring:=userform(suchstring);
        srec^.user:=suchstring;
      end

      else if suchfeld='MsgID' then srec^.mid:=suchstring

      else srec^.txt:=suchstring;
      if suchstring='' then goto ende;
      dec(x); inc(y);
    end


{--Eingabemaske Spezialsuche--}

  else with srec^ do begin
    add:=iif(ntBrettEmpfUsed,1,0);
    dialog(50,12+add,getreps2(441,1,anztxt),x,y);
    i:=6;
    while (i>0) and (ustr(typ)<>ustr(typa[i])) do dec(i);
    typ:=typa[i];
    i:=5;
    while (i>0) and (ustr(status)<>ustr(stata[i])) do dec(i);
    status:=stata[i];
    maddstring(3,2,getres2(441,6),user,32,SuchLen,'');  mhnr(630);   { 'Absender  ' }
    maddstring(3,3,getres2(441,7),betr,32,SuchLen,'');    { 'Betreff   ' }
    mnotrim;
    mset3proc(seek_cutspace);
    maddstring(3,4,getres2(441,8),txt,32,SuchLen,'');     { 'Text      ' }
    mnotrim;
    mset3proc(seek_cutspace);
    if ntBrettEmpfUsed then
      maddstring(3,5,getres2(441,9),fidoempf,32,SuchLen,'');    { 'Fido-Empf.' }
    madddate(3,6+add,getres2(441,10),vondat,false,false); mhnr(634); { 'von Datum ' }
    madddate(3,7+add,getres2(441,11),bisdat,false,false); mhnr(634); { 'bis Datum ' }
    maddint(27,6+add,getres2(441,19),vonkb,6,5,0,99999);  mhnr(635); { 'von ' }
      maddtext(42,6+add,getres(14),0);   { 'KBytes' }
    biskb:=min(biskb,99999);
    maddint(27,7+add,getres2(441,20),biskb,6,5,0,99999);  mhnr(635); { 'bis ' }
      maddtext(42,7+add,getres(14),0);   { 'KBytes' }
    maddstring(3,9+add,getres2(441,12),typ,8,11,'');        { 'Typ       ' }
    for i:=0 to 6 do
      mappsel(true,typa[i]);
    maddstring(3,10+add,getres2(441,13),status,8,8,'');     { 'Status    ' }
    for i:=0 to 5 do
      mappsel(true,stata[i]);
    maddstring(27,9+add,getres2(441,14),bretter,8,8,'');   { 'Bretter   ' }
    if aktdispmode=11 then
      MDisable
    else begin
      for i:=0 to 4 do
        mappsel(true,bera[i]);
      mset1func(testbrettscope);
    end;
    maddstring(27,10+add,getres2(441,15),suchopt,8,8,'');   { 'Optionen  ' }
    readmask(brk);
    closemask;
    dec(x);
  end;

{--Eingaben auswerten--}

  if not brk then with srec^ do begin
    sst:=suchstring;
    igcase:=multipos('iu',lstr(suchopt));
    umlaut:=multipos('���u',lstr(suchopt)); {JG:15.02.00 Umlautschalter}
    check4date:=cpos('l',lstr(suchopt))>0;  {Suchen ab aktuellem Lesedatum}
    {sword :=pos('w',lstr(suchopt))>0;}
    bereich:=0;
    for i:=1 to 4 do
      if ustr(bretter)=ustr(bera[i]) then bereich:=i;
    statb:=0;
    for i:=1 to 5 do
      if ustr(status)=ustr(stata[i]) then statb:=i;
    me:=true;
    attrtxt(col.coldialog);

    if spez then with srec^ do begin
      sst:=txt;
      user:=userform(user);
      if umlaut then begin                              {JG:15.02.00 umlaute konvertieren}
        UkonvStr(betr,high(betr)); UkonvStr(user,high(user));
       { UkonvStr(txt,high(txt));} UkonvStr(fidoempf,high(fidoempf));
      end;                                              {/JG}
      if igcase then begin
        UpString(betr); UpString(user); {UpString(txt);} UpString(fidoempf);
      end;
      scantilde(betr,nbetr); scantilde(user,nuser);
      scantilde(fidoempf,nfidoempf);
      if ustr(typ)=ustr(typa[1]) then typc:='T'
      else if ustr(typ)=ustr(typa[2]) then typc:='B'
      else if ustr(typ)=ustr(typa[3]) then typc:='F'
      else if ustr(typ)=ustr(typa[4]) then typc:='M'
      else if ustr(typ)=ustr(typa[5]) then typc:='H'
      else if ustr(typ)=ustr(typa[6]) then typc:='R'
      else typc:=' ';
      _vondat:=ixdat(copy(vondat,7,2)+copy(vondat,4,2)+copy(vondat,1,2)+'0000');
      _bisdat:=ixdat(copy(bisdat,7,2)+copy(bisdat,4,2)+copy(bisdat,1,2)+'2359');
      if biskb=99999 then biskb:=maxlongint div 2048;
      minsize:=vonkb*1024;
      maxsize:=biskb*1024+1023;
    end;
   { else begin}
    if umlaut then UkonvStr(sst,high(sst));                        {JG:15.02.00}
    if igcase then UpString(sst);
    {  end;}

{--Start der Suche--}

    if (suchfeld='MsgID') and NOT MID_teilstring then begin      {-- Suche: Message-ID  --}
      suche:=false;
      if not brk then begin
        markanz:=0;
        (*check_seekmode;                 {!!}
        for i:=0 to suchanz-1 do { JG: JG:- MsgId-Suche mit mehreren Strings }
        begin          { mAx: sp�ter einmal begutachten, deshalb deaktiviert }
          seek:=copy(suchstring,seekstart[i],seeklen[i]); {!!}
          n:=GetBezug(seek);*)
          n:=GetBezug(suchstring);
          if n<>0 then begin
            dbGo(mbase,n);
            MsgAddmark;
          end;
        {end;}
      end;
    end
                             { Anzeige fuer Alle anderen Suchvarianten }
    else begin
      { if spez then sst:=txt; } { Bei Spezialsuche nur im Volltext... }
      check_seekmode;            { Vorbereiten fuer verknuepfte Suche }
      if brk then goto ende;

      mwrt(x+3,y+iif(spez,11+add,4),getres2(441,16)); { 'Suche:         passend:' }
      if aktdispmode<>11 then markanz:=0;
      n:=0; nf:=0;
      new(hdp);
      attrtxt(col.coldiahigh);
      psize:=min(maxavail-10000,60000);
      getmem(p,psize);
      brk:=false;

      if aktdispmode=11 then begin                       {-- Suche markiert (Weiter suchen) --}
        i:=0;
        while i<markanz do begin
          dbGo(mbase,marked^[i].recno);
          msgunmark;
          TestMsg;
          if MsgMarked then inc(i);
        end;
        aufbau:=true;
      end

      else if bereich<3 then begin                       {-- Suche: Alle/Netz/User --}
        mi:=dbGetIndex(mbase);
        dbSetIndex(mbase,0);
        dbGoTop(mbase);
        brk:=false;
        while not dbEOF(mbase) and (markanz<maxmark) and not brk do begin
          dbReadN(mbase,mb_brett,_brett);
          if (bereich=0) or ((bereich=1) and (_brett[1]='A')) or
                            ((bereich=2) and (_brett[1]='U')) then
            TestMsg;
          if not dbEOF(mbase) then    { kann passieren, wenn fehlerhafter }
            dbNext(mbase);            { Satz gel�scht wurde               }
          testbrk(brk);
        end;
        dbSetIndex(mbase,mi);
      end

      else begin                                         {-- Suche: aktuelles Brett --}
        mi:=dbGetIndex(mbase);
        dbSetIndex(mbase,miBrett);
        if bereich=3 then begin     { markiert }
          if aktdispmode<10 then begin
            i:=0;
            uu:=(aktdispmode>0);
            while (i<bmarkanz) and not brk do begin
              if uu then begin
                dbGo(ubase,bmarked^[i]);
                TestBrett(mbrettd('U',ubase));
              end
              else begin
                dbGo(bbase,bmarked^[i]);
                dbReadN(bbase,bb_brettname,brett);
                TestBrett(mbrettd(brett[1],bbase));
              end;
              inc(i);
            end;
          end;
        end
        else
        case aktdispmode of
          -1..0 : begin
                    dbReadN(bbase,bb_brettname,brett);
                    TestBrett(mbrettd(brett[1],bbase));
                  end;
           1..4 : TestBrett(mbrettd('U',ubase));
             10 : TestBrett(such_brett);
        else      begin
                    hinweis(getres2(441,17));   { 'kein Brett gew�hlt' }
                    me:=false;
                  end;
        end;
        dbSetIndex(mbase,mi);
      end;

      if spez then with srec^ do
      begin               { Spezial: NOT-Flags wieder an Suchstrings setzen }
        if nbetr then betr:='~'+betr;
        if nuser then user:='~'+user;
        if nfidoempf then fidoempf:='~'+fidoempf;
      end;

      freemem(p,psize);
      CloseBox;
      dispose(hdp);
    end;

{--Suche beendet--}

    if markanz=0 then
      if me then begin
        hinweis(getres2(441,18));   { 'keine passenden Nachrichten gefunden' }
        aufbau:=true;   { wg. gel�schter Markierung! }
        suche:=false;
        if (suchfeld='MsgID') and not MID_teilstring and (pos('@',suchstring)<>0) and
           (suchstring=mailstring(suchstring,false)) then begin
          closebox;
          if ReadJN(getres(480),true) then begin { 'Soll die Nachricht zur Message-ID angefordert werden' }
            box:=UniSel(1,false,DefaultBox);
            if box<>'' then box:=getbfn(box) else
              { 'Nachricht beim ersten erreichbaren Server holen?' }
              if ReadJN(getres(347),false) then box:='*'
              else begin
                freeres;
                exit;
              end;
            if (box<>'*') and (nt<>nt_ppp) then begin
              fehler(getres(170)); {'Diese Funktion wird nur bei RFC/PPP-Boxtypen unterst�tzt'}
              freeres;
              exit;
            end;
            reqfname:=ownpath+midreqfile;
            assign(reqfile,reqfname);
            if not exist(reqfname) then rewrite(reqfile) else reset(reqfile);
            for i:=1 to filesize(reqfile) do begin
              read(reqfile,midrec);
              if (midrec.aktiv<>0) and (midrec.mid='<'+suchstring+'>') then begin
                if ReadJN(getres(137),false) then begin { 'Anforderung besteht bereits. Stornieren' }
                  system.seek(reqfile,i-1);
                  midrec.aktiv:=0;
                  midrec.zustand:=0;
                  midrec.box:='';
                  midrec.mid:='';
                  write(reqfile,midrec);
                end;
                close(reqfile);
                (*
                rmessage(481); { 'Anforderung existiert bereits' }
                wkey(1,false);
                closebox;
                *)
                freeres;
                exit;
              end;
            end;
            system.seek(reqfile,filesize(reqfile));      { eof }
            midrec.aktiv:=1;
            midrec.zustand:=0;
            midrec.box:=box;
            midrec.mid:='<'+suchstring+'>';
            write(reqfile,midrec);
            close(reqfile);
            rmessage(479); { 'Angeforderte Nachrichten werden beim n�chsten Netcall requestet' }
            wkey(1,false);
            closebox;
            freeres;
            exit;
          end;
        end;
      end
      else
    else begin
      suche:=true;
      signal;
    end;
  end

  else begin   { brk }
ende:
    suche:=false;
    CloseBox;
  end;
  freeres;
end;
{ R+}



{ Betreff-Direktsuche }

procedure betreffsuche;
var betr,betr2   : string;
    brett,_Brett : string[5];
    ll     : integer;

begin
  moment;
  dbReadN(mbase,mb_betreff,betr);
  ReCount(betr);  { schneidet Re's weg }
  betr:=trim(betr);
  UkonvStr(betr,high(betr));
  dbReadN(mbase,mb_brett,brett);
  dbSetIndex(mbase,miBrett);
  dbSeek(mbase,miBrett,brett);
  markanz:=0;
  repeat
    dbReadN(mbase,mb_betreff,betr2);
    ReCount(betr2);
    betr2:=trim(betr2);
    UkonvStr(betr2,high(betr2));
    ll:=min(length(betr),length(betr2));
    if (ll>0) and (ustr(left(betr,ll))=ustr(left(betr2,ll))) then
      MsgAddmark;
    dbSkip(mbase,1);
    if not dbEOF(mbase) then
      dbReadN(mbase,mb_brett,_brett);
  until dbEOF(mbase) or (_brett<>brett);
  closebox;
  signal;
  if markanz>0 then
    select(11);
  aufbau:=true;
end;


procedure SucheWiedervorlage;
var x,y,xx : byte;
    brk    : boolean;
    _brett : string[5];
    mbrett : string[5];
    dat    : string[4];
    n,nn   : longint;
    bi     : shortint;

  procedure testbase(xbase:pointer);
  begin 
    bi:=dbGetIndex(xbase);
    if xbase=bbase then begin
      dbSetIndex(xbase,bibrett);
      dbGoTop(xbase);
      end
    else begin
      dbsetindex(xbase,uiadrbuch);
      dbseek(xbase,uiadrbuch,#1); 
      end; 
    dat:=dbLongStr(ixDat('2712310000'));


    brk:=false;
    dbSetIndex(mbase,miBrett);
    while not dbEOF(xbase) and not brk do begin
      inc(n);
      gotoxy(xx,y+2); attrtxt(col.colmboxhigh);
      write(n*100 div nn:3);
      if (xbase=ubase) or (not smdl(dbReadInt(xbase,'ldatum'),ixDat('2712310000')))
      then begin
        if xbase=ubase then _brett:='U' else 
        _brett:=copy(dbReadStr(xbase,'brettname'),1,1);
        _brett:=_brett+dbLongStr(dbReadInt(xbase,'int_nr'));
        dbSeek(mbase,miBrett,_brett+dat);
        mbrett:=_brett;
        while not dbEOF(mbase) and (mbrett=_brett) do begin
          dbReadN(mbase,mb_brett,mbrett);
          if mbrett=_brett then MsgAddmark;
          dbSkip(mbase,1);
          end;
        end;
      dbSkip(xbase,1);
      testbrk(brk);
      end;
    dbSetIndex(xbase,bi);
  end;

begin 

  markanz:=0;
  msgbox(33,5,'',x,y);
  wrt(x+3,y+2,getres(443));   { 'Einen Moment bitte...     %' }
  xx:=wherex-5; 
  n:=0;
  nn:=dbRecCount(bbase)+dbreccount(ubase);

  testbase(ubase);
  if not brk then 
    testbase(bbase);
  closebox;
  if not brk then
    if markanz=0 then
      hinweis(getres(444))   { 'keine Wiedervorlage-Nachrichten gefunden' }
    else begin
      signal;
      select(11);
      end;
end;


{$I XP4O.INC}     { Reorg }


procedure ModiEmpfDatum;
var d   : datetimest;
    brk : boolean;
    l   : longint;
begin
  d:=fdat(longdat(dbReadInt(mbase,'empfdatum')));
  EditDate(15,11+(screenlines-25)div 2,getres(452),d,brk);   { 'neues Empfangsdatum:' }
  if not brk then begin
    l:=ixdat(copy(d,7,2)+copy(d,4,2)+copy(d,1,2)+'0000');
    dbWriteN(mbase,mb_empfdatum,l);
    aufbau:=true;
    end;
end;


function testuvs(txt:atext):boolean;
var uvs : byte;
begin
  dbReadN(mbase,mb_unversandt,uvs);
  if uvs and 1<>0 then rfehler1(422,txt);  { 'Bitte verwenden Sie Nachricht/Unversandt/%s' }
  testuvs:=(uvs and 1<>0);
end;


procedure ModiBetreff;
var brk  : boolean;
    hdp  : headerp;
    hds  : longint;
    x,y  : byte;
    fn   : pathstr;
    f    : file;
begin
  if testuvs(getres(453)) then exit;   { '�ndern' }
  new(hdp);
  ReadHeader(hdp^,hds,true);
  if hds>1 then begin
    diabox(63,5,'',x,y);
    readstring(x+3,y+2,getres(454),hdp^.betreff,40,BetreffLen,'',brk);  { 'neuer Betreff:' }
    closebox;
    if not brk then begin
      PGP_BeginSavekey;
      fn:=TempS(dbReadInt(mbase,'msgsize')+100);
      assign(f,fn);
      rewrite(f,1);
      { ClearPGPflags(hdp); }
      hdp^.orgdate:=true;
      WriteHeader(hdp^,f,reflist);
      XreadF(hds,f);   { den Nachrichtentext anh�ngen ... }
      close(f);
      Xwrite(fn);
      erase(f);
      wrkilled;
      TruncStr(hdp^.betreff,40);
      dbWriteN(mbase,mb_betreff,hdp^.betreff);
      PGP_EndSavekey;
      aufbau:=true;
      xaufbau:=true;
      end;
    end;
  dispose(hdp);
end;


procedure ModiHighlite;
var l : longint;
begin
  dbReadN(mbase,mb_netztyp,l);
  l:=l xor $1000;
  dbWriteN(mbase,mb_netztyp,l);
  aufbau:=true;
end;


procedure ModiText;
var fn   : pathstr;
    fn2  : pathstr;
    f,f2 : file;
    hdp  : headerp;
    hds  : longint;
    typ  : char;
    l    : longint;
begin
  dbReadN(mbase,mb_typ,typ);
  if typ='B' then begin
    rfehler(423);   { 'Bei Bin�rdateien nicht m�glich' }
    exit;
    end;
  if testuvs(getres(455)) then exit;   { 'Edit' }
  new(hdp);
  ReadHeader(hdp^,hds,true);           { Heder einlesen }
  if hds>1 then begin
    PGP_BeginSavekey;
    fn:=TempS(dbReadInt(mbase,'msgsize'));
    assign(f,fn);
    rewrite(f,1);
    XReadIsoDecode:=true;
    XreadF(hds,f);                { Nachrichtentext in Tempfile.. }
    close(f);
    editfile(fn,true,false,0,false);          { ..editieren.. }
    fn2:=TempS(_filesize(fn)+2000);
    assign(f2,fn2);
    rewrite(f2,1);
    hdp^.groesse:=_filesize(fn);
    dbWriteN(mbase,mb_groesse,hdp^.groesse);
    hdp^.charset:='';
    { ClearPGPflags(hdp); }
    hdp^.orgdate:=true;
    WriteHeader(hdp^,f2,reflist);   { ..Header in neues Tempfile.. }
    reset(f,1);
    fmove(f,f2);                  { ..den Text dranh�ngen.. }
    close(f); erase(f);
    close(f2);
    dbReadN(mbase,mb_netztyp,l);
    l:=l and (not $2000);         { ISO-Codierung abschalten }
    dbWriteN(mbase,mb_netztyp,l);
    Xwrite(fn2);                  { ..und ab in die Datenbank. }
    erase(f2);
    wrkilled;
    PGP_EndSavekey;
    aufbau:=true;                 { wg. ge�nderter Gr��e }
    end;
  dispose(hdp);
end;


procedure ModiRot13;
var ablg   : byte;
    adr    : longint;
    f      : file;
    l,size : longint;
    p      : pointer;
    ps  : word;
    rr: word;
    typ    : char;
begin
  dbReadN(mbase,mb_typ,typ);
  if typ='B' then begin
    rfehler(423);   { 'Bei Bin�rdateien nicht m�glich' }
    exit;
    end;
  if testuvs(getres(453)) then exit;   { '�ndern' }
  dbReadN(mbase,mb_ablage,ablg);
  dbReadN(mbase,mb_adresse,adr);
  dbReadN(mbase,mb_groesse,size);
  assign(f,aFile(ablg));
  reset(f,1);
  if (size=0) or (adr+size>filesize(f)) then begin
    rfehler1(424,strs(ablg));   { 'Nachricht ist besch�digt  (Ablage %s)' }
    close(f);
    end
  else begin
    ps:=min(maxavail,30000);
    getmem(p,ps);
    seek(f,adr+dbReadInt(mbase,'msgsize')-size);
    repeat
      l:=filepos(f);
      blockread(f,p^,min(ps,size),rr);
      Rot13(p^,rr);
      seek(f,l);
      blockwrite(f,p^,rr);
      dec(size,rr);
    until size=0;
    close(f);
    freemem(p,ps);
    end;
end;


procedure ModiTyp;
var c   : char;
    uvs : byte;
begin
  dbReadN(mbase,mb_unversandt,uvs);
  if uvs and 1<>0 then
    rfehler(425)   { 'Bei unversandten Nachrichten leider nicht m�glich.' }
  else begin
    dbReadN(mbase,mb_typ,c);
    if c='T' then c:='B'
    else c:='T';
    dbWriteN(mbase,mb_typ,c);
    aufbau:=true;
    end;
end;

procedure ModiGelesen;                    {Nachricht-Gelesen status aendern}
var b     : byte;
    brett : string[5];
begin
  if not dbBOF(mbase) then
  begin                                   {Nur Wenn ueberhaupt ne Nachricht gewaehlt ist...}  
    dbReadN(mbase,mb_gelesen,b);
    if b=1 then b:=0 else b:=1;
    dbWriteN(mbase,mb_gelesen,b);
    dbReadN(mbase,mb_brett,brett);
    if b=1 then begin
      dbSeek(mbase,miGelesen,brett+#0);
      if dbEOF(mbase) or (dbReadStr(mbase,'brett')<>brett) or (dbReadInt(mbase,'gelesen')<>0)
      then b:=0   { keine ungelesenen Nachrichten mehr im Brett vorhanden }
      else b:=2;
      end
    else
      b:=2;        { noch ungelesene Nachrichten im Brett vorhanden }
    dbSeek(bbase,biIntnr,mid(brett,2));
    if dbFound then begin
      b:=dbReadInt(bbase,'flags') and (not 2) + b;
      dbWriteN(bbase,bb_flags,b);
      end;
    aufbau:=true;
    end;
end;


{ Brettliste importieren }

procedure ImportBrettliste;
var fn  : pathstr;
    s   : string;
    t   : text;
    x,y : byte;
    n   : longint;
    useclip: boolean;
begin
  fn:='*.*';
  useclip:=true;
  if ReadFilename(getres2(456,1),fn,true,useclip) then   { 'Brettliste einlesen' }
    if not exist(fn) then
      fehler(getres2(456,2))   { 'Datei nicht vorhanden!' }
    else begin
      msgbox(30,5,'',x,y);
      wrt(x+3,y+2,getres2(456,3));   { 'Bretter anlegen ...' }
      n:=0;
      assign(t,fn);
      reset(t);
      while not eof(t) do begin
        readln(t,s);
        makebrett(s,n,DefaultBox,ntBoxNetztyp(DefaultBox),true);
        gotoxy(x+22,y+2); write(n:5);
        end;
      close(t);
      closebox;
      aufbau:=true;
      dbFlushClose(bbase);
      if useclip then _era(fn);
      end;
  freeres;
end;


{ Userliste importieren }

procedure ImportUserliste;
var fn  : pathstr;
    adrb: boolean;
    brk : boolean;
    s   : string;
    t   : text;
    x,y : byte;
    n   : longint;
    useclip: boolean;
    b   : byte;
begin
  fn:='*.*';
  useclip:=true;
  if ReadFilename(getres2(456,11),fn,true,useclip) then   { 'Userliste einlesen' }
    if not exist(fn) then
      fehler(getres2(456,2))   { 'Datei nicht vorhanden!' }
    else begin
      dialog(38,3,'',x,y);
      adrb:=true;
      maddbool(3,2,getres2(456,12),adrb);   { 'User in Adre�buch eintragen' }
      readmask(brk);
      enddialog;
      if brk then exit;
      msgbox(34,5,'',x,y);
      wrt(x+3,y+2,getres2(456,13));   { 'Userbretter anlegen ...' }
      n:=0;
      assign(t,fn);
      reset(t);
      b:=0;
      while not eof(t) do begin
        readln(t,s);
        s:=trim(s);
        if cpos('@',s)>0 then begin
          dbSeek(ubase,uiName,ustr(s));
          if not dbFound then begin
            inc(n);
            makeuser(s,DefaultBox);
            if not adrb then dbWriteN(ubase,ub_adrbuch,b);
            gotoxy(x+26,y+2); write(n:5);
            end;
          end;
        end;
      close(t);
      wkey(1,false);
      closebox;
      aufbau:=true;
      dbFlushClose(ubase);
      if useclip then _era(fn);
      end;
  freeres;
end;


{ User-/Brettliste exportieren }

procedure ExportUB(user:boolean);
var fname : pathstr;
    t     : text;
    d     : DB;
    x,y,xx: byte;
    cnt,n : longint;
    exkom : boolean;
    brk   : boolean;
    useclip: boolean;

label ende;

  function komform(d:DB; s:string):string;
  var kom : string[30];
  begin
    dbRead(d,'kommentar',kom);
    if exkom and (kom<>'') then
      komform:=forms(s,80)+kom
    else
      komform:=s;
  end;

begin
  fname:='';
  useclip:=true;
  if ReadFilename(getres2(457,iif(user,1,2)),fname,true,useclip)
  then
    if not ValidFileName(fname) then
      fehler(getres2(457,3))   { 'ung�ltiger Dateiname' }
    else begin
      exkom:=ReadJNesc(getres2(457,4),false,brk);  { 'auch Kommentare exportieren' }
      if brk then begin
        if useclip then _era(fname);
        goto ende;
        end;
      if user then begin
        dbSetIndex(ubase,uiName);
        d:=ubase;
        end
      else begin
        dbSetIndex(bbase,biBrett);
        d:=bbase;
        end;
      msgbox(34,5,'',x,y);
      wrt(x+3,y+2,getres2(457,iif(user,5,6)));  { 'erzeuge User/Brettliste...     %' }
      xx:=wherex-5;
      if not multipos(':\',fname) then fname:=ExtractPath+fname;
      assign(t,fname);
      rewrite(t);
      if not user then dbSeek(d,biBrett,'A')
      else dbGoTop(d);
      cnt:=dbRecCount(d); n:=0;
      while not dbEOF(d) do begin
        attrtxt(col.colmboxhigh);
        gotoxy(xx,y+2); write(n*100 div cnt:3);
        if user then
          if dbReadInt(ubase,'userflags') and 4=0 then  { keine Verteiler }
            writeln(t,komform(ubase,dbReadStr(ubase,'username')))
          else
        else
          writeln(t,komform(bbase,copy(dbReadStr(bbase,'brettname'),2,80)));
        dbNext(d);
        inc(n);
        end;
      close(t);
      if useclip then WriteClipfile(fname);
      closebox;
      end;
ende:
  freeres;
end;


procedure zeige_unversandt;
var _brett   : string[5];
    _mbrett  : string[5];
    sr       : searchrec;
    f        : file;
    hdp      : headerp;
    rr       : word;
    hds      : longint;
    ok       : boolean;
    adr,fsize: longint;
    box      : string[BoxNameLen];
    uvf      : boolean;
    uvs      : byte;
    mtyp     : char;
    ntyp     : longint;
    zconnect : boolean;
    crashs   : boolean;

  procedure fehlt;
  begin
    rfehler(426);   { 'Nachricht ist nicht mehr in der Datenbank vorhanden!' }
  end;

begin
  if uvs_active then exit;
  crashs:=false;
  findfirst('*.pp',DOS.Archive,sr);
  if doserror<>0 then begin
    findfirst('*.cp',DOS.Archive,sr);
    crashs:=true;
  end;
  markanz:=0;
  moment;
  new(hdp);
  while doserror=0 do begin
    if crashs then begin
      box:=strs(hexval(left(sr.name,4)))+'/'+strs(hexval(copy(sr.name,5,4)));
      { ^^^ nur f�r Anzeige bei fehlerhaftem CP }
      zconnect:=true;
    end
    else begin
      box:=file_box(nil,left(sr.name,pos('.',sr.name)-1));
      zconnect:=ntZConnect(ntBoxNetztyp(box));
    end;
    dbSetIndex(mbase,miBrett);
    assign(f,ownpath+sr.name);
    reset(f,1);
    adr:=0;
    fsize:=filesize(f);
    ok:=true;
    while ok and (adr<fsize) do begin
      seek(f,adr);
      makeheader(zconnect,f,1,0,hds,hdp^,ok,false);
      if not ok then
        rfehler1(427,box)   { 'fehlerhaftes Pollpaket:  %s' }
      else with hdp^ do begin
        _brett:='';
        if (cpos('@',empfaenger)=0) and
           ((netztyp<>nt_Netcall) or (left(empfaenger,1)='/'))
        then begin
          dbSeek(bbase,biBrett,'A'+ustr(empfaenger));
          if not dbFound then fehlt
          else _brett:='A'+dbLongStr(dbReadInt(bbase,'int_nr'));
        end
        else begin
          dbSeek(ubase,uiName,ustr(empfaenger+
                 iifs(pos('@',empfaenger)>0,'','@'+box+'.ZER')));
          if not dbFound then fehlt
          else _brett:='U'+dbLongStr(dbReadInt(ubase,'int_nr'));
        end;
        if _brett<>'' then begin
          dbSeek(mbase,miBrett,_brett+#255);
          uvf:=false;
          if dbEOF(mbase) then dbGoEnd(mbase)
          else dbSkip(mbase,-1);
          if not dbEOF(mbase) and not dbBOF(mbase) then
            repeat
              dbReadN(mbase,mb_brett,_mbrett);
              if _mbrett=_brett then begin
                dbReadN(mbase,mb_unversandt,uvs);
                dbReadN(mbase,mb_typ,mtyp);
                dbReadN(mbase,mb_netztyp,ntyp);
                if (uvs and 1=1) and EQ_betreff(betreff)  and ((mtyp='B') or
                   ((uvs and 4 <> 0) or (ntyp and $4000<>0) or  { codiert / signiert }
                   (groesse=dbReadInt(mbase,'groesse'))))
                   and (FormMsgid(msgid)=dbReadStr(mbase,'msgid'))
                   and not msgmarked then
                begin
                  MsgAddmark;
                  uvf:=true;
                end;
              end;
              dbSkip(mbase,-1);
            until uvf or dbBOF(mbase) or (_brett<>_mbrett);
          if not uvf then
            fehlt;
        end;
        inc(adr,groesse+hds);
      end;
    end;
    close(f);
    findnext(sr);
    if (doserror<>0) and not crashs then begin
      {$IFDEF virtualpascal}
      FindClose(sr);
      {$ENDIF}
      findfirst('*.cp',DOS.Archive,sr);
      crashs:=true;
    end;
  end;
  {$IFDEF virtualpascal}
  FindClose(sr);
  {$ENDIF}
  dispose(hdp);
  closebox;
  if markanz=0 then
    hinweis(getres(458))   { 'Keine unversandten Nachrichten vorhanden!' }
  else begin
    MarkUnversandt:=true;
    uvs_active:=true;
    select(11);
    uvs_active:=false;
  end;
  aufbau:=true;
end;


procedure msg_info;     { Zerberus-Header anzeigen }
var hdp   : headerp;
    hds   : longint;
    i     : integer;
    x,y  : byte;
    dat   : datetimest;
    anz   : byte;
    xxs   : array[1..20] of string[71];
    netz  : string[20];
    p     : byte;
    elist : boolean;    { mehrere Empf�nger }
    rlist : boolean;    { mehrere References }
    t     : taste;
    s     : atext;

  procedure apps(nr:word; s:string);
  begin
    inc(anz);
    xxs[anz]:=getres2(459,nr)+' '+left(s,59);
  end;

  function ddat:string;
  begin
    with hdp^ do
      if ddatum='' then
        ddat:=''
      else
        ddat:=', '+copy(ddatum,7,2)+'.'+copy(ddatum,5,2)+'.'+left(ddatum,4)+
              ', '+copy(ddatum,9,2)+':'+copy(ddatum,11,2)+':'+copy(ddatum,13,2);
  end;

  procedure empfliste;   { Fenster mit Empf�ngerliste }
  var ml  : byte;
      i,j : integer;
      x,y : byte;
  begin
    ml:=length(getres2(459,30))+8;
    with hdp^ do begin
      for i:=1 to empfanz do begin
        ReadHeadEmpf:=i;
        ReadHeader(hdp^,hds,false);
        ml:=max(ml,length(empfaenger)+6);
        end;
      ml:=min(ml,72);
      i:=min(empfanz,screenlines-8);
      msgbox(ml,i+4,getres2(459,30),x,y);   { 'Empf�ngerliste' }
      for j:=1 to i do begin
        ReadHeadEmpf:=j;
        ReadHeader(hdp^,hds,false);
        mwrt(x+3,y+1+j,left(empfaenger,72));
        end;
      wait(curoff);
      if rlist and (ustr(lastkey)='R') then keyboard('R');
      closebox;
      end;
  end;

  procedure refliste;   { Fenster mit Referenzliste }
  var ml  : byte;
      i,j : integer;
      x,y : byte;
      p   : refnodep;
    procedure writeref(p:refnodep);
    begin
      wrt(x+3,j,left(p^.ref,72));
      inc(j);
    end;
    procedure showrefs(list:refnodep);
    begin
      if list<>nil then begin
        showrefs(list^.next);
        writeref(list);
        end;
    end;
  begin
    ml:=length(getres2(459,31))+8;
    with hdp^ do begin
      p:=reflist;
      while p<>nil do begin
        ml:=max(ml,length(p^.ref)+6);
        p:=p^.next;
        end;
      ml:=max(ml,length(ref)+6);
      ml:=min(ml,72);
      i:=min(refanz,screenlines-8);
      msgbox(ml,i+4,getres2(459,31),x,y);   { 'Empf�ngerliste' }
      j:=y+2;
      showrefs(reflist);
      wrt(x+3,y+i+1,left(ref,72));
      wait(curoff);
      if elist and (ustr(lastkey)='E') then keyboard('E');
      closebox;
      end;
  end;

  function typstr(typ,mimetyp:string):string;
  begin
    if mimetyp<>'' then
      typstr:=extmimetyp(mimetyp)
    else begin
      UpString(typ);
      if typ='T' then typstr:=typ+getres2(459,1) else   { '  (Text)' }
      if typ='B' then typstr:=typ+getres2(459,2) else   { '  (bin�r)' }
      typstr:=typ;
      end;
  end;

begin
  new(hdp);
  ReadHeader(hdp^,hds,true);
  anz:=0;
  with hdp^ do begin
    apps(3,empfaenger);
    if fido_to<>'' then apps(4,fido_to);
    apps(5,betreff);
    apps(6,left(absender,59));
    if realname<>'' then apps(7,realname);
    if organisation<>'' then apps(8,left(organisation,59));
    if PmReplyTo<>'' then apps(9,left(PmReplyTo,59));
    apps(10,iifs(ntZDatum(netztyp),zdatum,datum)+
         iifs(datum<>'','  ('+fdat(datum)+', '+ftime(datum)+
         iifs(ntSec(netztyp),':'+copy(zdatum,13,2),'')+')',''));
    apps(11,left(pfad,59));
    repeat
      pfad:=mid(pfad,60);
      if pfad<>'' then apps(12,left(pfad,59));
    until pfad='';
    if msgid<>''    then apps(13,msgid);
    if ref<>''      then apps(14,ref);
    if pm_bstat<>'' then apps(15,pm_bstat);
    apps(16,typstr(typ,mimetyp));
    if programm<>'' then apps(17,programm);
    if datei<>''    then apps(18,datei+ddat);
    apps(19,strs(groesse)+getres(13));
    if komlen>0 then apps(21,strs(komlen)+getres(13));
    if attrib<>0 then
      apps(22,hex(attrib,4)+' - '+
           iifs(attrib and attrCrash<>0,'Crash ','')+
           iifs(attrib and attrFile<>0,'File ','')+
           iifs(attrib and attrReqEB<>0,'Req-EB ','')+
           iifs(attrib and attrIsEB<>0,'EB ','')+
           iifs(attrib and attrPmReply<>0,'PM-Reply ','')+
           iifs(attrib and attrQuoteTo<>0,'QuoteTo ','')+
           iifs(attrib and attrControl<>0,'Control ',''));
    if (netztyp in [nt_UUCP,nt_PPP]) then netz:=' / RFC'
    else begin
      netz:=ntName(netztyp);
      if netz='???' then netz:=''
      else netz:=' / '+netz;
      end;
    msgbox(76,anz+7,getres2(459,23)+' ('+            { 'Nachrichtenkopf' }
                    getres2(459,iif(ntZConnect(netztyp),24,25))+netz+')',x,y);
    moff;
    for i:=1 to anz do begin
      if left(xxs[i],1)=' ' then p:=0
      else p:=cpos(':',xxs[i]);
      if p>0 then begin
        attrtxt(col.colmboxhigh);
        wrt(x+3,y+i+1,left(xxs[i],p));
        end;
      attrtxt(col.colmbox);
      wrt(x+3+p,y+i+1,mid(xxs[i],p+1));
      end;
    attrtxt(col.colmboxhigh); wrt(x+3,y+anz+3,getres2(459,26));  { 'Gr��e des Kopfes: ' }
    attrtxt(col.colmbox);     write(hds,getres(13));
    dat:=longdat(dbReadInt(mbase,'empfdatum'));
    if smdl(IxDat('2712300000'),IxDat(dat)) then
      dat:=longdat(dbReadInt(mbase,'wvdatum'));
    attrtxt(col.colmboxhigh); wrt(x+40,y+anz+2,getres2(459,27));  { 'Empfangsdatum: ' }
    attrtxt(col.colmbox);     write(fdat(dat));
    attrtxt(col.colmboxhigh); wrt(x+40,y+anz+3,getres2(459,28));  { 'Ablagedatei  :' }
    attrtxt(col.colmbox);     write('MPUFFER.',dbReadInt(mbase,'ablage'));
    elist:=(empfanz>1);
    rlist:=(refanz>1);
    if elist then s:=' (E='+getres2(459,30)
    else s:='';
    if rlist then begin
      if s<>'' then s:=s+', '
      else s:=' (';
      s:=s+'R='+getres2(459,31);
      end;
    if s<>'' then s:=s+')';
    wrt(x+3,y+anz+5,getres2(459,29)+s+' ...');    { Taste dr�cken / E=Empf�ngerliste / R=Referenzliste }
    mon;
    x:=wherex; y:=wherey;
    repeat
      gotoxy(x,y);
      repeat
        get(t,curon);
      until (t<mausfirstkey) or (t>mauslastkey) or (t=mausleft) or (t=mausright);
      if elist and (ustr(t)='E') then empfliste;
      if rlist and (ustr(t)='R') then refliste;
    until (not elist or (ustr(t)<>'E')) and (not rlist or (ustr(t)<>'R'));
    end;
  closebox;
  freeres;
  dispose(hdp);
end;


procedure ShowHeader;            { Header direkt so anzeigen wie er im PUFFER steht }
var fn  : pathstr;
    f   : file;
    hdp : headerp;
    hds : longint;
    lm  : Byte;                  { Makrozwischenspeicher... }    
begin 
  ShowHdr:=true;
  new(hdp);
  ReadHeader(hdp^,hds,true);
  if hds>1 then begin
    fn:=TempS(dbReadInt(mbase,'msgsize')+1000);
    assign(f,fn);
    rewrite(f,1);
    XreadF(0,f);
    seek(f,hds);
    truncate(f);
    close(f);
    lm:=listmakros;                                   { Aktuelle Makros merken,       }
    listmakros:=16;                                   { Archivviewermakros aktivieren }
    if ListFile(fn,getres(460),true,false,0)=0 then;  { 'Nachrichten-Header' }
    listmakros:=lm;                                   { wieder alte Makros benutzen   }
    _era(fn);
  end;
  dispose(hdp);    
  ShowHdr:=false;
end;


{ Es wird nicht im Temp-, sondern im XP-Verzeichnis entpackt! }
{ exdir='' -> Lister/ArcViewer;  exdir<>'' -> Xtrakt          }
{ Fehler -> exdir:=''                                         }

procedure ShowArch(var fn:string);   { 'var' wegen Stackplatz }
var decomp : string[127];
    p      : byte;
    datei  : string[12];
    newarc : longint;
    atyp   : shortint;
    spath  : pathstr;
    ats    : shortint;
    viewer : viewinfo;
begin
  ats:=arctyp_save;
  atyp:=abuf[arcbufp]^.arcer_typ;
  if atyp>arctypes then exit;  { ??? }
  if not getDecomp(atyp,decomp) then
    exdir:=''
  else begin
    p:=pos('$DATEI',ustr(decomp));
    datei:=trim(copy(fn,2,12));
    if (exdir='') and ((temppath='') or (ustr(temppath)=ownpath))
      and exist(datei) then begin
        rfehler(428);   { 'extrahieren nicht m�glich - bitte Temp-Verzeichnis angeben!' }
        exit;
        end
    else if ((exdir<>'') and exist(exdir+datei)) or
            ((exdir='') and exist(temppath+datei)) then
      if exdir=ownpath then begin
        rfehler(429);  { 'Datei schon vorhanden - bitte Extrakt-Verzeichnis angeben!' }
        exit;
        end
      else
        if not ReadJN(getreps(461,fitpath(exdir+datei,40)),false)  { '%s existiert schon. �berschreiben' }
        then exit
        else
          _era(iifs(exdir<>'',exdir,temppath)+datei);
    spath:=ShellPath;
    if exdir<>'' then GoDir(exdir)
    else GoDir(temppath);
    decomp:=copy(decomp,1,p-1)+datei+copy(decomp,p+6,127);
    p:=pos('$ARCHIV',ustr(decomp));
    decomp:=copy(decomp,1,p-1)+abuf[arcbufp]^.arcname+copy(decomp,p+7,127);
    shell(decomp,400,3);
    if exdir='' then begin
      { !?! GoDir(temppath);     { wurde durch Shell zur�ckgesetzt }
      if not exist(temppath+datei) then
        rfehler(430)       { 'Datei wurde nicht korrekt entpackt.' }
      else begin
        newarc:=ArcType(TempPath+datei);
        if ArcRestricted(newarc) then newarc:=0;
        if newarc=0 then begin
          GetExtViewer(datei,viewer);
          if viewer.prog='' then TestGifLbmEtc(datei,false,viewer);
          if (viewer.prog<>'') and (viewer.prog<>'*intern*') then
            ViewFile(TempPath+datei,viewer,false)
          else
            ListFile(TempPath+datei,datei,true,false,0);
          end
        else
          if memavail<20000 then
            rfehler(431)   { 'zu wenig Speicher!' }
          else if arcbufp=max_arc then
            rfehler(432)   { 'Maximal 3 verschachtelte Archive m�glich!' }
          else begin
            decomp:=TempPath+datei;  { Stack sparen ... }
            if ViewArchive(decomp,newarc)<>0 then;
            end;
        if exist(temppath+datei) then
          _era(temppath+datei);
        end;
      { GoDir(OwnPath); }
      end;
    ShellPath:=spath;
    end;
  arctyp_save:=ats;
  attrtxt(col.colarcstat);
  wrt(77,4,arcname[ats]);
  keyboard(keydown);
end;


function a_getfilename(nr,nn:byte):pathstr;
var fn   : pathstr;
    sex  : pathstr;
begin
  fn:=trim(copy(get_selection,2,12));
  sex:=exdir; exdir:=TempPath;
  ShowArch(fn);
  exdir:=sex;
  a_getfilename:=TempPath+fn;
end;


procedure ArcSpecial(var t:taste);
var s   : string;
    dp  : pathstr;
    x,y : byte;
    brk : boolean;
    fk  : string[32];
    sex : pathstr;
    dd  : string[30];
begin
  if ustr(t)='X' then begin
    dp:=ExtractPath;
    dd:=getres(463);
    dialog(47+length(dd),3,getres(462),x,y);   { 'Extrakt' }
    maddstring(3,2,dd,dp,40,79,'');
    readmask(brk);
    enddialog;
    if brk then exit;
    UpString(dp);
    if (dp<>'') and (right(dp,1)<>':') and (right(dp,1)<>'\') then
      dp:=dp+'\';
    if not validfilename(dp+'test.$$1') then
      rfehler(433)   { 'ung�ltiges Verzeichnis' }
    else begin
      sex:=exdir;
      exdir:=dp;
      s:=first_marked;
      while (s<>#0) and (exdir<>'') do begin
        ShowArch(s);
        s:=next_marked;
        end;
      exdir:=sex;
      end;
    end
  else begin
    getfilename:=a_getfilename;
    fk:=forwardkeys; forwardkeys:='';
    if test_fkeys(t) then;
    keyboard(fk);
    xp1o.listext(t);
    end;
end;


{ 0=Esc, 1=minus, 2=plus }

function ViewArchive(var fn:pathstr; typ:shortint):shortint;
var ar   : ArchRec;
    brk  : boolean;
    lm   : byte;

  function dt(d,t:word):string;
  begin
    dt:=formi(d and 31,2)+'.'+formi((d shr 5) and 15,2)+'.'+
        formi((d shr 9+80)mod 100,2)+'  '+
        formi(t shr 11,2)+':'+formi((t shr 5)and $3f,2)+':'+formi((t and $1f)*2,2);
  end;

  function prozent:string;
  begin
    if ar.OrgSize>0 then
      prozent:=strsrn(ar.CompSize/ar.OrgSize*100,3,1)
    else
      prozent:='     ';
  end;

  procedure renameDWC;
  var f  : file;
      _d : dirstr;
      _n : namestr;
      _e : extstr;
  begin
    assign(f,fn);
    fsplit(fn,_d,_n,_e);
    fn:=_d+'temp$$.dwc';
    rename(f,fn);
  end;

begin
  if abs(typ)=ArcDWC then
    renameDWC;
  OpenList(1,80,5,screenlines-fnkeylines-1,1,'/NS/SB/M/NLR/');
  OpenArchive(fn,typ,ar);
  listcrp(ShowArch);
  listtp(ArcSpecial);
  showkeys(11);
  attrtxt(col.colarcstat);
  mwrt(1,4,forms(getres(464),80));   { ' Name            OrgGr��e  CompGr��e    %    Methode    Datum    Uhrzeit' }
  inc(arcbufp);
  new(abuf[arcbufp]);
  with ar do begin
    arctyp_save:=arctyp;
    abuf[arcbufp]^.arcer_typ:=arctyp;
    abuf[arcbufp]^.arcname:=fn;
    mwrt(77,4,arcname[arctyp]);
    while not ende do begin
      if (name<>'') or (path='') then
        app_l(iifc(path<>'','*',' ')+forms(name,12)+strsn(orgsize,11)+
              strsn(compsize,11)+'   '+ prozent+'  '+forms(method,10)+
              dt(datum,uhrzeit))
      else
        app_l('*'+path);
      ArcNext(ar);
      end;
    end;
  CloseArchive(ar);
  exdir:='';
  llh:=true; listexit:=0;
  lm:=ListMakros; ListMakros:=16;
  pushhp(67);
  list(brk);
  pophp;
  ListMakros:=lm;
  dispose(abuf[arcbufp]);
  dec(arcbufp);
  CloseList;
  attrtxt(col.colkeys);
  mwrt(1,2,sp(80));
  showlastkeys;
  if abs(typ)=ArcDWC then
    _era(fn);
  aufbau:=true;
  ViewArchive:=listexit;
end;



procedure FileArcViewer(fn:pathstr);
var useclip : boolean;
    arc     : shortint;
    lm      : byte;
    viewer : viewinfo;
    datei  : string[12];
    ende   : boolean;
begin
  if (fn='') or multipos('?*',fn) then begin
    if fn='' then fn:='*.*';
    useclip:=false;
    if not ReadFilename(getres(465),fn,true,useclip) then   { 'Archivdatei' }
      exit;
    fn:=FExpand(fn);
    end;
  if exist(fn) then begin
    arc:=ArcType(fn);
    if ArcRestricted(arc) then arc:=0;
    if arc=0 then begin                                 { Wenns kein Archiv war...      }
      lm:=listmakros;
      listmakros:=16;                                   { Archivviewermacros benutzen!  }
      repeat
        if listfile(fn,fn,true,false,0) = -4 then ende:=false
        else ende:=true;                                { und File einfach nur anzeigen }
      until ende;
      listmakros:=lm;
    end
      { rfehler(434)   { 'keine Archivdatei' }
    else
      if ViewArchive(fn,arc)=0 then;
    end
  else
    rfehler(22);     { 'Datei ist nicht vorhanden!' }
end;


procedure DupeKill(autodupekill:boolean);
var d     : DB;
    f1,f2 : file;
    n,ll  : longint;
    x,y   : byte;
    last,
    next  : string[30];
    flags : byte;
    log   : text;
    rec,rec2 : longint;

  procedure show;
  begin
    wrt(x+22,y+3,strsn(n,7));
    wrt(x+22,y+4,strsn(ll,7));
  end;

  procedure log_it;
  var _brett : string[5];
  begin
    dbRead(d,'brett',_brett);
    write(log,fdat(longdat(dbReadInt(d,'origdatum'))),' ');
    if _brett[1]='U' then
      write(log,forms(dbReadStr(d,'absender'),32))
    else begin
      dbSeek(bbase,biIntnr,copy(_brett,2,4));
      if dbFound then write(log,forms(copy(dbReadStr(bbase,'brettname'),2,40),32));
      end;
    writeln(log,' ',left(dbReadStr(d,'betreff'),37));
  end;

begin
  if diskfree(0)<_filesize(MsgFile+dbExt)*2 then begin
    rfehler(435);   { 'zu wenig Festplatten-Platz' }
    exit;
    end;
  message(getres2(466,1));   { 'Nachrichtendatei kopieren...' }
  dbTempClose(mbase);
  assign(f1,MsgFile+dbExt);  reset(f1,1);
  assign(f2,DupeFile+dbExt); rewrite(f2,1);
  fmove(f1,f2);
  close(f1);
  close(f2);
  if exist(DupeFile+dbIxExt) then
    _era(DupeFile+dbIxExt);
  closebox;
  dbOpen(d,DupeFile,1);   { indizieren }
  n:=1; ll:=0;
  msgbox(32,8,getres2(466,2),x,y);   { 'DupeKill' }
  wrt(x+3,y+2,getres2(466,3));       { 'Nachrichten gesamt:' }
  wrt(x+3,y+3,getres2(466,4));       { '        bearbeitet:' }
  wrt(x+3,y+4,getres2(466,5));       { '          gel�scht:' }
  attrtxt(col.colmboxhigh);
  wrt(x+22,y+2,strsn(dbRecCount(d),7));
  assign(log,logpath+DupeLogfile);
  if existf(log) then append(log)
  else rewrite(log);
  writeln(log,getres2(466,6)+date+getres2(466,7)+time);   { 'DupeKill gestartet am ' / ' um ' }
  last:='';
  dbGoTop(d);
  while not dbEOF(d) and (dbReadInt(d,'halteflags')=0) do begin
    show;
    repeat
      inc(n);
      next:=dbReadStr(d,'brett')+dbLongStr(dbReadInt(d,'origdatum'))+dbReadStr(d,'msgid');
      if (length(next)>10) and (next=last) and (dbReadInt(d,'unversandt') and 1=0)
      then begin
        dbRead(d,'HalteFlags',flags);
        rec:=dbRecno(d);
        dbSkip(d,1); rec2:=dbRecno(d);
        dbGo(d,rec);
        flags:=2;
        dbWrite(d,'HalteFlags',flags);
        log_it;
        dbGo(d,rec2);
        inc(ll);
        end
      else
        dbSkip(d,1);
    until (next<>last) or dbEOF(d);
    last:=next;
    end;
  dbClose(d);
  era(MsgFile+dbExt);
  assign(f1,DupeFile+dbExt); rename(f1,MsgFile+dbExt);
  era(DupeFile+dbIxExt);
  writeln(log);
  close(log);
{$IFDEF BP }
  FlushSmartdrive(true);
{$ENDIF }
  dbTempOpen(mbase);
  if not autodupekill then
  begin
    signal;
    attrtxt(col.colmbox);
    wrt(x+2,y+6,' '+getres(12)+' '#8);
    wait(curon);
  end;
  closebox;
  freeres;
  aufbau:=true; xaufbau:=true;
end;


procedure print_msg(initpr:boolean);
var t  : text;
    fn : pathstr;
    s  : string;
begin
  if dbReadInt(mbase,'typ')=ord('B') then
    rfehler(436)   { 'Drucken nicht m�glich - Bin�rnachricht' }
  else begin
    fn:=TempS(dbReadInt(mbase,'groesse')+1000);
    extract_msg(1,'',fn,false,1);
    assign(t,fn);
    if existf(t) then begin
      if initpr then begin
        rmessage(119);
        initprinter;
        end;
      if checklst then begin
        reset(t);
        while not eof(t) do begin
          readln(t,s);
          printline(s);
          end;
        close(t);
        erase(t);
        end;
      if initpr then begin
        exitprinter;
        mdelay(200);
        closebox;
        end;
      end;
    end;
end;


{ Ausgabe true -> UserMode umschalten }

function UserMarkSuche(allmode:boolean):boolean;
const suchst  : string[40] = '';
var   x,y     : byte;
      brk     : boolean;
      nn,n,nf : longint;
      uname,
      sname   : string[AdrLen];
      spos    : longint;
      rec     : longint;
      mi      : shortint;
begin
  UserMarkSuche:=false;
  rec:=dbRecno(ubase);
  diabox(52,7,getres2(467,1),x,y);   { 'User-(markier)-Suche' }
  pushhp(73);
  readstring(x+3,y+2,getres2(467,2),suchst,30,40,'>',brk);  { 'Suchbegriff:' }
  pophp;
  if not brk then begin
    attrtxt(col.coldialog);
    wrt(x+3,y+4,getres2(467,3));   { 'Suchen...     %        gefunden:' }
    nn:=dbRecCount(ubase); n:=0; nf:=0;
    sname:=#255;
    mi:=dbGetIndex(ubase); dbSetIndex(ubase,0);
    dbGoTop(ubase);
    attrtxt(col.coldiahigh);
    while not dbEOF(ubase) and not brk do begin
      inc(n);
      gotoxy(x+13,y+4); write(n*100 div nn:3);
      gotoxy(x+35,y+4); write(nf:4);
      dbReadN(ubase,ub_username,uname);
      if pos(suchst,ustr(uname))>0 then begin
        UBAddmark(dbRecno(ubase));
        if not allmode and (dbReadInt(ubase,'adrbuch')=0) then
          UserMarkSuche:=true;
        if uname<sname then begin
          sname:=uname;
          spos:=dbRecno(ubase);
          end;
        inc(nf);
        end;
      dbNext(ubase);
      if n mod 16=0 then testbrk(brk);
      end;
    dbSetIndex(ubase,mi);
    if sname<>#255 then dbGo(ubase,spos)
    else dbGo(ubase,rec);
    aufbau:=true;
    end;
  closebox;
  if not brk and (nf=0) then fehler(getres2(467,4));  { 'keine passenden User gefunden' }
  freeres;
end;


procedure BrettInfo;
var i   : longint;
    x,y : byte;
    brk : boolean;
begin
  dbReadN(bbase,bb_index,i);
  message(getres(468)+': '+strs(i));   { 'Brettindex-Nr.' }
  wait(curoff);
  closebox;
  if lastkey=' ' then begin
    dialog(30,1,'',x,y);
    maddint(3,1,getres(468)+' ',i,6,8,0,99999999);
    readmask(brk);
    enddialog;
    if not brk then begin
      dbWriteN(bbase,bb_index,i);
      aufbau:=true;
      end;
    end;
end;


procedure NtInfo;
var mnt : longint;
    nts : string[20];
begin
  dbReadN(mbase,mb_netztyp,mnt);
  nts:=' ('+ntName(mnt and $ff)+')';
  message(getres(469)+strs(mnt and $ff)+nts);   { 'Netztyp: ' }
  wait(curoff);
  closebox;
end;


procedure do_bseek(fwd:boolean);
begin
  repeat
    if fwd then dbSkip(bbase,1)
    else dbSkip(bbase,-1);
  until dbBOF(bbase) or dbEOF(bbase) or brettok(false);
end;


procedure FidoMsgRequest(var nnode:string);
var files    : string;
    ic,id,
    k,p      : byte;
    p1,s,s1,t,u : string[80];
    v        : char;
    node     : string[20];
    secondtry,
    mark,     
    lMagics  : boolean;
    dir      : dirstr;
    name     : namestr;
    ext      : extstr;

begin
  nnode := '';
  if not list_selbar and (list_markanz=0) then begin
    rfehler(438);   { 'keine Dateien markiert' }
    exit
  end;
  if not TestNodelist or not TestDefbox then exit;
  s := FMsgReqnode;
  p := cpos('.',s);
  if (p>0) then node:=left(s,p-1)
    else node:=s;
  files := '';
  u := ''; t := '';
  lMagics := Magics;
  secondtry:=false;
  s := first_marked;
  repeat
    { Von Anfang an leer oder Liste komplett durchlaufen und nichts gefunden,
      dann probieren wir's nochmal mit MAGICS }
    if (s=#0) then begin
      secondtry:=true;
      s := first_marked;
      lMagics:=true;
    end;
    while (s<>#0) do begin
      { --- komplett neu:oh (aus MultiReq uebernommen) --->> }
{     if (s='') then lMagics:=false; }

      { Usernamen vor Quotes killen }
      k:=pos('>',s);
      if (k>0) then if (k<6) then delete(s,1,k);

      k:=0;
      if (s<>'') then
      while (k<byte(s[0])) do begin
        t:=''; v:=#0;
        { Nach dem ersten erlaubten Zeichen suchen }
        while (byte(s[0])>0)
        and not (s[1] in ['a'..'z','A'..'Z','0'..'9','@','!','$','^']) do begin
            v:=s[1];
            delete(s,1,1);
          continue
        end;
        { Vor dem Dateinamen mu� ein Trennzeichen stehen }
        if (v<>#0) then if not (v in [#32,'"','<','>','�','�','(','[','{',',',';',':','_','*']) then begin
          while (byte(s[0])>0)
          and not (s[1] in [#32,'"','<','>','�','�','(','[','{','_','*']) do begin
            delete(s,1,1);
            continue
          end;
          continue
        end;
        mark:=false;
        if (v<>#0) then if (v='*') or (v='_') then mark:=true;
        k:=1; { erstes Zeichen ist schon ok, also Rest testen }
        while (k<Length(s))
        and (s[k+1] in ['a'..'z','A'..'Z','0'..'9','_','@','.','!','/','?','*',
                        '$','%','-']) do inc(k);
        t:=copy(s,1,k);
        u:=UStr(t);
        delete(s,1,byte(t[0]));
        { Auf den Dateinamen mu� ein Trennzeichen folgen }
        if (byte(s[0])>0) then if not (s[1] in [#32,'"','<','>','�','�',')',']','}',',',';',':','_','*']) then continue;

        if (mark and (t[byte(t[0])] in ['_','*'])) then dec(byte(t[0]));

        while (byte(t[0])>0) and (t[byte(t[0])] in ['.','!','?','/']) do dec(byte(t[0]));
        if (byte(t[0])<2) then continue;
        k:=0;
        for ic:=1 to byte(t[0]) do if t[ic]='.' then inc(k);
        if (k>1) then continue;
        if (pos('**',t)>0) then continue;
        if not lMagics then if (pos('.',t)<3) and (byte(t[0])<5) then continue;

        { Passwort suchen, erkennen und speichern }
        p1:='';
        ic:=pos('/',t); if (ic>0) then begin
          p1:=copy(t,ic,20); delete(t,ic,99)
        end;

        u:=UStr(t);
        if (length(u)<2) then continue;
        s1:=u;
        if (s1='S0') or (s1='XP') then continue;
        if (s1='ZMH') or (s1='NMH') then continue;
        if (s1='V.FC') or (s1='VFC') then continue;
        if (s1='ISDN') or (s1='USR') then continue;
        if (s1='FQDN') or (s1='INC') then continue;
        if (s1='IMHO') or (s1='YMMV') then continue;
        if (s1='ORG') or (s1='PGP') then continue;
        if (s1='FAQ') or (s1='OS') then continue;
        if (s1='DOS') then continue;
        if (length(s1)=3) then if (copy(s1,1,2)='RC') and (s1[3] in ['0'..'9']) then continue;
        ic:=pos('@',t); if (ic>1) and (ic<>byte(t[0])) then continue;

        { Auf Beschreibungs-Datei testen }
        FSplit(u,dir,name,ext);
        if (ext='.DIZ') then continue;
        if (name='FILES') or (name='FILE_ID') or (name='00GLOBAL')
          or (name='DESCRIPT') then continue;
        
        { Ist der String eine Versionsnummer? V42.3, 1.0, X75, V34B etc. }
        if (byte(t[0])<8) then begin
          u:=t;
          if (UStr(copy(u,1,3))='VOL') then delete(u,1,3);
          if (UpCase(u[1]) in ['V','X']) then delete(u,1,1);
          id:=0;
          for ic:=1 to length(u) do if not (UpCase(u[ic]) in ['0'..'9','.','A','B','G']) then id:=1;
          if (id=0) then continue
        end;

        { Ist der String eine Baudrate oder Dateigroesse? xx.xK, x in  [0..9] }
        if (length(t)<10) then begin
          u:=UStr(t);
          { Zahl }
          while ((u<>'') and (u[1] in ['0'..'9'])) do delete(u,1,1);
          { . }
          if (u<>'') then if (u[1]='.') then begin
            delete(u,1,1);
            { Zahl }
            while (u<>'') and (u[1] in ['0'..'9']) do delete(u,1,1);
          end;
          if (u='K') or (u='KB')
            or (u='M') or (u='MB')
            or (u='B') or (u='BYTES')
          then continue;
        end;

        { Telefonnummern ausblenden }
        id:=0;
        for ic:=1 to length(u) do if not (u[ic] in ['0'..'9','-','/','+','(',')']) then id:=1;
        if (id=0) then continue;

        if (lMagics) then if (UStr(t)=t) then begin
          files:=files+' '+t;
          continue
        end;
        u := UStr(t);
        ic := pos('.',u); if not (ic in [2..9]) then continue;
        if (length(u)<4) then continue;
        if (length(u)-ic>3) then continue;
        if (p1<>'') then u:=u+p1; p1:='';
        files:=files+' '+u;
        continue
      end; { while (k<byte(s[0])) }
      { <<--- komplett neu:oh (aus MultiReq uebernommen) --- }
      s:=next_marked;  
    end; { while (s<>#0) do begin }
    files:=trim(files);
    { Abbrechen, wenn was gefunden, oder zweiter Durchlauf oder schon beim
      ersten mal MAGICS an waren und ein zweiter Durchlauf unnoetig ist }
  until ((files<>'') or secondtry or lmagics);
  if (files='') then
    rfehler(438)    { 'keine Dateien markiert' }
  else
    nnode:=FidoRequest(node,files);
end;


function _killit(ask:boolean):boolean;
var uv     : byte;
    _brett : string[5];
begin
  _killit:=false;
  dbReadN(mbase,mb_unversandt,uv);
  if uv and 1<>0 then
    rfehler(439)   { 'Unversandte Nachricht mit "Nachricht/Unversandt/L�schen" l�schen!' }
  else
    if not ask or ReadJN(getres(470)+   { 'Nachricht l�schen' }
      iifs(KK and HasRef,getres(471),''),true) then
    begin                            { ' (unterbricht Bezugsverkettung)' }
      if msgmarked then
        msgUnmark;
      wrkilled;
      dbRead(mbase,'Brett',_brett);
      DelBezug;
      dbDelete(mbase);
      if left(_brett,1)<>'U' then RereadBrettdatum(_brett);
      _killit:=true;
      aufbau:=true; xaufbau:=true;
      setbrettgelesen(_brett);
      end;
end;

  procedure ReverseHdo;
  var
    t1,t2 : text;
    box   : string[BoxNameLen];
    brett : string[81];
    line1 : string[120];
    i     : integer;
    boxfn : string[8];
    rhdo  : boolean;
    nr    : byte;
    fsize : longint;
  begin
    {GoP;}
    dbReadN(bbase,bb_gruppe,nr);
    dbReadN(bbase,bb_pollbox,box);
    dbReadN(bbase,bb_brettname,brett);
    if (box='') or (nr=1) or (brett[1]='1') or (brett[1]='$') then begin
      fehler(getres(490)); { 'Bei internen Brettern nicht m�glich' }
      exit;
    end;
    boxfn:=ustr(boxfilename(box));
    if (ntBoxNetztyp(box)<>nt_PPP) then begin
      fehler(getres(489)); { 'Nur beim RFC/PPP-Boxtyp m�glich' }
      exit;
    end;
    fsize:=_filesize(ownpath+boxfn+'.RC');
    if not exist(ownpath+boxfn+'.RC') or (fsize=0) then begin
      fehler(getreps(491,ustr(box))); { 'F�r %s bestehen noch keine Bestellungen' }
      exit;
    end;
    if fsize > (250*1024) then moment;
    if brett[2]='/' then delete(brett,1,2);
    for i:=1 to length(brett) do
      if brett[i]='/' then brett[i]:='.';
    assign(t1,ownpath+boxfn+'.RC');
    reset(t1);
    if ioresult<>0 then exit;
    assign(t2,TempFile(''));
    rewrite(t2);
    i:=0;
    while not eof(t1) do begin
      readln(t1,line1);
      if (copy(line1,1,pos(' ',line1)-1)=brett) then begin
        if i<>1 then i:=1;
        rhdo:=(pos('HDRONLY',ustr(line1))<>0);
        if rhdo then
          writeln(t2,copy(line1,1,length(line1)-8)) else
        writeln(t2,line1+' HdrOnly');
      end else writeln(t2,line1);
    end;
    close(t1);  erase(t1);
    flush(t2);  close(t2);
    rename(t2,ownpath+boxfn+'.RC');
    if fsize > (250*1024) then closebox;
    if i=1 then begin
      if rhdo then
        rmessage(486) else { 'HeaderOnly zur�ckgesetzt' }
      rmessage(487);       { 'HeaderOnly gesetzt'       }
      wkey(1,false);
      closebox;
    end else hinweis(getres(488)); { 'Bitte �ber Brettmanager bestellen' }
  end;

function rfcbrett(s:string):string;
var i   : integer;
    box : string[BoxNameLen];
    user:boolean;
begin
  box:='';
  user:=(s[1]='1') or (s[1]='U');
  if user then
    if(s[1]='1') then delete(s,1,2) else delfirst(s);
  if user and NewsgroupDisp and (pos('@',s)=0) then begin
    i:=pos('/', s);
    if i<>0 then s[i]:='@';
  end;
  if (s[1]='/') then delfirst(s);
  if (s[2]='/') then delete(s,1,2);
  if user and userslash then s:='/'+s;
  if not user and not dbEOF(bbase) then
    dbReadN(bbase,bb_pollbox,box);
  if user or not (ntBoxNetztyp(box) in [nt_UUCP,nt_PPP]) or not NewsgroupDisp then
    rfcbrett:=s
  else begin
    for i:=1 to length(s) do if s[i]='/' then s[i]:='.';
    rfcbrett:=s;
  end;
end;


end.
{
  $Log: xp4o.pas,v $
  Revision 1.55  2001/12/26 09:21:54  MH
  - Fix bei Anzeige von Userbrettern

  Revision 1.54  2001/12/22 18:14:11  mm
  - SucheWiedervorlage auch in Userbrettern (Jochen Gehring)

  Revision 1.53  2001/12/22 14:35:56  mm
  - ListWrapToggle: mittels Ctrl-W kann im Lister und Archiv-Viewer der
    automatische Wortumbruch nicht-permanent umgeschaltet werden
    (Dank an Michael Heydekamp)

  Revision 1.52  2001/07/25 16:50:56  MH
  - Absturz bei Nachrichten/Suche/Wiedervorlage gefixt

  Revision 1.51  2001/07/22 12:06:32  MH
  - FindFirst-Attribute ge�ndert: 0 <--> DOS.Archive

  Revision 1.50  2001/07/11 09:57:34  MH
  - UKAD-Parameter korrigiert (news)

  Revision 1.49  2001/06/30 23:23:47  MH
  - ListerBrettAnzeige: Praevention bei Datenbankzugriff

  Revision 1.48  2001/06/29 01:22:39  MH
  - Brettanzeigen nun konstistent

  Revision 1.47  2001/06/28 17:54:13  MH
  -.-

  Revision 1.46  2001/06/28 17:36:41  MH
  -.-

  Revision 1.45  2001/06/28 17:16:48  MH
  -.-

  Revision 1.44  2001/06/28 15:42:27  MH
  - ListerBrettAnzeige nochmal korrigiert

  Revision 1.43  2001/06/27 01:54:54  MH
  - Brettanzeige jetzt Nachrichtenabh�ngig
    (/FIDO/-Brettebene wird entfernt)

  Revision 1.42  2001/06/26 23:17:17  MH
  - Brettanzeige (auch im Lister) auch RFC-Konform anzeigen

  Revision 1.41  2001/06/18 20:17:31  oh
  Teames -> Teams

  Revision 1.40  2001/01/06 17:44:10  MH
  HDO-Rev.:
  - Interne Bretter nicht bedienen

  Revision 1.39  2001/01/05 17:06:17  MH
  HDO-Rev.:
  - Moment-Anzeige bei RC-Dateien gr��er 250kB

  Revision 1.38  2001/01/04 15:25:35  MH
  HdoReverse:
  - HDO-Erkennung korrigiert

  Revision 1.37  2001/01/02 13:32:42  MH
  - HDO-Reverse mit 'Moment'-Anzeige ausgestattet, falls
    es mal wieder l�nger dauert

  Revision 1.36  2000/12/31 17:12:41  MH
  Fix Mid-Request:
  - Nach einer Suche oder auch direkt konnten ung�ltige
    MsgIDs verwendet werden

  Revision 1.35  2000/12/25 18:50:45  MH
  RFC/PPP - ReverseHdo:
  - in Postf�chern Fehler melden

  Revision 1.34  2000/12/25 17:39:54  MH
  - Windows-Umlaute korrigiert

  Revision 1.33  2000/12/25 17:27:19  MH
  - Aktualisierung mit weiterf�hrenden Arbeiten

  Revision 1.32  2000/12/25 17:14:31  MH
  Fix (JG):
  - Spezialsuche
  - Suche zum aktuellen Lesemode hinzugef�gt
  - RFC/PPP: Reverse HeaderOnly-Schaltung ('H') auf Bretter

  Revision 1.31  2000/11/21 16:16:53  MH
  Fix: L�nge des SuchStrings auf 73 Zeichen begrenzt

  Revision 1.30  2000/11/19 17:31:49  MH
  Message-ID Request:
  - Stornierung erm�glicht

  Revision 1.29  2000/11/19 10:30:22  MH
  Message-Request-Editor implementiert
  - First version...

  Revision 1.28  2000/10/08 15:34:25  MH
  WPOP Error endg�ltig beseitigt

  Revision 1.27  2000/10/08 12:58:31  MH
  WPOP Error beseitigt

  Revision 1.26  2000/10/07 13:17:11  MH
  HDO: Kleinere Detailverbesserung (Fix):
  - BoxFileName ben�tigt nur einen Zugriff

  Revision 1.25  2000/10/05 16:20:47  MH
  Msg-ID Req.: Bei ShowHeader verbesserte Erkennung f. Mid

  Revision 1.24  2000/10/04 16:23:39  MH
  MsgId-Suche: Den Suchedialog vor Requester schlie�en

  Revision 1.23  2000/10/03 09:10:07  MH
  - Fileclose vergessen...grrr

  Revision 1.22  2000/10/01 15:23:36  MH
  HDO: Kleinere Detailverbesserungen:
  - Meldungen k�nnen vor Zeitablauf durch Tastendruck
    abgebrochen werden

  Revision 1.21  2000/10/01 11:47:11  MH
  HDO: Kleinere Korekturen vorgenommen

  Revision 1.20  2000/09/30 15:15:32  MH
  MidSuche: Abfrage f�r Fehlermeldung erweitert

  Revision 1.19  2000/09/30 13:00:29  MH
  MidSuche incl Req.: Fehler melden, wenn Boxtyp nicht RFC/PPP

  Revision 1.18  2000/09/30 10:48:09  MH
  HDO/MidReq:
  - Weitere Meldung hinzugef�gt

  Revision 1.17  2000/09/30 09:49:09  MH
  Mid-Suche:
  - Wird eine Mid nicht gefunden, dann kann sie per Dialog
    requestet werden

  Revision 1.16  2000/09/24 08:41:26  MH
  HDO-Request in Spezial-Suche hinzugef�gt

  Revision 1.15  2000/09/03 09:56:17  MH
  SuchOption 'ai� or ai' ist vom 1. Eintrag in RQ abh�ngig,
  deshalb nun ein UpperString zum Vergleich verwenden, da
  dieser von wem auch immer ge�ndert wurde und die Funktion
  sonst au�er Kraft gesetzt wird.

  Revision 1.14  2000/09/03 09:42:44  MH
  Headeronly in der Spezialsuche hinzugef�gt

  Revision 1.13  2000/08/21 21:13:18  oh
  - F3-Request: keine Datei erkannt, dann nochmal nach Magic suchen

  Revision 1.12  2000/08/15 19:53:33  oh
  -F3-Request-Bug (filename-.bla) behoben

  Revision 1.11  2000/08/10 17:31:35  MH
  JG: SetBrettGelesen-Routine f�r Ungelesen-Bug

  Revision 1.10  2000/08/09 12:12:17  MH
  JG: Fix: (Suche) Zugriff auf nicht initialisierte Variablen

  Revision 1.9  2000/08/07 15:46:52  MH
  Fix:
  o Taste Volltextsuche (ALT T) im Lister wurde schon
    von Notepad verwendet - jetzt ALT V - und wurde nie aufgerufen
  o Begrenzung (RTE) auf max. 10 Suchstrings konnte �ber-
    schritten werden

  Revision 1.8  2000/07/16 15:39:36  MH
  Nachrichtenkopf-Fenster verbreitert

  Revision 1.7  2000/06/02 09:46:25  MH
  RFC/PPP: Weitere Anpassungen

  Revision 1.6  2000/04/10 22:13:10  rb
  Code aufger�umt

  Revision 1.5  2000/04/10 01:21:15  oh
  - F3-Request: Magicerkennung ein/ausschaltbar (C/O/e/V/Fido)

  Revision 1.30  2000/04/10 00:43:04  oh
  - F3-Request: Magicerkennung ein/ausschaltbar (C/O/e/V/Fido)

  Revision 1.29  2000/03/22 05:06:37  jg
  - Bugfix: Suchen-Spezial ohne Volltext aber mit Option "o" oder "a"
    Vorbereitung der Such Teilstrings fuehrte zu nem RTE 201.

  Revision 1.28  2000/03/21 15:22:10  jg
  - Suche: Pfeil fuer Historyauswahl kommt nur noch
    wenn auch was gewaehlt werden kann.

  Revision 1.27  2000/03/18 10:39:06  jg
  - Suche-MessageID Wahlmoeglichkeit:  schnelle Bezugs-DB Suche
    oder langsamere Msg-Base Suche mit Teilstrings und Suchoptionen

  Revision 1.26  2000/03/14 15:15:40  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.25  2000/03/13 18:55:18  jg
  - xp4o+typeform: Ukonv in UkonvStr umbenannt
  - xp4o: Compilerschalter "History" entfernt,
          "Debugsuche" durch "Debug" ersetzt

  Revision 1.24  2000/03/09 23:39:33  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.23  2000/03/08 22:36:33  mk
  - Bugfixes f�r die 32 Bit-Version und neue ASM-Routinen

  Revision 1.22  2000/03/06 08:51:04  mk
  - OpenXP/32 ist jetzt Realitaet

  Revision 1.21  2000/03/04 18:34:18  jg
  - Externe Viewer: zum Ansehen von Fileattaches wird keine Temp-Kopie
    mehr erstellt, und nicht mehr gewartet, da kein Loeschen noetig ist

  Revision 1.20  2000/03/02 20:09:31  jg
  - NOT Operator (~) fuer Suchstrings und Such-History eingebaut

  Revision 1.19  2000/03/01 13:17:41  jg
  - Ukonv Aufrufe benutzen jetzt High() fuer Maxlaenge
  - STRG + INS funktioniert in Texteingabefeldern wie STRG+C

  Revision 1.18  2000/03/01 08:04:23  jg
  - UND/ODER Suche mit Suchoptionen "o" + "u"
    Debug-Checkfenster mit Suchoption "c"
  - Umlautkonvertierungen beruecksichtigen
    jetzt Maximalstringlaenge

  Revision 1.17  2000/02/29 17:50:40  mk
  OH: - Erkennung der Magics verbessert

  Revision 1.16  2000/02/29 12:59:16  jg
  - Bugfix: Umlautkonvertierung beachtet jetzt Originalstringlaenge
    (Wurde akut bei Spezialsuche-Betreff)

  Revision 1.15  2000/02/29 10:46:28  jg
  -Bugfix Spezialsuche - Betreff

  Revision 1.14  2000/02/23 19:11:04  jg
  -Suchfunktionen im Lister benutzen Autosuche,
   "Global_Suchstring" und dessen auswertung entfernt.
  -!Todo.txt aktualisiiert

  Revision 1.13  2000/02/22 15:51:20  jg
  Bugfix f�r "O" im Lister/Archivviewer
  Fix f�r Zusatz/Archivviewer - Achivviewer-Macros jetzt aktiv
  O, I,  ALT+M, ALT+U, ALT+V, ALT+B nur noch im Lister g�ltig.
  Archivviewer-Macros g�ltig im MIME-Popup

  Revision 1.12  2000/02/19 18:00:24  jg
  Bugfix zu Rev 1.9+: Suchoptionen werden nicht mehr reseted
  Umlautunabhaengige Suche kennt jetzt "�"
  Mailadressen mit "!" und "=" werden ebenfalls erkannt

  Revision 1.11  2000/02/19 10:12:13  jg
  Bugfix Gelesenstatus aendern per F4 im ungelesen Modus

  Revision 1.10  2000/02/18 17:28:08  mk
  AF: Kommandozeilenoption Dupekill hinzugefuegt

  Revision 1.9  2000/02/18 15:54:52  jg
  Suchoptionen-Laenderabfrage verbessert

  Revision 1.8  2000/02/18 09:13:27  mk
  JG: * Volltextsuche jettz Sprachabhaengig gestaltet
      * XP3.ASM in XP3.PAS aufgenommen

  Revision 1.7  2000/02/16 15:25:32  mk
  OH: Schalter magics in FidoMsgRequest auf true gesetzt

  Revision 1.6  2000/02/15 21:19:24  mk
  JG: * Umlautkonvertierung von XP4O.Betreffsuche in Typeform verlagert
      * wenn man eine markierte Nachricht liest, wird beim Verlassen
        der Headeranzeige nicht gleich auch der Lister verlasssen
      * Die Suchfunktionen "Absender/User", "Betreff" und "Fidoempf�nger"
        k�nnen jetzt Umlautunabh�ngig geschalten werden

  Revision 1.5  2000/02/15 20:43:36  mk
  MK: Aktualisierung auf Stand 15.02.2000

}
