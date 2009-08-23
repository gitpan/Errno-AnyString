#!perl -T
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# This file was automatically built from t/with-vm.ttmpl
#
# Do not edit this file, instead edit the template and rebuild by running
# t/build-test-scripts
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Inter-operation with Variable::Magic, V::M loaded after Errno::AnyString

use strict;
use warnings;

use lib 't';
use NormalErrnoOperation;
our @norm;
BEGIN { @norm = NormalErrnoOperation->new }

use Errno::AnyString qw/custom_errstr register_errstr/;

use Test::More;
BEGIN {
    eval 'use Variable::Magic qw/wizard cast/';
    plan skip_all => 'Variable::Magic required' if $@;

    plan tests => 3 + 2*@norm + 2;
}
use Test::NoWarnings;

use Scalar::Util qw/dualvar/;

# On some Perl versions, 'local $!' copies the magic from one scalar to
# another with the side effect of reversing the order of the list of
# magics. If that's true here, I can arrange for V::M's get handler to
# run after the native $! magic. So I'll check.
our $local_reverses_magic;

our $setlog;

BEGIN {
    my $wiz = wizard
        set => sub { $setlog .= "set to ".(0+${$_[0]}).";"; ${$_[0]} },
        get => sub { ${$_[0]} = dualvar ${$_[0]}, "Dude, ${$_[0]}!"; };

    cast $!, $wiz;

    local $!;
    $! = 1;
    if ("$!" =~ /^Dude, /) {
        $local_reverses_magic = 1;
    } else {
        $local_reverses_magic = 0;
    }
};


local $!;

$setlog = '';
$! = 15;
$! = 0;

is $setlog, "set to 15;set to 0;", "V::M set hook working";


SKIP: {
    skip "local does not reverse magic list", 2*@norm+2 unless $local_reverses_magic;

    $! = custom_errstr "it's on fire";
    is "$!", "Dude, it's on fire!", "custom cooperates with V::M get hook";

    register_errstr "out of fruit", 999999;
    $! = 999999;
    is "$!", "Dude, out of fruit!", "register cooperates with V::M get hook";


    foreach my $n (@norm) {
        $n->set;
        my $errno = $n->errno;
        my $errstr = $n->errstr;

        is 0+$!, $n->errno, "errno ok $errno";
        is "$!", "Dude, $errstr!", "V::M errstr ok $errno";
    }
}
 

use Test::Taint;
taint_checking_ok;
