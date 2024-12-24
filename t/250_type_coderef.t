use Test2::V0 -no_srand => 1, '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix qw[:all];
use t::lib::helper;
use Capture::Tiny qw[/capture/];
use v5.40;
$|++;
#
my $lib = compile_test_lib <<'';
#include "std.h"
// ext: .c
typedef int (*cb)(int, int);
int do_cb(cb callback, int x, int y) { return callback(x, y); }

isa_ok typedef( CB => CodeRef [ [ Int, Int ] => Int ] ), ['Affix::Type'], 'typedef int (*cb)(int, int);';
isa_ok affix( $lib, 'do_cb', [ CB(), Int, Int ], Int ),  ['Affix'],       'int do_cb(cb callback, int x, int y) ';
#
is do_cb( sub ( $x, $y ) { $x * $y }, 4, 5 ), 20, 'do_cb( sub {...}, 4, 5 )';
subtest multicall => sub {
    my $code = sub { my ( $x, $y ) = @_; $x + $y };
    is do_cb( $code, 4,   5 ), 9,  'do_cb( sub {...}, 4, 5 )';
    is do_cb( $code, 20, -5 ), 15, 'do_cb( sub {...}, 20, -5 )';
};
like warning { do_cb( 'nope', 3, 2 ) }, qr[Undefined subroutine], 'CodeRef[...] must be a defined sub ref';
#
done_testing;
