use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;    # :default
use t::lib::helper;
#
isa_ok my $pow = wrap( 'm', 'pow', [ Double, Double ] => Double ), ['Affix'];
is $pow->( 5, 2 ), 25, '$pow->(5, 2)';
#
done_testing;
