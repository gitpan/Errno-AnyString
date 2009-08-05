# [ % Package %] 0.01 t/compat.t
# Test compatibility with traditional $! behavior

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use Errno ':POSIX';

our @system_errors = explore_system_errors();
our $flathash_noneset = $system_errors[-1]{FlatHash};

my $tests_per_errno_ok = 5 + @system_errors;
my $errno_ok_calls = 2 * (3 * @system_errors * 3 + 1);
plan tests => $errno_ok_calls * $tests_per_errno_ok + 1;

our $errno_ok_start_with_numeric;

foreach my $testtype (qw/baseline compat compat2/) {
    if ($testtype eq 'compat') {
        eval 'use Errno::AnyString'; die $@ if $@;
    }
    foreach $errno_ok_start_with_numeric (0, 1) {
        foreach my $i (0 .. $#system_errors) {
            my $sym = $system_errors[$i]{Symbol}; # Errno.pm symbolic code, such as ENOENT
            my $name = $sym || $system_errors[$i]{Errno};

            $system_errors[$i]{Setter}->();
            errno_ok( $system_errors[$i], "$testtype setter $name" );

            $! = $system_errors[$i]{Errno};
            errno_ok( $system_errors[$i], "$testtype set errno $name" );

            if ($sym) {
                eval "\$! = $sym"; die $@ if $@;
                errno_ok( $system_errors[$i], "$testtype set symbol $name" );
            } else {
                foreach my $j (1 .. $tests_per_errno_ok) {
                    ok 1, "fake test to simplify test counting calculation";
                }
            }
        }
        if ($testtype eq "compat") {
            # custom error string
            $! = "--my hovercraft is full of eels";
            errno_ok({
                Errno    => 458513437,
                Errstr   => "my hovercraft is full of eels",
                FlatHash => $flathash_noneset,
            }, "custom string set");
        }
    }
}

###############################################################################

sub errno_ok {
    my ($want, $testname) = @_;

    $testname .= " $errno_ok_start_with_numeric";

    if ($errno_ok_start_with_numeric) {
        is 0+$!, $want->{Errno}, "$testname errno";
    }
    is "$!", $want->{Errstr}, "$testname errstr";
    is 0+$!, $want->{Errno}, "$testname errno 2";
    is "$!", $want->{Errstr}, "$testname errstr 2";
    unless ($errno_ok_start_with_numeric) {
        is 0+$!, $want->{Errno}, "$testname errno postponed";
    }
    foreach my $other (@system_errors) {
        if ($other->{Errno} == $want->{Errno} and $want->{Symbol}) {
            ok $!{$other->{Symbol}}, "$testname correct symbol set in %!";
        } elsif ($other->{Symbol}) {
            ok ! $!{$other->{Symbol}}, "$testname incorrect symbol not set in %!";
        } else {
            ok 1, "fake test to simplify test counting calculation";
        }
    }
    is join(",", map {"$_=$!{$_}"} sort keys(%!)), $want->{FlatHash}, "$testname %!";
}

sub explore_system_errors {
    my @errorno_setters = (
        sub { open my $fh, "<", "osaudf080s8f0sa8fasf" and die "open failed to fail"; },
        sub { open my $fh, ">", "/oaudf080s8f0sa8fasf" and die "open failed to fail"; },
        sub {
            no warnings;
            setsockopt(3,3,3,3) and die "setsockopt failed to fail";
        },
        sub { $! = 3148753 },
    );

    my @system_errors;
    my %had_errno;
    foreach my $setter (@errorno_setters) {
        eval { $setter->() };
      next if $@;
        my $errno = 0+$!;
        my $errstr = "$!";
        my ($symbol) = grep { $!{$_} } keys(%!);
        my $flathash = join ",", map {"$_=$!{$_}"} sort keys(%!);
      next if $had_errno{$errno}++;
        push @system_errors, {
            Setter   => $setter,
            Errno    => $errno,
            Errstr   => $errstr,
            Symbol   => $symbol,
            FlatHash => $flathash,
        };
    }

    return @system_errors;
}

