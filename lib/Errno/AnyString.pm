package Errno::AnyString;
use strict;
use warnings;

=head1 NAME

Errno::AnyString - put arbitrary strings in $!

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

C<Errno::AnyString> allows you to place an arbitrary error message in the special C<$!> variable, without disrupting C<$!>'s ability to pick up the result of the next system call that sets C<errno>.

It is useful if you are writing code that reports errors by setting C<$!>, and none of the standard system error messages fit.

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

If C<Errno::AnyString> is loaded, C<$!> behaves as normal unless a custom error string has been set with C<custom_errstr>. If a custom error string is set, it will be returned when C<$!> is evaluated as a string, and 458513437 will be returned when C<$!> is evaluated as a number, see C<ERRSTR_SET> below.

=head1 EXPORTS

Nothing is exported by default. The following are available for export.

=head2 custom_errstr ( ERROR_STRING )

Returns a value which will set the custom error string when assigned to C<$!>

=head2 ERRSTR_SET

C<ERRSTR_SET> is a numeric constant with the value 458513437. This is the value that will be obtained when C<$!> is evaluated in a numeric context while a custom error string is set.

=head1 INTERNALS

=head2 BACKGROUND

Perl scalars can hold both a string and a number, at the same time. Normally these are different representations of the same thing, for example a scalar might have 123 in its number slot and "123" in its string slot. However, it is possible to put completely unrelated things in the string and number slots of a scalar. L<Scalar::Util/dualvar> allows you to do this from within Perl code:

  use Scalar::Util qw/dualvar/;

  my $foo = dualvar 10, "Hello";
  print "$foo\n";               # prints Hello
  print 0+$foo, "\n";           # prints 10

  # The dual values are preserved when scalars are copied around:
  my $bar = $foo;
  my %hash = ( foo => $bar );
  my @array = ( $hash{foo} );
  print "$array[0]\n";          # prints Hello
  print 0+$array[0], "\n";      # prints 10

At the C level, there is a global integer variable called C<errno>, the "error number". Many library functions set this value when they fail, to indicate what went wrong. There is a library function to translate C<errno> values into error message strings such as C<No such file or directory>, C<Permission denied>, etc. Perl's special C<$!> variable gives access to C<errno> from within Perl code. It uses the dual value property of scalars to return both the C<errno> value and the corresponding error message. For example:

  open my $fh, "<", "/there/is/no/such/file" or die "open: $!";

Here Perl calls a C library function to try to open the file. Within the C library, the operation fails and C<errno> is set to the value that indicates no such file or directory (2 on my system). The library function returns a value that indicates failure, which causes Perl's open() to return false. The code above then reads the C<$!> variable. The read triggers some magic, which copies C<errno> into C<$!>'s number slot , looks up the error message for error number 2, and sets C<$!>'s string value to "No such file or directory". The value of C<$!> is then used in a string, so the number value of 2 is ignored and the string value of "No such file or directory" is incorporated into the die message.

Perl also allows you to assign a number to C<$!>, to set C<errno>:

  $! = 2;

This code stores a value in C<$!>, which triggers some magic that converts the value to an integer if necessary and then copies the value to C<errno>. Since C<errno> is an integer, you can't put an error message of your own into C<$!>. If you try, Perl will convert your message string to an integer as best it can, and store that in C<errno>.

  $! = "You broke it";
  # gives an "Argument isn't numeric" warning and sets errno to 0

See L<perlvar/ERRNO>.

=head2 DESIGN GOALS

This module makes a global change to Perl's behavior when it is loaded, by interfering with the magical properties of C<$!>. The primary design goal is compatibility. Any code that works without C<Errno::AnyString> loaded should work just the same with C<Errno::AnyString> loaded. Module authors should be able to be confident that pulling in C<Errno::AnyString> to allow them to put arbitrary strings in C<$!> is very unlikely to break anything that might ever be used in conjunction with their module.

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

sub TIESCALAR {
    my $class = shift;

    return bless {}, $class;
}

sub UNTIE {}

=head2 IMPLEMENTATION

This module works by removing Perl's magic from C<$!>, and making it into a tied scalar. The magic that would normally be on C<$!> is put on another variable, which the tied scalar uses to access C<errno>.

=cut

our ($Errno, $_init_done);

unless ($_init_done) {
    # Make a new variable with $! magic
    Errno::AnyString::_set_errno_magic($Errno);

    unless ($Errno::AnyString::do_not_init) {
        # Replace $!'s magic
        Errno::AnyString::_clear_errno_magic($!);
        tie $!, __PACKAGE__;
    }

    $_init_done = 1;
}

=pod

When a scalar is assigned to the tied C<$!>, its numeric value is inspected. If it's equal to ERRSTR_SET then the string value is stashed away as the custom error string, replacing any previous custom error string. In any case, C<errno> is set to the numeric value of the scalar.

