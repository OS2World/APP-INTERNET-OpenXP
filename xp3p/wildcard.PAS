{ $Id: wildcard.PAS,v 1.1 2001/07/11 19:47:19 rb Exp $ }

unit wildcard;

{$i asldefine.inc}

interface uses misc, strings;

function match_wildcard (ws, s: shortstring; casesensitive: boolean): boolean;

function WildcardMatch(pattern, source: pchar): Boolean;
function WildcardMatchIC(pattern, source: pchar): Boolean;
function WildcardMatchEx(pattern, source: pchar; ic: Boolean): Boolean;
function myStrNew(Str: PChar): PChar;

implementation

function myStrNew(Str: PChar): PChar;
var
  L: Word;
  P: PChar;
begin
  myStrNew := nil;
  if (Str <> nil) { and (Str^ <> #0) } then
  begin
    L := StrLen(Str) + 1;
    GetMem(P, L);
    if P <> nil then myStrNew := StrMove(P, Str, L);
  end;
end;

function match_wildcard (ws, s: shortstring; casesensitive: boolean): boolean;
  var fertig, match, stern: boolean;
      p, ps, pf: word;
      s1, s_ws, s_s: string;
  label weiter;
  begin
    if not casesensitive then begin
      upstr (ws);
      upstr (s);
    end;
    fertig := false;
    match := false;
    stern := false;
    s_ws := '';
    while not fertig do begin
      if length (ws) = 0 then begin
        if stern or (length (s) = 0) then match := true;
        fertig := true;
      end;
      if not fertig then begin
        if ws [1] = '?' then begin
          if length (s) = 0 then fertig := true
          else begin
            delete (ws, 1, 1);
            delete (s, 1, 1);
          end;
        end
        else if ws [1] = '*' then begin
          delete (ws, 1, 1);
          stern := true;
        end
        else begin
          weiter:
          ps := pos ('*', ws);
          pf := pos ('?', ws);
          if ps = 0 then ps := pf;
          if (pf < ps) and (pf > 0) then ps := pf;
          if ps = 0 then ps := length (ws) else dec (ps);
          s1 := copy (ws, 1, ps);
          p := pos (s1, s);
          if p = 0 then fertig := true
          else begin
            if not stern and (p > 1) then fertig := true
            else begin
              if stern and (length (s_ws) = 0) then begin
                s_ws := ws;
                s_s := s;
                delete (s_s, 1, p);
              end;
              delete (ws, 1, ps);
              delete (s, 1, p + ps - 1);
              stern := false;
            end;
          end;
        end;
      end;
    end;
    if not match and (length (s_ws) > 0) then begin
      fertig := false;
      stern := true;
      ws := s_ws;
      s := s_s;
      s_ws := '';
      goto weiter;
    end;
    match_wildcard := match;
  end;

function WildcardMatchEx(pattern, source: pchar; ic: Boolean): Boolean;
begin
  { perform a wildcard match, either case-sensitive or case-insensitive,
    depending on the ic flag. }
  if ic = True then
    WildcardMatchEx := WildcardMatch(pattern, source)
  else
    WildcardMatchEx := WildcardMatchIC(pattern, source);
end;

function WildcardMatchIC(pattern, source: pchar): Boolean;
var src,pat:pchar;
begin
  { perform a case insensitive wildcard match by converting the pattern
    and source strings to uppercase. }
  src:=mystrnew(source);
  pat:=mystrnew(pattern);
  WildcardMatchIC := WildcardMatch(StrUpper(pat), StrUpper(src));
  strdispose(pat);
  strdispose(src);
end;

function WildcardMatch(pattern, source: pchar): Boolean;

begin
  if 0 = StrComp(pattern,'*') then
    WildcardMatch := True
  else if (source^ = Chr(0)) and (pattern^ <> Chr(0)) then
    WildcardMatch := False
  else if source^ = Chr(0) then
    WildcardMatch := True
  else begin
    case pattern^ of
    '*': if WildcardMatch(@pattern[1],source) then
           WildcardMatch := True
         else
           WildcardMatch := WildcardMatch(pattern,@source[1]);
    '?': WildcardMatch := WildcardMatch(@pattern[1],@source[1]);
    else
      if source^ = pattern^ then
        WildcardMatch := WildcardMatch(@pattern[1],@source[1])
      else
        WildcardMatch := False;
    end;
  end;
end;

end.


{
  $Log: wildcard.PAS,v $
  Revision 1.1  2001/07/11 19:47:19  rb
  checkin


}
