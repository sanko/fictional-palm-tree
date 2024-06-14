use Test2::V0;
use lib './lib', '../lib';
use Affix;
#
diag $Affix::VERSION;
is Affix::greet('World'), 'Hello, World', 'proper greeting';
#
done_testing;
