use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use t::lib::helper;

# Run code very close to the synopsis
use Affix qw[:all];

# bind to exported function
isa_ok affix( libm, 'floor', [Double], Double ), ['Affix'];
is floor(3.14159), 3, 'floor( 3.14159 )';

# wrap an exported function in a code reference
# See https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/getpid?view=msvc-170
isa_ok my $getpid = wrap( libc, ( Affix::Platform::Windows() ? '_' : '' ) . 'getpid', [], Int ), ['Affix'];
is $getpid->(), $$, '$getpid->() == ' . $$;    # $$

# bind an exported value to a Perl value
# pin( my $ver, 'libfoo', 'VERSION', Int );
#
done_testing;
