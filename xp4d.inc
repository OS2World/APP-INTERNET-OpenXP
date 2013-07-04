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
{ $Id: xp4d.inc,v 1.37 2001/07/29 23:29:28 MH Exp $ }

{ XP4.PAS - Anzeigeroutinen }


{ --- Zeile einlesen und anzeigen --- }

procedure brettform(var s:string; flags:byte; user:boolean);
var i : byte;
begin
  case brettanzeige of
    1 : s:=TopAllStr(s);
    2 : for i:=iif(user,1,2) to length(s) do
          s[i]:=LoCase(s[i]);
  end;
  if not user and (flags and 16<>0) and newsgroupdisp and (s[1]='A') and
     (cpos('/',s)>0)
  then begin
    if s[2]='/' then delete(s,2,1);
    for i:=3 to length(s) do
      if s[i]='/' then s[i]:='.';
  end else
  if newsgroupdisp and (pos('@',s)=0) and (cpos('/',s)>0) then begin
    if s[1]='1' then
      if userslash then
        delete(s,1,2)
      else
        delete(s,2,1)
    else
      exit;
    i:=pos('/', s);
    if i<>0 then s[i]:='@';
    if userslash then s:='1/'+s else s:='/'+s;
  end;
end;

procedure write_disp_line(y,p:shortint; show:boolean);
const hf : array[0..4] of char = ' +-A˘';
      uv : array[0..13] of char = ' !*'#19'z23456789#';
      ge : array[0..1] of char = '> ';
      wv : array[0..5] of char = ' cwwss';

var
    taus    : array[1..MsgFelderMax+UsrFelderMax] of string[81];
    tausc   : 0..MsgFelderMax+UsrFelderMax;
    HideAllDone,
    kuerzen : boolean;
    s,s0    : string[81];
    dat,edat: longint;
    sdat    : string[15];
    c       : string[3];
    s1,bet  : string[BetreffLen]; { bisher 70 (Stand 09/2000) }
    s2      : string[20];
    size    : longint;
    typ     : char;
    hzeit   : integer16;  { Haltezeit }
    pbox    : string[BoxNameLen];
    komm    : string[30];
    dadr,pw : char;
    ab,flags: byte;
    abc     : string[2];
    grnr    : longint;
    uflags  : byte;
    markc   : char;
    hd      : header;
    hds     : longint;
    pp      : byte;
    wvl     : byte;
    vert    : boolean;
    mnt     : longint;
    netztyp : byte;
    _brett  : string[5];
    t,m,j,d : rtlword;
    tempd: integer;
    fileatt : boolean;
    dflags  : string[20];
    fidoqwk : boolean;
    uv_anz  : integer;

    hflags,gelesen,unvers : byte;
    ulen,blen             : byte;

  function siz:string;
  begin
    if size<10000 then siz:=strsn(size,5)
    else
      if size<1024*1024 then
        siz:=strsn(size div 1024,4)+'K'
      else
        if size<1024*1024*1024 then
          siz:=strsn(size div (1024*1024),3)+'MB'
        else
          siz:=strsn(size div (1024*1024*1024),3)+'GB';
  end;

  function hz(i:integer):string;
  begin
    hz:=iifs(i=0,'   Ï',strsn(i,4));
  end;

  procedure formrfc;
  var i : byte;
  begin
    if not newsgroupdisp or (cpos('@',s)<>0) or (cpos('/',s)=0) then exit;
    if firstchar(s)='/' then delfirst(s);
    for i:=2 to length(s) do begin
      if s[i]='/' then s[i]:='.' else
      if s[i]=' ' then begin
        s:=left(s,i)+' '+mid(s,i+1);
        break;
      end;
    end;
  end;

