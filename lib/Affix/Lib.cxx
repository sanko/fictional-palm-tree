#include "../Affix.h"

XS_INTERNAL(Affix_Lib_load_library) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$lib");

    DLLib *lib;
    SV *const lib_sv = ST(0);
    SvGETMAGIC(lib_sv);

    // explicit undef
    if (UNLIKELY(!SvOK(lib_sv) && SvREADONLY(lib_sv))) lib = _affix_load_library(NULL);

    // object - not sure why someone would do this...
    else if (UNLIKELY(sv_isobject(lib_sv) && sv_derived_from(lib_sv, "Affix::Lib")))
        lib = INT2PTR(DLLib *, SvIV((SV *)SvRV(lib_sv)));
    // try treating it as a filename and then search for it as a last resort
    else if (NULL == (lib = _affix_load_library(SvPV_nolen(lib_sv))))
        lib = _affix_load_library(SvPV_nolen(call_sub(aTHX_ "Affix::find_library", lib_sv)));
    if (!lib) XSRETURN_EMPTY;
    SV *LIBSV = sv_newmortal();
    if (lib) sv_setref_pv(LIBSV, "Affix::Lib", (DCpointer)lib);
    ST(0) = LIBSV;
    XSRETURN(1);
}

XS_INTERNAL(Affix_Lib_DESTROY) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$affix");
    DLLib *lib;
    lib = INT2PTR(DLLib *, SvIV(SvRV(ST(0))));
    if (lib) dlFreeLibrary(lib);
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_Lib_END) {
    dXSARGS;
    // TODO: Maybe force all libs to unload?
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_list_symbols) {
    /* dlSymsName(...) is not thread-safe on MacOS */
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$lib");
    AV *RETVAL;
    DLLib *lib;
    if (SvROK(ST(0))) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lib = INT2PTR(DLLib *, tmp);
    }
    else
        croak("lib is not of type Affix::Lib");
    RETVAL = newAV_mortal();
    char *name;
    Newxz(name, 1024, char);
    int len = dlGetLibraryPath(lib, name, 1024);
    if (len == 0) croak("Failed to get library name");
    DLSyms *syms = dlSymsInit(name);
    int count = dlSymsCount(syms);
    for (int i = 0; i < count; ++i) {
        const char *symbolName = dlSymsName(syms, i);
        if (strlen(symbolName)) av_push(RETVAL, newSVpv(symbolName, 0));
    }
    dlSymsCleanup(syms);
    safefree(name);
    ST(0) = newRV_noinc(MUTABLE_SV(RETVAL));
    XSRETURN(1);
}

XS_EXTERNAL(boot_Affix_Lib) {
    dVAR;
#ifdef USE_ITHREADS // Windows...
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif

    (void)newXSproto_portable("Affix::Lib::load_library", Affix_Lib_load_library, __FILE__, "$");
    (void)newXSproto_portable("Affix::Lib::DESTROY", Affix_Lib_DESTROY, __FILE__, "$;$");
    (void)newXSproto_portable("Affix::Lib::END", Affix_Lib_END, __FILE__, "$;$");
}
