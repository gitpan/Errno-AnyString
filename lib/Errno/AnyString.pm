package Errno::AnyString;
use strict;
use warnings;

=head1 NAME

Errno::AnyString - put arbitrary strings in $!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Errno qw/EIO/;
  use Errno::AnyString qw/custom_errstr/;

  $! = custom_errstr "My hovercraft is full of eels";
  print "$!\n"; # prints My hovercraft is full of eels

  my $saved_errno = $!;

  open my $fh, "<", "/no/such/file";
  print "$!\n"; # prints No such file or directory

  $! = EIO;
  print "$!\n"; # prints Input/output error

  $! = $saved_errno;
  print "$!\n"; # prints My hovercraft is full of eels


=head1 DESCRIPTION

C<Errno::AnyString> allows you to place an arbitrary error message in the special C<$!> variable, without disrupting C<$!>'s ability to pick up the result of the next system call that sets C<errno>.

It is useful if you are writing code that reports errors by setting C<$!>, and none of the standard system error messages fit.

If C<Errno::AnyString> is loaded, C<$!> behaves as normal unless a custom error string has been set with C<custom_errstr>. If a custom error string is set, it will be returned when C<$!> is evaluated as a string, and 458513437 will be returned when C<$!> is evaluated as a number, see C<ERRSTR_SET> below.

=head1 EXPORTS

Nothing is exported by default. The following are available for export.

=head2 custom_errstr ( ERROR_STRING )

Returns a value which will set the custom error string when assigned to C<$!>

=head2 ERRSTR_SET

C<ERRSTR_SET> is a numeric constant with the value 458513437. This is the value that will be obtained when C<$!> is evaluated in a numeric context while a custom error string is set.

=cut

use Exporter;
use Carp;
use Scalar::Util qw/dualvar/;

require XSLoader;
XSLoader::load('Errno::AnyString', $VERSION);

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/custom_errstr ERRSTR_SET/;

# A value for errno that nothing else is likely to set.
sub ERRSTR_SET() { 458513437; }

our ($Errno, $init_done, $dont_restore_magic_at_untie);
unless ($init_done) {
    # Make a new variable with $! magic
    $Errno = 1;
    Errno::AnyString::_set_errno_magic($Errno);

    # Replace $!'s magic
    Errno::AnyString::_clear_errno_magic($!);
    tie $!, __PACKAGE__;

    $init_done = 1;
}

sub custom_errstr ($) {
    return dualvar ERRSTR_SET, $_[0];
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
        # Either the dualvar return value of custom_errstr(), or a previously
        # saved $! value with a custom error string in its pv slot. In either
        # case, the string value holds the custom error string.
        $self->{StrVal} = "$_[0]";
        $Errno = ERRSTR_SET;
    } else {
        # A regular $!=EIO type store.
        delete $self->{StrVal};
        $Errno = $_[0];
    }
}

sub UNTIE {
    # Put the $! magic back, rather than leave it as an untied non-magical
    # scalar.

    # But whoever unties it doesn't want that, let's not.
    return if $dont_restore_magic_at_untie;

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
