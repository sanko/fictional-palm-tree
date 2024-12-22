use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
{
    use Affix qw[:all];
    warn int Char;
    warn int String;
    warn int Pointer [Char];
    affix( 'C:\Windows\System32\user32.dll', 'MessageBoxA', [ Pointer [Void], String, String, Int ], Int );
    warn MessageBoxA( undef, "Hi", "What", 3 );
    warn;
}
