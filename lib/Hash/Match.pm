package Hash::Match;

use v5.10.0;

use strict;
use warnings;

use version 0.77; our $VERSION = version->declare('v0.1.0');

use Carp qw/ croak /;
use List::MoreUtils qw/ all any natatime /;

use namespace::autoclean;

=head1 NAME

Hash::Match - match contents of a hash against rules

=begin readme

=head1 REQUIREMENTS

This module requires Perl v5.10 or newer, and the following non-core
modules:

=over

=item L<List::MoreUtils>

=item L<namespace::autoclean>

=back

=end readme

=head1 SYNOPSIS

  use Hash::Match;

  my $m = Hash::Match->new( rules => { key => qr/ba/ } );

  $m->( { key => 'foo' } ); # returns false

  $m->( { key => 'bar' } ); # returns true

  $m->( { foo => 'bar' } ); # returns false

=head1 DESCRIPTION

TODO

=head1 METHODS

=head2 C<new>

  my $m = Hash::Match->new( rules => $rules );

Returns a function that matches a hash reference against the
C<$rules>, e.g.

  if ( $m->( \%hash ) ) { ... }

=head3 Rules

TODO

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=for readme stop

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=for readme continue

=cut

sub new {
    my ($class, %args) = @_;

    my $self = _compile_match( '-root' => $args{rules} );
    bless $self, $class;
}

sub _compile_match {
    my ( $key, $value ) = @_;

    my $code;

    if ( my $ref = ( ref $value ) ) {

        if ( $ref eq 'Regexp' ) {

            $code = sub {
                my $hash = $_[0];
                ($hash->{$key} // '') =~ $value;
            };

        } elsif ( $ref eq 'HASH' ) {

            my @codes = map { _compile_match( $_, $value->{$_} ) }
                ( keys %{$value} );

            $code = sub {
                my $hash = $_[0];
                all { $_->($hash) } @codes;
            };

        } elsif ( $ref eq 'ARRAY' ) {

            my @codes;
            my $it = natatime 2, @{$value};
            while ( my ( $k, $v ) = $it->() ) {
                push @codes, _compile_match( $k, $v );
            }

            $code = sub {
                my $hash = $_[0];
                any { $_->($hash) } @codes;
            };

        } elsif ( $ref eq 'CODE' ) {

            $code = sub {
                my $hash = $_[0];
                (exists $hash->{$key}) ? $value : 0;
            };

        } else {

            croak "Unsupported type: ${ref}";

       }

    } else {

        $code = sub {
            my $hash = $_[0];
            ($hash->{$key} // '') eq $value;
        };

    }

    return $code;
}

1;
