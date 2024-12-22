use strict;
use warnings;
use Config;
use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );

# use Test2::Require::AuthorTesting;
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[wrap affix libm Double];
BEGIN { chdir '../' if !-d 't'; }
use Benchmark qw[:all];
$|++;
#
my $wrap_sin = wrap( libm(), 'sin', [Double], Double );
affix( libm(), [ 'sin' => 'affix_sin' ], [Double], Double );
#
my $num = rand(time);
my $sin = sin $num;
subtest verify => sub {
    is $wrap_sin->($num), float( $sin, tolerance => 0.000001 ), 'wrap';
    is affix_sin($num),   float( $sin, tolerance => 0.000001 ), 'affix';
    is sin($num),         float( $sin, tolerance => 0.000001 ), 'pure perl';
};
my $depth = 20;
subtest benchmarks => sub {
    my $todo = todo 'these are fun but not important; we will not be beating perl opcodes';
    is fastest(
        -5,
        pure => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = sin($x); $x++ }
        },
        wrap => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = $wrap_sin->($x); $x++ }
        },
        affix => sub {
            my $x = 0;
            while ( $x < $depth ) { my $n = affix_sin($x); $x++ }
        }
        ),
        'affix', '[Int]';
};

# Cribbed from Test::Benchmark
sub fastest {
    my ( $times, %marks ) = @_;
    diag sprintf 'running %s for %s seconds each', join( ', ', keys %marks ), abs($times);
    my @marks;
    my $len = [ map { length $_ } keys %marks ]->[-1];
    for my $name ( sort keys %marks ) {
        my $res = timethis( $times, $marks{$name}, '', 'none' );
        my ( $r, $pu, $ps, $cu, $cs, $n ) = @$res;
        push @marks, { name => $name, res => $res, n => $n, s => ( $pu + $ps ) };
        diag sprintf '%' . ( $len + 1 ) . 's - %s', $name, timestr($res);
    }
    my $results = cmpthese {
        map { $_->{name} => $_->{res} } @marks
    }, 'none';
    my $len_1 = [ map { length $_->[1] } @$results ]->[-1];
    diag sprintf '%-' . ( $len + 1 ) . 's %' . ( $len_1 + 1 ) . 's' . ( ' %5s' x scalar keys %marks ), @$_ for @$results;
    [ sort { $b->{n} * $a->{s} <=> $a->{n} * $b->{s} } @marks ]->[0]->{name};
}
#
done_testing;