=cut

sub STORE {
    my $self = shift;

    my $numval;
    { no warnings ; $numval = 0 + $_[0] };
    if ($numval == ERRSTR_SET) {
        if ($_[0] eq ERRSTR_SET and defined $self->{StrVal}) {
            # ERRSTR_SET in both string and number contexts, and a custom
            # error string has previously been set. This is probably a saved
            # errno value that has been held in numeric-only storage, causing
            # the custom error string to be lost. The best I can do is to
            # re-activate the most recently set custom error string by
            # leaving $self->{StrVal} as it is.
        } else {
            # Either the dualvar return value of custom_errstr(), or a previously
            # saved $! value with a custom error string in its pv slot. In either
            # case, the string value holds the custom error string.
            $self->{StrVal} = "$_[0]";
        }
    }
    $Errno = $_[0];
}

=pod

The custom_errstr() function returns a scalar with ERRSTR_SET in the number slot and the specified error message in the string slot. Hence assigning the return value of custom_errstr() to C<$!> sets C<errno> to ERRSTR_SET and overwrites the stashed custom error string.

=cut

sub custom_errstr ($) {
    return dualvar ERRSTR_SET, $_[0];
}

=pod

This mechanism for setting the custom error string was chosen because it works correctly with code that saves and later restores the value of C<$!>.

  my $saved_errno = $!;
  do_other_things();
  $! = $saved_errno;

This code works as expected under C<Errno::AnyString>, even if a custom error string is set, and even if code called from do_other_things() sets other custom error strings. The first line saves both the numeric C<errno> value and the error string (which will be either one of the standard system error message or a custom error string) in C<$saved_errno>. The final line restores the saved C<errno> value, and if that value is ERRSTR_SET it also restores the stashed custom error string.

=pod

When the tied C<$!> is read, the numeric value of the returned scalar is fetched from C<errno>. If it's equal to ERRSTR_SET then the stashed custom error string is returned in the string slot, otherwise the system error message corresponding to C<errno> is returned.

=cut

sub FETCH {
    my $self = shift;

    if (defined $self->{StrVal} and $Errno == ERRSTR_SET) {
        return dualvar ERRSTR_SET, $self->{StrVal};
    } else {
        return dualvar $Errno, $Errno;
    }
}

=pod

=head2 INTER-OPERATION

Other modules that make changes to the way C<$!> works should use the following methods only to interact with C<Errno::AnyString>. These should always work, even if the underlying mechanism changes.

To undo the changes to C<$!> if they are already in place (and to prevent the changes if C<Errno::AnyString> is loaded later):

  $Errno::AnyString::do_not_init = 1;
  if (exists &Errno::AnyString::go_away) {
      &Errno::AnyString::go_away;
  }

=cut

sub go_away {
    if ($_init_done) {
        if (tied $! and ref tied $! eq __PACKAGE__) {
            untie $!;
            Errno::AnyString::_set_errno_magic($!);
        }
    }
    $Errno::AnyString::do_not_init = 1;
}

=pod

If you disable C<Errno::AnyString> in this way, you become responsible for ensuring that the right thing happens when an SV holding a C<Errno::AnyString> custom error string is assigned to C<$!>. A custom error string SV will have the numeric value 458513437, and its string value will hold the error string.

If C<Errno::AnyString> has been loaded, then a reference to the equivalent of the normal Perl C<$!> will be returned by C<&Errno::AnyString::real_errno>. To get a reference to the normal C<$!> whether or not C<Errno::AnyString> is loaded:

  my $eref = exists &Errno::AnyString::real_errno ? &Errno::AnyString::real_errno : \$!;

=cut

sub real_errno {
    return \$Errno;
}

=head1 AUTHOR

Dave Taylor, C<< <dave.taylor.cpan at gmail.com> >>

=head1 BUGS AND LIMITATIONS

=head2 C LEVEL STRERROR CALLS

If C level code attempts to get a textual error message based on C<errno> while a custom error string is set, it will get something like the following, depending on the platform:

  Unknown error 458513437

=head2 PURE NUMERIC RESTORE

If the string part of a saved C<$!> value is lost, then restoring that value to C<$!> restores the most recently set custom error string, which is not necessarily the custom error string that was set when the C<$!> value was saved.

  $! = custom_errstr "String 1";
  my $saved_errno = 0 + $!;

  $! = custom_errstr "String 2";

  $! = $saved_errno;
  print "$!\n"; # prints String 2

Note that the Perl code that saved the error number had to go out of its way to discard the string part of C<$!>, so I think this combination is fairly unlikely in practice.

=head2 OTHER BUGS

Please report any other bugs or feature requests to C<bug-errno-anystring at rt.cpan.org>, or through
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

L<Errno>, L<perlvar/ERRNO>, L<Scalar::Util>, L<perlguts>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Taylor, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Errno::AnyString
