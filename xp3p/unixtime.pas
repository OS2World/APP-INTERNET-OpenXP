{ $Id: unixtime.pas,v 1.2 2002/01/02 23:19:55 MH Exp $ }

(*-------------------------------------------------------------------*)
UNIT    UnixTime;   (*
    File name:      UNIXTIME.PAS    {Turbo Pascal 5+}
    Version:        0.2p
    Purpose:        Converts to/from Gregorian-local/Unix-kernel time.
    Author:         Copyright 1992 Gregory S. Vigneault
                    Box 7169,Stn.A,Toronto,Canada M5W 1X8.
                    greg.vigneault@canrem.uucp
    Created:        Feb.15.1992 02:00:00 EST (698137200 Unix time)
    Last edit:      Feb.19.1992 10:00:00 EST

    Version 0.2p changes the ZoneHrs function (TimeZone is now not
    accessable by programs).  The LocalZone variable still sets the
    TimeZone variable, but now LocalZone is updated to reflect result
    of ZoneHrs call.  See ZoneHrs function, and XTime example program.
                    *)
(*-------------------------------------------------------------------*)
INTERFACE

VAR     LocalZone   : String[6];
{---------------------------------------------------------------------}
FUNCTION DaysInMonth ( Month, Year :WORD ) :WORD;
{30 days has Sep,Apr,Jun & Nov; the rest have 31, except Feb... etc.}
{---------------------------------------------------------------------}
FUNCTION DaysInYear( Year :WORD ) :WORD;
{Returns either 365 or 366, depending if Year is a leap year or not.}
{---------------------------------------------------------------------}
FUNCTION GregToUnix(Year, Month, Day,           { Gregorian date }
                    Hour, Min,   Sec    :WORD;  { local time }
                    VAR tUnix           :LONGINT    { Unix time }
                                        ):BOOLEAN;  { error? }
{ Accepts: Gregorian calendar date, and local time.
  Returns: Unix kernel time.
  Refers to ZoneHrs function to derive Greenwich Mean Time (GMT).
  Earliest date allowed: Jan.1.1970, 00:00:00 local time
  Latest date accepted:  Jan.18.2038 (hour depends on +time zone)
              or         Jan.19.2038 (hour depends on -time zone)
  (Use LocalZone variable to account for Daylight Savings Time) }
{---------------------------------------------------------------------}
FUNCTION UnixToGreg( tUnix              :LONGINT;   { Unix time }
                    VAR Year,Month,Day,             { Gregorian date }
                        Hour,Min,Sec    :WORD       { local time }
                                        ):BOOLEAN;  { error? }
{ Accepts: Unix kernel time.
  Returns: Gregorian calendar date, and local time.
  Refers to ZoneHrs function to derive local time.
  (Use LocalZone variable to account for Daylight Savings Time) }
{---------------------------------------------------------------------}
FUNCTION ZoneHrs : INTEGER;
{ Determines +-hours from GMT, using TimeZone string.  Use LocalZone
  string to assign TimeZone, or to force use of TZ in environment:
    IF (LocalZone = '') THEN TimeZone := GetEnv('TZ')
    ... you can set environment TZ by typing SET TZ=EST+05 from DOS
    ELSE TimeZone := LocalTime;
    TimeZone value or format errors returns LocalZone='', otherwise
    returns LocalZone = TimeZone.
        Examples of valid TimeZone values ...
        'EST+05'    Eastern Standard Time
        'EDT+04'    Eastern Daylight-savings Time
        'CST+06'    Central Standard
        'MST+07'    Mountain Standard
        'PST+08'    Pacific Standard
        'GMT+00'    Greenwich Mean time
        'PAR-01'    Paris Standard                                  }
(*-------------------------------------------------------------------*)
IMPLEMENTATION

USES    Dos;    { for the GetEnv function (not avail in TP4) }
CONST   MinuteAsSeconds = 60;
        HourAsSeconds   = 60 * MinuteAsSeconds;
        DayAsSeconds    = 24 * HourAsSeconds;
