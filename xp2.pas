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
{ $Id: xp2.pas,v 1.67 2001/12/27 14:48:55 MH Exp $ }

{ CrossPoint - StartUp }

{$I XPDEFINE.INC}
{$IFDEF BP }
  {$O+,F+}
{$ENDIF }

unit xp2;

interface

uses xpglobal,{$IFDEF virtualpascal}sysutils,{$endif}
     crt,dos,dosx,typeform,fileio,keys,inout,winxp,mouse,datadef,database,
     databaso,maske,video,help,printerx,lister,win2,maus2,crc16,clip,
     resource,montage,
     xp0,xp1,xp1o2,xp1input,xp1help,xp5,xpdatum;


procedure zusatz_menue;
procedure setaltfkeys;

procedure defaultcolors;
procedure readcolors(fn:string);
procedure setcolors;
procedure GetResdata;
procedure FreeResdata;
procedure loadresource;
procedure setmenus;
procedure freemenus;

procedure initvar;
procedure SetNtAllowed;
procedure readconfig;
procedure saveconfig;
procedure SaveConfig2;
procedure cfgsave;       { mit Fenster }
procedure GlobalModified;
function  AskSave:boolean;
procedure read_regkey;   { registriert? }
procedure ChangeTboxSn;  { alte IST-BOX-Seriennr -> Config-File }
procedure test_pfade;
procedure test_defaultbox;
procedure test_defaultgruppen;
procedure test_systeme;
procedure testdiskspace;
procedure testcfg;  { CFG-File bei Updates kompatible machen }
procedure convbfg;  { BFG-Files konvertieren }
{$IFDEF BP }
procedure testfilehandles;
{$ENDIF }
procedure DelTmpfiles(fn:string);
procedure TestAutostart;
procedure check_date;
procedure check_tz;
procedure ReadDomainlist;
procedure testlock;
procedure ReadDefaultViewers;

procedure ShowDateZaehler;


implementation  {-----------------------------------------------------}

 uses xp1o,xpe,xp2c,xp3,xp3o,xp9bp,xp9,xpnt,xpfido,xpkeys,xpreg,xpcrc32;

var   zaehlx,zaehly : byte;


procedure setmenu(nr:byte; s:string);
begin
  getmem(menu[nr],length(s)+1);
  menu[nr]^:=s;
end;

procedure zusatz_menue;         { Zusatz-MenÅ neu aufbauen }
var s    : string;
    i,ml : byte;
    n    : byte;
begin
  freemem(menu[2],length(menu[2]^)+1);
  freemem(menu[menus],length(menu[menus]^)+1);
  s:=''; ml:=14;
  n:=0;

  for i:=1 to 10 do                                  { Zusatzmenue 1-10 }
    with fkeys[0]^[i] do
      if menue<>'' then begin
        s:=s+','+hex(i+$24,3)+menue;
        ml:=max(ml,length(menue)-iif(cpos('^',menue)>0,3,2));
        inc(n);
        end;
  if s<>'' then s:=',-'+s;
  s:='Zusatz,'+forms(getres2(10,100),ml+4)+'@K,'+getres2(10,101)+s;
  getmem(menu[2],length(s)+1);
  menu[2]^:=s;

  s:='';
  for i:=1 to iif(screenlines=25,9,10) do             { Zusatzmenue 11-20 }
    with fkeys[4]^[i] do
      if menue<>'' then begin
        s:=s+','+hex(i+$24,3)+menue;
        ml:=max(ml,length(menue)-iif(cpos('^',menue)>0,3,2));
        inc(n);
        end;
  getmem(menu[menus],length(s)+1);
  menu[menus]^:=s;
end;


procedure setmenus;
var i : integer;
begin
  for i:=0 to menus do
    if (i<>11) then setmenu(i,getres2(10,i));
  zusatz_menue;
  case videotype of
    0,1 : setmenu(11,'Zeilen,0b125');
    2   : setmenu(11,'Zeilen,0b125,0b226,0b329,0b431,0b535,0b638,0b743,0b850');
    3   : setmenu(11,'Zeilen,0b125,0b226,0b328,0b430,0b533,0b636,0b740,0b844,0b950');
    4   : setmenu(11,'Zeilen,0b125,0b243,0b350');
  end;
  FreeRes;
end;


procedure freemenus;
var i : integer;
begin
  for i:=0 to menus do
    freemem(menu[i],length(menu[i]^)+1);
end;


procedure readmenudat;   { Liste der unsichtbaren MenÅpunkte einlesen }
var f       : file;
    version : integer;
    i,j,w   : integer;
begin
  anzhidden:=0;
  if ParMenu then exit;
{$IFDEF Debug }
  dbLog('-- MenÅdatei einlesen');
{$ENDIF }
  assign(f,menufile);
  if existf(f) then begin
    reset(f,1);
    blockread(f,version,2);
    if version=1 then begin
      blockread(f,anzhidden,2);
      anzhidden:=minmax(anzhidden,0,min(maxhidden,filesize(f) div 2 - 2));
      if anzhidden>0 then begin
        getmem(hidden,2*anzhidden);
        blockread(f,hidden^,2*anzhidden);
        end;
      end;
    close(f);
    end;
  if anzhidden>0 then             { zur Sicherheit nochmal sortieren... }
    for i:=anzhidden downto 2 do
      for j:=1 to i-1 do
        if hidden^[j]>hidden^[j+1] then begin
          w:=hidden^[j];
          hidden^[j]:=hidden^[j+1];
          hidden^[j+1]:=w;
          end;
end;

procedure VersionScreen;

begin
        CloseResource;
        runerror:=false;
        halt;
end; {VersionScreen}

procedure HelpScreen;
var n,i     : integer;
    t       : taste;
    sclines : byte;
