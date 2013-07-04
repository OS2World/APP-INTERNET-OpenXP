{ $Id: xp3p.pas,v 1.16 2002/01/06 20:35:08 MH Exp $ }

program xp3p;

//
// 2do:
//
// Skip-Funktion (Ctrl-S)
//

{$i asldefine.inc}

uses sysutils, classes, crt, dos,
     aslabssocket, aslpop3client, aslsmtpclient, aslnntpclient,
     xp3pmisc, xp3pconfig, scoring, vpsyslow, vputils, pho;

{$ifdef os2}

{&linker
STUB "e:\vp\out.os2\start3p.exe"
}

{$endif}


const vernr       = 'v0.4.2r';

{$ifdef os2}
      xp3pos = 'OS/2';
      shortver = 'XP3P/2' + ' ' + vernr;
{$else}
 {$ifdef win32}
      xp3pos = 'Win32';
      shortver = 'XP3P/W' + ' ' + vernr;
 {$else}
      !!! 'Nur fÅr OS/2 und Win32'
 {$endif}
{$endif}

      xp3pversion = 'XP3P ' + xp3pos + ' ' + vernr + ' Beta ';
      xp3pcopyr1  = xp3pversion + '(c) 2000, 2001, 2002 by Robert Bîck';
      xp3pcopyr2  = 'Portions copyrighted 1998-99 by Soren Ager';
      xp3pnorev : string = 'Reverse engineering and disassembling prohibited.';

      maxmailmidl = 32767;

      err_noparam = 1;
      err_nofile  = 100;
      err_errsw   = 101;
      err_badsw   = 102;
      err_noxp    = 103;
      err_errfile = 104;
      err_wrongxp = 105;

      xp_cfg    = 'xpoint.cfg';
      xp_col    = 'xpoint.col';
      logn      = 'xp-ppp.log';
      mailmidn  = 'e-mail.idx';
      mailuidn  = 'e-mail.uid';
      newsmidn  = 'e-news.idx';
      idfilen   = 'request.id';

      sem_xp3p  = 'SEMXP3P';

      crlf      = #13#10;

      logppp    = 1;
      logdebug  = 2;
      logboth   = logppp or logdebug;

      nntpmaxthread = 4;

type tMsgID = record
                aktiv: byte;           { 1 Byte }
                zustand: byte;         { 1 Byte }
                box: string [8];       { 1 Laengenbyte + 8 Character }
                mid: string [255];     { 1 Laengenbyte + 255 Character }
              end;

type tcolarr = array [1 .. 3] of byte;

type txp3p_sinf = class
                  protected
                    fservice,
                    fserver,
                    fuserver,
                    finfo,
                    fuinfo: string;
                    fxpos,
                    fypos,
                    fcount,
                    fucount,
                    fmax,
                    fumax,
                    fbytes,
                    fubytes,
                    fsize,
                    fusize,
                    fperc,
                    fuperc: integer;
                    fcol: tcolarr;
                    fautoupdate: boolean;

                    procedure writeserver (s: string);
                    procedure writeinfo (s: string);
                    procedure writecount (i: integer);
                    procedure writemax (i: integer);
                    procedure writebytes (i: integer);
                    procedure writesize (i: integer);

                  public
                    constructor create (x, y: integer; service: string;
                                        colrs: tcolarr; autoupdate: boolean);
                    destructor destroy; override;
                    procedure draw; virtual;
                    procedure update; virtual;
                    property server: string write writeserver;
                    property info: string write writeinfo;
                    property count: integer write writecount;
                    property max: integer read fumax write writemax;
                    property bytes: integer read fubytes write writebytes;
                    property size: integer write writesize;
                  end;

     txp3p_ninf = class (txp3p_sinf)
                  protected
                    fnewsgrp,
                    funewsgrp: string;

                    procedure writenewsgrp (s: string);

                  public
                    constructor create (x, y: integer; service: string;
                                        colrs: tcolarr; autoupdate: boolean);
                    destructor destroy; override;
                    procedure draw; override;
                    procedure update; override;
                    property newsgrp: string write writenewsgrp;
                  end;

     txp3p_ninf_arr = array [1..nntpmaxthread] of txp3p_ninf;

     txp3p_info = class
                  protected
                    fpop3info,
                    fsmtpinfo: txp3p_sinf;
                    fnntpinfo: txp3p_ninf_arr;
                    fcopyr1,
                    fcopyr2: string;
                    fxpos,
                    fypos: integer;
                    fcol: tcolarr;
                    fautoupdate: boolean;

                    procedure getxpcolrs;

                  public
                    constructor create (x, y: integer; cp1, cp2: string;
                                        autoupdate: boolean);
                    destructor destroy; override;
                    procedure draw;
                    procedure update;
                    property pop3info: txp3p_sinf read fpop3info;
                    property smtpinfo: txp3p_sinf read fsmtpinfo;
                    property nntpinfo: txp3p_ninf_arr read fnntpinfo;
                  end;

     txp3p_msg  = class (tstringlist)
                  public
                    procedure savetofile (const filename: string;
                                          unixstyle, append: boolean);
                    function gethdr (hdr: string): string;
                    function hdrlines: integer;
                  end;

     txp3p_uid  = class (tstringlist)
                  public
                    function getuid (nr: integer): string;
                  end;

     txp3p_pop3 = class (tpop3client)
                  public
                    constructor create (port: string);
                    procedure dologline (msg: string);
                    procedure listonemsg (msgnum: word; var size: word);
                  end;

     txp3p_smtp = class (tabssmtpclient)
                  public
                    constructor create (port: string);
                    procedure dologline (msg: string);
                  end;

     exp3p_nntp = class (exception);

     txp3p_nntp = class (tabsnntpclient)
                  public
                    constructor create (port: string);
//                    destructor destroy; override;
                    procedure dologline (msg: string);

                    procedure xover (no_from, no_to: integer; dest: txp3p_msg);
                    procedure mkxovrhdr (xoverdata, NGs: string; dest: txp3p_msg);
                    function date: tdatetime;
                    function group (groupname: string;
                                    var articlecount, articlestart,
                                    articleend: integer): boolean;
                    procedure authinfo (user, pass: string);
                  end;

     exp3p_break = class (exception);

var // xp_logd_ok,
    verbose,
    smtp,
    showhelp: boolean;
    debug,
    multi,
    newsfcnt: integer;
    confign,
    aktconfign,
    my_path,
    xp_path,
    xp_spooldir,
    xp_logdir: string;
    saveexit: Pointer;
    info: txp3p_info;

    { TWJ: SpeedAnzeige }
    twj_speed    : real;
    twj_ut1,
    twj_ut2      : longint;

{ --------------------------------------------------------------------- }

constructor txp3p_sinf.create (x, y: integer; service: string;
                               colrs: tcolarr; autoupdate: boolean);
  begin
    inherited create;
    fxpos := x;
    fypos := y;
    fservice := service;
    fcol := colrs;
    fautoupdate := autoupdate;
    fserver := '';
    fuserver := '';
    finfo := '';
    fuinfo := '';
    fcount := 0;
    fucount := 0;
    fmax := 0;
    fumax := 0;
    fbytes := 0;
    fubytes := 0;
    fsize := 0;
    fusize := 0;
    fperc := -1;
    fuperc := -1;
    draw;
  end;

destructor txp3p_sinf.destroy;
  begin
    inherited destroy;
  end;

procedure txp3p_sinf.writeserver (s: string);
  begin
    fuserver := s;
    if fautoupdate then update;
  end;

procedure txp3p_sinf.writeinfo (s: string);
  begin
    fuinfo := s;
    if fautoupdate then update;
  end;

procedure txp3p_sinf.writecount (i: integer);
  begin
    fucount := i;
    if fautoupdate then update;
  end;

procedure txp3p_sinf.writemax (i: integer);
  begin
    fumax := i;
    if fautoupdate then update;
  end;

procedure txp3p_sinf.writebytes (i: integer);
  begin
    fubytes := i;
    if fautoupdate then update;
  end;

procedure txp3p_sinf.writesize (i: integer);
  begin
    fusize := i;
    if fautoupdate then update;
  end;

procedure txp3p_sinf.draw;
  begin
    textattr := fcol [1];
    writexy (fxpos, fypos, 'Serv:');
    writexy (fxpos, fypos + 1, 'Info:');
    if fservice = 'POP3' then begin
      writexy (fxpos, fypos + 2, 'Rcvd:');
      writexy (fxpos + 68, fypos, fservice);
    end
    else if fservice = 'SMTP' then begin
      writexy (fxpos, fypos + 2, 'Sent:');
      writexy (fxpos + 68, fypos, fservice);
    end;
  end;

procedure txp3p_sinf.update;
  begin
    if fuserver <> fserver then begin
      truncs (fuserver, 61);
      fserver := fuserver;
      textattr := fcol [2];
      writexy (fxpos + 6, fypos, reps (' ', 61));
      writexy (fxpos + 6, fypos, fserver);
    end;
    if fuinfo <> finfo then begin
      truncs (fuinfo, 66);
      finfo := fuinfo;
      textattr := fcol [2];
      writexy (fxpos + 6, fypos + 1, reps (' ', 66));
      writexy (fxpos + 6, fypos + 1, finfo);
    end;
    if (fucount <> fcount) or (fumax <> fmax) then begin
      fcount := fucount;
      fmax := fumax;
      textattr := fcol [2];
      writexy (fxpos + 6, fypos + 2, reps (' ', 16));
      writexy (fxpos + 6, fypos + 2, inttostr (fcount) + '/' +
                                     inttostr (fmax) + ' Msgs');
    end;
    if (fubytes <> fbytes) or (fusize <> fsize) then begin
      fbytes := fubytes;
      fsize := fusize;
      if fsize > 0 then fuperc := 100 * fbytes div fsize;
      textattr := fcol [2];
      writexy (fxpos + 23, fypos + 2, reps (' ', 13));
      writexy (fxpos + 23, fypos + 2, '(' + i1024 (fbytes) + '/' +
                                      i1024 (fsize) + ')');
    end;
    if (fuperc <> fperc) then begin
      fperc := fuperc;
      textattr := fcol [2];
      writexy (fxpos + 37, fypos + 2, reps (' ', 35));
      writexy (fxpos + 37, fypos + 2, balkens (fperc, 30) + ' ' +
                                      inttostr (fperc) + '%');
    end;
  end;