VAR     TimeZone        : String[6];
{---------------------------------------------------------------------}
FUNCTION ZoneHrs : INTEGER;
    VAR i,j : LONGINT;              { private work var }
    BEGIN
    ZoneHrs := 0;                       { assume none }
    IF LocalZone = ''                   { use environment var? }
        THEN  TimeZone := GetEnv('TZ')  { get env var }
        ELSE  TimeZone := LocalZone;    { use internal var }

    IF TimeZone[0] = CHR(6)             { proper string length }
        THEN    BEGIN                   { convert ASCII to integer }
                    Val(Copy(TimeZone, 4, 3), i, j);     {convert}
                    IF (j <> 0) OR (i < -23) OR (i > 23) {be liberal}
                        THEN TimeZone[0] := CHR(0)       {error}
                        ELSE ZoneHrs := i                {okay}
                END
    ELSE TimeZone[0] := CHR(0);         { string length error }
    LocalZone := TimeZone               { result }
    END;    {ZoneHrs}
{---------------------------------------------------------------------}
FUNCTION DaysInMonth ( Month, Year :WORD) :WORD;
    BEGIN
    IF Month=2                              { Feb? }
    THEN IF (Year AND 3) = 0                { yr divisible by 4? }
         THEN IF (Year MOD 100) = 0         { a century? }
              THEN IF (Year MOD 400) = 0    { century div by 400? }
                    THEN DaysInMonth := 29  { then leap-century }
                    ELSE DaysInMonth := 28  { else not leap-cent }
              ELSE DaysInMonth := 29        { non-century leapyear }
         ELSE DaysInMonth := 28             { not leapyear }
    ELSE DaysInMonth := $15AA SHR Month AND 1 OR 30 { not Feb }
    END;    {DaysInMonth}
{---------------------------------------------------------------------}
FUNCTION DaysInYear( Year :WORD) :WORD;
    BEGIN
        DaysInYear := 337 + DaysInMonth( 2, Year )      { 365 or 366 }
    END;    {DaysInYear}
{---------------------------------------------------------------------}
FUNCTION GregToUnix( Year, Month, Day, Hour, Min, Sec :WORD;
                    VAR tUnix :LONGINT) :BOOLEAN;
{ globals used: DaysInMonth, ZoneHrs,                           }
{               MinuteAsSeconds, HourAsSeconds, DayAsSeconds    }
VAR days : LONGINT;  i : INTEGER;
BEGIN
    GregToUnix := FALSE;                    { if error }
    IF (Year < 1970)                        { invalid year? }
        OR (Year > 2038)
        OR (Hour > 23)                      { invalid hour? }
        OR (Min > 59)                       { invalid minute? }
        OR (Sec > 59)                       { invalid second? }
        OR (Month < 1)                      { invalid month? }
        OR (Month > 12)
        OR (Day < 1)                        { invalid day? }
        OR (Day > DaysInMonth(Month, Year))
    THEN EXIT;                              { abort GregToUnix }
    days := 0;                              { clear counter }
    FOR i := 1970 TO PRED(Year) DO INC(days, DaysInYear(i));
    FOR i := 1 TO PRED(Month) DO INC(days, DaysInMonth(i,Year));
    tUnix := DayAsSeconds * (days + Day - 1);   { total days }
    INC(tUnix,HourAsSeconds * (Hour + ZoneHrs));  { add all hours }
    INC(tUnix,MinuteAsSeconds * Min);           { add minutes }
    INC(tUnix,Sec);                             { add seconds }
    GregToUnix := TRUE;                         { no errors }
END;    {GregToUnix}
{---------------------------------------------------------------------}
FUNCTION UnixToGreg(tUnix :LONGINT;
                    VAR Year,Month,Day,Hour,Min,Sec :WORD) :BOOLEAN;
{globals used: DaysInMonth, DaysInYear, HourAsSeconds, ZoneHrs }
VAR days : LONGINT; DOY : WORD;
BEGIN
    UnixToGreg := FALSE;                { assume errors }
    IF (tUnix < 0) THEN EXIT;           { negative }
    DEC(tUnix,HourAsSeconds * ZoneHrs); { convert GMT to local time }
    Sec := tUnix MOD 60;                { Seconds }
        tUnix := tUnix DIV 60;          { convert secs to mins  }
    Min := tUnix MOD 60;                { Minutes }
        tUnix := tUnix DIV 60;          { cvt mins to hours  }
    Hour := tUnix MOD 24;               { Hours }
        days := tUnix DIV 24;           { cvt hours to days  }
        INC(days);                      { days since Jan.1.1970AD }
    Year := 1970;                       { assume starting year }
    IF (days <= DaysInYear(Year))       { 1970? }
        THEN    DOY := WORD(days)       { yes }
        ELSE    REPEAT                  { else scan }
                    DEC( days, DaysInYear( Year ) );
                    INC( Year );
                    DOY := WORD(days);
                UNTIL (days <= DaysInYear(Year));
    IF (Year > 2038) THEN EXIT;         { invalid year? }
    Month := 1;                         { assume starting month }
    IF (DOY <= DaysInMonth(Month,Year)) { Jan? }
        THEN    Day := DOY              { yes }
        ELSE    REPEAT                  { else scan }
                    DEC( DOY, DaysInMonth( Month,Year ) );
                    INC( Month );
                    Day := DOY;
                UNTIL (DOY <= DaysInMonth( Month,Year ));
    UnixToGreg := TRUE;                 { no errors }
END;    {UnixToGreg}
(*-------------------------------------------------------------------*)
END.    {Unit UnixTime}

{
 $Log: unixtime.pas,v $
 Revision 1.2  2002/01/02 23:19:55  MH
 # Komplette Ueberarbeitung der letzten Tage:
 - Fix: AccessViolations -> HugoStrings = AnsiString != String
   (evtl. Bug in Sysutils: Exception.Message)
 - Ausloesung von Exceptions korrigiert/ergaenzt (Sockets)
 - Anpassungen an neuer Schnittstelle
 - PHO-Filter (TWJ) ueberarbeitet - optimiert, LOGs, BFG-KillFile
 - CPS-SpeedAnzeige im Screen (TWJ)
 - APOP implementiert: Wird wahrscheinlich so noch nicht funktionieren, da noch
                       ein TimeStamp mit dem Password crypted werden muﬂ?!?

}
