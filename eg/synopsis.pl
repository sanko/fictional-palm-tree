use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
{
    use Affix qw[:all];

    # bind to exported function
    affix libm, 'floor', [Double], Double;
    warn floor(3.14159);    # 3

    # wrap an exported function in a code reference
    # See https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/getpid?view=msvc-170
    my $getpid = wrap libc, ( Affix::Platform::Windows() ? '_' : '' ) . 'getpid', [], Int;
    warn $getpid->();    # $$
}
