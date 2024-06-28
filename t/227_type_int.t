use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;    # :default
use Capture::Tiny qw[/capture/];
use t::lib::helper;
$|++;
#
isa_ok Int,           ['Affix::Type'];
isa_ok Pointer [Int], ['Affix::Type'];
#
ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
void test_1( int i ) { if (i == 100){ warn("ok"); }else {warn("not ok");}}
int test_2( ) {return 700;}
int test_3( int * in, int x ) { return in[x];}
int test_4( int ** in, int x, int y ) { warn("CALLED"); warn("in[%d][%d]", x, y);DumpHex(in, 32); return in[x][y];}
void * test_5( ) { warn( "ok" ); }

#
subtest 'affix' => sub {
    ok affix( $lib, test_1 => [Int]                                   => Void ), 'void test_1(int)';
    ok affix( $lib, test_2 => []                                      => Int ),  'int test_2()';
    ok affix( $lib, test_3 => [ Pointer [Int], Int ]                  => Int ),  'int test_3(int *, int)';
    ok affix( $lib, test_4 => [ Pointer [ Pointer [Int] ], Int, Int ] => Int ),  'int test_4(int **, int, int)';
    # ok affix( $lib, test_5 => []                 => Pointer [Void] ), 'void * test_4(void)';
};
like capture_stderr { test_1(100) }, qr[^ok at .+$],     'test_1(100)';
like capture_stderr { test_1(99) },  qr[^not ok at .+$], 'test_1(99)';
is test_2(),                                                        700, 'test_2()';
is test_3( [ 5 .. 10 ], 3 ),                                        8,   'test_3([5..10], 3)';
is test_4( [ [ 5 .. 10 ] ], 0, 3 ),                                 8,   'test_4([[5..10]], 0, 3)';
is test_4( [ [ 5 .. 10 ], [ 90 .. 200 ], [ 10, 11, 89 ] ], 1, 80 ), 170, 'test_4( [ [ 5 .. 10 ], [ 90 .. 200 ], [ 10, 11, 89 ] ], 1, 80)';
done_testing;
exit;
like capture_stderr { test_2("Just random junk here\0") }, qr[^ok at .+$], 'test_2';
like capture_stderr { test_3() },                          qr[^ok at .+$], 'test_3';
#
done_testing;
