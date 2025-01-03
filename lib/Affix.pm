package Affix 1.00 {    # 'FFI' is my middle name!

    #~ G|-----------------------------------|-----------------------------------||
    #~ D|--------------------------4---5~---|--4--------------------------------||
    #~ A|--7~\-----4---44-/777--------------|------7/4~-------------------------||
    #~ E|-----------------------------------|-----------------------------------||
    #~   1 . + . 2 . + . 3 . + . 4 . + .     1 . + . 2 . + . 3 . + . 4 . + .
    use v5.32;
    use Carp               qw[];
    use vars               qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
    use warnings::register qw[Type];
    my $okay = 0;

    BEGIN {
        use XSLoader;
        $DynaLoad::dl_debug = 1;
        $okay               = XSLoader::load();
        use Affix::Platform;
        my $platform
            = 'Affix::Platform::' .
            ( ( Affix::Platform::Windows() ) ? 'Windows' :
                Affix::Platform::macOS() ? 'MacOS' :
                ( Affix::Platform::FreeBSD() || Affix::Platform::OpenBSD() || Affix::Platform::NetBSD() || Affix::Platform::DragonFlyBSD() ) ? 'BSD' :
                'Unix' );
        eval 'use ' . $platform . ' qw[:all];';
        $@ && die $@;
        our @ISA = ($platform);
    }
    #
    #~ use lib '../lib';
    use Affix::Type          qw[:all];
    use Affix::Type::CodeRef qw[:all];
    use Affix::Type::Enum    qw[:all];
    use Affix::Type::Struct  qw[:all];
    use Affix::Type::Union   qw[:all];
    use parent 'Exporter';
    $EXPORT_TAGS{types} = [
        @Affix::Type::EXPORT_OK,         @Affix::Type::CodeRef::EXPORT_OK, @Affix::Type::Enum::EXPORT_OK,
        @Affix::Type::Struct::EXPORT_OK, @Affix::Type::Union::EXPORT_OK
    ];
    $EXPORT_TAGS{pin}    = [qw[pin unpin]];
    $EXPORT_TAGS{memory} = [
        qw[
            affix wrap pin unpin
            malloc calloc realloc free memchr memcmp memset memcpy sizeof offsetof
            raw hexdump]
    ];
    $EXPORT_TAGS{lib} = [qw[load_library find_library find_symbol dlerror libm libc]];
    {
        my %seen;
        push @{ $EXPORT_TAGS{default} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} } for qw[core types cc lib];
    }
    {
        my %seen;
        push @{ $EXPORT_TAGS{all} }, grep { !$seen{$_}++ } @{ $EXPORT_TAGS{$_} } for keys %EXPORT_TAGS;
    }
    #
    @EXPORT    = sort @{ $EXPORT_TAGS{default} };    # XXX: Don't do this...
    @EXPORT_OK = sort @{ $EXPORT_TAGS{all} };
    #
    sub libm() { CORE::state $m //= find_library('m'); $m }
    sub libc() { CORE::state $c //= find_library('c'); $c }
};
1;
