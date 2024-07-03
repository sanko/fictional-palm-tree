use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib';
use Affix qw[:all];
use FFI::Platypus 1.58;
use Inline C => config => libs => '-lm';
use Config;
use Benchmark qw[cmpthese timethese :hireswallclock];
use Test2::V0;

# arbitrary benchmarks
$|++;
our $libfile;

BEGIN {
    $libfile
        = $^O eq 'MSWin32' ? 'ntdll.dll' :
        $^O eq 'darwin'    ? '/usr/lib/libm.dylib' :
        $^O eq 'bsd'       ? '/usr/lib/libm.so' :
        $Config{archname} =~ /64/ ?
        -e '/lib64/libm.so.6' ?
            '/lib64/libm.so.6' :
            '/lib/' . $Config{archname} . '-gnu/libm.so.6' :
        '/lib/libm.so.6';
}
#
my $sin_default = wrap( $libfile, 'sin', [Double] => Double );
affix( $libfile, [ 'sin', '_affix_sin_default' ], [Double] => Double );
#
my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib($libfile);
my $ffi_func = $ffi->function( sin => ['double'] => 'double' );
$ffi->attach( [ sin => 'ffi_sin' ] => ['double'] => 'double' );
#
use Inline C => <<'...';
#include <math.h>

double inline_c_sin(double in) {
  return sin(in);
}
...

# prime the pump and verify results
subtest 'verify' => sub {
    my $int = rand(time);
    my $sin = sin $int;
    diag sprintf 'sin(%f) == %f', $int, $sin;
    is $sin_default->($int),     float( $sin, tolerance => 0.00000001 ), 'Affix::wrap';
    is _affix_sin_default($int), float( $sin, tolerance => 0.00000001 ), 'Affix::affix';
    is ffi_sin($int),            float( $sin, tolerance => 0.00000001 ), 'FFI::Platypus->attach';
    is $ffi_func->($int),        float( $sin, tolerance => 0.00000001 ), 'FFI::Platypus->function';
    is inline_c_sin($int),       float( $sin, tolerance => 0.00000001 ), 'Inline::C';
};
done_testing;
#
my $depth = 20;
cmpthese(
    timethese(
        -30,
        {   perl => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin($x); $x++ }
            },
            'Affix::affix' => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = _affix_sin_default($x); $x++ }
            },
            'Affix::wrap' => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_default->($x); $x++ }
            },
            'Platypus->function' => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = ffi_sin($x); $x++ }
            },
            'Platypus->attach' => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $ffi_func->($x); $x++ }
            },
            'Inline::C' => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = inline_c_sin($x); $x++ }
            }
        }
    )
);
