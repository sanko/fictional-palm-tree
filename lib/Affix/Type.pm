package Affix::Type 0.5 {
    use strict;
    use warnings;
    use Carp qw[];
    $Carp::Internal{ (__PACKAGE__) }++;
    use parent 'Exporter';
    our ( @EXPORT_OK, %EXPORT_TAGS );
    $EXPORT_TAGS{all} = [
        @EXPORT_OK = qw[
            Void Bool Char UChar SChar WChar Short UShort Int UInt Long ULong LongLong ULongLong Float Double
            Size_t
            String WString StdString
            Struct Union
            CodeRef Function
            Pointer Array
            SV
            typedef
        ]
    ];
    @Affix::Type::Void::ISA = @Affix::Type::Bool::ISA = @Affix::Type::Char::ISA = @Affix::Type::UChar::ISA = @Affix::Type::Short::ISA
        = @Affix::Type::UShort::ISA   = @Affix::Type::Int::ISA       = @Affix::Type::UInt::ISA   = @Affix::Type::Long::ISA = @Affix::Type::ULong::ISA
        = @Affix::Type::LongLong::ISA = @Affix::Type::ULongLong::ISA = @Affix::Type::Size_t::ISA = @Affix::Type::Float::ISA
        = @Affix::Type::Double::ISA   = __PACKAGE__;

    sub Void() {
        bless { stringify => 'Void', numeric => Affix::VOID_FLAG(), sizeof => 0, alignment => 0, }, 'Affix::Type::Void';
    }

    sub Bool() {
        bless {
            stringify => 'Bool',
            numeric   => Affix::BOOL_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_BOOL(),
            alignment => Affix::Platform::ALIGNOF_BOOL(),
            },
            'Affix::Type::Bool';
    }

    sub Char() {
        bless {
            stringify => 'Char',
            numeric   => Affix::CHAR_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_CHAR(),
            alignment => Affix::Platform::ALIGNOF_CHAR(),
            },
            'Affix::Type::Char';
    }

    sub UChar() {
        bless {
            stringify => 'UChar',
            numeric   => Affix::UCHAR_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_UCHAR(),
            alignment => Affix::Platform::ALIGNOF_UCHAR(),
            },
            'Affix::Type::UChar';
    }

    sub Short() {
        bless {
            stringify => 'Short',
            numeric   => Affix::SHORT_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_SHORT(),
            alignment => Affix::Platform::ALIGNOF_SHORT()
            },
            'Affix::Type::Short';
    }

    sub UShort() {
        bless {
            stringify => 'Bool',
            numeric   => Affix::USHORT_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_USHORT(),
            alignment => Affix::Platform::ALIGNOF_USHORT()
            },
            'Affix::Type::UShort';
    }

    sub Int() {
        bless {
            stringify => 'Int',
            numeric   => Affix::INT_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_INT(),
            alignment => Affix::Platform::ALIGNOF_INT(),
            },
            'Affix::Type::Int';
    }

    sub UInt() {
        bless {
            stringify => 'UInt',
            numeric   => Affix::UINT_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_UINT(),
            alignment => Affix::Platform::ALIGNOF_UINT(),
            },
            'Affix::Type::UInt';
    }

    sub Long() {
        bless {
            stringify => 'Long',
            numeric   => Affix::LONG_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_LONG(),
            alignment => Affix::Platform::ALIGNOF_LONG(),
            },
            'Affix::Type::Long';
    }

    sub ULong() {
        bless {
            stringify => 'ULong',
            numeric   => Affix::ULONG_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_ULONG(),
            alignment => Affix::Platform::ALIGNOF_ULONG()
            },
            'Affix::Type::ULong';
    }

    sub LongLong() {
        bless {
            stringify => 'LongLong',
            numeric   => Affix::LONGLONG_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_LONGLONG(),
            alignment => Affix::Platform::ALIGNOF_LONGLONG()
            },
            'Affix::Type::LongLong';
    }

    sub ULongLong() {
        bless {
            stringify => 'ULongLong',
            numeric   => Affix::ULONGLONG_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_ULONGLONG(),
            alignment => Affix::Platform::ALIGNOF_ULONGLONG()
            },
            'Affix::Type::ULongLong';
    }

    sub Size_t() {
        bless {
            stringify => 'Size_t',
            numeric   => Affix::SIZE_T_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_SIZE_T(),
            alignment => Affix::Platform::ALIGNOF_SIZE_T()
            },
            'Affix::Type::Size_t';
    }

    sub Float() {
        bless {
            stringify => 'Float',
            numeric   => Affix::FLOAT_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_FLOAT(),
            alignment => Affix::Platform::ALIGNOF_FLOAT()
            },
            'Affix::Type::Float';
    }

    sub Double() {
        bless {
            stringify => 'Double',
            numeric   => Affix::DOUBLE_FLAG(),
            sizeof    => Affix::Platform::SIZEOF_DOUBLE(),
            alignment => Affix::Platform::ALIGNOF_DOUBLE()
            },
            'Affix::Type::Double';
    }

    #  char numeric;
    #     bool const_flag = false;
    #     bool volitile_flag = false;
    #     bool restrict_flag = false;
    #     bool saints = false; // preserve us
    #     size_t pointer_depth = 0;
    #     size_t size;
    #     size_t _alignment;
    #     size_t offset;
    #     size_t arraylen;
    #     const char *_stringify;
    #     //
    #     void *subtype = NULL; // Affix_Type
    #     const char *_typedef = NULL;
    #     DCaggr *aggregate = NULL;
    #     void **args = NULL;       // list of Affix_Type
    #     const char *field = NULL; // If part of a struct
};
1;
