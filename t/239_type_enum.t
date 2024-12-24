use Test2::V0 -no_srand => 1, '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix qw[:all];
use t::lib::helper;

# use Affix qw[/Enum/ typedef];
$|++;
#
subtest expressions => sub {

    # Taken from https://en.cppreference.com/w/c/language/enum
    isa_ok( ( typedef CPPRef => Enum [ 'A', 'B', [ C => 10 ], 'D', [ E => 1 ], 'F', [ G => 'F + C' ] ] ),
        ['Affix::Type::Enum'], 'enum Foo { A, B, C = 10, D, E = 1, F, G = F + C };' );
    is int CPPRef::A(), 0,  'A == 0';
    is int CPPRef::B(), 1,  'B == 1';
    is int CPPRef::C(), 10, 'C == 10';
    is int CPPRef::D(), 11, 'D == 11';
    is int CPPRef::E(), 1,  'E == 1';
    is int CPPRef::F(), 2,  'F == 2';
    is int CPPRef::G(), 12, 'G == 12';
};
subtest stringify => sub {
    is Enum [qw[a b c d]], q[Enum[ 'a', 'b', 'c', 'd' ]], 'simple';
    is Enum [ 'A', 'B', [ C => 10 ], 'D', [ E => 1 ], 'F', [ G => 'F + C' ] ],
        q[Enum[ 'A', 'B', [C => '10'], 'D', [E => '1'], 'F', [G => 'F + C'] ]], 'with values';
};
subtest TV => sub {
    typedef TV => Enum [ [ FOX => 11 ], [ CNN => 25 ], [ ESPN => 15 ], [ HBO => 22 ], [ NBC => 32 ] ];
    ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
enum TV { FOX = 11, CNN = 25, ESPN = 15, HBO = 22, MAX = 30, NBC = 32 };
enum TV fn(enum TV chan) { return chan == FOX ? NBC : HBO; }

    isa_ok my $fn = Affix::wrap( $lib, 'fn', [ TV() ], TV() ), [qw[Affix]], 'wrap symbol in $fn';
    is $fn->( TV::FOX() ), int TV::NBC(), 'return from $fn->(TV::FOX()) is TV::NBC()';
    is $fn->( TV::CNN() ), int TV::HBO(), 'return from $fn->(TV::CNN()) is TV::HBO()';
};
#
done_testing;
