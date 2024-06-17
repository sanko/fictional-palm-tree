use Test2::V0;
use lib './lib', '../lib';
use Affix;
#
diag $Affix::VERSION;
is Affix::greet('World'), 'Hello, World', 'proper greeting';
is Affix::greet("fdsafda");
#
done_testing;
