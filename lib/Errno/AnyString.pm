package Errno::AnyString;
use strict;
use warnings;

=head1 NAME

Errno::AnyString - put arbitrary strings in $!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Errno qw/ENOENT/;
  use Errno::AnyString;

  $! = "--my hovercraft is full of eels";
  my $s = "$!"; # $s now contains "my hovercraft is full of eels"

  open my $fh, "<", "/no/such/file";
  $s = "$!"; # $s now contains "no such file or directory"

  $! = "--the bells the bells";
  my $s = "$!"; # $s now contains "the bells the bells"

  my $saved_errno = $!;
   
  $! = ENOENT;
  $s = "$!"; # $s now contains "no such file or directory"

  $! = $saved_errno;
  $s = "$!"; # $s now contains "the bells the bells"


=head1 DESCRIPTION

C<Errno::AnyString> allows you to place an arbitrary error message in the special C<$!> variable, without disrupting C<$!>'s ability to pick up the result of the next system call that sets C<errno>.

It is useful if you are writing code that reports errors by setting C<$!>, and none of the standard system error messages fit.

If C<Errno::AnyString> is loaded, C<$!> behaves as normal unless a custom error string has been set by assigning a string starting with C<--> to C<$!>. If a custom error string is set, it will be returned when C<$!> is evaluated as a string, and 458513437 will be returned when C<$!> is evaluated as a number, see C<ERRSTR_SET> below.

=head1 EXPORTS

Nothing is exported by default. The following are available for export.

=head2 ERRSTR_SET

C<ERRSTR_SET> is a numeric constant with the value 458513437. This is the value that will be obtained when C<$!> is evaluated in a numeric context while a custom error string is set.

=cut

use Exporter;
use Carp;
use Scalar::Util qw/dualvar/;

require XSLoader;
XSLoader::load('Errno::AnyString', $VERSION);

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/ERRSTR_SET/;

# A value for errno that nothing else is likely to set.
sub ERRSTR_SET() { 458513437; }

our ($Errno, $init_done);
unless ($init_done) {
    # Make a new variable with $! magic
    $Errno = 1;
    Errno::AnyString::_set_errno_magic($Errno);

    # Replace $!'s magic
    Errno::AnyString::_clear_errno_magic($!);
    tie $!, __PACKAGE__;

    $init_done = 1;
}

sub TIESCALAR {
    my $class = shift;

    return bless {}, $class;
}

sub FETCH {
    my $self = shift;

    if (defined $self->{StrVal} and $Errno == ERRSTR_SET) {
        return dualvar ERRSTR_SET, $self->{StrVal};
    } else {
        return dualvar $Errno, $Errno;
    }
}

sub STORE {
    my $self = shift;

    my $numval;
    { no warnings ; $numval = 0 + $_[0] };
    if ($numval == ERRSTR_SET) {
        # Restoring a saved errno, and a custom string was set when it
        # was saved. The string should still be in the pv slot of the sv
        # used to save the errno.
        my $str = "$_[0]";
        if ($str eq ERRSTR_SET) {
            $str = "Errno::AnyString failed to restore a saved errno value";
        }
        $self->{StrVal} = $str;
        $Errno = ERRSTR_SET;
    } elsif ($_[0] =~ /^--/) {
        $self->{StrVal} = substr $_[0], 2;
        $Errno = ERRSTR_SET;
    } else {
        delete $self->{StrVal};
        $Errno = $_[0];
    }
}

sub UNTIE {
    # Put the $! magic back, rather than leave it as an untied non-magical scalar.
    Errno::AnyString::_set_errno_magic($!);
}

=head1 AUTHOR

Dave Taylor, C<< <dave.taylor.cpan at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug- at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Errno::AnyString>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Errno::AnyString

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Errno::AnyString>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Errno::AnyString>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Errno::AnyString>

=item * Search CPAN

L<http://search.cpan.org/dist/Errno::AnyString>

=back

=head1 SEE ALSO

L<Errno>, L<perltie>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Taylor, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Errno::AnyString
