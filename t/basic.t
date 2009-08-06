# Errno::AnyString 0.02 t/basic.t
# Test basic usage

use strict;
use warnings;

use Test::More tests => 7;
use Test::NoWarnings;

use Errno::AnyString;

use Errno ':POSIX';
use Errno::AnyString qw/ERRSTR_SET/;

$! = "--an error string";
is "$!", "an error string", "set string worked";
is 0+$!, ERRSTR_SET, "$! returned ERRSTR_SET in number context";

{
    $! = "--keep this error message";
    my $saved_errno = $!;

    $! = "--foo";
    $! = "--bar";
    $! = ENOENT;

    $! = $saved_errno;
    is 0+$!, ERRSTR_SET, "saved errno number restored";
    is "$!", "keep this error message", "saved errno custom string restored";

    $! = 0 + $saved_errno;
    is 0+$!, ERRSTR_SET, "saved numonly errno number restored";
    is "$!", "Errno::AnyString failed to restore a saved errno value", "saved numonly errno fallback string";
}

