#!perl -T
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# This file was automatically built from t/autodie.ttmpl
#
# Do not edit this file, instead edit the template and rebuild by running
# t/build-test-scripts
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Inter-operation with Fatal, Fatal loaded after Errno::AnyString

use strict;
use warnings;

BEGIN { require Errno::AnyString; };

use Test::More;
use Test::Exception;
BEGIN {
    eval 'require Fatal';
    plan skip_all => 'Fatal required' if $@;

    plan tests => 4;
}
use Test::NoWarnings;

sub try_but_fail1 {
    $! = custom_errstr("set with custom errstr");
    return;
}
sub try_but_fail2 {
    $! = 999_999_999;
    return;
}
use Fatal qw/try_but_fail1 try_but_fail2/;

use Errno::AnyString qw/custom_errstr register_errstr/;
register_errstr "set with register errstr", 999_999_999;

throws_ok { try_but_fail1() } qr/set with custom errstr/,   "custom errstr seen by Fatal";
throws_ok { try_but_fail2() } qr/set with register errstr/, "register errstr seen by Fatal";


use Test::Taint;
taint_checking_ok;

