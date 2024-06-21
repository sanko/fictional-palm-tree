use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );

# use Test2::Require::AuthorTesting;
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[wrap affix find_library Double];
BEGIN { chdir '../' if !-d 't'; }
use Benchmark qw[:all];
$|++;
#
my $wrap_w_params = wrap( find_library('m'), 'pow', [ Double, Double ], Double );
affix( find_library('m'), [ 'pow' => 'affix_w_params' ], [ Double, Double ], Double );
#
subtest verify => sub {
    ok 81 == $wrap_w_params->( 3.0, 4.0 ), 'wrap w/ params';
    ok 81 == affix_w_params( 3.0, 4.0 ),   'affix w/ params';
    ok 81 == pow( 3.0, 4.0 ),              'pure perl [Double, Double]';
};

sub pow($$) {
    my ( $x, $y ) = @_;
    return $x**$y;
}
subtest benchmarks => sub {
    my $todo = todo 'these are fun but not important';
    isnt fastest( -5, wrap => sub { $wrap_w_params->( 3, 4 ) }, affix => sub { affix_w_params( 3, 4 ) }, pure => sub { pow( 3, 4 ) } ), 'pure',
        '[Int, Int]';
    isnt fastest( -5, wrap => sub { $wrap_w_params->( 3.0, 4.0 ) }, affix => sub { affix_w_params( 3.0, 4.0 ) }, pure => sub { pow( 3.0, 4.0 ) } ),
        'pure', '[Double, Double]';
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
