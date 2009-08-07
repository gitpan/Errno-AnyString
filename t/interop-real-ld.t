# Errno::AnyString 0.04 t/interop-real-ld.t
# Test the inter-operation interface: get real $! after load/disable

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;

use Scalar::Util qw/dualvar/;

use lib "t";
use ThingThatUsesIt;
use ThingThatDisablesIt;

$! = dualvar 458513437, "qwerty";

my $e = exists &Errno::AnyString::real_errno ? &Errno::AnyString::real_errno : \$!;

is 0+$$e, 458513437, "number consistent with real \$!";
unlike "$$e", qr/qwerty/, "string consistent with real \$!";

