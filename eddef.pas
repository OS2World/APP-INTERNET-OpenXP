{ --------------------------------------------------------------- }
{ Dieser Quelltext ist urheberrechtlich geschuetzt.               }
{ (c) 1991-1999 Peter Mandrella                                   }
{                                                                 }
{ Aenderungen des XP2 Teams unterliegen urheberrechtlich          }
{ dem XP2 Team, weitere Informationen unter: http://www.xp2.de    }
{                                                                 }
{ Basierend auf der Sourcebuild vom 09.04.2000 des OpenXP Teams.  }
{ Aenderungen des Sources, die vom OpenXP Team getaetigt wurden,  }
{ unterliegen den Rechten, die bis zum 09.04.2000 fuer das OpenXP }
{ Team gueltig waren.                                             }
{                                                                 }
{ CrossPoint ist eine eingetragene Marke von Peter Mandrella.     }
{                                                                 }
{ Die Nutzungsbedingungen fuer diesen Quelltext finden Sie in der }
{ Datei SLIZENZ.TXT oder auf www.crosspoint.de/srclicense.html.   }
{ --------------------------------------------------------------- }
{ $Id: eddef.pas,v 1.8 2001/12/23 12:39:08 mm Exp $ }

{ Deklarationen f�r Unit EDITOR }

unit eddef;

interface

{$I XPDEFINE.INC }

uses xpglobal, dos,keys;


type   ECB     = pointer;

const  EditfLeft        = 1;          { Cursor links                   }
       EditfRight       = 2;          { Cursor rechts                  }
       EditfUp          = 3;          { Cursor oben                    }
       EditfDown        = 4;          { Cursor unten                   }
       EditfPgUp        = 5;          { Seite nach oben                }
       EditfPgDn        = 6;          { Seite nach unten               }
       EditfWordLeft    = 7;          { Wort links                     }
       EditfWordRight   = 8;          { Wort rechts                    }
       EditfTop         = 9;          { Textanfang                     }
       EditfBottom      = 10;         { Textende                       }
       EditfPageTop     = 11;         { 1. Bildschirmzeile             }
       EditfPageBottom  = 12;         { letzte Bildschirmzeile         }
       EditfEOL         = 13;         { Zeilenende                     }
       EditfBOL         = 14;         { Zeilenanfang                   }
       EditfNextPara    = 15;         { Beginn n�chster Absatz         }
       EditfPrevPara    = 16;         { Vorausgehender Absatzbeginn    }
       EditfScrollUp    = 17;         { Bild eine Zeile hochscrollen   }
       EditfScrollDown  = 18;         { Bild eine Zeile nach unten     }

       EditfMark1       = 30;         { Marke 1 setzen                 }
       EditfMark2       = 31;         { Marke 2 setzen                 }
       EditfMark3       = 32;         { Marke 3 setzen                 }
       EditfMark4       = 33;         { Marke 4 setzen                 }
       EditfMark5       = 34;         { Marke 5 setzen                 }
       EditfGoto1       = 35;         { Sprung zu Marke 1              }
       EditfGoto2       = 36;         { Sprung zu Marke 2              }
       EditfGoto3       = 37;         { Sprung zu Marke 3              }
       EditfGoto4       = 38;         { Sprung zu Marke 4              }
       EditfGoto5       = 39;         { Sprung zu Marke 5              }
       EditfLastpos     = 40;         { Ctrl-Q-P                       }
       EditfGotoBStart  = 41;         { Blockanfang anspringen         }
       EditfGotoBEnd    = 42;         { Blockende anspringen           }

       EditfBS          = 50;         { Zeichen links l�schen          }
       EditfDEL         = 51;         { Zeichen unter Cursor l�schen   }
       EditfDelWordRght = 52;         { Wort rechts l�schen            }
       EditfDelWordLeft = 53;         { Wort links l�schen             }
       EditfDelLine     = 54;         { Zeile l�schen                  }
       EditfDelBlock    = 55;         { markierten Block l�schen       }
       EditfBlockBegin  = 56;         { Blockbeginn setzen             }
       EditfBlockEnd    = 57;         { Blockende setzen               }
       EditfCopyBlock   = 58;         { Kopie an Cursorposition        }
       EditfMoveBlock   = 59;         { verschieben an Cursorposition  }
       EditfCutBlock    = 60;         { in Clipboard ausschneiden      }
       EditfCCopyBlock  = 61;         { in Clipboard kopieren          }
       EditfPasteBlock  = 62;         { aus Clipboard einf�gen         }
       EditfWriteBlock  = 63;         { Block in Datei schreiben       }
       EditfReadBlock   = 64;         { Block aus Datei einlesen       }
       EditfMarkWord    = 65;         { Wort markieren                 }
       EditfMarkLine    = 66;         { Zeile markieren                }
       EditfMarkPara    = 67;         { Absatz markieren               }
       EditfMarkAll     = 68;         { ganzen Text markieren          }
       EditfNewline     = 69;         { Enter                          }
       EditfTAB         = 70;         { TAB-Sprung                     }
       EditfUndelete    = 71;         { Undelete                       }
       EditfHideBlock   = 72;         { Blockmarkierung abschalten     }
       EditfReformat    = 73;         { Block reformatieren            }
       EditfDelToEOF    = 74;         { alles ab Cursorposition l�schen }
       EditfRot13       = 75;         { Block Rot13-codieren           }
       EditfPrint       = 76;         { Block ausdrucken               }
       EditfDeltoEnd    = 77;         { L�schen bis Absatzende         }
       EditfParagraph   = 78;         { ^P^U                           }
       EditfChangeCase  = 79;         { Alt-3                          }
       EditfReadUUeBlock= 80;         { Block aus Datei einlesen & UU-Encode }
       EditfFormatBlock = 81;         { Block reformatieren            }
       EditfGlossary    = 82;         { Glossary-Funktion              }

       EditfFind        = 100;        { Suchen                         }
       EditfFindReplace = 101;        { Suchen + Ersetzen              }
       EditfFindRepeat  = 102;        { wiederholen (^L)               }
       EditfCtrlPrefix  = 103;        { Steuerzeichen-Pr�fix           }
       EditfWrapOn      = 104;        { Absatzumbruch einschalten      }
       EditfWrapOff     = 105;        { Absatzumbruch ausschalten      }
       EditfAllwrapOn   = 106;        { Umbruch f�r ganzen Text ein    }
       EditfAllwrapOff  = 107;        { Umbruch f�r ganzen Text aus    }
       EditfSetMargin   = 108;        { rechten Rand einstellen        }
       EditfText        = 109;        { *** Zeicheneingabe ***         }
       EditfChangeInsert= 110;        { Einf�gemodus umschalten        }
       EditfAbsatzmarke = 111;        { #20 ein/ausschalten            }
       EditfRestorePara = 112;        { �nderungen r�ckg�ngig machen   }
       EditfChangeIndent= 113;        { Einr�cken umschalten           }

       EditfMenu        = 120;        { F10 - lokales Men�             }
       EditfSetup       = 121;        { Einstellungen                  }
       EditfSaveSetup   = 122;        { Einstellungen speichern        }
       EditfSave        = 123;        { Speichern                      }
       EditfBreak       = 124;        { Abbruch                        }
       EditfSaveQuit    = 125;        { Speichern + Ende               }

       MaxFindLen       = 30;
       EditMenuMps      = 17;

       QuoteCharSet : set of char = [':','|']; { Weitere Quotezeichen }


type   EdColrec = record
                    coltext,colstatus,colmarked,
                    colendmark                   : byte;
                    colquote                     : array[1..9] of byte;
                    colmenu,colmenuhi,colmenuinv,
                    colmenuhiinv                 : byte;
                  end;

       LangData = record
                    zeile,spalte : string[8];
                    ja,nein      : char;
                    errors       : array[1..6] of string[30];
                    askquit      : string[30]; { 'Ge�nderten Text speichern' }
                    askoverwrite : string[50]; { 'Datei existiert schon - �berschreiben' }
                    askreplace   : string[40]; { 'Text ersetzen (Ja/Nein/Alle/Esc)' }
                    replacechr   : string[3];  { 'JNA' }
                    ersetzt      : string[30]; { ' Textstellen ersetzt' }
                    drucken      : string[15]; { 'Drucken ...' }
                    menue        : array[0..editmenumps] of string[20];
                  end;
       LdataPtr = ^LangData;

       EdConfig = record
                    absatzendezeichen : char;
                    rechter_rand      : word;
                    AutoIndent        : boolean;
                    PersistentBlocks  : boolean;
                    QuoteReflow       : boolean;
                  end;

       EdAskQuit   = function(ed:ECB):taste;  { J/N/Esc }
       EdAskOverwrite = function(ed:ECB; fn:pathstr):taste;
       EdMessage   = procedure(txt:string; error:boolean);   { Meldung anzeigen }
       EdAskFile   = procedure(ed:ECB; var fn:pathstr; save,uuenc:boolean);  { Dateinameneingabe }
       EdFindPanel = function(ed:ECB; var txt:string; var igcase:boolean):boolean;
       EdReplPanel = function(ed:ECB; var txt,repby:string; var igcase:boolean):boolean;
       EdConfigPanel = procedure(var cfg:EdConfig; var brk:boolean);

       EdProcs  = record
                    QuitFunc  : EdAskQuit;         { Frage bei Programmende }
                    Overwrite : EdAskOverwrite;    { Datei �berschreiben?   }
                    MsgProc   : EdMessage;         { Meldung/Fehler         }
                    FileProc  : EdAskFile;         { Dateiname abfragen     }
                    FindFunc  : EdFindPanel;       { Such-Dialog            }
                    ReplFunc  : EdReplPanel;       { Ersetze-Dialog         }
                    CfgFunc   : EdConfigPanel;     { Config-Dialog          }
                  end;


implementation

end.
{
  $Log: eddef.pas,v $
  Revision 1.8  2001/12/23 12:39:08  mm
  - Log ;-)

  Revision 1.7  2001/12/23 12:22:06  mm
  "Suchen", "Ersetzen", "Weitersuchen" und "Beenden" zum
  Rechtsklick/F10-Menue hinzugefuegt (Jochen Gehring)

  Revision 1.6  2000/11/24 19:46:55  rb
  Bugfix: C/O/I wurde im Editor nicht �bernommen

  Revision 1.5  2000/07/19 23:04:39  rb
  Glossary-Funktion eingebaut (Alt-G)

  Revision 1.4  2000/04/09 18:05:19  openxp
  Aktualisiert mit Source vom 09.04.2000 des OpenXP Teams

  Revision 1.5  2000/03/17 21:22:10  rb
  vActAbs entfernt, erster Teil von 'Bl�cke reformatieren' (<Ctrl K><F>)

  Revision 1.4  2000/02/17 16:14:19  mk
  MK: * ein paar Loginfos hinzugefuegt

}
