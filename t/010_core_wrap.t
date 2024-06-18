use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;    # :default
use t::lib::helper;
#
diag $Affix::VERSION;
#
isa_ok wrap( 'm', 'pow', [ Float, Float ] => Float ), ['Affix'];
#
done_testing;
