{******************************************************************************
                         E C H O S T A T    V1.41

                        (c) Hilmar Buchta, April 1996

******************************************************************************}

{ $Id: echostat.pas,v 1.2 2001/01/22 19:31:27 MH Exp $ }

{.$G+,X+}
{$I XPDEFINE.INC}
{$M 32768,8192,655360}
{.$M 32768,8192,400000}

uses dos,crt,dialog;
{$I-,R-}


const
      daymonth:array[1..12] of integer=
       (31,28,31,30,31,30,31,31,30,31,30,31);
      rbuffersize=32000;
      compatible_version='v1.41';
      version='v1.41beta R11.XP2';
      teamstr='[Bugfixes  -->  (c) 2001 by XP2-Team (www.xp2.de)]';
      dummysize1=15;
      dummysize2=15;

type
   pstring=^string;
   tpuffer=array[0..64000] of byte;
   ppuffer=^tpuffer;

   pbrettinfo=^tbrettinfo;
   tbrettinfo=record
    s:pstring;
    int_nr,flags:longint;
    next:pbrettinfo;
    end;


   puser=^tuser;
   tuser=record
    name:pstring;
    mails,totalsize,quotesize:longint;
    next:puser;
    end;

   pbrett=^tbrett;
   tbrett=record
    name:pstring;
    mails,totalsize,quotesize:longint;
    next:pbrett;
    end;

   preceive=^treceive;
   treceive=record
    name:pstring;
    mails:longint;
    next:preceive;
    end;

   psubject=^tsubject;
   tsubject=record
    title:pstring;
    mails:longint;
    size:longint;
    next:psubject;
    end;

   tdatum=record
    day,month,year:word;
    end;

   tstatistik=record
    myname:string[50];
    date1,date2:tdatum;
    datemode:integer;
    {0: Endedatum z„hlt, 1:Startdatum+Woche, 2:Monatstatistik}
    dest:integer;
     {0: >>Statistik, 1: Brett destname, 2:Lister (Standardausgabe), 3:Datei}
    betrefftext:string[50]; { Fr Ausgabe in Brett }
    brettptr:integer;       { Anzahl Bretter -1    }
    with_bretter, with_sender, with_empf, with_graph,
    with_betreff,with_time,with_box,ibmchar,automode:boolean;
    dummy1:array[0..dummysize1] of boolean;
    destname,destbrett,destfile,header,footer:string[128];
    top_sender, top_empf, top_graph,top_betreff,top_box,top_bretter:longint;
    dummy2:array[0..dummysize2] of boolean;
    hierarchien:string;       { Durch Kommata getrennte Liste von Areas     }
    brettrealname:string[50]; { Falls <>'' wird dies als Brettliste gezeigt }
    mybretter:pstrlist;
    daydist:integer;
    mtime:array[0..24] of word;
    end;

    pstatlist=^tstatlist;
    tstatlist=record
     myname:string;
     ps:longint;
     size:word;
     next:pstatlist;
     end;


var
   totalfree:longint;       { Kompletter freier Speicher }
   user:puser;
   brett:pbrett;
   receive:preceive;
   subject:psubject;
   box:puser;
   userptr,receiveptr,subjptr,boxptr, brettptr:integer;


   xp_dir,xp_auto_dir,my_dir,my_dirtmp,my_dircfg:string;
   outp:text;


   strvalerror:boolean;
   failmsgs:longint;

   rbuffer:array[0..rbuffersize-1] of char;
   rbfill:word; rbpos:longint;
   f_in:file;
   endoffile,endoffile1:boolean;


   totalfilesize,readfilesize,starttime:longint;
   totalmsgs,foundmsgs:longint;
   msgsize:longint;

   mouse,interactive,newstatist:boolean;




{ Variablen fr das Fenster zum Aufbauen der Statistik }
   statdiag:pdialog;
   sd_tbar,sd_tfound,sd_ttotal,sd_trest,sd_tmsgs,sd_t:pstatictext;

   stat:tstatistik;         { Kenndaten der Statistik: Zeit, Ziel, etc   }
   bretterlist:pstrlist;    { Komplette Brettliste im passenden Format   }
                            { fr eine tlistbox                          }
   dialogstatus:integer;    { interne Variable, um die "Zurck"-Funktion }
                            { zu erkennen (siehe rundialog;)             }


{ Liste aller Statistiken in der .cfg-Datei }

  statlst:pstatlist;
  headersize:word;  { Gr”áe des Headers in der cfg-Datei }

  autostatrun:boolean;

  { Rechter Einzug fr Logfile }
  right_align:string;


{ Vorgabewerte der .ini-Datei }
  dateformat1, dateformat2:integer;  {0: tt.mm.jjjj, 1:tt.mm.jj, 2:tt.mm.}
  autostatcount:integer; { Anzahl Sekunden fr Autostatfrage }
(*  bretthierarchie:boolean;  { true: Hierarchie wird angezeigt, Voreinstll. }*)

procedure logmem(s:string;nlevel:integer);
begin
  if nlevel=-1 then
    if length(right_align)>=2 then right_align:=copy(right_align,1,length(right_align)-2);
  if debuglevel=1 then logwrite(right_align+ s+' ('+fstr(memavail)+', '+fstr(maxavail)+')');
  if nlevel=1 then right_align:=right_align+'  '
end;


procedure exitechostat(k:integer);
begin
  if mouse then
    hidemouse;
  cursorshape:=origshape; showcursor;
  right_align:='';
  logmem('app exit echostat',-1);
  if debuglevel>0 then closelogfile;
  halt(k);
end;


procedure txterror(s:string);
begin
  writeln;
  writeln('FEHLER:');
  writeln(s);
  writeln;
  if debuglevel>0 then begin
    logwrite('FEHLER:');
    logwrite(s);
  end;
  exitechostat(10);
end;



function heaperrorfunc(size:word):integer; far;
begin
  if size=0 then
    heaperrorfunc:=2
  else begin
    clrscr;
    txterror('Nicht genug freier Speicher vorhanden');
    heaperrorfunc:=0;
  end;
end;

function upstring(s:string):string;
var
  i : integer;
begin
  for i:=1 to length(s) do s[i]:=upcase(s[i]);
  upstring:=s;
end;

procedure setbasedate(date:tdatum);
begin
  if (date.year mod 400=0) or ((date.year mod 4=0) and (date.year mod 100<>0))
    then daymonth[2]:=29; { Schaltjahr }
end;


function strval(s:string):longint;
var
  code : integer;
  k    : longint;
begin
  val(s,k,code);
  if code<>0 then begin
    strvalerror:=true; k:=0;
  end;
  strval:=k;
end;


procedure incdate(var d:tdatum);
begin
  if d.day>=daymonth[d.month] then begin
    if d.month>=12 then begin
      d.month:=1; inc(d.year); d.day:=1;
    end else begin
      inc(d.month); d.day:=1;
    end;
  end
  else inc(d.day);
end;

procedure decdate(var d:tdatum);
begin
  if d.day<2 then begin
    if d.month<2 then begin
      d.month:=12; d.day:=31; dec(d.year)
    end else begin
      dec(d.month); d.day:=daymonth[d.month];
    end;
  end
  else dec(d.day);
end;

function datumkleiner(d1,d2:tdatum):boolean;
{ Test auf kleiner/gleich }
begin
  if (d1.year<d2.year) or (d1.year=d2.year) and
    ( (d1.month<d2.month) or ((d1.month=d2.month) and (d1.day<=d2.day)) )
    then datumkleiner:=true
  else datumkleiner:=false;
end;


function min(a,b:longint):longint;
begin
  if a<b then
    min:=a
  else
    min:=b;
end;

