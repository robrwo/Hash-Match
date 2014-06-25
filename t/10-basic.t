use Test::More;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use_ok('Hash::Match');

{
    my $m = Hash::Match->new( rules => { k => '1' } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( {} ), 'fail';

    ok $m->( { k => 1 } ),  'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
}

{
    my $m = Hash::Match->new( rules => { -not => { k => '1' } } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok $m->( { k => 2 } ),  'match';
    ok $m->( { j => 1 } ),  'match';
}

{
    my $m = Hash::Match->new( rules => { -not => { k => '1', j => 1 } } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ),  'match';
    ok $m->( { k => 2 } ),  'match';
    ok $m->( { j => 1 } ),  'match';
    ok $m->( { j => 2 } ),  'match';
    ok !$m->( { k => 1, j => 1 } ),  'fail';
}

{
    my $m = Hash::Match->new( rules => { -not => [ k => '1', j => 1 ] } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok $m->( { k => 2 } ),  'match';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { j => 2 } ),  'match';
    ok !$m->( { k => 1, j => 1 } ),  'fail';
}

{
    my $m = Hash::Match->new( rules => { k => '1', j => qr/\d/, } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
}

{
    my $m = Hash::Match->new( rules => [ k => '1', j => qr/\d/, ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
}

{
    my $m = Hash::Match->new( rules => { -or => { k => '1', j => qr/\d/, } } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
}


{
    my $m = Hash::Match->new( rules => {
        k => '1', -or => [ j => qr/\d/, i => qr/x/, ], } );
    isa_ok($m, 'Hash::Match');

    ok !$m->( { k => 1 } ), 'fail';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
    ok $m->( { k => 1, i => 'wxyz' } ),  'match';
    ok !$m->( { k => 1, i => 'abc' } ),  'fail';
}

{
    my $m = Hash::Match->new( rules => [
        k => '1', -and => { j => qr/\d/, } ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
}

{
    my $m = Hash::Match->new( rules => [
        k => '1', -and => [ j => qr/\d/, ] ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok $m->( { j => 1 } ), 'match';
    ok $m->( { k => 1, j => 3 } ),  'match';
}

{
    my $m = Hash::Match->new( rules => [
        k => '1', -and => { j => qr/\d/, i => qr/x/ } ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ), 'match';
    ok !$m->( { k => 2 } ), 'fail';
    ok !$m->( { j => 1 } ), 'fail';
    ok $m->( { k => 1, j => 3 } ),  'match';
    ok !$m->( { k => 2, i => 'xyz' } ),  'fail';
    ok $m->( { k => 2, j => 6, i => 'xyz' } ),  'match';
}

{
    my $m = Hash::Match->new( rules => { k => sub {1} } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1 } ),  'match';
    ok $m->( { k => 2 } ),  'match';
    ok !$m->( { j => 1 } ), 'fail';
}

{
    my $m = Hash::Match->new( rules => { k => '1', j => undef } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k => 1, j => undef } ),  'match';
    ok !$m->( { k => 1 } ), 'fail';
}

{
    my $m = Hash::Match->new( rules => [ qr/^k/ => 1, ] );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 2 } ),  'match';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
}

{
    my $m = Hash::Match->new( rules => { -or => [ qr/^k/ => 1, ] } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 2 } ),  'match';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
}

{
    my $m = Hash::Match->new( rules => { -and => [ qr/^k/ => 1, ] } );
    isa_ok($m, 'Hash::Match');

    ok $m->( { k_a => 1, k_b => 1 } ),  'match';
    ok !$m->( { k_a => 1, k_b => 2 } ), 'fail';
    ok !$m->( { k_a => 3, k_b => 2 } ), 'fail';
}

done_testing;
