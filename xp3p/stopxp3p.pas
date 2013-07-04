{ $Id: stopxp3p.pas,v 1.1 2001/07/11 19:47:19 rb Exp $ }

uses vpsyslow;

const sem_xp3p = 'SEMXP3P';

procedure postsem;
  begin
    {$ifdef os2}
    sempostevent(semaccessevent(sem_xp3p));
    {$endif}
  end;

begin
  postsem;
end.


{
  $Log: stopxp3p.pas,v $
  Revision 1.1  2001/07/11 19:47:19  rb
  checkin


}
