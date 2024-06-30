use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[Pointer Int wrap :pin];
BEGIN { chdir '../' if !-d 't'; }
use t::lib::helper;
$|++;
imported_ok qw[pin unpin];
subtest Int => sub {
    ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
extern int var;
int var = 100;
int verify(){ return var; }

    ok my $verify = wrap( $lib, 'verify', [] => Int ), 'wrap( ..., "verify", ... )';
    ok pin( my $var, $lib, 'var', Int ),               'pin( my $var, ... )';
    is $var, 100, '$var == 100';
    subtest 200 => sub {
        is $var = 200,  200, '$var = 200';
        is $var,        200, '$var == 200';
        is $verify->(), 200, '$verify->() == 200';
    };
    subtest 120 => sub {
        is $var = 120,  120, '$var = 120';
        is $var,        120, '$var == 120';
        is $verify->(), 120, '$verify->() == 120';
    };
    subtest unpin => sub {
        ok unpin($var), 'unpin( ... )';
        is $var = 300,  300, '$var = 300';
        is $var,        300, '$var == 300';
        is $verify->(), 120, '$verify->() == 120 (still)';
    }
};
done_testing;