begin
  DosOutput;
  iomaus:=false;
  n:=res2anz(202);
  writeln;
  sclines:=getscreenlines;
  for i:=1 to n do begin
    writeln(getres2(202,i));
    if (i+5) mod (sclines-1)=0 then
      if not outputredirected then begin
        write(getres(12));
        get(t,curon);
        write(#13,sp(30),#13);
        end;
    end;
  CloseResource;
  runerror:=false;
  halt;
end;



procedure GetResdata;
const intbrett = '$/Ø';
var s : string;
    p : byte;
    i : integer;

  procedure getkey(var c:char);
  begin
    if p<=length(s) then begin
      if s[p]='^' then begin
        inc(p);
        c:=chr(ord(s[p])-64);
        end
      else
        c:=s[p];
      inc(p,2);
      end;
  end;

begin
  helpfile:=getres(1);
  keydeffile:=getres(2);
  _fehler_:=getres2(11,1);
  _hinweis_:=getres2(11,2);
  _daylen_:=ival(getres2(11,3));
  s:=getres2(11,4);
  getmem(_days_,length(s)+1);
  _days_^:=s;
  statbrett:=intbrett+getres2(11,5);
  unvbrett:=intbrett+getres2(11,6);
  netbrett:=intbrett+getres2(11,7);
  _jn_:=getres2(11,8);
  masklanguage(_jn_);
  _wotag_:=getres2(11,9);
  for i:=1 to 12 do
    monat[i].tag:=getres2(11,i+9);
  ListHelpStr:=getres2(11,22);
  freeres;
  if IsRes(22) then begin     { Tastendefinitionen }
    s:=getres2(22,1);         { Bretter }
    p:=1;
    getkey(k0_S);  getkey(k0_A);  getkey(k0_H);  getkey(k0_cH);
    getkey(k0_L);  getkey(k0_E);  getkey(k0_V);  getkey(k0_cT);
    getkey(k0_P);  getkey(k0_Le); getkey(k0_B);  getkey(k0_I);
    getkey(k0_TE); getkey(k0_cG); getkey(k0_cE); getkey(k0_cW);
    getkey(k0_cF); getkey(k0_Ac); getkey(k0_SB); getkey(k0_RH);
    s:=getres2(22,2);          { User }
    p:=1;
    getkey(k1_S);  getkey(k1_A);  getkey(k1_H);  getkey(k1_V);
    getkey(k1_L);  getkey(k1_E);  getkey(k1_cV); getkey(k1_B);
    getkey(k1_I);  getkey(k1_TE); getkey(k1_R);  getkey(k1_P);
    getkey(k1_cE); getkey(k1_cW); getkey(k1_U);  getkey(k1_SB);
    s:=getres2(22,3);          { Nachrichten }
    p:=1;
    getkey(k2_S);  getkey(k2_cR); getkey(k2_cH); getkey(k2_I);
    getkey(k2_O);  getkey(k2_H);  getkey(k2_L);  getkey(k2_K);
    getkey(k2_cU); getkey(k2_V);  getkey(k2_cE); getkey(k2_U);
    getkey(k2_cF); getkey(k2_cI); getkey(k2_G);  getkey(k2_cA);
    getkey(k2_KA); getkey(k2_EA); getkey(k2_cW); getkey(k2_cS);
    getkey(k2_cD); getkey(k2_cN); getkey(k2_BB); getkey(k2_A);
    getkey(k2_b);  getkey(k2_cB); getkey(k2_SB); getkey(k2_p);
    getkey(k2_cP); getkey(k2_SP); getkey(k2_cT); getkey(k2_cQ);
    getkey(k2_R);  getkey(k2_SR);
    s:=getres2(22,4);          { AutoVersand }
    p:=1;
    getkey(k3_H);  getkey(k3_E);  getkey(k3_L);  getkey(k3_A);
    getkey(k3_T);  getkey(k3_I);  getkey(k3_S);  getkey(k3_K);
    s:=getres2(22,5);          { Lister }
    p:=1;
    getkey(k4_D);  getkey(k4_W);  getkey(k4_L);  getkey(k4_cL);
    getkey(k4_H);  getkey(k4_F);
    freeres;
    end;
end;

procedure FreeResdata;
begin
  freemem(_days_,length(_days_^)+1);
end;


procedure loadresource;             { Sprachmodul laden }
var lf : string[12];
    lf2: string[12];
    sr : searchrec;
    t  : text;
    s  : string[40];
    ca : char;

  procedure WrLf;
  begin
    rewrite(t);
    writeln(t,lf);
    close(t);
  end;
begin
  col.colmbox:=$70;
  col.colmboxrahmen:=$70;
  findfirst('XP-*.RES',DOS.Archive,sr);
  assign(t,'XP.RES');
  reset(t);
  if ioresult<>0 then
  begin                                        { Wenn XP.RES nicht existiert }
    if (parlanguage='') then                   { /L Parameter beruecksichtigen }
    if (doserror<>0) then parlanguage:='D' else
    begin
      parlanguage:=sr.name[4];
      write ('<D>eutsch / <E>nglish ?  '+parlanguage);
      repeat
        ca:=upcase(readkey);                              { Und ansonsten Auswahl-Bringen }
      until (ca='D') or (ca='E') or (ca=keycr);
      if (ca<>keycr) then parlanguage:=ca;                { Enter=Default }
      writeln;
    end;
    lf:='XP-'+parlanguage+'.RES';
    WrLf;                                                 { und XP.RES erstellen }
  end
  else begin
    readln(t,lf);
    close(t);
    if (ParLanguage<>'') then begin
      lf2:='XP-'+ParLanguage+'.RES';
      if not exist(lf2) then writeln('language file '+ParLanguage+' not found')
      else if (ustr(lf)<>lf2) then begin
        lf:=lf2;
        WrLf;
      end;
    end;
  end;
  if doserror=0 then begin
    findnext(sr);
    languageopt:=(doserror=0);
  end
  else
    languageopt:=false;

  {$IFDEF Ver32 }
  FindClose(sr);
  {$ENDIF}
  if not exist(lf) then
    interr(lf+' not found');
  ParLanguage:=copy(lf,4,cpos('.',lf)-4);
  assign(t,lf);
  reset(t);
  readln(t); readln(t);
  readln(t,s);
  deutsch:=(lstr(s)='deutsch');
  close(t);
  OpenResource(lf,ResMinmem);
  if getres(6)<>LangVersion then begin
    if exist('xp.res') then _era('xp.res');
    interr(iifs(deutsch,'falsche Version von ','wrong version of ')+lf);
  end;
  GetResdata;
  if ParHelp then HelpScreen;
  if ParVersion then VersionScreen;
end;


{$I xp2cfg.inc}


procedure test_pfade;
var   res  : integer;

  procedure TestDir(d:dirstr);
  begin
    if not IsPath(ownpath+d) then begin
      mkdir(ownpath+left(d,length(d)-1));
      if ioresult<>0 then
        interr(reps(getres(203),left(d,length(d)-1))+#7);   { 'Fehler: Kann %s-Verzeichnis nicht anlegen!' }
      end;
  end;

  procedure TestDir2(d:dirstr);
  begin
    if not IsPath(d) then begin
      mkdir(left(d,length(d)-1));
      if ioresult<>0 then;
        {trfehler(reps(getres(203),left(d,length(d)-1))+#7);   { 'Fehler: Kann %s-Verzeichnis nicht anlegen!' }
      end;
  end;

  procedure SetPath(var pathp:pathptr; var oldpath:pathstr);
  begin
    getmem(pathp,length(oldpath)+1);
    pathp^:=oldpath;
    oldpath:=OwnPath;
  end;

begin
  TestDir2(logpath);     {MW 04/2000}
  TestDir2(temppath);    {MW 04/2000}
  TestDir2(extractpath); {MW 04/2000}
  TestDir2(sendpath);    {MW 04/2000}
  EditLogpath:=nil;
  if logpath='' then logpath:=ownpath
  else
    if not IsPath(logpath) then begin
      trfehler(204,errortimeout);  { 'ungÅltiges Logfileverzeichnis' }
       SetPath(EditLogpath,logpath);
      end;
  EditTemppath:=nil;
  if temppath='' then temppath:=ownpath
  else
    if not IsPath(temppath) then begin
      trfehler(201,errortimeout);   { 'ungÅltiges TemporÑr-Verzeichnis eingestellt' }
      SetPath(EditTemppath,temppath);
      end;
  EditExtpath:=nil;
  if extractpath='' then extractpath:=OwnPath
  else
    if not IsPath(extractpath) then begin
      trfehler(202,errortimeout);   { 'ungÅltiges Extrakt-Verzeichnis eingestellt' }
      SetPath(EditExtpath,extractpath);
      end;
  EditSendpath:=nil;
  if sendpath='' then sendpath:=ownpath
  else
    if not IsPath(sendpath) then begin
      trfehler(203,errortimeout);   { 'ungÅltiges Sendeverzeichnis' }
      SetPath(EditSendpath,sendpath);
      end;
  editname:=sendpath+'*.*';
  TestDir(XFerDir);
  TestDir(JanusDir);
  TestDir(FidoDir);
  TestDir(AutoxDir);
  TestDir(BadDir);
  if not IsPath(filepath) then begin
    MkLongdir(filepath,res);
    if res<>0 then begin
      filepath:=OwnPath+InfileDir;
      TestDir(InfileDir);
      end;
    end;
end;


{ Stammbox anlegen, falls noch nicht vorhanden }

procedure test_defaultbox;
var d    : DB;
    dname: string[8];
begin
{$IFDEF Debug }
  dbLog('-- Boxen ÅberprÅfen');
{$ENDIF }
  dbOpen(d,BoxenFile,1);
  dbSeek(d,boiName,ustr(DefaultBox));
  if not dbFound then begin
    if dbRecCount(d)=0 then begin
      xp9.get_first_box(d);
      dbRead(d,'dateiname',dname);
      end
    else begin
      dbGoTop(d);
      dbRead(d,'boxname',DefaultBox);
      dbRead(d,'dateiname',dname);
      end;
    SaveConfig;
    end
  else
    dbRead(d,'Dateiname',dname);
  if not exist(OwnPath+dname+BfgExt) then begin
    DefaultBoxPar(nt_Netcall,boxpar);
    WriteBox(dname,boxpar,nt_netcall);
    end;
  if deffidobox<>'' then begin
    dbSeek(d,boiName,deffidobox);
    if not dbFound then deffidobox:=''
    else HighlightName:=ustr(dbReadStr(d,'username'));
    if deffidobox<>'' then SetDefZoneNet;
    end;
  dbClose(d);
  if abgelaufen1 then rfehler(213);
end;


{ Testen, ob die 3 Default-Brettruppen vorhanden sind }

procedure test_defaultgruppen;
var d     : DB;

  procedure AppGruppe(name:string; limit:longint; halten:integer16;
                      var grnr:longint);
  const b : byte = 1;
  var   s : string[8];
  begin
    dbAppend(d);
    dbWrite(d,'name',name);
    dbWrite(d,'haltezeit',halten);
    dbWrite(d,'msglimit',limit);
    dbWrite(d,'flags',b);
    s:='header';   dbWrite(d,'kopf',s);
    s:='signatur'; dbWrite(d,'signatur',s);
    dbRead(d,'INT_NR',grnr);
  end;

  procedure getGrNr(name:string; var grnr:longint);
  begin
    dbSeek(d,giName,ustr(name));
    if not dbFound then interr(getres(204));  { 'fehlerhafte Gruppendatei!' }
    dbRead(d,'INT_NR',grnr);
  end;

(*  procedure WriteFido;
  var b : byte;
      s : string[8];
  begin
    b:=4;  dbWrite(d,'flags',b);     { Re^n = N }
    b:=1;  dbWrite(d,'umlaute',b);   { ASCII    }
    s:=''; dbWrite(d,'signatur',s);  { keine Sig. }
  end; *)

begin
{$IFDEF Debug }
  dbLog('-- Gruppen ÅberprÅfen');
{$ENDIF }
  dbOpen(d,GruppenFile,1);
  if dbEOF(d) then begin
    AppGruppe('Intern',0,0,IntGruppe);
    AppGruppe('Lokal',0,stdhaltezeit,LocGruppe);
    AppGruppe('Netz',maxnetmsgs,stdhaltezeit,NetzGruppe);
    { AppGruppe('Fido',8192,stdhaltezeit,dummy);
      WriteFido; }
    end
  else begin
    getGrNr('Intern',IntGruppe);
    getGrNr('Lokal',LocGruppe);
    getGrNr('Netz',NetzGruppe);
    end;
  dbCLose(d);
end;


procedure test_systeme;
var d : DB;
    s : string[30];
begin
{$IFDEF Debug }
  dbLog('-- Systeme ÅberprÅfen');
{$ENDIF }
  dbOpen(d,SystemFile,1);
  if dbRecCount(d)=0 then begin
    dbAppend(d);
    s:='SYSTEM';
    dbWrite(d,'name',s);
    end;
{ if abgelaufen2 then
    fillchar(registriert,sizeof(registriert)+1,0); }
  dbClose(d);
end;


procedure testdiskspace;
var free : longint;
    x,y  : byte;
begin
  if ParNomem then exit;
{$IFDEF Debug }
  dbLog('-- Plattenplatz testen');
{$ENDIF }
  free:=diskfree(0);                       { <0 bei Platten >2GB! }
  if (free>=0) and (free<200000) then begin
    exitscreen(0);
    writeln(getreps(205,left(OwnPath,2)));   { 'Fehler: zu wenig freier Speicher auf Laufwerk %s !' }
    writeln;
    errsound; errsound;
    closeresource;
    runerror:=false;
    halt(1);
    end
  else
    if (free>0) and (free div $100000<MinMB) then begin
      msgbox(51,8,'',x,y);
      moff;
      wrt(x+3,y+1,getres2(206,1));   { 'WARNUNG!' }
      wrt(x+3,y+3,reps(getres2(206,2),trim(strsrn(free/$100000,0,1))));
      wrt(x+3,y+4,reps(getres2(206,3),left(ownpath,2)));
      wrt(x+3,y+6,getres(12));   { 'Taste drÅcken ...' }
      freeres;
      mon;
      errsound; errsound;
      inout.cursor(curon);
      DisableDOS:=true;
      wkey(30,false);
      DisableDOS:=false;
      inout.cursor(curoff);
      closebox;
      end;
end;


{$IFDEF BP }
procedure testfilehandles;
var f,nf : byte;
begin
  abgelaufen1:=false; {(right(date,4)+copy(date,4,2)>reverse('104991')); }
  abgelaufen2:=false; { abgelaufen1; }
  f:=FreeFILES(30);   { 20 -> 30}
  if {(f>5) and} (f<16) then begin
    {nf:=((ConfigFILES+(16-f)+4) div 5) * 5);}
    nf:=(ConfigFILES+(26-f)+4);
    rfehler1(210,strs(nf));
    exitscreen(0);
    closeresource;
    runerror:=false;
    halt(1);
    end;
end;
{$ENDIF }


procedure read_regkey;
var t   : text;
    s   : string[20];
    p   : byte;
    l1,l2,l3 : integer32;
    l   : integer32;
    code: integer32;
    rp  : ^boolean;

begin
  regstr1:=''; regstr2:=''; registriert.nr:=0;
  registriert.komreg:=false;
  registriert.orgreg:=false;
  assign(t,regdat);
  if existf(t) then begin
    reset(t);
    readln(t,s);
    s:=trim(s);
    close(t);
    if firstchar(s)='!' then begin
      registriert.komreg:=true;
      registriert.orgreg:=true;
      delfirst(s);
      end;
    p:=cpos('-',s);
    if p>0 then begin
      if s[1] in ['A','B','C'] then begin
        registriert.tc:=s[1]; delete(s,1,1); dec(p);
        end
      else
        registriert.tc:='A';
      l:=ival(left(s,p-1));              { lfd. Nummer }
      if ((l>=4001) and (l<=4009)) or
         (l=800) or                      { Key in Cracker-Box aufgetaucht }
         (l=4088) or                     { Key auf CD-ROM aufgetaucht     }
         (l=4266) or (l=4333) or         { storniert                      }
         (l=8113) or                     { Key in CCC.GER verîffentlicht  }
         (l=6323) or                     { Key in Cracker-Kreisen aufgetaucht }
         (l=101) or                      { Key im Usenet aufgetaucht }
         (l=0) or (l=11232) or (l=12345) or (l=23435) or (l=32164) or
         (l=33110) or (l=34521) or (l=54321) or (l=12034) then   { Hacks }
        l:=0;
      registriert.nr:=l;
      rp:=@registriert;
      inc(longint(rp));
      l1:=CRC16strXP(reverse(hex(l+11,4))); l1:=l1 xor (l1 shl 4);

      { Registrierungsbug PlattformunabhÑnig emulieren }
      { 10923 * 3 ist grî·er als maxint (32767) }
      if l<10923 then
        l2:=CRC16strXP(reverse(hex(l*3,5)))
      else
        l2:=CRC16strXP(reverse(hex(l*3-65536,5)));

      l2:=l2 xor (l2*37);
      l3:=l1 xor l2 xor CRC16strXP(reverse(strs(l)));
      delete(s,1,p);
      p:=cpos('-',s); if p=0 then p:=length(s)+1;
      code:=ival(left(s,p-1));                { -Code }
      if registriert.nr=0 then code:=-1;
      delete(s,1,p);
      registriert.ppp:=false;
      case registriert.tc of
        'A' : begin
                rp^:=(code=l1);
                if rp^ then begin
                  registriert.non_uucp:=true;
                  registriert.ppp:=true;
                  regstr1:=' R';
                  end;
              end;
        'C' : begin
                rp^:=(code=l3);
                if rp^ then begin
                  registriert.uucp:=true; registriert.non_uucp:=true;
                  registriert.ppp:=true;
                  regstr1:=' R'; regstr2:=' R'; end;
              end;
        'B' : begin
                rp^:=(code=l2);
                if rp^ then begin
                  registriert.uucp:=true;
                  registriert.ppp:=true;
                  regstr2:=' R';
                  end;
              end;
      end;
      with registriert do begin
        komreg:=komreg and IsKomCode(nr);
        orgreg:=orgreg and IsOrgCode(nr);
        end;
      end;
    end;
end;


procedure ChangeTboxSN;
var d : DB;
begin
  if (registriert.nr>=5000) and (registriert.nr<=5999) then begin
    dbOpen(d,BoxenFile,0);
    while not dbEOF(d) do begin
      if dbReadInt(d,'netztyp')=nt_Turbo then begin
        ReadBox(nt_Turbo,dbReadStr(d,'dateiname'),BoxPar);
        boxpar^.seriennr:=registriert.nr;
        WriteBox(dbReadStr(d,'dateiname'),BoxPar,nt_turbo);
        end;
      dbNext(d);
      end;
    dbClose(d);
    fillchar(registriert,sizeof(registriert),0);
    _era(RegDat);
    end;
end;


procedure DelTmpfiles(fn:string);
var sr : searchrec;
begin
  findfirst(fn,DOS.Archive,sr);
  while doserror=0 do begin
    _era(sr.name);
    findnext(sr);
  end;
  {$IFDEF virtualpascal}
  FindClose(sr);
  {$ENDIF}
end;


procedure TestAutostart;
var p   : byte;
    f,t : string[5];
    min : word;
begin
  p:=cpos('-',ParAutost);
  if p=0 then exit;
  min:=ival(left(ParAutost,p-1));
  f:=formi(min div 100,2)+':'+formi(min mod 100,2)+':00';
  min:=ival(mid(ParAutost,p+1));
  t:=formi(min div 100,2)+':'+formi(min mod 100,2)+':59';
  if f<t then
    quit:=quit or (time<f) or (time>t)
  else
    quit:=quit or ((f>time) and (t<time));
end;

procedure testcfg;  { CFG-File bei Updates kompatible machen }
const
  notdef : array[1..15] of string[17] =
  ('SHOWUNGELESEN','VIEWERSAVE','VIEWERVIRSCAN','VIEWERLISTER','DELVIEWTMP',
   'NEUUSERGRUPPE','ARCHIVVERMERK','USERSORTBOX','IGNORESUPCANCEL','MAXNETPM',
   'MAXLOCALPM','SAVEVGAPAL','XPOINT-TEARLINE','EIGENEPMSHALTEN','AUTODATUMSBEZUEGE');

var
  cfg,ourcfg : text;
  line       : string;
  strfound   : boolean;
  b          : byte;
begin
{.$I+}
  if exist(ownpath+cfgfile) then begin
    strfound:=false;
    assign(cfg,ownpath+cfgfile);
    reset(cfg);
    readln(cfg,line);
    if (pos('(XP2)'+cfgnr,line)<>0) then begin
      close(cfg);
      exit;
    end;
    assign(ourcfg,ownpath+TempFile(''));
    rewrite(ourcfg);
    writeln(ourcfg,'## ',getres2(214,1)+cfgnr);
    while not eof(cfg) do begin
      readln(cfg,line);
      for b:=1 to 15 do
      if pos(notdef[b],ustr(line))<>0 then begin
        strfound:=true;
        break;
      end;
      if (line<>'') and (pos('=',line)=0) and (pos('#',line)=0) then line:=line+'=';
      if not strfound and (pos(reverse('PXNEPO'),ustr(line))=0) then writeln(ourcfg,line);
      strfound:=false;
    end;
    close(cfg);
    flush(ourcfg);
    if not exist(ownpath+'xpoint.upd') then begin
    { 'Die Konfigurationsdatei XPOINT.CFG wird in XPOINT.UPD gesichert' }
      trfehler(222,30);
      rename(cfg,ownpath+'xpoint.upd');
    end else
    erase(cfg);
    close(ourcfg);
    rename(ourcfg,ownpath+cfgfile);
    InOutRes:=0;
    freeres;
  end;
{.$I-}
end;

procedure convbfg;
  const
    pstr : array[1..10] of string[16] =
           ('nntpreplaceown=','nntpposting=','nntplist=','nntprescan=',
            'smtpafterpop=','pop3useenvelope=','pop3keep=','pop3auth=',
            'smtpport=','pop3port=');
  notdef : array[1..9] of string[12] =
  ('uu-smtp-ppp','client-mode','client-exec','client-spool','client-path',
   'uu-mode','uu-port','nntp-port','pop3clear');
  var
    b,b1     : byte;
    strfound : boolean;
    closeup  : boolean;
    t1,t2    : text;
    dir      : DirStr;
    bname    : NameStr;
    ext      : ExtStr;
    sr       : searchrec;
    s,s1     : string;

  procedure box2bfg;
  var
    d       : db;
    i,anz,p : byte;
    boxp    : string;
    blist   : array[0..10] of string;
  begin
    anz:=1;  s:=trim(s);
    for i:=1 to length(s) do
      if s[i]=' ' then
        inc(anz);
    blist[0]:=s;
    for i:=1 to anz do begin
      p:=blankpos(blist[0]);
      if p=0 then p:=length(blist[0])+1;
      if p>=3 then begin
        blist[i]:=left(blist[0],p-1);
        blist[0]:=trim(mid(blist[0],p));
      end;
    end;
    dbOpen(d,BoxenFile,1);
    boxp:='PPP_BoxPakete=';
    for i:=1 to anz do begin
      dbSeek(d,boiname,ustr(blist[i]));
      if dbFound then
        boxp:=boxp+dbReadStr(d,'dateiname')+' ';
    end;
    dellast(boxp);
    s:=boxp;
    dbClose(d);
  end;

begin
{.$I+}
  findfirst(OwnPath+'*'+BfgExt,dos.archive,sr); b1:=1;
  while doserror=0 do begin
    fsplit(sr.name,dir,bname,ext);
    assign(t1,OwnPath+bname+BfgExt);
    reset(t1);
    readln(t1,s);
    closeup:=true;
    if s<>bfgver+bfgnr then begin
      if b1=1 then writeln('Konvertiere Boxen-Konfiguration! Bitte warten...');
      assign(t2,TempPath+'CONVERT'+BfgExt);
      rewrite(t2);
      writeln(t2,bfgver+bfgnr);
      if pos(bfgver,s)=0 then reset(t1);
      repeat
        readln(t1,s);
        strfound:=false;
        s:=trim(s);
        if (s<>'') and (pos('=',s)=0) and (pos('#',s)=0) then s:=s+'=';
        s1:=s; inc(b1);
        s:=lstr(s);
        if pos('ppp_boxpakete',s)<>0 then begin
          s:=mid(s,pos('=',s)+1);
          if length(s)<>0 then begin
            box2bfg;
            writeln(t2,s);
            strfound:=true;
          end
        end else
        for b:=1 to 10 do
          if (pos(pstr[b],s)<>0) {$IFnDEF ToBeOrNotToBe} or (left(s,4)='tcp_') {$ENDIF} then begin
          strfound:=true;
          s:=left(s,blankposx(s)-1);
        {$IFnDEF ToBeOrNotToBe}
          if left(s,4)='tcp_' then break else
        {$ENDIF}
          if (pos('smtpport=',s)<>0) then writeln(t2,left(s1,blankposx(s1)-1)) else
          if (pos('pop3port=',s)<>0) then writeln(t2,left(s1,blankposx(s1)-1)) else
          if s='nntpposting=enabled' then writeln(t2,'NntpPosting=J') else
          if s='nntpposting=disabled' then writeln(t2,'NntpPosting=N') else
          if s='nntpreplaceown=enabled' then writeln(t2,'ReplaceOwn=J') else
          if s='nntpreplaceown=disabled' then writeln(t2,'ReplaceOwn=N') else
          if s='nntprescan=enabled' then writeln(t2,'NntpRescan=J') else
          if s='nntprescan=disabled' then writeln(t2,'NntpRescan=N') else
          if s='nntplist=enabled' then writeln(t2,'NntpList=J') else
          if s='nntplist=disabled' then writeln(t2,'NntpList=N') else
          if s='smtpafterpop=enabled' then writeln(t2,'SmtpAfterPop=J') else
          if s='smtpafterpop=disabled' then writeln(t2,'SmtpAfterPop=N') else
          if s='pop3keep=enabled' then writeln(t2,'Pop3Keep=J') else
          if s='pop3keep=disabled' then writeln(t2,'Pop3Keep=N') else
          if s='pop3useenvelope=enabled' then writeln(t2,'Pop3UseEnvelope=J') else
          if s='pop3useenvelope=disabled' then writeln(t2,'Pop3UseEnvelope=N') else
          if s='pop3auth=enabled' then writeln(t2,'Pop3Auth=J') else
          if s='pop3auth=disabled' then writeln(t2,'Pop3Auth=N') else
          writeln(t2,s1);
          break;
        end else
        if (left(s,4)='smtp') or (left(s,4)='pop3') then
          s1:=left(s1,blankposx(s1)-1);
        for b:=1 to 9 do
        if pos(notdef[b],s)<>0 then begin
          strfound:=true;
          break;
        end;
        if not strfound then writeln(t2,s1);
      until eof(t1);
      closeup:=false;
      close(t1);
      flush(t2);
      close(t2);
      copyfile(OwnPath+bname+BfgExt,OwnPath+bname+'.BAK');
      erase(t1);
      copyfile(TempPath+'CONVERT'+BfgExt,OwnPath+bname+BfgExt);
      erase(t2);
    end;
    if closeup then close(t1);
    findnext(sr);
  end;
  {$IFDEF ver32}
  FindClose(sr);
  {$ENDIF}
{.$I-}
end;

procedure ShowDateZaehler;
const lastdz : integer = -1;
begin
  if zaehler[1]<>lastdz then begin
    savecursor;
    lastdz:=zaehler[1];
    attrtxt(col.coldiarahmen);
    wrt(zaehlx,zaehly,' '+strsn(lastdz,2)+' ');
    restcursor;
    if lastdz=0 then keyboard(KeyEsc);
    end;
end;

procedure check_date;      { Test, ob Systemdatum verstellt wurde }
const maxdays = 14;
var dt   : DateTime;
    days : longint;
    dow  : rtlword;
    ddiff: longint;
    wdt  : byte;
    x,y  : byte;
    brk  : boolean;
    dat  : datetimest;
    t,m,j: word;
    m3s  : procedure;
begin
  fillchar(dt,sizeof(dt),0);
  getdate(dt.year,dt.month,dt.day,dow);
  days:=longint(dt.year)*365+dt.month*30+dt.day;
  unpacktime(filetime(NewDateFile),dt);                  { Abstand in Tagen }
  ddiff:=days - (longint(dt.year)*365+dt.month*30+dt.day);
  if (ddiff<0) or (ddiff>maxdays) then begin
    wdt:=4+max(max(length(getres2(225,1)),length(getres2(225,2))),
                   length(getres2(225,3))+10);
    dialog(wdt,5,'',x,y);
    if ddiff>0 then
      { 'Seit dem letzten Programmstart sind mehr als %s Tage vergangen.' }
      maddtext(3,2,getreps2(225,1,strs(maxdays)),0)
    else
      { 'Das Systemdatum liegt vor dem Datum des letzten Programmstarts.' }
      maddtext(3,2,getreps2(225,2,strs(maxdays)),0);
    dat:=left(date,6)+right(date,2);
    madddate(3,4,getres2(225,3),dat,false,false);   { 'Bitte bestÑtigen Sie das Datum: ' }
      mhnr(92);
    zaehler[1]:=30; zaehlx:=x+wdt-6; zaehly:=y-1;
    m3s:=multi3;
    multi3:=ShowDateZaehler; hotkeys:=false;
    readmask(brk);
    multi3:=m3s; hotkeys:=true;
    if not brk and mmodified then begin
      t:=ival(left(dat,2));
      m:=ival(copy(dat,4,2));
      j:=ival(right(dat,2));
      if j<80 then inc(j,2000) else inc(j,1900);
      setdate(j,m,t);
      end;
    enddialog;
    end;
end;

procedure check_tz; { Test, ob TZ-Umgebungsvariable richtig gesetzt }
var tz:string[7];
begin
  if (timezone='AUTO') and not getTZ(tz) then hinweis(getres(226));
end;

procedure ReadDomainlist;
var d   : DB;
    p   : DomainNodeP;
    dom : string[120];

  function smaller(dl:DomainNodeP):boolean;
  begin
    smaller:=(dom<dl^.domain^);
  end;

  procedure InsertIntoList(var dl:DomainNodeP);
  begin
    if dl=nil then
      dl:=p
    else
      if smaller(dl) then
        InsertIntoList(dl^.left)
      else
        InsertIntoList(dl^.right);
  end;

  procedure FreeDomainList(var DomainList:DomainNodeP);
  var lauf : DomainNodeP;   { Damit eine Umstellung in EditBox }
  begin                     { sofort Wirkung zeigt             }
    if Assigned(Domainlist) then begin
      FreeDomainList(DomainList^.left);
      lauf:=DomainList^.right;
      Dispose(DomainList);
      FreeDomainList(lauf);
    end;
  end;

begin
  FreeDomainList(DomainList);
  DomainList:=nil;
  dbOpen(d,BoxenFile,0);
  while not dbEOF(d) do
  begin
    inc(ntused[dbReadInt(d,'netztyp')]);
    if ntDomainReply(dbReadInt(d,'netztyp')) then
    begin
      new(p);
      dom:=lstr(dbReadStr(d,'fqdn'));
      if dom='' then
        begin
          if (dbReadInt(d,'netztyp') in [nt_UUCP,nt_PPP]) then
            dom := lstr(dbReadStr(d,'pointname')+dbReadStr(d,'domain'))
          else
            dom := lstr(dbReadStr(d,'pointname')+'.'+dbReadStr(d,'boxname')+
                   dbReadStr(d,'domain'));
        end;
      getmem(p^.domain,length(dom)+1);
      p^.domain^:=dom;
      p^.left:=nil;
      p^.right:=nil;
      insertintolist(DomainList);
    end;
    dbNext(d);
  end;
  dbClose(d);
  if reg_hinweis and (ParTiming=0) and (ParAutost='') then
    copyright(true);
end;


procedure testlock;
var i : integer;
begin
  if ParNolock then exit;
  assign(lockfile, 'lockfile');
  filemode:=FMRW + FMDenyWrite;
  rewrite(lockfile);
  if (ioresult<>0) or not fileio.lockfile(lockfile) then
  begin
    writeln;
    for i:=1 to res2anz(244) do
      writeln(getres2(244,i));
    mdelay(1000);
    close(lockfile);
    if ioresult<>0 then;
    closeresource;
    runerror:=false;
    halt(1);
  end;
  lockopen:=true;
  { MK 09.01.00: Bugfix fÅr Mime-Lîschen-Problem von Heiko.Schoenfeld@gmx.de }
  FileMode := FMRW;
end;


procedure ReadDefaultViewers;

  procedure SeekViewer(mimetyp:string; var viewer:pviewer);
  var prog : string[ViewprogLen];
  begin
    dbSeek(mimebase,mtiTyp,ustr(mimetyp));
    if not dbEOF(mimebase) and not dbBOF(mimebase) and
       stricmp(dbReadStr(mimebase,'typ'),mimetyp) then begin
      dbReadN(mimebase,mimeb_programm,prog);
      getmem(viewer,length(prog)+1);   { auch bei prog=''! }
      viewer^:=prog;
      end
    else
      viewer:=nil;
  end;

begin
  SeekViewer('*/*',DefaultViewer);
  SeekViewer('text/*',DefTextViewer);
  SeekViewer('text/plain',PTextViewer);
end;


end.
{
  $Log: xp2.pas,v $
  Revision 1.67  2001/12/27 14:48:55  MH
  - Auf die Variable ErrorTimeout kann an dieser Stelle nicht
    sinnvoll zugegriffen werden

  Revision 1.66  2001/12/26 19:45:07  MH
  - RFC/PPP: BFG-Komponenten konvertieren - Backupfiles anlegen

  Revision 1.65  2001/12/26 19:26:23  MH
  - RFC/PPP: Weitere BFG-Komponenten konvertieren (Korrektur)

  Revision 1.64  2001/12/26 19:13:24  MH
  - RFC/PPP: Weitere BFG-Komponenten konvertieren (Korrektur)

  Revision 1.63  2001/12/26 19:05:35  MH
  - RFC/PPP: Weitere BFG-Komponenten konvertieren

  Revision 1.62  2001/12/26 18:58:09  MH
  - RFC/PPP: Weitere BFG-Komponenten konvertieren

  Revision 1.61  2001/12/26 17:58:32  MH
  - RFC/PPP: TCP_?????? Parameter aus BFG entfernen - geaenderte konvertieren

  Revision 1.60  2001/08/20 16:16:02  MH
  - Letzter co: Sicherheitshalber string trimmen

  Revision 1.59  2001/08/20 16:11:20  MH
  - Konvertierung fÅr PPP_BoxPakete: BOX2BFG!

  Revision 1.58  2001/07/28 07:52:25  MH
  - Taste 'Ne^w' (englisch) im Specialmode wieder hergestellt

  Revision 1.57  2001/07/25 19:55:09  mm
  no message

  Revision 1.56  2001/07/25 19:53:07  mm
  - in Win32-Version erst mal nur die ConsolenModes auswaehlbar
    welche wirklich sauber funktionieren (auch im Fullscreen): 80*25/43/50

  Revision 1.55  2001/07/22 12:06:25  MH
  - FindFirst-Attribute ge‰ndert: 0 <--> DOS.Archive

  Revision 1.54  2001/06/29 15:55:43  MH
  - AutoDatumsBezuege entfernt

  Revision 1.53  2001/06/26 15:02:06  MH
  - Resourcen bei Fehler entladen

  Revision 1.52  2001/06/19 21:15:27  mm
  Zusatzmenue auf 20 erweitert (von Jochen Gehring)

  Revision 1.51  2001/06/18 20:17:25  oh
  Teames -> Teams

  Revision 1.50  2001/06/18 07:45:23  MH
  -.-

  Revision 1.49  2001/06/18 07:09:00  MH
  - FileHandleCheck korrigiert
    (konnte natÅrlich nicht funktionieren: Keine Meldung erschienen)

  Revision 1.48  2001/04/04 19:57:01  oh
  -Timeouts konfigurierbar

  Revision 1.47  2001/03/22 16:54:53  oh
  - lockfile wieder nach \xp\ geschoben ;)

  Revision 1.46  2001/03/22 09:28:38  oh
  - Farbprofile werden erst in colors\ gesucht, dann im XP-Verzeichnis

  Revision 1.43  2001/03/04 12:36:44  MH
  - Fix: HDO-Reverse klappte in der englischen Version nicht

  Revision 1.42  2001/02/04 15:16:37  MH
  -.-

  Revision 1.41  2001/02/04 15:02:20  MH
  - Bei der Konvertierung auf das '=' - Zeichen prÅfen und ggfs. ergÑnzen

  Revision 1.40  2001/02/04 14:25:50  MH
  - BFG-Konvertierung ergÑnzt

  Revision 1.39  2001/02/03 20:56:50  MH
  -.-

  Revision 1.38  2001/02/02 22:09:01  MH
  -.-

  Revision 1.37  2001/01/31 20:53:22  MH
  XPOINT.CFG-Konvertierung:
  - OXP-String entfernen

  Revision 1.36  2001/01/30 21:31:44  MH
  XPOINT.CFG:
  - weitere Keywords updaten

  Revision 1.35  2001/01/30 15:48:45  MH
  XPOINT.CFG:
  - XP2-Header bei Konvertierung setzen

  Revision 1.34  2001/01/08 16:44:33  MH
  Fixes fÅr FQDN:
  - Es wurde dann die eigene Nachricht nicht erkannt und
    hervorgehoben, wenn sich Gro·buchstaben darin befanden

  Revision 1.33  2000/12/30 12:26:52  MH
  Fix:
  - ParLanguage Auswahl, wenn keine XP-*.RES-Dateien vorhanden sind

  Revision 1.32  2000/11/02 23:52:26  rb
  Automatische Sommer-/Winterzeitumstellung bei korrekt gesetzter
  TZ-Umgebungsvariable

  Revision 1.31  2000/10/30 18:15:02  MH
  Optimierung der Box-Konvertierung

  Revision 1.30  2000/10/27 21:55:41  MH
  Konvertierung der BFGs verlagert

  Revision 1.29  2000/09/24 00:42:06  MH
  Requester nun auf R-Taste (deutsch) und G-Taste (englisch)

  Revision 1.28  2000/09/21 21:59:29  rb
  Codeteile ausgelagert

  Revision 1.27  2000/08/13 07:49:13  MH
  MailtTo: Subject wird nun vollstÑndig Åbergeben

  Revision 1.26  2000/08/11 15:05:52  MH
  Parameter 'mailto:' startet CrossPoint in 'Nachrichten/Direkt'
  und Åbergibt den EmpfÑnger

  Revision 1.25  2000/08/08 08:59:32  MH
  Reg-Hinweis-Anzeige wieder hergestellt

  Revision 1.24  2000/08/02 16:03:04  MH
  *** empty log message ***

  Revision 1.23  2000/07/15 14:23:13  MH
  FILES hochgesetzt

  Revision 1.22  2000/07/10 13:51:37  MH
  UpdateRoutine:
  - Um die Variabeln fÅr PM-Limts erweitert

  Revision 1.21  2000/07/09 17:16:49  MH
  Updateroutine erstellt nun beim ersten Start eine Sicherheitskopie
  von XPOINT.CFG und gibt zuvor eine Meldung aus

  Revision 1.20  2000/07/08 15:43:13  MH
  Updateroutine:
  - Fragt nun das Konfigurationsfile ab, ob es vom XP2-Team stammt

  Revision 1.19  2000/07/08 10:24:35  MH
  - Updateroutine erstellt

  Revision 1.18  2000/07/02 22:02:25  MH
  Test_Pfade: TestDir2 wieder aktiviert

  Revision 1.17  2000/06/29 20:44:22  tj
  Sourceheader aktualisiert

  Revision 1.16  2000/06/29 20:38:06  tj
  Parameter /version zugefuegt

  Revision 1.15  2000/06/29 18:35:02  MH
  Test_Pfade: Unsinnige Routine 'TestDir2' erst mal ausgeklammert...

  Revision 1.14  2000/06/22 03:47:05  rb
  Haltezeit-Bug bei ver32 gefixt

  Revision 1.13  2000/06/13 18:52:20  tg
  Config-Optionen-Sprache wieder aktiviert


  Revision 1.12  2000/06/06 07:59:34  MH
  RFC/PPP: Weitere Anpassungen und Fixes

  Revision 1.11  2000/05/17 17:40:44  MH
  Fix: RFC/PPP: Sourcen-Uebertragungsfehler beseitigt

  Revision 1.10  2000/05/17 17:27:00  MH
  Neuer Boxentyp: RFC/PPP

  Revision 1.9  2000/05/11 22:37:17  rb
  Rechenzeitfreigabe default fÅr die 32 Bit Version

  Revision 1.8  2000/05/02 17:23:08  MH
  Damit eine Aenderung in EditBox hinsichtlich MID sofort Wirkung zeigt

  Revision 1.7  2000/05/01 12:03:05  MH
  BugFix: [ReadDomainList] Wird FQDN verwendet, wird auch nur diese hervorgehoben

  Revision 1.6  2000/04/10 22:13:08  rb
  Code aufgerÑumt

  Revision 1.5  2000/04/10 01:27:54  oh
  - Update auf aktuellen OpenXP-Stand

  Revision 1.24  2000/04/08 13:33:14  mk
  MW: Defaultwerte angepasst und aktualisiert

  Revision 1.23  2000/04/04 21:01:23  mk
  - Bugfixes f¸r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.22  2000/04/04 10:33:56  mk
  - Compilierbar mit Virtual Pascal 2.0

  Revision 1.21  2000/03/16 19:25:10  mk
  - fileio.lock/unlock nach Win32 portiert
  - Bug in unlockfile behoben

  Revision 1.20  2000/03/14 15:15:38  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.19  2000/03/10 13:29:33  mk
  Fix: Registrierung wird sauber erkannt

  Revision 1.18  2000/03/09 23:39:33  mk
  - Portierung: 32 Bit Version laeuft fast vollstaendig

  Revision 1.17  2000/03/07 23:41:07  mk
  Komplett neue 32 Bit Windows Screenroutinen und Bugfixes

  Revision 1.16  2000/03/04 15:54:43  mk
  Funktion zur DOSEmu-Erkennung gefixt

  Revision 1.15  2000/03/03 21:12:49  jg
  - Config-Optionen-Sprache ausgeklammert
  - Sprachabfrage bei allererstem Start eingebaut

  Revision 1.14  2000/03/02 18:32:24  mk
  - Code ein wenig aufgeraeumt

  Revision 1.13  2000/03/02 00:17:23  rb
  Hilfe bei XP /? fÅr Rechenzeitfreigabe Åberarbeitet

  Revision 1.12  2000/03/01 23:49:02  rb
  Rechenzeitfreigabe komplett Åberarbeitet

  Revision 1.11  2000/02/29 17:55:42  mk
  - /nb wird jetzt in Release-Versionen ignoriert

  Revision 1.10  2000/02/28 08:57:05  mk
  - Version auf 3.20 RC1 geandert

  Revision 1.9  2000/02/27 22:30:10  mk
  - Kleinere Aenderung zum Sprachenwechseln-Bug (2)

  Revision 1.8  2000/02/19 14:59:36  jg
  Parameter /w0 hat keine wirkung mehr, wenn /osx definiert ist.

  Revision 1.6  2000/02/19 11:40:08  mk
  Code aufgeraeumt und z.T. portiert

  Revision 1.5  2000/02/18 17:28:08  mk
  AF: Kommandozeilenoption Dupekill hinzugefuegt

}
