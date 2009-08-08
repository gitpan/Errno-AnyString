# Errno::AnyString 0.05 t/threads.t
# Check that Errno::AnyString does the right thing under a threaded Perl

use strict;
use warnings;

use Test::More;
BEGIN {
    use Config;
    plan skip_all => 'ithreads required' unless $Config{useithreads};
    plan tests => 8;
}
use Test::NoWarnings;

use threads;
use Errno::AnyString qw/custom_errstr ERRSTR_SET/;

my $badthread = threads->create(\&thread_try_to_cause_problems);

{
    $! = 99_999_971;
    select undef, undef, undef, .3;
    is 0+$!, 99_999_971, "per-thread errno";

    $! = custom_errstr "test message";
    select undef, undef, undef, .3;
    is 0+$!, ERRSTR_SET, "per-thread errno";
    is "$!", "test message", "per-thread custom errstr";

    my $saved_errno = $!;
    $! = 1235;
    $! = custom_errstr "aksjfdhakdsfh";
    $! = $saved_errno;
    select undef, undef, undef, .3;
    is "$!", "test message", "custom errstr restore theadsafe";

    $! = custom_errstr "test message 2";
    my $saved_errno_numeric = 0 + $!;
    $! = 1235;
    select undef, undef, undef, .3;
    $! = $saved_errno_numeric;
    is "$!", "test message 2", "custom errstr numeric restore theadsafe";

    my $result = threads->create(sub {
        $! = custom_errstr "message from another thread";
        return { Error => $! };
    })->join;
    is "$result->{Error}", "message from another thread", "cross-thread errstr passing";
    is 0+$result->{Error}, ERRSTR_SET,                    "cross-thread errno passing";

}

$badthread->kill('KILL')->join;

sub thread_try_to_cause_problems {
    $SIG{'KILL'} = sub { threads->exit(); };

    my $i = 0;
    for (1 .. 1000) {
        $! = custom_errstr "qwerty " . ++$i;
        select undef, undef, undef, .01;

        $! = 1234;
        select undef, undef, undef, .01;

        open my $fh, "<", "/no/such/file";
        select undef, undef, undef, .01;
    }
}

