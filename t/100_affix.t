use Test2::V0 -no_srand => 1, '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix qw[:all];
use t::lib::helper;

# Run code very similar to the synopsis
# bind to exported function
isa_ok affix( libm, 'floor', [Double], Double ), ['Affix'];
is floor(3.14159), 3, 'floor( 3.14159 )';

# wrap an exported function in a code reference
# See https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/getpid?view=msvc-170
isa_ok my $getpid = wrap( libc, ( Affix::Platform::Windows() ? '_' : '' ) . 'getpid', [], Int ), ['Affix'];
is $getpid->(), $$, '$getpid->() == ' . $$;    # $$
#
subtest pin => sub {
    my ( $lib, $ver );
    #
    subtest 'setup for pin' => sub {
        ok $lib = compile_test_lib(<<''), 'build libfoo';
#include "std.h"
// ext: .c
DLLEXPORT int VERSION = 100;
DLLEXPORT int get_VERSION(){ return VERSION; }

        isa_ok affix( $lib, 'get_VERSION', [], Int ), ['Affix'];
    };

    # bind an exported value to a Perl value
    ok pin( $ver, $lib, 'VERSION', Int ), 'ping( $ver, ..., "VERSION", Int )';
    is $ver,          100, 'var pulled value from pin( ... )';
    is $ver = 2,      2,   'set var on the perl side';
    is get_VERSION(), 2,   'pin set the value in our library';
};
#
done_testing;
