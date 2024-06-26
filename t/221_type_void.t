use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;    # :default
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
void test_2( void * in ) { warn( "ok" ); warn("%s",(char *) in);}
void * test_3( ) { warn( "ok" ); }

#
subtest 'affix' => sub {
    ok affix( $lib, test_1 => []                 => Void ),           'void test_1(void)';
    ok affix( $lib, test_2 => [ Pointer [Void] ] => Void ),           'void test_2(void *)';
    ok affix( $lib, test_3 => []                 => Pointer [Void] ), 'void * test_3(void)';
};
test_1();
like capture_stderr { test_1() }, qr[^ok at .+$], 'test_1';
test_2("Just random junk here\0");
done_testing;
exit;
like capture_stderr { test_2("Just random junk here\0") }, qr[^ok at .+$], 'test_2';
like capture_stderr { test_3() },                          qr[^ok at .+$], 'test_3';
#
done_testing;
