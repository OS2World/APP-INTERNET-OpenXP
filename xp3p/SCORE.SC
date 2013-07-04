#
# { $Id: SCORE.SC,v 1.1 2001/07/11 19:47:18 rb Exp $ }
#
# Kommentare beginnen mit '#' oder ';' am Zeilenanfang
#

# alles, was auf -9999 gescored wird, nicht herunterladen
# alles, was zwischen -1000 und -9998 gescored wird, nur Header laden

-9999 -9999 skip
-9998 -1000 hdronly

# folgende Regeln anwenden auf Postings mit Crosspoint im Gruppennamen

[*crosspoint*]

# Wenn mindestens zwei der folgenden vier Regeln anschlagen, wird nur der
# Header geholt:

score -500
name Text+HTML runterscoren
content-type=*multipart/alternative*

or score -500
name Outlook Express als Newsreader: runterscoren
x-newsreader=*Outlook Express*
user-agent=*Outlook Express*

score -500
name Kein Realname: runterscoren!
from!=* *(* *)*

score -500
name Crossposting in mind. 5 NGs
newsgroups=*,*,*,*,*

# Wenn eine dieser Regeln anschl„gt, wird der Artikel gar nicht
# heruntergeladen:

or score=-9999
name Dummuser wech
from=*dummuser1*
from=*dummuser2*

score=-9999
name Nerv-Thread wech
subject=*mega-nerv-thread*

# {
#   $Log: SCORE.SC,v $
#   Revision 1.1  2001/07/11 19:47:18  rb
#   checkin
#
# 
# }
