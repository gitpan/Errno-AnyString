# Errno::AnyString 0.02 t/in-pm-files-impl.t
# Check that the effects of loading Errno::AnyString materialise in other
# already-loaded modules.

use strict;
use warnings;

# The line below differs between t/in-pm-files-*.t - it pulls
# in Errno.pm (or not) in various different ways.
my @implicitly_load_Errno_pm = keys(%!);

use Test::More;
use Test::NoWarnings;

use lib 't';
use Foo1;
use Foo2;
use Foo3;
use Foo4;
use Errno::AnyString qw/ERRSTR_SET/;

my @pkgs = map {"Foo$_"} (1 .. 4);
plan tests => @pkgs*6 + 1;

foreach my $pkg (@pkgs) {
    my $x = $pkg->new;

    $! = "--string1";
    is $x->errstr, "string1", "$pkg special errstr set";
    is $x->errno, ERRSTR_SET, "$pkg special errno set";

    my $save = $!;

    $! = 0;
    isnt $x->errstr, "string1", "$pkg special errstr unset";
    isnt $x->errno, ERRSTR_SET, "$pkg special errno unset";

    $! = $save;
    is $x->errstr, "string1", "$pkg special errstr restored";
    is $x->errno, ERRSTR_SET, "$pkg special errno restored";
}


