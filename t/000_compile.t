use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;    # :default
use t::lib::helper;
#
diag $Affix::VERSION;
#
imported_ok qw[affix wrap];
imported_ok qw[Void Bool Char UChar Short UShort Int UInt Long ULong LongLong ULongLong Size_t Float Double];
not_imported_ok qw[set_destruct_level];
#
done_testing;