begin  { __ Suchmarke }
  case aktdispmode of
   -1,0 : begin
            dbRead(bbase,'brettname',s);
            dbRead(bbase,'kommentar',komm);
            if left(s,3)='$/T' then begin
              if komm='' then
                dispbuf[y]^:='   '+dup(76,s[4])+' '
              else
                case trennkomm of
                  1 : dispbuf[y]^:='   '+komm+' '+dup(76-length(komm),s[4]);
                  2 : begin
                        dispbuf[y]^:='   '+dup((74-length(komm))div 2,s[4])+' '+
                                     komm+' ';
                        dispbuf[y]^:=dispbuf[y]^+dup(80-length(dispbuf[y]^),s[4]);
                      end;
                  3 : dispbuf[y]^:='   '+dup(75-length(komm),s[4])+' '+komm+' ';
                end;
              markflag[y]:=2;
              end
            else begin
              dbReadN(bbase,bb_LDatum,dat);
              dbReadN(bbase,bb_flags,flags);
              dbReadN(bbase,bb_pollbox,pbox);
              markflag[y]:=iif(UBmarked(dbRecno(bbase)),1,0);
              markc:=iifc(markflag[y]<>0,suchch,' ');
              brettform(s,flags,false);
              if not UserSlash and (s[1]<'A') then delete(s,2,1);
              if not dispext then begin
                case readmode of     { s. auch XP4.BRETTOK() }
                  0 : c:=markc+'  ';
                  1 : c:=markc+iifs(flags and 2<>0,#16' ','  ');
                else
                  c:=markc+iifs(not smdl(dat,readdate),#16' ','  ');
                end;
                if length(s)>43 then
                  if length(s)>70 then
                    dispbuf[y]^:=c+forms(copy(s,2,76),77)
                  else
                    dispbuf[y]^:=c+copy(s,2,70)+' '+forms(komm,77-length(s))
                else
                  dispbuf[y]^:=c+forms(copy(s,2,43),44)+forms(komm,33);
                end
              else begin
                dbReadN(bbase,bb_haltezeit,hzeit);
                dbReadN(bbase,bb_gruppe,grnr);
                dispbuf[y]^:=markc+iifc(dat<>0,' ','-')+iifc(flags and 8<>0,'X',' ')+
                             iifc(dbReadStr(bbase,'adresse')<>'',
                                  iifc(flags and 32=0,'*','O'),' ')+
                             iifc(odd(flags),'N',' ')+hz(hzeit)+'  '+
                             forms(pbox,9)+strsn(grnr,4)+' '+
                             forms(copy(s,2,37),38)+forms(komm,17);
                end;
              end;
          end;
    1,2,
    3,4 : begin { USERLISTE }

           { LÑngen:
             FLAGS   4
             ADRBUCH 2
             PBOX    9
             HZEIT   4
            }

            for tausc := 1 to UsrFelderMax do taus[tausc]:='';
            dbReadN(ubase,ub_username,s);
            dbReadN(ubase,ub_kommentar,komm);
            dbReadN(ubase,ub_adrbuch,ab);
            dbReadN(ubase,ub_userflags,uflags);
            abc:=iifc(ab<>0,'˚',' ')+iifc(odd(uflags),' ','#');
            dadr:=iifc(dbXsize(ubase,'adresse')>0,'*',' ');
            pw:=iifc((dbXsize(ubase,'passwort')>0) or
                     (dbReadInt(ubase,'codierer')=9),'P',' ');
            vert:=(uflags and 4<>0);
            dbReadN(ubase,ub_haltezeit,hzeit);

            { (F)lags }
            if vert then begin
              { Verteiler }
              s := vert_name(s);
              taus[pos('F',UsrFeldTausch)] := 'V   '; { Laenge 4 }
            end else
              taus[pos('F',UsrFeldTausch)] := abc+pw+dadr; { Laenge 4 }

            markflag[y]:=iif(UBmarked(dbRecno(ubase)),1,0);
            brettform(s,0,true);

            kuerzen := false;
            if dispext then begin
            { Anzeige/Spezial }
              kuerzen := true; { wir brauchen mehr platz, also Felder kuerzen }
              dbReadN(ubase,ub_pollbox,pbox);
              brettform(s,0,true);

              { (H)altezeit }
              taus[pos('H',UsrFeldTausch)] := '  '+hz(hzeit);

              { (B)OX }
              taus[pos('B',UsrFeldTausch)] := forms(pbox,9);
            end;

            { Falls (S)pezial EIN, dann mu· der folgende Resttext um
              10 bzw. 17 Zeichen gekÅrzt werden: }

            { Verteilername bzw. (A)dresse }
            taus[pos('A',UsrFeldTausch)]
              := Forms(s,
                   { Adresse vor Kommentar: beide kÅrzen, sonst nur Adresse }
                   iif(pos('K',UsrFeldTausch)>pos('A',UsrFeldTausch),
                     44-iif(kuerzen,9,0),
                     44-iif(kuerzen,17,0)
                   )
                 );

            { Kommentar }
            taus[pos('K',UsrFeldTausch)]
              := Forms(komm,
                   { Kommentar nur kÅrzen, wenn er hinter der Adresse steht }
                   iif(pos('K',UsrFeldTausch)<pos('A',UsrFeldTausch),
                     30,
                     30-iif(kuerzen,8,0)
                   )
                 );

            { Felder zusammenkopieren }
            tausc:=0; dispbuf[y]^:='';
            while (tausc<UsrFelderMax) do begin
              inc(tausc);
              if (taus[tausc]='') then continue; { Leere Felder Åbergehen }
              if (dispbuf[y]^<>'') then dispbuf[y]^:=dispbuf[y]^+' ';
              dispbuf[y]^:=dispbuf[y]^+taus[tausc];
            end;
            { Sicherheitshalber nochmal auf 80 Zeichen kÅrzen }
            dispbuf[y]^:=forms(dispbuf[y]^,80);

          end;
  10..12: begin { NACHRICHTENLISTE }
            for tausc := 1 to MsgFelderMax do taus[tausc]:='';
            dbReadN(mbase,mb_absender,s0);
            {dbReadN(mbase, mb_prioflags, mnt);}
            { Hervorhebung der Nachrichten bei hoher PrioritÑt }
            {PrioFlag[y] := (mnt and $1000 <> 0);}

              dbReadN(mbase, mb_flags, flags);
              userflag[y] := 0;          { Man muss PrioritÑten setzen... }
              flags := flags and 56;
              case flags of
                 8: userflag[y] := 2;    { Hîchste    }
                16: userflag[y] := 3;    { Hohe       }
                24: userflag[y] := 4;    { Niedrige   }
                32: userflag[y] := 5;    { Niedrigste }
              end;

            dbReadN(mbase,mb_netztyp,mnt);
            fileatt:=(mnt and $200<>0);
            netztyp:=mnt and $ff;
            uv_anz:=(mnt shr 16) and $ff;
            pp:=cpos('@',s0);
            fidoqwk:=(netztyp=nt_Fido) or (netztyp=nt_QWK);
            if ((netztyp=nt_Maus) or fidoqwk) and (pp>0) then
              if pos('#',s0)=0 then
                s:=left(s0,pp-1)+' @ '+mid(s0,pp+1)
              else begin
                readheader(hd,hds,true);
                s:=hd.realname;
              end
            else
              if showrealos and (dbReadStr(mbase,'name')<>'') and
                 ((dispmode<>11) or not markunversandt) then
                dbReadN(mbase,mb_name,s)
              else begin
                s:=s0;
                if (sabsender<>0) then begin
                  if right(s,4)='.ZER' then dec(byte(s[0]),4);
                  case sabsender of
                    1 : if pp=0 then s:=TopAllstr(s)
                        else s:=TopAllStr(left(s,pp-1))+'@'+copy(s,pp+1,length(s)-pp);
                    2 : if pp=0 then s:=TopAllstr(s)
                        else s:=TopAllStr(left(s,pp-1))+' @ '+copy(s,pp+1,length(s)-pp);
                    3 : if pp>0 then s:=left(s,pp-1);
                    4 : s:=TopAllStr(left(s,iif(pp>0,pp-1,length(s))));
                    5 : if pp>0 then s:=forms(left(s,pp-1),16)+' '+copy(s,pp+1,length(s)-pp);
                    6 : if pp=0 then s:=TopAllstr(s)
                        else s:=TopAllStr(forms(left(s,pp-1),16))+' '+copy(s,pp+1,length(s)-pp);
                  end;
                end;
              end;

            { Betreff aus dem Header holen }
            if LongBetr and (HideRe or HideMLHead) then begin
              readheader(hd,hds,true);
              s1:=hd.betreff;
            end else
            { Betreff aus der Datenbank holen }
            dbReadN(mbase,mb_betreff,s1);

            { Loop bis alle Re: etc. und [MLHeader] weg sind }
            repeat
              HideAllDone:=true;

              { Mailinglisten-Header ala [bla] aus Betreff filtern }
              if (HideMLHead) and {(dispmode<>11)} not dbEOF(bbase) and not dbBOF(bbase) then begin
                dbReadN(bbase,bb_kommentar,komm);
                if (komm<>'') and (pos('['+komm+']',s1)<>0) then begin
                  j:=pos('['+komm,s1);
                  t:=posn(']',s1,j+1);
                  if (j>0) and (t>j) and (pos(' ',copy(s1,j,t-j+1))=0) then begin
                    delete(s1,j,t-j+1);
                    s1:=trim(s1);
                    HideAllDone:=false           { weiter checken! }
                  end;
                end;
              end;

              { Re: und AW: aus Betreff filtern }
              if (HideRe) then begin
                bet:=ustr(s1);

                while (pos('RE:',bet)=1)
                  or (pos('WG:',bet)=1)
                  or (pos('AW:',bet)=1)
                  or (pos('ANTWORT:',bet)=1)
                  or (pos('FWD:',bet)=1)
                do begin
                  HideAllDone:=false;          { weiter checken! }
                  delete(s1,1,pos(':',s1));
                  s1:=trim(s1);
                  bet:=ustr(s1)
                end;

                while (pos('RE^',bet)=1) do begin
                  HideAllDone:=false;          { weiter checken! }
                  delete(s1,1,3);
                  while (length(s1)>0)
                    and (s1[1] in ['0'..'9']) do delete(s1,1,1);
                  if (pos(':',s1)=1) then delete(s1,1,1);
                  s1:=trim(s1);
                  bet:=ustr(s1)
                end
              end; { if (HideRe) then begin }

              { Doppelspaces lîschen }
              j:=pos('  ',s1);
              while (j>0) do begin
                delete(s1,j,1);
                j:=pos('  ',s1)
              end;

            until (HideAllDone);

            if (dispmode<>12) then begin
              { wird eh nochmal abgeschnitten, alt jeweils: s1:=left('-'+s1,40); }
              if (netztyp=nt_Maus) and (mnt and $100<>0) then
                s1:='-'+s1 else
              if ntKomkette(netztyp) and (mnt and $100<>0) and
                 (lstr(left(s1,3))<>'re:') and (left(s1,3)<>'Re^') then
                s1:='-'+s1;
            end;

            dbReadN(mbase,mb_OrigDatum,dat);
            if (dispmode=10) then
              dbReadN(mbase,mb_EmpfDatum,edat)
            else
              edat:=ixdat('6912310000');
            { Datum anzeigen }
            if (showmsgdatum) then begin
              s2:=fdat(longdat(dat));
              getdate(j,m,t,d);

              { MK 01/00, Y2K-Bug beseitigt }
              tempd := ival(copy(s2,7,2));
              if (tempd < 70) then inc(tempd, 2000) else inc(tempd, 1900);
              if abs(tempd*12+ival(copy(s2,4,2))-1-(j*12+m-1)) > 11 then
                sdat:=copy(s2,4,2)+'/'+copy(s2,7,2)
              else
                sdat:=left(s2,5);
              ulen:=25; blen:=36;
            { kein Datum anzeigen }
            end else begin
              sdat:=''; ulen:=27; blen:=40;
            end;
            if (dispmode=11) and MarkUnversandt then begin
              inc(ulen,5); dec(blen,5);
              readheader(hd,hds,true);
              if hd.wab<>'' then s:=hd.wab;
              pp:=cpos('@',s);
              s:=copy(s,pp+1,length(s)-pp);
              pp:=cpos('.',s);
              if pp>0 then s:=left(s,pp-1);
              if hd.real_box<>'' then s:=hd.real_box;
              if left(hd.empfaenger,length(TO_ID))=TO_ID then
                s:=forms(mid(hd.empfaenger,length(TO_ID)+1),ulen-length(s)-1)+' '+s
              else
                s:=forms(hd.empfaenger,ulen-length(s)-1)+' '+s;
              if hd.netztyp in [nt_UUCP,nt_PPP] then
                formrfc;
            end;
            dbReadN(mbase,mb_brett,_brett);
            pp:=iif(netztyp=nt_Maus,35,iif(fidoqwk,35,0));
            if (pp<>0) and (_brett[1]<>'$') and (blen>pp) then begin
              inc(ulen,blen-pp);
              blen:=pp;
            end;
            dbReadN(mbase,mb_Groesse,size);
            dbReadN(mbase,mb_unversandt,unvers);
            dbReadN(mbase,mb_Typ,typ);
            dbReadN(mbase,mb_flags,flags);
            if typ='T' then
              typ:=iifc((flags and 64<>0) and (size=0),'H',
                   iifc((flags and 128<>0) and (size=0),'R',
                   iifc(fileatt,'F',
                   iifc(flags and 4<>0,'M',' '))))
            else
            if (typ='B') and (size=0) then
              typ:=iifc(flags and 64<>0,'H',
                   iifc(flags and 128<>0,'R','B'));
            wvl:=(unvers and 12) div 4;

            if (wvl=0) and (mnt and $4000<>0) then begin
             wvl:=5;
             {if (flags and 1<>0) then wvl:=5;} { 'S' - 'good' signierte Nachricht }
             {if (flags and 2<>0) then wvl:=4;} { 's' - 'bad' signierte Nachricht }
            end;

            dbReadN(mbase,mb_Halteflags,hflags);
            dbReadN(mbase,mb_gelesen,gelesen);
            if unvers and 32<>0 then
              unvers:=4
            else
              unvers:=unvers and 1 + (unvers and 16) div 8;
            if (unvers=1) and (uv_anz>1) then unvers:=min(uv_anz,10)+3;
            if (hflags=0) and (unvers=0) and (abhdatum<>0) and
               smdl(edat,abhdatum)
            then
              hflags:=4;
            if dispmode=11 then
              markflag[y]:=1
            else
              markflag[y]:=iif(msgmarked,1,0);
            dflags:=iifc(markflag[y]<>0,suchch,' ')+ge[gelesen]+hf[hflags]+
                    uv[unvers]+wv[wvl]+typ;

            if fidoqwk and (dispmode=10) and
               dispfto and (_brett[1]='A') then begin
              if cpos('@',s)>0 then s[0]:=chr(cpos('@',s)-1);
              dbReadN(mbase,mb_name,s0);

              { (F)lags }
              taus[pos('F',MsgFeldTausch)] := dflags;

              { (G)roesse }
              taus[pos('G',MsgFeldTausch)] := siz;

              { (D)atum }
              taus[pos('D',MsgFeldTausch)] := iifs(showmsgdatum,sdat,'');

              { (A)bsender }
              taus[pos('A',MsgFeldTausch)] := forms(s,19);

              { (E)mpfaenger }
              taus[pos('E',MsgFeldTausch)] := forms(s0,19);

              { (B)etreff }
              taus[pos('B',MsgFeldTausch)] := forms(s1,iif(showmsgdatum,21,27));

              userflag[y]:=IIf((HighlightName=ustr(s0)) or (mnt and $1000<>0),1,0);

            end else begin

              { Kommentarbaum }
              if dispmode=12 then begin
                s:=' '+BaumBlatt(baumdispofs,ulen+blen,bezpos,s,s1);
                if (sdat<>'') then sdat:=' '+sdat;
                dispbuf[y]^:=forms(dflags+siz+sdat+' '+s,80);
              end else begin

              { (F)lags }
              taus[pos('F',MsgFeldTausch)] := dflags;

              { (G)roesse }
              taus[pos('G',MsgFeldTausch)] := siz;

              { (D)atum }
              taus[pos('D',MsgFeldTausch)] := iifs(showmsgdatum,sdat,'');

              { (A)bsender }
              taus[pos('A',MsgFeldTausch)] := forms(s,ulen);

              { (B)etreff }
              taus[pos('B',MsgFeldTausch)] := forms(s1,blen-1);

              end;

              if fidoqwk and (_brett[1]='A') and
                 (HighlightName=ustr(dbReadStr(mbase,'name'))) then
                userflag[y] := 1
              else
                if (cpos('@',dispspec)>0) and
                  (ustr(left(s0,40))=ustr(copy(dispspec,2,min(40,length(s0)))))
                then userflag[y] := 1
                else
                if mnt and $1000 <> 0 then userflag[y]:=1;
            end;

            { Kommentarbaum-Ausgabe schon fertig, fuer andere dispmodes
              muss sie noch zusammenkopiert werden: }
            if (dispmode<>12) then begin
              { Felder zusammenkopieren }
              tausc:=0; dispbuf[y]^:='';
              while (tausc<MsgFelderMax) do begin
                inc(tausc);
                if (taus[tausc]='') then continue; { Leere Felder Åbergehen }
                if (dispbuf[y]^<>'') then dispbuf[y]^:=dispbuf[y]^+' ';
                dispbuf[y]^:=dispbuf[y]^+taus[tausc];
              end;
              { Sicherheitshalber nochmal auf 80 Zeichen kÅrzen }
              dispbuf[y]^:=forms(dispbuf[y]^,80);
            end;
          end;
     20 : dispbuf[y]^:=AutoShow;
  end;
  if show then begin
    lcol(y,p);
    moff;
    fwrt(1,3+y+ya,dispbuf[y]^);
    mon;
    end;
  disprec[y]:=dbRecNo(dispdat);
  Do_XPhilite(false);
end;

procedure RedispLine;
begin
  write_disp_line(p,p,true);
end;


{$IFNDEF FPC }
  {$B+}
{$ENDIF }
procedure display(p:shortint);
var i,j : integer;
    mi  : shortint;
begin
  i:=1;
  fillchar(disprec,sizeof(disprec),0);
  mi:=dbGetIndex(mbase);
  if (dispmode=11) or (dispmode=12) then dbSetIndex(mbase,0);
  repeat
    write_disp_line(i,p,true);
    inc(i);
  until (i>gl) or not Forth;
  dbSetIndex(mbase,mi);
  if i<=gl then begin
    if dispmode<10 then attrtxt(col.colbretter)
    else attrtxt(col.colmsgs);
    clwin(1,screenwidth,3+i+ya,3+ya+gl);
    for j:=i to gl do dispbuf[j]^:='';
    end;
  aufbau:=false;
  if dispmode=12 then xaufbau:=false;
  mdisplay:=false;
end;
{$IFNDEF FPC }
  {$B-}
{$ENDIF }

procedure redisplay(p:shortint);
var i,bp : integer;
begin
  i:=1;
  bp:=bezpos;
  while (i<=gl) and (disprec[i]<>0) do begin
    dbGo(mbase,disprec[i]);
    bezpos:=i;
    write_disp_line(i,p,true);
    inc(i);
    end;
  bezpos:=bp;
  if i<=gl then begin
    if dispmode<10 then attrtxt(col.colbretter)
    else attrtxt(col.colmsgs);
    clwin(1,screenwidth,3+i+ya,3+ya+gl);
    end;
  mdisplay:=false;
end;


procedure scrollup(show:boolean);
var p : pointer;
    i : integer;
begin
  p:=dispbuf[1];
  Move(dispbuf[2],dispbuf[1],sizeof(dispbuf)-4);
  dispbuf[maxgl]:=p;
  Move(disprec[2],disprec[1],sizeof(disprec)-4);
  disprec[maxgl]:=0;
  Move(markflag[2],markflag[1],sizeof(markflag)-1);
  Move(userflag[2],userflag[1],sizeof(userflag)-1);
  { Hervorhebung der Nachrichten bei hoher PrioritÑt }
  {Move(PrioFlag[2],PrioFlag[1],sizeof(PrioFlag)-1);}
  if show then begin
    moff;
    for i:=1 to gl-1 do begin
      lcol(i,0);
      fwrt(1,i+3+ya,dispbuf[i]^);
      end;
    mon;
    end;
end;

procedure scrolldown(show:boolean);
var p : pointer;
    i : integer;
begin
  p:=dispbuf[maxgl];
  Move(dispbuf[1],dispbuf[2],sizeof(dispbuf)-4);
  dispbuf[1]:=p;
  Move(disprec[1],disprec[2],sizeof(disprec)-4);
  Move(markflag[1],markflag[2],sizeof(markflag)-1);
  Move(userflag[1],userflag[2],sizeof(userflag)-1);
  { Hervorhebung der Nachrichten bei hoher PrioritÑt }
  {Move(PrioFlag[1],PrioFlag[2],sizeof(PrioFlag)-1);}
  if show then begin
    moff;
    for i:=2 to gl do begin
      lcol(i,0);
      fwrt(1,i+3+ya,dispbuf[i]^);
      end;
    mon;
    end;
end;


{
  $Log: xp4d.inc,v $
  Revision 1.37  2001/07/29 23:29:28  MH
  - HDO: Flags auch beim Typ 'B' (binÑr) darstellen

  Revision 1.36  2001/07/25 16:25:45  MH
  - Absturz bei Nachrichten/Suche/Wiedervorlage gefixt

  Revision 1.35  2001/07/14 18:55:54  MH
  - Letzte énderung optisch angepasst

  Revision 1.34  2001/07/14 18:25:47  MH
  - RFC-BrettkonformitÑt auch bei Nachrichten/Zeigen/Unversandt

  Revision 1.33  2001/07/12 19:07:12  MH
  - Mailinglistenkopp schnigge: ][XP] <- auch dann!

  Revision 1.32  2001/07/07 12:01:07  MH
  - optik

  Revision 1.31  2001/07/04 19:18:22  MH
  - Fixversuch-Nachrichtenweiterschaltung: Beim scrollen in jedem LeseMode
    sprang der CursorBalken auf die erste Position, aber auf die falsche
    Nachricht (!Back! in GoDown() auskommentiert)

  Revision 1.30  2001/07/04 18:37:25  MH
  - Fixversuch-Nachrichtenweiterschaltung: Beim scrollen in jedem LeseMode
    sprang der CursorBalken auf die erste Position, aber auf die falsche
    Nachricht (!Back! in GoDown() auskommentiert)

  Revision 1.29  2001/06/29 01:22:46  MH
  - Brettanzeigen nun konstistent

  Revision 1.28  2001/06/22 09:19:26  MH
  - Realnamen auch Åber Fidogates anzeigen

  Revision 1.27  2001/06/18 20:17:30  oh
  Teames -> Teams

  Revision 1.26  2000/11/11 14:41:02  MH
  Lange Betreffs fÅr HideRe usw.
  - nur, wenn sie auch verwendet werden

  Revision 1.25  2000/11/11 14:12:49  MH
  Lange Betreffs fÅr HideRe usw.

  Revision 1.24  2000/11/09 17:11:34  rb
  - Kommentarbaum-Limits geaendert: 65 Ebenen, 4680 Nachrichten
  - Kommentarbaum ist mit Crtl und Cursor rechts/links verschiebbar

  Revision 1.23  2000/11/01 08:04:47  MH
  H/R-Flag hîhere PrioritÑt als M/F

  Revision 1.22  2000/09/21 22:19:39  MH
  HdrOnly:
  - neues Format: NEWS.ID
  - Bei Request wird ein 'R' vor die Nachricht gestellt
  - Mit Alt+F3 kann ein Request RÅckgÑngig gemacht werden

  Revision 1.21  2000/09/15 21:54:35  oh
  -[MLHead]-Filter optimiert

  Revision 1.19  2000/09/13 21:28:54  oh
  - Re:-Loeschung erweitert (oh/rb)

  Revision 1.18  2000/09/12 20:32:49  oh
  ML-Header-Filter eingebaut

  Revision 1.17  2000/09/12 16:40:41  oh
  Hide Re: update

  Revision 1.15  2000/09/02 20:33:25  MH
  HeaderOnly-Request: Nachtrichten mit 'X-XP-Mode: HdrOnly'
  erhalten in der NachrichtenÅbersicht ein 'H' voran gestellt

  Revision 1.14  2000/06/22 03:47:07  rb
  Haltezeit-Bug bei ver32 gefixt

  Revision 1.13  2000/06/12 21:01:15  oh
  - Signaturflag bei Unversandt jetzt korrekt vorhanden

  Revision 1.12  2000/05/25 22:58:09  rb
  Loginfos hinzugefÅgt

  Revision 1.11  2000/05/25 22:56:37  rb
  *** empty log message ***


}
