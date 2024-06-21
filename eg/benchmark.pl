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

sub libfile {
    return undef;
    $libfile;
}
#
my $sin_default = wrap( $libfile, 'sin', [Double] => Double );
affix( $libfile, [ 'sin', '_affix_sin_default' ], [Double] => Double );
#
my $ffi = FFI::Platypus->new( api => 1 );
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
    my $int = rand;
    my $sin = sin $int;
    diag sprintf 'pow(%f) == %f', $int, $sin;
    is $sin_default->($int),     float( $sin, tolerance => 0.000000001 ), 'Affix coderef';
    is _affix_sin_default($int), float( $sin, tolerance => 0.000000001 ), 'Affix affix\'d';
    is ffi_sin($int),            float( $sin, tolerance => 0.000000001 ), 'FFI::Platypus attach';
    is $ffi_func->($int),        float( $sin, tolerance => 0.000000001 ), 'FFI::Platypus coderef';
    is inline_c_sin($int),       float( $sin, tolerance => 0.000000001 ), 'Inline::C';
};
done_testing;
#
my $depth = 1000;
cmpthese(
    timethese(
        -30,
        {   perl => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = sin($x); $x++ }
            },
            affix_sub => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = _affix_sin_default($x); $x++ }
            },
            affix_coderef => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $sin_default->($x); $x++ }
            },
            ffi_sub => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = ffi_sin($x); $x++ }
            },
            ffi_coderef => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = $ffi_func->($x); $x++ }
            },
            inline_c_sin => sub {
                my $x = 0;
                while ( $x < $depth ) { my $n = inline_c_sin($x); $x++ }
            }
        }
    )
);
