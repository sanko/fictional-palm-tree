use Test2::V0 '!subtest', 'array';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix         qw[:all];
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
int test_10(int x){ return -x; }
typedef int (*callback)(int, int);
int test_11(callback cb, int a, int b){ return cb(a, b); }
typedef int* (*ptr_callback)(int *);
int * test_12(ptr_callback cb, int* a){ return cb(a); }

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
    ok affix( $lib, [ test_6 => 'test_9' ] => [ Int, Int ]            => Pointer [ Pointer [ Int, 1 ], 5 ] ), 'int ** test_8(int, int)';
    ok affix( $lib, 'test_10'              => [Int]                   => Int ),                               'int test_10(int)';
    ok affix( $lib, 'test_11'              => [ CodeRef [ [ Int, Int ] => Int ], Int, Int ] => Int ),         'int test_11(callback, int, int)';
    ok affix( $lib, 'test_12'              => [ CodeRef [ [ Pointer [Int] ] => Pointer [Int] ], Pointer [Int] ] => Pointer [Int] ),
        'int* test_12(ptr_callback, int*)';
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
is test_9( 5, 1 ),                                                                                              [ 0 .. 4 ], 'test_9(5, 1)';
is test_10(-20),                                                                                                 20,        'test_10(-20)';
is test_10( 20),                                                                                                -20,        'test_10(20)';
is test_11( sub { my ( $one, $two ) = @_; is \@_, [ 1, 999 ], 'callback args: 1, 999'; $one + $two }, 1, 999 ), 1000, 'test_11( sub { ... }, 1, 999)';
is test_11( sub { my ( $one, $two ) = @_; is \@_, [ 1, -999 ], 'callback args: 1, -999'; $one + $two }, 1, -999 ), -998,
    'test_11( sub { ... }, 1, -999)';
isa_ok my $ptr = test_12(
    sub {
        my ($ptr) = shift;
        $ptr->dump(32);
        use Data::Printer;

        # ddx $ptr->[1..3];
        isa_ok $ptr, ['Affix::Pointer'], 'callback arg is a pointer';
        $ptr;
    },
    [ 1, 3, 5, 7, 9 ]
    ),
    ['Affix::Pointer'], 'test_12( sub { ... },[...]])';

package Affix::Pointer {

    sub TIEARRAY {
        my $class    = shift;
        my $elemsize = shift;
        if ( @_ || $elemsize =~ /\D/ ) {

            # croak "usage: tie ARRAY, '" . __PACKAGE__ . "', elem_size";
        }
        return bless { ELEMSIZE => $elemsize, ARRAY => [], }, $class;
    }
}
use Data::Printer;
warn $ptr;
p $ptr->dump(32);
print @$ptr;
print $ptr->[0];
tie my @array, 'Affix::Pointer', 3;
warn $array[2];

#~ ...;
warn $ptr->FETCH(1);
#
done_testing;
