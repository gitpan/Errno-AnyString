# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# This file was automatically built from t/with-mockbdb.ttmpl
#
# Do not edit this file, instead edit the template and rebuild by running
# t/build-test-scripts
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Inter-operation with BDB, BDB loaded after Errno::AnyString
# Actually tests inter-operation with t/MockBDB.pm, which uses Inline::C to load up a
# copy of BDB's xs code to patch $!.

use strict;
use warnings;

use lib 't';
use NormalErrnoOperation;
our @norm;
BEGIN { @norm = NormalErrnoOperation->new }

use Errno::AnyString qw/custom_errstr register_errstr CUSTOM_ERRSTR_ERRNO/;

use Test::More;
BEGIN {
    eval 'use MockBDB';
    plan skip_all => 'Inline::C missing or failed' if $@;

    plan tests => 7 + 2*@norm + 1;
}
use Test::NoWarnings;


# Errno::AnyString features
$! = custom_errstr "custom 1";
is "$!", "custom 1", "custom_errstr string";
is 0+$!, CUSTOM_ERRSTR_ERRNO, "custom_errstr number";

$! = register_errstr "register 1";
is "$!", "register 1", "register_errstr string";

register_errstr "register 2", 999999;
$! = 999999;
is "$!", "register 2", "register_errstr string numeric assign";
is 0+$!, 999999, "register_errstr number numeric assign";

# BDB features
$! = -30923;
is "$!", "Fake BDB error -30923", "BDB string";
is 0+$!, -30923, "BDB numeric";

# Normal operation
foreach my $n (@norm) {
    $n->set;
    my $errno = $n->errno;
    my $errstr = $n->errstr;

    is 0+$!, $n->errno, "normal errno ok $errno";
    is "$!", $errstr, "normal errstr ok $errno";
}

