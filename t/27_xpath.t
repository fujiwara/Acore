# -*- mode:perl -*-
use Test::More;
use strict;
use warnings;

BEGIN {
    use_ok('Acore::Document');
}

my $hash = {
    scalar => 'scalar_value',
    array  => [ qw( array_value0 array_value1 array_value2 array_value3) ],
    hash   => {
        hash1 => 'hash_value1',
        hash2 => 'hash_value2'
    },
    complex => {
        level2 => [
            {
                level3_0 => [
                    'level4_0', { level4_1 => { level5 => 'huhu' } },
                    'level4_2'
                ]
            }
        ]
    },
};

my $a = Acore::Document->new($hash);

ok($a);

my $v = '';

$v = $a->get('/scalar');
ok( $v eq 'scalar_value', " value=$v" );

$v = $a->get('/array[0]');
ok( $v eq 'array_value0', " value=$v" );

$v = $a->get('/hash/hash1');
ok( $v eq 'hash_value1', " value=$v" );

$v = $a->get('/complex/level2[0]/level3_0[0]');
ok( $v eq 'level4_0', " value=$v" );

$v = $a->get('/complex/level2[0]/level3_0[2]');
ok( $v eq 'level4_2', " value=$v" );

$v = $a->get('/complex/level2[0]/level3_0[1]/level4_1/level5');
ok( $v eq 'huhu', " value=$v" );

$v = $a->get('/complex/level2[0]/level3_0[1]/level4_1/level5_not_exists')
  || 'UNDEF';
ok( $v eq 'UNDEF', " value=$v" );

$v = $a->get('/complex/level2[0]/level3_0[99]') || 'UNDEF';
ok( $v eq 'UNDEF', " value=$v" );

$v = $a->get('/complex/level2[0]/level3_0[2]') || 'UNDEF';
ok( $v eq 'level4_2', " value=$v" );

done_testing;
