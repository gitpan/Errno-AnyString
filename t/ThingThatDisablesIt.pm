package ThingThatDisablesIt;
use strict;
use warnings;

  $Errno::AnyString::do_not_init = 1;
  if (exists &Errno::AnyString::go_away) {
      &Errno::AnyString::go_away;
  }


1;

