use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
{
    use Affix qw[:all];

    # bind to exported function
    affix libm, 'floor', [Double], Double;
    warn floor(3.14159);    # 3

    # wrap an exported function in a code reference
    my $getpid = wrap libc, 'getpid', [], Int;    # '_getpid' on Win32
    warn $getpid->();                             # $$
}
