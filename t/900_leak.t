use Test2::V0;
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';

use t::lib::helper qw[leaktest compile_test_lib leaks];
$|++;

leaks 'use Affix' => sub {
    use Affix;
    pass 'loaded';
};
leaks 'affix($$$$)' => sub {
    isa_ok affix( 'm', 'pow', [ Double, Double ], Double ), ['Affix'],
      'double pow(double, double)';
    is pow( 5, 2 ), 25, 'pow(5, 2)';
};
leaks 'wrap($$$$)' => sub {
    isa_ok my $pow = wrap( 'm', 'pow', [ Double, Double ], Double ), ['Affix'],
      'double pow(double, double)';
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
__END__
=fdsa
{
    # my $todo = todo 'FreeBSD has trouble with vectors under valgrind'
    #   if Affix::Platform::FreeBSD();
    my $leaks = leaks {
        use Affix;
        use t::lib::helper qw[compile_test_lib];
        {
            subtest pin => sub {
                my ( $lib, $ver );
                #
                subtest 'setup for pin' => sub {
                    ok $lib =
                      t::lib::helper::compile_test_lib(<<''), 'build libfoo';
#include "std.h"
// ext: .c
int * ptr;
DLLEXPORT int * get_ptr(int size){ ptr = (int*) malloc(size * sizeof(int)); for ( int i = 0; i < size; ++i ) ptr[i] = i; return ptr; }
DLLEXPORT void free_ptr(){ free (ptr); }

                    isa_ok affix( $lib, 'get_ptr', [Int], Pointer [ Int, 5 ] ),
                      ['Affix'];
                    isa_ok affix( $lib, 'free_ptr', [], Void ), ['Affix'];
                };

                # bind an exported value to a Perl value
                ok my $ptr = get_ptr(5), '$ptr = get_ptr()';
                free_ptr();
            };
        }

        #done_testing;
    };
    is $leaks->{error}, U(), 'int *';
}

done_testing;

exit;
__END__
=fdsa
{
    # my $todo = todo 'FreeBSD has trouble with vectors under valgrind'
    #   if Affix::Platform::FreeBSD();
    my $leaks = leaks {
        use Affix;
        use t::lib::helper qw[compile_test_lib];
        {
            subtest pin => sub {
                my ( $lib, $ver );
                #
                subtest 'setup for pin' => sub {
                    ok $lib =
                      t::lib::helper::compile_test_lib(<<''), 'build libfoo';
#include "std.h"
// ext: .c
DLLEXPORT int VERSION = 100;
DLLEXPORT int get_VERSION(){ return VERSION; }

                    isa_ok affix( $lib, 'get_VERSION', [], Int ), ['Affix'];
                };

                # bind an exported value to a Perl value
                ok Affix::pin( $ver, $lib, 'VERSION', Int ),
                  'ping( $ver, ..., "VERSION", Int )';
                is $ver,          100, 'var pulled value from pin( ... )';
                is $ver = 2,      2,   'set var on the perl side';
                is get_VERSION(), 2,   'pin set the value in our library';
                Affix::unpin $ver;
            };
        }

        #done_testing;
    };
    is $leaks->{error}, U(), 'pin( ... )';
}

done_testing;

exit;
__END__
=fdsa
{
    # my $todo = todo 'FreeBSD has trouble with vectors under valgrind'
    #   if Affix::Platform::FreeBSD();
    leaks {
        use Affix;
        use t::lib::helper qw[compile_test_lib];
        my ( $lib, $ver );
        #
        subtest 'setup for pin' => sub {
            ok $lib = t::lib::helper::compile_test_lib(<<''), 'build libfoo';
#include "std.h"
// ext: .c
int * ptr(int size){ int * ret = (int*)malloc(sizeof(int) * 5); return ret;}

            isa_ok affix( $lib, 'ptr', [Int], Pointer [Void] ), ['Affix'];
        };

        # Free it manually
        isa_ok my $ptr = ptr(3), ['Affix::Pointer'];
        $ptr->free;
    };
}
=cut

leaks 'idk yet' => sub {
    use Affix;
    use t::lib::helper qw[compile_test_lib];
    ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
void test_1( void ) { warn("ok");}
void test_2( void * in ) { 
    if(memcmp(in, "Just random junk here", 22) == 0) { warn( "ok" ); }
    else{ warn ("not ok"); }
}
void * test_3( ) { warn( "ok" ); void * ret = "Testing"; return ret; }

    #
    subtest 'affix' => sub {
        ok affix( $lib, test_1 => [] => Void ), 'void test_1(void)';
        ok affix( $lib, test_2 => [ Pointer [Void] ] => Void ),
          'void test_2(void *)';
        ok affix( $lib, test_3 => [] => Pointer [Void] ), 'void * test_3(void)';
        ok affix( $lib, [ test_3 => 'test_4' ] => [] => Pointer [ Void, 3 ] ),
          'void * test_3(void)';
    };

    # test_1();
    # like capture_stderr { test_1() }, qr[^ok at .+$], 'test_1';
    # test_2("Just random junk here\0");
    my $tttt = test_3();
};

exit;
leaks 'free pointer' => sub {
    use Affix;
    use t::lib::helper qw[compile_test_lib];
    my ( $lib, $ver );
    #
    subtest 'setup for pin' => sub {
        ok $lib = t::lib::helper::compile_test_lib(<<''), 'build libfoo';
#include "std.h"
// ext: .c
int * ptr(int size){ int * ret = (int*)malloc(sizeof(int) * 5); return ret;}
bool free_ptr(int * ptr){ if(ptr==NULL) return false; free(ptr); return true; }

        isa_ok affix( $lib, 'ptr',      [Int], Pointer [Void] ),    ['Affix'];
        isa_ok affix( $lib, 'free_ptr', [ Pointer [Void] ], Bool ), ['Affix'];
    };

    # Free it manually
    isa_ok my $ptr = ptr(1024), ['Affix::Pointer'], 'ptr(1024)';
    ok free_ptr($ptr), 'free_ptr( $ptr )';
};
done_testing;
exit;

my $todo = todo 'FreeBSD has trouble with vectors under valgrind'
  if Affix::Platform::FreeBSD();
leaks callbacks => sub {
    use Affix;
    use t::lib::helper qw[compile_test_lib];
    my ( $lib, $ver );
    #
    subtest 'setup for pin' => sub {
        my $lib = compile_test_lib <<'';
#include "std.h"
// ext: .c
typedef int (*cb)(int, int);
int do_cb(cb callback, int x, int y) { return callback(x, y); }

        isa_ok typedef( CB => CodeRef [ [ Int, Int ] => Int ] ),
          ['Affix::Type'], 'typedef int (*cb)(int, int);';
        isa_ok affix( $lib, 'do_cb', [ CB(), Int, Int ], Int ), ['Affix'],
          'int do_cb(cb callback, int x, int y) ';
        #
    };
    is do_cb( sub { my ( $x, $y ) = @_; $x * $y }, 4, 5 ), 20,
      'do_cb( sub {...}, 4, 5 )';
};

my $todo = todo 'FreeBSD has trouble with vectors under valgrind'
  if Affix::Platform::FreeBSD();
leaks 'callbacks' => sub {
    use Affix;
    use t::lib::helper qw[compile_test_lib];
    my ( $lib, $ver );
    #
    subtest 'setup for pin' => sub {
        my $lib = compile_test_lib <<'';
#include "std.h"
// ext: .c
typedef int (*cb)(int, int);
int do_cb(cb callback, int x, int y) { return callback(x, y); }

        isa_ok typedef( CB => CodeRef [ [ Int, Int ] => Int ] ),
          ['Affix::Type'], 'typedef int (*cb)(int, int);';
        isa_ok affix( $lib, 'do_cb', [ CB(), Int, Int ], Int ), ['Affix'],
          'int do_cb(cb callback, int x, int y) ';
        #
    };
    my $code = sub { my ( $x, $y ) = @_; $x + $y };
    is do_cb( $code, 4,   5 ), 9,  'do_cb( sub {...}, 4, 5 )';
    is do_cb( $code, 20, -5 ), 15, 'do_cb( sub {...}, 20, -5 )';
};

leaks 'malloc/free' => sub {
    use Affix;
    use t::lib::helper qw[compile_test_lib];
    #
    subtest 'malloc' => sub {
        isa_ok my $pointer = Affix::malloc(1024), ['Affix::Pointer'],
          'malloc(1024)';
        $pointer->free;
    }
};

leaks 'malloc/DESTROY' => sub {
    use Affix;
    use t::lib::helper qw[compile_test_lib];
    #
    subtest 'malloc' => sub {
        isa_ok my $pointer = Affix::malloc(1024), ['Affix::Pointer'],
          'malloc(1024)';
    }
};

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
