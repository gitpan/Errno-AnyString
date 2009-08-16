#!perl -T
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# This file was automatically built from t/in-pm-files.ttmpl
#
# Do not edit this file, instead edit the template and rebuild by running
# t/build-test-scripts
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Check that the effects of loading Errno::AnyString materialize in other
# already-loaded modules. Errno.pm loading = evaluse

use strict;
use warnings;

eval "use Errno"; die $@ if $@;

use Test::More;
use Test::NoWarnings;

use lib 't';
use Foo1;
use Foo2;
use Foo3;
use Foo4;
use Errno::AnyString qw/CUSTOM_ERRSTR_ERRNO custom_errstr/;

my @pkgs = map {"Foo$_"} (1 .. 4);
plan tests => @pkgs*6 + 2;

foreach my $pkg (@pkgs) {
    my $x = $pkg->new;

    $! = custom_errstr "string1";
    is $x->errstr, "string1", "$pkg special errstr set";
    is $x->errno, CUSTOM_ERRSTR_ERRNO, "$pkg special errno set";

    my $save = $!;

    $! = 0;
    isnt $x->errstr, "string1", "$pkg special errstr unset";
    isnt $x->errno, CUSTOM_ERRSTR_ERRNO, "$pkg special errno unset";

    $! = $save;
    is $x->errstr, "string1", "$pkg special errstr restored";
    is $x->errno, CUSTOM_ERRSTR_ERRNO, "$pkg special errno restored";
}


use Test::Taint;
taint_checking_ok;

