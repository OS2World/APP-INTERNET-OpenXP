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
{ $Id: xp8.pas,v 1.51 2001/09/02 17:05:07 MH Exp $ }

{ CrossPoint - 'maps & Fileserver }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp8;

interface

uses xpglobal, crt,dos,typeform,fileio,inout,keys,datadef,database,lister,
  maske,maus2, resource,win2,xp0,xp1,xp1o2,xp1help,xp1input,xp2c,xp_iti,
  xpcrc32;


procedure SendMaps(bef:string; var box,datei:string);
procedure MapsDelBrett(brett:string);
procedure MapsReadList;
procedure MapsReadFile;
procedure ReadPromafList(fn:pathstr; var bfile:string);
procedure MapsBrettliste(art:byte);
procedure MapsCommands(defcom:byte);   { 0=Auswahl, 1=Brettliste holen }
procedure GetSysfile;

function MakeRC(bestellen: boolean; rctemp: pathstr; box: string):boolean;
{procedure Sortbliste;}

procedure AddFileechos;
procedure RemoveFileechos;
procedure FilescanReadlist;
procedure FilescanReadFile;
procedure FilescanCommands(cmd:shortint);


function  IsServer(box:string; var fstype:byte):boolean;
procedure FS_ReadList(msg:boolean);
procedure FS_command(comm:string; request:byte);

function testmark(var s:string; block:boolean):boolean;
function BrettMark(var s:string; block:boolean):boolean;
function MapsListcolor(var s:string; line:longint):byte;
function UUsendTestSourcefile(var s:string):boolean;
function fileechomarkfunc(var s:string; block:boolean):boolean;
function fileechocolfunc(var s:string; line:longint):byte;


implementation  { ------------------------------------------------- }

uses xp1o,xp3,xp3o2,xp3ex,xp4,xp6,xp6o,xp9bp,xp9,xpfido,xpnt;

const mapsbox : string[BoxNameLen] = '';

var mapsname : string[20];
    mapsnt   : byte;
    mapsart  : byte;
    {hdo      : boolean;}


function mapstype(box:string):byte;  { 0=MAPS, 1=AREAFIX, 2=MAF, 3=Maus, 4=Q. }
var d  : DB;                         { 5=Fido, 6=G&S, 7=changesys, 8=Pronet,  }
    nt : byte;                       { 9=Turbobox, 10=ZQWK, 11=GUP, 12=AutoSys}
begin                                { 13=Feeder, 14=postmaster, 15=PPP       }
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  if not dbFound then
    mapstype:=0
  else begin
    dbRead(d,'nameomaps',mapsname);     { mu· vor MAF-Test stehen !! }
    dbRead(d,'netztyp',nt);
    if ntMAF(nt) then
      mapstype:=2
    else if ntNude(nt) then
      mapstype:=3
    else if ntQuickMaps(nt) then
      mapstype:=4
    else if ntAreamgr(nt) then
      mapstype:=5
    else if (nt=nt_PPP) then begin
      ReadBoxpar(nt,box);
      mapstype:=15;
    end
    else if (nt=nt_UUCP) then begin
      ReadBoxpar(nt,box);
      case Boxpar^.BMtyp of
        bm_changesys : mapstype:=7;
        bm_GUP       : mapstype:=11;
        bm_Feeder    : mapstype:=13;
        bm_AutoSys   : mapstype:=12;
        else           mapstype:=14;  { postmaster }
      end;
      end
    else if (nt=nt_Pronet) then
      mapstype:=8
    else if (nt=nt_Turbo) then
      mapstype:=9
    else if nt=nt_QWK then
      mapstype:=10
    else
      if mapsname='AREAFIX' then mapstype:=1
      else if mapsname='SYSTEM' then mapstype:=6  { G&S }
      else mapstype:=0;
    end;
  dbClose(d);
end;

function BoxHasMaps(box:string):boolean;
begin
  if ntNoMaps(ntBoxNetztyp(box)) then begin
    rfehler(801);   { 'Diese Box unterstÅtzt keine Brettbestell-Funktionen.' }
    BoxHasMaps:=false;
    end
  else
    BoxHasMaps:=true;
end;

procedure SendMaps(bef:string; var box,datei:string);
var hf : string[12];
    mt : byte;
    nt : byte;

  procedure AreaBef;
  var t1,t2 : text;
      tn    : pathstr;
      s     : string[80];
  begin
    if (bef='ADD') or (bef='DEL') then begin
      tn:=TempS(_filesize(datei)*2);
      assign(t1,datei); reset(t1);
      assign(t2,tn); rewrite(t2);
      while not eof(t1) do begin
        readln(t1,s);
        writeln(t2,bef,' ',s);
        end;
      close(t1); erase(t1);
      close(t2); rename(t2,datei);
      end
    else begin
      assign(t1,datei);
      rewrite(t1);
      writeln(t1,bef);
      close(t1);
      end;
    bef:='AREAFIX';
  end;

  procedure MafNude(maf,promaf:boolean);
  var t1,t2 : text;
      tn    : pathstr;
      s     : string[80];
  begin
    ReadBoxpar(0,box);
    if (bef='ADD') or (bef='DEL') then begin
      tn:=TempS(_filesize(datei)*2);
      assign(t1,datei); reset(t1);
      assign(t2,tn); rewrite(t2);
      if maf then
        writeln(t2,'%',boxpar^.passwort);
      while not eof(t1) do begin
        readln(t1,s);
        if trim(s)<>'' then begin
          if not (maf or promaf) then write(t2,'G');    { Maus-Gruppe }
          if bef='ADD' then writeln(t2,iifs(promaf,'','+'),s)
          else writeln(t2,'-',s);
          end;
        end;
      close(t1); erase(t1);
      close(t2); rename(t2,datei);
      if promaf then bef:='Bretter';
      end
    else if not promaf then begin
      assign(t1,datei);
      rewrite(t1);
      if maf then begin
        writeln(t1,'%',boxpar^.passwort);
        writeln(t1,'%',bef);
        end
      else
        writeln(t1,bef);
      close(t1);
      end;
    if maf then bef:='BRETTER'
    else if not promaf then bef:='<Maus-Command>'
    else forceabs:='SYSOP';
  end;

  procedure ChangeSys;
  type bnodep = ^bnode;
       bnode  = record
                  l,r : bnodep;
                  c   : ^string;
                  del : boolean;
                end;
  var t       : text;
      root    : bnodep;
      sysfile : string[12];
      s       : string;
      syspos  : byte;
      first   : boolean;
      _brett  : string[5];
      d       : DB;

    procedure SetBrett(add:boolean; var bn:bnodep);

      procedure setbretts;
      begin bn^.c^:=s; end;

      function smaller:boolean;
      begin smaller:=(s<bn^.c^); end;

      function found:boolean;
      begin found:=(s=bn^.c^); end;

    begin
      if bn=nil then
        if add then begin   { ADD - Brett hinzufÅgen }
          new(bn);
          bn^.l:=nil; bn^.r:=nil; bn^.del:=false;
          getmem(bn^.c,length(s)+1);
          setbretts;
          end
        else                { DEL - Brett nicht vorhanden }
      else
        if found then
          if add then         { ADD - Brett schon vorhanden }
          else bn^.del:=true  { Brett lîschen }
        else
          if smaller then SetBrett(add,bn^.l)   { links suchen }
          else SetBrett(add,bn^.r);             { rechts suchen }
    end;

    procedure syswrite(bn:bnodep);
    begin
      if bn<>nil then begin
        syswrite(bn^.l);
        if not bn^.del then
          if syspos=0 then writeln(t,bn^.c^)
          else begin
            if not first then write(t,',')
            else first:=false;
            if syspos+length(bn^.c^)>77 then begin
              writeln(t,'\'); syspos:=1; end;
            write(t,bn^.c^);
            inc(syspos,length(bn^.c^)+1);
            end;
        syswrite(bn^.r);
        end;
    end;

    procedure freelist(bn:bnodep);
    begin
      if bn<>nil then begin
        freelist(bn^.l);
        freelist(bn^.r);
        freemem(bn^.c,length(bn^.c^)+1);
        dispose(bn);
        end;
    end;

  begin
    sysfile:=BoxFilename(box)+'.BBL';
    root:=nil;
    if exist(sysfile) then begin         { alte .BBL-Datei einlesen }
      assign(t,sysfile);
      reset(t);
      while not eof(t) do begin
        readln(t,s);
        if (s<>'') and (s[1]<>'#') then SetBrett(true,root);
        end;
      close(t);
      end;
    assign(t,datei);                     { Brett(ab)bestellungen einlesen }
    reset(t);
    while not eof(t) do begin
      readln(t,s);
      if (s<>'') and (s[1]>='a') then
        if bef='ADD' then SetBrett(true,root)
        else SetBrett(false,root);
      end;
    close(t);
    assign(t,sysfile);                   { neue .BBL-Datei schreiben }
    rewrite(t); syspos:=0; first:=false;
    syswrite(root);
    close(t);
    assign(t,datei);                     { neue (Ab)Bestellung schreiben }
    ReadBoxPar(nt_UUCP,box);
    dbOpen(d,BoxenFile,1);
    dbSeek(d,boiName,ustr(box));
    rewrite(t);
    writeln(t,'system: ',boxpar^.pointname,
                         iifs(boxpar^.BMdomain,dbReadStr(d,'domain'),''));
    writeln(t,'passwd: ',boxpar^.AreaPW);
    write(t,'sysentry: '); syspos:=30; first:=true;
    dbClose(d);
    syswrite(root);
    writeln(t);
    close(t);
    freelist(root);
    bef:='setsys';
    s:=mapsname+'@'+box+ntServerDomain(box);  { evtl. alten setsys-Befehl lîschen }
    dbSeek(ubase,uiName,ustr(s));
    if dbFound then begin
      _brett:=mbrettd('U',ubase);
      dbSeek(mbase,miBrett,_brett+dup(4,#255));
      if dbEOF(mbase) then dbGoEnd(mbase)
      else dbSkip(mbase,-1);
      while not dbBOF(mbase) and (dbReadStr(mbase,'brett')=_brett) and
            odd(dbReadInt(mbase,'unversandt')) do begin
        if dbReadStr(mbase,'betreff')='setsys' then
          Unversandt(false,false);
        dbSkip(mbase,-1);
        end;
      end;
  end;

  procedure Guppie(typ:byte);   { 1=GUP, 2=AutoSys, 3=Feeder }
  var tn    : pathstr;
      t1,t2 : text;
      s     : string[120];
      d     : DB;
      domain: string[60];
  begin
    ReadBoxpar(0,box);
    tn:=TempS(_filesize(datei)*2);
    assign(t1,datei); reset(t1);
    assign(t2,tn); rewrite(t2);
    dbOpen(d,BoxenFile,1);
    dbSeek(d,boiName,ustr(box));
    if boxpar^.BMdomain then domain:=dbReadStr(d,'domain')
    else domain:='';
    case typ of
      1 : writeln(t2,'site ',boxpar^.pointname,domain,' ',boxpar^.AreaPW);
      2 : writeln(t2,'host ',boxpar^.pointname,domain,' ',boxpar^.AreaPW);
      3 : writeln(t2,'@id ',boxpar^.pointname,domain,' ',boxpar^.AreaPW);
    end;
    dbClose(d);
    writeln(t2);
    if (bef='ADD') or (bef='DEL') then begin
      if typ=3 then writeln(t2,'@append');
      while not eof(t1) do begin
        readln(t1,s);
        if (trim(s)<>'') and (s[1]<>'#') and (s[1]<>'-') then
          if (bef='ADD') then
            case typ of
              1 : writeln(t2,'include ',s);
              2 : writeln(t2,'add ',s);
              3 : writeln(t2,s);
            end
          else
            case typ of
              1 : writeln(t2,'delete ',s);
              2 : writeln(t2,'rem ',s);
              3 : writeln(t2,'!',s);
            end;
        end;
      if typ=3 then writeln(t2,'@end');
      end
    else
      writeln(t2,bef);
    if (bef<>'help') and (typ<>3) then writeln(t2,'quit');
    close(t1); erase(t1);
    close(t2); rename(t2,datei);
  end;

begin
  mt:=mapstype(box);
  nt:=ntBoxNetztyp(box);
  case mt of
    1 : AreaBef;
    2 : MafNude(true,false);
    3 : MafNude(false,false);
    5 : begin
          ReadBoxpar(nt,box);
          if (bef='ADD') or (bef='DEL') or (bef='') then
            bef:=boxpar^.AreaPW
          else
            bef:=boxpar^.AreaPW+' '+bef;
        end;
    6 : if bef='ADD' then bef:='BRETT +'
        else if bef='DEL' then bef:='BRETT -';
    7 : if (bef='ADD') or (bef='DEL') or (bef='setsys') then
          ChangeSys;
    8 : MafNude(false,true);   { ProNet }
    9 : begin
          mapsname:='SYSTEM';
          ControlMsg:=true;
        end;
   10 : begin
          mapsname:='ZQWK';
          bef:='CONFIG';
        end;
   11 : Guppie(1);
   12 : Guppie(2);
   13 : Guppie(3);
   14 : ;   { Postmaster }
  end;
  hf:='';
  _sendmaps:=true;
  forcebox:=box;
  if DoSend(true,datei,mapsname+'@'+box+ntServerDomain(box),bef,
            false,false,false,false,false,nil,hf,hf,0) then;
  _sendmaps:=false;
end;


procedure wr_btext(var t:text; del,news:boolean);
var bretter : string[15];
begin
  writeln(t,'##  ',getres2(800,1));   { 'Lieber Systemverwalter,' }
  writeln(t,'##');
  bretter:=getres2(800,iif(news,2,3));
  writeln(t,'##  ',getreps2(800,iif(del,4,5),bretter));
  writeln(t,'##');
  writeln(t,'##  ',getres2(800,6));   { 'mit virtuellen GrÅ·en' }
  writeln(t,'##     '+xp_xp+' ',verstr);
  writeln(t);
  writeln(t,dup(40,'-'));
  writeln(t);
  freeres;
end;


{ bbase-aktuelles Brett abbstellen   }
{ brett='' -> markierte Bretter abb. }

procedure MapsDelBrett(brett:string);
const maxmaggi = 500;

type maggibrett  = record
                     code  : string[4];
                     name  : string[40];
                   end;
    ma           = array[1..maxmaggi] of maggibrett;
var t     : text;
    fn    : pathstr;
    box   : string[20];
    i,nr  : integer;
    d     : DB;
    topen : boolean;
    maf   : boolean;
    maus  : boolean;
    quick : boolean;
    fido  : boolean;
    turbo : boolean;
    gs    : boolean;
    uucp  : boolean;
    ppp   : boolean;
    postmaster : boolean;
    pronet: boolean;
    qwk   : boolean;
    map   : ^ma;
    mm    : integer;
    bfile : string[8];

  { s. auch MAGGI.loadbretter! }

  procedure ReadBrettliste;
  var t : text;
      s : string;
  begin
    mm:=0;
    assign(t,bfile+'.bl');
    reset(t);
    if ioresult=0 then begin
      message(getreps(801,ustr(box)));   { 'Brettliste fÅr %s laden...' }
      while (mm<maxmaggi) and not eof(t) do begin
        readln(t,s);
        if maf then begin
          inc(mm);
          if s[41]<>' ' then
            map^[mm].code:=copy(s,41,4)
          else
            map^[mm].code:=trim(copy(s,41,6));
          s:=trim(left(s,40));
          if left(s,1)<>'/' then s:='/'+s;
          while cpos(' ',s)>0 do s[cpos(' ',s)]:='_';
          map^[mm].name:=ustr(s);
          end
        else   { ProNet }
          if left(s,1)<>';' then begin
            inc(mm);
            map^[mm].code:=left(s,4);
            map^[mm].name:=trim(mid(s,32));
            end;
        end;
      close(t);
      closebox;
      end;
    if ioresult<>0 then;
  end;

  function brettcode(brett:string):string;
  var i : integer;
  begin
    UpString(brett);
    i:=1;
    while (i<=mm) and (brett<>map^[i].name) do inc(i);
    if i<=mm then brettcode:=map^[i].code
    else brettcode:='';
  end;

  procedure GetDel(txt:string);
  var width,x,y : byte;
      t         : taste;
  begin
    width:=max(33,length(txt)+5);
    diabox(width,5,'',x,y);
    mwrt(x+2,y+1,txt+'?');
    t:='';
    nr:=readbutton(x+2,y+3,2,getres(802),1,true,t);   { '  ^Ja  , ^Nein , ^Liste ' }
    closebox;
  end;

  function newsgroup(s:string):string;
  var i : integer;
  begin
    delete(s,1,2);
    for i:=1 to length(s) do
      if s[i]='/' then s[i]:='.';
    newsgroup:=s;
  end;

  function qwkbrett(brett:string):string;
  var t : text;
      s : string[80];
  begin
    brett:=ustr(mid(brett,length(boxpar^.magicbrett)+2));
    assign(t,bfile+'.Bl');
    qwkbrett:='';
    if existf(t) then begin
      reset(t);
      while not eof(t) do begin
        readln(t,s);
        if pos(brett,ustr(s))>0 then
          qwkbrett:=left(s,3);
        end;
      close(t);
      end;
  end;

begin
  if brett='' then
    if bmarkanz=0 then
      nr:=3
    else
      GetDel(getreps(803,strs(bmarkanz)))   { '%s markierte Bretter abbestellen' }
  else
    if left(brett,1)<>'A' then
      nr:=3
    else
      GetDel(getreps(804,copy(brett,2,40)));   { '%s abbestellen' }
  if nr=3 then
    MapsBrettliste(1)
  else if nr=1 then begin
    if brett<>'' then begin
      dbRead(bbase,'pollbox',box);
      if box='' then begin
        rfehler(802);   { 'Dieses Brett hat keine Serverbox!' }
        exit; end;
      if not IsBox(box) then begin
        rfehler1(803,box);   { 'Unbekannte Serverbox: %s' }
        exit; end;
      if not BoxHasMaps(box) then exit;
      end;
    new(map);
    fn:=TempS(10000);
    assign(t,fn);
    if brett<>'' then begin
      maf:=false; maus:=false; quick:=false; fido:=false; gs:=false;
      uucp:=false; turbo:=false; pronet:=false; qwk:=false; ppp:=false;
      postmaster:=false;
      case mapstype(box) of
        2 : maf:=true;
        3 : maus:=true;
        4 : quick:=true;
        5 : fido:=true;
        6 : gs:=true;
        7 : uucp:=true;
        8 : pronet:=true;
        9 : turbo:=true;
       10 : qwk:=true;
       11..13 : uucp:=true;
       14 : begin uucp:=true; postmaster:=true; end;
       15 : ppp:=true;
      end;
      rewrite(t);
      if quick or (uucp and postmaster) then
        wr_btext(t,true,uucp);
      if maus or fido or turbo or qwk then begin
        ReadBoxPar(0,box);
        if copy(ustr(brett),2,length(boxpar^.magicbrett))=ustr(boxpar^.magicbrett)
        then
          if qwk then begin
            bfile:=boxfilename(box);
            writeln(t,'DROP ',qwkbrett(brett));
            end
          else begin
            if fido then write(t,'-');
            writeln(t,mid(brett,length(boxpar^.magicbrett)+2));
            end;
        end
      else if not maf then
        if gs then writeln(t,copy(brett,3,brettlen))
        else if uucp or ppp then writeln(t,newsgroup(brett))
        else writeln(t,copy(brett,2,brettlen))
      else begin
        dbOpen(d,OwnPath+BoxenFile,1);
        dbSeek(d,boiName,ustr(box));
        if dbFound then begin
          dbRead(d,'dateiname',bfile);
          ReadBrettliste;
          writeln(t,brettcode(copy(brett,2,40)));
          end;
        dbClose(d);
        end;
      if fido then
        writeln(t,'---');
      close(t);
      if not ppp then
      SendMaps('DEL',box,fn) else
      if MakeRc(false,fn,box) then;  { markiertes Brett abbestellen }
    end
    else begin   { mehrere markierte Bretter }
      dbOpen(d,OwnPath+BoxenFile,1);
      while not dbEOF(d) do begin
        topen:=false;
        box:=dbReadStr(d,'boxname');
        maf:=ntMAF(dbReadInt(d,'netztyp'));
        quick:=ntQuickMaps(dbReadInt(d,'netztyp'));
        maus:=ntNude(dbReadInt(d,'netztyp'));
        fido:=ntAreaMgr(dbReadInt(d,'netztyp'));
        gs:=(dbReadInt(d,'netztyp')=nt_GS);
        uucp:=(dbReadInt(d,'netztyp')=nt_UUCP);
        ppp:=(dbReadInt(d,'netztyp')=nt_PPP);
        turbo:=(dbReadInt(d,'netztyp')=nt_Turbo);
        pronet:=(dbReadInt(d,'netztyp')=nt_Pronet);
        qwk:=(dbReadInt(d,'netztyp')=nt_QWK);
        dbRead(d,'dateiname',bfile);
        if maus or fido or turbo or qwk or uucp or ppp then
          ReadBox(0,bfile,boxpar);
        for i:=0 to bmarkanz-1 do begin
          dbGo(bbase,bmarked^[i]);
          if ustr(dbReadStr(bbase,'pollbox'))=ustr(box) then begin
            if not topen then begin
              rewrite(t);
              if quick or (uucp and (boxpar^.BMtyp=bm_postmaster)) then
                wr_btext(t,true,uucp);
              if maf or pronet then ReadBrettliste;
            end;
            dbReadN(bbase,bb_brettname,brett);
            if maus or fido or turbo or qwk then begin
              if copy(ustr(brett),2,length(boxpar^.magicbrett))=
                 ustr(boxpar^.magicbrett)
              then
                if qwk then writeln(t,'DROP ',qwkbrett(brett))
                else begin
                  if fido then write(t,'-');
                  writeln(t,mid(brett,length(boxpar^.magicbrett)+2));
                end;
              end
            else
              if not (maf or pronet) then
                if gs then writeln(t,copy(brett,3,brettlen))
                else if uucp or ppp then writeln(t,newsgroup(brett))
                else writeln(t,copy(brett,2,BrettLen))
              else writeln(t,brettcode(mid(brett,2)));
            topen:=true;
          end;
        end;
        if topen then begin
          if fido then
            writeln(t,'---');
          close(t);
          if not ppp then
          SendMaps('DEL',box,fn) else
          if MakeRc(false,fn,box) then; { mehrere markierte Bretter abbestellen}
          topen:=false;
        end;
        dbSkip(d,1);
        end;
      dbClose(d);
      end;
    if existf(t) then erase(t);
    dispose(map);
    end;
end;


{ Unterprozeduren fÅr MapsReadList und MapsReadFile }

function ReadMafList(fn:pathstr; var bfile:string):boolean;
var t1,t2 : text;
    s     : string;
    ss    : string[40];

  function zok:boolean;
  begin
    zok:=pos('bestellt',lstr(s))>40;
  end;

begin
  assign(t1,fn); reset(t1);
  s:='';
  while not eof(t1) and not zok do readln(t1,s);
  if eof(t1) then begin
    closebox;
    fehler('Nachricht ist keine MAF-Brettliste!');
    ReadMaflist:=false;
    end
  else begin
    assign(t2,bfile+'.bl'); rewrite(t2);
    repeat
      if zok then begin
        ss:=trim(left(s,40));
        while cpos(' ',ss)>0 do ss[cpos(' ',ss)]:='_';
        writeln(t2,forms(boxpar^.MagicBrett+ss,40),mid(s,41));
        end;
      readln(t1,s);
    until eof(t1);
    close(t2);
    closebox;
    ReadMaflist:=true;
    end;
  close(t1);
end;

procedure ReadPromafList(fn:pathstr; var bfile:string);
var t1,t2 : text;
    s     : string;
begin
  assign(t1,fn); reset(t1);
  s:='';
  assign(t2,bfile+'.bl'); rewrite(t2);
  repeat
    readln(t1,s);
    if (s[1]=';') or (s[32]<>'/') then
      writeln(t2,s)
    else
      writeln(t2,left(s,31),left(BoxPar^.MagicBrett,length(Boxpar^.Magicbrett)-1),
                 mid(s,32));
  until eof(t1);
  close(t1);
  close(t2);
  closebox;
end;

procedure MapsReadList;
var absender : string[Adrlen];
    box      : string[BoxNameLen];
    betreff  : string[BetreffLen];
    d        : DB;
    bfile    : string[8];
    fido     : boolean;
    turbo    : boolean;
    uucp     : boolean;
    fn       : pathstr;
    bpsik    : BoxPtr;
label ende;
begin
  dbReadN(mbase,mb_absender,absender);
  dbReadN(mbase,mb_betreff,betreff);
  box:=systemname(absender);
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  if dbFound then
    dbRead(d,'dateiname',bfile)
  else
    if automessaging then begin
      trfehler1(804,box,errortimeout_short);   { 'unbekannte Box (%s) - Brettliste wurde nicht eingelesen' }
      dbClose(d);
      exit;
      end
    else begin
      box:=UniSel(1,false,'');
      if box='' then begin
        dbClose(d);
        exit;
        end
      else
        bfile:=BoxFilename(box);
      end;

  dbClose(d);
  fido:=(mapstype(box)=5);
  turbo:=(mapstype(box)=9);
  uucp:=(mapstype(box) in [7,11]);
  bpsik:=boxpar;
  new(boxpar);
  ReadBox(0,bfile,boxpar);
  if mapstype(box) in [2,8] then begin
    message('Brettliste fÅr '+ustr(box)+' wird eingelesen ...');
    fn:=TempS(dbReadInt(mbase,'msgsize'));
    extract_msg(0,'',fn,false,0);
    case mapstype(box) of
      2 : if ReadMaflist(fn,bfile) then;
      8 : ReadPromafList(fn,bfile);
    end;
    _era(fn);
    end
  else begin
    if (pos('BRETT',ustr(betreff))=0) and (betreff<>'Gruppenliste') and
       (pos('list',lstr(betreff))=0) and
      not (fido or turbo or uucp)
      and not ReadJN(getres(805),true) then   { 'Sind Sie sicher, da· das eine Brettliste ist' }
      goto ende;
    if pos('@',absender)=0 then
      trfehler(805,errortimeout)    { 'UngÅltige Absenderangabe' }
    else begin
      message(getreps(806,ustr(box)));   { 'Brettliste fÅr %s wird eingelesen ...' }
      makebak(bfile+'.BL','BAK');
      fn:=TempS(dbReadInt(mbase,'msgsize'));
      extract_msg(xTractMsg,'',fn,false,0);
      ExpandTabs(fn,bfile+'.BL');
      _era(fn);
      wkey(1,false);
      closebox;
      end;
    end;
ende:
  dispose(boxpar);
  boxpar:=bpsik;
end;


{ Brettliste aus Datei nach .BL einlesen }

procedure MapsReadFile;
var box     : string[BoxNameLen];
    fn      : pathstr;
    useclip : boolean;
    d       : DB;
    maggi   : boolean;
    promaf  : boolean;
    bfile   : string[8];
begin
  box:=UniSel(1,false,DefaultBox);
  if box='' then exit;   { brk }
  fn:='*.*';
  useclip:=true;
  if not ReadFilename(getres(821),fn,true,useclip) then exit;  { 'Brettliste einlesen }
  maggi:=(mapstype(box)=2);    { MagicNet }
  promaf:=(mapstype(box)=8);
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  dbRead(d,'dateiname',bfile);
  dbClose(d);
  ReadBox(0,bfile,boxpar);
  message(getreps(806,ustr(box)));   { 'Brettliste fÅr %s wird eingelesen ...' }
  if maggi then
    if not ReadMafList(fn,bfile) then exit
    else
  else if promaf then
    ReadPromafList(fn,bfile)
  else begin
    ExpandTabs(fn,bfile+'.BL');
    closebox;
    end;
  if useclip or ReadJN(getreps(817,fn),false) then    { '%s lîschen' }
    _era(fn);
end;


function BrettMark(var s:string; block:boolean):boolean;
begin
  BrettMark:=false;
  if (trim(s)='') or
     ((mapsnt=nt_Pronet) and ((s[8]='-') or (s[1] in [';','-']) or (left(s,4)='CODE')))
  then begin
    if not block then errsound;
    end
  else if (mapsnt=nt_ZConnect) and (mapsart=0) and (firstchar(s)='-') then
    rfehler(826)     { 'Dieses Brett kann nicht bestellt werden.' }
  else if (mapsnt=nt_ZConnect) and (mapsart=1) and (firstchar(s)='!') then
    rfehler(827)     { 'Dieses Brett kann nicht abbestellt werden.' }
  else if (mapsnt=nt_PPP) and (mapsart=15) and (firstchar(s)='!') then
    rfehler(826)     { 'Dieses Brett kann nicht bestellt werden.' }
  else
    BrettMark:=true;
end;


var LcolType : byte;  { 0=nix, 1=Z, 2=Maus, 3=ProNet, 4=Fido }

function MapsListcolor(var s:string; line:longint):byte;
begin
  MapsListcolor:=col.collisttext;
  case LColType of
    1 :   if (length(s)>2) and ((s[1]='J') or (s[1] in ['+','!'])) then
            MapsListcolor:=col.ColMapsBest;
    2,4 : if (length(s)>2) and (s[1]='+') then
            MapsListcolor:=col.colMapsBest;
    3 :   if (s[1]<>';') and (s[8]='X') then
            MapsListcolor:=col.colMapsBest;
  end;
end;

{ art: 0=bestellen, 1=abbestellen, 2=Bretter anlegen, 3=Inhalt (EM), 4=Rescan }

procedure MapsBrettliste(art:byte);
var d      : DB;
    box    : string[BoxNameLen];
    fn     : pathstr;
    brk    : boolean;
    t,tn   : text;
    s      : string;
    anz    : longint;
    netztyp: byte;
    maf    : boolean;
    promaf : boolean;
    quick  : boolean;
    maus   : boolean;
    fido   : boolean;
    turbo  : boolean;
    gs     : boolean;
    uucp   : boolean;
    ppp    : boolean;
    changesys: boolean;
    postmaster: boolean;
    qwk    : boolean;
    ask    : string[60];
    bretter: string[15];
    lfile  : string[12];
    verbose: boolean;
    listisopen: boolean;

label again;

  function fidobrett(s:string):string;
  var p : byte;
  begin
    s:=trim(s);
    p:=cpos(' ',s);
    if p=2 then begin
      s:=trim(mid(s,3)); p:=cpos(' ',s); end;
    if p=0 then p:=cpos(#9,s);
    if p>0 then s:=left(s,p-1);
    if s[1]='+' then delfirst(s);
    if s[1]='*' then delfirst(s);
    p:=pos('....',s);         { direkt angehÑngten Kommentar abschneiden }
    if p>0 then truncstr(s,p-1);
    fidobrett:=s;
  end;

  procedure writeform;
  var p  : byte;
      gr : string[78];
  begin
    if maf then
      if s[41]<>' ' then
        writeln(t,copy(s,41,4))
      else
        writeln(t,trim(copy(s,41,6)))
    else if promaf then
      writeln(t,left(s,4))
    else if maus then begin
      p:=13;
      while (p<length(s)) and (s[p]<>' ') do inc(p);
      gr:=trim(copy(s,3,p-2));
      if left(gr,1)='?' then delfirst(gr);    { geheime Gruppe }
      if (length(gr)=11) and (gr[10]=' ') then
        gr:=trim(left(gr,length(gr)-1));
      writeln(t,gr);
    end
    else if fido then begin
      if (art=0) and boxpar^.AreaPlus then
        write(t,'+');
      if art=1 then write(t,'-');
      s:=fidobrett(s);
(*      if (art=4) and not BoxPar^.areabetreff then
        s:=s+' -R'; {'%Rescan '+s;}     { rescan } *)
      writeln(t,s);
    end
    else if qwk then begin
      if art=0 then write(t,'ADD ')
      else write(t,'DROP ');
      writeln(t,left(s,3));
    end
    else begin
      s:=trim(s);
      if length(s)<2 then exit;
      p:=pos(' ',s);
      if p=0 then p:=pos(#9,s);
      if p>0 then
        if uucp or ppp then
          s:=left(s,p-1)
        else begin
          if p<5 then
            s:=copy(s,p+1,80);
          if pos(' ',s)>0 then
            s:=copy(s,1,pos(' ',s)-1);
          end;
      if s='' then exit;
      if not (quick or gs or uucp or ppp or turbo) and (s[1]<>'/') then
        write(t,'/');  { Euromail }
      writeln(t,s);
      end;
  end;

  const
    maxbuf = 50;
    
  var  
    linebuf : array[1..maxbuf] of String[100];
    tlb : text;
    lc : integer;
    
  function linebuffer : string;      
  begin
    if (lc<1) then begin
      lc:=0;
      while (lc<maxbuf) and (not Eof(tlb)) do begin
        Readln(tlb, s);
        s:=rtrim(s);
        if lastchar(s)='˚' then dellast(s);
        if (cpos(' ',s)<>0) and (firstchar(s)<>'!') then
          s:=copy(s,1,cpos(' ',s)-1);
        if (s<>#0) then begin
          inc(lc);
          linebuf[lc] := s;
        end
      end
    end;
    if (lc>0) then begin
      linebuffer:=linebuf[lc];
      dec(lc);
    end else linebuffer:=#0;
  end;

  procedure BretterAnlegen(fn:string);
  var
    x,y : byte;
    n   : longint;
    s   : string[100];
    i   : integer;
    fromfile : boolean;
  
    procedure nextbrett;
    begin
      moff;
      gotoxy(x+22,y+2); write(n:5);
      mon;
      if fromfile then s:=linebuffer
        else s:=next_marked
    end;

  begin
    if (fn<>'') then if not (exist(fn)) then exit;
    msgbox(30,5,'',x,y);
    mwrt(x+3,y+2,getres2(807,10));   { 'Bretter anlegen ...' }
    n:=0;
    lc:=0;
    fromfile:=false;
    if (fn<>'') then begin
      assign(tlb,fn);
      reset(tlb);
      fromfile:=true;
      s:=linebuffer;
    end else s:=first_marked;

    while s<>#0 do begin
      if quick then
        for i:=1 to length(s) do
          if s[i]='/' then s[i]:='\'
          else if s[i]='\' then s[i]:='/';
      if ppp and ((firstchar(s)='#') or
                  (firstchar(s)='$') or
                  (firstchar(s)=';')) then begin
        nextbrett;
        break;
      end;
      if uucp or ppp then
        for i:=1 to length(s) do
          if s[i]='.' then s[i]:='/';
      if maf then makebrett(trim(left(s,40)),n,box,netztyp,true) else
      if promaf then makebrett(trim(mid(s,32)),n,box,netztyp,true) else
      if maus then begin
        s:=trim(mid(s,3));
        if left(s,1)='?' then delfirst(s);  { geheime Gruppen }
        makebrett(boxpar^.MagicBrett+s,n,box,netztyp,true);
        end else
      if turbo then
        makebrett(boxpar^.magicbrett+s,n,box,netztyp,true) else
      if fido then
        makebrett(boxpar^.MagicBrett+fidobrett(s),n,box,netztyp,true)
      else if qwk then
        makebrett(boxpar^.MagicBrett+trim(copy(s,4,50)),n,box,netztyp,true)
      else makebrett(s,n,box,netztyp,true);
      nextbrett;
    end; { while (s<>#0) }

    if fromfile then close(tlb);
    closebox;
    dbFlushClose(bbase);
    aufbau:=true;
  end;

begin
  if mapsbox='' then begin
    box:=UniSel(1,false,DefaultBox);
    if box='' then exit;   { brk }
  end else box:=mapsbox;
  listisopen:=true;
  if not BoxHasMaps(box) then exit;
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  if dbFound then begin
    dbRead(d,'dateiname',fn);
    netztyp:=dbReadInt(d,'netztyp');
    dbRead(d,'nameomaps',mapsname);
    maf:=ntMAF(netztyp);
    promaf:=ntProMAF(netztyp);
    quick:=ntQuickMaps(netztyp);
    maus:=ntNude(netztyp);
    fido:=ntAreamgr(netztyp);
    gs:=(netztyp=nt_GS);
    uucp:=(netztyp=nt_UUCP);
    ppp:=(netztyp=nt_PPP);
    if uucp then begin
      ReadBoxpar(netztyp,box);
      changesys:=(boxpar^.BMtyp=bm_changesys);
      postmaster:=(boxpar^.BMtyp=bm_postmaster);
    end;
    turbo:=(netztyp=nt_Turbo);
    qwk:=(netztyp=nt_QWK);
  end else begin
    fn:='';
    maf:=false; quick:=false; maus:=false; fido:=false; gs:=false;
    uucp:=false; turbo:=false; promaf:=false; qwk:=false; postmaster:=false;
    netztyp:=0;
  end;
  dbClose(d);
  if fn='' then
    rfehler(806)      { 'BOXEN.IX1 ist defekt - bitte lîschen!' }
  else begin
    if (art=1) and exist(fn+'.bbl') and changesys and not ppp then
      lfile:=fn+'.bbl'  else
    if (art=1) and ppp then
      if exist(fn+'.RC') and (_filesize(fn+'.RC')>0) then
        lfile:=fn+'.RC'
      else begin
        rfehler(836); { Keine Bestellungen fÅr diese Box vorhanden! }
        exit;
      end
    else
    if (art=0) and ppp and exist(fn+'.GR') then
      lfile:=fn+'.GR'
    else lfile:=fn+'.BL';
    if not exist(lfile) then
      rfehler(807)    { 'Keine Brettliste fÅr diese Box vorhanden!' }
    else begin
      if fido or maus or turbo or qwk then
        ReadBoxpar(netztyp,box);
      OpenList(1,iif(_maus,79,80),4,screenlines-fnkeylines-1,-1,'/NS/M/SB/S/'+
                 'APGD/'+iifs(_maus,'VSC:080/',''));
      list_readfile(lfile,0);
      case art of
        0 : showkeys(9);
        1 : showkeys(-9);
        2 : showkeys(12);
        3 : showkeys(9);
        4 : showkeys(12);
      end;
    again:
      listVmark(BrettMark); mapsnt:=netztyp; mapsart:=art;
      if maus then LColType:=2 else
      if fido then lcoltype:=4 else
      if maf or quick then LColType:=0 else
      if promaf then lcoltype:=3
      else LColType:=1;
      ListCFunc(MapsListcolor);
      list(brk);
      if not brk then begin
        anz:=list_markanz;
        if anz=0 then anz:=1;
        if (mapsnt=nt_ZConnect) and (anz=1) then begin
          if (art=0) and (firstchar(first_marked)='-') then begin
            rfehler(826);   { 'Dieses Brett kann nicht bestellt werden.' }
            goto again;
          end;
          if (art=1) and (firstchar(first_marked)='!') then begin
            rfehler(827);   { 'Dieses Brett kann nicht abbestellt werden.' }
            goto again;
          end;
        end;
        if ppp and (anz=1) then
        if (art=0) and (firstchar(first_marked)='!') then begin
          rfehler(826);   { 'Dieses Brett kann nicht bestellt werden.' }
          goto again;
        end;
        bretter:=getres2(807,iif(anz=1,1,2));
        case art of
            0 : ask:=reps(reps(getreps2(807,3,strs(anz)),bretter),box);
            1 : ask:=reps(reps(getreps2(807,4,strs(anz)),bretter),box);
            2 : ask:=reps(getreps2(807,5,strs(anz)),bretter);
          3,4 : ask:=getres2(807,6);   { 'Inhalt der gewÑhlten Bretter anfordern' }
        end;
        if not ReadJN(ask,true) then
          goto again;
        if art in [0,1,3,4] then begin
          fn:=TempS(10000);
          assign(t,fn);
          rewrite(t);
          if quick or (uucp and postmaster) then
            wr_btext(t,art<>0,uucp);
          s:=first_marked;
          if fido and (art=4) and not Boxpar^.areabetreff then
            writeln(t,'%Rescan');
          while s<>#0 do begin
            writeform;
            s:=next_marked;
          end;
          if fido then writeln(t,'---');
          close(t);
          if art=3 then
            verbose:=ReadJN(getres2(810,20),false);  { 'ausfÅhrliche Liste' }
          if not ppp then
          case art of
            0 : sendmaps('ADD',box,fn);
            1 : sendmaps('DEL',box,fn);
            3 : sendmaps('INHALT'+iifs(verbose,' VERBOSE',''),box,fn);
            4 : sendmaps(iifs(BoxPar^.AreaBetreff,'-r',''),box,fn);
          end;
          {hdo:=false;
          if ppp and (art=0) and readjn(getres2(807,11),false) then hdo:=true;}
          if ppp and (art in [0,1]) then begin
            closelist;
            listisopen:=false;
            if MakeRC(art=0,fn,box) then
              BretterAnlegen(ustr(boxfilename(box))+'.RC');
          end;
          if (art=0) and (uucp or (netztyp=nt_ZCONNECT)) then
            BretterAnlegen('');
          erase(t);
        end else BretterAnlegen('');
      end;
      if (listisopen) then closelist;
      freeres;
      aufbau:=true;
      {if ppp then copyfile(ustr(box)+'.RC',ustr(box)+'.BBL');}
    end
  end
end;

(*
procedure Sortbliste;
  var
    box    : string[boxnamelen];
    blfile : string[12];
    d      : DB;
    nt     : byte;
begin
  if not exist(ownpath+'GR-SORT.EXE') then begin
    rfehler(834); { 'GR-SORT.EXE nicht vorhanden!' }
    exit;
  end;
  box:=UniSel(1,false,DefaultBox);
  if box='' then exit;
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  dbRead(d,'netztyp',nt);
  dbClose(d);
  blfile:=ustr(boxfilename(box))+'.BL';
  if not exist(ownpath+blfile) then begin
    rfehler1(835,blfile); { '%s ist nicht vorhanden' }
    exit;
  end;
  if nt in [nt_ppp,nt_uucp] then
    shell('GR-SORT.EXE '+blfile,600,3) else
  rfehler(833); { 'Diese Funktion wird nur bei RFC-Boxtypen unterstÅtzt' }
end;
*)

type
  pmarklist = ^tmarklist;
  tmarklist = record
    brettCRC : longint;
    brettSZ : byte;
    next : pmarklist;
  end;
  plinelist = ^tlinelist;
  tlinelist = record
    lineNo : word;
    next : plinelist;
  end;

var    
  marklist,
  markact       : pmarklist;
  linelist,
  lineact       : plinelist;

procedure ClearRCCache;
begin
  markact:=marklist;
  while (markact<>nil) do begin
    marklist:=markact^.next;
    dispose(markact);
    markact:=marklist
  end
end;
  
procedure ClearLineList;
begin
  lineact:=linelist;
  while (lineact<>nil) do begin
    linelist:=lineact^.next;
    dispose(lineact);
    lineact:=linelist
  end
end;
  
  
function MakeRC(bestellen: boolean; rctemp: pathstr; box: string):boolean;
var t1,t2,t3      : text;
    CachedRCFile,
    rcfile,blfile : string[12];
    Line,Line2    : string;
    Count,
    LineCount     : integer;
    LineNoInTMP,
    LineNoInRC    : longint;
    rccounter,
    banz          : word;
    x,y           : byte;
    brk           : boolean;
    hdo           : boolean;

   function BrettInRC(brett:string) : boolean;
   var tx : text;
       mark : boolean;
       brettCRC : longint;
       brettSZ : byte;
   begin
     mark:=false;
     LineNoInRC:=0;
     rccounter:=0;
     if (marklist=nil) then begin
       assign(tx,CachedRCFile);
       reset(tx);
       repeat
         readln(tx,line);
         line:=copy(line,1,pos(' ',line)-1);
         if (maxavail>sizeof(tmarklist)+1024) then begin
           if (markact=nil) then begin
             new(markact);
             marklist:=markact
           end else begin
             new(markact^.next);
             markact:=markact^.next
           end;
           markact^.brettCRC:=crc32(line);
           markact^.brettSZ:=length(line);
           markact^.next:=nil;
           inc(rccounter)
         end else begin
           fehler(getres2(2422,103));  { 'Nicht genug Hauptspeicher!~ }
           freeres;
           break
         end
       until eof(tx);
       close(tx)
     end;
     markact:=marklist;
     brettCRC:=crc32(brett);
     brettSZ:=length(brett);
     while (markact<>nil) do begin
       inc(LineNoInRC);
       if (markact^.brettCRC=brettCRC) and (markact^.brettSZ=brettSZ)
       then begin
         mark:=true; markact:=nil
       end else markact:=markact^.next
     end;
     BrettInRC := mark
  end;

  procedure domark;
  var
    x,y,z     : byte;
  begin
    blfile:=ustr(boxfilename(box));
    blfile:=blfile+iifs(exist(blfile+'.GR'),'.GR','.BL');
    if not exist(rcfile) or not exist(blfile) then exit;
    closebox;
    z:=length(getres(832));
    msgbox(z+12,3,'',x,y);
    attrtxt(col.colmbox);
    mwrt(x+3,y+1,getres(832)); { 'Noch zu verarbeiten:' }
    attrtxt(col.colmboxhigh);
    assign(t2,blfile);
    reset(t2);
    assign(t3,TempFile('')); { neues BL-File }
    rewrite(t3);
    reset(t1);
    repeat   { bestellte Bretter markieren }
      mwrt(x+z+4,y+1,strsn(banz,5));
      readln(t2,line2);
      if (pos(' ',line2)<>0) and (firstchar(line2)<>'!') then
        line2:=copy(line2,1,pos(' ',line2)-1);
      line2:=rtrim(line2);
      if lastchar(line2)='*' then dellast(line2);
      if BrettInRC(line2) then begin
        writeln(t3,line2+'   ˚');
        dec(banz)
      end else writeln(t3,line2);
    until eof(t2);
    close(t1);                          {#251}
   {writeln(t3,'Memory: ',memavail);}
    mwrt(x+z+4,y+1,getres(833)); { 'fertig' }
    signal; wkey(1,false);
    close(t2);
    flush(t3);
    close(t3);
    erase(t2);
    rename(t3,blfile);
  end;

begin
{.$I+}
  moment;
  MakeRc:=true;
  marklist:=nil;
  markact:=nil;
  linelist:=nil;
  lineact:=nil;
  ReadBox(nt_PPP,box,boxpar);
  rcfile:=ustr(boxfilename(box))+'.RC';
  assign(t1,rcfile);       { BOX.RC                      }
  assign(t2,rctemp);       { ????.TMP: ab/bestellte NG's }
  if not (exist(rcfile)) then begin
    rewrite(t1);
    close(t1);
  end;
  reset(t2);
  CachedRCFile:=rcfile;

  if bestellen then begin
    with BoxPar^ do begin
      hdo:=false;
      dialog(30,5,getres2(810,94),x,y);  {'Newsgroups bestellen'}
      pushhp(11909);
      maddbool(2,2,getres2(807,11),hdo); {'Nur Header bestellen'}
      maddint(2,4,getres2(810,95),NntpArtclAnz,4,6,0,32000); { 'Anzahl der Artikel' }
      mappsel(false,getres2(936,98)+getres2(936,100));
      freeres;
      readmask(brk);
      pophp;
      enddialog;
    end;
    if BrettInRC('test') then ; { preload cache }
    banz:=rccounter;
    append(t1);
    while not eof(t2) do begin   { PrÅfen, ob Brett schon bestellt }
      readln(t2,Line);
      inc(LineNoInTMP);
      if cpos(' ',Line) <> 0 then
        Line:=copy(Line,1,cpos(' ',Line)-1);
      if lastchar(Line)='˚' then dellast(Line);
      line:=RTrim(Line);
      if lastchar(line)='*' then dellast(line);
      if (firstchar(Line)='!') or (BrettInRC(line)) then begin
        if (firstchar(Line)='!') then
          rfehler1(830,Line) else  { '%s kann nicht bestellt werden' }
          rfehler1(831,Line);      { '%s wurde bereits bestellt'     }
      end else begin
        inc(banz);
        Line:=Line+' -'+strs(BoxPar^.NntpArtclAnz);
        if hdo then Line:=Line+' HdrOnly';
        writeln(t1,Line)
      end
    end;
    close(t2);
    flush(t1);
    close(t1)

  end else begin             { abbestellen }
    banz:=0;
    MakeRc:=false;
    while not eof(t2) do begin
      readln(t2,line);       { Zeile aus Temp lesen }
      if pos(' ',line)<>0 then line:=copy(line,1,pos(' ',line)-1);
      if (BrettInRC(line)) then begin
        if (maxavail>sizeof(tmarklist)+1024) then begin
          if (lineact=nil) then begin
            new(lineact);
            linelist:=lineact
          end else begin
            new(lineact^.next);
            lineact:=lineact^.next
          end;
          lineact^.lineNo:=LineNoInRC;
          lineact^.next:=nil;
        end else begin
          fehler(getres2(2422,103));  { 'Nicht genug Hauptspeicher!~ }
          freeres;
          break
        end
      end
    end;
    close(t2);
    ClearRCCache;

    assign(t3,TempFile('')); { RC-Copy-File }
    rewrite(t3);             { ????.TMP: neues BOX.RC      }
    reset(t1);               { altes BOX.RC                }
    Count:=0;
    repeat
      readln(t1,Line2);
      inc(Count);
      lineact:=linelist;
      while (lineact<>nil) do begin
        if (lineact^.lineNo<>Count)
          then lineact:=lineact^.next
          else break { Gruppe gefunden, also abbrechen (mit lineact<>nil) }
      end;
      if (lineact=nil) then begin
        writeln(t3,Line2); { nicht gefunden: Åbernehmen }
        inc(banz)
      end
    until eof(t1);
   
    close(t1);
    erase(t1);                   { Altes RC lîschen }
    flush(t3);
    close(t3);
    rename(t3,rcfile);           { temp nach RC umbenennen }
  end;
  ClearLineList;
  ClearRCCache; { *.RC neu einlesen fÅr domark }
  domark;
  ClearRCCache;
  InOutRes:=0;
  closebox;
{.$I-}
end;


procedure MapsCommands(defcom:byte);   { 0=Auswahl, 1=Brettliste holen }
var brk     : boolean;
    comm    : string;
    box     : string[BoxNameLen];
    t       : text;
    fn      : pathstr;
    d       : DB;
    area    : boolean;
    request : boolean;
    nt      : byte;
    maf     : boolean;
    maus    : boolean;
    info    : MausInfAP;
    infos   : integer;
    fido    : boolean;
    gs      : boolean;
    turbo   : boolean;
    uucp,gup: boolean;
    ppp     : boolean;
    autosys : boolean;
    feeder  : boolean;
    postmaster : boolean;
    promaf  : boolean;
    lines   : byte;
    i       : integer;
    domain  : string[60];
    bfname  : string[8];
    bflist  : string[12];

  procedure app(s1,s2:string);
  begin
    app_l(' '+forms(s1,iif(maus,8,iif(fido or (uucp and not gup),15,20)))+s2);
  end;

  procedure rdsystem;
  var x,y : byte;
      sys : string[BoxNameLen];
      brk : boolean;
  begin
    diabox(28,5,getres(808),x,y);   { 'Info <System>' }
    sys:='';                  {!!MH: BoxNameLen?}
    readstring(x+3,y+2,getres(809),sys,8,8,'>',brk);   { 'Systemname' }
    closebox;
    if brk then comm:=''
    else comm:='INFO '+sys;
  end;

  procedure rdthema;
  begin
    case minisel(33,10+(screenlines-25)div 2,'Thema',
                 '^HILFE,^INFO,^LIST,^SCRIPT,^STATUS,^VERSION,^ADD,^DEL',1) of
      1 : comm:='HILFE HILFE';
      2 : comm:='HILFE INFO';
      3 : comm:='HILFE LIST';
      4 : comm:='HILFE SCRIPT';
      5 : comm:='HILFE STATUS';
      6 : comm:='HILFE VERSION';
      7 : comm:='HILFE ADD';
      8 : comm:='HILFE DEL';
    else
      comm:='';
    end;
  end;

  procedure gruppenuser;
  var gruppe : string[80];
      user   : string[80];
      x,y,p  : byte;
      brk    : boolean;
      aufnehm: boolean;
  begin
    aufnehm:=cpos('>',comm)>0;
    gruppe:=''; user:='';
    case aktdispmode of
      -1,0 : if not dbEOF(bbase) then
               dbReadN(bbase,bb_brettname,gruppe);
      1..4 : if not dbEOF(ubase) then begin
               dbReadN(ubase,ub_username,user);
               end;
    10..12 : if not dbEOF(mbase) then begin
               if not aufnehm then
                 dbReadN(mbase,mb_absender,user);
               dbSeek(bbase,biIntnr,copy(dbReadStr(mbase,'brett'),2,4));
               if dbFound then
                 dbReadN(bbase,bb_brettname,gruppe);
               end;
    end;
    if user<>'' then begin
      p:=cpos('@',user);
      if p>0 then user:=trim(left(user,p-1))+' @ '+trim(mid(user,p+1));
      end;
    if gruppe<>'' then begin
      delete(gruppe,1,1);
      ReadBoxPar(0,box);
      with BoxPar^ do
        if left(ustr(gruppe),length(MagicBrett))<>ustr(MagicBrett) then
          gruppe:=''
        else
          delete(gruppe,1,length(magicbrett));
      end;
    dialog(44,5,'User '+iifs(aufnehm,'aufnehmen','ausschlie·en'),x,y);
    maddstring(3,2,'Gruppe ',gruppe,30,eBrettLen,''); mhnr(670);
    maddstring(3,4,'User   ',user,30,eAdrLen,'');
    readmask(brk);
    enddialog;
    if brk then
      comm:=''
    else
      comm:='GU'+user+right(comm,1)+gruppe;
  end;

  function MausCRC(comm:string):boolean;
  var i : integer;
  begin
    i:=infos;
    while (i>0) and (comm<>info^[i].ID) do dec(i);
    MausCRC:=((i=0) and (firstchar(comm)='I')) or info^[i].crcflag;
  end;

  procedure Sortblist;
  var
    i      : integer;
    x,y    : byte;
  begin
    if not exist(ownpath+bflist) then begin
      rfehler1(835,bflist); { '%s ist nicht vorhanden' }
      exit;
    end;
    if exist(ownpath+'RPSORT.COM') then begin
      shell('RPSORT.COM /a /b /d /n /z '+bflist+' '+temppath+'sort.tmp',600,3);
      if exist(temppath+'sort.tmp') then begin
        copyfile(temppath+'sort.tmp',bflist);
        _era(temppath+'sort.tmp');
      end;
    end else
    if exist(ownpath+'GR-SORT.EXE') then
      shell('GR-SORT.EXE '+bflist,600,3)
    else
    if exist(ownpath+'SORT.BAT') then
      shell('SORT.BAT '+bflist,600,1)
    else
    if exist(ownpath+'SORT.CMD') then
      shell('SORT.CMD '+bflist,600,1)
    else begin
      errsound;
      msgbox(63,10,_hinweis_,x,y);
      y:=y+2;
      for i:=1 to 6 do begin
        mwrt(x+3,y,getres2(10810,i));
        inc(y);
      end;
      wait(curoff);
      closebox;
      if ReadJN(getres2(10810,7),false) then begin
        moment;
        shell('sort <'+bflist+' >'+temppath+'sort.tmp',600,0);
        if exist(temppath+'sort.tmp') then begin
          copyfile(temppath+'sort.tmp',bflist);
          _era(temppath+'sort.tmp');
        end;
        closebox;
      end;
      freeres;
    end;
  end;

begin
  box:=UniSel(1,false,DefaultBox);
  if box='' then exit;
  if not BoxHasMaps(box) then exit;
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(box));
  bfname:=ustr(dbReadStr(d,'dateiname'));
  bflist:=bfname+iifs(exist(bfname+'.GR'),'.GR','.BL');
  dbRead(d,'nameomaps',mapsname);
  dbRead(d,'netztyp',nt);
  dbRead(d,'domain',domain);
  dbClose(d);
  maf:=ntMAF(nt);
  ntQuickMaps(nt);
  maus:=ntNude(nt);
  fido:=ntAreamgr(nt);
  gs:=(nt=nt_GS);
  uucp:=(nt=nt_UUCP);
  ppp:=(nt=nt_ppp);
  if ppp and (defcom=1) then begin
    ReadBoxpar(nt,box);
    with boxpar^ do begin
      if not nntpList then begin
        nntpList:=not nntpList;
        WriteBox(bfname,BoxPar,nt_PPP);
      end;
    end;
    if exist(bflist) then era(bflist);
    message(getreps2(810,91,ustr(box)));   { 'Newsgroup-Liste fÅr %s wird angefordert...' }
    wkey(1,false);
    closebox;
    exit;
  end;
  if uucp then begin
    ReadBoxpar(nt,box);
    gup:=(boxpar^.BMtyp=bm_gup);
    autosys:=(boxpar^.BMtyp=bm_autosys);
    feeder:=(boxpar^.BMtyp=bm_feeder);
    postmaster:=(boxpar^.BMtyp=bm_postmaster);
    end;
  turbo:=(nt=nt_Turbo);
  promaf:=ntProMaf(nt);
  case defcom of
    0 : if not ntMapsOthers(nt) or ((nt=nt_UUCP) and postmaster) then begin
          rfehler(818);     { 'Bei dieser Box nicht mîglich.' }
          exit;
          end;
    1 : if not ntMapsBrettliste(nt) then begin
          rfehler(818);
          exit;
          end;
  end;
  area:=(mapsname='AREAFIX');
  request:=(mapsname='REQUEST');
  if maf then lines:=4
  else if maus then lines:=17
  else if fido then lines:=5
  else if area then lines:=7
  else if request then lines:=6
  else if gs then lines:=4
  else if ppp then lines:=2
  else if uucp then
    if gup then lines:=3
    else if autosys then lines:=5
    else if feeder then lines:=5
    else lines:=4
  else if turbo then lines:=1
  else lines:=18;
  if maus then begin
    new(info);
    MausReadITI(box,info,infos);
    end;
  if defcom=1 then begin
    if fido then comm:='List' else
    if area then comm:='LIST ALL BRETTER' else
    if request then comm:='LIST BRETTER' else
    if maf  then comm:='LIST ALLE' else
    if maus then comm:='ITG' else
    if gs   then comm:='BESTELLBARE BRETTER' else
    if uucp then if gup then comm:='newsgroups *'
                 else if autosys then comm:='newsgroups'
                 else if feeder then comm:='@active'
                 else comm:='getgroups' else
    if turbo then comm:='BRETTLISTE' else
    if promaf then comm:='REQUEST'
    else comm:='LIST VERBOSE BRETTER *';
    brk:=false;
    end
  else begin
    listbox(iif(maus,45,iif(ppp,62,57)),lines,
      iifs(ppp,getreps2(810,89,ustr(box)),  {'RFC/PPP: Newsgroup-Liste fÅr <'+box+'> bearbeiten'}
      getres2(810,0)+mapsname+        { 'Nachricht an ' }
      iifs((mapsname='MAPS') and (random<0.07),'-o-MAT','')+'@'+box));
    if fido then begin
      app('List',getres2(810,40));      { 'Liste der verfÅgbaren Bretter' }
      app('Query',getres2(810,41));     { 'Liste der bestellten Bretter' }
      app('Unlinked',getres2(810,42));  { 'Liste der nicht bestellten Bretter' }
      app('Help',getres2(810,43));      { 'Hilfe zu den Areafix-Befehlen' }
      app('Rescan',getres2(810,44));    { 'Brettinhalt anfordern' }
      end
    else if area then begin
      app('HILFE',getres2(810,50));     { 'Hilfe zu den AREAFIX-Befehlen' }
      app('LIST ALL BRETTER',getres2(810,51));   { 'komplette Brettliste' }
      end
    else if request then begin
      app('HILFE',getres2(810,55));     { 'Hilfe zu den REQUEST-Befehlen' }
      app('LIST BRETTER',getres2(810,56));  { 'Brettliste' }
      app('LIST OTHER BRETTER',getres2(810,57));   { 'nicht bestellte Bretter' }
      end
    else if maf then begin
      app('HILFE','Hilfe zu dem MAF-Befehlen');
      app('LIST ALLE','Brettliste');
      app('LIST BESTELLT','bestellte Bretter');
      app('LIST UNBESTELLT','unbestellte Bretter');
      end
    else if maus then begin
      for i:=1 to infos do
        app(info^[i].ID,info^[i].text);
      app('GU>','Gruppenmitglied aufnehmen');
      app('GU<','Gruppenmitglied ausschlie·en');
      end
    else if gs then begin
      app('BESTELLBARE BRETTER','Liste der bestellbaren Bretter');
      app('BESTELLTE BRETTER','Liste der bestellten Bretter');
      app('BRETT +','Bretter bestellen');
      app('BRETT -','Bretter abbestellen');
      end
    else if ppp then begin
      app(getres2(810,85),getres2(810,86)); {'Sortieren','Newsgroup-Liste alphabetisch sortieren'}
      app(getres2(810,87),getres2(810,88)); {'Lîschen','Newsgroup-Liste lîschen (Neuanforderung)'}
    end
    else if uucp then
      if gup then begin
        app('help',getres2(810,70));      { 'Hilfe zu Gup anfordern' }
        app('list',getres2(810,71));      { 'Liste der bestellten Bretter' }
        app('newsgroups *',getres2(810,72));   { 'Liste der verfÅgbaren Bretter' }
        end
      else if autosys then begin
        app('help',getres2(810,75));        { 'Hilfe zu AutoSys anfordern' }
        app('newsgroups',getres2(810,72));  { 'Liste der verfÅgbaren Bretter' }
        app('active',getres2(810,77));      { 'Traffic-öbersicht' }
        app('perms',getres2(810,76));       { 'Brett-Zugriffsrechte abfragen' }
        app('show',getres2(810,71));        { 'Liste der bestellten Bretter' }
        end
      else if feeder then begin
        app('@help',getres2(810,80));        { 'Hilfe zu Feeder anfordern' }
        app('@active',getres2(810,72));      { 'Liste der verfÅgbaren Bretter' }
        app('@get',getres2(810,71));         { 'Liste der bestellten Bretter' }
        app('@suspend',getres2(810,81));     { 'alle Bretter vorÅbergehend abbestellen' }
        app('@resume',getres2(810,82));      { 'alle Bretter reaktivieren' }
        end
      else begin
        app('getgroups',getres2(810,60));
        app('getsys',getres2(810,62));
        app('setsys',getres2(810,63));
        app('help',getres2(810,61));
        end
    else if turbo then
      app('BRETTLISTE','Brettliste anfordern')
    else begin
      app('HILFE *',getres2(810,1));          { 'Hilfe zu allen MAPS-Befehlen' }
      app('HILFE <Thema>',getres2(810,2));    { 'Hilfe zu einem Befehl' }
      app('HILFE THEMEN',getres2(810,3));     { 'Themen-öbersicht' }
      app('HOLD ON',getres2(810,21));         { 'Bretter vorÅbergehend abbestellen (Urlaub)' }
      app('HOLD OFF',getres2(810,22));        { 'Bretter wieder aktivieren' }
      app('INHALT',getres2(810,4));           { 'Brettinhalt' }
      app('INFO',getres2(810,5));             { 'Infos zum eigenen System' }
      app('INFO *',getres2(810,6));           { 'Infos zu allen Systemen' }
      app('INFO <System>',getres2(810,7));    { 'Infos zu einem bestimmten System' }
      app('LIST ALL',getres2(810,8));         { 'User-, Brett- und Systemliste' }
      app('LIST BRETTER',getres2(810,9));     { 'Brettliste' }
      end;
    if not (maf or maus or fido or gs or uucp or ppp or turbo) then begin
      if not request then app('LIST USER',getres2(810,11));   { 'Userliste' }
      app('LIST MY BRETTER',getres2(810,12));   { 'bestellte Bretter' }
      if not request then app('LIST OTHER BRETTER',getres2(810,13));   { 'nicht bestellte Bretter' }
      if not (area or request) then begin
        app('PM LOESCHEN',getres2(810,14));   { 'Postfachinhalt in *Mailbox* lîschen' }
        app('STATUS',getres2(810,18));   { 'Eigenen Userstatus abfragen' }
        end;
      app('ADD',getres2(810,16));        { 'Bretter bestellen' }
      app('DEL',getres2(810,17));        { 'Bretter abbestellen' }
      end;
    freeres;
    list(brk);
    closebox;
    if not brk then begin
      comm:=trim(left(first_marked,iif(maus,9,iif(fido or uucp or ppp,16,21))));
      if ppp then begin
        brk:=true;
        if comm=getres2(810,85) then Sortblist; {'Sortieren'}
        if comm=getres2(810,87) then begin      {'Lîschen'  }
          if exist(bflist) then begin
            era(bflist);
            message(getreps2(810,92,ustr(box)));   { 'Newsgroup-Liste fÅr %s wurde gelîscht...' }
          end else
            message(getreps2(810,93,ustr(box)));   { 'Newsgroup-Liste fÅr %s existiert nicht!' }
          wkey(1,false);
          closebox;
          ReadBoxpar(nt,box);
          with boxpar^ do begin
            if not nntpList and ReadJN(getres2(810,90),true) then begin {'Soll die Newsgroup-Liste angefordert werden'}
              nntpList:=not nntpList;
              WriteBox(bfname,BoxPar,nt_PPP);
              message(getreps2(810,91,ustr(box)));   { 'Newsgroup-Liste fÅr %s wird angefordert...' }
              wkey(1,false);
              closebox;
            end;
          end;
        end;
      end;
    end;
  end;
  if not brk then begin
    if comm='BRETT +' then comm:='ADD'
    else if comm='BRETT -' then comm:='DEL';
    brk:=false;
    if not (area or request or maf or fido)
       and ((left(comm,4)='LIST') and (comm<>'LIST SYSTEME')) and (defcom=0)
    then begin
      pushhp(69);
      if ReadJNesc(getres2(810,20),true,brk) then begin   { 'ausfÅhrliche Liste' }
        insert(' VERBOSE',comm,pos(' ',comm));
        comm:=comm+' *';
        end;
      pophp;
      end;
    if not brk then begin
      if Fido or uucp then begin
        ReadBoxPar(0,box);
        if comm='Rescan' then begin
          mapsbox:=box;
          MapsBrettliste(4);
          mapsbox:='';
          exit;
          end;
        end;
      fn:=TempS(2000);
      if comm='INFO <System>' then rdsystem;
      if comm='HILFE <Thema>' then rdthema;
      if (comm='GU>') or (comm='GU<') then
        gruppenuser
      else
        if maus and MausCRC(comm) then
          comm:=comm+' -1';    { CRC -1 -> Maus-Infofile anfordern }
      if comm='INHALT' then begin
        mapsbox:=box;
        mapsbrettliste(3);
        mapsbox:='';
        end
      else if (comm<>'ADD') and (comm<>'DEL') and (comm<>'SCRIPT') then begin
        assign(t,fn);
        rewrite(t);
        if fido then begin
          if not boxpar^.AreaBetreff then writeln(t,'%',comm);
          writeln(t,'---');
          end
        else if uucp then begin
          writeln(t,'system: ',boxpar^.pointname,
                    iifs(boxpar^.BMdomain,domain,''));
          writeln(t,'passwd: ',boxpar^.areapw);
          writeln(t,comm);
          end
        else if promaf then begin
          writeln(t);
          writeln(t);
          writeln(t,'BRETTER');
          end
        else
          writeln(t);
        close(t);
        end
      else begin
        EditFile(fn,false,false,0,false);
        if _filesize(fn)<=2 then begin
          rfehler(808);   { 'leere Nachricht - nicht abgeschickt' }
          comm:='';
          end;
        end;
      if exist(fn) and (comm<>'') then
        if fido then begin
          if boxpar^.AreaBetreff then
            if comm='Query' then comm:='-q'
            else if comm='List' then comm:='-l'
            else if comm='Unlinked' then comm:='-u'
            else comm:='-h'
          else
            comm:='';
          SendMaps(comm,box,fn);
          end
        else
          SendMaps(comm,box,fn);
      if exist(fn) then _era(fn);
      end;
    end;
  if maus then
    dispose(info);
  if defcom=0 then
    closelist;
end;


{ Usenet-Sysfile aus akt. Nachricht auslesen   }
{ BoxPar der betreffenden Box mu· geladen sein }

{ This is your latest sys file entry

  xpoint/xpoint.sh.sub.org:shlink.dfue,shlink.general,shlink.ibm,shlink.general,\
          shlink.test/!local,all:f:   }

procedure GetSysfile;
var fn   : pathstr;
    t,t2 : text;
    s    : string;
    p    : byte;

  procedure WriteStr;
  var p : byte;
  begin
    repeat
      p:=cpos(',',s);
      if p>0 then begin
        writeln(t2,left(s,p-1));
        delete(s,1,p);
        end;
    until p=0;
  end;

begin
  rmessage(820);      { 'Lese Sysfile-Eintrag ...' }
  fn:=TempS(dbReadInt(mbase,'groesse'));
  XRead(fn,false);
  assign(t,fn);
  reset(t);
  s:='';
  with BoxPar^ do begin
    while not eof(t) and (left(s,length(pointname))<>pointname) do
      readln(t,s);
    s:=trim(s); p:=cpos(':',s);
    if not eof(t) and (p>0) then begin
      assign(t2,BoxFilename(boxpar^.boxname)+'.BBL');
      rewrite(t2);
      delete(s,1,p);
      while right(s,1)='\' do begin
        dellast(s);
        WriteStr;
        readln(t,s);
        s:=trim(s);
        end;
      p:=cpos('/',s); if p=0 then p:=cpos(':',s);
      if p>0 then begin
        s:=left(s,p-1)+',';
        WriteStr;
        end;
      close(t2);
      end;
    end;
  close(t);
  _era(fn);
  closebox;
end;


{$I xp8fs.inc}     { Fileserver }
{$I xp8.inc}       { Fido FileScan }

end.
{
  $Log: xp8.pas,v $
  Revision 1.51  2001/09/02 17:05:07  MH
  - XPNews-Fix: '*' in BL-File ignorieren bzw. entfernen
    (es wird sonst ein ebensolches Brett angelegt)

  Revision 1.50  2001/07/15 11:15:02  MH
  - Fix im Brettmanger: Nochmal ergÑnzt

  Revision 1.49  2001/07/15 10:54:47  MH
  - Fix im Brettmanger: Existierten keine Bestellungen, so wurde
    das BL-File zum abbestellen verwendet.
  - Auch ';' als Kommentar in der Brettliste erlauben

  Revision 1.48  2001/07/10 00:40:06  MH
  - RPSORT Parameter Åbergeben, die die Sortierung optimieren

  Revision 1.47  2001/07/08 15:03:45  MH
  - Auch Newsgrouplisten im Format *.GR akzeptieren

  Revision 1.46  2001/07/08 11:35:01  MH
  - BrettManager: Sortieren...SORT.BAT und SORT.CMD
    wird auch im XP-Verzeichnis gesucht (CMD funzt hier unter NT nicht)

  Revision 1.45  2001/07/08 10:22:34  MH
  - BrettManager: Sortieren...DOS SORT Befehl absichern!
    (fehlender Variablen hinzugefuegt)

  Revision 1.44  2001/07/08 10:20:33  MH
  - BrettManager: Sortieren...DOS SORT Befehl absichern!

  Revision 1.43  2001/07/08 09:54:50  MH
  - BrettManager: Sortieren...RPSORT-UnterstÅtzung!

  Revision 1.42  2001/07/07 21:36:58  MH
  - BretterAnlegen im SpezialMode und ^H wieder hergestellt

  Revision 1.41  2001/07/07 15:52:59  MH
  - ArticelAnzahl immer aus Config nehmen und nicht bei 0 Åberschreiben

  Revision 1.40  2001/07/07 14:55:26  MH
  - Onlinehilfe hinzugefÅgt

  Revision 1.39  2001/07/07 14:46:27  MH
  - Onlinehilfe hinzugefÅgt

  Revision 1.38  2001/07/04 23:41:38  MH
  - optik

  Revision 1.37  2001/07/04 21:02:57  MH
  - Fixversuch-Nachrichtenweiterschaltung: Beim scrollen in jedem LeseMode
    sprang der CursorBalken auf die erste Position, aber auf die falsche
    Nachricht (!Back! in GoDown() auskommentiert)

  Revision 1.36  2001/07/04 01:14:57  MH
  - unnîtige StringCopyOperation entfernt

  Revision 1.35  2001/07/03 23:26:27  MH
  - unnîtige StringCopyOperation entfernt

  Revision 1.34  2001/06/20 18:47:37  MH
  - Anlegen von Geisterbrettern verhindern (#, $)

  Revision 1.33  2001/06/18 20:17:38  oh
  Teames -> Teams

  Revision 1.32  2001/04/04 19:57:03  oh
  -Timeouts konfigurierbar

  Revision 1.31  2001/03/21 21:58:48  oh
  -Brettmanager final update, verkraftet jetzt ueber 7000 Bretter im RC und ist irre schnell

  Revision 1.30  2001/01/05 22:37:58  MH
  Fortschrittsanzeige:
  - Zahlen heller darstellen

  Revision 1.29  2001/01/05 17:05:59  MH
  RFC/PPP Brettbestellung:
  - Fortschrittsanzeige hinzugefÅgt

  Revision 1.28  2000/09/05 20:25:22  MH
  Brettmanager: Kleineren Fix im Dateihandling

  Revision 1.27  2000/09/02 22:07:10  MH
  HeaderOnly: Kann nun auch Åber Brettmanager gesetzt werden

  Revision 1.26  2000/08/24 14:27:31  MH
  Bestellroutine: Flushen, damit nichts verloren geht.

  Revision 1.25  2000/08/21 18:44:11  MH
  Brettlist-Sortierer in den Resourcen aufgenommen

  Revision 1.24  2000/08/20 13:23:50  MH
  Markierung in der Brettliste etwas beschleunigt

  Revision 1.23  2000/08/12 11:55:59  MH
  RFC/PPP/UUCP:
  - Brettlisten kînnen nun Åber den Brettmanager sortiert werden

  Revision 1.22  2000/08/12 09:46:26  MH
  [RFC/PPP]: Abbestellfunktion verbessert

  Revision 1.21  2000/08/11 22:55:09  MH
  [RFC/PPP] Fix: Brettmarkierung

  Revision 1.20  2000/08/11 18:24:18  MH
  RFC/PPP: Bestellliste wird nun fÅr bestellte Bretter zur
           besseren öbersicht mit einer Markierung versehen

  Revision 1.19  2000/06/28 20:09:39  MH
  RFC/PPP:
  Bei Abbestellung von Brettern, wurde BretterAnlegen ausgefÅhrt

  Revision 1.18  2000/06/17 12:35:13  MH
  RFC/PPP: Falschmeldung bei Brettmanager/Sonstiges korrigiert

  Revision 1.17  2000/06/15 16:49:17  MH
  RFC/PPP: Der Dateiname der Newsliste wird nun aus der Datenbank gelesen

  Revision 1.16  2000/06/07 20:20:47  MH
  RFC/PPP: Meldungen ins Resourcenfile uebertragen

  Revision 1.15  2000/06/06 20:28:20  MH
  RFC/PPP: Fix: Beim NewsSteuerfile '!' kam eine Fehlermeldung, Brett wurde trotzdem angelegt

  Revision 1.14  2000/06/05 16:13:43  MH
  RFC/PPP: BugFix: Nicht markiertes einzelnes Brett wurde nicht abbestellt

  Revision 1.13  2000/06/05 15:28:48  MH
  RFC/PPP: BugFix: Datenbankfehler bei anfordern einer neuen Liste

  Revision 1.12  2000/06/05 14:41:49  MH
  RFC/PPP: BugFix: Artikelanzahl wurde nicht immer korekt eingelesen

  Revision 1.11  2000/06/05 13:34:39  MH
  RFC/PPP: Bei Liste anfordern wird zur Aktuallisierung BOX.BL gelˆscht

  Revision 1.10  2000/06/05 09:03:57  MH
  RFC/PPP: Anzahl der Artikel kann nun selbst bestimmt werden

  Revision 1.9  2000/06/05 07:12:46  MH
  RFC/PPP: Zum abbestellen wird nun das RC-File herangezogen

  Revision 1.8  2000/06/05 06:52:42  MH
  RFC/PPP: Kleiner BugFix...

  Revision 1.7  2000/06/04 15:08:20  MH
  RFC/PPP: Fix: Bug Zaehlroutine beseitigt

  Revision 1.6  2000/06/04 13:38:37  MH
  RFC/PPP: Code aufgeraeumt

  Revision 1.5  2000/06/04 04:23:18  MH
  RFC/PPP: Erste Versuche des Brettmanagers

  Revision 1.4  2000/04/09 18:28:08  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.7  2000/03/14 15:15:41  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.6  2000/02/21 22:48:01  mk
  MK: * Code weiter gesaeubert

  Revision 1.5  2000/02/19 11:40:08  mk
  Code aufgeraeumt und z.T. portiert

}
