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
{ $Id: xp0.pas,v 1.94 2002/01/01 12:13:16 mm Exp $ }

{ CrossPoint - Deklarationen }

{$I XPDEFINE.INC}

unit xp0;

interface

uses   xpglobal, dos,typeform,keys;


{ Die folgenden drei Konstanten mÅssen Sie in XPGLOBAL.PAS !!!      }
{ ergÑnzen, bevor Sie CrossPoint compilieren kînnen. Falls Die das  }
{ compilierte Programm weitergeben mîchten, mÅssen der angegebene   }
{ Name korrekt und die E-Mail-Adresse erreichbar sein               }
{ (siehe LIZENZ.TXT). Beispiel:                                     }
{                                                                   }
{ const  author_name = 'Ralf MÅller';                               }
{        author_mail = 'ralf@t-offline.de';                         }
{        x_copyright = '(c) 2001';                                  }
{                                                                   }
{ Diese Informationen werden bei Programmstart und bei              }
{ /XPoint/Registrierung angezeigt.                                  }



const  {$IFDEF DPMI}
       IsDPMI      = true;
       {$ELSE}
       IsDPMI      = false;
       {$ENDIF}

       LangVersion = '13';           { Version des Sprachmoduls }
       menus       = 41;             { Anzahl der Menus }
       ZeilenMenue = 11;
       maxbmark    = 1000;           { maximal markierbare User/Bretter }
       maxmarklist = 5000;           { MK: Maximale Anzahl markierter Msgs }
       QuoteLen    = 5;              { maximale QuoteChar-LÑnge }
       Ablagen     = 20;             { 0..9 }
       maxpmc      = 3;              { installierbare pmCrypt-Verfahren }
       MaxSigsize  = 300;            { maximale Signaturgrî·e (Bytes) }
       maxkeys     = 100;            { s. auch XP10.maxentries }
       excludes    = 4;              { Anzahl Ausschlu·zeiten  }
       maxskeys    = 15;             { max. Tasten in Zeile 2  }
       mausdefx    = 620;            { Maus-Startposition      }
       mausdefy    = 28;
       MaxNodelists = 100;
       MaxAKAs     = 10;
       maxviewers  = 7;
       defviewers  = 3;
       maxpmlimits = 7;              { Z/Maus/Fido/UUCP/Magic/QMGS/PPP }
       maxheaderlines = 40;
       MaxXposts   = 15;
       MaxCom      = 5;

       BoxNameLen  = 20;             { diese LÑngenangaben sollten fÅr }
       BoxRealLen  = 15;             { alle Bearbeitungs-Variablen fÅr }
       BrettLen    = 81;             { die entsprechenden Felder ver-  }
       eBrettLen   = 79;             { wendet werden                   }
       AdrLen      = 80;
       eAdrLen     = 79;
       BetreffLen  = 248;            { 255 abzÅglich 'BET: ' und #13#10 }
       DateLen     = 11;
       midlen      = 120;
       AKAlen      = 127;
       OrgLen      = 80;             { Organisation }
       PostadrLen  = 80;             { Postadresse }
       TeleLen     = 100;            { Telefon }
       HomepageLen = 90;             { WWW-Homepage }
       CustHeadLen = 60;             { Customizable Header-Lines }
       hdErrLen    = 60;
       ViewprogLen = 70;             { Kommandozeile fÅr ext. Viewer }
       ResMinmem   = 340000;
       realnlen    = 40;             { robo 01/00 LÑnge der Realnames }
       MsgFelderMax = 6;             { max. Feldzahl in der Nachrichtenliste }
       UsrFelderMax = 5;             { max. Feldzahl in der Userliste }

       patchlevel  : string[13] = '*patchlevel*0';
{$IFDEF Ver32 }
       xp_xp       : string[10] = 'XP2';
       xp_name     : string[30] = '## XP2 '+verstr+betastr;  { fÅr ZConnect-Header }
       xp_origin   : string[15] = '--- XP2';
{$ELSE }
       xp_xp       : string[10] = 'CrossPoint';
       xp_name     : string[30] = '## CrossPoint '+verstr+betastr;  { fÅr ZConnect-Header }
       xp_origin   : string[15] = '--- CrossPoint';
{$ENDIF }
       bfgver      : string[34] = '### XP2-Boxen Konfiguration';
       bfgnr       : string[9]  = ' [20] ###'; { BFG-File-Version }
       cfgnr       : string[8]  = ' [20] ##';  { CFG-File-Version }
       xp_short    : string[2]  = 'XP';
       QPC_ID      = 'QPC:';
       DES_ID      = 'DES:';
       PMC_ID      = '*crypted*';
       XPMC_ID     = '*Xcrypted*';
       TO_ID       = '/'#0#0#8#8'TO:';
       TO_len      = length(TO_ID);
       vert_char   = #4;             { Verteiler-Kennung }
       MausinfoBrett= '$/ØMausinfo';
       uuserver    = 'UUCP-Fileserver';

       PufferFile  = 'PUFFER';       { Z-Netz-Puffer }
       TPufferFile = 'TPUFFER';      { TurboBox-Puffer }
       XFerDir     = 'SPOOL\';       { eingehende Mailbatches }
       XFerDir_    = 'SPOOL';
       JanusDir    = 'SPOOL\JANUS\';
       JanusDir_   = 'SPOOL\JANUS';
       FidoDir     = 'FIDO\';        { Nodelists }
       FidoDir_    = 'FIDO';
       InfileDir   = 'FILES\';       { Default: Filerequests }
       AutoxDir    = 'AUTOEXEC\';    { AutoStart-Daten }
       BadDir      = 'BAD\';

       HeaderFile  = 'header.xps';     { Schablonen-Dateien }
       HeaderPriv  = 'privhead.xps';
       SignatFile  = 'signatur.xps';
       PrivSignat  = 'privsig.xps';
       QuoteMsk    = 'qbrett.xps';
       QuotePriv   = 'qpriv.xps';
       QuotePMpriv = 'qpmpriv.xps';
       QuoteToMsk  = 'quoteto.xps';
       WeiterMsk   = 'weiter.xps';
       ErneutMsk   = 'erneut.xps';
       EB_Msk      = 'empfbest.xps';
       CancelMsk   = 'cancel.xps';

       BfgExt      = '.BFG';           { Boxen-Config-File }
       QfgExt      = '.QFG';           { QWK-Config-File   }
       SwapExt     = '.SWP';

       MsgFile     = 'MSGS';           { DB1-Dateinamen }
       BrettFile   = 'BRETTER';
       UserFile    = 'USER';
       BoxenFile   = 'BOXEN';
       GruppenFile = 'GRUPPEN';
       SystemFile  = 'SYSTEME';
       DupeFile    = 'DUPEKILL';       { temporÑr in XP4O.DupeKill }
       AutoFile    = 'AUTOMSG';
       PseudoFile  = 'PSEUDOS';
       BezugFile   = 'BEZUEGE';
       MimetFile   = 'MIMETYP';

       CfgFile     = 'xpoint.cfg';     { verschiedene Dateien }
       Cfg2File    = 'xpoint2.cfg';
       ColCfgfile  = 'xpoint.col';
       NewDateFile = 'neues.dat';
       MsgTempFile = 'msg.tmp';
       AblagenFile = 'mpuffer.';
       UncryptedFile = 'crypt.msg';
       CryptedFile = 'crypt.enc';
       TimingFile  = 'timing.';
       TimingDat   = 'timing.dat';
       KilledDat   = 'reorg.dat';
       CCfile      = 'verteil.dat';
       FidoCfg     = 'fido.cfg';
       OldNLCfg    = FidoDir+'nodelist.cfg';
       NodelistCfg = FidoDir+'nodelst.cfg';
       NodeindexF  = FidoDir+'nodelist.idx';
       UserindexF  = FidoDir+'nodeuser.idx';
       ARCmailDat  = 'arcmail.dat';
       FileLists   = FidoDir+'filelist.cfg';
       ReqDat      = 'request.dat';    { Crashs + Requests }
       RegDat      = 'regdat.xp';
       UUnumdat    = 'uunummer.dat';
       FeierDat    = 'feiertag.dat';
       PGPkeyfile  = 'pgp-key.bin';
       PGPkeyfileAscii = 'pgp-key.asc';
       menufile    = 'xpmenu.dat';
       CrashTemp   = 'crash.tmp';
       MIDReqFile  = 'request.id';

       ErrlogFile  = 'errors.log';     { LogFiles }
       Logfile     = 'xpoint.log';
       BiLogFile   = 'logfile';        { fÅr BiModem-öbertragung }
       BrettlogFile= 'bretter.log';    { automatisch angelegte Bretter }
       UserlogFile = 'user.log';       { automatisch angelegte User }
       DupeLogfile = 'dupes.log';      { s. XP4.DupeKill }
       MausLogfile = 'maus.log';       { MAGGI: MausTausch-Logfile }
       MausPmLog   = 'mauspm.log';     { MAGGI: MausTausch-PM-Logfile }
       MausStLog   = 'mausstat.log';   { MAGGI: MausTausch-Nachrichtenstati }
       FidoLog     = 'xpfido.log';     { XP-FM-Logfile   }
       UUCPlog     = 'xpuucp.log';     { uucico-Logfile  }
       PPPlog      = 'xp-ppp.log';     { PPP-Logfile     }
       ScerrLog    = 'scerrors.log';   { Script-Fehler   }
       NetcallLog  = 'netcall.log';    { Netcall-Logfile }

       miBrett     = 1;                { BRETTNAME/EMPFDATUM/INT_NR         }
       miGelesen   = 2;                { BRETTNAME/GELESEN/EMPFDATUM/INT_NR }
       uiName      = 1;                { User:    +USERNAME                 }
       uiAdrbuch   = 2;                {          ADRBUCH/+USERNAME         }
       biBrett     = 1;                { Bretter: BRETTNAME                 }
       biGruppe    = 2;                {          GRUPPE                    }
       biIntnr     = 3;                {          INT_NR                    }
       biIndex     = 4;                {          INDEX                     }
       giName      = 1;                { Gruppen: +NAME                     }
       giIntnr     = 2;                {          INT_NR                    }
       boiName     = 1;                { Boxen:   +BOXNAME                  }
       boiDatei    = 2;                {          +DATEINAME                }
       siName      = 1;                { Systeme: +NAME                     }
       aiBetreff   = 1;                { AutoMsg: +BETREFF                  }
       piKurzname  = 1;                { Pseudos: +KURZNAME                 }
       beiMsgID    = 1;                { Bezuege: MsgID                     }
       beiRef      = 2;                {          Ref                       }
       mtiTyp      = 1;                { MimeType: +TYP                     }
       mtiExt      = 2;                {           +EXTENSION               }

       rmUngelesen = 1;                { ReadMode: Lesen/Ungelesen  }
       rmNeues     = 2;                { ReadMode: Lesen/Neues      }
       rmHeute     = 3;                { ReadMode: Lesen/Heute      }

       MaxHdsize   = 2000;             { maximal *erzeugte* Headergrî·e }

       AttrQPC     = $0001;            { QPC-codierte Nachricht     }
       AttrCrash   = $0002;            { header.attrib: Crashmail   }
       AttrPmcrypt = $0004;            { pmCrypt-codierte Nachricht }
       AttrIgate   = $0008;            { IGATE.EXE-Nachricht        }
       AttrFile    = $0010;            { File attached              }
       AttrControl = $0020;            { Cancel-Nachricht           }
       AttrMPbin   = $0040;            { Multipart-Binary           }
       AttrPmReply = $0100;            { PM-Reply auf AM (Maus/RFC) }
       AttrQuoteTo = $0400;            { QuoteTo (Maus)             }
       AttrReqEB   = $1000;            { EB anfordern               }
       AttrIsEB    = $2000;            { EB                         }

       fPGP_encoded  = $0001;          { Nachricht ist PGP-codiert  }
       fPGP_avail    = $0002;          { PGP-Key vorhanden          }
       fPGP_signed   = $0004;          { Nachricht ist mit PGP sign.}
       fPGP_clearsig = $0008;          { Clear-Signatur             }
       fPGP_sigok    = $0010;          { Signatur war ok            }
       fPGP_sigerr   = $0020;          { Signatur war fehlerhaft    }
       fPGP_please   = $0040;          { Verifikations-Anforderung  }
       fPGP_request  = $0080;          { Key-Request                }
       fPGP_haskey   = $0100;          { Nachricht enthÑlt PGP-Key  }
       fPGP_comprom  = $0200;          { Nachricht enthÑlt compromise }

       fattrHalten   = $0001;          { Nachricht auf "halten"     }
       fattrLoeschen = $0002;          { Nachricht auf "lîschen"    }
       fattrGelesen  = $0004;          { Nachricht auf "gelesen"    }
       fattrHilite   = $0008;          { Nachricht hervorheben      }

       {fattrPrio1    = 8;              { PrioritÑt: Hîchste         }
       {fattrPrio2    = 16;             { PrioritÑt: Hoch            }
       {fattrPrio4    = 24;             { PrioritÑt: Niedrig         }
       {fattrPrio5    = 32;             { PrioritÑt: Niedrigste      }

       {$ifndef ver32}
       kommlmax   = 6;                             { Kommentarbaum }
       kommemax   = kommlmax * wordsize + 1;       { maximale Tiefe }
       maxkomm    = 65520 div (6 + kommlmax * (wordsize div 8)); { max. Nachr. }
       {$else}
       kommlmax   = 3;                             { Kommentarbaum }
       kommemax   = kommlmax * wordsize + 1;       { maximale Tiefe }
       maxkomm    = 262080 div (6 + kommlmax * (wordsize div 8)); { max. Nachr. }
       {$endif}

       kflLast    = 1;
       kflBetr    = 2;
       kflPM      = 4;
       kflBrett   = 8;                 { Brettwechsel }

       hdf_Trenn  = 0;                 { Nummern fÅr Header-Felder }
       hdf_EMP    = 1;
       hdf_ABS    = 2;
       hdf_BET    = 3;        hdf_OAB     = 13;     hdf_TEL      = 23;
       hdf_EDA    = 4;        hdf_OEM     = 14;     hdf_MSTAT    = 24;
       hdf_ROT    = 5;        hdf_WAB     = 15;     hdf_KOP      = 25;
       hdf_MID    = 6;        hdf_ERR     = 16;     hdf_PGPSTAT  = 26;
       hdf_LEN    = 7;        hdf_ANTW    = 17;     hdf_Homepage = 27;
       hdf_BEZ    = 8;        hdf_DISK    = 18;     hdf_Part     = 28;
       hdf_MAILER = 9;        hdf_STW     = 19;     hdf_Priority = 31; {!MH:}
       hdf_FILE   = 10;       hdf_ZUSF    = 20;     hdf_xNoArchive = 32; {!MH:}
       hdf_STAT   = 11;       hdf_DIST    = 21;     hdf_XP_Mode = 33;
       hdf_ORG    = 12;       hdf_POST    = 22;
       hdf_Cust1  = 29;
       hdf_Cust2  = 30;

type   textp  = ^text;
       ColArr = array[0..3] of byte;
       ColQArr= array[1..9] of byte;
       ColRec = record
                  ColMenu       : ColArr; { Normaler MenÅtext       }
                  ColMenuHigh   : ColArr; { Direkt-Buchstaben       }
                  ColMenuInv    : ColArr; { MenÅ-Balken             }
                  ColMenuInvHi  : ColArr; { MenÅ-Balken/Buchstabe   }
                  ColMenuDis    : ColArr; { MenÅ disabled           }
                  ColMenuSelDis : ColArr; { MenÅ disabled/gewÑhlt   }
                  ColKeys       : byte;   { Direkttasten            }
                  ColKeysHigh   : byte;   { Direkttasten-Buchstaben }
                  ColKeysAct    : byte;   { aktivierte Taste        }
                  ColKeysActHi  : byte;   { aktivierter Buchstabe   }
                  ColTLine      : byte;   { Trennlinie              }
                  ColBretter    : byte;   { User / Bretter          }
                  ColBretterInv : byte;   { User / Bretter, gewÑhlt }
                  ColBretterHi  : byte;   { User / Bretter, markiert}
                  ColBretterTr  : byte;   { Trennzeile              }
                  ColMsgs       : byte;   { Msgs                    }
                  ColMsgsHigh   : byte;   { Msgs, markiert          }
                  ColMsgsInv    : byte;   { Msgs, gewÑhlt           }
                  ColMsgsInfo   : byte;   { Msgs, 1. Zeile          }
                  ColMsgsUser   : byte;   { PM-archivierte Msgs     }
                  ColMsgsInvUser: byte;   { gewÑhlt+hervorgehoben   }
                  ColMsgsPrio1  : byte;   { Farbe fuer Priority 1   }
                  ColMsgsPrio2  : byte;   { ... 2 }
                  ColMsgsPrio4  : byte;   { ... 4 }
                  ColMsgsPrio5  : byte;   { ... 5 }
                  ColMsgsInvPrio: byte;   { Prio. gewÑhlt+hervorgehoben }
                  ColMbox       : byte;   { Meldungs-Box, Text      }
                  ColMboxRahmen : byte;   { Meldungs-Box, Rahmen    }
                  ColMboxHigh   : byte;   { Meldungs-Box, hervorgeh.}
                  ColMboxEHigh  : byte;   { MBox eigene Msgs hervorgehoben }
                  ColMboxCHigh  : byte;   { MBox Cancel/S.-Sedes hervorgeh.}
                  ColMboxPHigh  : byte;   { MBox Priority hervorgeh.}
                  ColDialog     : byte;   { Dialoge, Feldnamen u.Ñ. }
                  ColDiaRahmen  : byte;   { Dialogbox, Rahmen       }
                  ColDiaHigh    : byte;   { Dialogbox, hervorgeh.T. }
                  ColDiaInp     : byte;   { Dialogbox, Eingabefeld  }
                  ColDiaMarked  : byte;   { Dial., markierter Text  }
                  ColDiaArrows  : byte;   { Pfeile bei Scrollfeldern}
                  ColDiaSel     : byte;   { Masken-Auswahlliste     }
                  ColDiaSelBar  : byte;   {            "            }
                  ColDiaButtons : byte;   { Check/Radio-Buttons     }
                  ColSelbox     : byte;   { Auswahlbox              }
                  ColSelRahmen  : byte;   { Auswahlbox, Rahmen      }
                  ColSelHigh    : byte;   { Auswahlbox, hervorgeh.  }
                  ColSelBar     : byte;   { Auswahlbox, Balken      }
                  ColSelBarHigh : byte;   { Auswahlbox, Balken/hv.  }
                  ColSel2box    : byte;   { Auswahlbox / dunkel     }
                  ColSel2Rahmen : byte;   { Auswahlbox, Rahmen      }
                  ColSel2High   : byte;   { Auswahlbox, hervorgeh.  }
                  ColSel2Bar    : byte;   { Auswahlbox, Balken      }
                  ColButton     : byte;   { Button                  }
                  ColButtonHigh : byte;   { Button - Hotkeys        }
                  ColButtonArr  : byte;   { aktiver Button: Pfeile  }
                  ColUtility    : byte;   { Kalender u.Ñ.           }
                  ColUtiHigh    : byte;
                  ColUtiInv     : byte;
                  ColHelp       : byte;   { Hilfe normal            }
                  ColHelpHigh   : byte;   { hervorgehobener Text    }
                  ColHelpQVW    : byte;   { Querverweis             }
                  ColHelpSlQVW  : byte;   { gewÑhlter Querverweis   }
                  ColListText   : byte;   { Lister, normaler Text   }
                  ColListMarked : byte;   { Lister, markiert        }
                  ColListSelbar : byte;   { Lister, Auswahlbalken   }
                  ColListFound  : byte;   { Lister, nach Suche mark.}
                  ColListStatus : byte;   { Lister, Statuszeile     }
                  ColListQuote  : ColQArr; { Quote-Zeilen + Maps"J" }
                  ColListScroll : byte;   { vertikaler Scroller     }
                  ColListHeader : byte;   { Nachrichtenkopf         }
                  ColListHigh   : byte;   { *hervorgehoben*         }
                  ColListQHigh  : ColQArr; { Quote / *hervorgehoben* }
                  ColEditText   : byte;   { Editor, normaler Text   }
                  ColEditStatus : byte;   { Editor, Statuszeile     }
                  ColEditMarked : byte;   { Editor, markierter Blck.}
                  ColEditMessage: byte;   { Editor-Meldung          }
                  ColEditHead   : byte;   { TED: Info-Kopf          }
                  ColEditQuote  : ColQArr; { TED: farbige Quotes     }
                  ColEditEndmark: byte;   { TED: Endmarkierung      }
                  ColEditMenu   : byte;   { TED: MenÅ               }
                  ColEditMenuHi : byte;   { TED: Hotkey             }
                  ColEditMenuInv: byte;   { TED: Selbar             }
                  ColEditHiInv  : byte;   { TED: gewÑhlter Hotkey   }
                  ColArcStat    : byte;   { Status-Zeile ArcViewer  }
                  ColMapsBest   : byte;   { bestellte Bretter       }
                  ColMailer     : byte;   { Fido-Mailer/uucico      }
                  ColMailerhigh : byte;   { .. hervorgehoben #1     }
                  ColMailerhi2  : byte;   { .. hervorgehoben #2     }
                  ColBorder     : byte;   { Rahmenfarbe             }
                end;

       { alle nicht genutzen Headerzeilen sollten = 0 sein         }
       { Netztypen: 0=Netcall, 1=Pointcall, 2=ZConnect, 3=MagicNET }
       {            10=QM, 11=GS, 20=Maus, 30=Fido, 40=RFC, 41=PPP }
       {            90=Turbo-Box                                   }

       OrgStr      = string[OrgLen];
       AdrStr      = string[AdrLen];
       TeleStr     = string[TeleLen];
       HomepageStr = string[HomepageLen];
       CustHeadStr = string[CustHeadLen];
       pviewer     = ^string;

       refnodep= ^refnode;             { Datentyp fÅr Reference-Liste }
       refnode = record
                   next  : refnodep;
                   ref   : string[midlen];
                 end;
       empfnodep=^empfnode;
       empfnode= record
                   next   : empfnodep;
                   empf   : AdrStr;
                 end;

       header = record
                  netztyp    : byte;          { --- intern ----------------- }
                  archive    : boolean;       { archivierte PM               }
                  attrib     : word;          { Attribut-Bits                }
                  filterattr : word;          { Filter-Attributbits          }
                  empfaenger : string[90];    { --- allgemein --- Brett / User / TO:User }
                  kopien     : empfnodep;     { KOP: - Liste }
                  empfanz    : integer;       { Anzahl EMP-Zeilen }
                  betreff    : string[BetreffLen];
                  absender   : string[80];
                  datum      : string[11];    { Netcall-Format               }
                  zdatum     : string[22];    { ZConnect-Format; nur auslesen }
                  orgdate    : boolean;       { Ausnahme: zdatum schreiben   }
                  pfad       : string;        { Netcall-Format               }
                  msgid,ref  : string[midlen];{ ohne <>                      }
                  ersetzt    : string[midlen];{ ohne <>                      }
                  refanz     : integer;       { Anzahl BEZ-Zeilen            }
                  typ        : string[1];     { T / B                        }
                  crypttyp   : string[1];     { '' / T / B                   }
                  charset    : string[7];
                  ccharset   : string[7];     { crypt-content-charset }
                  groesse    : longint;
                  realname   : string[realnlen]; { MK 01/00 UUZ Fix von robo }
                  programm   : string[120];   { Mailer-Name }
                  organisation : OrgStr;
                  postanschrift: string[PostAdrLen];
                  telefon    : TeleStr;
                  homepage   : HomepageStr;
                  PmReplyTo  : AdrStr;        { Antwort-An    }
                  AmReplyTo  : AdrStr;        { Diskussion-In }
                  amrepanz   : integer;       { Anzahl Diskussion-in's }
                  komlen     : longint;       { --- ZCONNECT --- Kommentar-LÑnge }
                  ckomlen    : longint;       { Crypt-Content-KOM }
                  datei      : string[40];    { Dateiname                  }
                  ddatum     : string[14];    { Dateidatum, jjjjmmtthhmmss }
                  prio       : byte;          { 10=direkt, 20=Eilmail      }
                  error      : string[hdErrLen]; { ERR-Header              }
                  oem,oab,wab: AdrStr;
                  oar,war    : string[realnlen];    { Realnames }
                  real_box   : string[20];    { --- Maggi --- falls Adresse = User@Point }
                  hd_point   : string[25];    { eigener Pointname }
                  pm_bstat   : string[20];    { --- Maus --- Bearbeitungs-Status }
                  org_msgid  : string[midlen];
                  org_xref   : string[midlen];
                  ReplyPath  : string[8];
                  ReplyGroup : string[40];    { Kommentar-zu-Gruppe          }
                  fido_to    : string[36];    { --- Fido ------------------- }
                  x_charset  : string[25];    { --- RFC -------------------- }
                  keywords   : string[60];
                  summary    : string[200];
                  priority   : byte;          { Priority: 1, 3, 5 }
                  distribution:string[40];
                  pm_reply   : boolean;       { Followup-To: poster }
                  quotestring: string[20];
                  empfbestto : string[AdrLen];
                  pgpflags   : word;          { PGP-Attribut-Flags           }
                  pgp_uid    : string[80];    { alternative Adresse          }
                  vertreter  : string[80];
                  XPointCtl  : longint;
                  nokop      : boolean;
                  boundary   : string[70];    { MIME-Multipart-Boundary      }
                  mimetyp    : string[30];
                  xnoarchive : boolean; { MK 01/00 fÅr UUZ Fix von Robo }
                  xpmode     : string[20];
                  xpmsg      : string[6];
                  Cust1,Cust2: CustHeadStr;
                end;
       headerp = ^header;

       markrec  =  record
                     recno : longint;
                     datum : longint;
                     intnr : longint;
                   end;

       marklist = array[0..maxmarklist] of markrec;
       marklistp= ^marklist;
       bmarklist= array[0..maxbmark-1] of longint;
       bmarkp   = ^bmarklist;

       tMsgID = record
                  aktiv: byte;           { 1 Byte }
                  zustand: byte;         { 1 Byte }
                  box: string [8];       { 1 Laengenbyte + 8 Character }
                  mid: string [255];     { 1 Laengenbyte + 255 Character }
                end;

       ComRec = record
                  Fossil : boolean;
                  Cport  : word;        { UART-Adresse   }
                  Cirq   : byte;        { 0..7           }
                  MInit  : ^string;
                  MExit  : ^string;
                  MDial  : ^string;     { WÑhlbefehl     }
                  Warten : byte;        { Warten auf Modem-Antwort }
                  IgCD   : boolean;     { CD ignorieren  }
                  IgCTS  : boolean;     { CTS ignorieren }
                  UseRTS : boolean;     { RTS-Handshake  }
                  Ring   : boolean;     { RING-Erkennung }
                  u16550 : boolean;     { FIFO verwenden }
                  postsperre : boolean; { 30-Sek.-MinimalwÑhlpause }
                  tlevel : byte;        { FIFO trigger level }
                end;

       BoxRec = record
                  boxname   : string[20];   { redundant; wird aus .. }
                  pointname : string[25];
                  username  : string[30];
                  _replyto  : string[80];
                  _domain   : string[60];   { .. BOXEN.DB1 kopiert   }
                  _fqdn     : string[60];   {16.01.00 HS}
                  passwort  : string[20];
                  telefon   : string[60];
                  zerbid    : string[4];
                  uploader  : string[127];
                  downloader: string[127];
                  zmoptions : string[60];
                  prototyp  : string[1];    { Protokoll-Typ /Maus }
                  uparcer   : string[100];
                  downarcer : string[100];
                  unfreezer : string[40];
                  ungzipper : string[40];
                  uparcext  : string[3];
                  downarcext: string[3];
                  connwait  : integer;
                  loginwait : integer;
                  redialwait: integer;
                  redialmax : integer;
                  connectmax: integer;
                  packwait  : integer;
                  retrylogin: integer;
                  conn_time : integer;      { Modem-Connect-Zeit }
                  owaehlbef : string[10];   { wird nicht mehr verwendet! }
                  modeminit : string[60];
                  mincps    : integer;
                  bport     : byte;
                  params    : string[3];
                  baud      : longint;
                  gebzone   : string[20];
                  SysopInp  : string[60];  { Eingabe-Puffer fÅr SysMode }
                  SysopOut  : string[60];  { Zieldatei fÅr Sysop-Mode  }
                  SysopStart: string[60];
                  SysopEnd  : string[60];
                  O_passwort: string[25];  { Online-Pa·wort }
                  O_logfile : string[60];  { Online-Logfile }
                  O_script  : string[45];  { Online-Script  }
                  MagicNet  : string[8];   { Name des MagicNet's..     }
                  MagicBrett: string[25];  { Bretthierarchie fÅr Magic }
                  lightlogin: boolean;     { LightNET-Login: \ statt ^F}
                  exclude   : array[1..excludes,1..2] of string[5];
                  FPointNet : smallword;   { Fido: Pointnetz-Nr.       }
                  f4D       : boolean;     { Fido: 4D-Adressen         }
                  fTosScan  : boolean;     { Fido: Box benutzt TosScan }
                  AreaPlus  : boolean;     { Fido: "+" bei AreaFix     }
                  AreaBetreff:boolean;     { Fido: -q / -l             }
                  AreaPW    : string[12];  { Fido/UUCP: Areafix-PW     }
                  FileScanner:string[15];  { Fido: Filescan-Name       }
                  FilescanPW: string[12];  { Fido: Filescan-Pa·wort    }
                  EMSIenable: boolean;     { Fido: EMSI mîglich        }
                  AKAs      : string[AKAlen]; { Fido: lokale AKA-Liste }
                  SendAKAs  : string[AKAlen]; { Fido: Pakete mitsenden fÅr.. }
                  GetTime   : boolean;     { Fido: TRX#-Zeit setzen    }
                  SendTrx   : boolean;     { Fido: TRX# senden - undok }
                  NotSEmpty : boolean;     { Fido: kein sendempty - "  }
                  PacketPW  : boolean;     { Fido: Paketpa·wort senden }
                  ExtPFiles : boolean;     { Fido: erweiterte Paketdateinamen }
                  LocalIntl : boolean;     { Fido: ~d'Bridge-Areafix   }
                  Brettmails: boolean;     { Turbo-Box/Maus:  Brettnachr. }
                  LoginName : string[20];  { UUCP/QM: login-Username   }
                  UUCPname  : string[8];   { uucico-Systemname         }
                  MaxWinSize: byte;        { UUCP: max. Windowgrî·e    }
                  MaxPacketSize:smallword;      { UUCP: max. Blockgrî·e     }
                  VarPacketSize:boolean;   { UUCP: variable Blockgrî·e }
                  ForcePacketSize:boolean; { UUCP: SendWinsize=RecvWinsize }
                  UUprotos  : string[10];  { UUCP: mîgl. Protokolle    }
                  SizeNego  : boolean;     { UUCP: size negotiation    }
                  UUsmtp    : boolean;     { UUCP: SMTP                }
                  eFilter   : string[60];  { Eingangsfilter            }
                  aFilter   : string[60];  { Ausgangsfilter            }
                  SysopNetcall : boolean;  { Netzanruf-Bericht im S.M. }
                  SysopPack : boolean;     { Sysopnetcall-Paket packen }
                  SerienNr  : smallword;   { Turbo-Box: Seriennr.      }
                  Script    : string[50];  { Netcall-Script     }
                  chsysbetr : string[50];  { Changesys-Betreff  }
                  uucp7e1   : boolean;     { gerade Parity beim Login }
                  JanusPlus : boolean;     { Janus+             }
                  DelQWK    : boolean;     { ZQWK-Schalter -del }
                  BMtyp     : byte;        { UUCP: Brettmanager-Typ }
                  BMdomain  : boolean;     { UUCP: Brettmanager braucht Domain }
                  maxfsize  : smallword;   { UUCP: max. Empfangsdateigrî·e / KB }

                { RFC/PPP: POP3, SMTP, NNTP, XP-Score }
                  Pop3Server          : string[60];  { Name des Pop3 Servers }
                  Pop3User            : string[60];  { Authentifizierung: User Name }
                  Pop3Envelope        : string[60];  { eMail/Umschlag Adresse fÅr den Pop3 Zugang }
                  Pop3Pass            : string[40];  { Authentifizierung: Password }
                  Pop3Keep            : boolean;     { Mail auf Server belassen }
                  Pop3UseEnvelope     : boolean;     { eventuelle Envelope-To nutzen }
                  Pop3Spool           : string[79];  { Spoolverzeichnis }
                  Pop3TimeOut         : integer;     { Timeout bis Abbruch }
                  Pop3Port            : longint;     { Port des Pop3 Servers }
                  Pop3MaxLen          : longint;     { maximale Grî·e einer mail }
                  Pop3ReportInfo      : string[40];  { Brett fÅr Reports }
                  IMAP                : boolean;     { IMAP anstatt Pop3 nutzen }
                  Pop3Auth            : boolean;

                  SmtpUser            : string[60];  { Authentifizierung: User Name }
                  SmtpServer          : string[60];  { Name des Smtp Servers }
                  SmtpFallback        : string[20];  { DateiName der Smtp Fallbackbox }
                  SmtpEnvelope        : string[60];  { eMail/Umschlag Adresse fÅr Smtp }
                  SmtpPort            : longint;     { Port des Smtp Servers }
                  SmtpAfterPopTimeOut : integer;     { Timeout bis 'Smtp After Pop3 abbricht }
                  SmtpTimeOut         : integer;     { Timeout bis Abbruch }
                  SmtpAfterPopDelay   : integer;     { Verzîgerung bis Smtp nach erfolgreichem Pop3 Connect beginnt }
                  SmtpSpool           : string;      { Spoolverzeichnis }
                  SmtpAfterPop        : boolean;     { Smtp After Pop3 benutzen }
                  SmtpPass            : string[40];  { Authentifizierung: Password }
                  SmtpReportInfo      : string[40];  { Brett fÅr Reports }
                  SmtpAuth            : string[11];  { auto˘Login˘Plain˘Digest-MD5˘Cram-MD5 }

                  NntpServer          : string[60];  { Name des News Servers }
                  NntpFallback        : string[20];  { DateiName der Nntp Fallbackbox }
                  NntpUser            : string[60];  { Authentifizierung: User Name }
                  NntpPass            : string[40];  { Authentifizierung: Passwort }
                  NntpTimeOut         : integer;     { Timeout bis Abbruch }
                  NntpQueue           : integer;     { Vorlaufpuffer fÅr Artikelanforderungen }
                  NntpArtclAnz        : integer;     { letzte xx Artikel bei Neubestellung holen }
                  NntpPort            : longint;     { Port des News Servers }
                  NntpMaxLen          : longint;     { maximale Grî·e eines Artikels }
                  NntpNewMax          : longint;     { maximale Anzahl der Artikel pro NG }
                  NntpDupeSize        : longint;     { Grî·e der internen Dupebase }
                  NntpList            : boolean;     { Newsgroup Liste holen/ updaten }
                  NntpRescan          : boolean;     { alle Artikel-Pointer neu setzen }
                  NntpSpool           : string[79];  { Spoolverzeichnis }
                  NntpReportInfo      : string[40];  { Brett fÅr Reports }
                  NntpPosting         : boolean;     {  }
                  ReplaceOwn          : boolean;     { RÅcklÑufer ersetzen }

                  PPP_Dialer          : string[79];  { Dialer zum Verbindungsaufbau }
                  PPP_HangUp          : string[79];  { Dialer zum Verbindungsabbau }
                  PPP_Mail            : string;      { Mail Client }
                  PPP_News            : string;      { News Client }
                  PPP_UUZ_Out         : string;      { Outgoing Spool Utility }
                  PPP_UUZ_In          : string;      { Incoming Spool Uitlity }
                  PPP_UUZ_Spool       : string[79];  { UUZ-Spoolverzeichnis }
                  PPP_Shell           : integer;     { Zeilenanzahl fÅr Mailer-Shell}

                  DialInAccount       : string[40];  { Provider, RAS-Eintrag }
                  DialInNumber        : string[25];  { Telefonnummer }
                  DialInPass          : string[40];  { Password }
                  DialInUser          : string[60];  { User }
                  RedialOnBusy        : integer;     { Anwahlversuche bei Besetzt }
                  RedialTimeout       : integer;     { Wahlabbruch Abbruch nach}
                  HangupTimeOut       : integer;     { spÑtestens nach dieser Zeit auflegen  }
                  PerformPass         : boolean;     { stÑndige Pa·worteingabe }
                  AfterDialinState    : boolean;     { Disconnect nur wenn XP Verbindung aufgebaut hatte }
                  AskForDisconnect    : boolean;     { Vor Auflegen anchfragen }
                {$IFDEF ToBeOrNotToBe}
                  TCP_PktDrv          : string[10];
                  TCP_PktVec          : integer;
                  TCP_PktInt          : integer;
                  TCP_NameServer      : string[15];
                  TCP_Gateway         : string[15];
                  TCP_Netmask         : string[15];
                  TCP_LocalIP         : string[15];
                  TCP_Socket_Timeout  : integer;  { Timeout bei Socketfehlern }
                  TCP_Bootp_Timeout   : integer;  { Timeout fÅr BOOTP-Server  }
                {$ENDIF}
                  XpScoreAktiv        : boolean;     {}
                  ScoreFile           : string[79];  {}
                  PPP_KillFile        : string[79];  {}

                  PPP_BoxPakete       : string[90];  { Pakete mitsenden }
                  MailerDaemon        : boolean;     { Mailer-Daemon }
                end;
       BoxPtr = ^BoxRec;

       QfgRec = record                     { QWK-QFG-Daten }
                  RepFile   : string[8];   { REP-Dateinahme ohne Ext. }
                  Packer    : string[3];   { Packer-Typ (Extension)   }
                  Door      : string[20];  { Name des Doorprogramms   }
                  requests  : boolean;     { File Requests mîglich    }
                  ebs       : boolean;     { EmpfangsbestÑtigungen "  }
                  privecho  : string[50];  { PM-Echo                  }
                  netecho   : string[50];  { Netmail-Echo             }
                  emailecho : string[50];  { EMail-Echo (Oerx)        }
                  nmt       : byte;        { Netmail-Typ              }
                  midtyp    : shortint;    { Message-ID-Typ           }
                  hdr       : boolean;     { Header im Body           }
                  bretter   : string[25];  { Brettebene               }
                end;

       FidoAdr = record
                   username   : string[36];
                   zone,net   : word;
                   node,point : word;
                   ispoint    : boolean;
                 end;

       NL_Rec  = record
                   listfile   : string[12];    { Nodelisten-Datei      }
                   number     : integer;       { akt. Nummer           }
                   updatefile : string[12];    { Diff/Update-Datei     }
                   updatearc  : string[12];    { gepackte Update-Datei }
                   processor  : ^string;       { externer Bearbeiter   }
                   DoDiff     : boolean;
                   DelUpdate  : boolean;       { Diff lîschen }
                   format     : byte;     { 1=NL, 2=P24, 3=PVT, 4=4D, 5=FD }
                   zone,net,node : word;
                   sort       : longint;       { TemporÑrfeld }
                 end;
       NL_array= array[1..maxNodelists] of NL_Rec;
       NL_ap   = ^NL_array;

       fkeyt  = array[1..10] of record
                                  menue    : string[20];
                                  prog     : string[60];
                                  warten   : boolean;
                                  bname    : boolean;  { $FILE aus Betreff }
                                  ntyp     : byte;   { xp3.extract_msg.typ }
                                  listout  : boolean;  { Ausgabe an Lister }
                                  speicher : word;       { 50 .. 500 KByte }
                                  vollbild : boolean;
                                  autoexec : boolean;
                                end;
       fkeyp  = ^fkeyt;

       KeyRec = record
                  keypos : byte;   { X-Position in 2. Bildzeile }
                  keylen : byte;
                  keyspot: shortint;  { <0 : mehrere Zeichen ab Pos. 0 }
                  key    : taste;  { LowerCase-Taste }
                end;

       proc   = procedure;

       komlines = array[0..kommlmax-1] of word;
       komrec   = record
                    msgpos : longint;
                    lines  : komlines;
                    _ebene : shortint;
                    flags  : byte;
                  end;
       komliste = array[0..maxkomm-1] of komrec;   { Kommentarbaum }
       komlistp = ^komliste;

       ExtHeaderType = array[1..maxheaderlines] of byte;

       viewert  = array[1..maxviewers] of record
                                            ext : string[3];
                                            prog: string[40];
                                          end;
       UnpackRec = record
                     UnARC, UnLZH, UnZOO,
                     UnZIP, UnARJ, UnPAK,
                     UnDWC, UnHYP, UnSQZ,
                     UnRAR                : string[50];
                   end;

       PathPtr   = ^pathstr;

       DomainNodeP = ^domainnode;
       DomainNode = record
                      left,right : DomainNodeP;
                      domain     : ^string;
                    end;


const  menupos : array[0..menus] of byte = (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                                            1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                                            1,1,1,1,1,1,1,1);
       menable : array[0..menus] of word = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                            0,0,0,0,0,0,0,0);
       checker : array[0..menus] of byte = (0,0,0,0,0,0,0,0,0,0,0,1,0,2,0,0,0,
                                            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                                            0,0,0,0,0,0,0,0);

       OStype : (os_dos,os_linux,os_windows,os_2) = os_dos;

       Quit       : boolean = false;
       mbase      : pointer = nil;     { Nachrichten.Datenbank  }
       ubase      : pointer = nil;     { User-Datenbank         }
       bbase      : pointer = nil;     { Brett-Datenbank        }
       auto       : pointer = nil;     { automsg.db1            }
       bezbase    : pointer = nil;     { Bezugs-Datenbank       }
       mimebase   : pointer = nil;     { MIME-Typen-Datenbank   }
       runerror   : boolean = true;    { Runtime Error aufgetreten }
       Timing_Nr  : byte = 1;          { zuletzt eingegebene Nummer}
       ErrLevel   : byte = 0;          { bei Beenden Åber XP.PAS   }
       startup    : boolean = true;    { Datenbank noch nicht initialisier }
       netcalling : boolean = false;   { laufender Netcall }
       autoactive : boolean = false;   { select(20) aktiv  }
       { extended   : boolean = false; ?!? }
       keydisp    : boolean = true;    { TastenkÅrzel anzeigen  }
       Clipboard  : boolean = false;   { Windows-Clipboard }
       deutsch    : boolean = true;
       screenlines: byte    = 25;      { Bildschirmzeilen       }
       screenwidth: byte    = 80;      { Bildschirmspalten      }
       OrgVideomode:word    = 3;
       uvs_active : boolean = false;   { /N/Z/Unversandt        }
       marksorted : boolean = false;   { marked^[] sortiert     }
       fidolastseek:string[40] = '';   { Fido/Fileliste/Suchen  }
       abgelaufen1: boolean = false;   { Betaversion ist abgelaufen }
       abgelaufen2: boolean = false;   {  " }
       cfgmodified: boolean = false;   { Einstellungen geÑndert }
       DisableAltN: boolean = false;   { Alt-N deaktiviert      }
       automessaging: boolean = false; { Nachrichten werden nicht-manuell }
       actscreenlines: integer = 25;
       exzconfig  : boolean = false;   { exist('zconfig.exe') -> /C/A/P }
                                       { verarbeitet (wÑhren P.-Einlesen  }
       lockopen   : boolean = false;   { LOCKFILE geîffnet }

       XPhilite   : byte    = 20;
       XPdisplayed: boolean = false;   { 'CrossPoint' rechts unten angezeigt }

       ParMailto  : string[AdrLen] = '';
       ParHelp    : boolean = false;   { Hilfsseite             }
       ParDebug   : boolean = false;   { Debugging-Mode         }
       ParDDebug  : boolean = false;   { Database-Debug         }
       ParDebFlags: byte    = 0;       { 1 = Shell-Commands     }
       ParDupeKill: boolean = false;   { autom. DupeKill        }
       ParTrace   : boolean = false;   { Script-Tracefile       }
       ParMono    : boolean = false;   { monochrome Anzeige     }
       ParNojoke  : boolean = false;   { Spruch am Ende abschalten }
       ParXX      : boolean = false;   { s. XP4E                }
       ParNetcall : string[BoxNameLen] = '';  { autom. Netcall }
       ParNCtime  : string[5] = '';    { Uhrzeit f. autom. Netcall }
       ParRelogin : boolean = false;   { Relogin-Netcall        }
       ParReorg   : boolean = false;   { autom. Reorganisation  }
       ParSpecial : boolean = false;   { Spezial-Reorg - Puffer-reparieren }
       ParPack    : boolean = false;   { autom. Packen          }
       ParXPack   : boolean = false;   { autom. Packen / nur Dateien mit LÅcken }
       ParXPfile  : string[8] = '';    { optional zu /xpack: Datenbankname }
       ParQuiet   : boolean = false;   { keine GerÑusche        }
       ParTestres : boolean = true;    { Test auf residente Prg. }
       ParMaus    : boolean = false;   { Pseudo-Maus            }
       ParPuffer  : pathstr = '';      { autom. Puffer einlesen }
       ParPufED   : boolean = false;   { -> EmpfDat = ErstDat   }
       ParGelesen : boolean = false;   { ip-eingelesene Nachrichten auf }
       ParTiming  : byte    = 0;       {    'gelesen' setzen    }
       ParExit    : boolean = false;   { Programm beenden       }
       ParSetuser : string[50] = '';   { Username setzen        }
       ParSendbuf : pathstr = '';      { Puffer automatisch versenden }
       ParKey     : char    = ' ';     { autom. Tastendruck     }
       ParEmpfbest: boolean = false;   { Zusatzschalter fÅr /IPx }
       ParPass    : string[10] = '';   { * -> ausgeben; Hex -> setzen }
       ParPasswd  : string[10] = '';   { Pa·wort }
       ParZeilen  : byte = 0;          { Bildzeilen }
       ParWintime : byte    = 0;       { Rechenleistungs-Freigabe:
                                         0=aus, 1=Timeslice, 2=konservativ }
       ParOS2     : byte    = 0;       { Rechenleistungs-Freigabe }
       ParSsaver  : boolean = false;   { Screensaver }
       ParAutost  : string[12] = '';   { /autostart: }
       ParGebdat  : string[12] = 'gebuehr.dat';  { GebÅhrenzonenliste }
       ParGebdat2 : string[12] = 'tarife.dat';   { 2. Teil der " }
       ParAV      : pathstr = '';      { Archiv-Viewer }
       ParLanguage: string[4] = '';    { /l: Sprache }
       ParFontfile: pathstr = '';      { /f: Fontdatei laden }
       ParNomem   : boolean = false;   { Speichertest Åbergehen }
       ParNoSmart : boolean = false;   { kein Schreibcache-Flush }
       ParLCD     : boolean = false;   { keine Int10/CharGen-Zugriffe }
       ParMenu    : boolean = false;   { /menu: XP mit vollen MenÅs starten }
       ParG1      : boolean = false;   { GebÅhrenzone ermitteln }
       ParG2      : boolean = false;   { GebÅhren berechnen }
       ParNolock  : boolean = false;   { keine Lockfile-öberprÅfung }
       ParVersion : boolean = false;   { Versionsanzeige }
{$IFDEF Beta }
       ParNoBeta  : boolean = false;   { MK 01/00 keine Beta-Meldung }
{$ENDIF }

       MoreMode   : boolean = true;
       Developer  : boolean = false;
       SupportCfg : string[12] = 'SUPPORT.CFG';
       Delviewtmp : boolean = false;   {Win-Viewertempfiles erst beim naechsten Start loeschen}

       QuoteCharSet    : set of char = [':','|']; { Weitere Quotezeichen }
       OtherQuoteChars : boolean = false; { andere Quotezeichen neben > aktivieren }
       Otherqcback     : boolean = false; { Backup von Otherqqotechars zum Umschalten }
       ListWrapBack    : boolean = false; { Backup von ListWrap zum Umschalten }

       BrettVerteiler : boolean = false;

       PGP2 = 'PGP 2.6.x';
       PGP5 = 'PGP 5.x';
       PGP6 = 'PGP 6.5.x';
       GPG1  = 'GnuPG 1.x';
       PGPVersion : string[10] = PGP2;

       mheadercustom : array[1..2] of string[custheadlen] = ('','');

       {AutoDatumsBezuege : boolean = false;}
       MsgFeldDef = 'FGDAEB'; { Standardreihenfolge: Feldtausch Nachrichtenliste }
       UsrFeldDef = 'FHBAK'; { Standardreihenfolge: Feldtausch Userliste }

var    bb_brettname,bb_kommentar,bb_ldatum,bb_flags,bb_pollbox,bb_haltezeit,
       bb_gruppe,bb_index,bb_adresse,
       ub_username,ub_adresse,ub_kommentar,ub_adrbuch,ub_pollbox,
       ub_haltezeit,ub_userflags,ub_codierer,
       mb_brett,mb_absender,mb_betreff,mb_origdatum,mb_empfdatum,
       mb_groesse,mb_typ,mb_halteflags,mb_gelesen,mb_unversandt,
       mb_ablage,mb_adresse,mb_msgsize,mb_wvdatum,mb_msgid,mb_netztyp,
       mb_name,mb_flags,mb_mimetyp, {mb_prioflags,}
       bezb_msgpos,bezb_msgid,bezb_ref,bezb_datum,
       mimeb_typ,mimeb_extension,mimeb_programm : integer;

       IntGruppe,LocGruppe,NetzGruppe : longint;   { INT_NRs der Std.-Gruppen }

       menu         : array[0..menus] of ^string;
       SwapFileName : string[12];
       helpfile     : string[12];     { XP.HLP     }
       keydeffile   : string[12];     { KEYDEF.CFG }
       OwnPath      : pathstr;
       ShellPath    : pathstr;
       TempPath     : pathstr;
       ExtractPath  : pathstr;
       SendPath     : pathstr;
       LogPath      : pathstr;
       FilePath     : pathstr;
       FidoPath     : pathstr;       { OwnPath+FidoDir }
       ColorDir     : pathstr;
       lockfile     : file;          { gelockte Datei LOCKFILE }

       midrec      : tMsgID;
       reqfile     : file of tMsgID;
       reqfname    : pathstr;

       EditLogpath  : pathptr;
       EditTemppath : pathptr;
       EditExtpath  : pathptr;
       EditSendpath : pathptr;

       col          : ColRec;        { CFG-Variablen :  ------ }
       ExtraktTyp   : byte;          { 0=ohne Kopf, 1=mit, 2=Puffer, 3=Quote }
       defExtrakttyp: byte;          { .. in XPOINT.CFG        }
       brettanzeige : byte;          { 0=gross, 1=top, 2=klein }
       ShowMsgDatum : boolean;       { Datum im Nachrichtenf.  }
       viewers      : ^viewert;
       errortimeout_mini,
       errortimeout_short,
       errortimeout : byte;          { Wartezeit (sec) nach Fehler }

       VarEditor,
       VarLister    : string[40];    { externer Editor/Lister  }
       ListerKB     : smallword;
       EditorKB     : smallword;
       stdhaltezeit,
       stduhaltezeit: integer16;
       HideRe       : boolean;       { Re: und AW: verstecken }
       HideMLHead   : boolean;       { [Listenname] verstecken }
       LongBetr     : boolean;
       CutMlBetr    : boolean;
       QuoteChar    : string[QuoteLen];
       QuoteBreak   : byte;          { Zeilenumbruch fÅr Quoter }
       COMn         : array[1..MaxCom] of ComRec;  { Schnitten-Paras }
       BoxPar       : BoxPtr;
       DefaultBox   : string[20];
       DefFidoBox   : string[20];
   {}  LongNames    : boolean;       {   "       "         : >40 Zeichen }
       ScrSaver     : smallword;
       SoftSaver    : boolean;       { Bild weich ausblenden }
       BlackSaver   : boolean;       { schwarzschalten }
       smallnames   : boolean;       { kleingeschriebene Brett/Usernamen }
       UserAufnahme : byte;          { 0=Alle, 1=Zerberus, 2=keine, 3=PM }
       MaxBinSave   : longint;
       MaxNetMsgs   : longint;       { Default-Wert fÅr neue Gruppen }
       ReHochN      : boolean;
       SwapToEMS    : boolean;       { EMS-Swapper fÅr DOS-Shell }
       SwapToXMS    : boolean;       { XMS-Swapper fÅr DOS-Shell }
       HayesComm    : boolean;
       ShowLogin    : boolean;
       BreakLogin   : boolean;
       ArchivBretter: string[BrettLen];
       ArchivLoesch : boolean;       { Msgs nach Archivierung lîschen }
       ArchivText   : boolean;       { Archivier-Vermerk erstellen}
       shell25      : boolean;       { 25-Zeilen-Mode bei DOS-Shell }
       edit25       : boolean;       { dito bei externem Editor }
       MailerShell  : integer;       { Zeilenanzahl bei Mailer-Shell }
       MinMB        : smallword;
       AskQuit      : boolean;
       ListVollbild : boolean;       { Vollbild bei internem Lister }
       ListUhr      : Boolean;       { Uhr bei Vollbildlister }
       ListEndCR    : boolean;       { internen Lister mit <cr> beenden }
       ListWrap     : boolean;
       FKeys        : array[0..4] of fkeyp;
       Unpacker     : ^UnpackRec;
       EditVollbild : boolean;
       ExtEditor    : byte;          { 3=immer, 2=Nachrichten, 1=gro·e Files }
       DefaultSavefile : string[80];
       ShowMsgPath  : boolean;
       ShowMsgID    : boolean;
       ShowMsgSize  : boolean;
       DruckLPT     : smallword;          { 1-5: LPT1-3, COM1-2 }
       DruckInit    : string[80];
       DruckExit    : string[80];
       DruckFormlen : byte;          { SeitenlÑnge; 0 = kein autom. Vorschub }
       DruckFF      : string[80];
       DruckLira    : byte;
       AutoCpgd     : boolean;       { automatisches Ctrl-PgDn im Editor }
       XP_ID_PMs    : boolean;
       XP_ID_AMs    : boolean;
       XP_ID_Fido   : boolean;
       UserSlash    : boolean;
       BAKext       : string[3];
       keepedname   : boolean;
       pmcrypt      : array[1..maxpmc] of
                        record
                          encode,decode : string[40];
                          name          : string[20];
                          binary        : boolean;
                        end;
       wpz          : longint;       { DM/Zeile bei GebÅhrenstat. *1000  }
       sabsender    : byte;          { 0=normal, 1=klein, 2=mit space,   }
       envspace     : smallword;     { ..3=nur User, 4=Spalten           }
       DefReadmode  : integer;       { Default fÅr 'readmode' (s.u.) }
       AAmsg        : boolean;       { Auto-Advace }
       AAbrett      : boolean;
       AAuser       : boolean;
       ScrollLock   : boolean;       { umschaltbarer Scroll-Mode }
       GrossWandeln : boolean;       { Adressen in Gro·schreibung wandeln }
       HaltOwn      : boolean;
       HaltownPM    : boolean;
       DispUsername : boolean;
       SaveUVS      : boolean;       { AutoPark }
       EmpfBest     : boolean;       { autom. EmpfangsbestÑtigungen }
       EmpfBkennung : string[10];    { '##' }
       unescape     : string[100];   { UUCP-Adressen... }
       ReplaceEtime : boolean;       { 00:00 Erstellungszeit }
       trennchar    : string[1];     { Trennzeichen fÅr Brett-Trennzeilen }
       AutoArchiv   : boolean;       { automatische PM-Archivierung }
       NewBrettEnde : boolean;       { neue Bretter ans Listenende }
       _maus        : boolean;       { Mausbedienung }
       TrennAll     : boolean;       { Trennzeilen im 'Alle'-Mode }
       BaumAdresse  : boolean;       { volle Adresse im Bezugsbaum }
       SwapMausKeys : boolean;       { Maustasten vertauschen }
       MausDblclck  : byte;          { 4/7/11 }
       MausShInit   : boolean;       { Init nach Shell-Aufruf }
       ConvISO      : boolean;       { ISO-Umlaute im Lister lesbar machen }
       KomArrows    : boolean;       { Kommentarpfeile im Lister anzeigen }
       ListScroller : boolean;       { Scrollbalken bei Mausbedienung }
       ListAutoscroll:boolean;       { Scrolling am Bildschirmrand }
       LargestNets  : integer;       { Conf2: die n grî·ten Netze bei Nodestat }
       NS_MinFlags  : integer;       { Conf2: min. Flags bei Nodestatistik }
       CountDown    : boolean;       { Conf2: Down-Nodes mitzÑhlen }
       UserBoxname  : boolean;       { Boxname in Userbrettern belassen }
       nDelPuffer   : boolean;       { PUFFER nach Einlesen lîschen }
       MaxMaus      : boolean;       { Outfile-Grî·e begrenzen }
       Auswahlcursor: boolean;       { Blinden-Option }
       Soundflash   : boolean;       { Gehîrlosen-Option }
       MausLeseBest : boolean;       { manuelle Maus-BestÑtigen }
       MausPSA      : boolean;       { Stati anfordern }
       ShowRealnames: boolean;       { Realnames anzeigen, falls vorhanden }
       ss_passwort  : boolean;       { Startpa·wort nach Screensaver }
       NewsMIME     : boolean;       { MIME auch in News verwenden }
       MIMEqp       : boolean;       { quoted-printable }
       RFC1522      : boolean;       { RFC-1522-Header erzeugen }
       NoArchive    : boolean;       { NoArchive-Headerz. erzeugen } {!MMH}
       PPP_AnzReq   : byte;          { Anz. Versuche zur Artikelanforderung }
     { Daemon       : boolean; }     { Mailer-Daemon als Abs. verwenden }
       pmlimits     : array[1..maxpmlimits,1..2] of longint;
       ZC_xposts    : boolean;       { ZConnect-Crosspostings }
       ZC_ISO       : boolean;       { ISO-8859-1 verwenden }
       leaveconfig  : boolean;       { /Config-MenÅ bei <Esc> ganz verlassen }
       NewsgroupDisp: boolean;       { Anzeige mit "." statt "/" }
       NetcallLogfile:boolean;       { Logfile Åber Netcalls fÅhren }
       ShrinkUheaders : boolean;     { UUZ-Schalter -r }
       ListHighlight: boolean;       { ** und __ auswerten }
       ListFixedHead: boolean;       { feststehender Nachrichtenkopf }
       MaggiVerkettung: boolean;     { s. xpnt.ntKomkette() }
       ISDN_Int     : byte;          { CAPI-Int, Default=$f1 }
       ISDN_EAZ     : char;          { eigene EAZ, Default='0' }
       ISDN_Controller:byte;         { Nummer des Controllers, Default=0 }
       ISDN_MSN_Incoming: string[10];
       ISDN_MSN_Outgoing: string[10];
       SaveType     : byte;          { 0=Sofort, 1=Alt-S, 2=RÅckfrage }
       XSA_NetAlle  : boolean;       { Netcall/Alle-Schalter bei /Netcall/L }
       maxcrosspost : byte;          { Filter fÅr Massen-Crosspostings }
       maildelxpost : boolean;       { 20.01.2000 robo - auch bei Mail? }
       allowcancel  : byte;          { Supersede/Cancel erlauben }
       { 0=immer, 1=nicht halten, 2=nicht Wdvlg., 3=nicht (h. od. Wv.), 4=nie }
       KeepRequests : boolean;       { Requests zurÅckstellen }
       waehrung     : string[5];
       gebnoconn    : longint;       { GebÅhren fÅr nicht zustandegek. Verb. }
       gebCfos      : boolean;       { GebÅhrenÅbernahme von cFos }
       autofeier    : boolean;       { Feiertage bei GebÅhren berÅcksichtigen }
       ShellShowpar : boolean;       { Anzeige vor Shell-Aufruf }
       ShellWaitkey : boolean;       { warten nach Shell-Aufruf }
       msgbeep      : boolean;       { Tonsignal in N/B/U-öbersicht }
       Netcallunmark: boolean;       { Nachrichten nach Netcall ent-markieren }
       DefaultNokop : boolean;       { Default STAT: NOKOP }
       blind        : boolean;       { AnzeigeunterstÅtzung fÅr Blinde }
       quotecolors  : boolean;       { verschiedenfarbige Quoteebenenen }
       trennkomm    : byte;          { 1=links, 2=Mitte, 3=rechts }
       vesa_dpms    : boolean;       { Screen-Saver-Stromsparmodus }
       termbios     : boolean;       { BIOS-Ausgabe im Terminal }
       tonsignal    : boolean;       { zusÑtzliches Tonsignal nach Reorg u.a. }
       MsgFeldTausch   : string[MsgFelderMax]; { fÅr blinde Benutzer,
                                       die sich Ausgaben vorlesen lassen, kînnen
                                       in der Brettliste Felder vertauscht werden }
       UsrFeldTausch   : string[UsrFelderMax]; { fÅr blinde Benutzer,
                                       die sich Ausgaben vorlesen lassen, kînnen
                                       in der Userliste Felder vertauscht werden }
       Magics       : boolean;       { Auch Magics im F3-Request erkennen j/n }
       brettkomm    : boolean;       { Kommentar aus Brettliste Åbernehmen }
       adrpmonly    : boolean;       { Telefon/Adresse nur in PMs }
       newuseribm   : boolean;       { Default-Umlauteinstellung f. neue User }
       multipartbin : boolean;       { RFC-BinÑrnachrichten als Multipart }
       mausmpbin    : boolean;       { dto. fÅr MausTausch }
       askreplyto   : boolean;       { 03.02.2000 robo - fragen bei ANTWORT-AN }

       UsePGP       : boolean;       { PGP verwenden }
       PGPbatchmode : boolean;       { PGP-Schalter +batchmode verwenden }
       PGPpassmemo  : boolean;       { Passphrase bis Programmende merken }
       {PGP_PPP      : boolean;       { PGP fÅr RFC/PPP }
       {PGP_UUCP     : boolean;       { PGP fÅr RFC/UUCP }
       PGP_RFC      : boolean;       { PGP fÅr RFC }
       PGP_Fido     : boolean;       { PGP fÅr Fido }
       PGP_Passphrase : string;      { PGP Passphrase }
       PGP_UserID   : string[80];    { Netzadresse von Key }
       PGP_AutoPM   : boolean;       { Keys aus PMs automatisch einlesen }
       PGP_AutoAM   : boolean;       { Keys aus AMs automatisch einlesen }
       PGP_waitkey  : boolean;       { 'Taste drÅcken ...' nach PGP }
       PGP_log      : boolean;       { Logfile fÅr PGP-AktivitÑten }
       PGP_signall  : boolean;       { alle Nachrichten signieren }
       PGP_GPGEncodingOptions : string; { Standardparameter fuer GPG }

       IntVorwahl   : string[15];    { internationale Vorwahl }
       NatVorwahl   : string[10];    { nationale Vorwahl, normalerweise 0 }
       Vorwahl      : string[15];    { eigene Vorwahl }
       AutoDiff     : boolean;       { Node/Pointdiffs automatisch einbinden }
       ShowFidoEmpf : boolean;       { von/an/Betreff-Anzeige }
       HighlightName: string[25];    { eigenen Fido-BrettempfÑnger hervorheben }
       AutoTIC      : boolean;       { TIC-Files auswerten }

       AutoUpload   : boolean;       { CrossTerm - PD-Zmodem-Autoupload }
       AutoDownload : boolean;       { Autodownload }
       TermCOM      : byte;          { Schnittstelle }
       TermBaud     : longint;       { Baudrate }
       TermStatus   : boolean;       { Statuszeile }
       TermInit     : string[40];    { Modem-Init }

       mono         : boolean;       { monochrome Anzeige      }
       fnkeylines   : byte;          { wird durch DispFunctionKeys gesetzt }
       lesemodepos  : byte;          { X-Position Lesemode }

       orgcbreak    : boolean;
       oldexit      : pointer;       { alte Exit-Prozedur }

       gl,actgl     : shortint;      { Anzeige-Zeilen im Hauptfenster }
       aufbau       : boolean;       { neuer Bildschirm-Aufbau nîtig  }
       xaufbau      : boolean;       { Bezugsbaum neu einlesen        }
       readmode     : integer;       { 0=Alles, 1=Ungelesen, 2=Neues }
       readdate     : longint;       { 3=Heute, 4=Datum              }
       nachweiter   : boolean;       { Auto-Advace im Msg-Fenster    }
       brettweiter  : boolean;
       userweiter   : boolean;
       qchar        : string[20];    { zuletzt verwendeter Quote-String }
       brettall     : boolean;       { false -> nur zutreffende Bretter anz. }
       cfgscrlines  : byte;          { Config-Bildzeilen (wg. /z: }
       domainlist   : DomainNodeP;   { zum Erkennen von Replys auf eigene N. }
       DefaultViewer: pviewer;       { Viewer fÅr */* }
       DefTextViewer: pviewer;       { Viewer fÅr text/* }
       PtextViewer  : pviewer;       { Viewer fÅr text/plain }

       maxmark   : word;             { maximal markierbare Msgs }
       marked    : marklistp;        { Liste der markierten Msgs     }
       markanz   : integer;          { Anzahl markierte Msgs         }
       bmarked   : bmarkp;           { Liste der markierten Bretter/User }
       bmarkanz  : integer;          { Anzahl markierte Bretter/User }

       ablsize     : array[0..ablagen-1] of longint;   { Dateigrî·en }
       AktDispmode : shortint;
       AktDisprec  : longint;
       editname    : pathstr;        { Dateiname fÅr /Edit/Text }
       keymacros   : integer;        { Anzahl geladene Tastenmakros }
       macrokey    : array[1..maxkeys] of taste;
       macroflags  : array[1..maxkeys] of byte;
       macrodef    : array[1..maxkeys] of ^string;
       shortkey    : array[1..maxskeys] of KeyRec;
       shortkeys   : shortint;
       registriert : record r1,r2:boolean; nr:longint;
                            uucp,non_uucp,ppp:boolean; { ppp in [A,B,C] }
                            tc:char;        { A=normal, B=UUCP, C=komplett }
                            komreg,           { R-Kom / R-Org anzeigen }
                            orgreg:boolean;
                     end;
       regstr1     : string[2];      { mu· unmittelbar hinter registriert stehen! }
       regstr2     : string[2];      { fÅr UUCP }
       AutoCrash   : string[30];     { Crash automatisch starten; *.. -> normaler Netcall }
       ntAllowed   : set of byte;    { zulÑssige Netztypen }
       extheadersize : integer;      { grî·e des Kopfes bei xp3.extract_msg() }
       extHdLines  : integer;        { Anzahl Kopfzeilen bei Extrakt mit Kopf }
       fidobin     : boolean;        { BinÑrnachrichten im FidoNet mîglich }
       HeaderLines : integer;        { Def. Anzahl Zeilen bei Extrakt m.Kopf }
       ExtraktHeader : ExtHeaderType;
       reg_hinweis : boolean;        { Fenster bei Programmstart anzeigen }

       PointListn  : string[8];      { alte Pointlisten-Daten }
       PointDiffn  : string[8];
       Pointlist4D : boolean;        { 4D-Liste statt Points24 }

       DefaultZone : word;           { Fido - eigene Zone }
       DefaultNet  : word;           {      - eigenes Net }
       DefaultNode : word;           {      - eigener Node}
       Nodelist    : NL_ap;          { Node-/Pointlisten }
       NL_anz      : byte;           { Anzahl " }
       NodeOpen    : boolean;        { Nodelist(en) vorhanden & geîffnet }
       ShrinkNodes : string[100];    { Nodeliste einschrÑnken }
       kludges     : boolean;        { ^A-Zeilen im Lister anzeigen }
       KomShowadr  : boolean;        { <-> BaumAdresse }
       gAKAs       : ^string;        { globale AKA-Adressliste }
       Orga        : ^OrgStr;
       Postadresse : ^string;
       TelefonNr   : ^TeleStr;
       wwwHomepage : ^HomepageStr;
       BrettAlle   : string[20];     { StandardempfÑnger fÅr Brettnachrichten }
       fidoto      : string[35];     { XP6: EmpfÑngername bei Brettnachr.     }
       FidoDelEmpty: boolean;        { 0-Byte-Nachrichten lîschen }
       KeepVia     : boolean;        { ZFIDO: Option -via }

       kombaum     : komlistp;       { Kommentarbaum }
       komanz      : word;           { Anzahl EintrÑge }
       maxebene    : shortint;
       komwidth    : shortint;       { Anzeigeabstand zwischen Ebenen }
       kombrett    : string[5];      { Brettcode der Ausgangsnachricht }

       languageopt : boolean;        { /Config/Optionen/Sprachen }
       _fehler_    : string[12];
       _hinweis_   : string[12];
       _days_      : ^string;        { 'Monatag Dienstag ... ' }
       _daylen_    : word;
       StatBrett,                    { /ØStatistik  }
       UnvBrett,                     { /ØUnversandt }
       NetBrett    : string[15];     { /ØNetzanruf  }
       _wotag_     : string[14];     { 'MoDiMiDoFrSaSo' }
       _jn_        : string[2];      { 'JN' }


{ Globale Variable enthalten eine Listerzeile mit text in charbuf und word-Attribuen }
{ in attrbuf. beschrieben werden sie in xp1.MakeListDisplay, gelesen in Winxp.consolewrite }

{$IFDEF Ver32}
       charbuf     : string[82];                  {82 Zeichen   Reihenfolge nicht vertauschen!}
       attrbuf     : array [1..82] of smallword;  {82 Attribute}
{$ENDIF}

implementation

end.
{
  $Log: xp0.pas,v $
  Revision 1.94  2002/01/01 12:13:16  mm
  - Automatisches Halten selbstgeschriebener PMs unter
    Config/Optionen/Nachrichten/"Eigene PMs halten" konfigurierbar
    (Jochen Gehring)

  Revision 1.93  2001/12/30 12:01:54  mm
  - Archivierungsvermerk abschaltbar unter:
    Config/Optionen/Allgemeines/"Archivierungsvermerk erstellen"
    (Jochen Gehring)

  Revision 1.92  2001/12/27 14:00:39  MH
  - Startwerte fÅr BFG-Nr und CFG-Nr auf 20 festgelegt, damit sich diese
    Version vom Release unterscheidet und die Konvertierungen durchgefÅhrt
    werden

  Revision 1.91  2001/12/26 17:58:32  MH
  - RFC/PPP: TCP_?????? Parameter aus BFG entfernen - geaenderte konvertieren

  Revision 1.90  2001/12/22 14:35:55  mm
  - ListWrapToggle: mittels Ctrl-W kann im Lister und Archiv-Viewer der
    automatische Wortumbruch nicht-permanent umgeschaltet werden
    (Dank an Michael Heydekamp)

  Revision 1.89  2001/09/07 09:39:47  MH
  - RFC/PPP:
    Smtp- und NntpFallback-Felder fÅr Clients hinzugefÅgt, die
    diese Funktion unterstÅtzen mîchten. Es wird der BFG-Dateiname
    ohne Extention Åbergeben.

  Revision 1.88  2001/08/20 16:40:57  MH
  - stringgrî·e f. BoxPakete angepasst - 90 reichen hier jetzt vîllig aus.

  Revision 1.87  2001/08/20 16:11:20  MH
  - Konvertierung fÅr PPP_BoxPakete: BOX2BFG!

  Revision 1.86  2001/08/02 01:45:29  MH
  - RFC/PPP: Anpassungen im Mailclientbereich

  Revision 1.85  2001/07/16 10:02:37  MH
  - Farbsetup erweitert:
    Beim 'Puffereinlesen' werden eigene Nachrichten, Cancel/Supersedes usw.
    in verschiedenen Farben im Betreff angeszeigt

  Revision 1.84  2001/06/29 17:36:58  MH
  - AutoDatumsBezuege entfernt

  Revision 1.83  2001/06/29 15:55:54  MH
  - AutoDatumsBezuege entfernt

  Revision 1.82  2001/06/26 15:02:18  MH
  - ÅberflÅssiges entfernt (xtended.15 / extended)

  Revision 1.81  2001/06/19 21:15:26  mm
  Zusatzmenue auf 20 erweitert (von Jochen Gehring)

  Revision 1.80  2001/06/18 20:10:03  oh
  OH: GPG-Fixes (von Malte Kiesel), Sign All geht jetzt wieder

  Revision 1.79  2001/06/11 09:21:24  mm
  BetreffLen auf 248 raufgesetzt

  Revision 1.78  2001/04/04 19:57:00  oh
  -Timeouts konfigurierbar

  Revision 1.77  2001/03/22 09:28:37  oh
  - Farbprofile werden erst in colors\ gesucht, dann im XP-Verzeichnis

  Revision 1.76  2001/03/20 18:59:36  tg
  MailerShell

  Revision 1.75  2001/02/04 14:41:32  MH
  - énderung der ISDN-MSN-Variablen

  Revision 1.74  2001/01/29 22:08:47  MH
  RFC/PPP:
  - Einige Grenzen erweitert

  Revision 1.73  2001/01/04 22:08:13  MH
  - DialInAccount von 25 auf 40 Zeichen erhîht

  Revision 1.72  2000/12/25 17:15:18  MH
  ISDN-Parameter hinzugefÅgt

  Revision 1.71  2000/12/16 19:05:58  MH
  RFC/PPP:
  - Einige Erweiterungen im BoxmenÅ

  Revision 1.70  2000/11/27 13:19:17  rb
  Source-Kosmetik

  Revision 1.69  2000/11/25 08:31:45  MH
  RFC/PPP:
  - Weitere Schalter hinzugefÅgt

  Revision 1.68  2000/11/21 23:14:54  mm
  - Edit/Glossary hinzugefÅgt

  Revision 1.67  2000/11/14 15:12:28  MH
  Schalter fÅr CutMlBetr undokumentiert nachgerÅstet

  Revision 1.66  2000/11/11 15:08:28  oh
  -PGPkeyfileASCII eingefuegt

  Revision 1.65  2000/11/11 14:12:47  MH
  Lange Betreffs fÅr HideRe usw.

  Revision 1.64  2000/11/10 13:11:50  rb
  - Kommentarbaum-Limits geaendert: 97 Ebenen, 3640 Nachrichten
  - Kommentarbaum arbeitet jetzt speicherschonender auch bei vielen Ebenen

  Revision 1.63  2000/11/09 22:05:59  oh
  -First try with GnuPG - please test it!

  Revision 1.62  2000/11/09 17:11:33  rb
  - Kommentarbaum-Limits geaendert: 65 Ebenen, 4680 Nachrichten
  - Kommentarbaum ist mit Crtl und Cursor rechts/links verschiebbar

  Revision 1.61  2000/11/02 01:11:39  rb
  Kommentarbaumlimits erhîht

  Revision 1.60  2000/11/01 12:01:53  rb
  Tearline-Schalter

  Revision 1.59  2000/10/30 18:15:02  MH
  Optimierung der Box-Konvertierung

  Revision 1.58  2000/10/27 21:55:36  MH
  Konvertierung der BFGs verlagert

  Revision 1.57  2000/10/27 11:38:59  MH
  RFC/PPP: Kleiner Umbau des BoxmenÅs

  - ReplaceOwn bei weiteren Boxen hinzugefÅgt

  Revision 1.56  2000/10/26 14:49:21  MH
  Ein reiner Brettverteiler erfÑhrt eine Sonderbehandlung

  Revision 1.55  2000/10/13 00:42:06  rb
  Feineinstellung fÅr Cancel- und Supersedes-Verarbeitung

  Revision 1.54  2000/10/12 21:44:44  oh
  -PGP-Passphrase merken + Screenshot-File-Verkleinerung

  Revision 1.53  2000/10/11 17:04:59  MH
  RFC/PPP: Fix:
  - String fÅr UUZ-In/Out zu kurz

  Revision 1.52  2000/10/11 17:04:03  MH
  RFC/PPP: Fix:
  - String fÅr UUZ-In/Out zu kurz

  Revision 1.51  2000/10/10 15:28:32  MH
  ReplaceOwn nun Client- und Netz unabhÑngig...

  Revision 1.50  2000/10/07 10:08:43  MH
  HDO: Im MenÅ Config/Optionen/Netze/RFC...
  Anzahl der Versuche zur Requestanforderung einstellen

  Revision 1.49  2000/10/07 00:55:19  rb
  Mailerstring auf 120 Zeichen verlÑngert

  Revision 1.48  2000/10/05 19:02:58  MH
  RFC/PPP: NntpReplaceOwn hinzugefÅgt

  Revision 1.47  2000/09/29 11:47:03  MH
  HDO:
  - Filename nun in XP0 definiert

  Revision 1.46  2000/09/23 21:00:45  MH
  HdrOnly und MsgID-Request:
  - beide im neuen Format: NEWS.ID
  - HdrOnly kann mit F3 ohne Boxauswahl bestellt und abbestellt werden
  - MsgID kann mit F3 ohne Boxauswahl bestellt werden
  - Shift+F3 = Boxauswahl

  Revision 1.45  2000/09/12 20:32:49  oh
  ML-Header-Filter eingebaut

  Revision 1.44  2000/09/11 22:26:26  oh
  -Re: und AW: ausblendbar

  Revision 1.43  2000/09/02 20:33:23  MH
  HeaderOnly-Request: Nachtrichten mit 'X-XP-Mode: HdrOnly'
  erhalten in der NachrichtenÅbersicht ein 'H' voran gestellt

  Revision 1.42  2000/08/21 23:01:22  oh
  Defaultfile bei W im Lister

  Revision 1.41  2000/08/17 14:50:12  MH
  RFC/PPP: Online-Filter: KillFile bei Diverses hinzugefÅgt

  Revision 1.40  2000/08/11 15:05:51  MH
  Parameter 'mailto:' startet CrossPoint in 'Nachrichten/Direkt'
  und Åbergibt den EmpfÑnger

  Revision 1.39  2000/08/02 16:03:05  MH
  *** empty log message ***

  Revision 1.38  2000/07/31 19:15:45  MH
  RFC/PPP: Maximale Grî·e einer E-Mail kann konfiguriert werden

  Revision 1.37  2000/07/31 15:11:32  MH
  MAILER-DAEMON kann nun fÅr jede Box separat konfiguriert werden

  Revision 1.36  2000/07/30 16:14:49  MH
  RFC/PGP: Jetzt auch im PGP-MenÅ

  Revision 1.35  2000/07/28 13:07:03  MH
  RFC/PPP: PGP vorbereitet

  Revision 1.34  2000/07/27 16:59:05  MH
  RFC/PPP: Einige Grenzen erweitert und mit Mîglichkeit
           der Einstellung der Hangup-Zeit ergÑnzt

  Revision 1.33  2000/07/18 21:14:41  rb
  Supersedes - UUZ outgoing

  Revision 1.32  2000/07/05 21:44:52  MH
  Mailerzeile:
  - auf 66 Zeichen (in/out) verlÑngert
  - mit (XP2) gekennzeichnet

  Revision 1.31  2000/07/05 09:06:27  MH
  - Priority Filteratrribut deaktiviert

  Revision 1.30  2000/06/29 20:36:11  tj
  Parameter /version zugefuegt

  Revision 1.29  2000/06/24 17:03:07  MH
  RFC/PPP: Neuer Parameter NntpPosting hinzugefÅgt
           Pop3-/Smtp-/Port in einen String umgewandelt

  Revision 1.28  2000/06/22 03:47:04  rb
  Haltezeit-Bug bei ver32 gefixt

  Revision 1.27  2000/06/21 07:02:47  MH
  RFC/PPP: Pakete mitsenden implementiert

  Revision 1.26  2000/06/18 21:52:56  MH
  RFC/PPP: UUZ-SpoolDir eingerichtet (f. Pakete mitsenden v. Bedeutung)

  Revision 1.25  2000/06/17 09:40:25  MH
  RFC/PPP: Pakete mitsenden ins Menue aufgenommen

  Revision 1.24  2000/06/13 18:51:05  tg
  RFC/PPP: Sources dokumentiert

  Revision 1.23  2000/06/08 20:05:57  MH
  Teamname geandert

  Revision 1.22  2000/06/07 22:24:52  MH
  *** empty log message ***

  Revision 1.21  2000/06/05 09:05:38  MH
  RFC/PPP: Anzahl der Artikel kann nun selbst bestimmt werden

  Revision 1.20  2000/06/02 08:37:12  MH
  RFC/PPP: LoginTyp hergestellt

  Revision 1.18  2000/05/30 20:33:13  MH
  RFC/PPP: automatisches Verzeichnis anlegen

  Revision 1.17  2000/05/30 16:49:46  MH
  RFC/PPP: Fix: ReplyTo und Pointname wurden bei neuen Boxen mit den Daten einer anderen gefuellt

  Revision 1.16  2000/05/29 19:10:00  MH
  RFC/PPP: Weitere Anpassungen (Port nun 5stellig, IMAP ge‰ndert, Abwahlstring hinzugefuegt)

  Revision 1.15  2000/05/22 12:36:45  MH
  MAILER-DAEMON: Fuer autom. Empfangsbestaetigung jetzt konfigurierbar (C/O/E)

  Revision 1.14  2000/05/21 12:06:27  MH
  RFC/PPP: Weitere Anpassungen

  Revision 1.13  2000/05/17 17:26:26  MH
  Neuer Boxentyp: RFC/PPP

  Revision 1.12  2000/04/30 11:34:41  MH
  Altes Datenbankformat wieder hergestellt

  Revision 1.10  2000/04/18 00:24:07  tj
  xp_short auf XP zurueckgesetzt

  Revision 1.9  2000/04/16 17:35:41  tj
  noch ne Kleinigkeit gefunden

  Revision 1.8  2000/04/16 17:33:42  tj
  Kleinigkeit korrigiert

  Revision 1.7  2000/04/15 21:40:50  tj
  benoetigte Strings angepasst

  Revision 1.6  2000/04/10 22:13:07  rb
  Code aufgerÑumt

  Revision 1.5  2000/04/10 01:27:51  oh
  - Update auf aktuellen OpenXP-Stand

  Revision 1.22  2000/04/10 00:43:03  oh
  - F3-Request: Magicerkennung ein/ausschaltbar (C/O/e/V/Fido)

  Revision 1.21  2000/04/09 06:51:56  jg
  - XP/32 Listdisplay (Hervorhebungsroutine fuer Lister) portiert.
  - XP/16 Listdisplay etwas umgebaut und optimiert (Tabelle in DS)

  Revision 1.20  2000/04/04 21:01:22  mk
  - Bugfixes f¸r VP sowie Assembler-Routinen an VP angepasst

  Revision 1.19  2000/04/02 11:33:54  oh
  - Feldtausch-Routine abgesichert, OLH dazu ueberarbeitet

  Revision 1.18  2000/04/01 07:41:38  jg
  - "Q" im Lister schaltet otherquotechars (benutzen von | und :) um.
    neue Einstellung wird dann auch beim Quoten verwendet
  - Hilfe aktualisiert, und Englische Hilfe fuer
    Config/Optionen/Allgemeines auf Stand gebracht.

  - Externe-Viewer (Windows): "START" als Allroundviewer
    funktioniert jetzt auch mit der Loeschbatch-Variante
  - Text fuer MIME-Auswahl in englische Resource eingebaut

  Revision 1.17  2000/04/01 02:21:47  oh
  - Userliste: Felder jetzt sortierbar: Config/Anzeige/Hilfen, dasselbe fuer die MsgListe vorbereitet

  Revision 1.16  2000/03/25 11:46:09  jg
  - Lister: Uhr wird jetzt auch bei freiem Nachrichtenkopf eingeblendet
  - Config/Optionen/Lister: Schalter ListUhr zum (de)aktivieren der Uhr

  Revision 1.15  2000/03/24 04:15:22  oh
  - PGP 6.5.x Unterstuetzung

  Revision 1.14  2000/03/24 02:20:17  oh
  - Schalter Config/Anzeige/Hilfen: Feldtausch in Listen eingefuegt

  Revision 1.13  2000/03/14 15:15:37  mk
  - Aufraeumen des Codes abgeschlossen (unbenoetigte Variablen usw.)
  - Alle 16 Bit ASM-Routinen in 32 Bit umgeschrieben
  - TPZCRC.PAS ist nicht mehr noetig, Routinen befinden sich in CRC16.PAS
  - XP_DES.ASM in XP_DES integriert
  - 32 Bit Windows Portierung (misc)
  - lauffaehig jetzt unter FPC sowohl als DOS/32 und Win/32

  Revision 1.12  2000/03/07 17:45:13  jg
  - Viewer: Bei Dateien mit Leerzeichen im Namen wird
    grundsaetzlich ein .tmp File erzeugt
  - Env.Variable DELVTMP setzt jetzt nur noch beim Start
    die Globale Variable DELVIEWTMP

  Revision 1.11  2000/03/04 22:41:37  mk
  LocalScreen fuer xpme komplett implementiert

  Revision 1.10  2000/03/01 23:49:02  rb
  Rechenzeitfreigabe komplett Åberarbeitet

  Revision 1.9  2000/03/01 22:30:21  rb
  Dosemu-Erkennung eingebaut

  Revision 1.8  2000/02/27 22:28:51  mk
  - Kleinere Aenderung zum Sprachenwechseln-Bug

  Revision 1.7  2000/02/20 22:09:30  mk
  MO: * Fidolastseek von 28 auf 40 erweitert

  Revision 1.6  2000/02/19 14:46:39  jg
  Automatische Rechenzeitfreigabe unter Win (/W Default an)
  Parameter /W0 um Rechenzeitfreigabe auszuschalten
  Bugfix fuer allerersten Start: Parameter /L wird ausgewertet

  Revision 1.5  2000/02/18 17:28:08  mk
  AF: Kommandozeilenoption Dupekill hinzugefuegt

}