{ --------------------------------------------------------------------- }

constructor txp3p_ninf.create (x, y: integer; service: string;
                               colrs: tcolarr; autoupdate: boolean);
  begin
    inherited create(x, y, service, colrs, autoupdate);
  end;

destructor txp3p_ninf.destroy;
  begin
    inherited destroy;
  end;

procedure txp3p_ninf.writenewsgrp (s: string);
  begin
    funewsgrp := s;
    if fautoupdate then update;
  end;

procedure txp3p_ninf.draw;
  begin
    textattr := fcol [1];
    writexy (fxpos, fypos, 'Serv:');
    writexy (fxpos, fypos + 1, '  NG:');
    writexy (fxpos, fypos + 2, 'Info:');
    writexy (fxpos, fypos + 3, ' S+R:');
  end;

procedure txp3p_ninf.update;
  begin
    if fuserver <> fserver then begin
      truncs (fuserver, 30);
      fserver := fuserver;
      textattr := fcol [2];
      writexy (fxpos + 6, fypos, reps (' ', 30));
      writexy (fxpos + 6, fypos, fserver);
    end;
    if funewsgrp <> fnewsgrp then begin
      truncs (funewsgrp, 30);
      fnewsgrp := funewsgrp;
      textattr := fcol [2];
      writexy (fxpos + 6, fypos + 1, reps (' ', 30));
      writexy (fxpos + 6, fypos + 1, fnewsgrp);
    end;
    if fuinfo <> finfo then begin
      truncs (fuinfo, 30);
      finfo := fuinfo;
      textattr := fcol [2];
      writexy (fxpos + 6, fypos + 2, reps (' ', 30));
      writexy (fxpos + 6, fypos + 2, finfo);
    end;
    if (fucount <> fcount) or (fumax <> fmax) then begin
      fcount := fucount;
      fmax := fumax;
      textattr := fcol [2];
      writexy (fxpos + 6, fypos + 3, reps (' ', 16));
      writexy (fxpos + 6, fypos + 3, inttostr (fcount) + '/' +
                                     inttostr (fmax) + ' Msgs');
    end;
    if (fubytes <> fbytes) or (fusize <> fsize) then begin
      fbytes := fubytes;
      fsize := fusize;
      if fsize > 0 then fuperc := 100 * fbytes div fsize;
      textattr := fcol [2];
      writexy (fxpos + 23, fypos + 3, reps (' ', 13));
      writexy (fxpos + 23, fypos + 3, '(' + i1024 (fbytes) + ')');
    end;

    { TWJ: SpeedAnzeige }
    twj_ut2 := pho.twj_unixtime - twj_ut1;
    if twj_ut2 > 0 then twj_speed := fbytes / twj_ut2;
    textattr := fcol[1];
    writexy(fxpos + 2, fypos + 8, reps('ƒ', 20));
    writexy(fxpos + 2, fypos + 8, '[' + inttostr(round(twj_speed)) + ' cps]');

  end;

{ --------------------------------------------------------------------- }

constructor txp3p_info.create (x, y: integer; cp1, cp2: string;
                               autoupdate: boolean);
  begin
    inherited create;
    fxpos := x;
    fypos := y;
    fcopyr1 := cp1;
    fcopyr2 := cp2;
    fautoupdate := autoupdate;
    getxpcolrs;
    draw;
    fpop3info := txp3p_sinf.create (fxpos + 2, fypos + 3, 'POP3', fcol, fautoupdate);
    fsmtpinfo := txp3p_sinf.create (fxpos + 2, fypos + 7, 'SMTP', fcol, fautoupdate);
    fnntpinfo [1] := txp3p_ninf.create (fxpos + 2, fypos + 11, 'NNTP', fcol, fautoupdate);

    fnntpinfo [2] := txp3p_ninf.create (fxpos + 39, fypos + 11, 'NNTP', fcol, fautoupdate);
    fnntpinfo [3] := txp3p_ninf.create (fxpos + 2, fypos + 15, 'NNTP', fcol, fautoupdate);
    fnntpinfo [4] := txp3p_ninf.create (fxpos + 39, fypos + 15, 'NNTP', fcol, fautoupdate);

  end;

destructor txp3p_info.destroy;
  begin
    textattr := 7;
    fpop3info.free;
    fsmtpinfo.free;
    fnntpinfo [1].free;

    fnntpinfo [2].free;
    fnntpinfo [3].free;
    fnntpinfo [4].free;

    inherited destroy;
  end;

procedure txp3p_info.getxpcolrs;
  var t: text;
      s: string;
      i: integer;
  begin
    fcol [1] := $70;
    fcol [2] := $7f;
    fcol [3] := $7e;
    if exist (xp_path + xp_col) then begin
      assign (t, xp_path + xp_col);
      reset (t);
      while not eof (t) do begin
        readln (t, s);
        s := uppercase (s);
        delspace (s);
        if pos ('MAILER', s) = 1 then begin
          delete (s, 1, 6);
          delspace (s);
          if (length (s) = 0) or (s [1] <> '=') then continue;
          delete (s, 1, 1);
          delspace (s);
          for i := 1 to parcount (s) do fcol [i] := strtoint (parstr (s, i));
          break;
        end;
      end;
      close (t);
    end;
  end;

procedure txp3p_info.draw;
  begin
    textattr := fcol [1];
    writexy (fxpos, fypos     , '⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø');
    writexy (fxpos, fypos +  1, '≥                                                                          ≥');
    writexy (fxpos, fypos +  2, '√ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥');
    writexy (fxpos, fypos +  3, '≥                                                                          ≥');
    writexy (fxpos, fypos +  4, '≥                                                                          ≥');
    writexy (fxpos, fypos +  5, '≥                                                                          ≥');
    writexy (fxpos, fypos +  6, '√ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥');
    writexy (fxpos, fypos +  7, '≥                                                                          ≥');
    writexy (fxpos, fypos +  8, '≥                                                                          ≥');
    writexy (fxpos, fypos +  9, '≥                                                                          ≥');
    writexy (fxpos, fypos + 10, '√ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥');
    writexy (fxpos, fypos + 11, '≥                                                                          ≥');
    writexy (fxpos, fypos + 12, '≥                                                                          ≥');
    writexy (fxpos, fypos + 13, '≥                                                                          ≥');
    writexy (fxpos, fypos + 14, '≥                                                                          ≥');
    writexy (fxpos, fypos + 15, '≥                                                                          ≥');
    writexy (fxpos, fypos + 16, '≥                                                                          ≥');
    writexy (fxpos, fypos + 17, '≥                                                                          ≥');
    writexy (fxpos, fypos + 18, '≥                                                                          ≥');
    writexy (fxpos, fypos + 19, '¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ');

    textattr := fcol [3];
    writexy (fxpos + 2, fypos + 1, fcopyr1);
    writexy (fxpos + 72 - length (fcopyr2), fypos + 19, ' ' + fcopyr2 + ' ');
  end;

procedure txp3p_info.update;
  var i: integer;
  begin
    fpop3info.update;
    fsmtpinfo.update;
    for i := 1 to nntpmaxthread do fnntpinfo [i].update;
  end;

{ --------------------------------------------------------------------- }

{
function TStrings.GetTextStr: string;
var
  I, L, Size, Count: Integer;
  P: PChar;
  S: string;
begin
  Count := GetCount;
  Size := 0;
  for I := 0 to Count - 1 do Inc(Size, Length(Get(I)) + 2);
  SetString(Result, nil, Size);
  P := Pointer(Result);
  for I := 0 to Count - 1 do
  begin
    S := Get(I);
    L := Length(S);
    if L <> 0 then
    begin
      System.Move(Pointer(S)^, P^, L);
      Inc(P, L);
    end;
    P^ := #13;
    Inc(P);
    P^ := #10;
    Inc(P);
  end;
end;
}

procedure txp3p_msg.savetofile (const filename: string;
                                unixstyle, append: boolean);
  const crlf: array [0 .. 1] of byte = (13, 10);
  var i, res, crlf_i, crlf_c: integer;
      s: string;
      f: file;
  begin
    if unixstyle then crlf_i := 1 else crlf_i := 0;
    crlf_c := 2 - crlf_i;
    system.assign (f, filename);
    if append and exist (filename) then begin
      reset (f, 1);
      seek (f, filesize (f));
    end
    else rewrite (f, 1);
    for i := 0 to getcount - 1 do begin
      s := get (i);
      blockwrite (f, s [1], length (s), res);
      if res <> length (s)
      then raise estringlisterror.create ('Error: Savetofile');
      blockwrite (f, crlf [crlf_i], crlf_c, res);
      if res <> crlf_c
      then raise estringlisterror.create ('Error: Savetofile');
    end;
    close (f);
  end;

function txp3p_msg.gethdr (hdr: string): string;
  var i: integer;
      s: string;
  begin
    result := '';
    for i := 0 to getcount - 1 do begin
      s := get (i);
      if s = '' then break
      else if pos (uppercase (hdr), uppercase (s)) = 1 then begin
        system.delete (s, 1, length (hdr));
        delspace (s);
        result := s;
        break;
      end;
    end;
  end;

function txp3p_msg.hdrlines: integer;
  var i: integer;
      s: string;
  begin
    result := 0;
    for i := 0 to getcount - 1 do begin
      s := get (i);
      if s = '' then begin
        result := i;
        break;
      end;
    end;
  end;

{ --------------------------------------------------------------------- }

function txp3p_uid.getuid (nr: integer): string;
  var i: integer;
  begin
    result := get (nr - 1);
    i := pos (' ', result);
    if i > 0 then system.delete (result, 1, i);
  end;

{ --------------------------------------------------------------------- }

constructor txp3p_pop3.create (port: string);
  begin
    inherited create;
    service := port;
  end;

procedure txp3p_pop3.dologline (msg: string);
  begin
    if verbose then writeln (msg);
    appendtofile (xp_logdir + aktconfign + '.log', msg);
  end;

