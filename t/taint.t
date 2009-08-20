#!perl -T
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# This file was automatically built from t/taint.ttmpl
#
# Do not edit this file, instead edit the template and rebuild by running
# t/build-test-scripts
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Check that tainting is handled correctly

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;
use Test::Exception;
use Test::Taint;

use Errno::AnyString qw/custom_errstr register_errstr/;



my @set_tainted_errstr = (
    ['custom direct',    sub { $! = custom_errstr $_ }],
    ['custom indirect',  sub { my $x = custom_errstr $_; $! = $x; }],
    ['reg direct',       sub { $! = register_errstr $_ }],
    ['reg direct num',   sub { $! = register_errstr $_, 999999 }],
    ['reg indirect',     sub { my $x = register_errstr $_; $! = $x }],
    ['reg indirect num', sub { my $x = register_errstr $_, 111111; $! = $x }],
    ['reg numeric',      sub { register_errstr $_, 222222; $! = 222222 }],
);
    
plan tests => 4*@set_tainted_errstr + 2;

taint_checking_ok;

my $tainted_string = "a tainted string";
taint $tainted_string;

foreach my $test (@set_tainted_errstr) {
    my ($name, $setter) = @$test;

    $! = custom_errstr "not tainted";
    untainted_ok $!, "$name initially untainted";

    local $_ = "$name $tainted_string";
    tainted_ok $_, "\$_ tainted as expected";

    throws_ok { $setter->() } qr/Tainted error string used with Errno::AnyString/,
            "$name set tainted string croaked";

    untainted_ok $!, "$name didn't taint \$!";
}

