use Test2::V0;
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use t::lib::helper qw[leaktest compile_test_lib leaks];
$|++;
skip_all 'I have no idea why *BSD is leaking here' if Affix::Platform::OS() =~ /BSD/;
leaks 'use Affix' => sub {
    use Affix;
    pass 'loaded';
};
leaks 'affix($$$$)' => sub {
    isa_ok affix( 'm', 'pow', [ Double, Double ], Double ), ['Affix'], 'double pow(double, double)';
    is pow( 5, 2 ), 25, 'pow(5, 2)';
};
leaks 'wrap($$$$)' => sub {
    isa_ok my $pow = wrap( 'm', 'pow', [ Double, Double ], Double ), ['Affix'], 'double pow(double, double)';
    is $pow->( 5, 2 ), 25, '$pow->(5, 2)';
};
leaks 'return pointer' => sub {
    ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
void * test( ) { void * ret = "Testing"; return ret; }

    ok affix( $lib, 'test', [] => Pointer [Void] ), 'void * test(void)';
    isa_ok my $string = test(), ['Affix::Pointer'], 'test()';
    is $string->raw(7), 'Testing', '->raw(7)';
};
leaks 'return malloc\'d pointer' => sub {
    ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
void * test() {
  void * ret = malloc(8);
  if ( ret == NULL ) { warn("Memory allocation failed!"); }
  else { strcpy(ret, "Testing"); }
  return ret;
}

    ok affix( $lib, 'test', [] => Pointer [Void] ), 'void * test(void)';
    isa_ok my $string = test(), ['Affix::Pointer'], 'test()';
    is $string->raw(7), 'Testing', '->raw(7)';
    $string->free;
    is $string, U(), '->free() worked';
};
done_testing;
exit;
