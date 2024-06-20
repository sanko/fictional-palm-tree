use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;
use t::lib::helper qw[leaktest compile_test_lib leaks];
$|++;
{
    my $leaks = leaks {
        use Affix;
        pass 1, 'loaded';
        done_testing;
    };
    is $leaks->{error}, U(), 'no leaks when just loading Affix';
}
{
    my $leaks = leaks {
        use Affix;
        isa_ok $_, ['Affix::Type'], for Void, Bool, Char, UChar, Short, UShort, Int, UInt, Long, ULong, LongLong, ULongLong, Float, Double;
        done_testing;
    };
    is $leaks->{error}, U(), 'no leaks in types';
    use Data::Dump;
    diag Data::Dump::dump($leaks);
}
{
    my $leaks = leaks {
        use Affix;
        isa_ok affix( 'm', 'pow', [ Double, Double ], Double ), ['Affix'];
        is pow( 5, 2 ), 25, 'pow(5, 2)';
        done_testing;
    };
    is $leaks->{error}, U(), 'no leaks when using affix($$$$)';
    use Data::Dump;
    diag Data::Dump::dump($leaks);
}
{
    my $leaks = leaks {
        use Affix;
        isa_ok my $pow = wrap( 'm', 'pow', [ Double, Double ], Double ), ['Affix'];
        is $pow->( 5, 2 ), 25, '$pow->(5, 2)';
        done_testing;
    };
    is $leaks->{error}, U(), 'no leaks when using wrap($$$$)';
    use Data::Dump;
    diag Data::Dump::dump($leaks);
}
{
    my $leaks = leaks {
        use Affix;
        my $type = Double;
        {
            isa_ok affix( 'm', 'pow', [ $type, $type ], $type ), ['Affix'];
            is pow( 5, 2 ), 25, 'pow(5, 2)';
        }
        done_testing;
    };
    is $leaks->{error}, U(), 'type defined in higher scope';
    use Data::Dump;
    diag Data::Dump::dump($leaks);
}
done_testing;
__END__
{
    my $leaks = leaks {
        use Affix;
        my $sub = Affix::wrap( Affix::libm(), 'pow', [ x => Float, y => Float ] => Float );
    };
    is $leaks->{error}, U(), 'no leaks when binding with wrap()';
}
#
#~ my $test= 'wow';
{
    my $leaks = leaks {
        isa_ok my $ptr = Affix::malloc(1024);
        $ptr->free;
    };
    is $leaks->{error}, U(), 'no leaks when freeing pointer after malloc';
}
{
    my $leaks = leaks {
        isa_ok my $ptr = Affix::malloc(1024);
        $ptr->free;
    };
    is $leaks->{error}, U(), 'no leaks when freeing pointer after malloc';
}
#
$leaks = leaks {
    ok Void,  'Void';
    ok Bool,  'Bool';
    ok Char,  'Char';
    ok SChar, 'SChar';
    ok UChar, 'UChar';
    ok WChar, 'WChar';
    #
    ok Struct [ i => Int ],                                  'Struct[ i => Int ]';
    ok Union [ i => Int, ptr => Pointer [Int], f => Float ], 'Union [ i => Int, ptr => Pointer [Int], f => Float ]';
};
is $leaks->{error}, U(), 'no leaks in types';
#
$leaks = leaks {
    ok 1, 'fake';
    my $leak = Affix::malloc(1024);
};
is $leaks->{error}[0]->{kind},               'Leak_DefinitelyLost', 'leaked memory without freeing it after malloc';
is $leaks->{error}[0]->{xwhat}{leakedbytes}, 1024,                  '1k lost';
#
{
    {
        $leaks = leaks {
            @Affix::Typex::Int::ISA = 'Affix::Typex';
            ok my $type = Affix::Typex::Int->new( 'Int', Affix::INT_FLAG, Affix::Platform::SIZEOF_INT, Affix::Platform::ALIGNOF_INT );
            diag $type->sizeof;
            diag $type->alignment;
            diag $type->stringify;
        };
        is $leaks->{error}, U(), 'no leaks from testing type system';
    }
    #
    {
        $leaks = leaks {
            @Affix::Typex::Char::ISA = 'Affix::Typex';
            ok my $type = Affix::Typex::Char->new( 'Char', Affix::CHAR_FLAG, Affix::Platform::SIZEOF_CHAR(), Affix::Platform::ALIGNOF_CHAR );
            diag $type->stringify;
            diag $type->alignment;
            $type->pointer(1);
            diag $type->alignment;
            diag $type->stringify;
            $type->const(1);
            diag $type->sizeof;
            diag $type->alignment;
            diag $type->stringify;
        };
        is $leaks->{error}, U(), 'no leaks from testing type system (pointer, const)';
    }
}
done_testing;
exit;
