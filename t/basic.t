# Errno::AnyString 0.05 t/basic.t
# Test basic usage

use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

use Errno ':POSIX';
use Errno::AnyString qw/custom_errstr ERRSTR_SET/;

$! = custom_errstr "an error string";
is "$!", "an error string", "set string worked";
is 0+$!, ERRSTR_SET, "$! returned ERRSTR_SET in number context";

# basic saved errno
{
    $! = custom_errstr "keep this error message";
    my $saved_errno = $!;

    $! = custom_errstr "foo";
    $! = custom_errstr "bar";
    $! = ENOENT;

    $! = $saved_errno;
    is 0+$!, ERRSTR_SET, "saved errno number restored";
    is "$!", "keep this error message", "saved errno custom string restored";
}

# saved errno with the dualvar value copied around
{
    $! = custom_errstr "qwerty";

    my $a = { foo => $! };
    my $b = [ 1, $a, 3 ];

    $! = custom_errstr "foo";
    $! = custom_errstr "bar";
    $! = ENOENT;

    $! = $b->[1]{foo};
    is 0+$!, ERRSTR_SET, "copyaround errno number restored";
    is "$!", "qwerty", "copyaround errno custom string restored";
}

# errno saved numerically only, can only work if no other custom errstr
# was set between the save and the restore.
{ 
    $! = custom_errstr "qwerty123";

    my $a = 0 + $!;

    $! = ENOENT;

    $! = $a;
    is 0+$!, ERRSTR_SET, "numeric saved errno number restored";
    is "$!", "qwerty123", "numeric saved errno custom string restored";
}

