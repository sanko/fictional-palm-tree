use Test2::V0 '!subtest', 'array';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix         qw[:all];
use Capture::Tiny qw[/capture/];
use t::lib::helper;
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
is do_cb( sub { my ( $x, $y ) = @_; $x * $y }, 4, 5 ), 20, 'do_cb( sub {...}, 4, 5 )';
subtest multicall => sub {
    my $code = sub { my ( $x, $y ) = @_; $x + $y };
    is do_cb( $code, 4,   5 ), 9,  'do_cb( sub {...}, 4, 5 )';
    is do_cb( $code, 20, -5 ), 15, 'do_cb( sub {...}, 20, -5 )';
};
like dies { do_cb( 'nope', 3, 2 ) }, qr[Type of arg 1 .+ must be subroutine], 'CodeRef[...] must be a CODE ref';
#
done_testing;
