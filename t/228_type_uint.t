use Test2::V0 '!subtest', 'array';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix         qw[:all];
use Capture::Tiny qw[/capture/];
use t::lib::helper;
$|++;
#
isa_ok UInt,           ['Affix::Type'];
isa_ok Pointer [UInt], ['Affix::Type'];
#
ok my $lib = compile_test_lib(<<''), 'build test lib';
#include "std.h"
// ext: .c
void test_1( unsigned int i ) { if (i == 100){ warn("ok"); }else {warn("not ok");}}
unsigned int test_2( ) {return 700;}
unsigned int test_3( unsigned int * in, unsigned int x ) { return in[x];}
unsigned int test_4( unsigned int ** in, unsigned int x, int y ) { return in[x][y]; }
unsigned int * test_5( unsigned int size ) { 
    unsigned int* ret = (unsigned int*)malloc(size * sizeof(unsigned int));
    if (ret != NULL)
    for (unsigned int i = 0; i < size; ++i) 
        ret[i] = i * 2;
  return ret;
}
unsigned int ** test_6( unsigned int rows, unsigned int cols){
  // Allocate memory for the rows of pointers
  unsigned int** arr = (unsigned int**)malloc(rows * sizeof(unsigned int*));
  if (arr == NULL) 
    return NULL; // Error handling: malloc failed
  // Allocate memory for each row (inner array)
  for (unsigned int i = 0; i < rows; ++i) {
    arr[i] = (unsigned int*)malloc(cols * sizeof(unsigned int));
    if (arr[i] == NULL) {
      // Free already allocated rows to avoid memory leak
      for (unsigned int j = 0; j < i; ++j) {
        free(arr[j]);
      }
      free(arr);
      return NULL; // Error handling: malloc failed
    }
  }
  // Initialize all elements of the array
  for (unsigned int i = 0; i < rows; ++i) {
    for (unsigned int j = 0; j < cols; ++j) {
      arr[i][j] = i * cols + j; 
    }
  }
  return arr;
}

#
subtest 'affix' => sub {
    ok affix( $lib, test_1 => [UInt]                                   => Void ),                              'void test_1(unsigned int)';
    ok affix( $lib, test_2 => []                                      => UInt ),                               'unsigned int test_2()';
    ok affix( $lib, test_3 => [ Pointer [UInt], UInt ]                  => UInt ),                               'unsigned int test_3(unsigned int *, unsigned int)';
    ok affix( $lib, test_4 => [ Pointer [ Pointer [UInt] ], UInt, UInt ] => UInt ),                               'unsigned int test_4(unsigned int **, iunsigned intnt, unsigned int)';
    ok affix( $lib, test_5 => [UInt]                                   => Pointer [ UInt, 5 ] ),                'unsigned int * test_5(unsigned int)';
    ok affix( $lib, test_6 => [ UInt, UInt ]                            => Pointer [ Pointer [ UInt, 3 ], 5 ] ), 'unsigned int ** test_6(unsigned int, unsigned int)';
    ok affix( $lib, [ test_6 => 'test_7' ] => [ UInt, UInt ]                => Pointer [ Pointer [UInt], 3 ] ),      'unsigned int ** test_7(unsigned int, unsigned int)';
    ok affix( $lib, [ test_6 => 'test_8' ] => [ UInt, UInt ]                => Pointer [ Pointer [UInt] ] ),         'unsigned int ** test_8(unsigned int, unsigned int)';
    ok affix( $lib, [ test_6 => 'test_9' ] => [ UInt, UInt ]                => Pointer [ Pointer [ UInt, 1 ], 5 ] ), 'unsigned int ** test_8(unsigned int, unsigned int)';
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
is test_9( 5, 1 ), [ 0 .. 4 ], 'test_9(5, 1)';
#
done_testing;
