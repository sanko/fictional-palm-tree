#include "../Affix.h"

DLLib *_affix_load_library(const char *lib) {
    return
#if defined(DC__OS_Win64) || defined(DC__OS_MacOSX)
        dlLoadLibrary(lib);
#else
        (DLLib *)dlopen(lib, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
}

std::string _affix_dlerror() {
    return dlerror();
}

XS_INTERNAL(Affix_Lib_load_library) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$lib");
    DLLib *lib = _affix_load_library(SvPV_nolen(ST(0)));
    if (!lib) croak("Failed to load lib: %s", _affix_dlerror().c_str());
    SV *LIBSV = sv_newmortal();
    sv_setref_pv(LIBSV, NULL, (DCpointer)lib);
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

XS_INTERNAL(Affix_find_library) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$lib");
}

XS_INTERNAL(Affix_find_symbol) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$lib");
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

    EX(Affix_Lib_load_library, "Affix::Lib::load_library", "$");
    EX(Affix_Lib_DESTROY, "Affix::Lib::DESTROY", "$;$");
    EX(Affix_Lib_END, "Affix::Lib::END", "$;$");
}
