{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.1 $    $Date: 2001/07/11 19:47:17 $    $Author: rb $ }
{                                                                             }
{ Definition af c types                                                       }

{ $Id: CTypes.PAS,v 1.1 2001/07/11 19:47:17 rb Exp $ }

UNIT CTypes;

INTERFACE

//USES Use32;

CONST
  BUFSIZ = 128; // ???

TYPE
  int    = LongInt;
  uint   = LongInt;
  long   = LongInt;
  ulong  = LongInt;
  short  = Integer;
  ushort = Word;

IMPLEMENTATION

END.


{
  $Log: CTypes.PAS,v $
  Revision 1.1  2001/07/11 19:47:17  rb
  checkin


}