procedure ltrim(var s:string);
begin
  if s='' then exit;
  while (s<>'') and (s[1]<=#32) do s:=copy(s,2,255);
end;

procedure rtrim(var s:string);
begin
  if s='' then exit;
  while (s<>'') and (s[length(s)]<=#32) do s:=copy(s,1,length(s)-1);
end;

procedure trim(var s:string);
begin
  ltrim(s);
  rtrim(s);
end;

procedure process(var s:string);
var
  i : integer;
  s1: string;
begin
  if stat.ibmchar then exit;
  s1:='';
  for i:=1 to length(s) do begin
    case s[i] of
      '„': s1:=s1+'ae';
      '”': s1:=s1+'oe';
      '': s1:=s1+'ue';
      'á': s1:=s1+'ss';
      '': s1:=s1+'Ae';
      'š': s1:=s1+'Ue';
      '™': s1:=s1+'Oe';
      '*':
      else if (ord(s[i])>=32) and (ord(s[i])<=127) then s1:=s1+s[i];
    end;
  end;
  s:=s1;
end;

procedure adduser(username:string; totalsize,quotesize:longint);
var
  i : integer;
  p : puser;
  p1: ^pointer;
begin
  process(username);
  p:=user; p1:=@user;
  while assigned(p) and (upstring(p^.name^)<>upstring(username)) do begin
    p1:=@p^.next; p:=p^.next;
  end;
  if not assigned(p) then begin
    new(p); getmem(pointer(p^.name),length(username)+2);
    p^.name^:=username; p^.totalsize:=totalsize;
    p^.quotesize:=quotesize; p^.mails:=1; p^.next:=nil;
    p1^:=p; inc(userptr);
  end else begin
    inc(p^.totalsize,totalsize);
    inc(p^.quotesize,quotesize);
    inc(p^.mails);
  end;
end;


procedure addbox(boxname:string; totalsize,quotesize:longint);
var
  i : integer;
  p : puser;
  p1: ^pointer;
begin
  process(boxname);
  p:=box; p1:=@box;
  i:=pos(' ',boxname);
  if i=0 then i:=255;
  boxname:=copy(boxname,1,i-1);
  {FIDO Adresse?}
  if pos(':',boxname)>0 then begin
    i:=pos('.',boxname);
    if i>0 then boxname:=copy(boxname,1,i-1);
  end;
  if boxname='' then exit;
  while assigned(p) and (upstring(p^.name^)<>upstring(boxname)) do begin
    p1:=@p^.next; p:=p^.next;
  end;
  if not assigned(p) then begin
    new(p); getmem(pointer(p^.name),length(boxname)+2);
    p^.name^:=boxname; p^.totalsize:=totalsize;
    p^.quotesize:=quotesize; p^.mails:=1; p^.next:=nil;
    p1^:=p; inc(boxptr);
  end
  else begin
    inc(p^.totalsize,totalsize);
    inc(p^.quotesize,quotesize);
    inc(p^.mails);
  end;
end;


procedure addbrett(brettname:string; totalsize, quotesize:longint);
var
  i : integer;
  p : pbrett;
  p1: ^pointer;
begin
  process(brettname);
  p:=brett; p1:=@brett;
  while assigned(p) and (upstring(p^.name^)<>upstring(brettname)) do begin
    p1:=@p^.next; p:=p^.next;
  end;
  if not assigned(p) then begin
    new(p); getmem(pointer(p^.name),length(brettname)+2);
    p^.name^:=brettname; p^.totalsize:=totalsize;
    p^.quotesize:=quotesize; p^.mails:=1; p^.next:=nil;
    p1^:=p; inc(brettptr);
  end
  else begin
    inc(p^.totalsize,totalsize);
    inc(p^.quotesize,quotesize);
    inc(p^.mails);
  end;
end;


procedure addreceive(username:string);
var
  i : integer;
  p : preceive;
  p1: ^pointer;
begin
  process(username);
  p:=receive; p1:=@receive;
  while assigned(p) and (upstring(p^.name^)<>upstring(username)) do begin
    p1:=@p^.next; p:=p^.next;
  end;
  if not assigned(p) then begin
    new(p); getmem(pointer(p^.name),length(username)+2);
    p^.name^:=username; p^.mails:=1; p^.next:=nil;
    p1^:=p; inc(receiveptr);
  end
  else inc(p^.mails);
end;


procedure addsubject(subj:string; thesize:longint);
var
  i,ps   : integer;
  p      : psubject;
  p1     : ^pointer;
  changed: boolean;
  s1     : string;
begin
  process(subj);
  repeat changed:=false;
    if length(subj)>0 then begin
      if (subj[1]='-') or (subj[1]=' ') or (subj[1]='#') then begin
        subj:=copy(subj,2,255); changed:=true;
      end;
      if upstring(copy(subj,1,2))='RE' then begin
        ps:=pos(':',subj);
        if (ps=3) or ((ps<8) and (subj[3]='^')) then begin
          subj:=copy(subj,ps+1,255); changed:=true;
        end;
      end;
    end;
  until not changed;
  p:=subject; p1:=@subject;
  while assigned(p) and (upstring(p^.title^)<>upstring(subj)) do begin
    p1:=@p^.next; p:=p^.next;
  end;
  if not assigned(p) then begin
    new(p); getmem(pointer(p^.title),length(subj)+2);
    p^.title^:=subj; p^.mails:=1; p^.next:=nil; p^.size:=thesize;
    p1^:=p; inc(subjptr);
  end
  else begin
    inc(p^.mails); inc(p^.size,thesize);
  end;
end;


function valdate(s:string; var d:tdatum):boolean;
var
  p1,p2      :integer;
  code       :integer;
  w1,w2,w3,w4: word;
begin
  valdate:=false;
  getdate(w1,w2,w3,w4);
  p2:=1;
  while (s[p2]<>'.') and (p2<=length(s)) do inc(p2);
  if p2>length(s) then exit;
  val(copy(s,1,p2-1),d.day,code);
  if code<>0 then exit;
  p1:=p2+1; inc(p2);
  while (s[p2]<>'.') and (p2<=length(s)) do inc(p2);
  if p2>length(s) then exit;
  val(copy(s,p1,p2-p1),d.month,code);
  if code<>0 then exit;
  p1:=p2+1; p2:=length(s);
  s:=copy(s,p1,p2-p1+1);
  if s='' then
    d.year:=w1
  else begin
    val(s,d.year,code);
    if code<>0 then begin
    end
    else if d.year<100 then begin
      d.year:=d.year+(w1 div 100)*100;
    end;
  end;
  valdate:=true;
end;

function str0(w:word;len:integer):string;
var
  s0: string;
begin
  str(w,s0);
  if length(s0)<len then s0:='0'+s0;
  str0:=s0;
end;

procedure putkey(c:char);
{ einzelnes Zeichen in den Tastaturpuffer schreiben }
begin
  memw[$40:memw[$40:$80]]:=ord(c);
  memw[$40:$1c]:=memw[$40:$80]+2;
  memw[$40:$1a]:=memw[$40:$80];
end;

function strdate(d:tdatum; format:integer):string;
var
  s,s1: string;
begin
  s:=str0(d.day,2)+'.'+str0(d.month,2)+'.';
  if format=0 then
    s:=s+str0(d.year,4)
  else if format=1 then s:=s+copy(str0(d.year,4),3,2);
  strdate:=s;
end;


function evalmacro(s:string):string;
var
  p      : integer;
  s1     : string;
  changed: boolean;
begin
  repeat
    changed:=false; s1:=upstring(s);
    p:=pos('$START',s1);
    if p>0 then begin
      s:=copy(s,1,p-1)+strdate(stat.date1,dateformat1)+copy(s,p+6,255);
      changed:=true; continue;
    end;
    p:=pos('$END',s1);
    if p>0 then begin
      s:=copy(s,1,p-1)+strdate(stat.date2,dateformat2)+copy(s,p+4,255);
      changed:=true; continue;
    end;
  until not changed;
  evalmacro:=s;
end;


procedure newconfigfile(name:string; neustart:boolean);
var
  f: file;
  s: string;
begin
  assign(f,name); rewrite(f,1);
  s:='Echostat-Configfile '+version+#27+#13;
  blockwrite(f,s[1],length(s));
  close(f);
  if neustart then begin
    messagebox('Meldung','Bitte starten Sie ECHOSTAT erneut');
    putkey(#27);
    exitechostat(1);
  end;
end;

procedure configreaderror;
begin
  messagebox('Fehler','Beim Einlesen der Datei "echostat.cfg" ist ein'+#13
    +'Fehler aufgetreten. Die Datei muá neu angelegt werden.');
  newconfigfile(my_dircfg,true);
end;

procedure readconfigfile;
var
  p      : ppuffer;
  i      : integer;
  f      : file;
  s      : string;
  p0     : array[0..600] of byte;
  ps     : longint;
  fsize  : longint;
  statist: tstatistik;
  mysize : word;
  pslst  : pstatlist;
  label 1,2;
begin
  logmem('proc entry readconfigfile',1);
  i:=ioresult;
  assign(f,my_dircfg); reset(f,1);
  if ioresult<>0 then begin
    messagebox('Fehler','Datei "echostat.cfg" nicht gefunden'+#13
    +'Die Datei wird neu angelegt');
    newconfigfile(my_dircfg,true);
  end;
  fsize:=filesize(f);
  {!!! statlst muá noch freigegeben werden !!!}
  statlst:=nil;
  blockread(f,p0[0],600); i:=ioresult;
  i:=0; s:='';
  while (p0[i]<>13) and (i<255) do begin
    s:=s+chr(p0[i]); inc(i)
  end;
  if (i>=255) or (copy(s,1,20)<>'Echostat-Configfile ') then configreaderror;
  if copy(s,21,length(compatible_version))<>compatible_version then begin
    s:=copy(s,21,length(s)-21);
    messagebox('Fehler','Die vorgefundene Datei "echostat.cfg" ist von'+#13+
      'Echostat Version '+s+' geschrieben worden und'+#13
      +'kann nicht gelesen werden.'+#13+
      'Bitte erstellen Sie diese Datei erneut.');
    exitechostat(1);
  end;
  ps:=length(s)+1;
  headersize:=ps;
1:
  if ps>=fsize then goto 2;
  seek(f,ps);
  blockread(f,mysize,2);
  blockread(f,statist,sizeof(tstatistik));
  new(pslst); pslst^.next:=statlst; statlst:=pslst;
  pslst^.ps:=ps; pslst^.size:=mysize; pslst^.myname:=statist.myname;
  inc(ps,mysize+2);
  goto 1;
2:
  close(f);
  logmem('proc exit readconfigfile',-1);
end;



function showtime(t:longint):string;
var
  w1,w2,w3,w4: word;
begin
  w1:=t div (60*60); t:=t mod (60*60);
  w2:=t div 60; t:=t mod 60;
  w3:=t;
  showtime:=str0(w1,2)+':'+str0(w2,2)+':'+str0(w3,2);
end;

procedure exitstatistic;
var
  diag      : pdialog;
  b_ok,b_esc: pbutton;
  event     : tevent;
  status    : integer;
begin
  new(diag,init(25,(screen_y-5) shr 1,30,5,true));
  diag^.name:='Statistik beenden?';
  new(b_ok,init(diag,2,2,10,'&Weiter',kbaltw));
  new(b_esc,init(diag,18,2,10,'&Ende',kbalte));
  diag^.paint;
  diag^.rundialog(b_ok,b_esc);
  status:=diag^.mystatus;
  diag^.done;
  if status=dg_exit then begin
    statdiag^.done;
    putkey(#27);
    exitechostat(1);
  end;
end;

procedure updatedisplay;
var
  r          : real;
  k,i,j      : integer;
  s0,s1      : string;
  thistime   : longint;
  w1,w2,w3,w4: word;
  c          : char;
begin
  r:=readfilesize/totalfilesize;
  str(100*r:0:0,s0);
  while length(s0)<4 do s0:=' '+s0;
  k:=round(40*r); s1:='';
  for i:=1 to k do s1:=s1+'Û';
  while length(s1)<40 do s1:=s1+'°';
  sd_tbar^.settext(s1+' '+s0+'%');
  gettime(w1,w2,w3,w4);
  thistime:=longint(w3)+longint(w2)*60+longint(w1)*60*60-starttime;
  if r>0.1 then begin
    sd_ttotal^.settext(showtime(round(thistime/r)));
    sd_trest^.settext(showtime(round((1/r-1)*thistime)));
  end;
  str(totalmsgs:6,s0);
  sd_tmsgs^.settext(s0);
  str(foundmsgs:6,s0);
  sd_tfound^.settext(s0);
  while keypressed do begin
    c:=readkey;
    if c=#27 then exitstatistic;
  end;
end;


procedure getline(var s:string);
var
  p1: integer;
  c : char;
  label 1,2;
begin
  p1:=1;
1:
  while rbpos>=rbfill do begin
    if endoffile1 then begin
      endoffile:=true; goto 2;
    end;
    rbpos:=rbpos-rbfill;
    blockread(f_in,rbuffer[0],rbuffersize,rbfill);
    inc(readfilesize,rbfill); updatedisplay;
    if rbfill<rbuffersize then endoffile1:=true;
  end;
  c:=rbuffer[rbpos]; inc(rbpos); inc(msgsize);
  if c=#10 then begin
    dec(p1); goto 2;
  end;
  s[p1]:=c; inc(p1);
  if p1>255 then goto 2;
  goto 1;
2:
  s[0]:=chr(p1-1);
  if debuglevel>1 then logwrite(s);
end;


procedure scanusers(fn:string);
var
  s,s1        : string;
  p,p1,i,j    : integer;
  total,quote : longint;
  brett,
  user,fs,
  emp,bet,box : string;
  date        : tdatum;
  valid,valid1: boolean;
  w1,w2       : integer;
  thismsgsize : longint;
  ps          : pstrlist;
  timeindex   : integer;
  label 1;
begin
  logmem('proc entry scanusers ('+fn+')',1);
  assign(f_in,xp_dir+fn); reset(f_in,1); rbpos:=0; rbfill:=0;
  endoffile:=false; endoffile1:=false;
  user:=''; emp:='';
  thismsgsize:=0; msgsize:=0;
  bet:=''; brett:='';
  fs:='Fehler in Datei "'+fn+'"';
1:
  valid:=false; valid1:=false; user:=''; emp:=''; bet:='';
  repeat
    getline(s1); s:=s1;
    if endoffile then begin
      logmem('proc exit scanusers',-1);
      close(f_in); exit;
    end;
    p:=pos(':',s);
    if p>0 then begin
      { Nachrichtenkopf einlesen }
      if (copy(s,1,3)='EMP') then begin
        s:=upstring(copy(s,5,255)); trim(s); inc(totalmsgs);
        ps:=stat.mybretter;
        while assigned(ps) do begin
          if upstring(ps^.s^)=s then begin
            valid1:=true; ps^.marked:=true; brett:=s;
            break;
          end;
          ps:=ps^.next;
        end;
      end
      else if copy(s,1,3)='ABS' then begin
        p1:=pos('@',s);
        user:=copy(s,5,p1-5); trim(user);
        box:=copy(s,p1+1,255); trim(box);
      end
      else if copy(s,1,3)='EDA' then begin
        s:=copy(s,5,255);
        trim(s);
        strvalerror:=false;
        date.day:=strval(copy(s,7,2));
        date.month:=strval(copy(s,5,2));
        date.year:=strval(copy(s,1,4));
        if copy(s,16,255)<>'' then begin
          p1:=pos(':',s);
          if p1=0 then
            p1:=255
          else
            p1:=p1-16;
          w1:=strval(copy(s,9,2)); w2:=strval(copy(s,16,p1));
          if w1+w2>=24 then
            incdate(date)
          else if w1+w2<0 then decdate(date);
        end;
        if (strvalerror) and (debuglevel>0) then begin
          logwrite(right_align+'  Error in Date/Time-Stamp');
          logwrite(right_align+'  >>>'+s+'<<<'); inc(failmsgs);
        end;
        if datumkleiner(stat.date1,date) and datumkleiner(date,stat.date2)
          then valid:=true;
        w1:=(w1+w2) mod 24;
        strvalerror:=false;
        if ((w1=0) and (strval(copy(s,11,2))=0)) or strvalerror
          then timeindex:=24
        else timeindex:=w1;
        strvalerror:=false;
      end
      else if copy(s,1,8)='X-XP-FTO' then begin
        emp:=copy(s,10,255); trim(emp);
      end
      else if copy(s,1,3)='BET' then begin
        bet:=copy(s,5,255);
        trim(bet);
      end
      else if copy(s,1,3)='LEN' then begin
        s:=copy(s,5,255); trim(s);
        strvalerror:=false;
        thismsgsize:=strval(s);
        if strvalerror and (debuglevel>0) then
          logwrite(right_align+'Error in messagesize: >>>'+s+'<<<');
      end;
    end;
  until s1[0]=#0;
  msgsize:=0; total:=0; quote:=0;
  if valid and valid1 then begin
    inc(foundmsgs); inc(stat.mtime[timeindex]);
    while msgsize<thismsgsize do begin
      getline(s);
      p:=pos('>',s);
      if (p>0) and (p<5) then inc(quote,length(s));
      inc(total,length(s));
    end;
    if user<>''  then adduser(user,total,quote);
    if emp<>''   then addreceive(emp);
    if bet<>''   then addsubject(bet,total);
    if brett<>'' then addbrett(brett,total,quote);
    if box<>''   then addbox(box,total,quote);
  end
  else inc(rbpos,thismsgsize);
  goto 1;
end;


procedure scanallfiles;
var
  r    : searchrec;
  i,x  : integer;
  f    : file;
  s1   : string;
  w1,w2,
  w3,w4: word;
begin
  logmem('proc entry scanallfiles',1);
  new(statdiag,init(5,(screen_y-11) shr 1,70,11,true));
  statdiag^.name:='Echostat '+version;
  new(sd_t,init(statdiag,2,2,'Name           :'));
  new(sd_t,init(statdiag,20,2,stat.myname)); sd_t^.highlight:=true;
  new(sd_t,init(statdiag,2,3,'XP Verzeichnis :'));
  new(sd_t,init(statdiag,20,3,xp_dir)); sd_t^.highlight:=true;
  new(sd_t,init(statdiag,2,4,'Puffer einlesen:'));
  new(sd_tbar,init(statdiag,20,4,'')); sd_tbar^.highlight:=true;
  new(sd_t,init(statdiag,2,5,'Gesamtzeit     :'));
  new(sd_ttotal,init(statdiag,20,5,'')); sd_ttotal^.highlight:=true;
  new(sd_t,init(statdiag,2,6,'Restzeit       :'));
  new(sd_trest,init(statdiag,20,6,'')); sd_trest^.highlight:=true;
  new(sd_t,init(statdiag,2,8,'Gefunden       :'));
  new(sd_tfound,init(statdiag,22,8,'')); sd_tfound^.highlight:=true;
  new(sd_t,init(statdiag,2,7,'Nachrichten    :'));
  new(sd_tmsgs,init(statdiag,22,7,'')); sd_tmsgs^.highlight:=true;
  statdiag^.paint; hidecursor;
  gettime(w1,w2,w3,w4);
  starttime:=longint(w3)+longint(w2)*60+longint(w1)*60*60;
  totalfilesize:=0; readfilesize:=0; totalmsgs:=0; foundmsgs:=0;
  for i:=0 to 24 do stat.mtime[i]:=0;
  user:=nil; receive:=nil; subject:=nil; brett:=nil;
  userptr:=-1; boxptr:=-1; brettptr:=-1; receiveptr:=-1; subjptr:=-1;
  findfirst(xp_dir+'mpuffer.*',anyfile,r);
  while doserror=0 do begin
    assign(f,xp_dir+r.name); reset(f,1);
    if ioresult<>0 then begin
      if debuglevel>0 then logwrite(right_align+'   Error on open')
    end
    else begin
      inc(totalfilesize,filesize(f));
      close(f);
    end;
    findnext(r);
  end;
  findfirst(xp_dir+'mpuffer.*',anyfile,r);
  while doserror=0 do begin
    scanusers(r.name);
    findnext(r);
  end;
  if failmsgs>0 then
    messagebox('Warnung','Einige Nachrichten konnten nicht'+#13
      +'korrekt gelesen werden'+#13
      +'Siehe Logfile fr mehr Info');
  statdiag^.done; showcursor;
  str(totalmsgs:5,s1);
  if debuglevel=1 then logwrite(right_align+'messages: '+s1);
  str(foundmsgs:5,s1);
  if debuglevel=1 then logwrite(right_align+'messages relevant: '+s1);
  logmem('proc exit scanallfiles',-1);
end;


procedure initdefaultstat;
var
  p: pstrlist;
begin
{ !!! Alte Statistik muá noch freigegeben werden !!! }
  with stat do begin
    automode:=false; destfile:=fexpand(my_dir+'stat.out');
    destbrett:=''; destname:=''; dest:=2;
    daydist:=3; header:=''; footer:='';
    ibmchar:=true; datemode:=1;
    top_sender:=20; top_empf:=20; top_graph:=20; top_betreff:=20;
    top_bretter:=10; top_box:=10;
    with_bretter:=false; with_box:=false;
    with_sender:=true; with_empf:=true; with_graph:=true;
    with_betreff:=true; with_time:=false; betrefftext:='Statistik ($START)';
    myname:='Neue Statistik';
    brettptr:=-1; hierarchien:=''; brettrealname:='';
    mybretter:=nil;
  end;
  p:=bretterlist;
  while assigned(p) do begin
    p^.marked:=false; p:=p^.next;
  end;
  userptr:=-1; boxptr:=-1; brettptr:=-1; receiveptr:=-1; subjptr:=-1;
  user:=nil; receive:=nil; subject:=nil; brett:=nil;
end;

procedure loadstat(ps:longint);
{ L„dt die Statistik ab Position ps }
var
  f        : file;
  size,
  size1,i,j: word;
  p        : ppuffer;
  br,abr   : pstrlist;
begin
  logmem('proc entry loadstat',1);
  initdefaultstat;
  assign(f,my_dircfg); reset(f,1); seek(f,ps);
  blockread(f,size,2);
  blockread(f,stat,sizeof(stat));
  size1:=size-sizeof(stat);
  getmem(pointer(p),size1+5);
  blockread(f,p^,size1);
  close(f);
  i:=0;
  stat.mybretter:=nil;
  for j:=0 to stat.brettptr do begin
    new(br); br^.next:=stat.mybretter; stat.mybretter:=br;
    getmem(pointer(br^.s),ord(p^[i])+4);
    move(p^[i],br^.s^[0],ord(p^[i])+1);
    inc(i,p^[i]+1);
  end;
  abr:=bretterlist;
  while assigned(abr) do begin
    br:=stat.mybretter;
    while assigned(br) and (br^.s^<>abr^.s^) do br:=br^.next;
    if assigned(br) then
      abr^.marked:=true
    else
      abr^.marked:=false;
    abr:=abr^.next;
  end;
  dispose(pointer(p));
  logmem('proc exit loadstat',-1);
end;


function factor(d:tdatum):longint;
begin
  if d.month<3 then
    factor:=365*longint(d.year)+longint(d.day)+31*(longint(d.month)-1)+
      trunc((longint(d.year)-1)/4)
      -trunc(3/4*trunc(((longint(d.year)-1)/100)+1))
  else
    factor:=365*longint(d.year)+longint(d.day)+31*(longint(d.month)-1)
     -trunc(0.4*longint(d.month)+2.3)
     +trunc(longint(d.year)/4)-trunc(3/4*(trunc(longint(d.year)/100)+1));
end;


function dist(d1,d2:tdatum):longint;
begin
  dist:=factor(d2)-factor(d1);
end;

function findtempname(path,ext:string):string;
var
  f   : file;
  name: string;
  i,j : integer;
  label 1;
begin
  randomize;
1:
  for i:=1 to 100 do begin
    name:='';
    for j:=1 to 8 do name:=name+chr(random(25)+65);
    name:=path+name+'.'+ext;
    assign(f,name);
    reset(f);
    if ioresult<>0 then begin
      findtempname:=name;
      if debuglevel=1 then logwrite(right_align+'proc findtempname, result: '+name);
      exit;
    end;
    close(f);
  end;
  i:=ioresult;
  criterror('Es konnte kein tempor„rer Dateiname'+#13+'ermittelt werden',
    'Letzter Versuch war: '+name);
end;

procedure enlarge(var s:string; k:integer; chr:char);
begin
  while length(s)<k do s:=s+chr;
end;


procedure insertfile(s:string);
var
  t: text;
  r: string;
begin
  if s='' then exit;
  assign(t,s); reset(t);
  if ioresult<>0 then exit;
  while not eof(t) do begin
    readln(t,r);
    writeln(outp,r);
  end;
  writeln(outp,'');
  close(t);
end;


procedure sendzmsg(fname:string);
var
  f          : file;
  f_in,f_out : text;
  size       : longint;
  name,s     : string;
  w1,w2,w3,w4: word;
  label ende;
begin
  assign(f,fname); reset(f,1); size:=filesize(f); close(f);
  name:=findtempname(xp_auto_dir+'\','zer');
  assign(f_in,fname); reset(f_in);
  while (not eof(f_in)) do begin
    readln(f_in,s); dec(size,length(s)+2);
    if s='' then break;
  end;
  if eof(f_in) then goto ende;
  assign(f_out,name); rewrite(f_out);
  writeln(f_out,'EMP: '+stat.destname);
  writeln(f_out,'ABS: Echostat '+version);
  writeln(f_out,'BET: ',evalmacro(stat.betrefftext));
  writeln(f_out,'MID: 56390212');
  getdate(w1,w2,w3,w4);
  s:=str0(w1,4)+str0(w2,2)+str0(w3,2);
  gettime(w1,w2,w3,w4);
  s:=s+str0(w1,2)+str0(w2,2)+str0(w3,2)+'W+0';
  writeln(f_out,'EDA: ',s);
  writeln(f_out,'ROT: ');
  writeln(f_out,'X-XP-NTP: 30');
  str(size,s);
  writeln(f_out,'LEN: ',s);
  writeln(f_out,'');
  while not eof(f_in) do begin
    readln(f_in,s);
    writeln(f_out,s);
  end;
  close(f_out);
ende:
  close(f_in); erase(f_in);
end;


procedure replacestr(var s:string; fnd,rpl:string);
var
  p: integer;
begin
  repeat
    p:=pos(fnd,s);
    if p>0 then s:=copy(s,1,p-1)+rpl+copy(s,p+length(fnd),255);
  until p=0;
end;

procedure checkstr(var s:string);
begin
  replacestr(s,'*','');
  if stat.ibmchar then exit;
  replacestr(s,'„','ae');
  replacestr(s,'”','oe');
  replacestr(s,'','ue');
  replacestr(s,'á','ss');
  replacestr(s,'','Ae');
  replacestr(s,'™','Oe');
  replacestr(s,'š','Ue');
end;

procedure trimbrett(var s:string);
var
  h,h1: string;
  i   : integer;
begin
  if stat.hierarchien='' then exit;
  h:=stat.hierarchien;
  repeat
    i:=pos(',',h);
    if i=0 then i:=length(h)+1;
    h1:=copy(h,1,i-1);
    h:=copy(h,i+1,255);
    trim(h1);
    if copy(s,1,length(h1))=h1 then begin
      s:=copy(s,length(h1)+1,255);
      exit;
    end;
  until h='';
end;

procedure statistics;
var
  t              : puser;
  i,j,k          : integer;
  changed        : boolean;
  s,s1,header    : string;
  maxlen,totallen: longint;
  p1,p2          : real;
  mails          : word;
  c1,c2,c3       : char;
  br,br1         : pbrett;
  us,us1         : puser;
  rc,rc1         : preceive;
  sb,sb1         : psubject;
  up0            : ^pointer;
  memsize        : longint;
  ps             : pstrlist;
  stfilename     : string;
  label ende;
begin
  logmem('proc entry statistics',1);
  case stat.dest of
    0:
      begin
        stfilename:=findtempname(xp_auto_dir+'\','msd');
        stat.destname:='/¯Statistik'; assign(outp,stfilename);
      end;
    1:
      begin
        stfilename:=findtempname(xp_auto_dir+'\','msd');
        stat.destname:=stat.destbrett; assign(outp,stfilename);
      end;
    2:
      begin
        stat.destname:=''; assign(outp,'');
      end;
    3:
      begin
        stat.destname:=stat.destfile; assign(outp,stat.destname);
      end;
  end;
  trim(stat.hierarchien);
  memsize:=maxavail;
  if debuglevel=1 then begin
    logwrite(right_align+'mem usage: '+fstr(round(100*(totalfree-memsize)/totalfree))+'%');
  end;
  rewrite(outp);
  if ioresult<>0 then begin
    messagebox('Fehler','Fehler bei Schreibversuch in'+#13+stat.destname);
    exitechostat(1);
  end;
  if stat.dest<2 then begin
    writeln(outp,'Empfaenger: '+stat.destname);
    writeln(outp,'Betreff: ',evalmacro(stat.betrefftext));
    writeln(outp,'');
  end;
  if stat.ibmchar then
    s:='ÍÍÍÍÍÍÍÍÍÍÍÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÍÍÍÍÍÍÍÍÍÍÍ'
  else
    s:='===========--------------------------------------------------------===========';
  s1:=' Echostat '+version+' ';
  if stat.ibmchar then
    s1:=s1+'ÄÄ'
  else
    s1:=s1+'--';
  s1:=s1+' (c) 1996 Hilmar Buchta ';
  k:=(length(s)-length(s1)) div 2;
  for i:=1 to length(s1) do s[k+i]:=s1[i];
  writeln(outp,s);
  if stat.ibmchar then
    writeln(outp,'ÍÍÍÍÍÍÍÍÍÄÄÄÄ '+teamstr+' ÄÄÄÄÍÍÍÍÍÍÍÍÍ')
  else
    writeln(outp,'=========---- '+teamstr+' ----=========');
  writeln(outp,'');
  insertfile(stat.header);
  if stat.brettrealname<>'' then
    writeln(outp,'Statistik : ',stat.brettrealname)
  ;{else if assigned(stat.mybretter) then begin
    if stat.ibmchar then
      c1:='ş'
    else
      c1:='#';
    s:='Brettliste:';
    ps:=stat.mybretter;   <-- dieser Zeiger tickt noch nicht ganz sauber!
    while assigned(ps) do begin
      s1:=ps^.s^;
      trimbrett(s1);
      writeln(outp,s);
      if s1[1]<>'/' then
        s:='            '+c1+' Fehlerhafte Zeigeroperation!'
      else
        s:='            '+c1+' '+s1;
      ps:=ps^.next;
    end;
    writeln(outp,s);
  end;}

{************************************************************************
*                                                                       *
*                                                                       *
*   1. Teil : šbersicht                                                 *
*                                                                       *
*                                                                       *
************************************************************************}

  writeln(outp,'Zeitraum  : ',strdate(stat.date1,0),' bis ',strdate(stat.date2,0));
  if userptr<0 then begin
    writeln(outp,'Es liegen keine Nachrichten ber diesen Zeitraum vor');
    goto ende;
  end;
  mails:=0; us:=user; maxlen:=0;
  while assigned(us) do begin
    inc(mails,us^.mails); inc(maxlen,us^.totalsize); us:=us^.next;
  end;
  writeln(outp,'');
  if stat.with_sender or stat.with_graph or stat.with_empf or stat.with_betreff
    or stat.with_time or stat.with_bretter or stat.with_box then begin
    writeln(outp,'');
    if stat.ibmchar then begin
      writeln(outp,'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸');
      writeln(outp,'³      šbersicht                                                             ³');
      writeln(outp,'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾');
    end
    else begin
      writeln(outp,'==============================================================================');
      writeln(outp,'|      Uebersicht                                                            |');
      writeln(outp,'==============================================================================');
    end;
  end;
  writeln(outp,'Nachrichten gesamt     : ',mails:6);
  writeln(outp,'User gesamt            : ',userptr+1:6);
  writeln(outp,'Betreffs               : ',subjptr+1:6);
  writeln(outp,'Boxen                  : ',boxptr+1:6);
  write(outp,'Gesamtl„nge der Mails  : ');
  if maxlen>100000 then
    writeln(outp,maxlen div 1024:6,' KB')
  else
    writeln(outp,maxlen:6,' Byte');
  if stat.with_bretter then begin
    writeln(outp,'');
    { Beginn der Brettbersicht }
    if brettptr>stat.top_bretter-1 then begin
      str(stat.top_bretter,header); header:='(Top '+header+')';
    end
    else
      header:='';
    header:=' Bretter  '+header;
    enlarge(header,43,' ');
    if stat.ibmchar then begin
      writeln(outp,'');
      writeln(outp,header,'³ Mails ³ L„nge gesamt ³  L„nge í');
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ');
      c1:='³';
    end
    else begin
      writeln(outp,header,'| Mails | Laenge ges.  | Durchschn.');
      writeln(outp,'-------------------------------------------+-------+--------------+-----------');
      c1:='|';
    end;
    repeat changed:=false;
      br:=brett; br1:=brett^.next; up0:=@brett;
      while assigned(br) and assigned(br1) do begin
        if (br^.mails<br1^.mails) or
          ((br^.mails=br1^.mails) and (br^.totalsize<br1^.totalsize)) then begin
          up0^:=br1; br^.next:=br1^.next; br1^.next:=br; changed:=true;
        end;
        up0:=@br^.next; br:=br^.next; br1:=br^.next;
      end;
    until not changed;
    br:=brett; mails:=0;
    totallen:=0;
    for i:=0 to min(brettptr,stat.top_bretter-1) do begin
      s:=br^.name^; trimbrett(s); checkstr(s); s:=copy(s,1,29);
      while length(s)<42 do s:=s+'.';
      if br^.totalsize=0 then str(br^.quotesize:0,s1) else
        str(100*br^.quotesize/br^.totalsize:0:1,s1);
      while length(s1)<5 do s1:=' '+s1;
      writeln(outp,s,' ',c1,' ',br^.mails:5,' ',c1,' ',br^.totalsize:12,
        ' ',c1,' ',br^.totalsize/br^.mails:9:2);
      inc(mails,br^.mails); inc(totallen,br^.totalsize);
      br:=br^.next;
    end;
    if stat.ibmchar then
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ')
    else
      writeln(outp,'------------------------------------------------------------------------------');
  end;

  { Beginn der Boxbersicht }
  if stat.with_box then begin
    if boxptr>stat.top_box-1 then begin
      str(stat.top_box,header); header:='(Top '+header+')';
    end
    else header:='';
    header:=' Boxen  '+header;
    writeln(outp,'');
    enlarge(header,43,' ');
    if stat.ibmchar then begin
      writeln(outp,header,'³ Mails ³ L„nge gesamt ³  L„nge í');
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ');
      c1:='³';
    end
    else begin
      writeln(outp,header,'| Mails | Laenge ges.  | Durchschn.');
      writeln(outp,'-------------------------------------------+-------+--------------+-----------');
      c1:='|';
    end;
    repeat changed:=false;
      us:=box; us1:=box^.next; up0:=@box;
      while assigned(us) and assigned(us1) do begin
        if (us^.mails<us1^.mails) or
          ((us^.mails=us1^.mails) and (us^.totalsize<us1^.totalsize)) then begin
          up0^:=us1; us^.next:=us1^.next; us1^.next:=us; changed:=true;
        end;
        up0:=@us^.next; us:=us^.next; us1:=us^.next;
      end;
    until not changed;
    us:=box;
    totallen:=0; mails:=0;
    for i:=0 to min(boxptr,stat.top_box-1) do begin
      inc(totallen,us^.totalsize);
      inc(mails,us^.mails);
      s:=us^.name^; checkstr(s);
      s:=copy(s,1,29);
      while length(s)<42 do s:=s+'.';
      if us^.totalsize=0 then str(us^.quotesize:0,s1) else
        str(100*us^.quotesize/us^.totalsize:0:1,s1);
      while length(s1)<5 do s1:=' '+s1;
      writeln(outp,s,' ',c1,' ',us^.mails:5,' ',c1,' ',us^.totalsize:12,
        ' ',c1,' ',us^.totalsize/us^.mails:9:2);
      us:=us^.next;
    end;
    if stat.ibmchar then
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ')
    else
      writeln(outp,'------------------------------------------------------------------------------');
    end; { von if with_box... }


{************************************************************************
*                                                                       *
*                                                                       *
*   2. Teil : Gesendete Nachrichten                                     *
*                                                                       *
*                                                                       *
************************************************************************}

  if stat.with_sender then begin
    if userptr>stat.top_sender-1 then begin
      str(stat.top_sender,header); header:='(Top '+header+')';
    end
    else header:='';
    header:='    Nachrichtensender  '+header;
    enlarge(header,76,' ');
    writeln(outp,''); writeln(outp,'');
    if stat.ibmchar then begin
      writeln(outp,'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸');
      writeln(outp,'³'+header+'³');
      writeln(outp,'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ¾');
      writeln(outp,'            Name              ³ Mails ³ L„nge gesamt ³  L„nge í  ³ Quoteanteil');
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄ');
      c1:='³';
    end
    else begin
      writeln(outp,'==============================================================================');
      writeln(outp,'|'+header+'|');
      writeln(outp,'==============================================================================');
      writeln(outp,'            Name              | Mails | Laenge ges.  | Durchschn.| Quoteanteil');
      writeln(outp,'------------------------------+-------+--------------+-----------+------------');
      c1:='|';
    end;
    repeat changed:=false;
      us:=user; us1:=user^.next; up0:=@user;
      while assigned(us) and assigned(us1) do begin
        if (us^.mails<us1^.mails) or
          ((us^.mails=us1^.mails) and (us^.totalsize<us1^.totalsize)) then begin
          up0^:=us1; us^.next:=us1^.next; us1^.next:=us; changed:=true;
        end;
        up0:=@us^.next; us:=us^.next; us1:=us^.next;
      end;
    until not changed;
    us:=user; mails:=0;
    for i:=0 to min(userptr,stat.top_sender-1) do begin
      s:=us^.name^; checkstr(s);
      s:=copy(s,1,29);
      while length(s)<29 do s:=s+'.';
      if us^.totalsize=0 then str(us^.quotesize:0,s1) else
        str(100*us^.quotesize/us^.totalsize:0:1,s1);
      while length(s1)<5 do s1:=' '+s1;
      writeln(outp,s,' ',c1,' ',us^.mails:5,' ',c1,' ',us^.totalsize:12,
        ' ',c1,' ',us^.totalsize/us^.mails:9:2,' ',c1,'     ',s1,'%');
      inc(mails,us^.mails);
      us:=us^.next;
    end;
    if stat.ibmchar then
      writeln(outp,'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍ')
    else
      writeln(outp,'==============================================================================');
  end; {von if with_sender...}

  if stat.with_graph then begin
    writeln(outp,''); write(outp,'Sortiert nach ');
    if stat.ibmchar then
      write(outp,'Gesamtl„nge')
    else write(outp,'Gesamtlaenge');
    if userptr>stat.top_graph-1 then begin
      str(stat.top_graph,header); header:=' (Top '+header+'):';
    end
    else header:=':';
    writeln(outp,header);
    repeat changed:=false;
      us:=user; us1:=user^.next; up0:=@user;
      while assigned(us) and assigned(us1) do begin
        if (us^.totalsize<us1^.totalsize) then begin
          up0^:=us1; us^.next:=us1^.next; us1^.next:=us; changed:=true;
        end;
        up0:=@us^.next; us:=us^.next; us1:=us^.next;
      end;
    until not changed;
    maxlen:=-1; totallen:=0; mails:=0; us:=user;
    for i:=0 to userptr do begin
      if us^.totalsize>maxlen then maxlen:=us^.totalsize;
      inc(mails,us^.mails);
      inc(totallen,us^.totalsize);
      us:=us^.next;
    end;
    if stat.ibmchar then begin
      c1:='Û'; c2:='±'; c3:='ù';
    end
    else begin
      c1:='#'; c2:='+'; c3:=' ';
    end;
    us:=user;
    for i:=0 to min(userptr,stat.top_graph-1) do begin
      s:=us^.name^; checkstr(s);
      s:=copy(s,1,29);
      while length(s)<29 do s:=s+'.';
      write(outp,s);
      p1:=(us^.totalsize-us^.quotesize)/maxlen;
      p2:=us^.totalsize/maxlen;
      k:=round(p1*40);
      s:='';
      for j:=1 to k do s:=s+c1;
      k:=round(p2*40)-k;
      for j:=1 to k do s:=s+c2;
      while length(s)<40 do s:=s+c3;
      if totallen=0 then str(us^.totalsize:0,s1) else
        str(100*us^.totalsize/totallen:0:1,s1);
      while length(s1)<5 do s1:=' '+s1;
      writeln(outp,' ',s,' ',s1,'%');
      us:=us^.next;
    end;
    writeln(outp,c1,': nicht-gequoteter Anteil,');
    writeln(outp,c2,': gequoteter Anteil');
  end; {von if with_graph... }


{************************************************************************
*                                                                       *
*                                                                       *
*   3. Teil : Empfangene Nachrichten                                    *
*                                                                       *
*                                                                       *
************************************************************************}
  if (receiveptr>=0) and (stat.with_empf) then begin
    if receiveptr>stat.top_empf-1 then begin
      str(stat.top_empf,header); header:='(Top '+header+')';
    end
    else header:='';
    if stat.ibmchar then
      header:='    Nachrichtenempf„nger  '+header
    else
      header:='    Nachrichtenempfaenger  '+header;
    enlarge(header,76,' ');
    repeat changed:=false;
      rc:=receive; rc1:=receive^.next; up0:=@receive;
      while assigned(rc) and assigned(rc1) do begin
        if (rc^.mails<rc1^.mails) then begin
          up0^:=rc1; rc^.next:=rc1^.next; rc1^.next:=rc; changed:=true;
        end;
        up0:=@rc^.next; rc:=rc^.next; rc1:=rc^.next;
      end;
    until not changed;
    writeln(outp,'');
    writeln(outp,'');
    if stat.ibmchar then begin
      writeln(outp,'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸');
      writeln(outp,'³'+header+'³');
      writeln(outp,'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍ¾');
      writeln(outp,'            Name                                           ³  Mails  ³ Anteil ');
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ');
      c1:='³';
    end
    else begin
      writeln(outp,'==============================================================================');
      writeln(outp,'|'+header+'|');
      writeln(outp,'==============================================================================');
      writeln(outp,'            Name                                           |  Mails  | Anteil ');
      writeln(outp,'-----------------------------------------------------------+---------+--------');
      c1:='|';
    end;
    rc:=receive; maxlen:=0;
    while assigned(rc) do begin
      inc(maxlen,rc^.mails);  rc:=rc^.next;
    end;
    rc:=receive;
    for i:=0 to min(receiveptr,stat.top_empf-1) do begin
      s:=rc^.name^; checkstr(s);
      s:=copy(s,1,58);
      while length(s)<58 do s:=s+'.';
      if maxlen=0 then str(rc^.mails:0,s1) else
        str(100*rc^.mails/maxlen:0:1,s1);
      while length(s1)<5 do s1:=' '+s1;
      writeln(outp,s,' ',c1,'  ',rc^.mails:6,' ',c1,' ',s1,'%');
      rc:=rc^.next;
    end;
    if stat.ibmchar then
      writeln(outp,'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍ')
    else
      writeln(outp,'==============================================================================');
  end; { der empfangenen Nachrichten }


{************************************************************************
*                                                                       *
*                                                                       *
*   4. Teil : Betreffs                                                  *
*                                                                       *
*                                                                       *
************************************************************************}
  if (subjptr>=0) and (stat.with_betreff) then begin
    writeln(outp,''); writeln(outp,'');
    if subjptr>stat.top_betreff-1 then begin
      str(stat.top_betreff,header); header:='(Top '+header+')';
    end
    else header:='';
    header:='    Betreffs  '+header;
    enlarge(header,76,' ');
    repeat changed:=false;
      sb:=subject; sb1:=subject^.next; up0:=@subject;
      while assigned(sb) and assigned(sb1) do begin
        if (sb^.mails<sb1^.mails) or
          ((sb^.mails=sb1^.mails) and (sb^.size<sb1^.size)) then begin
          up0^:=sb1; sb^.next:=sb1^.next; sb1^.next:=sb; changed:=true;
        end;
        up0:=@sb^.next; sb:=sb^.next; sb1:=sb^.next;
      end;
    until not changed;
    if stat.ibmchar then begin
      writeln(outp,'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸');
      writeln(outp,'³'+header+'³');
      writeln(outp,'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍ¾');
      writeln(outp,'            Betreff                                ³ Anzahl ³ Gr”áe  ³ Anteil ');
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄ');
      c1:='³';
    end
    else begin
      writeln(outp,'==============================================================================');
      writeln(outp,'|'+header+'|');
      writeln(outp,'==============================================================================');
      writeln(outp,'            Name                                   | Anzahl |Groesse | Anteil ');
      writeln(outp,'---------------------------------------------------+--------+--------+--------');
      c1:='|';
    end;
    sb:=subject; maxlen:=0;
    while assigned(sb) do begin
      inc(maxlen,sb^.mails);  sb:=sb^.next;
    end;
    sb:=subject;
    for i:=0 to min(subjptr,stat.top_betreff-1) do begin
      s:=sb^.title^; checkstr(s);
      s:=copy(s,1,50);
      while length(s)<50 do s:=s+'.';
      if maxlen=0 then str(sb^.mails:0,s1) else
        str(100*sb^.mails/maxlen:0:1,s1);
      while length(s1)<5 do s1:=' '+s1;
      writeln(outp,s,' ',c1,' ',sb^.mails:6,' ',c1,' ',sb^.size div 1024:6,'K',
        c1,' ',s1,'%');
      sb:=sb^.next;
    end;
    if stat.ibmchar then
      writeln(outp,'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍ')
    else
      writeln(outp,'==============================================================================');
  end; { des Betreff-Listers }

{************************************************************************
*                                                                       *
*                                                                       *
*   5. Teil : Zeitauswertung                                            *
*                                                                       *
*                                                                       *
************************************************************************}
  if stat.with_time then begin
    writeln(outp,''); writeln(outp,'');
    header:='    Zeitauswertung';  enlarge(header,76,' ');
    if stat.ibmchar then begin
      writeln(outp,'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸');
      writeln(outp,'³'+header+'³');
      writeln(outp,'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾');
      writeln(outp,'  Uhrzeit      ³  Anzahl  ³      Mailaufkommen');
      writeln(outp,'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
      c1:='³'; c2:='ß';
    end
    else begin
      writeln(outp,'==============================================================================');
      writeln(outp,'|'+header+'|');
      writeln(outp,'==============================================================================');
      writeln(outp,'  Uhrzeit      |  Anzahl  |      Mailaufkommen');
      writeln(outp,'---------------+----------+---------------------------------------------------');
      c1:='|'; c2:='#';
    end;
    maxlen:=-1; totallen:=0;
    for i:=0 to 23 do begin
      inc(totallen,stat.mtime[i]);
      if stat.mtime[i]>maxlen then maxlen:=stat.mtime[i];
    end;
    for i:=0 to 23 do begin
      s:=str0(i,2); s:=' '+s+':00 - '+s+':59'+' '+c1;
      str(stat.mtime[i]:8,s1); s:=s+s1+'  '+c1+' ';
      j:=(40*stat.mtime[i]) div maxlen;
      for k:=1 to j do s:=s+c2;
      enlarge(s,70,' ');
      if totallen=0 then str(stat.mtime[i]:0,s1) else
        str(100*stat.mtime[i]/totallen:0:1,s1);
      while length(s1)<5 do s1:=' '+s1;
      s:=s+s1+'%';
      writeln(outp,s);
    end;
    if stat.ibmchar then
      writeln(outp,'ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ')
    else
      writeln(outp,'==============================================================================');
    if stat.mtime[24]=1 then
      writeln(outp,'( Eine 00:00 - Nachricht wurde nicht ausgewertet)')
    else if stat.mtime[24]>1 then
      writeln(outp,'(',stat.mtime[24],' 00:00 - Nachrichten wurden nicht ausgewertet)');
  end; { der Zeitauswertung }
ende:
  insertfile(stat.footer);
  close(outp);
  if (stat.dest<2) and (copy(stat.destname,1,2)='/¯') then
    sendzmsg(stfilename);
  logmem('proc exit statistics',-1);
end;


procedure copytotemp(ps:longint; size:longint);
{ Kopiert size Bytes von der Datei echostat.cfg in die Datei
 echostat.tmp, und zwar ab Position ps }
var
  f1,f2   : file;
  b       : array[0..1024] of byte;
  loadsize: word;
begin
  assign(f1,my_dircfg); reset(f1,1);
  assign(f2,my_dirtmp); reset(f2,1);
  if ioresult<>0 then rewrite(f2,1);
  seek(f2,filesize(f2)); seek(f1,ps);
  if size<0 then size:=filesize(f1)-ps;
  while (size>0) do begin
    if size>1024 then
      loadsize:=1024
    else
      loadsize:=size;
    blockread(f1,b[0],loadsize);
    blockwrite(f2,b[0],loadsize);
    dec(size,loadsize);
  end;
  close(f1); close(f2);
end;



function appendstatsetup(name:string):word;
{ H„ngt die Einstellungen der aktuellen Statistik an die Datei name an }
var
  f     : file;
  fs    : longint;
  mysize: word;
  ps    : pstrlist;
  i     : integer;
begin
  logmem('proc entry appendstatsetup',1);
  for i:=0 to dummysize1 do stat.dummy1[i]:=false;
  for i:=0 to dummysize2 do stat.dummy2[i]:=false;
  assign(f,name); reset(f,1);
  fs:=filesize(f); seek(f,fs);
  mysize:=sizeof(stat);
  ps:=stat.mybretter;
  while assigned(ps) do begin
    inc(mysize,length(ps^.s^)+1);
    ps:=ps^.next;
  end;
  blockwrite(f,mysize,2);
  blockwrite(f,stat,sizeof(stat));
  ps:=stat.mybretter;
  while assigned(ps) do begin
    blockwrite(f,ps^.s^[0],length(ps^.s^)+1);
    ps:=ps^.next;
  end;
  close(f);
  appendstatsetup:=mysize;
  logmem('proc exit appendstatsetup',-1);
end;



procedure savetostatfile(sps:longint);
var
  f    : file;
  i    : integer;
  ssize: word;
begin
  logmem('proc entry savetostatfile',1);
  assign(f,my_dirtmp); setfattr(f,0); erase(f); i:=ioresult;
  if sps=0 then
    appendstatsetup(my_dircfg)
  else begin
    assign(f,my_dircfg); reset(f,1); seek(f,sps); blockread(f,ssize,2);
    copytotemp(0,sps);
    appendstatsetup(my_dirtmp);
    copytotemp(sps+ssize+2,-1);
    assign(f,my_dircfg); setfattr(f,0); erase(f); i:=ioresult;
    assign(f,my_dirtmp);
    rename(f,my_dircfg);
  end;
  readconfigfile;
  logmem('proc exit savetostatfile',-1);
end;


function askautodiag:boolean;
var
  askdiag  : pdialog;
  pt1,pt2  : pstatictext;
  count    : integer;
  w1,w2,
  w3,w4,w3o: word;
  c        : chaR;
  label is_ok;
begin
  if autostatcount=0 then begin
    askautodiag:=true;
    exit
  end;
  askdiag:=new(pdialog,init(5,(screen_y-6) shr 1, 70,6,true));
  askdiag^.name:='Automatische Statistik';
  new(pt1,init(askdiag,2,2,'Statistik: '));
  new(pt1,init(askdiag,2,3,'[J]: Statistik berechnen    , [N]: Statistik berspringen'));
  new(pt1,init(askdiag,20,2,'')); pt1^.highlight:=true;
  new(pt2,init(askdiag,28,3,'')); pt2^.highlight:=true;
  askdiag^.paint;
  pt1^.settext(stat.myname);
  count:=autostatcount;
  gettime(w1,w2,w3o,w4);
  repeat
    gettime(w1,w2,w3,w4)
  until w3<>w3o;
  w3o:=w3;
  repeat
    pt2^.settext(str0(count,-1));
    gettime(w1,w2,w3,w4);
    if w3<>w3o then begin
      dec(count); w3o:=w3;
      pt2^.settext(str0(count,-1));
    end;
    if keypressed then begin
      c:=upcase(readkey);
      if (c='J') or (c=#13) then
        goto is_ok
      else if (c='N') then begin
        askdiag^.done;
        askautodiag:=false;
        exit;
      end;
    end else if (c=#27) then begin
      askdiag^.done;
      exitechostat(0);
    end;
  until count=0;
is_ok:
  askdiag^.done;
  askautodiag:=true;
end;


procedure autostat;
var
  p      : pstatlist;
  dist1  : longint;
  today  : tdatum;
  w1,w2,
  w3,w4  : word;
  i      : integer;
  k      : longint;
  askdiag: pdialog;
  pt1,pt2: pstatictext;
  count  : integer;
  label start;
begin
  logmem('proc entry autostat',1);
  getdate(w1,w2,w3,w4);
  with today do begin
    day:=w3; month:=w2; year:=w1;
  end;
start:
  readconfigfile;
  p:=statlst;
  while assigned(p) do begin
    loadstat(p^.ps);   { Statistik laden }
    if stat.automode then
      case stat.datemode of
        0: { freie Statistik }
          begin
            dist1:=dist(stat.date1,stat.date2);
            k:=dist(stat.date1,today);
            if (k>=stat.daydist+dist1) and askautodiag then begin
              scanallfiles;
              statistics;
              for i:=1 to dist1 do begin
                incdate(stat.date1); incdate(stat.date2);
              end;
              savetostatfile(p^.ps);
              goto start;
            end;
          end;
        1: { w”chentl. Statistik }
          begin
            k:=dist(stat.date1,today);
            if (k>=stat.daydist+6) and askautodiag then begin
              scanallfiles;
              statistics;
              for i:=1 to 7 do begin
                incdate(stat.date1); incdate(stat.date2);
              end;
              savetostatfile(p^.ps);
              goto start;
            end;
          end;
        2: { monatl. Statistik }
          begin
            dist1:=daymonth[stat.date1.month]+stat.daydist-1;
            stat.date1.day:=1;
            k:=dist(stat.date1,today);
            if (k>=dist1) and askautodiag then begin
              scanallfiles;
              statistics;
              inc(stat.date1.month);
              if stat.date1.month>12 then begin
                stat.date1.month:=1; inc(stat.date1.year);
              end;
              stat.date2:=stat.date1; stat.date2.day:=daymonth[stat.date2.month];
              savetostatfile(p^.ps);
              goto start;
            end;
          end;
      end;
    p:=p^.next;
  end;
  logmem('proc exit autostat',-1);
  exitechostat(0);
end;




procedure loadinifile;
var
  f       : text;
  s,e_name,
  e_value : string;
  p       : integer;
begin
  if debuglevel=1 then logwrite('------------ Contents of echostat.ini: -------------');
  p:=ioresult;
  dateformat1:=0; dateformat2:=0; autostatcount:=5;
  xp_dir:='c:\xpoint'; xp_auto_dir:='';
  assign(f,my_dir+'echostat.ini');
  reset(f);
  if ioresult<>0 then begin
    if debuglevel>0 then logwrite('File not found:echostat.ini. Using default');
    exit;
  end;
  while not eof(f) do begin
    readln(f,s);
    if debuglevel=1 then logwrite(s);
    trim(s);
    if (s[1]=';') or (s[1]='*') then continue;
    p:=pos('=',s);
    if p=0 then continue;
    e_name:=upstring(copy(s,1,p-1));
    e_value:=upstring(copy(s,p+1,255));
    if e_name='DATUMFORMAT1' then
      dateformat1:=strval(e_value)
    else if e_name='DATUMFORMAT2' then
      dateformat2:=strval(e_value)
    else if e_name='AUTOSTATWARTEZEIT' then
      autostatcount:=strval(e_value)
    else if e_name='XPOINT_DIR' then
      xp_dir:=e_value
    else if e_name='XPOINT_AUTO_DIR' then
      xp_auto_dir:=e_value
    else if debuglevel=1 then begin
      logwrite('  Unknown entry in echostat.ini:');
      logwrite('    '+s);
    end;
  end;
  close(f);
  if (dateformat1<0) or (dateformat1>2) then dateformat1:=0;
  if (dateformat2<0) or (dateformat2>2) then dateformat2:=0;
  if xp_auto_dir='' then xp_auto_dir:=xp_dir+'\'+'autoexec';
  strvalerror:=false;
  if debuglevel=1 then logwrite('----------------------------------------------------')
end;


procedure checkparam;
var
  w1,w2,
  w3,w4   : word;
  i,code  : integer;
  s,s1,
  errorstr: string;
  ft,fo   : text;
  label 1;
  procedure checksinglepar(s:string);
  begin
    if (s[1]<>'-') and (s[1]<>'/') then begin
      xp_dir:=s; exit;
    end;
    s:=copy(s,2,255); s[1]:=upcase(s[1]);
    if s[2]=':' then delete(s,2,1);
    if s[1]='S' then
      valdate(copy(s,2,255),stat.date1)
    else if s[1]='E' then
      valdate(copy(s,2,255),stat.date2)
    else if s[1]='T' then begin
      val(copy(s,2,255),stat.top_sender,code);
      if (code<>0) or (stat.top_sender<0) then
        txterror('Nach dem Parameter /t muá eine positive Zahl angegeben werden');
      with stat do begin
        top_empf:=top_sender;
        top_graph:=top_sender;
        top_betreff:=top_sender;
      end;
    end
    else if upstring(s)='AUTO' then
      autostatrun:=true
    else if upstring(s)='NOMOUSE' then
      mouse:=false
    else if s[1]='A' then
      stat.ibmchar:=false
    else if s[1]='B' then begin
      inc(stat.brettptr);
      newstatist:=false;
      addstrlist(stat.mybretter,upstring(copy(s,2,255)));
    end else if s[1]='M' then
      stat.datemode:=2
    else if s[1]='O' then begin
      s:=upstring(copy(s,2,255));
      stat.with_sender:=(pos('S',s)>0);
      stat.with_empf:=(pos('E',s)>0);
      stat.with_graph:=(pos('G',s)>0);
      stat.with_betreff:=(pos('B',s)>0);
      stat.with_time:=(pos('Z',s)>0);
      stat.with_bretter:=(pos('L',s)>0);
      stat.with_box:=(pos('D',s)>0);
    end
    else if (upstring(s)='LOG') then
      debuglevel:=1
    else if (upstring(s)='LOG1') then
      debuglevel:=2
    else if (s[1]='Z') then begin
      if length(s)=1 then
        stat.dest:=0
      else if s[2]='!' then begin
        stat.dest:=3;
        stat.destfile:=copy(s,3,255);
      end
      else begin
        stat.dest:=1; stat.destbrett:=copy(s,2,255);
      end;
    end
    else if (s[1]='H') or (s[1]='?') then
      errorstr:='?'
    else
      errorstr:='Unzul„ssiger Parameter /'+s;
  end {subprocedure};

  procedure breakline(sln:string);
  var
    p  : integer;
    par: string;
  begin
    trim(sln);
    if sln='' then exit;
    repeat
      p:=pos(' ',sln);
      if p=0 then
        par:=sln
      else begin
        par:=copy(sln,1,p-1); sln:=copy(sln,p+1,255);
      end;
      checksinglepar(par);
    until p=0;
  end {subprocedure};

begin
  getdate(w1,w2,w3,w4);
  debuglevel:=0;
  with stat do begin
    ibmchar:=true; datemode:=1;
    date1.day:=0; date2.day:=0;
    top_sender:=99999; top_empf:=99999; top_graph:=99999; top_betreff:=99999;
    with_sender:=true; with_empf:=true; with_graph:=true; with_betreff:=true;
    with_time:=false; betrefftext:='Statistik ($START)';
    hierarchien:=''; brettrealname:='';
    with_bretter:=false; mouse:=true;
    datemode:=0;
    mybretter:=nil;
    myname:='Neue Statistik';
  end;
  errorstr:=''; autostatrun:=false;
  loadinifile;
  interactive:=false;
  breakline(getenv('ECHOSTATPAR'));
  newstatist:= true;
  for i:=1 to paramcount do begin
    s:=paramstr(i);
    if (s[1]='/') or (s[1]='-') then begin
      if s[2]='@' then begin
        if s[3]=':' then
          s1:=copy(s,4,255)
        else
          s1:=copy(s,3,255);
        assign(ft,s1); reset(ft);
        if ioresult<>0 then begin
          errorstr:='Datei "'+s1+'" konnte nicht ge”ffnet werden';
          break;
        end;
        while not eof(ft) do begin
          readln(ft,s1); trim(s1);
          if s1[1]<>';' then breakline(s1);
        end;
        close(ft);
      end
      else
        checksinglepar(s);
    end
    else
      xp_dir:=s;
    if errorstr<>'' then break;
  end;
  if not assigned(stat.mybretter) and (errorstr='') then begin
    interactive:=true; stat.dest:=1;
  end;
  assign(fo,''); rewrite(fo);
  if errorstr<>'' then begin
    writeln(fo,'ECHOSTAT '+version+' (c) Hilmar Buchta 1996');
    writeln(fo,teamstr);
    writeln(fo);
    if errorstr<>'?' then begin
      writeln(fo,'FEHLER:');
      writeln(fo,errorstr);
      if debuglevel=1 then logwrite(right_align+'  error: '+errorstr);
      writeln(fo,'Verwenden Sie die Option /? fr Hilfe');
      close(fo);
      exitechostat(1);
    end;
    writeln(fo,'Verwendung:');
    writeln(fo,'echostat [/s:<datum>] [/e:<datum>] [/t:<Wert>] [<xp_dir>] [/a] [/m]');
    writeln(fo,'   [/O:[S][E][G][B][Z]] [/@:<name>] [/Z:[[!]<Name>] /b:<brettname>');
    writeln(fo,'   [/auto] <xp_dir>');
    writeln(fo,' /s:<datum>      Startdatum (Voreinstellung: heute)');
    writeln(fo,' /e:<datum>      Endedatum  (Voreinstellung: heute-6 Tage)');
    writeln(fo,' /b:<brettname>  Name des Brettes');
    writeln(fo,' /t:<Wert>       Nur die ersten <Wert> User bercksichtigen');
    writeln(fo,' /a              Nur Ascii-Zeichen zwischen 32 und 127 verwenden');
    writeln(fo,' /m              Statistik fr ganzen Monat erzeugen');
    writeln(fo,' /o              Angabe, welche Statistiken erzeugt werden sollen:');
    writeln(fo,'                 S: Sender, E:Empf„nger, G:Balkendiagramm, B:Betreff,');
    writeln(fo,'                 Z: Zeit, L: Bretter; Default: /o:SEGB');
    writeln(fo,' /@:<name>       Parameterdatei mit Namen <name> laden');
    writeln(fo,' /Z:[[!]<Name>]  Ausgabeziel festlegen (siehe Doku)');
    writeln(fo,' /auto           Automatische Statistiken (siehe Doku)');
    writeln(fo,' /nomouse        Mausuntersttzung deaktivieren');
    writeln(fo,' <xp_dir>        Pfad zum Crosspoint Verzeichnis');
    writeln(fo,''); writeln(fo,'Beispiel:');
    writeln(fo,'echostat /s:1.1.95 /b:black.chat /dialog');
    writeln(fo,'Keine Leerzeichen zwischen Optionen und Parametern der Optionen!');
    close(fo);
    exitechostat(1);
  end;
  close(fo);
  { Datum festlegen }
  if stat.date1.day=0 then begin
    getdate(w1,w2,w3,w4);
    with stat.date1 do begin
      day:=w3; month:=w2; year:=w1;
    end;
    stat.date2:=stat.date1;
    setbasedate(stat.date1);
    if stat.datemode<>2 then
      for i:=1 to 6 do decdate(stat.date1);
  end;
  if stat.date2.day=0 then begin
    stat.date2:=stat.date1;
    setbasedate(stat.date1);
    if stat.datemode<>2 then
      for i:=1 to 6 do incdate(stat.date2);
  end;
  setbasedate(stat.date1);
  if stat.datemode=2 then begin
    stat.date2:=stat.date1;
    stat.date1.day:=1; stat.date2.day:=daymonth[stat.date1.month];
  end;
end;



procedure init;
var
  p      : integer;
  srcr   : searchrec;
  diag   : pdialog;
  b_esc,
  b_setup: pbutton;
  st     : pstatictext;
  status : integer;
begin
  xp_dir:='';  userptr:=-1; receiveptr:=-1; subjptr:=-1; stat.brettptr:=-1;
  boxptr:=-1;
  right_align:='';
  HeapError:=@HeapErrorFunc;
  newstatist:=false;
  statlst:=nil;
  initdefaultstat;
  my_dir:=paramstr(0); p:=length(my_dir);
  while my_dir[p]<>'\' do dec(p);
  my_dir:=copy(my_dir,1,p);
  my_dirtmp:=my_dir+'echostat.tmp';
  my_dircfg:=my_dir+'echostat.cfg';
  helpfile:=my_dir+'echostat.hlp';
  openhelpindex;
  failmsgs:=0;
  totalfree:=maxavail;
  strvalerror:=false;
  user:=nil; receive:=nil; subject:=nil; brett:=nil;
  checkparam;
  logfilename:=my_dir+'echostat.log';
  if debuglevel>0 then begin
    initlogfile;
    logwrite('ECHOSTAT '+version+' Logfile'); logwrite('');
    logwrite('Video-Mem. Start: '+fstr(vidstart));
    logmem('app entry echostat',1);
  end;
  if (xp_dir[length(xp_dir)]='\') then
    xp_dir:=copy(xp_dir,1,length(xp_dir)-1);
  findfirst(xp_dir,anyfile,srcr);
  if (doserror<>0) or (srcr.attr and Directory=0) then begin
    messagebox('Fehler','Verzeichnis '+#13+xp_dir+#13+'konnte nicht gefunden werden.'
      +#13+'šberprfen Sie die Einstellungen in echostat.ini');
    halt(1);
  end;
  findfirst(xp_auto_dir,anyfile,srcr);
  if (doserror<>0) or (srcr.attr and Directory=0) then begin
    messagebox('Fehler','Verzeichnis '#13+'"'+xp_auto_dir+'"'+#13'konnte nicht gefunden werden.'
      +#13+'šberprfen Sie die Einstellungen in echostat.ini');
    halt(1);
  end;
  if xp_dir<>'' then xp_dir:=xp_dir+'\';
  if autostatrun then autostat;
end;



procedure brettauswahl;
var
  diag      : pdialog;
  lst       : plistbox;
  event     : tevent;
  b_ok,
  b_esc,
  b_back    : pbutton;
  p         : pstrlist;
  status    : integer;
  { Variablen zum Einlesen der bretter.db1 }

  pbrett,
  ptemp     : pbrettinfo;
  ptmpptr   : ^pointer;
  pstrptr,ps: pstrlist;
  changed   : boolean;
  ysize     : integer;
begin
  logmem('diag entry brettauswahl',1);
  ysize:=screen_y-3;
  new(diag,init(5,1+(screen_y-ysize) shr 1,70,ysize,true));
  diag^.name:='Echostat Brettauswahl ['+stat.myname+']';
  diag^.help_id:='NEW_STAT';
  new(lst,init(diag,1,1,68,ysize-4,0));
  new(b_ok,init(diag,8,ysize-3,10,'&Ok',kbalto));
  new(b_back,init(diag,27,ysize-3,12,'&Zurck',kbaltz));
  new(b_esc,init(diag,50,ysize-3,11,'A&bbruch',kbaltb));
  lst^.lst:=bretterlist;
  pstrptr:=bretterlist; lst^.max:=0;
  while assigned(pstrptr) do begin
    inc(lst^.max); pstrptr:=pstrptr^.next;
  end;
  diag^.addacc(kbreturn,kbreturn,b_ok);
  diag^.paint;
  lst^.showlistentries(true);

  repeat
    waitevent(event);
    diag^.handleevent(event);
    if (b_ok^.waspressed) then
      diag^.mystatus:=dg_ok
    else if (b_esc^.waspressed) then
      diag^.mystatus:=dg_exit
    else if assigned(b_back) and (b_back^.waspressed) then
      diag^.mystatus:=1000;
  until (diag^.mystatus<>dg_run);
  waitleftrelease;

  p:=lst^.lst;
  stat.mybretter:=nil;
  stat.brettptr:=-1;
  while assigned(p) do begin
    if p^.marked then begin
      inc(stat.brettptr);
      addstrlist(stat.mybretter,p^.s^);
    end;
    p:=p^.next;
  end;
  if stat.brettptr<0 then begin
    p:=lst^.getlstptr(lst^.cursor);
    if assigned(p) then begin
      stat.brettptr:=0; new(stat.mybretter);
      stat.mybretter^.s:=p^.s; stat.mybretter^.next:=nil; p^.marked:=true;
    end;
  end;
  lst^.lst:=nil;
  status:=diag^.mystatus;
  dispose(diag,done);
  logmem('diag exit brettauswahl',-1);
  if status=1000 then begin
    dialogstatus:=-1; exit;
  end;
  if status=dg_exit then begin
    putkey(#27); exitechostat(1);
  end;
  if stat.brettptr<0 then
    criterror('Es wurden keine Bretter gefunden','brettauswahl()');
  dialogstatus:=1;
end;


procedure savethisstatistic;
var
  diag  : pdialog;
  b_ok,
  b_esc : pbutton;
  p_inp : pinput;
  p_lst : plistbox;
  ts    : pstatictext;
  p     : pstatlist;
  status: integer;
  name  : string;
  sps   : longint;
  ssize : word;
  i     : integer;
  f     : file;
  label 1, exit_save;
begin
  logmem('diag entry savethisstatistic',1);
  new(diag,init(15,(screen_y-15) shr 1,50,15,true));
  diag^.name:='Statistik speichern';
  new(ts,init(diag,2,2,'Geben Sie einen Namen fr die Statistik ein'));
  new(p_inp,init(diag,2,4,46,0)); p_inp^.maxlen:=50;
  if stat.myname<>'' then p_inp^.s:=stat.myname;
  if assigned(statlst) then begin
    new(p_lst,init(diag,2,5,46,6,0));
    p_lst^.inpbox:=p_inp;
    p:=statlst;
    while assigned(p) do begin
      p_lst^.add(p^.myname); p:=p^.next;
    end;
  end
  else begin
    p_lst:=nil;
    new(ts,init(diag,3,7,'Bislang wurden keine Statistiken'));
    new(ts,init(diag,3,8,'gespeichert.'));
  end;
  new(b_ok,init(diag,3,12,14,'&Ok',kbalto));
  new(b_esc,init(diag,32,12,14,'&Abbruch',kbalta));
  diag^.paint;
  if p_inp^.s='' then
    diag^.setfocus(p_inp)
  else
    diag^.setfocus(b_ok);

1:
  diag^.rundialog(b_ok,b_esc);
  status:=diag^.mystatus;
  if status=dg_exit then goto exit_save;
  name:=p_inp^.s; trim(name);
  if name='' then goto exit_save;
  stat.myname:=name;
  p:=statlst;
  while assigned(p) do begin
    if p^.myname=name then break;
    p:=p^.next;
  end;
  if assigned(p) then begin
    { Name existiert bereits, Dialog hierfr anzeigen (fehlt noch)
    hier kann evtl. ein goto 1; kommen }
    sps:=p^.ps; ssize:=p^.size;
  end
  else begin
    { Daten werden an das Ende der cfg-Datei angeh„ngt }
    ssize:=0; sps:=0;
  end;
  savetostatfile(sps);
exit_save:
  dispose(diag,done);
  logmem('diag exit savethisstatistic',-1);
end;


function datevalidate(var s:string):boolean; far;
var
  d: tdatum;
begin
  if not valdate(s,d) then begin
    messagebox('Fehler','Das eingegebene Datum ist ungltig');
    datevalidate:=false;
    exit;
  end;
  s:=strdate(d,0); datevalidate:=true;
end;

function topvalidate(var s:string):boolean; far;
var
  l: longint;
  c: integer;
begin
  trim(s);
  val(s,l,c);
  if c<>0 then begin
    if upcase(s[1])='A' then
      l:=-1
    else begin
      messagebox('Fehler','Der eingegebene Wert ist ungltig');
      topvalidate:=false; exit;
    end;
  end;
  if l<=0 then s:='alle';
  topvalidate:=true;
end;

function numvalidate(var s:string):boolean; far;
var
  i,c: integer;
begin
  trim(s);
  val(s,i,c);
  if c<>0 then begin
    messagebox('Fehler','Der eingegebene Wert ist ungltig');
    numvalidate:=false; exit;
  end;
  numvalidate:=true;
end;

function newfilevalidate(var s:string):boolean; far;
var f:file; i:integer;
begin
  s:=fexpand(s);
  assign(f,s); reset(f);
  i:=ioresult;
  if i=0 then begin
    messagebox('Warnung','Die gew„hlte Datei existiert'+#13+'bereits.'+#13
      +'Falls Sie keinen anderen Namen w„hlen'+#13+'wird diese Datei berschrieben');
    close(f); newfilevalidate:=false;
    exit;
  end
  else if i=3 then begin
    messagebox('Fehler','Der angegebene Pfad ist ungltig'+#13+
      'Bitte w„hlen Sie einen anderen Namen');
    newfilevalidate:=false;
    exit;
  end;
  newfilevalidate:=true;
end;


function fileexistvalidate(var s:string):boolean; far;
var
  f: file;
begin
  trim(s);
  if s='' then exit;
  s:=fexpand(s);
  assign(f,s); reset(f,1);
  if ioresult=0 then begin
    close(f); fileexistvalidate:=true;
  end
  else begin
    messagebox('Warnung','Die angegebene Datei existiert nicht');
    fileexistvalidate:=false;
  end;
end;


procedure specialoption;
var
  diag  : pdialog;
  b_ok,
  b_esc : pbutton;
  s_auto: pswitch;
  ts    : pstatictext;
  inp1,
  inp2,
  inp3,
  inp4,
  inp5,
  inp6  : pinput;
  c     : integer;
begin
  logmem('diag entry specialoption',1);
  new(diag,init(15,(screen_y-14) shr 1,50,14,true));
  diag^.name:='Spezielle Optionen';
  diag^.help_id:='SPECIAL';
  new(s_auto,init(diag,2,2,kbalta,' &automatisch versenden'));
  new(ts,init(diag,2,3,'&Sperrzeit :'));
  new(ts,init(diag,20,3,'Tage'));
  new(inp3,init(diag,15,3,4,kbalts));
  str(stat.daydist,inp3^.s); inp3^.validate:=numvalidate;
  inp3^.maxlen:=2;
  s_auto^.status:=stat.automode;
  new(ts,init(diag,2,5,'&Betreff    :'));
  new(ts,init(diag,2,6,'&Vorspann   :'));
  new(ts,init(diag,2,7,'&Nachspann  :'));
  new(ts,init(diag,2,8,'&Hierarchien:'));
  new(ts,init(diag,2,9,'&Brettnamen :'));
  new(inp4,init(diag,16,5,33,kbaltb)); inp4^.s:=stat.betrefftext;
  inp4^.maxlen:=50;
  new(inp1,init(diag,16,6,33,kbaltv)); inp1^.s:=stat.header;
  inp1^.validate:=fileexistvalidate; inp1^.maxlen:=128;
  new(inp2,init(diag,16,7,33,kbaltn)); inp2^.s:=stat.footer;
  inp2^.maxlen:=128;
  inp2^.validate:=fileexistvalidate;
  new(inp5,init(diag,16,8,33,kbalth));
  inp5^.s:=stat.hierarchien; inp5^.maxlen:=255;
  new(inp6,init(diag,16,9,33,kbaltb));
  inp6^.s:=stat.brettrealname; inp6^.maxlen:=50;
  new(b_ok,init(diag,3,11,10,'&Ok',kbalto));
  new(b_esc,init(diag,35,11,10,'A&bbruch',kbaltb));
  diag^.paint; diag^.setfocus(s_auto);
  diag^.rundialog(b_ok,b_esc);
  if diag^.mystatus<>dg_exit then begin
    val(inp3^.s,stat.daydist,c);
    if c<>0 then stat.daydist:=3;
    stat.header:=inp1^.s;
    stat.footer:=inp2^.s;
    stat.betrefftext:=inp4^.s;
    stat.automode:=s_auto^.status;
    stat.hierarchien:=inp5^.s;
    stat.brettrealname:=inp6^.s;
  end;
  dispose(diag,done);
  logmem('diag exit specialoption',-1);
end;

procedure setit(var p:pinput; l:longint);
begin
 if l>=20000 then
   p^.s:='alle'
 else
   str(l,p^.s);
 p^.maxlen:=5; p^.validate:=topvalidate;
end;

procedure topdialog;
var
  diag  : pdialog;
  i1,
  i2,
  i3,
  i4,
  i5,
  i6    : pinput;
  b_ok,
  b_esc : pbutton;
  status,
  c     : integer;
begin
  logmem('diag entry topdialog',1);
  new(diag,init(47,(screen_y-19) shr 1+2,20,8,true)); diag^.name:='';
  diag^.help_id:='TOP_TEN';
  with stat do begin
    new(i5,init(diag,1,1,6,0)); setit(i5,top_bretter);
    new(i6,init(diag,1,2,6,0)); setit(i6,top_box);
    new(i1,init(diag,1,3,6,0)); setit(i1,top_sender);
    new(i2,init(diag,1,4,6,0)); setit(i2,top_empf);
    new(i3,init(diag,1,5,6,0)); setit(i3,top_graph);
    new(i4,init(diag,1,6,6,0)); setit(i4,top_betreff);
    new(b_ok,init(diag,8,1,10,'&Ok',kbalto));
    new(b_esc,init(diag,8,3,10,'&Abbruch',kbalta));
  end;
  diag^.paint;
  diag^.rundialog(b_ok,b_esc);
  status:=diag^.mystatus;
  if status=dg_ok then begin
    val(i1^.s,stat.top_sender,c);
    if stat.top_sender<=0 then stat.top_sender:=20000;
    val(i2^.s,stat.top_empf,c);
    if stat.top_empf<=0 then stat.top_empf:=20000;
    val(i3^.s,stat.top_graph,c);
    if stat.top_graph<=0 then stat.top_graph:=20000;
    val(i4^.s,stat.top_betreff,c);
    if stat.top_betreff<=0 then stat.top_betreff:=20000;
    val(i5^.s,stat.top_bretter,c);
    if stat.top_bretter<=0 then stat.top_bretter:=20000;
    val(i6^.s,stat.top_box,c);
    if stat.top_box<=0 then stat.top_box:=20000;
  end;
  dispose(diag,done);
  logmem('diag exit topdialog',-1);
end;


procedure optionen;
var diag: pdialog;
    dt  : pstatictext;
    df  : pstaticframe;
    dinp1,dinp2,dinp3,dinp4             : pinput;
    dr1,dr2,dr3,dr21,dr22,dr23,dr24     : pradio;
    ds0,ds1,ds2,ds3,ds4,ds5,ds6,ds7     : pswitch;
    b_ok,b_esc,b_opt,b_save,b_back,b_top: pbutton;
    dates1,dates2: string;
    i,status     : integer;
    brtlst: psubbox;
    ptemp : pstrlist;
    event : tevent;
  label 1;
begin
  logmem('diag entry optionen',1);
  overwrite:=true;
  if stat.destbrett='' then stat.destbrett:=stat.mybretter^.s^;
  new(diag,init(3,(screen_y-19) shr 1,70,19,true));
  diag^.name:='Echostat Optionen ['+stat.myname+']';
  diag^.help_id:='OPT_START';
  new(df,init(diag,2,2,22,3)); df^.name:='&Start';
  new(dinp1,init(diag,7,3,12,kbalts));
  dinp1^.maxlen:=10; dates1:=strdate(stat.date1,0); dinp1^.s:=dates1;
  dinp1^.validate:=datevalidate;
  new(df,init(diag,2,6,22,5)); df^.name:='&Ende';
  new(dr1,init(diag,3,7,0,'bis'));
  new(dr1^.nradio,init(diag,3,8,0,'ganze Woche')); dr2:=dr1^.nradio;
  new(dr2^.nradio,init(diag,3,9,0,'ganzer Monat')); dr3:=dr2^.nradio;
  dr3^.nradio:=dr1;
  diag^.addacc(kbalte,0,dr1);
  new(dinp2,init(diag,11,7,12,0)); dinp2^.myswitch:=dr1;
  dinp2^.maxlen:=10; dates2:=strdate(stat.date2,0); dinp2^.s:=dates2;
  dinp2^.validate:=datevalidate;
  new(df,init(diag,26,2,23,10)); df^.name:='O&ptionen';
  new(ds0,init(diag,27,3,0,'Brettbersicht')); ds0^.status:=stat.with_bretter;
  new(ds7,init(diag,27,4,0,'Boxbersicht')); ds7^.status:=stat.with_box;
  new(ds1,init(diag,27,5,0,'Sender')); ds1^.status:=stat.with_sender;
  new(ds2,init(diag,27,6,0,'Empf„nger')); ds2^.status:=stat.with_empf;
  new(ds3,init(diag,27,7,0,'Diagramm')); ds3^.status:=stat.with_graph;
  new(ds4,init(diag,27,8,0,'Betreffs')); ds4^.status:=stat.with_betreff;
  new(ds6,init(diag,27,9,0,'Zeitauswertung')); ds6^.status:=stat.with_time;
  new(ds5,init(diag,27,10,0,'IBM Zeichen')); ds5^.status:=stat.ibmchar;
  diag^.addacc(kbaltp,0,ds1);
  new(df,init(diag,2,12,47,6)); df^.name:='&Ausgabeziel';
  new(dr21,init(diag,3,13,0,'Brett ¯Statistik'));
  new(dr21^.nradio,init(diag,3,14,0,'Brett')); dr22:=dr21^.nradio;
  new(dr22^.nradio,init(diag,3,15,0,'Lister')); dr23:=dr22^.nradio;
  new(dr23^.nradio,init(diag,3,16,0,'Datei')); dr24:=dr23^.nradio;
  dr24^.nradio:=dr21;
  diag^.addacc(kbalta,0,dr21);
  new(dinp3,init(diag,14,14,34,0)); dinp3^.myswitch:=dr22;
  dinp3^.s:=stat.destbrett; dinp3^.maxlen:=128;
  new(dinp4,init(diag,14,16,34,0)); dinp4^.myswitch:=dr24;
  dinp4^.s:=stat.destfile; dinp4^.validate:=newfilevalidate;
  dinp4^.maxlen:=128;
  new(b_ok,init(diag,52,3,13,'&GO!',kbaltg));
  new(b_back,init(diag,52,5,13,'&Zurck',kbaltz));
  new(b_opt,init(diag,52,7,13,'Spezia&l',kbaltl));
  new(b_save,init(diag,52,9,13,'Spe&ichern',kbalti));
  new(b_top,init(diag,52,11,13,'&Top',kbaltt));
  new(b_esc,init(diag,52,16,13,'A&bbruch',kbaltb));
  new(brtlst,init(dinp3,6));
  brtlst^.lst:=bretterlist; brtlst^.max:=0;
  brtlst^.x:=diag^.x+1; brtlst^.dx:=diag^.dx-2;
  brtlst^.dy:=screen_y-(diag^.y+diag^.dy)+3;
  if brtlst^.dy>10 then brtlst^.dy:=10;
  ptemp:=brtlst^.lst;
  while assigned(ptemp) do begin
    inc(brtlst^.max); ptemp:=ptemp^.next;
  end;
  diag^.setfocus(dinp1);
  diag^.paint;
  dr21^.settrue;
  case stat.datemode of
    0:
      dr1^.settrue;
    1:
      dr2^.settrue;
    2:
      dr3^.settrue;
  end;
  case stat.dest of
    0:
      dr21^.settrue;
    1:
      dr22^.settrue;
    2:
      dr23^.settrue;
    3:
      dr24^.settrue;
  end;
1:
  diag^.mystatus:=dg_run; b_ok^.waspressed:=false;
  repeat
    waitevent(event);
    diag^.handleevent(event);
    if (b_ok^.waspressed) then
      diag^.mystatus:=dg_ok
    else if (b_esc^.waspressed) then
      diag^.mystatus:=dg_exit
    else if (b_back^.waspressed) then
      diag^.mystatus:=1000
    else if (b_save^.waspressed) then
      diag^.mystatus:=1010
    else if (b_top^.waspressed) then begin
      b_top^.waspressed:=false;
      topdialog;
    end
    else if (b_opt^.waspressed) then begin
      b_opt^.waspressed:=false;
      specialoption;
    end;
  until (diag^.mystatus<>dg_run);
  waitleftrelease;

  if diag^.mystatus=dg_exit then begin
    brtlst^.lst:=nil;
    diag^.done; putkey(#27); exitechostat(1);
  end;

  if not valdate(dinp1^.s,stat.date1) then begin
    messagebox('Fehler','Das Startdatum ist unzul„ssig');
    goto 1;
  end;
  if (not valdate(dinp2^.s,stat.date2)) and (dr1^.status) then begin
    messagebox('Fehler','Das Enddatum ist unzul„ssig');
    goto 1;
  end;

  setbasedate(stat.date1);
  if dr2^.status then begin
    stat.date2:=stat.date1; for i:=1 to 6 do incdate(stat.date2);
    stat.datemode:=1;
  end
  else if dr3^.status then begin
    stat.date1.day:=1; stat.date2:=stat.date1;
    stat.date2.day:=daymonth[stat.date2.month];
    stat.datemode:=2;
  end else
    stat.datemode:=0;
  stat.with_bretter:=ds0^.status;
  stat.with_sender:=ds1^.status;
  stat.with_empf:=ds2^.status;
  stat.with_graph:=ds3^.status;
  stat.with_betreff:=ds4^.status;
  stat.with_time:=ds6^.status;
  stat.ibmchar:=ds5^.status;
  stat.with_box:=ds7^.status;
  if dr21^.status then
    stat.dest:=0
  else if dr22^.status then
    stat.dest:=1
  else if dr23^.status then
    stat.dest:=2
  else if dr24^.status then
    stat.dest:=3;
  stat.destbrett:=dinp3^.s; stat.destfile:=dinp4^.s;
  status:=diag^.mystatus;
  if status=1010 then begin
    savethisstatistic;
    b_save^.waspressed:=false;
    diag^.name:='Echostat Optionen ['+stat.myname+']';
    diag^.paint;
    goto 1;
  end;
  brtlst^.lst:=nil;
  dispose(diag,done);
  logmem('diag exit optionen',-1);
  if status=1000 then
    dialogstatus:=0
  else
    dialogstatus:=2;
end;


procedure liesbrettliste;
{ Liest die Brettliste in die Listenvariable bretterlist ein }
var
  sn,errs:string;
  f:file;
  buffer:array[0..64] of byte;
  size:word;
  blocksize,namepos,intnrpos,flagspos,fieldnr:word;
  bp:ppuffer;
  pbrett,ptemp:pbrettinfo;
  ptmpptr:^pointer;
  i,status:integer;
  changed:boolean;
  bretter:pbrettinfo;
  int_nr,flags,count:longint;
  label 1,2;
begin
{ bretter.db1 einlesen, sortieren und zu lst hinzufgen }
  logmem('proc entry liesbrettliste',1);
  i:=ioresult;
  errs:='Fehler beim Einlesen der Brettstruktur.'+#13
    +'šberprfen Sie, ob das Crosspoint Home-'+#13
    +'verzeichnis richtig eingestellt wurde';
  assign(f,xp_dir+'bretter.db1'); reset(f,1);
  i:=ioresult;
  if i<>0 then
    criterror(errs,'Fehler beim ™ffnen von '+xp_dir+'bretter.db1');
  blockread(f,buffer[0],64);
  if (buffer[0]<>ord('D')) or (buffer[1]<>ord('B')) then
    criterror(errs,'Ge”ffnete Datei ist keine Datenbankdatei');
  fieldnr:=0; namepos:=$ffff; intnrpos:=$ffff; flagspos:=$ffff; blocksize:=0;
1:
  blockread(f,buffer[0],32);
  if buffer[0]=0 then goto 2;
  inc(fieldnr);
  move(buffer[0],sn[0],buffer[0]+1);
  if sn='BRETTNAME' then
    namepos:=blocksize
  else if sn='INDEX' then
    intnrpos:=blocksize
  else if sn='FLAGS' then
    flagspos:=blocksize;
  move(buffer[16],size,2);
  inc(blocksize,size);
  goto 1;
2:
  bretter:=nil;
  inc(blocksize);
  if (namepos=$ffff) then criterror(errs,'Kein Feld fr BRETTNAME gefunden');
  if (intnrpos=$ffff) then criterror(errs,'Kein Feld fr INDEX gefunden');
  if (flagspos=$ffff) then criterror(errs,'Kein Feld fr FLAGS gefunden');
  seek(f,65+fieldnr*32);
  getmem(pointer(bp),blocksize);
  count:=0;
  while not eof(f) do begin
    blockread(f,bp^[0],blocksize);
    move(bp^[namepos+2],sn[1],bp^[namepos]);
    sn[0]:=chr(bp^[namepos]-1);
    move(bp^[intnrpos],int_nr,4);
    move(bp^[flagspos],flags,4);
    if ((int_nr<>0) or (flags<>0)) and
      ((copy(sn,1,2)<>'/T') or (length(sn)>3)) then begin
      inc(count);
      new(pbrett);
      getmem(pointer(pbrett^.s),length(sn)+4); pbrett^.s^:=sn;
      pbrett^.int_nr:=int_nr; pbrett^.flags:=flags;
      pbrett^.next:=bretter; bretter:=pbrett;
    end;
  end;
  status:=ioresult;
  logmem('total areas: '+fstr(count),0);
  close(f);
  dispose(pointer(bp));
  repeat changed:=false;
    ptmpptr:=@bretter;
    pbrett:=bretter;
    while assigned(pbrett) and assigned(pbrett^.next) do begin
      if pbrett^.int_nr>pbrett^.next^.int_nr then begin
        ptmpptr^:=pbrett^.next;
        ptemp:=pbrett^.next;
        pbrett^.next:=pbrett^.next^.next;
        ptemp^.next:=pbrett;
        changed:=true;
      end;
      ptmpptr:=@pbrett^.next; pbrett:=pbrett^.next;
    end;
  until not changed;
  pbrett:=bretter;
  bretterlist:=nil;
  while assigned(pbrett) do begin
    addstrlist(bretterlist,pbrett^.s^);
    ptemp:=pbrett;
    dispose(
    pointer(pbrett));
    pbrett:=ptemp^.next;
  end;
  logmem('proc exit liesbrettliste',-1);
end;


procedure renamestatistic(s:string);
var
  p:pstatlist;
  diag:pdialog;
  ts:pstatictext;
  pinp:pinput;
  b_ok,b_esc:pbutton;
  status:integer;
  name:string;
  position:longint;
begin
  logmem('diag entry renamestatistic',1);
  p:=statlst;
  while assigned(p) and (s<>p^.myname) do p:=p^.next;
  if not assigned(p) then exit;
  position:=p^.ps; loadstat(p^.ps);
  new(diag,init(15,(screen_y-9) shr 1,50,9,true));
  diag^.name:='Statistik umbennenen';
  new(ts,init(diag,3,2,'Alter Name :  '+stat.myname));
  new(ts,init(diag,3,4,'Neuer Name :'));
  new(pinp,init(diag,16,4,32,0)); pinp^.s:=stat.myname;
  new(b_ok,init(diag,4,6,10,'&Ok',kbalto));
  new(b_esc,init(diag,30,6,10,'&Abbruch',kbalta));
  diag^.paint;
  diag^.rundialog(b_ok,b_esc);
  status:=diag^.mystatus; name:=pinp^.s;
  diag^.done;
  logmem('diag exit renamestatistic',-1);
  if (status=dg_exit) or (name='') then exit;
  { Existiert der Name schon ? }
  p:=statlst;
  while assigned(p) and (name<>p^.myname) do p:=p^.next;
  if assigned(p) then
    messagebox('Fehler','Der gew„hlte Name existiert bereits.')
  else begin
    stat.myname:=name;
    savetostatfile(position);
  end;
end;




procedure choosestat;
var
  diag:pdialog;
  ts:pstatictext;
  lst:plistbox;
  b_ok,b_neu,b_kill,b_esc,b_ren:pbutton;
  event:tevent;
  status:integer;
  p:pstatlist;
  pdummy:pinput;
  f:file;
  i:integer;
  label 1,2;
begin
  logmem('diag entry choosestat',1);
2:
  new(diag,init(10,(screen_y-18) shr 1,60,18,true));
  diag^.name:='Echostat Statistikauswahl';
  diag^.help_id:='MAIN_WINDOW';
  new(ts,init(diag,2,2,'Echostat '+version+',  (c) 1996 Hilmar Buchta'));
  new(ts,init(diag,2,3,teamstr));
  new(ts,init(diag,2,4,'Dieses Programm ist Freeware'));
  if helpenabled then new(ts,init(diag,4,17,' F1 Hilfe '));
  p:=statlst;
  if not assigned(p) then begin
    new(ts,init(diag,4,8,'Keine Statistiken'));
    new(ts,init(diag,4,9,'gespeichert.'));
    new(ts,init(diag,4,10,'W„hlen Sie den'));
    new(ts,init(diag,4,11,'Schalter <Neu>'));
    lst:=nil; pdummy:=nil;
  end
  else begin
    new(lst,init(diag,1,6,40,11,0));
    new(pdummy,init(nil,diag^.x+1,diag^.y+5,40,0)); pdummy^.mydiag:=diag;
    lst^.inpbox:=pdummy;
    while assigned(p) do begin
      lst^.add(p^.myname); p:=p^.next;
    end;
  end;
  if assigned(statlst) then begin
    new(b_ok,init(diag,45,5,10,'&Ok',kbalto));
    new(b_kill,init(diag,45,7,10,'&L”schen',kbaltl));
    new(b_ren,init(diag,45,9,10,'&Name',kbaltn));
  end
  else begin
    b_ok:=nil; b_kill:=nil; b_ren:=nil;
  end;
  new(b_neu,init(diag,45,11,10,'N&eu',kbalte));
  new(b_esc,init(diag,45,13,10,'&Abbruch',kbalta));
  diag^.paint;
  if assigned(pdummy) then pdummy^.paint(true);
  hidecursor;
1:
  diag^.mystatus:=dg_run;
  repeat
    waitevent(event);
    diag^.handleevent(event);
    if assigned(b_ok) and (b_ok^.waspressed) then begin
      b_ok^.waspressed:=false;
      if pdummy^.s='' then
        messagebox('Fehler','Keine Statistik gew„hlt')
      else begin
        p:=statlst;
        while assigned(p) and (pdummy^.s<>p^.myname) do p:=p^.next;
        if assigned(p) then begin
          loadstat(p^.ps);
          diag^.mystatus:=dg_ok;
        end;
      end;
    end
    else if (b_esc^.waspressed) then
      diag^.mystatus:=dg_exit
    else if (b_neu^.waspressed) then
      diag^.mystatus:=1000
    else if assigned(b_ren) and (b_ren^.waspressed) then begin
      b_ren^.waspressed:=false;
      if pdummy^.s='' then
        messagebox('Fehler','Keine Statistik gew„hlt')
      else begin
        renamestatistic(pdummy^.s);
        readconfigfile; diag^.done; goto 2;
      end;
    end
    else if assigned(b_kill) and (b_kill^.waspressed) then begin
      { L”schen }
      b_kill^.waspressed:=false;
      if pdummy^.s='' then
        messagebox('Fehler','Keine Statistik gew„hlt')
      else begin
        p:=statlst;
        while assigned(p) and (pdummy^.s<>p^.myname) do p:=p^.next;
        if assigned(p) then begin
          { Hier wirds ernst }
          assign(f,my_dirtmp); setfattr(f,0); erase(f); i:=ioresult;
          copytotemp(0,p^.ps);
          copytotemp(p^.ps+p^.size+2,-1);
          assign(f,my_dircfg); setfattr(f,0); erase(f); i:=ioresult;
          assign(f,my_dirtmp);
          rename(f,my_dircfg);
          { Statistikliste aktualisieren }
          readconfigfile; diag^.done;
          goto 2;
        end;
      end;
    end;
  until (diag^.mystatus<>dg_run);
  waitleftrelease;
  status:=diag^.mystatus;
  diag^.done;
  logmem('diag exit choosestat',-1);
  if status=1000 then initdefaultstat;
  if status=dg_exit then begin
    if interactive then putkey(#27);
    exitechostat(1);
  end;
  dialogstatus:=0;
end;


procedure rundialog;
var
  scr:word;
begin
  logmem('proc entry rundialog',1);
  readconfigfile;
  if mouse then begin
    initmouse;
    scr:=(screen_y-1)*8;
    if mouseok then
      asm
        mov ax,0008h
        mov cx,0
        mov dx,scr
        int 33h
      end;
    showmouse;
  end;
  clrscr;
  write('  Lese Brettliste...');
  liesbrettliste;
  stat.destbrett:='';
  clrscr;
  if newstatist then
    dialogstatus:=-1
  else
    dialogstatus:=0;
  repeat
    case dialogstatus of
      -1:
         choosestat;
       0:
         brettauswahl;
       1:
         optionen;
    end;
  until dialogstatus=2;
  logmem('proc exit rundialog',-1);
end;


procedure runstatistic;
begin
  scanallfiles;
  statistics;
  if (stat.dest<>2) and interactive then
    putkey(#27); { Lister im interaktiven Modus schlieáen }
end;


begin
  init;
  if interactive then rundialog;
  runstatistic;
  exitechostat(0);
end.

{
  $Log: echostat.pas,v $
  Revision 1.2  2001/01/22 19:31:27  MH
  Erste Arbeiten an EchoStat:
  - /nomouse schaltet die Maus ab
  - divisions by zero fixed
  - Brettliste deaktiviert, da zum einen der Zeiger nicht sauber
    ist und zum anderen redudant (Bug muá aber trotzdem beseitigt werden)
  - Farbe zur besseren lesbarkeit von Gelb auf Blau ge„ndert

  Revision 1.1  2001/01/05 19:29:57  rb
  ECHOSTAT eingecheckt


}
