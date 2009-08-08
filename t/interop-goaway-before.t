# Errno::AnyString 0.05 t/interop-goaway-before.t
# Test the inter-operation interface: disabling package before it has been loaded

use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use lib "t";
use ThingThatDisablesIt;
use ThingThatUsesIt;

ok !tied($!), "\$! not tied after goaway";

eval 'use Errno::AnyString qw/custom_errstr/'; die $@ if $@;

ok !tied($!), "\$! still not tied after use after goaway";

$! = custom_errstr("qwerty");
unlike $!, qr/qwerty/, "\$! magic restored by goaway";

