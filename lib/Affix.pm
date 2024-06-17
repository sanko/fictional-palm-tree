package Affix v0.0.1 {    # 'FFI' is my middle name!

    # ABSTRACT: A Foreign Function Interface eXtension
    #~ G|-----------------------------------|-----------------------------------||
    #~ D|--------------------------4---5~---|--4--------------------------------||
    #~ A|--7~\-----4---44-/777--------------|------7/4~-------------------------||
    #~ E|-----------------------------------|-----------------------------------||
    #~   1 . + . 2 . + . 3 . + . 4 . + .     1 . + . 2 . + . 3 . + . 4 . + .
    use v5.26;
    use experimental 'signatures';
    use Carp qw[];
    use vars qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
    my $okay = 0;

    BEGIN {
        use XSLoader;
        $okay               = XSLoader::load();
        $DynaLoad::dl_debug = 1;
        my $platform
            = 'Affix::Platform::' .
            ( ( Affix::Platform::Win32() || Affix::Platform::Win64() ) ? 'Windows' :
                Affix::Platform::macOS() ? 'MacOS' :
                ( Affix::Platform::FreeBSD() || Affix::Platform::OpenBSD() || Affix::Platform::NetBSD() || Affix::Platform::DragonFlyBSD() ) ? 'BSD' :
                'Unix' );

        #~ warn $platform;
        eval 'use ' . $platform . ' qw[:all];';
        $@ && die $@;
        our @ISA = ($platform);

        #~ require ($platform); $platform->import(':all');
    }
    #
    #~ use lib '../lib';
    #~ use Affix::Type       qw[:all];
    #~ use Affix::Type::Enum qw[:all];
    #use Affix::Platform;
    use parent 'Exporter';
    $EXPORT_TAGS{types} = [ @Affix::Type::EXPORT_OK, @Affix::Type::Enum::EXPORT_OK ];
    #
    sub greet ($whom) {"Hello, $whom"}
};
1;

=encoding utf-8

=head1 NAME

Affix - A Foreign Function Interface eXtension

=head1 SYNOPSIS

    use Affix;

=head1 DESCRIPTION

Affix is brand new, baby!



=head1 Stack Size

You may control the max size of the internal stack that will be allocated and used to bind the arguments to by setting
the C<$VMSize> variable before using Affix.

    BEGIN{ $Affix::VMSize = 2 ** 16; }

This value is C<4096> by default and probably should not be changed.

=head1 See Also

=head1 LICENSE

This software is Copyright (c) 2024 by Sanko Robinson <sanko@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See L<http://www.perlfoundation.org/artistic_license_2_0>.

=head1 AUTHOR

Sanko Robinson <sanko@cpan.org>

=begin stopwords

dyncall

=end stopwords

=cut

