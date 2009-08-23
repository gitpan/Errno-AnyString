# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# This file was automatically built from t/threads.ttmpl
#
# Do not edit this file, instead edit the template and rebuild by running
# t/build-test-scripts
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Check that Errno::AnyString does the right thing under a threaded Perl

use strict;
use warnings;

use Test::More;
BEGIN {
    use Config;
    plan skip_all => 'ithreads required' unless $Config{useithreads};

    eval 'use threads';
    plan skip_all => 'threads.pm required' if $@;

    plan tests => 11;
}
use Test::NoWarnings;

use threads;
use Errno::AnyString qw/custom_errstr register_errstr CUSTOM_ERRSTR_ERRNO/;

my $badthread = threads->create(\&thread_try_to_cause_problems);

{
    $! = 99_999_971;
    select undef, undef, undef, .3;
    is 0+$!, 99_999_971, "per-thread errno";

    $! = custom_errstr "test message";
    select undef, undef, undef, .3;
    is 0+$!, CUSTOM_ERRSTR_ERRNO, "per-thread errno";
    is "$!", "test message", "per-thread custom errstr";

    my $saved_errno = $!;
    $! = 1235;
    $! = custom_errstr "aksjfdhakdsfh";
    $! = $saved_errno;
    select undef, undef, undef, .3;
    is "$!", "test message", "custom errstr restore theadsafe";

    $! = register_errstr "reg test message";
    select undef, undef, undef, .3;
    is "$!", "reg test message", "per-thread registered errstr";

    my $regsave = 0 + $!;
    $! = 1235;
    $! = register_errstr "aksjfdhakdsfh";
    $! = register_errstr "foo-aksjfdhakdsfh";
    $! = $regsave;
    select undef, undef, undef, .3;
    is "$!", "reg test message", "registered errstr restore theadsafe";

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
    is 0+$result->{Error}, CUSTOM_ERRSTR_ERRNO,           "cross-thread errno passing";

    my $regresult = threads->create(sub {
        $! = register_errstr "reg message from another thread";
        return { Error => $! };
    })->join;
    is "$regresult->{Error}", "reg message from another thread", "cross-thread reg errstr passing";
}

# Older versions of threads.pm lack kill, in which case I'll wait for
# the child to die of old age.
eval { $badthread->kill('KILL') };

$badthread->join;

sub thread_try_to_cause_problems {
    $SIG{'KILL'} = sub { threads->exit(); };

    for my $i (1 .. 200) {
        $! = custom_errstr "qwerty $i";
        select undef, undef, undef, .01;

        $! = 1234;
        select undef, undef, undef, .01;

        open my $fh, "<", "/no/such/file";
        select undef, undef, undef, .01;
    }
}

