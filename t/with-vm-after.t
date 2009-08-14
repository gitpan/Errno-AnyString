# Errno::AnyString 0.50 t/with-vm-after.t
# Inter-operation with Variable::Magic, V::M loaded after Errno::AnyString

use strict;
use warnings;

use lib 't';
use NormalErrnoOperation;
use Errno::AnyString qw/custom_errstr register_errstr/;

our @norm;
BEGIN { @norm = NormalErrnoOperation->new }

use Test::More;
BEGIN {
    eval 'use Variable::Magic qw/wizard cast/';
    plan skip_all => 'Variable::Magic required' if $@;

    plan tests => 4 + 2*@norm;
}
use Test::NoWarnings;

use Scalar::Util qw/dualvar/;

our $setlog;

my $wiz = wizard
    set => sub { $setlog .= "set to ".(0+${$_[0]}).";"; ${$_[0]} },
    get => sub { ${$_[0]} = dualvar ${$_[0]}, "Dude, ${$_[0]}!"; };

cast $!, $wiz;

# Hack: local copies $!'s magic to a new scalar, and on some Perl
# versions it reverses the list of magics in the process, so this
# might move the V::M get hook to the end of the list, giving it
# a chance to run last. Or it might not.
local $!; 

$setlog = '';
$! = 15;
$! = 0;

is $setlog, "set to 15;set to 0;", "V::M set hook working";

$! = custom_errstr "it's on fire";

SKIP: {
    skip "local doesn't reverse magic list on this Perl", 2+2*@norm if "$!" eq "it's on fire";

    is "$!", "Dude, it's on fire!", "custom cooperates with V::M get hook";

    register_errstr "out of fruit", 999999;
    $! = 999999;
    is "$!", "Dude, out of fruit!", "register cooperates with V::M get hook";

    foreach my $n (@norm) {
        $n->set;
        my $errno = $n->errno;
        my $errstr = $n->errstr;

        is 0+$!, $n->errno, "errno ok $errno";
        is "$!", "Dude, $errstr!", "errstr ok $errno";
    }
}
 
