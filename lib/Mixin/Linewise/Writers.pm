use strict;
use warnings;
package Mixin::Linewise::Writers;
# ABSTRACT: get linewise writers for strings and filenames

use Carp ();
use IO::File;
use IO::String;

use Sub::Exporter -setup => {
  exports => { map {; "write_$_" => \"_mk_write_$_" } qw(file string) },
  groups  => {
    default => [ qw(write_file write_string) ],
    writers => [ qw(write_file write_string) ],
  },
};

=head1 SYNOPSIS

  package Your::Pkg;
  use Mixin::Linewise::Writers -writers;

  sub write_handle {
    my ($self, $data, $handle) = @_;

    $handle->print("datum: $_\n") for @$data;
  }

Then:

  use Your::Pkg;

  Your::Pkg->write_file($data, $filename);

  Your::Pkg->write_string($data, $string);

  Your::Pkg->write_handle($data, $fh);

=head1 EXPORTS

C<write_file> and C<write_string> are exported by default.  Either can be
requested individually, or renamed.  They are generated by
L<Sub::Exporter|Sub::Exporter>, so consult its documentation for more
information.

Both can be generated with the option "method" which requests that a method
other than "write_handle" is called with the created IO::Handle.

If given an "encoding" option, any C<write_file> type functions will use
that as an IO layer, otherwise, the default is C<encoding(UTF-8)>.

  use Mixin::Linewise::Writers -writers => { encoding => "raw" };
  use Mixin::Linewise::Writers -writers => { encoding => "encoding(iso-8859-1)" };

=head2 write_file

  Your::Pkg->write_file($data, $filename);
  Your::Pkg->write_file($data, $options, $filename);

This method will try to open a new file with the given name.  It will then call
C<write_handle> with that handle.

An optional hash reference may be passed before C<$filename> with options.
The only valid option currently is C<encoding>, which overrides any
default set from C<use> or the built-in C<encoding(UTF-8)>.

Any arguments after C<$filename> are passed along after to C<write_handle>.

=cut

sub _mk_write_file {
  my ($self, $name, $arg) = @_;
  my $method = defined $arg->{method} ? $arg->{method} : 'write_handle';
  my $dflt_enc = defined $arg->{encoding} ? $arg->{encoding} : 'encoding(UTF-8)';

  sub {
    my ($invocant, $data, $options, $filename);
    if ( ref $_[2] eq 'HASH' ) {
      # got options before filename
      ($invocant, $data, $options, $filename) = splice @_, 0, 4;
    }
    else {
      ($invocant, $data, $filename) = splice @_, 0, 3;
    }

    $options->{encoding} = $dflt_enc unless defined $options->{encoding};
    $options->{encoding} =~ s/^://; # we add it later

    # Check the file
    Carp::croak "no filename specified"           unless $filename;
    Carp::croak "'$filename' is not a plain file" if -e $filename && ! -f _;

    # Write out the file
    my $handle = IO::File->new($filename, ">:$options->{encoding}")
      or Carp::croak "couldn't write to file '$filename': $!";

    $invocant->write_handle($data, $handle, @_);
  }
}

=head2 write_string

  my $string = Your::Pkg->write_string($data);

C<write_string> will create a new IO::String handle, call C<write_handle> to
write to that handle, and return the resulting string.

Any arguments after C<$data> are passed along after to C<write_handle>.

=cut

sub _mk_write_string {
  my ($self, $name, $arg) = @_;
  my $method = defined $arg->{method} ? $arg->{method} : 'write_handle';

  sub {
    my ($invocant, $data) = splice @_, 0, 2;

    my $string = '';
    my $handle = IO::String->new($string);

    $invocant->write_handle($data, $handle, @_);

    return $string;
  }
}

1;
