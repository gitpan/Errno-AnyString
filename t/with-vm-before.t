# Errno::AnyString 0.50 t/with-vm-before.t
# Inter-operation with Variable::Magic, V::M loaded before Errno::AnyString

use strict;
use warnings;

use Test::More;
BEGIN {
    eval 'use Variable::Magic qw/wizard cast/';
    plan skip_all => 'Variable::Magic required' if $@;

    plan tests => 5;
}
use Test::NoWarnings;

use Scalar::Util qw/dualvar/;
use lib 't';
use NormalErrnoOperation;

our $setlog;

# On some perl versions, 'local $!' copies the magic from one scalar to
# another with the side effect of reversing the order of the list of
# magics. If that's true here, I can arrange for V::M's get handler to
# run after the native $! magic.
our $local_reverses_magic;

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
}

use Errno::AnyString qw/custom_errstr register_errstr/;

local $!; 

$setlog = '';
$! = 15;
$! = 0;

is $setlog, "set to 15;set to 0;", "V::M set hook working";

$! = custom_errstr "it's on fire";
is "$!", "it's on fire", "custom overrides V::M get hook";

register_errstr "out of fruit", 999999;
$! = 999999;
is "$!", "out of fruit", "register overrides with V::M get hook";

SKIP: {
    skip "local does not reverse magic list", 1 unless $local_reverses_magic;

    my $normal = NormalErrnoOperation->new;
    $normal->set;
    my $errstr = $normal->errstr;
    is "$!", "Dude, $errstr!", "V::M get hook works when not overridden";
}