procedure txp3p_pop3.listonemsg (msgnum: word; var size: word);
  var s: string;
      i: integer;
  begin
    sendcommand ('LIST ' + inttostr (msgnum));
    if lastresponsecode <> wtrue then
      raise eabspop3client.create ('ListOneMsg', lastresponse);
    s := copy (lastresponse, 5, length (lastresponse) - 4);
    i := pos (' ', s);
    size := strtoint (copy(s, i + 1, length (s) - i));
  end;

{ --------------------------------------------------------------------- }

constructor txp3p_smtp.create (port: string);
  begin
    inherited create;
    service := port;
  end;

procedure txp3p_smtp.dologline (msg: string);
  begin
    if verbose then writeln (msg);
    appendtofile (xp_logdir + aktconfign + '.log', msg);
  end;

{ --------------------------------------------------------------------- }

constructor txp3p_nntp.create (port: string);
  begin
    inherited create;
    service := port;
  end;
{
destructor txp3p_nntp.destroy;
  begin
    inherited destroy;
  end;
}
procedure txp3p_nntp.dologline (msg: string);
  begin
    if verbose then writeln (msg);
    appendtofile (xp_logdir + aktconfign + '.log', msg);
  end;

procedure txp3p_nntp.xover (no_from, no_to: integer; dest: txp3p_msg);
  begin
    if no_to <= no_from
      then sendcommand ('XOVER ' + inttostr(no_from))
      else sendcommand ('XOVER ' + inttostr(no_from) + '-' + inttostr(no_to));
    if lastresponsecode <> 224 then
      raise eabsnntpclient.create('Xover', lastresponse);
    getmsglines (dest);
  end;

