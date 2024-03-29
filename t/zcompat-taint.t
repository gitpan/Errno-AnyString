#!perl -T
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# This file was automatically built from t/zcompat.ttmpl
#
# Do not edit this file, instead edit the template and rebuild by running
# t/build-test-scripts
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Test compatibility with traditional $! behavior.

use strict;
use warnings;

use Test::More;
use Test::NoWarnings;

use Scalar::Util qw/dualvar/;
use Errno;

use lib 't';
use NormalErrnoOperation;

our @system_errors = NormalErrnoOperation->new;
our $fh_none = NormalErrnoOperation->flathash_none;

my $tests_per_errno_ok = 6 + @system_errors;
my $errno_ok_calls = 2 * 2 * (3 * @system_errors * 9);
plan tests => $errno_ok_calls * $tests_per_errno_ok + 3 + 2*2*8 + 2;

our $errno_ok_start_with_numeric;

foreach my $testtype (qw/baseline compat compat2/) {
    if ($testtype eq 'compat') {
        eval 'use Errno::AnyString qw/custom_errstr register_errstr/'; die $@ if $@;
    }
    $! = 74;
    my $copied_errno = $!;
    foreach my $reset_zero (0, 1) {
        foreach $errno_ok_start_with_numeric (0, 1) {
            foreach my $i (0 .. $#system_errors) {
                my $sym = $system_errors[$i]->symbol; # Errno.pm symbolic code, such as ENOENT
                my $errno = $system_errors[$i]->errno;
                my $name = $sym || $errno;

                $system_errors[$i]->set;
                errno_ok( $system_errors[$i], "$testtype setter $name" );
                $! = 0 if $reset_zero;

                {
                    local $!;
                    $system_errors[$i]->set;
                    errno_ok( $system_errors[$i], "$testtype setter $name, local preserves magic" );
                }

                $! = $errno;
                errno_ok( $system_errors[$i], "$testtype set errno $name" );
                $! = 0 if $reset_zero;

                # anything that perl groks as a number must be treated as such
                $! = $errno."e0";
                errno_ok( $system_errors[$i], "$testtype set errno $name exp" );
                $! = 0 if $reset_zero;

                $! = "$errno ";
                errno_ok( $system_errors[$i], "$testtype set errno $name trailspace" );
                $! = 0 if $reset_zero;

                $! = "$errno.0000e00 ";
                errno_ok( $system_errors[$i], "$testtype set errno $name xmas" );
                $! = 0 if $reset_zero;

                # even this silly thing must work. It warns, but sets $! to the number
                { 
                    no warnings;
                    $! = "$errno things are currently on fire";
                }
                errno_ok( $system_errors[$i], "$testtype set errno $name silly" );
                $! = 0 if $reset_zero;

                # Native $! will ignore the pv if the sv contains a number, so do I
                # unless my magic errno value is used.
                $! = dualvar $errno, "123456";
                errno_ok( $system_errors[$i], "$testtype set errno $name dualvar" );
                $! = 0 if $reset_zero;

                if ($sym) {
                    eval "\$! = &Errno::$sym"; die $@ if $@;
                    errno_ok( $system_errors[$i], "$testtype set symbol $name" );
                    $! = 0 if $reset_zero;
                } else {
                    foreach my $j (1 .. $tests_per_errno_ok) {
                        ok 1, "fake test to simplify test counting calculation";
                    }
                }
            }
            if ($testtype eq "compat") {
                $! = custom_errstr("my hovercraft is full of eels");
                my $fh_now = NormalErrnoOperation->flathash_now;
                is $fh_now, $fh_none, "custom errstr sets nothing in %!";
                is $!+0, 458513437, "custom string expected errno";
                is "$!", "my hovercraft is full of eels", "custom string expected errstr";
                $! = 0 if $reset_zero;
                
                $! = register_errstr("my hovercraft is full of peels");
                $fh_now = NormalErrnoOperation->flathash_now;
                is $fh_now, $fh_none, "register errstr sets nothing in %!";
                is "$!", "my hovercraft is full of peels", "register string expected errstr";
                $! = 0 if $reset_zero;

                $! = register_errstr("my hovercraft is full of beagles", 654321);
                $fh_now = NormalErrnoOperation->flathash_now;
                is $fh_now, $fh_none, "register errstr 654321 sets nothing in %!";
                is $!+0, 654321, "custom string expected errno";
                is "$!", "my hovercraft is full of beagles", "register string 654321 expected errstr";
                $! = 0 if $reset_zero;
            }
        }
    }
    is 0+$copied_errno, 74, "copying $! does not copy the magic";
}

sub errno_ok {
    my ($want, $testname) = @_;

    $testname .= " $errno_ok_start_with_numeric";

    {
        local $! = 13;
        is 0+$!, 13, "$testname localized 13";
    }

    if ($errno_ok_start_with_numeric) {
        is 0+$!, $want->errno, "$testname errno";
    }
    is "$!", $want->errstr, "$testname errstr";
    is 0+$!, $want->errno, "$testname errno 2";
    is "$!", $want->errstr, "$testname errstr 2";
    unless ($errno_ok_start_with_numeric) {
        is 0+$!, $want->errno, "$testname errno postponed";
    }
    foreach my $other (@system_errors) {
        if ($other->errno == $want->errno and $other->symbol) {
            ok $!{$other->symbol}, "$testname correct symbol set in %!";
        } elsif ($other->symbol) {
            ok ! $!{$other->symbol}, "$testname incorrect symbol not set in %!";
        } else {
            ok 1, "fake test to simplify test counting calculation";
        }
    }
    is $want->flathash_now, $want->normal_flathash, "$testname %!";
}


use Test::Taint;
taint_checking_ok;

