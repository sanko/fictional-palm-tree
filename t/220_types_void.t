use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;    # :default
use t::lib::helper;
#
isa_ok Void, ['Affix::Type'];

#isa_ok Pointer[Void], ['Affix::Type'];
#
done_testing;
