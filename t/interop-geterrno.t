# Errno::AnyString 0.50 t/interop-geterrno.t
# Test the documented way to get at the real $!

use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;

use Errno ':POSIX';
use Errno::AnyString qw/register_errstr/;

open my $fh, "<", "/no/such/file/as0d8f0asd8f0sdf" and die "open unexpectedly worked";

my $errno = 0+$!;
my $real_errstr = "$!";

register_errstr "$real_errstr, dude!", $errno;

is 0+$!, $errno, "errno";
is "$!", "$real_errstr, dude!", "modified errstr";

my $e = do { local %Errno::AnyString::Errno2Errstr ; $! };

is 0+$e, $errno, "real errno";
is "$e", $real_errstr, "real errstr";

