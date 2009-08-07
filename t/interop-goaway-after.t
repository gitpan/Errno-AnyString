# Errno::AnyString 0.04 t/interop-goaway-after.t
# Test the inter-operation interface: disabling package after it has been loaded

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use lib "t";
use ThingThatUsesIt;
use ThingThatDisablesIt;

ok !tied($!), "\$! not tied after goaway";

eval 'use Errno::AnyString qw/custom_errstr/'; die $@ if $@;

ok !tied($!), "\$! still not tied after use after goaway";

$! = custom_errstr("qwerty");
unlike $!, qr/qwerty/, "\$! magic restored by goaway";
