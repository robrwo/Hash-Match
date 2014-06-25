package Hash::Match;

use v5.10.0;

use strict;
use warnings;

use version 0.77; our $VERSION = version->declare('v0.3.0');

use Carp qw/ croak /;
use List::MoreUtils qw/ natatime /;

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

This module allows you to specify complex matching rules for the
contents of a hash.

=head1 METHODS

=head2 C<new>

  my $m = Hash::Match->new( rules => $rules );

Returns a function that matches a hash reference against the
C<$rules>, e.g.

  if ( $m->( \%hash ) ) { ... }

=head3 Rules

The rules can be a hash or array reference of key-value pairs, e.g.

  {
    k_1 => 'string',    # k_1 eq 'string'
    k_2 => qr/xyz/,     # k_2 =~ qr/xyz/
    k_3 => sub { ... }, # k_3 exists and sub->($hash->{k_3}) is true
  }

For a hash reference, all keys in the rule must exist in the hash and
match the criteria specified by the rules' values.

For an array reference, at least one key must exist and match the
criteria specified in the rules.

=head4 Boolean Operators

The following special keys allow you to use nested boolean operators:

=over

=item C<-not>

  {
    -not => $subrules,
  }

Negate the C<$subrules>.

If C<$subrules> is a hash reference, that it is true when not all of
the rules match.

If C<$subrules> is an array reference, then it is true when none of
the rules match.

=item C<-and>

  [
    -and => \%subrules,
  ]

True if all of the C<%subrules> are true.

You can also use

  {
    -and => \@subrules,
  }

which is useful for cases where the keys of C<@subrules> are not
strings, e.g. regular expressions.

=item C<-or>

  {
    -or => \@subrules,
  }

True if at least one of the C<@subrules> is true.

=back

=head4 Regular Expressions for Keys

You can use regular expressions for matching keys. For example,

  -or => [
    qr/xyz/ => $rule,
  ]

will match if there is any key that matches the regular expression has
a corresponding value which matches the C<$rule>.

You can also use

  -and => [
    qr/xyz/ => $rule,
  ]

to match if all keys that match the regular expression have
corresponding values which match the C<$rule>.

Note that you cannot use regular expressions as hash keys in Perl. So
the following I<will not> work:

  {
    qr/xyz/ => $rule,
  }

=cut

sub new {
    my ($class, %args) = @_;

    if (my $rules = $args{rules}) {

        my $root = ((ref $rules) eq 'HASH') ? '-and' : '-or';
        my $self = _compile_rule( $root => $args{rules}, $class );
        bless $self, $class;

    } else {

        croak "Missing 'rules' attribute";

    }
}

sub _compile_match {
    my ($value) = @_;

    if ( my $match_ref = ( ref $value ) ) {

        return sub { ($_[0] // '') =~ $value } if ( $match_ref eq 'Regexp' );


        return sub { $value->($_[0]) } if ( $match_ref eq 'CODE' );

        croak "Unsupported type: ${match_ref}";

    } else {

        return sub { ($_[0] // '') eq $value } if (defined $value);

        return sub { !defined $_[0] };

    }
}

sub _compile_rule {
    my ( $key, $value, $ctx ) = @_;

    if ( my $key_ref = ( ref $key ) ) {

        if ( $key_ref eq 'Regexp' ) {

            my $n  = ($ctx eq 'HASH') ? 'all' : 'any';
            my $fn = List::MoreUtils->can($n);

            my $match = _compile_match($value);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $match->( $hash->{$_} ) },
                       grep { $key_ref } (keys %{$hash}) );
            };

        } else {

            croak "Unsupported key type: '${key_ref}'";

        }

    } else {

        my $match_ref = ref $value;

        if ( $match_ref eq 'HASH' ) {

            my @codes = map { _compile_rule( $_, $value->{$_}, $match_ref ) }
            ( keys %{$value} );

            my $n  = ($key eq '-not') ? 'notall' : ($key eq '-or') ? 'any' : 'all';
            my $fn = List::MoreUtils->can($n);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $_->($hash) }, @codes );
            };

        } elsif ( $match_ref eq 'ARRAY' ) {

            my @codes;
            my $ref = ($key eq '-and') ? 'HASH' : $match_ref;
            my $it = natatime 2, @{$value};
            while ( my ( $k, $v ) = $it->() ) {
                push @codes, _compile_rule( $k, $v, $ref );
            }

            my $n  = ($key eq '-not') ? 'none' : ($key eq '-and') ? 'all' : 'any';
            my $fn = List::MoreUtils->can($n);

            return sub {
                my $hash = $_[0];
                $fn->( sub { $_->($hash) }, @codes );
            };

        } elsif ( $match_ref =~ /^(?:Regexp|CODE|)$/ ) {

            my $match = _compile_match($value);

            return sub {
                my $hash = $_[0];
                (exists $hash->{$key}) ? $match->($hash->{$key}) : 0;
            };

        } else {

            croak "Unsupported type: ${match_ref}";

        }

    }

    croak "Unhandled condition";
}

1;

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

