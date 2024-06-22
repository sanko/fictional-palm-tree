package Affix::Type::Struct 0.5 {
    use strict;
    use warnings;
    use Carp qw[];
    $Carp::Internal{ (__PACKAGE__) }++;
    use Scalar::Util qw[dualvar];
    use parent -norequire, 'Exporter', 'Affix::Type::Parameterized';
    our ( @EXPORT_OK, %EXPORT_TAGS );
    $EXPORT_TAGS{all} = [ @EXPORT_OK = qw[Struct] ];

    sub typedef : prototype($$) {
        my ( $self, $name ) = @_;
        no strict 'refs';
        warn 'TODO: generate mutators';

        #~ for my $key ( keys %{ $self->[5] } ) {
        #~ my $val = $self->[5]{$key};
        #~ *{ $name . '::' . $key } = sub () { dualvar $val, $key; };
        #~ }
        1;
    }

    sub Struct : prototype($) {
        my (@types) = @{ +shift };
        my @fields;
        my $sizeof = 0;
        my $packed = 0;
        my @store;
        for ( my $i = 0; $i < $#types; $i += 2 ) {
            my $field    = $types[$i];
            my $subtype  = $types[ $i + 1 ];
            my $__sizeof = $subtype->sizeof;
            my $__align  = $subtype->align;
            $subtype->{offset} =

                #~ $sizeof +
                #~ Affix::Platform::padding_needed_for( $sizeof + $__sizeof, $__align );
                int( ( $sizeof + $__align - 1 ) / $__align ) * $__align;

            #~ warn sprintf '%10s => %d', $field, $subtype->[Affix::SLOT_TYPE_OFFSET];
            # offset
            $subtype->{name} = $field;                       # field name
            push @store, bless {%$subtype}, ref $subtype;    # clone
            push @fields, sprintf '%s => %s', $field, $subtype;

            #~ warn sprintf 'Before: struct size: %d, element size: %d, align: %d, offset: %d', $sizeof, $__sizeof, $__align,
            #~ $subtype->[Affix::SLOT_TYPE_OFFSET];
            #~ $sizeof += $__sizeof + Affix::Platform::padding_needed_for( $sizeof + $__sizeof, $__align );
            $sizeof = $subtype->{offset} + $__sizeof;

            #~ warn sprintf 'After:  struct size: %d, element size: %d', $sizeof, $__sizeof;
        }

        #~ use Data::Dump;
        #~ ddx \@store;
        bless {
            stringify => sprintf( 'Struct[ %s ]', join ', ', @fields ),                                              # SLOT_TYPE_STRINGIFY
            numeric   => Affix::STRUCT_FLAG(),                                                                       # SLOT_TYPE_NUMERIC
            sizeof    => $sizeof + Affix::Platform::padding_needed_for( $sizeof, Affix::Platform::BYTE_ALIGN() ),    # SLOT_TYPE_SIZEOF
            alignment => Affix::Platform::BYTE_ALIGN(),                                                              # SLOT_TYPE_ALIGNMENT
            offset    => undef,                                                                                      # SLOT_TYPE_OFFSET
            subtype   => \@store,                                                                                    # SLOT_TYPE_SUBTYPE
            length    =>    # 1,                                                                                          # SLOT_TYPE_ARRAYLEN
                const => !1,    # SLOT_TYPE_CONST
            volitile => !1,     # SLOT_TYPE_VOLATILE
            restrict => !1,     # SLOT_TYPE_RESTRICT
            typedef  => undef,  # SLOT_TYPE_TYPEDEF
            name     => undef   # SLOT_TYPE_FIELD
            },
            'Affix::Type::Struct';
    }

    sub offsetof {
        my ( $s, $path ) = @_;
        my $offset = 0;
        my ( $field, $tail ) = split '\.', $path, 2;
        $field //= $path;
        my $now;
        my $i = 0;
        for my $element ( @{ $s->{subtype} } ) {
            $now = $element and last if $element->{subtype} eq $field;
        }
        return () unless defined $now;
        if ( length $tail && $now->isa('Affix::Type::Struct') ) {
            return $now->offsetof($tail);
        }
        $offset += $now->{offset} + ( $s->{offset} // 0 );
        return $offset;
    }
};
1;