procedure txp3p_nntp.mkxovrhdr (xoverdata, NGs: string; dest: txp3p_msg);

  function getnextfield: string;
    var i: integer;
    begin
      i := pos (#9, xoverdata);
      if i = 0  then i := length (xoverdata)
      else begin
        delete (xoverdata, i, 1);
        dec (i);
      end;
      getnextfield := copy (xoverdata, 1, i);
      delete (xoverdata, 1, i);
    end;

  begin
    dest.add ('X-Message-Number: ' + getnextfield);
    dest.add ('Newsgroups: ' + NGs);
    dest.add ('Subject: ' + getnextfield);
    dest.add ('From: ' + getnextfield);
    dest.add ('Date: ' + getnextfield);
    dest.add ('Message-ID: ' + getnextfield);
    dest.add ('References: ' + getnextfield);
    dest.add ('X-Messagelength: ' + getnextfield);
    dest.add ('Lines: ' + getnextfield);
  end;

function txp3p_nntp.date: tdatetime;
  begin
    sendcommand ('DATE');
    if lastresponsecode <> 111 then
      raise eabsnntpclient.create('Date', lastresponse);
    result := encodedate (strtoint (copy (lastresponse,  5, 4)),
                          strtoint (copy (lastresponse,  9, 2)),
                          strtoint (copy (lastresponse, 11, 2)))
            + encodetime (strtoint (copy (lastresponse, 13, 2)),
                          strtoint (copy (lastresponse, 15, 2)),
                          strtoint (copy (lastresponse, 17, 2)),
                          0);
  end;

function txp3p_nntp.group (groupname: string; var articlecount,
                           articlestart, articleend: integer): boolean;
  var i: integer;
      s: string;
  begin
    sendcommand ('GROUP ' + groupname);
    if (lastresponsecode <> 211) and (lastresponsecode <> 411) then
      raise eabsnntpclient.create('Group', lastresponse);
    if lastresponsecode = 211 then begin
      s := lastresponse;
      delete (s, 1, 4);
      i := pos (' ', s);
      if i = 0 then
        raise eabsnntpclient.create('Group - articlecount', lastresponse);
      articlecount := strtoint (copy (s, 1, i - 1));
      delete (s, 1, i);
      i := pos (' ', s);
      if i = 0 then
        raise eabsnntpclient.create('Group - articlestart', lastresponse);
      articlestart := strtoint (copy (s, 1, i - 1));
      delete (s, 1, i);
      i := pos (' ', s);
      if i = 0 then
        raise eabsnntpclient.create('Group - articleend', lastresponse);
      articleend := strtoint (copy (s, 1, i - 1));
    end;
    result := (lastresponsecode = 211);
  end;

procedure txp3p_nntp.authinfo (user, pass: string);
  begin
    sendcommand ('AUTHINFO USER ' + user);
    if lastresponsecode <> 381 then
      raise eabsnntpclient.create('Authinfo user', lastresponse);
    sendcommand ('AUTHINFO PASS ' + pass);
    if lastresponsecode <> 281 then
      raise eabsnntpclient.create('Authinfo pass', lastresponse);
  end;

{ --------------------------------------------------------------------- }

procedure writelog (s: string; which: integer);
  begin
    if (verbose or (which and logppp <> 0)) and not assigned (info)
      then writeln (s);
    if which and logppp <> 0
      then logtofile (xp_logdir + logn, s);
    if (which and logdebug <> 0) and (debug > 0)
      then appendtofile (xp_logdir + aktconfign + '.log', s);
  end;

procedure loadmsgidfile (n: string; var mids: ansistring);
  var f: file;
  begin
    if exist (n) then begin
      assign (f, n);
      reset (f, 1);
      setlength (mids, filesize (f));
      blockread (f, mids [1], filesize (f));
      close (f);
    end
    else mids := '';
  end;

procedure savemsgidfile (n: string; var mids: ansistring);
  var f: file;
  begin
    assign (f, n);
    rewrite (f, 1);
    blockwrite (f, mids [1], length (mids));
    close (f);
  end;

procedure truncmids (var mids: ansistring; l: integer);
  begin
    if length (mids) > l then begin
      mids := copy (mids, length (mids) - l + 1, l);
      if (length (mids) > 0) and (mids [1] <> '<') and (pos ('>', mids) > 0)
        then delete (mids, 1, pos ('>', mids));
    end;
  end;

procedure addmids (var mids: ansistring; const s: string; l: integer);
  begin
    mids := mids + s;
    truncmids (mids, l);
  end;

function testmids (const mids: ansistring; const s: string): boolean;
  begin
    testmids := pos (s, mids) > 0;
  end;

procedure delmids (var mids: ansistring; const s: string);
  var i: integer;
  begin
    i := pos (s, mids);
    if i > 0 then delete (mids, i, length (s));
  end;

procedure checkbreak;
  var ch: char;
  begin
    if keypressed then ch := readkey;
    while keypressed do readkey;
    if ch = #27 then begin
      write (^G);
      raise exp3p_break.create ('aborted by user ...');
    end;
  end;

{ --------------------------------------------------------------------- }

procedure getmail (cfg: txp3pconfig; filtern: boolean);
  var i, j, count, n, skipped: integer;
      midfound: boolean;
      cli: txp3p_pop3;
      msg: txp3p_msg;
      uid: txp3p_uid;
      s, sinf, sact, envto, spooldir: string;
      msgids: ansistring;
  begin
    msg := nil;
    uid := nil;
    try
      if cfg.pop3envelope = '' then cfg.pop3envelope := 'Pop3Envelope@localhost';
      n := 0;
      for i := 1 to parcount (cfg.pop3server) do
      begin
        skipped := 0;
        spooldir := parstr (cfg.pop3spool, i);
        cli := txp3p_pop3.create (parstr (cfg.pop3port, i));
        checkbreak;
        try
          if debug > 0 then begin
            cli.onlogline := cli.dologline;
            if debug > 1 then cli.socket.onlogline := cli.dologline;
            cli.logline('');
            logtofile (xp_logdir + aktconfign + '.log',
                       'getmail ' + parstr (cfg.pop3server, i) +
                       ':' + parstr (cfg.pop3port, i));
          end;
          msg := txp3p_msg.create;
          uid := txp3p_uid.create;
          cli.delafter := not testbool (parstr (cfg.pop3keep, i));
          if not verbose then begin
            info.pop3info.server := parstr (cfg.pop3server, i) + ':' +
                                    parstr (cfg.pop3port, i);
            info.pop3info.info := 'connecting ...';
          end;
          writelog ('POP3: ' +
                    parstr (cfg.pop3server, i) + ':' +
                    parstr (cfg.pop3port, i), logppp);
          cli.connect (parstr (cfg.pop3server, i),
                       parstr (cfg.pop3user, i),
                       parstr (cfg.pop3pass, i),
                       testbool (parstr (cfg.pop3auth, i)));
          checkbreak;
          try
            if not verbose then
              info.pop3info.info := 'UIDL';
            cli.uidl (uid);
          except
            on e: eabspop3client do writelog ('Error (getmail): '+ e.message, logboth);
            else raise;
          end;
          if assigned (uid)
            then loadmsgidfile (xp_path + mailuidn, msgids)
            else loadmsgidfile (xp_path + mailmidn, msgids);
          try
            if not verbose then begin
              info.pop3info.info := inttostr (cli.msgs) + ' mails, ' +
                                    inttostr (cli.size) + ' bytes';
              info.pop3info.count := 0;
              info.pop3info.max := cli.msgs;
              info.pop3info.bytes := 0;
              info.pop3info.size := cli.size;
            end;
            writelog (inttostr (cli.msgs) + ' mails, ' +
                      inttostr (cli.size) + ' bytes', logppp);
            for count := 1 to cli.msgs do begin
              if assigned (uid) then begin
                s := '<' + uid.getuid (count) + '@' +
                     parstr (cfg.pop3user, i) + '.' +
                     parstr (cfg.pop3server, i) + '>';
                sinf := '???';
              end
              else begin
                cli.top (count, 0, msg);
                s := msg.gethdr ('Message-ID:');
                sinf := msg.gethdr ('From:');
                msg.clear;
              end;
              checkbreak;
              midfound := testmids (msgids, s);
              if cli.delafter then begin
                if midfound then delmids (msgids, s);
              end
              else begin
                if not midfound then addmids (msgids, s, maxmailmidl);
              end;
              if filtern and (sinf='???') then begin
                cli.top (count, 0, msg);
                sinf := msg.gethdr ('From:');
                msg.clear;
              end;
              if midfound or (filtern and pho.twj_check_filter (lowercase (sinf))) then begin
                if not verbose then cli.listonemsg (count, j);
                if cli.delafter then begin
                  sact := 'deleting';
                  cli.dele (count);
                end
                else begin
                  sact := 'skipping';
                  inc (skipped);
                end;
                if not verbose then begin
                  info.pop3info.info := sact + ' mail #' + inttostr (count) +
                                        ' (' + i1024 (j) + ')' +
                                        ' [From: ' + sinf + ']';
                  info.pop3info.count := count;
                  info.pop3info.bytes := info.pop3info.bytes + j;
                end;
                if debug > 0 then
                  writelog (sact + ' mail #' + inttostr (count), logppp);
                continue;
              end;
              if not verbose then begin
                cli.listonemsg (count, j);
                info.pop3info.info := 'mail #' + inttostr (count) +
                                      ' (' + i1024 (j) + ')' +
                                      ' [From: ' + sinf + ']';
                info.pop3info.count := count;
              end;
              if debug > 0 then
                writelog ('fetching mail #' + inttostr (count), logppp);
              checkbreak;
              cli.getmsg (count, msg);
              if not verbose then
                info.pop3info.bytes := info.pop3info.bytes + j;
              if smtp then begin
                if testbool (parstr (cfg.pop3useenvelope, i))
                then begin
                  envto := msg.gethdr ('Envelope-To:');
                  if envto = '' then envto := msg.gethdr ('X-Envelope-To:');
                end
                else envto := parstr (cfg.pop3envelope, i);
                msg.insert (0, 'HELO ' + parstr (cfg.pop3server, i));
                msg.insert (1, 'RCPT TO:<' + envto + '>');
                msg.insert (2, 'DATA');
                msg.add ('.');
                msg.add ('QUIT');
                for j := 3 to msg.count - 3 do
                  if (length (msg.strings [j]) > 0)
                  and (msg.strings [j][1] = '.')
                  then msg.strings [j] := '.' + msg.strings [j];
              end
              else msg.insert (0, 'From ' + parstr (cfg.pop3user, i) +
                               '@localhost');
              while exist (spooldir + 'm' + inttohex (n, 4) + '.msg')
                do inc (n);
              msg.savetofile (spooldir + 'm' + inttohex (n, 4) + '.msg',
                              true, false);
              msg.clear;
              checkbreak;
              inc (n);
            end;
          finally
            if skipped > 0 then
              writelog (inttostr (skipped) + ' mails skipped', logppp);
            if assigned (uid) then begin
              savemsgidfile (xp_path + mailuidn, msgids);
              uid.free;
            end
            else savemsgidfile (xp_path + mailmidn, msgids);
            if assigned (msg) then msg.free;
//            cli.quit; Quit wird in disconnect bereits ausgefÅhrt
            cli.disconnect;
          end;
        finally
          cli.free;
        end;
      end;
    except
      on e: exp3p_break do writelog (e.message, logboth);
      on e: eabspop3client do writelog ('Error (getmail): ' + e.message, logboth);
      on e: easlexception do writelog ('Error (getmail): ' + e.message, logboth);
      else raise;
    end;
  end;

procedure sendmail (cfg: txp3pconfig);
  const l_bufsize = 2048;
  type t_l_buf = array [0..l_bufsize - 1] of char;
  var i, count, size: integer;
      f1: file;
      sr: searchrec;
      cli: txp3p_smtp;
      l_buf: ^t_l_buf;
      l_bufp, l_bufs: longint;
      l_eof, helo, data, header, sent: boolean;
      s, s1, spooldir: string;
      authresponse: TStringList;

  procedure get_line (var s_line: string);
    const nix = 0;
          cr = 1;
          ready = 2;
    var stat: word;
    begin
      s_line := '';
      stat := nix;
      while not (stat = ready) do begin
        if l_bufp = l_bufs then begin
          if not eof (f1) then begin
            blockread (f1, l_buf^ [0], l_bufsize, l_bufs);
            l_bufp := 0;
          end
          else begin
            l_eof := true;
            stat := ready;
          end;
        end
        else begin
          if stat = cr then begin
            if l_buf^ [l_bufp] = char ($0a) then inc (l_bufp);
            stat := ready;
          end
          else begin
            if l_buf^ [l_bufp] = char ($0d) then begin
              inc (l_bufp);
              stat := cr;
            end
            else if l_buf^ [l_bufp] = char ($0a) then begin
              inc (l_bufp);
              stat := ready;
            end
            else begin
              if length (s_line) < 255
              then s_line := s_line + l_buf^ [l_bufp];
              inc (l_bufp);
            end;
          end;
        end;
      end;
    end;

  begin
    try
      getmem (l_buf, l_bufsize);
      try
        for i := 1 to parcount (cfg.smtpserver) do
        begin
          spooldir := parstr (cfg.smtpspool, i);
          cli := txp3p_smtp.create (parstr (cfg.smtpport, i));
          if debug > 0 then begin
            cli.onlogline := cli.dologline;
            if debug > 1 then cli.socket.onlogline := cli.dologline;
            cli.logline('');
            logtofile (xp_logdir + aktconfign + '.log',
                       'sendmail ' + parstr (cfg.smtpserver, i) +
                       ':' + parstr (cfg.smtpport, i));
          end;
          helo := false;
          header := true;
          try
            if not verbose then begin
              info.smtpinfo.server := parstr (cfg.smtpserver, i) + ':' +
                                      parstr (cfg.smtpport, i);
              info.smtpinfo.info := 'connecting ...';
            end;
            writelog ('SMTP: ' +
                      parstr (cfg.smtpserver, i) + ':' +
                      parstr (cfg.smtpport, i), logppp);
            cli.connect (parstr (cfg.smtpserver, i));
            checkbreak;
            try
              size := 0;
              count := 0;
              findfirst (spooldir + 'm*.out', archive, sr);
              while doserror = 0 do
              begin
                inc (size, sr.size);
                inc (count);
                findnext (sr);
              end;
              findclose (sr);
              checkbreak;
              if not verbose then begin
                info.smtpinfo.info := inttostr (count) + ' mails to send, ' +
                                      inttostr (size) + ' bytes';
                info.smtpinfo.count := 0;
                info.smtpinfo.max := count;
                info.smtpinfo.bytes := 0;
                info.smtpinfo.size := size;
              end;
              writelog (inttostr (count) + ' mails to send, ' +
                        inttostr (size) + ' bytes', logppp);
              count := 0;
              findfirst (spooldir + 'm*.out', archive, sr);
              while doserror = 0 do
              begin
                assign (f1, spooldir + sr.name);
                reset (f1, 1);
                try
                  l_bufp := 0;
                  l_bufs := 0;
                  l_eof := false;
                  sent := false;
                  inc (count);
                  data := false;
                  if not verbose
                    then info.smtpinfo.info := 'mail #' + inttostr (count) +
                                               ': ' + spooldir + sr.name;
                  if debug > 0 then
                  writelog ('sending mail #' + inttostr (count) + ': ' +
                            spooldir + sr.name + '...', logppp);
                  get_line (s);
                  while not l_eof or (length (s) > 0) do begin
                    s1 := uppercase (s);
                    if not data then begin
                      if (pos ('HELO', s1) = 1) and not helo then begin
                        delete (s, 1, 4);
                        delspace (s);
                        if (parstr (cfg.smtpauth, i)<>'KEINE') and
                           (parstr (cfg.smtpauth, i)<>'DISABLED') and
                           (parstr (cfg.smtpuser, i)<>'') and
                           (parstr (cfg.smtppass, i)<>'')
                        then begin
                          authresponse := nil;
                          authresponse := TStringList.Create;
                          try
                            cli.ehlo (s,
                                      authresponse,
                                      parstr (cfg.smtpauth, i),
                                      parstr (cfg.smtpuser, i),
                                      parstr (cfg.smtppass, i));
                          finally
                            authresponse.destroy;
                          end;
                        end
                        else
                          cli.helo (s);
                        helo := true;
                      end
                      else if pos ('MAIL FROM:', s1) = 1 then begin
                        delete (s, 1, 10);
                        delspace (s);
                        if firstchar (s) = '<' then delete (s, 1, 1);
                        if lastchar (s) = '>' then delete (s, length (s), 1);
                        if cfg.smtpenvelope <> ''
                          then s := parstr (cfg.smtpenvelope, i);
                        cli.mail (s);
                      end
                      else if pos ('RCPT TO:', s1) = 1 then begin
                        delete (s, 1, 8);
                        delspace (s);
                        if firstchar (s) = '<' then delete (s, 1, 1);
                        if lastchar (s) = '>' then delete (s, length (s), 1);
                        if not verbose
                          then info.smtpinfo.info := 'mail #' + inttostr (count) +
                                                     ' [To: ' + s + ']';
                        cli.rcpt (s);
                      end
                      else if pos ('DATA', s1) = 1 then begin
                        cli.data;
                        data := true;
                      end;
                    end
                    else begin
                      if s = '.' then begin
                        data := false;
                        header := true;
                      end
                      else if (pos ('X-Mailer: ', s) = 1) and header
                        then s := s + ', via ' + shortver
                      else if s = '' then header := false;
                      cli.socket.writeln (s);
                    end;
                    get_line (s);
                  end;
                  checkbreak;
                  if not verbose then begin
                    info.smtpinfo.count := count;
                    info.smtpinfo.bytes := info.smtpinfo.bytes + sr.size;
                  end;
                  cli.getresponse (nil);
                  if debug > 0 then
                  writelog ('done.', logppp);
                  sent := true;
                finally
                  close (f1);
                  if sent then erase (f1);
                end;
                findnext (sr);
              end;
            finally
              writelog (inttostr (count) + ' mails sent', logppp);
              findclose (sr);
              cli.quit;  { ! }
              cli.disconnect;
            end;
          finally
            cli.free;
          end;
        end;
      finally
        freemem (l_buf, l_bufsize);
      end;
    except
      on e: exp3p_break do writelog (e.message, logboth);
      on e: eabssmtpclient do writelog ('Error (sendmail): ' + e.message, logboth);
      on e: easlexception do writelog ('Error (sendmail): ' + e.message, logboth);
      else raise;
    end;
  end;

procedure getnglist (cfg: txp3pconfig);
  var i: integer;
      cli: txp3p_nntp;
      msg, msg1: txp3p_msg;
      dt: tdatetime;
      s: string;
  begin
    if cfg.nntplist then begin   { Newsgroupliste }
      msg := nil;
      try
        cli := txp3p_nntp.create (cfg.nntpport);
        try
          if debug > 0 then begin
            cli.onlogline := cli.dologline;
            if debug > 1 then cli.socket.onlogline := cli.dologline;
            cli.logline('');
            logtofile (xp_logdir + aktconfign + '.log',
                       'getnglist ' + cfg.nntpserver + ':' + cfg.nntpport);
          end;
          writelog ('NNTP: ' + cfg.nntpserver + ':' + cfg.nntpport, logppp);
          cli.connect (cfg.nntpserver);
          checkbreak;
          if not verbose
            then info.nntpinfo [1].server := cfg.nntpserver + ':' + cfg.nntpport;
          msg := txp3p_msg.create;
          try
            if (cfg.nntpuser <> '') and (cfg.nntppass <> '') then
            begin
              if not verbose
                then info.nntpinfo [1].info := 'newsserver authentification';
              writelog ('newsserver authentification ...', logppp);
              cli.authinfo (cfg.nntpuser, cfg.nntppass);
            end;
            if not exist (xp_path + aktconfign + '.bl')
            then begin                                         { neu anfordern }
              if not verbose
                then info.nntpinfo [1].info := 'requesting newsgroup list';
              writelog ('requesting newsgroup list', logppp);
//              raise eabsnntpclient.create ('Test', 'bla bla');
              dt := cli.date;
              cli.list (msg);
              checkbreak;
              if not verbose
                then info.nntpinfo [1].info := 'newsgroups: ' + inttostr (msg.count);
              writelog ('newsgroups: ' + inttostr (msg.count), logppp);
              msg.insert (0, '!new_groups:' +
                             formatdatetime ('yymmdd hhnnss', dt));
              msg.savetofile (xp_path + aktconfign + '.bl', false, false);
              msg.clear;
              checkbreak;
            end
            else begin                                         { updaten }
              if not verbose
                then info.nntpinfo [1].info := 'updating newsgroup list';
              writelog ('updating newsgroup list', logppp);
              msg.loadfromfile (xp_path + aktconfign + '.bl');
              checkbreak;
              if msg.count > 0
              then if pos ('!new_groups:', msg.strings [0]) = 1
              then begin
                s := msg.strings [0];
                msg.delete (0);
                i := strtoint (copy (s, 13, 2));
                if i < 80 then inc (i, 2000) else inc (i, 1900);
                dt := encodedate (i,
                                  strtoint (copy (s, 15, 2)),
                                  strtoint (copy (s, 17, 2)))
                    + encodetime (strtoint (copy (s, 20, 2)),
                                  strtoint (copy (s, 22, 2)),
                                  strtoint (copy (s, 24, 2)),
                                  0);
                msg1 := txp3p_msg.create;
                cli.newgroups (dt, false, '', msg1);
                checkbreak;
                if msg1.count > 0 then begin
                  if not verbose
                    then info.nntpinfo [1].info := 'new newsgroups: ' + inttostr (msg1.count);
                  writelog ('new newsgroups: ' + inttostr (msg1.count), logppp);
                  dt := cli.date;
                  msg.sorted:=true;
                  msg.addstrings (msg1);
                  msg.sorted:=false;
                  msg.insert (0, '!new_groups:' +
                                 formatdatetime ('yymmdd hhnnss', dt));
                  msg.savetofile (xp_path + aktconfign + '.bl', false, false);
                end;
                msg1.free;
              end;
              msg.clear;
            end;
          finally
            if assigned (msg) then msg.free;
//            cli.quit; { wird bereits im disconnect angesto·en }
            cli.disconnect;
          end;
        finally
          cli.free;
        end;
      except
        on e: exp3p_break do writelog (e.message, logboth);
        on e: exp3p_nntp do writelog ('Error (getnglist): ' + e.message, logboth);
        on e: eabsnntpclient do writelog ('Error (getnglist): ' + e.message, logboth);
        on e: easlexception do writelog ('Error (getnglist): ' + e.message, logboth);
        else raise;
      end;
    end;
  end;

procedure postnews (cfg: txp3pconfig);
  var i, count, size: integer;
      cli: txp3p_nntp;
      msg: txp3p_msg;
      s, spooldir: string;
      f: file;
      sr: searchrec;
      msgids: ansistring;
      idfile: file of tMsgID;
      idrec: tMsgID;
  begin
    msg := nil;
    try
      if not exist_wild (cfg.nntpspool + 'n*.out') then exit;
      spooldir := cfg.nntpspool;
      cli := txp3p_nntp.create (cfg.nntpport);
      loadmsgidfile (xp_path + newsmidn, msgids);
      if cfg.replaceown then begin
        assign (idfile, idfilen);
        if exist (idfilen) then reset (idfile) else rewrite (idfile);
        seek (idfile, filesize (idfile));
      end;
      try
        if debug > 0 then begin
          cli.onlogline := cli.dologline;
          if debug > 1 then cli.socket.onlogline := cli.dologline;
          cli.logline('');
          logtofile (xp_logdir + aktconfign + '.log',
                     'postnews ' + cfg.nntpserver + ':' + cfg.nntpport);
        end;
        if not verbose then begin
          info.nntpinfo [1].server := cfg.nntpserver + ':' + cfg.nntpport;
          info.nntpinfo [1].info := 'connecting ...';
        end;
        writelog ('NNTP: ' + cfg.nntpserver + ':' + cfg.nntpport, logppp);
        cli.connect (cfg.nntpserver);
        checkbreak;
        msg := txp3p_msg.create;
        try
          if (cfg.nntpuser <> '') and (cfg.nntppass <> '') then
          begin
            if not verbose
              then info.nntpinfo [1].info := 'newsserver authentification';
            writelog ('newsserver authentification ...', logppp);
            cli.authinfo (cfg.nntpuser, cfg.nntppass);
          end;
          count := 0;
          if exist_wild (spooldir + 'n*.out') then begin    { post news }
            try
              size := 0;
              findfirst (spooldir + 'n*.out', archive, sr);
              while doserror = 0 do begin
                inc (size, sr.size);
                inc (count);
                findnext (sr);
              end;
              findclose (sr);
              checkbreak;
              if not verbose then begin
                info.nntpinfo [1].info := inttostr (count) + ' articles to post, ' +
                                      inttostr (size) + ' bytes';
                info.nntpinfo [1].count := 0;
                info.nntpinfo [1].max := count;
                info.nntpinfo [1].bytes := 0;
                info.nntpinfo [1].size := size;
              end;
              writelog (inttostr (count) + ' articles to post, ' +
                        inttostr (size) + ' bytes', logppp);
              count := 0;
              findfirst (spooldir + 'n*.out', archive, sr);
              while doserror = 0 do begin
                msg.loadfromfile (spooldir + sr.name);
                for i := 0 to msg.count - 1 do begin
                  if msg.strings [i] = '' then break;
                  if pos ('X-Newsreader: ', msg.strings [i]) = 1
                  then msg.strings [i] := msg.strings [i] + ', via ' + shortver;
                end;
                try
                  inc (count);
                  if not verbose then begin
                    info.nntpinfo [1].newsgrp := msg.gethdr ('Newsgroups:');
                    info.nntpinfo [1].info := 'posting article #' + inttostr (count);
                  end;
                  cli.post (msg);
                  checkbreak;
                  s := msg.gethdr ('Message-ID:');
                  msgids := msgids + s;
                  truncmids (msgids, cfg.nntpdupesize);
                  if debug > 0 then
                  writelog ('article #' + inttostr (count) + ' posted', logppp);
                  if not verbose then begin
                    info.nntpinfo [1].info := 'article #' + inttostr (count) +
                                           ' posted';
                    info.nntpinfo [1].count := count;
                    info.nntpinfo [1].bytes := info.nntpinfo [1].bytes + sr.size;
                  end;
                  assign (f, spooldir + sr.name);
                  erase (f);
                  if cfg.replaceown then with idrec do begin
                    aktiv := 3;
                    zustand := 0;
                    box := '*';
                    mid := s;
                    write (idfile, idrec);
                  end;
                except
                  on e: eabsnntpclient do writelog (e.message, logboth);
                  else raise;
                end;
                msg.clear;
                findnext (sr);
              end;
            finally
              findclose (sr);
            end;
          end;
        finally
          writelog (inttostr (count) + ' articles posted', logppp);
          if assigned (msg) then msg.free;
//          cli.quit;
          cli.disconnect;
        end;
      finally
        if cfg.replaceown then close (idfile);
        cli.free;
        savemsgidfile (xp_path + newsmidn, msgids);
      end;
    except
      on e: exp3p_break do writelog (e.message, logboth);
      on e: exp3p_nntp do writelog ('Error (postnews): ' + e.message, logboth);
      on e: eabsnntpclient do writelog ('Error (postnews): ' + e.message, logboth);
      on e: easlexception do writelog ('Error (postnews): ' + e.message, logboth);
      else raise;
    end;
  end;

procedure getnews (cfg: txp3pconfig; filtern: boolean);
  var i, j, rci, count, gcount, xcount, size, gsize, skipped: integer;
      cli: txp3p_nntp;
      msg, xover, rcfile, scmsg: txp3p_msg;
      s, mids, sinf, group, spooldir, addhdr: string;
      sr: searchrec;
      artstart, artend, artcount, actart, score: integer;
      starttime, endtime: integer;
      hdronly, x255: boolean;
      msgids: ansistring;
      scaction: tscaction;

  procedure rc_split (var s, group: string; var actart: integer;
                      var hdronly: boolean);
    var i: integer;
    begin
      if parcount (s) < 2
      then raise exp3p_nntp.create ('Error in RC-file ' + sr.name + ': ' + s);
      group := parstr (s, 1);
      actart := strtoint (parstr (s, 2));
      if parcount (s) > 2
      then hdronly := uppercase (parstr (s, 3)) = 'HDRONLY'
      else hdronly := false;
      delspace (s);
      delete (s, 1, pos (' ', s));
      delspace (s);
      i := pos (' ', s);
      if i = 0 then i := length (s) + 1;
      delete (s, 1, i - 1);
    end;

  procedure getarticlesbyid (idfilename, boxfname: string);
    var i, j, idcount: integer;
        idfile: file of tMsgID;
        idrec: tMsgID;
    begin
      idcount := 0;
      assign (idfile, idfilename);
      reset (idfile);
      try
        if not verbose then
          info.nntpinfo [1].max := info.nntpinfo [1].max + filesize (idfile);
        writelog ('fetching ' + inttostr (filesize (idfile)) +
                  ' articles by Message-ID', logppp);
        for i := 1 to filesize (idfile) do begin
          read (idfile, idrec);
          mids := idrec.mid;
          if ((uppercase (idrec.box) = uppercase (boxfname)) or (idrec.box = '*'))
          and (idrec.aktiv in [1, 2, 3]) and (idrec.zustand < 199) then
          try
            if debug > 0 then
              writelog ('fetching article ' + mids, logppp);
            if firstchar (mids) = '<' then delete (mids, 1, 1);
            if lastchar (mids) = '>' then delete (mids, length (mids), 1);
            cli.articlebyid (mids, msg);
            mids := msg.gethdr ('Message-ID:');
            sinf := msg.gethdr ('From:');
            checkbreak;
            j := pos (mids, msgids);
            if j = 0 then begin
              msgids := msgids + mids;
              truncmids (msgids, cfg.nntpdupesize);
            end;
            if not verbose then begin
              info.nntpinfo [1].newsgrp := msg.gethdr ('Newsgroups:');
              info.nntpinfo [1].info := 'From: ' + sinf;
            end;
            if idrec.aktiv = 3
              then msg.insert (msg.hdrlines, 'X-XP-Mode: ReplaceOwn')
              else msg.insert (msg.hdrlines, 'X-XP-Mode: Message-ID Request');
            size := 0;
            for j := 0 to msg.count - 1 do
              inc (size, length (msg.strings [j]) + 1);
            msg.insert (0, '#! rnews ' + inttostr (size));
            msg.savetofile (spooldir + 'n' + inttohex (newsfcnt, 4) +
                            '.msg', true, true);
            msg.clear;
            idrec.zustand := 255;
            seek (idfile, i - 1);
            write (idfile, idrec);
            checkbreak;
            inc (count);
            inc (idcount);
            if not verbose then begin
              info.nntpinfo [1].count := count;
              info.nntpinfo [1].bytes := info.nntpinfo [1].bytes + size;
            end;
          except
            on e: eabsnntpclient do
            begin
              if not verbose then
                info.nntpinfo [1].max := info.nntpinfo [1].max - 1;
              writelog (e.message, logboth);
              inc (idrec.zustand);
              seek (idfile, i - 1);
              write (idfile, idrec);
            end;
            else raise;
          end
          else if not verbose then
            info.nntpinfo [1].max := info.nntpinfo [1].max - 1;
        end;
        inc (newsfcnt);
      finally
        close (idfile);
        writelog (inttostr (idcount) + ' articles received', logppp);
      end;
    end;

  function getxnr (s: string): integer;
    begin
      getxnr := strtoint (copy (s, 1, pos (#9, s) - 1));
    end;

  begin
    msg := nil;
    scmsg := nil;
    xover := nil;
    try
      spooldir := cfg.nntpspool;
      cli := txp3p_nntp.create (cfg.nntpport);
      loadmsgidfile (xp_path + newsmidn, msgids);
      try
        if debug > 0 then begin
          cli.onlogline := cli.dologline;
          if debug > 1 then cli.socket.onlogline := cli.dologline;
          cli.logline('');
          logtofile (xp_logdir + aktconfign + '.log',
                     'getnews ' + cfg.nntpserver + ':' + cfg.nntpport);
        end;
        if not verbose then begin
          info.nntpinfo [1].server := cfg.nntpserver + ':' + cfg.nntpport;
          info.nntpinfo [1].info := 'connecting ...';
        end;
        writelog ('NNTP: ' + cfg.nntpserver + ':' + cfg.nntpport, logppp);
        cli.connect (cfg.nntpserver);
        checkbreak;
        msg := txp3p_msg.create;
        scmsg := txp3p_msg.create;
        try
          if (cfg.nntpuser <> '') and (cfg.nntppass <> '') then
          begin
            if not verbose
              then info.nntpinfo [1].info := 'newsserver authentification';
            writelog ('newsserver authentification ...', logppp);
            cli.authinfo (cfg.nntpuser, cfg.nntppass);
          end;
          rcfile := txp3p_msg.create;
          try
            count := 0;
            skipped := 0;
            if not verbose then begin
              info.nntpinfo [1].info := 'receiving news';
              info.nntpinfo [1].count := 0;
              info.nntpinfo [1].max := 0;
              info.nntpinfo [1].bytes := 0;
              info.nntpinfo [1].size := 0;
            end;
            if not exist_wild (xp_path + aktconfign + '.rc') then begin
              if not verbose
                then info.nntpinfo [1].info := 'RC-file not found';
              writelog ('RC-file not found', logppp);
            end;
            findfirst (xp_path + aktconfign + '.rc', archive, sr);
            while doserror = 0 do begin
              rcfile.loadfromfile (xp_path + sr.name);
              try
                for rci := 0 to rcfile.count - 1 do
                begin
                  s := rcfile.strings [rci];
                  if (length (s) > 0) and (s [1] <> '#') then
                  begin
                    rc_split (s, group, actart, hdronly);
                    if cli.group (group, artcount, artstart, artend) then
                    begin
                      gcount := 0;
                      gsize := 0;
                      writelog ('newsgroup: ' + group, logppp);
                      if not verbose
                        then info.nntpinfo [1].newsgrp := group;
                      if actart < 0 then actart := artend + actart;
                      if actart < 0 then actart := 0;
                      if actart > artend then actart := artend;
                      if artend - actart > cfg.nntpnewmax
                        then actart := artend - cfg.nntpnewmax;
                      if cfg.nntprescan then begin
                        if not verbose
                          then info.nntpinfo [1].info := 'updating article pointer';
                        if debug > 0
                          then writelog ('updating article pointer', logboth);
                      end;
                      starttime := 0;
                      if (actart < artend) and not cfg.nntprescan then
                      try
                        xover := txp3p_msg.create;
                        try
                          if not verbose
                            then info.nntpinfo [1].info := 'XOVER '
                                                + inttostr (actart + 1) + '-'
                                                + inttostr(artend);
                          cli.xover (actart + 1, artend, xover);
                          if xover.count = 0 then begin
                            xover.free;
                            xover:=nil;
                          end;
                        except
                          xover.free;
                          xover:=nil;
                        end;
                        if not verbose then begin
                          if assigned (xover)
                            then info.nntpinfo [1].max := info.nntpinfo [1].max +
                                                       xover.count
                            else info.nntpinfo [1].max := info.nntpinfo [1].max +
                                                       artend - actart;
                        end;
                        if debug > 0
                          then if assigned (xover)
                            then writelog ('fetching '
                                           + inttostr (xover.count)
                                           + ' articles', logppp)
                            else writelog ('fetching '
                                           + inttostr (artend - actart)
                                           + ' articles', logppp);
                        if assigned (xover)
                          then artend := getxnr (xover.strings [xover.count - 1]);
                        xcount := -1;
                        starttime := getsecs;
                        repeat
                          inc (xcount);
                          if assigned (xover)
                            then actart := getxnr (xover.strings [xcount])
                            else inc (actart);
                          try
                            if debug > 0 then
                            writelog ('fetching article #' + inttostr (count + 1),
                                      logppp);
                            if assigned (xover) and not cfg.scoreaktiv
                              then cli.mkxovrhdr (xover.strings [xcount], group, msg)
                              else cli.headbyno (actart, msg);
                            mids := msg.gethdr ('Message-ID:');
                            sinf := msg.gethdr ('From:');
                            checkbreak;
                            if cfg.scoreaktiv then begin
                              prepare_header (scmsg, msg);
                              score := score_message (scmsg, scaction, addhdr);
                              scmsg.clear;
                            end
                            else begin
                              score := 0;
                              scaction := tscnone;
                            end;
                            i := pos (mids, msgids);
                            if (i = 0) and (scaction <> tscskip) then begin
                              msgids := msgids + mids;
                              truncmids (msgids, cfg.nntpdupesize);
                            end
                            else begin
                              if not verbose then begin
                                info.nntpinfo [1].info := 'skipping article #' + inttostr (actart);
                                info.nntpinfo [1].max := info.nntpinfo [1].max - 1;
                              end;
                              if debug > 0 then
                              writelog ('skipping article #' + inttostr (actart), logppp);
                              inc (skipped);
                              msg.clear;
                              continue;
                            end;
                            if not verbose then
                            info.nntpinfo [1].info := 'From: ' + sinf;

                            { TWJ 080801 - Hier frage ich ab, ob vom }
                            { Absender nur der Header geholt werden  }
                            { soll                                   }
                            if filtern and pho.twj_check_filter (lowercase (sinf)) then begin
                              scaction := tschdronly;
                              writelog ('PHO-Filter matched: ' + sinf, logboth);
                            end;

                            if not hdronly and (scaction <> tschdronly) then begin
                              msg.clear;
                              cli.articlebyno (actart, msg);
                            end
                            else begin
                              for i := 0 to msg.count - 1 do
                              if pos ('Lines: ', msg.strings [i]) = 1
                              then begin
                                msg.strings [i] := 'Lines: 0';
                                break;
                              end;
                              msg.add ('X-XP-Mode: HdrOnly');
                              msg.add ('');
                            end;
                            if cfg.scoreaktiv then begin
                              if addhdr <> ''
                                then msg.insert (msg.hdrlines, addhdr);
                              msg.insert (msg.hdrlines, 'X-Score: ' +
                                                        inttostr (score));
                              if score <> 0 then
                                writelog ('Score: ' + sinf, logboth);
                            end;
                            size := 0;
                            for i := 0 to msg.count - 1 do
                              inc (size, length (msg.strings [i]) + 1);
                            msg.insert (0, '#! rnews ' + inttostr (size));
                            msg.savetofile (spooldir + 'n' + inttohex (newsfcnt, 4) +
                                            '.msg', true, true);
                            msg.clear;
                            checkbreak;
                            inc (count);
                            inc (gcount);
                            inc (gsize, size);
                            if not verbose then begin
                              info.nntpinfo [1].count := count;
                              info.nntpinfo [1].bytes := info.nntpinfo [1].bytes + size;
                            end;
                          except
                            on e: eabsnntpclient do
                            begin
                              if not verbose then
                                info.nntpinfo [1].max := info.nntpinfo [1].max - 1;
                              writelog (e.message, logboth);
                            end;
                            else raise;
                          end;
                        until actart = artend;
                        endtime := getsecs;
                        if endtime < starttime then inc (endtime, secsperday);
                        dec (endtime, starttime);
                        if endtime > 0
                          then starttime := gsize div endtime
                          else starttime := 0;
                        inc (newsfcnt);
                      finally
                        if assigned (xover) then begin
                          xover.free;
                          xover:=nil;
                        end;
                      end
                      else actart := artend;
                      writelog (inttostr (gcount) + ' articles received ('
                                + inttostr (starttime) + ' CPS)', logppp);
                    end
                    else writelog ('no such newsgroup: ' + group, logppp);
                    rcfile.strings [rci] := group + ' ' + inttostr (actart) + s;
                  end;
                end;
              finally
                rcfile.savetofile (xp_path + sr.name, false, false);
                rcfile.clear;
              end;
              findnext (sr);
            end;
          finally
            writelog ('total: ' + inttostr (count) + ' articles received, ' +
                      inttostr (skipped) + ' articles skipped', logppp);
            findclose (sr);
            rcfile.free;
          end;
          if exist (xp_path + idfilen) then
            getarticlesbyid (xp_path + idfilen, aktconfign);
        finally
          if assigned (msg) then msg.free;
          if assigned (scmsg) then scmsg.free;
//          cli.quit; { wird bereits im disconnect angesto·en }
          cli.disconnect;
        end;
      finally
        cli.free;
        savemsgidfile (xp_path + newsmidn, msgids);
      end;
    except
      on e: exp3p_break do writelog (e.message, logboth);
      on e: exp3p_nntp do writelog ('Error (getnews): ' + e.message, logboth);
      on e: eabsnntpclient do writelog ('Error (getnews): ' + e.message, logboth);
      on e: easlexception do writelog ('Error (getnews): ' + e.message, logboth);
      else raise;
    end;
  end;

procedure main;
  var cfg: txp3pconfig;
      sourcename: shortstring;
      linenr: longint;
      callpop3, callsmtp, callnntp, filtern: boolean;
      t1, t2: longint;
      i: integer;
      scset: tscsettings;
  begin
    try
      if not verbose
        then info := txp3p_info.create (3, 4, xp3pcopyr1, xp3pcopyr2, true);
      try

        { Anpassung an neue Schnittstelle: AbwÑrtskompatible! }

        { Vorrang hat PPP_BoxPakete, welche die BFG-Dateinamen ohne Extension     }
        { enthÑlt und der Mainbox angehangen wird, alle anderen werden ignoriert. }

        cfg := txp3pconfig.create (xp_path + parstr (confign, 1) + '.bfg');
        if length (cfg.ppp_boxpakete) > 2 then
          confign := parstr (confign, 1) + ' ' + cfg.ppp_boxpakete;
        delspace (confign);
        cfg.free;

        for i := 1 to parcount (confign) do
        begin
          aktconfign := parstr (confign, i);
          if debug > 0 then begin
            appendtofile (xp_logdir + aktconfign + '.log', '------------------------------------------------------------------------');
            appendtofile (xp_logdir + aktconfign + '.log', xp3pcopyr1);
            appendtofile (xp_logdir + aktconfign + '.log', xp3pcopyr2);
          end;
          cfg := txp3pconfig.create (xp_path + aktconfign + '.bfg');

          { TWJ 080801 - Daten fuer PHO laden und in den Speicher schauffeln }
          filtern := (cfg.ppp_killfile <> '') and exist(cfg.ppp_killfile);
          if filtern and  pho.twj_oeffne_datei (cfg.ppp_killfile) then begin
            pho.twj_create_list;
            writelog ('Reading PHO-Filter...', logboth);
          end;

          if cfg.uuzspool  = '' then cfg.uuzspool  := xp_spooldir;
          if cfg.pop3spool = '' then cfg.pop3spool := cfg.uuzspool;
          if cfg.smtpspool = '' then cfg.smtpspool := cfg.uuzspool;
          if cfg.nntpspool = '' then cfg.nntpspool := cfg.uuzspool;
          cfg.smtpauth := uppercase (cfg.smtpauth);
          if cfg.scoreaktiv and (cfg.scorefile <> '') then begin
            scset.makereport:=false;
            scset.expire:=false;
            cfg.scoreaktiv := init_score (my_path, my_path + cfg.scorefile, scset);
            if not cfg.scoreaktiv then ;
          end
          else cfg.scoreaktiv := false;
          try        { dadurch werden alle eMailaccounts durchlaufen }
            callpop3 := (cfg.pop3server <> '') {and (i = 1)};
            callsmtp := (cfg.smtpserver <> '') {and (i = 1)} and
                        exist_wild (parstr (cfg.smtpspool, 1) + 'm*.out');
            callnntp := (cfg.nntpserver <> '');
            if cfg.smtpafterpop then begin
              if callpop3 then begin
                t1 := syssysmscount;
                getmail (cfg, filtern);
                t2 := syssysmscount;
                if (t2 < t1) or (t1 < 0) or (t2 < 0)
                  then t1 := 0
                  else t1 := t2 - t1;
                if cfg.smtpafterpopdelay > 0
                  then if cfg.smtpafterpopdelay * 1000 > t1
                    then sysctrlsleep (cfg.smtpafterpopdelay * 1000 - t1)
              end;
              if callsmtp then sendmail (cfg);
            end
            else begin
              if callsmtp then sendmail (cfg);
              if callpop3 then getmail (cfg, filtern);
            end;
            if not callpop3 and (debug > 0) {and (i = 1)} then begin
              writelog ('Keine Mail geholt, weil ...', logboth);
              if cfg.pop3server = ''
                then writelog (' - kein POP3-Server eingetragen ist', logboth);
            end;
            if not callsmtp and (debug > 0) {and (i = 1)} then begin
              writelog ('Keine Mail versendet, weil ...', logboth);
              if cfg.smtpserver = ''
                then writelog (' - kein SMTP-Server eingetragen ist', logboth);
              if not exist_wild (parstr (cfg.smtpspool, 1) + 'm*.out')
                then writelog (' - nichts zu versenden ist, Verzeichnis:' +
                               parstr (cfg.smtpspool, 1), logboth);
            end;

            if callnntp then begin
              getnglist (cfg);
              postnews (cfg);
              getnews (cfg, filtern);
            end
            else if debug > 0 then begin
              writelog ('Keine News geholt, weil ...', logboth);
              if cfg.nntpserver = ''
                then writelog (' - kein NNTP-Server eingetragen ist', logboth);
            end;
          finally
            if cfg.scoreaktiv then done_score;
            if filtern then pho.twj_del_list;
            cfg.free;
          end;
        end;
      finally
        if not verbose then begin
          info.free;
          gotoxy (1, 25);
        end;
      end;
    except
      on e: exp3pconfigerror do writelog ('Error (main): ' + e.message,
                                          logboth);
      on e: exception  do
      begin
        writelog ('Exception ' + e.classname + ' at address ' +
                  inttohex (longint (exceptaddr), 8) + '.', logboth);
        if getlocationinfo (exceptaddr, sourcename, linenr) <> nil
          then writelog ('File: ' + sourcename + ', line #' +
                         inttostr (linenr), logboth);
        writelog (e.message, logboth);
      end;
    end;
  end;

procedure show_copyright;
  begin
    writeln (xp3pcopyr1);
    writeln (xp3pcopyr2);
    writeln;
  end;

procedure show_help;
  begin
    writeln;
{   writeln ('Usage: xp3p.exe -config:<configfile> [-h] [-v] [-smtp] [-debug[1..9]]'); }
    writeln ('Usage: xp3p.exe <configfile> [-h] [-v] [-smtp] [-debug[1..9]]');
    writeln;
{   writeln (' -config:<file> configuration file (*.BFG)'); }
    writeln (' <configfile>   configuration file (*.BFG)');
    writeln (' -h             help');
    writeln (' -v             verbose mode');
    writeln (' -smtp          make batched smtp files');
    writeln (' -debugX        make debug level X logfile (where X is between 1 and 2)');

    writeln (' -multiX        X=0: no multithreading');
    writeln ('                X=1: news multithreading');
    writeln ('                X=2: complete multithreading (default)');

    writeln;
    halt (err_noparam);
  end;

procedure myexit; far;
  begin
    exitproc := saveexit;
{$ifdef os2}
    sempostevent (semaccessevent (sem_xp3p));
{$endif}
//    sysctrlsleep (6000);
  end;

procedure init;

 {$IFDEF XPTEST}
  const cfgu = 0; { unknown }
        cfgo = 1; { OpenXP }
        cfgx = 2; { XP2 }
 {$ENDIF}

  var i: word;
      ps: string;
     {$IFDEF XPTEST} config: integer; {$ENDIF}

  procedure get_xp_logdir; { und Test auf XP2 / OpenXP }
   {$IFDEF XPTEST}
    const dv : string = ']|uOp\nMti'; { 'DelViEwTmp' xor $19 }
          ox : string = 'Vi|wAI';     { 'OpenXP' xor $19 }
          xx : string = 'Ai+';        { 'Xp2' xor $19 }
          xy : string = '1aI+0';      { '(xP2)' xor $19 }
          xe : string = 'aI7|A\';     { 'xP.eXE' xor $19 }
          xp : string = 'ZkVjJIvpWm'; { 'CrOsSPoiNt' xor $19 }
          hr : string = 'Qp}\K|';     { 'HidERe' xor $19 }
          hm : string = 'qP}|TuQ\x]'; { 'hIdeMlHEaD' xor $19 }
          df : string = '}\_xlUmjXo|_Pu\'; { 'dEFauLtsAveFIlE' xor $19 }
   {$ENDIF}

    var savefm: longint;
        t: text;
        f: file;
        s: ansistring;
        z: string;

   {$IFDEF XPTEST}
    procedure xu (var s: string);
      var i: integer;
      begin
        for i := 1 to length (s) do s [i] := char (byte (s [i]) xor $19);
        s := uppercase (s);
      end;
   {$ENDIF}

    begin
      xp_logdir := '';
     {$IFDEF XPTEST}
      config := cfgu;
      xu (dv);
      xu (ox);
      xu (xy);
      xu (xp);
      xu (hr);
      xu (hm);
      xu (df);
     {$ENDIF}
(*
      xu (xx);
      xu (xe);
      if exist (xp_path + xe) then begin
        savefm := filemode;
        filemode := 0;
        assign (f, xp_path + xe);
        reset (f, 1);
        filemode := savefm;
        setlength (s, filesize (f));
        blockread (f, s [1], filesize (f));
        close (f);
        s := uppercase (s);
        if pos (xx, s) > 0 then config := cfgx;
        if pos (ox, s) > 0 then config := cfgo;
      end;
*)
      if not exist (xp_path + xp_cfg)
        then errorhalt('Fehler: Datei ' + xp_path + xp_cfg +
                       ' nicht gefunden', err_nofile);
      savefm := filemode;
      filemode := 0;
      assign (t, xp_path + xp_cfg);
      reset (t);
      filemode := savefm;
      while not eof(t) do begin
        readln (t, z);
        delspace (z);
        z := uppercase (z);
        if pos ('LOGDIR=', z) = 1 then begin
          delete (z, 1, 7);
          xp_logdir := z;
          delspace (xp_logdir);
          // xp_logd_ok := true;
        end
       {$IFDEF XPTEST}
        else if (pos (dv, z) = 1) then config := cfgo
        else if (pos (xp, z) = 4) and (pos (ox, z) > 4) then config := cfgo
        else if (pos (xp, z) = 4) and
                (pos (xy, z) > 4) and (config = cfgu) then config := cfgx
        else if (pos (hr, z) = 1) and (config = cfgu) then config := cfgx
        else if (pos (hm, z) = 1) and (config = cfgu) then config := cfgx
        else if (pos (df, z) = 1) and (config = cfgu) then config := cfgx
       {$ENDIF}
        ;
      end;
      close (t);
    end;

  begin
    saveexit := exitproc;
    exitproc := @myexit;

    { TWJ: SpeedAnzeige }
    twj_ut1 := pho.twj_unixtime;
    twj_speed := 0;

    showhelp := false;
    // xp_logd_ok := false;
    debug := 0;
    multi := 2;
    verbose := false;
    smtp := false;
    newsfcnt := 0;

    confign := xp3pnorev;
    { Zugriff auf String erzeugen, damit er nicht rausoptimiert wird }

    confign := '';

    hidecursor;
    show_copyright;

    for i := 1 to paramcount do begin
      ps := paramstr (i);
      ps := uppercase (ps);
      if ((ps [1] = '/') or (ps [1] = '-')) and (length (ps) > 1) then begin
        delete (ps, 1, 1);
        if (ps = 'H') or (ps = 'HELP') or (ps = '?') then showhelp := true
        else if ps = 'V' then verbose := true
        else if ps = 'SMTP' then smtp := true
        else if pos ('DEBUG', ps) = 1 then begin
          if (length (ps) = 6) and (ps [6] in ['1' .. '9'])
          then debug := strtoint (copy (ps, 6, 1))
          else debug := 1;
        end

(* mAx: erst mal wieder abschalten, wird vieleicht doch nie gebraucht

        else if pos ('MULTI', ps) = 1 then begin
          if (length (ps) = 6) and (ps [6] in ['1' .. '9'])
          then multi := strtoint (copy (ps, 6, 1))
          else multi := 2;
          if multi > 2 then multi := 2;
        end
*)
        else if pos ('CONFIG:', ps) = 1 then begin
          delete (ps, 1, 7);
          if length (ps) = 0
            then errorhalt ('Fehler: -config: Parameterformat falsch', err_errsw);
          while pos ('\', ps) > 0 do delete (ps, 1, 1);
          if pos ('.BFG', ps) = length (ps) - 3
            then delete (ps, length (ps) - 3, 4);
          confign := confign + ' ' + ps;
        end
        else if pos ('WORKDIR:', ps) = 1 then begin
          delete (ps, 1, 8);
          if length (ps) = 0
            then errorhalt ('Fehler: -workdir: Parameterformat falsch', err_errsw);
          chdir (ps);
        end
        else errorhalt ('Fehler: ungÅltiger Schalter: ' + ps + crlf
                        + crlf + 'Hilfe zu den Aufrufparametern mit XP3P -?' + crlf, err_badsw);
      end
      else if pos ('.BFG', ps) = length (ps) - 3 then begin
        delete (ps, length (ps) - 3, 4);
        while pos ('\', ps) > 0 do delete (ps, 1, 1);
        confign := confign + ' ' + ps;
      end
      else errorhalt ('Fehler: ungÅltiger Parameter: ' + ps + crlf
                      + crlf + 'Hilfe zu den Aufrufparametern mit XP3P -?' + crlf, err_badsw);
    end;

    delspace (confign);

    if showhelp or (paramcount = 0) then show_help;

    if confign = ''
      then errorhalt ('Fehler: keine Config-Datei angegeben', err_nofile);

    my_path := paramstr (0);
    while (length (my_path) > 0)
      and (my_path [length (my_path)] <> '\')
      do delete (my_path, length (my_path), 1);

    xp_path := getenv ('XP');
    if length (xp_path) = 0 then xp_path := my_path;

    if (length (xp_path) > 0)
      and (xp_path [length (xp_path)] <> '\') then xp_path := xp_path + '\';

    xp_spooldir := xp_path + 'spool\';

    if not dir_exist (xp_spooldir)
      then errorhalt ('Fehler: XP-Pfad ' + xp_path + ' falsch oder '
                      + 'SPOOL-Verzeichnis nicht gefunden.', err_noxp);

    get_xp_logdir;

   {$IFDEF XPTEST}
    if config <> cfgx
      then errorhalt ('Fehler: Falsche CrossPoint Version.', err_wrongxp);
   {$ENDIF}

    if length (xp_logdir) = 0 then xp_logdir := xp_path;

    if not dir_exist (xp_logdir) or (length (xp_logdir) = 0)
      then errorhalt ('Fehler: XP-Pfad ' + xp_path + ' falsch oder '
                      + 'LOG-Verzeichnis nicht gefunden.', err_noxp);

    appendtofile (xp_logdir + logn, '');
    appendtofile (xp_logdir + logn, xp3pcopyr1);
    appendtofile (xp_logdir + logn, xp3pcopyr2);
    appendtofile (xp_logdir + logn, '');

(* mAx: Routine umgezogen nach MAIN!

    { TWJ 080801 - Daten fuer PHO laden und in den Speicher schauffeln }
    { mAx: nach MAIN verlagert...}
    if pho.twj_oeffne_datei (my_path) then begin
      pho.twj_create_list;
      logtofile (xp_logdir + logn, 'Reading PHO-Filter...');
    end;
*)
  end;

procedure done;
  begin
//    pho.twj_del_list; wird in MAIN fÅr jede Box separat ausgefÅhrt
    showcursor;
  end;

begin
  init;
  main;
  done;
end.


{
  $Log: xp3p.pas,v $
  Revision 1.16  2002/01/06 20:35:08  MH
  - Log fuer Score hinzugefuegt: Aber nur bei score <> 0

  Revision 1.15  2002/01/06 19:34:56  MH
  - Log fuer Score hinzugefuegt
  - Copyright 2002 hinzugefuegt

  Revision 1.14  2002/01/06 12:14:45  MH
  - Quit vor Disconnect bei Smtp

  Revision 1.13  2002/01/06 10:10:09  MH
  - Alte SmtpAuth-Parameter beachten (disabled = keine)

  Revision 1.12  2002/01/05 14:03:31  MH
  - Tippfehler beseitigt
  - SmtpAuth (LOGIN) implementiert
  - APOP optimiert (ueberfluessigen Code entfernt)

  Revision 1.11  2002/01/04 19:04:09  MH
  - OpenXP-Unterstuetzung fuer W32-Version
  - Schalter hinzugefuegt: NntpFallback und SmtpAuth

  Revision 1.10  2002/01/03 19:10:41  MH
  - Filterabfrage in GetMail ergaenzt

  Revision 1.9  2002/01/02 23:16:48  MH
  # Komplette Ueberarbeitung der letzten Tage:
  - Fix: AccessViolations -> HugoStrings = AnsiString != String
    (evtl. Bug in Sysutils: Exception.Message)
  - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
  - Anpassungen an neuer Schnittstelle
  - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
  - CPS-SpeedAnzeige im Screen (TWJ)
  - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                        ein TimeStamp mit dem Password crypted werden muﬂ?!?

  Revision 1.8  2001/08/15 19:23:25  rb
  mm: Cursor verstecken, Anpassung an Parameterformat in BFG-Datei

  Revision 1.7  2001/08/14 07:58:00  mm
  - Kommando zurueck... :-)

  Revision 1.3  2001/07/21 21:03:21  rb
  Bugfix

  Revision 1.2  2001/07/16 19:59:08  rb
  ParameterÅbergabe

  Revision 1.1  2001/07/11 19:47:19  rb
  checkin

}
