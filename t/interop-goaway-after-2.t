# Errno::AnyString 0.05 t/interop-goaway-after-2.t
# Test the inter-operation interface: disabling package after it has been loaded

use strict;
use warnings;

use Test::More tests => 6;
use Test::NoWarnings;

use lib "t";
use ThingThatUsesIt;
use ThingThatDisablesIt;

ok !tied($!), "\$! not tied after goaway";

eval 'use Errno::AnyString qw/custom_errstr/'; die $@ if $@;

ok !tied($!), "\$! still not tied after use after goaway";

$! = custom_errstr("qwerty");
unlike $!, qr/qwerty/, "\$! magic restored by goaway";

  $Errno::AnyString::do_not_init = 1;
  if (exists &Errno::AnyString::go_away) {
      &Errno::AnyString::go_away;
  }


ok !tied($!), "\$! still not tied after extra goaway";

$! = custom_errstr("qwerty");
unlike $!, qr/qwerty/, "\$! magic after extra goaway";

