use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix         qw[:all];
use Capture::Tiny qw[/capture/];
use t::lib::helper;
$|++;
#
isa_ok Void,           ['Affix::Type'];
isa_ok Pointer [Void], ['Affix::Type'];
#
ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
void test_1( void ) { warn("ok");}
void test_2( void * in ) { 
    if(memcmp(in, "Just random junk here", 22) == 0) { warn( "ok" ); }
    else{ warn ("not ok"); }
}
void * test_3( ) { warn( "ok" ); void * ret = "Testing"; return ret; }

#
subtest 'affix' => sub {
    ok affix( $lib, test_1                 => []                 => Void ),                'void test_1(void)';
    ok affix( $lib, test_2                 => [ Pointer [Void] ] => Void ),                'void test_2(void *)';
    ok affix( $lib, test_3                 => []                 => Pointer [Void] ),      'void * test_3(void)';
    ok affix( $lib, [ test_3 => 'test_4' ] => []                 => Pointer [ Void, 3 ] ), 'void * test_3(void)';
};
test_1();
like capture_stderr { test_1() }, qr[^ok at .+$], 'test_1';
test_2("Just random junk here\0");
warn test_3();
warn test_4();
done_testing;
exit;
like capture_stderr { test_2("Just random junk here\0") }, qr[^ok at .+$], 'test_2';
like capture_stderr { test_3() },                          qr[^ok at .+$], 'test_3';
#
done_testing;
