package Affix::Type::Union 0.5 {
    use strict;
    use warnings;
    use Carp qw[];
    $Carp::Internal{ (__PACKAGE__) }++;
    use Scalar::Util qw[dualvar];
    use parent -norequire, 'Exporter', 'Affix::Type::Parameterized';
    our ( @EXPORT_OK, %EXPORT_TAGS );
    $EXPORT_TAGS{all} = [ @EXPORT_OK = qw[Union] ];

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

    sub Union : prototype($) {
        my (@types) = @{ +shift };
        my @fields;
        my $sizeof    = 0;
        my $packed    = 0;
        my $alignment = 0;
        my @store;
        for ( my $i = 0; $i < $#types; $i += 2 ) {
            my $field    = $types[$i];
            my $subtype  = $types[ $i + 1 ];
            my $__sizeof = $subtype->sizeof;
            $subtype->{offset} = 0;
            $subtype->{name}   = $field;                     # field name
            push @store, bless {%$subtype}, ref $subtype;    # clone
            push @fields, sprintf '%s => %s', $field, $subtype;
            if ( $sizeof < $__sizeof ) {
                $sizeof    = $__sizeof;
                $alignment = $subtype->alignment;
            }
        }
        __PACKAGE__->new(
            sprintf( 'Union[ %s ]', join ', ', @fields ),                                               # SLOT_TYPE_STRINGIFY
            Affix::UNION_FLAG(),                                                                        # SLOT_TYPE_NUMERIC
            $sizeof + Affix::Platform::padding_needed_for( $sizeof, Affix::Platform::BYTE_ALIGN() ),    # SLOT_TYPE_SIZEOF
            $alignment,                                                                                 # SLOT_TYPE_ALIGNMENT
            undef,                                                                                      # SLOT_TYPE_OFFSET
            \@store,                                                                                    # SLOT_TYPE_SUBTYPE
            1,                                                                                          # SLOT_TYPE_ARRAYLEN
            !1,                                                                                         # SLOT_TYPE_CONST
            !1,                                                                                         # SLOT_TYPE_VOLATILE
            !1,
        );
    }

    sub offsetof {
        my ( $s, $path ) = @_;
        my $offset = 0;
        my ( $field, $tail ) = split '\.', $path, 2;
        $field //= $path;
        my $now;
        my $i = 0;
        for my $element ( @{ $s->{subtype} } ) {
            $now = $element and last if $element->{name} eq $field;
        }
        return () unless defined $now;
        if ( length $tail && $now->isa('Affix::Type::Union') ) {
            return $now->offsetof($tail);
        }
        $offset += $now->{offset} + ( $s->{offset} // 0 );
        return $offset;
    }
};
1;
