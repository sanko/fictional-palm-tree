#include "../Affix.h"

#define TYPE(name)                                                                                 \
    (void)newXSproto_portable("Affix::" #name, Affix_Type_##name, __FILE__, "");                   \
    set_isa("Affix::Type::" #name, "Affix::Type");                                                 \
    export_function("Affix", #name, "types")

// Simple type
#define STYPE(name, flag, size, align)                                                             \
    XS_INTERNAL(Affix_Type_##name) {                                                               \
        dVAR;                                                                                      \
        dXSARGS;                                                                                   \
        if (items) croak_xs_usage(cv, "");                                                         \
        Affix_Type *type = new Affix_Type(#name, flag, size, align);                               \
        SV *RETVAL = sv_newmortal();                                                               \
        sv_setref_pv(RETVAL, "Affix::Type::" #name, (DCpointer)type);                              \
        ST(0) = RETVAL;                                                                            \
        XSRETURN(1);                                                                               \
    }

// Parameterized type
#define PTYPE(name, flag, size, align) ;

STYPE(Void, VOID_FLAG, 0, 0);
STYPE(Bool, BOOL_FLAG, SIZEOF_BOOL, ALIGNOF_BOOL);
STYPE(Char, CHAR_FLAG, SIZEOF_CHAR, ALIGNOF_CHAR);
STYPE(UChar, UCHAR_FLAG, SIZEOF_UCHAR, ALIGNOF_UCHAR);
STYPE(WChar, WCHAR_FLAG, SIZEOF_WCHAR, ALIGNOF_WCHAR);
STYPE(Short, SHORT_FLAG, SIZEOF_SHORT, ALIGNOF_SHORT);
STYPE(UShort, USHORT_FLAG, SIZEOF_USHORT, ALIGNOF_USHORT);
STYPE(Int, INT_FLAG, SIZEOF_INT, ALIGNOF_INT);
STYPE(UInt, UINT_FLAG, SIZEOF_UINT, ALIGNOF_UINT);
STYPE(Long, LONG_FLAG, SIZEOF_LONG, ALIGNOF_LONG);
STYPE(ULong, ULONG_FLAG, SIZEOF_ULONG, ALIGNOF_ULONG);
STYPE(LongLong, LONGLONG_FLAG, SIZEOF_LONGLONG, ALIGNOF_LONGLONG);
STYPE(ULongLong, ULONGLONG_FLAG, SIZEOF_ULONGLONG, ALIGNOF_ULONGLONG);
STYPE(Size_t, SIZE_T_FLAG, SIZEOF_SIZE_T, ALIGNOF_SIZE_T);
STYPE(Float, FLOAT_FLAG, SIZEOF_FLOAT, ALIGNOF_FLOAT);
STYPE(Double, DOUBLE_FLAG, SIZEOF_DOUBLE, ALIGNOF_DOUBLE);

XS_INTERNAL(Affix_Type_DESTROY) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$type");
    Affix_Type *type;
    type = INT2PTR(Affix_Type *, SvIV(SvRV(ST(0))));
    if (type) delete type;
    type = NULL;
    XSRETURN_EMPTY;
}

XS_EXTERNAL(boot_Affix_Type) {
    dVAR;
    // dXSBOOTARGSXSAPIVERCHK;
    // PERL_UNUSED_VAR(items);
#ifdef USE_ITHREADS // Windows...
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif

    TYPE(Void);
    TYPE(Bool);
    TYPE(Char);
    TYPE(UChar);
    TYPE(WChar);
    TYPE(Short);
    TYPE(UShort);
    TYPE(Int);
    TYPE(UInt);
    TYPE(Long);
    TYPE(ULong);
    TYPE(LongLong);
    TYPE(ULongLong);
    TYPE(Size_t);
    TYPE(Float);
    TYPE(Double);
    // TODO: Parameterized
    // TYPE(Pointer);
    // TYPE(Struct);
}
