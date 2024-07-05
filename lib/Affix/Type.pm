package Affix::Type 0.5 {
    use strict;
    use warnings;
    use Carp qw[];
    use warnings::register;
    use feature 'current_sub';    # perl 5.16+
    {
        package                   #hide
            Affix::Type::Parameterized 0.00 {
            use parent -norequire, 'Affix::Type';
            sub parameterized          {1}
            sub subtype : prototype($) { return shift->[ Affix::SLOT_SUBTYPE() ]; }
        }
    }
    use Affix::Type::Struct qw[:all];
    use Affix::Type::Union  qw[:all];
    $Carp::Internal{ (__PACKAGE__) }++;
    use parent 'Exporter';
    our ( @EXPORT_OK, %EXPORT_TAGS );
    $EXPORT_TAGS{all} = [
        @EXPORT_OK = qw[
            Void Bool Char UChar SChar WChar Short UShort Int UInt Long ULong LongLong ULongLong Float Double
            Size_t
            String WString StdString
            CodeRef
            Pointer
            SV
            Const
            typedef alignment sizeof
        ]
    ];
    use overload '""' => sub {
        my $ret = $_[0]->{stringify};
        return $ret unless $_[0]->{const};
        return $ret if $_[0]->{depth};
        return 'Const[ ' . $ret . ' ]';
        },
        '0+' => sub { shift->{numeric} };
    sub parameterized($) {0}

    sub sizeof ($) {
        shift->{sizeof};
    }

    sub alignment ($) {
        shift->{alignment};
    }

    sub offsetof ($) {
        shift->{offset};
    }

    sub new($$$$$$;$$) {
        my ( $pkg, $str, $flag, $sizeof, $align, $offset, $subtype, $array_len ) = @_;
        die 'Please subclass Affix::Type' if $pkg eq __PACKAGE__;
        bless {
            stringify => $str,
            numeric   => $flag,
            sizeof    => $sizeof,
            alignment => $align,
            offset    => $offset,                # TODO
            subtype   => $subtype,
            length    => [ $array_len // () ],
            typedef   => undef,                  # TODO
            const     => !1,
            volitile  => !1,
            restrict  => !1,
            depth     => 0                       # pointer depth
        }, $pkg;
    }

    sub typedef ($$) {
        my ( $name, $type ) = @_;
        if ( !$type->isa('Affix::Type') ) {
            require Carp;
            Carp::croak( 'Unknown type: ' . $type );
        }
        my $fqn = $name =~ /::/ ? $name : [caller]->[0] . '::' . $name;
        {
            no strict 'refs';
            no warnings 'redefine';
            *{$fqn} = sub { CORE::state $s //= $type };
            @{ $fqn . '::ISA' } = ref $type;
        }
        bless $type, $fqn;
        $type->{typedef}   = $name;
        $type->{stringify} = sprintf q[typedef ( %s => %s )], $name =~ /::/ ? "'$name'" : $name, $type->{stringify};
        push @{ $EXPORT_TAGS{types} }, $name if $fqn eq 'Affix::' . $name;    # only great when triggered by/before import
        my $next = $type->can('typedef');
        $next->( $type, $fqn ) if defined $next && __SUB__ != $next;
        $type;
    }

    # Types
    sub Void() { Affix::Type::Void->new( 'Void', Affix::VOID_FLAG(), 0, 0 ); }

    sub Bool() {
        Affix::Type::Bool->new( 'Bool', Affix::BOOL_FLAG(), Affix::Platform::SIZEOF_BOOL(), Affix::Platform::ALIGNOF_BOOL(), );
    }

    sub Char() {
        Affix::Type::Char->new( 'Char', Affix::CHAR_FLAG(), Affix::Platform::SIZEOF_CHAR(), Affix::Platform::ALIGNOF_CHAR() );
    }

    sub SChar() {
        Affix::Type::SChar->new( 'SChar', Affix::SCHAR_FLAG(), Affix::Platform::SIZEOF_SCHAR(), Affix::Platform::ALIGNOF_SCHAR() );
    }

    sub UChar() {
        Affix::Type::UChar->new( 'UChar', Affix::UCHAR_FLAG(), Affix::Platform::SIZEOF_UCHAR(), Affix::Platform::ALIGNOF_UCHAR() );
    }

    sub WChar() {
        Affix::Type::WChar->new( 'WChar', Affix::WCHAR_FLAG(), Affix::Platform::SIZEOF_WCHAR(), Affix::Platform::ALIGNOF_WCHAR() );
    }

    sub Short() {
        Affix::Type::Short->new( 'Short', Affix::SHORT_FLAG(), Affix::Platform::SIZEOF_SHORT(), Affix::Platform::ALIGNOF_SHORT() );
    }

    sub UShort() {
        Affix::Type::UShort->new( 'UShort', Affix::USHORT_FLAG(), Affix::Platform::SIZEOF_USHORT(), Affix::Platform::ALIGNOF_USHORT() );
    }

    sub Int () {
        Affix::Type::Int->new( 'Int', Affix::INT_FLAG(), Affix::Platform::SIZEOF_INT(), Affix::Platform::ALIGNOF_INT() );
    }

    sub UInt () {
        Affix::Type::UInt->new( 'UInt', Affix::UINT_FLAG(), Affix::Platform::SIZEOF_UINT(), Affix::Platform::ALIGNOF_UINT() );
    }

    sub Long () {
        Affix::Type::Long->new( 'Long', Affix::LONG_FLAG(), Affix::Platform::SIZEOF_LONG(), Affix::Platform::ALIGNOF_LONG() );
    }

    sub ULong () {
        Affix::Type::ULong->new( 'ULong', Affix::ULONG_FLAG(), Affix::Platform::SIZEOF_ULONG(), Affix::Platform::ALIGNOF_ULONG() );
    }

    sub LongLong () {
        Affix::Type::LongLong->new( 'LongLong', Affix::LONGLONG_FLAG(), Affix::Platform::SIZEOF_LONGLONG(), Affix::Platform::ALIGNOF_LONGLONG() );
    }

    sub ULongLong () {
        Affix::Type::ULongLong->new( 'ULongLong', Affix::ULONGLONG_FLAG(), Affix::Platform::SIZEOF_ULONGLONG(),
            Affix::Platform::ALIGNOF_ULONGLONG() );
    }

    sub Float () {
        Affix::Type::Float->new( 'Float', Affix::FLOAT_FLAG(), Affix::Platform::SIZEOF_FLOAT(), Affix::Platform::ALIGNOF_FLOAT() );
    }

    sub Double () {
        Affix::Type::Double->new( 'Double', Affix::DOUBLE_FLAG(), Affix::Platform::SIZEOF_DOUBLE(), Affix::Platform::ALIGNOF_DOUBLE() );
    }

    sub Size_t () {
        Affix::Type::Size_t->new( 'Size_t', Affix::SIZE_T_FLAG(), Affix::Platform::SIZEOF_SIZE_T(), Affix::Platform::ALIGNOF_SIZE_T() );
    }

    sub String() {
        CORE::state $type //= Pointer( [ Const( [ Char() ] ) ] );
        $type;
    }

    sub WString() {
        CORE::state $type //= Pointer( [ Const( [ WChar() ] ) ] );
        $type;
    }

    sub StdString () {
        Affix::Type::StdString->new( 'StdString', Affix::STD_STRING_FLAG(), Affix::Platform::SIZEOF_INTPTR_T(), Affix::Platform::ALIGNOF_INTPTR_T() );
    }

    # TODO: CPPStruct
    #~ $pkg, $str, $flag, $sizeof, $align, $offset, $subtype, $array_len
    sub CodeRef : prototype($) {
        my (@elements) = @{ +shift };
        my ( $args, $ret ) = @elements;
        $ret //= Void;
        my $s = Affix::Type::CodeRef->new(
            sprintf( 'CodeRef[ [ %s ] => %s ]', join( ', ', @$args ), $ret ),    # SLOT_CODEREF_STRINGIFY
            Affix::CODEREF_FLAG(),                                               # SLOT_CODEREF_NUMERIC
            Affix::Platform::SIZEOF_INTPTR_T(),                                  # SLOT_CODEREF_SIZEOF
            Affix::Platform::ALIGNOF_INTPTR_T(),                                 # SLOT_CODEREF_ALIGNMENT
            undef,                                                               # SLOT_CODEREF_OFFSET
            $ret                                                                 # SLOT_CODEREF_RET
        );

        # TODO:
        # $s->[ Affix::SLOT_CODEREF_ARGS() ] = $args;
        # $s->[ Affix::SLOT_CODEREF_SIG() ]  = join( '', map { chr $_ } @$args );
        $s;
    }

    sub Function : prototype($) {
        my (@elements) = @{ +shift };
        my ( $args, $ret ) = @elements;
        $ret //= Void;
        Affix::Type::Function->new(
            sprintf( 'Function[ [ %s ] => %s ]', join( ', ', @$args ), $ret ),    # SLOT_STRINGIFY
            Affix::AFFIX_FLAG(),                                                  # SLOT_NUMERIC
            Affix::Platform::SIZEOF_INTPTR_T(),                                   # SLOT_SIZEOF
            Affix::Platform::ALIGNOF_INTPTR_T(),                                  # SLOT_ALIGNMENT
            undef,                                                                # SLOT_OFFSET
            $ret,                                                                 # SLOT_CODEREF_RET (result type)
            $args,                                                                # SLOT_CODEREF_ARGS
            join '', map { chr $_ } @$args                                        # SLOT_CODEREF_SIG
        );
    }

    #~ // [ text, id, size, align, offset, subtype, length, aggregate, typedef ]
    #define SLOT_STRINGIFY 0
    #define SLOT_NUMERIC 1
    #define SLOT_SIZEOF 2
    #define SLOT_ALIGNMENT 3
    #define SLOT_OFFSET 4
    #define SLOT_SUBTYPE 5
    #define SLOT_ARRAYLEN 6
    #define SLOT_AGGREGATE 7
    #define SLOT_TYPEDEF 8
    #define SLOT_CAST 9
    #define SLOT_CODEREF_RET 5
    #define SLOT_CODEREF_ARGS 6
    #define SLOT_CODEREF_SIG 7
    #define SLOT_POINTER_SUBTYPE SLOT_SUBTYPE
    #define SLOT_POINTER_COUNT SLOT_ARRAYLEN
    #define SLOT_POINTER_ADDR 7
    sub Pointer : prototype($) {
        my ( $subtype, $length ) = @{ +shift };
        $subtype->{depth}++;
        unshift @{ $subtype->{length} }, $length // -1;    # -1 forces fallback
        $subtype->{stringify} = 'Pointer[ ' . $subtype->{stringify} . ( defined $length ? ', ' . $length : '' ) . ' ]';
        $subtype;
    }

    sub Array : prototype($) {
        my ( $subtype, $length ) = @{ +shift };            # No defaults
        bless(
            [   'Array[ ' . $subtype . ', ' . $length . ' ]',    # SLOT_STRINGIFY
                Affix::POINTER_FLAG(),                           # SLOT_NUMERIC
                Affix::Platform::SIZEOF_INTPTR_T(),              # SLOT_SIZEOF
                Affix::Platform::ALIGNOF_INTPTR_T(),             # SLOT_ALIGNMENT
                undef,                                           # SLOT_OFFSET
                $subtype,                                        # SLOT_SUBTYPE
                $length                                          # SLOT_ARRAYLEN
            ],
            'Affix::Type::Pointer'
        );
    }

    # Should only be used inside of a Pointer[]
    sub SV : prototype() { Affix::Type::SV->new( 'SV', Affix::SV_FLAG(), 0, 0 ); }

    #~ typedef ShortInt     => Short;
    #~ typedef SShort       => Short;
    #~ typedef SShortInt    => Short;
    #~ typedef UShortInt    => UShort;
    #~ typedef Signed       => Int;
    #~ typedef SInt         => Int;
    #~ typedef Unsigned     => UInt;
    #~ typedef LongInt      => Long;
    #~ typedef SLongInt     => Long;
    #~ typedef LongLongInt  => LongLong;
    #~ typedef SLongLong    => LongLong;
    #~ typedef SLongLongInt => LongLong;
    #~ typedef ULongLongInt => ULongLong;
    #~ typedef Str          => String;
    #~ typedef WStr         => WString;
    #~ typedef wchar_t => WChar;
    # Qualifier flags
    sub Const : prototype($) {
        my ( $subtype, @etc ) = @_ ? @{ +shift } : Void();    # Defaults to Pointer[Void]
        Carp::croak sprintf( 'Too may arguments in Pointer[ %s, %s ]', $subtype, join ', ', @etc ) if @etc;
        $subtype->{const}     = 1;
        $subtype->{stringify} = 'Const[ ' . $subtype->{stringify} . ' ]';
        $subtype;
    }

    sub Volatile : prototype($) {
        $_[0][0]->{volitile} = 1;
        $_[0][0];
    }

    sub Restrict : prototype($) {
        $_[0][0]->{restrict} = 1;
        $_[0][0];
    }
    package    # hide
        Affix::Type::CodeRef {
        sub parameterized           {1}
        sub rettype : prototype($)  { return shift->[ Affix::SLOT_SUBTYPE() ]; }
        sub argtypes : prototype($) { return shift->[ Affix::SLOT_CODEREF_ARGS() ]; }
    }
    @Affix::Type::Void::ISA = @Affix::Type::SV::ISA

        # Numerics
        = @Affix::Type::Bool::ISA  = @Affix::Type::Char::ISA     = @Affix::Type::SChar::ISA     = @Affix::Type::UChar::ISA = @Affix::Type::WChar::ISA
        = @Affix::Type::Short::ISA = @Affix::Type::UShort::ISA   = @Affix::Type::Int::ISA       = @Affix::Type::UInt::ISA = @Affix::Type::Long::ISA
        = @Affix::Type::ULong::ISA = @Affix::Type::LongLong::ISA = @Affix::Type::ULongLong::ISA = @Affix::Type::Float::ISA
        = @Affix::Type::Double::ISA
        = @Affix::Type::Size_t::ISA

        # Enumerations (subclasses handled in Affix::Type::Enum)
        = @Affix::Type::Enum::ISA

        # Pointers
        = @Affix::Type::String::ISA = @Affix::Type::WString::ISA = @Affix::Type::StdString::ISA

        # Typedef'd aliases
        = @Affix::Type::Str::ISA

        # Calling conventions
        = @Affix::CC::ISA
        #
        = @Affix::Type::Parameterized::ISA = 'Affix::Type';

    # Pointers
    @Affix::Type::Pointer::Unmanaged::ISA = 'Affix::Pointer';

    # Aggregates
    @Affix::Type::Union::ISA
        #
        = @Affix::Type::Pointer::ISA = @Affix::Type::CodeRef::ISA = @Affix::Type::Function::ISA = 'Affix::Type::Parameterized';
    @Affix::CC::Reset::ISA = @Affix::CC::This::ISA = @Affix::CC::Ellipsis::ISA = @Affix::CC::Varargs::ISA = @Affix::CC::CDecl::ISA
        = @Affix::CC::STDcall::ISA = @Affix::CC::MSFastcall::ISA = @Affix::CC::GNUFastcall::ISA = @Affix::CC::MSThis::ISA = @Affix::CC::GNUThis::ISA
        = @Affix::CC::Arm::ISA     = @Affix::CC::Thumb::ISA      = @Affix::CC::Syscall::ISA     = 'Affix::CC';

    sub Reference : prototype(;$) {    # [ text, id, size, align, offset, subtype, sizeof, package ]

        #~ use Data::Dump;
        #~ ddx \@_;
        my $sizeof  = 0;
        my $packed  = 0;
        my $subtype = undef;
        if (@_) {
            ($subtype) = @{ +shift };

            #~ ddx $subtype;
            my $__sizeof = $subtype->sizeof;
            my $__align  = $subtype->align;
            $sizeof += $packed ? 0 : padding_needed_for( $sizeof, $__align > $__sizeof ? $__sizeof : $__align );
            $sizeof += $__sizeof;
        }
        else {
            warn scalar caller;
            Carp::croak 'Reference requires a type' unless scalar caller =~ /^Affix(::.+)?$/;
            $subtype = Void();    # Defaults to Pointer[Void]
        }
        bless( [ 'Reference [ ' . $subtype . ' ]', REFERENCE_FLAG(), $subtype->sizeof(), $subtype->align(), undef, $subtype, $sizeof, undef ],
            'Affix::Flag::Reference' );
    }

    # Calling Conventions
    sub Reset() { bless( [ 'This', RESET_FLAG(), undef, undef, undef ], 'Affix::CC::Reset' ); }
    sub This()  { bless( [ 'This', THIS_FLAG(),  undef, undef, undef ], 'Affix::CC::This' ); }

    sub Ellipsis() {
        bless( [ 'Ellipsis', ELLIPSIS_FLAG(), undef, undef, undef ], 'Affix::CC::Ellipsis' );
    }

    sub Varargs() {
        bless( [ 'Varargs', VARARGS_FLAG(), undef, undef, undef ], 'Affix::CC::Varargs' );
    }
    sub CDecl() { bless( [ 'CDecl', CDECL_FLAG(), undef, undef, undef ], 'Affix::CC::CDecl' ); }

    sub STDcall() {
        bless( [ 'STDcall', STDCALL_FLAG(), undef, undef, undef ], 'Affix::CC::STDcall' );
    }

    sub MSFastcall() {
        bless( [ 'MSFastcall', MSFASTCALL_FLAG(), undef, undef, undef ], 'Affix::CC::MSFastcall' );
    }

    sub GNUFastcall() {
        bless( [ 'GNUFastcall', GNUFASTCALL_FLAG(), undef, undef, undef ], 'Affix::CC::GNUFastcall' );
    }

    sub MSThis() {
        bless( [ 'MSThis', MSTHIS_FLAG(), undef, undef, undef ], 'Affix::CC::MSThis' );
    }

    sub GNUThis() {
        bless( [ 'GNUThis', GNUTHIS_FLAG(), undef, undef, undef ], 'Affix::CC::GNUThis' );
    }
    sub Arm()   { bless( [ 'Arm',   ARM_FLAG(),   undef, undef, undef ], 'Affix::CC::Arm' ); }
    sub Thumb() { bless( [ 'Thumb', THUMB_FLAG(), undef, undef, undef ], 'Affix::CC::Thumb' ); }

    sub Syscall() {
        bless( [ 'Syscall', SYSCALL_FLAG(), undef, undef, undef ], 'Affix::CC::Syscall' );
    }
    #
    sub intptr_t { Pointer [Void] }
}
1;
