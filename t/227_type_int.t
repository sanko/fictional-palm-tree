use Test2::V0 '!subtest', 'array';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix;    # :default
use Capture::Tiny qw[/capture/];
use t::lib::helper;
$|++;
#
isa_ok Int,           ['Affix::Type'];
isa_ok Pointer [Int], ['Affix::Type'];
#
ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
void test_1( int i ) { if (i == 100){ warn("ok"); }else {warn("not ok");}}
int test_2( ) {return 700;}
int test_3( int * in, int x ) { return in[x];}
int test_4( int ** in, int x, int y ) { return in[x][y]; }
int * test_5( int size ) { 
    int* ret = (int*)malloc(size * sizeof(int));
    if (ret != NULL)
    for (int i = 0; i < size; ++i) 
        ret[i] = i * 2;
  return ret;
}
int ** test_6( int rows, int cols){
  // Allocate memory for the rows of pointers
  int** arr = (int**)malloc(rows * sizeof(int*));
  if (arr == NULL) 
    return NULL; // Error handling: malloc failed
  // Allocate memory for each row (inner array)
  for (int i = 0; i < rows; ++i) {
    arr[i] = (int*)malloc(cols * sizeof(int));
    if (arr[i] == NULL) {
      // Free already allocated rows to avoid memory leak
      for (int j = 0; j < i; ++j) {
        free(arr[j]);
      }
      free(arr);
      return NULL; // Error handling: malloc failed
    }
  }
  // Initialize all elements of the array
  for (int i = 0; i < rows; ++i) {
    for (int j = 0; j < cols; ++j) {
      arr[i][j] = i * cols + j; 
    }
  }
  return arr;
}

{
    my ( $lib, $ver );
    #
    subtest 'setup for pin' => sub {
        ok $lib = t::lib::helper::compile_test_lib(<<''), 'build libfoo';
#include "std.h"
// ext: .c
DLLEXPORT int * get_ptr(int size){ int*ptr = (int*) malloc(size * sizeof(int)); for ( int i = 0; i < size; ++i ) ptr[i] = i; return ptr; }
DLLEXPORT bool free_ptr(int * ptr){ free( ptr ); return 1; }

        isa_ok affix( $lib, 'get_ptr',  [Int],                  Pointer [ Int, 5 ] ), ['Affix'];
        isa_ok affix( $lib, 'free_ptr', [ Pointer [ Int, 5 ] ], Bool ),               ['Affix'];
    };

    # bind an exported value to a Perl value
    ok my $ptr = get_ptr(5), '$ptr = get_ptr()';

    # ok free_ptr($ptr), 'free_ptr($ptr)';
}
{
    my ( $lib, $ver );
    #
    subtest 'setup for pin' => sub {
        ok $lib = t::lib::helper::compile_test_lib(<<''), 'build libfoo';
#include "std.h"
// ext: .c
int * ptr(int size){ int * ret = (int*)malloc(sizeof(int) * 5); return ret;}
bool free_ptr(int * ptr){ if(ptr==NULL) return false; free(ptr); return true; }

        isa_ok affix( $lib, 'ptr',      [Int],             Pointer [Void] ), ['Affix'];
        isa_ok affix( $lib, 'free_ptr', [ Pointer [Int] ], Bool ),           ['Affix'];
    };

    # Free it manually
    isa_ok my $ptr = ptr(5), ['Affix::Pointer'];
    ok free_ptr($ptr), 'free_ptr( $ptr )';
};
#
subtest 'affix' => sub {
    ok affix( $lib, test_1 => [Int]                                   => Void ),                              'void test_1(int)';
    ok affix( $lib, test_2 => []                                      => Int ),                               'int test_2()';
    ok affix( $lib, test_3 => [ Pointer [Int], Int ]                  => Int ),                               'int test_3(int *, int)';
    ok affix( $lib, test_4 => [ Pointer [ Pointer [Int] ], Int, Int ] => Int ),                               'int test_4(int **, int, int)';
    ok affix( $lib, test_5 => [Int]                                   => Pointer [ Int, 5 ] ),                'int * test_5(int)';
    ok affix( $lib, test_6 => [ Int, Int ]                            => Pointer [ Pointer [ Int, 3 ], 5 ] ), 'int ** test_6(int, int)';
    ok affix( $lib, [ test_6 => 'test_7' ] => [ Int, Int ]            => Pointer [ Pointer [Int], 3 ] ),      'int ** test_7(int, int)';
    ok affix( $lib, [ test_6 => 'test_8' ] => [ Int, Int ]            => Pointer [ Pointer [Int] ] ),         'int ** test_8(int, int)';
};
like capture_stderr { test_1(100) }, qr[^ok at .+$],     'test_1(100)';
like capture_stderr { test_1(99) },  qr[^not ok at .+$], 'test_1(99)';
is test_2(),                                                        700, 'test_2()';
is test_3( [ 5 .. 10 ], 3 ),                                        8,   'test_3([5..10], 3)';
is test_4( [ [ 5 .. 10 ] ], 0, 3 ),                                 8,   'test_4([[5..10]], 0, 3)';
is test_4( [ [ 5 .. 10 ], [ 90 .. 200 ], [ 10, 11, 89 ] ], 1, 80 ), 170, 'test_4( [ [ 5 .. 10 ], [ 90 .. 200 ], [ 10, 11, 89 ] ], 1, 80)';
is test_5(5),      [ 0, 2, 4, 6, 8 ],                                                        'test_5( 5 ))';
is test_6( 5, 3 ), [ [ 0, 1, 2 ], [ 3, 4, 5 ], [ 6, 7, 8 ], [ 9, 10, 11 ], [ 12, 13, 14 ] ], 'test_6( 5, 3 ))';
like test_7( 5, 3 ), array {
    item check_isa 'Affix::Pointer';
    item check_isa 'Affix::Pointer';
    item check_isa 'Affix::Pointer';
    end();
}, 'test_7(5, 3)';
isa_ok test_8( 5, 3 ), ['Affix::Pointer'], 'test_8(5, 3)';
#
done_testing;
