# Errno::AnyString 0.50 t/register.t
# Test register_errstr

use strict;
use warnings;

use Test::More tests => 22;
use Test::NoWarnings;

use Errno::AnyString qw/register_errstr custom_errstr/;

$! = register_errstr "first registered error string";
my $first_errno = 0+$!;
is "$!", "first registered error string", "set string worked";

# basic saved errno
{
    $! = register_errstr "keep this error message";
    my $saved_errno = $!;

    $! = custom_errstr "foo";
    $! = register_errstr "asdfadsfs 123";
    $! = custom_errstr "bar";
    $! = register_errstr "asdfadsfs 124";
    $! = 1234;

    $! = $saved_errno;
    is "$!", "keep this error message", "saved errno custom string restored";
}

# saved errno via local
{
    $! = register_errstr "keep this error message too";

    {
        local $!;

        $! = custom_errstr "foo23";
        is "$!", "foo23", "local custom errstr installed";
        $! = register_errstr "foo24";
        is "$!", "foo24", "local registered errstr installed";
        $! = 12345;
        $! = custom_errstr "foo23qwerqewr";
        $! = register_errstr "foo23qwerqewrasdfasfdsdf";

        { local $! = 123 }
    }

    is "$!", "keep this error message too", "saved registered string restored";
}

# saved errno with the dualvar value copied around
{
    $! = register_errstr "qwerty";

    my $a = { foo => $! };
    my $b = [ 1, $a, 3 ];

    $! = custom_errstr "foo";
    $! = register_errstr "bar";
    $! = 12345;

    $! = $b->[1]{foo};
    is "$!", "qwerty", "copyaround registered string restored";
}

# errno saved numerically only, multi level.
{ 
    $! = register_errstr "qwerty123";
    my $a = 0 + $!;

    $! = 1234;
    $! = custom_errstr "zxcvzxcv";
    $! = register_errstr "zxcvzxcv-123423";
    $! = custom_errstr "AAAzxcvzxcv";
    $! = register_errstr "AAAzxcvzxcv-123423";

    $! = $a;
    is "$!", "qwerty123", "numeric saved errno registered string restored";
}

# reuse registered errno
{
    my $foo = register_errstr "a string";
    my $errno = 0 + $foo;
    $! = $errno;
    is "$!", "a string", "register 1";

    $foo = register_errstr "a string";
    my $e2 = 0+$!;
    is "$!", "a string", "register 2";

    is $e2, $errno, "errno reused";
}

# specify the errno
{
    {
        local $!;

        $! = register_errstr "nine nine nine", 999;
        is "$!", "nine nine nine", "register 999 string";
        is 0+$!, 999, "register 999 number";

        $! = 1234;
        $! = custom_errstr "zxcvzxcv";
        $! = register_errstr "zxcvzxcv-123423";
        $! = custom_errstr "AAAzxcvzxcv";
        $! = register_errstr "AAAzxcvzxcv-123423";

        $! = 999;
        is "$!", "nine nine nine", "restore 999 string";
        is 0+$!, 999, "restore 999 number";
    }

    $! = 999;
    is "$!", "nine nine nine", "restore 999 string outside block";
    is 0+$!, 999, "restore 999 number outside block";
}

# ignore register_errstr return value
{
    for my $i (0..9999) {
        register_errstr "foo error $i", 123450000+$i;
    }

    $! = 123455648;
    is 0+$!, 123455648, "register many, numeric set ok";
    is "$!", "foo error 5648", "register many, got registered string";
}

# re-use errno values
{
    my $x = register_errstr "string 999";
    my $y = register_errstr "string 999 foo";
    my $z = register_errstr "string 999";
    isnt 0+$y, 0+$x, "errno value not re-used on non-duplicate registration";
    is 0+$z, 0+$x, "errno value re-used on duplicate registration";
}


$! = $first_errno;
is "$!", "first registered error string", "longterm numeric restore worked";


