use Test2::V0 '!subtest';
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
warn("!!!rows: %d, cols: %d", rows, cols);
  // Allocate memory for the rows of pointers
  int** arr = (int**)malloc(rows * sizeof(int*));
  if (arr == NULL) {
    return NULL; // Error handling: malloc failed
  }
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
  warn("i: %d, p: %p", i, arr[i]);
    for (int j = 0; j < cols; ++j) {
      arr[i][j] = i * cols + j; 
      warn("arr[%d][%d] = %d", i, j, arr[i][j]);
    }
  }
  warn("******* %p", arr);
  DumpHex(arr, 16);
  return arr;
}

#
subtest 'affix' => sub {
    ok affix( $lib, test_1 => [Int]                                   => Void ),                              'void test_1(int)';
    ok affix( $lib, test_2 => []                                      => Int ),                               'int test_2()';
    ok affix( $lib, test_3 => [ Pointer [Int], Int ]                  => Int ),                               'int test_3(int *, int)';
    ok affix( $lib, test_4 => [ Pointer [ Pointer [Int] ], Int, Int ] => Int ),                               'int test_4(int **, int, int)';
    ok affix( $lib, test_5 => [Int]                                   => Pointer [ Int, 5 ] ),                'int * test_5(int)';
    ok affix( $lib, test_6 => [ Int, Int ]                            => Pointer [ Pointer [ Int, 5 ], 3 ] ), 'int ** test_6(int, int)';
};
like capture_stderr { test_1(100) }, qr[^ok at .+$],     'test_1(100)';
like capture_stderr { test_1(99) },  qr[^not ok at .+$], 'test_1(99)';
is test_2(),                                                        700, 'test_2()';
is test_3( [ 5 .. 10 ], 3 ),                                        8,   'test_3([5..10], 3)';
is test_4( [ [ 5 .. 10 ] ], 0, 3 ),                                 8,   'test_4([[5..10]], 0, 3)';
is test_4( [ [ 5 .. 10 ], [ 90 .. 200 ], [ 10, 11, 89 ] ], 1, 80 ), 170, 'test_4( [ [ 5 .. 10 ], [ 90 .. 200 ], [ 10, 11, 89 ] ], 1, 80)';
is test_5(5),      [ 0, 2, 4, 6, 8 ],                                                        'test_5( 5 ))';
is test_6( 5, 3 ), [ [ 0, 1, 2 ], [ 3, 4, 5 ], [ 6, 7, 8 ], [ 9, 10, 11 ], [ 12, 13, 14 ] ], 'test_6( 5, 3 ))';
use Data::Dump;

# ddx (test_6(3, 5));
done_testing;
exit;
like capture_stderr { test_2("Just random junk here\0") }, qr[^ok at .+$], 'test_2';
like capture_stderr { test_3() },                          qr[^ok at .+$], 'test_3';
#
done_testing;
