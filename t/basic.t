# Errno::AnyString 0.03 t/basic.t
# Test basic usage

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;

use Errno ':POSIX';
use Errno::AnyString qw/custom_errstr ERRSTR_SET/;

$! = custom_errstr "an error string";
is "$!", "an error string", "set string worked";
is 0+$!, ERRSTR_SET, "$! returned ERRSTR_SET in number context";

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

