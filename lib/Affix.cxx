#include "Affix.h"
/*
G|-------------------0----------------|--0---4----------------------------||
D|.----------0---3-------0---3---0----|----------3---0-------0---3---0---.||
A|.------2----------------------------|----------------------------------.||
E|---3--------------------------------|------------------3----------------||
*/
/* globals */
#define MY_CXT_KEY "Affix::_cxt" XS_VERSION

typedef struct {
    DCCallVM *cvm;
} my_cxt_t;

START_MY_CXT

extern "C" void Fiction_trigger(pTHX_ CV *cv) {
    dXSARGS;

    Affix *affix = (Affix *)XSANY.any_ptr;

    dMY_CXT;
    DCCallVM *cvm = MY_CXT.cvm;
    dcMode(cvm, DC_CALL_C_DEFAULT);
    dcReset(cvm);

    // TODO: Generate aggregate in type constructor

    if (affix->restype->aggregate != NULL) dcBeginCallAggr(cvm, affix->restype->aggregate);
    if (items != affix->argtypes.size())
        croak("Wrong number of arguments to %s; expected: %ld", affix->symbol.c_str(),
              affix->argtypes.size());

    size_t st_pos = 0;
    for (const auto &type : affix->argtypes) {
        // warn("[%d] %s", st_pos, type->stringify());
        switch (type->numeric) {
        case VOID_FLAG:
        case BOOL_FLAG:
        case CHAR_FLAG:
        case UCHAR_FLAG:
        case SHORT_FLAG:
        case USHORT_FLAG:
        case INT_FLAG:
        case UINT_FLAG:
        case LONG_FLAG:
        case ULONG_FLAG:
        case LONGLONG_FLAG:
        case ULONGLONG_FLAG:
            croak("TODO: %s", type->stringify());
            break;
        case FLOAT_FLAG:
            dcArgFloat(cvm, (float)SvNV(ST(st_pos)));
            break;
        case DOUBLE_FLAG:
            dcArgDouble(cvm, (double)SvNV(ST(st_pos)));
            break;
        default:
            croak("No idea yet.");
        }

        ++st_pos;
    }

    switch (affix->restype->numeric) {
    case DOUBLE_FLAG:
        sv_setnv(affix->res, dcCallDouble(cvm, affix->entry_point));
        break;
    default:
        croak("Ofdsafdasfdsa");
    }

    if (affix->res == NULL) XSRETURN_EMPTY;

    ST(0) = newSVsv(affix->res);

    XSRETURN(1);
}

XS_INTERNAL(Affix_affix) {
    // ix == 0 if Affix::affix
    // ix == 1 if Affix::wrap
    dXSARGS;
    dXSI32;
    Affix *affix = new Affix();
    std::string prototype;

    if (items != 4) croak_xs_usage(cv, "$lib, $symbol, \\@arguments, $return");

    { // lib, ..., ..., ...
        SV *const lib_sv = ST(0);
        SvGETMAGIC(lib_sv);
        // explicit undef
        if (UNLIKELY(!SvOK(lib_sv) && SvREADONLY(lib_sv))) affix->lib = _affix_load_library(NULL);

        // object - not sure why someone would do this...
        else if (UNLIKELY(sv_isobject(lib_sv) && sv_derived_from(lib_sv, "Affix::Lib")))
            affix->lib = INT2PTR(DLLib *, SvIV((SV *)SvRV(lib_sv)));

        // try treating it as a filename and then search for it as a last resort
        else if (NULL == (affix->lib = _affix_load_library(SvPV_nolen(lib_sv)))) {
            Stat_t statbuf;
            Zero(&statbuf, 1, Stat_t);
            if (PerlLIO_stat(SvPV_nolen(lib_sv), &statbuf) < 0) {
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(lib_sv);
                PUTBACK;
                int count = call_pv("Affix::find_library", G_SCALAR);
                SPAGAIN;
                char *_name = POPp;
                affix->lib = _affix_load_library(_name);
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }

        if (affix->lib == NULL) { // bail out if we fail to load library
            delete affix;
            XSRETURN_EMPTY;
        }
    }

    {                       // ..., symbol, ..., ...
        std::string rename; // affix(...) allows you to change the name of the perlsub
        if (ix == 0 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
            SV **symbol_sv = av_fetch(MUTABLE_AV(SvRV(ST(1))), 0, 0);
            SV **rename_sv = av_fetch(MUTABLE_AV(SvRV(ST(1))), 1, 0);
            if (symbol_sv == NULL || !SvPOK(*symbol_sv)) croak("Unknown or malformed symbol name");
            affix->symbol = SvPV_nolen(*symbol_sv);
            if (rename_sv && SvPOK(*rename_sv)) rename = SvPV_nolen(*rename_sv);
            affix->entry_point = dlFindSymbol(affix->lib, SvPV_nolen(*symbol_sv));
        }
        else
            affix->symbol = rename = SvPV_nolen(ST(1));

        affix->entry_point = dlFindSymbol(affix->lib, affix->symbol.c_str());
        if (!affix->entry_point) {
            croak("Failed to locate symbol named %s", affix->symbol.c_str());
            delete affix;
        }

        STMT_START {
            cv = newXSproto_portable(ix == 0 ? rename.c_str() : NULL, Fiction_trigger, __FILE__,
                                     prototype.c_str());
            if (affix->symbol.empty()) affix->symbol = "anonymous subroutine";
            if (UNLIKELY(cv == NULL))
                croak("ARG! Something went really wrong while installing a new XSUB!");
            XSANY.any_ptr = (DCpointer)affix;
        }
        STMT_END;
    }

    { // ..., ..., args, ...
        if (LIKELY(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV)) {
            AV *av_args = MUTABLE_AV(SvRV(ST(2)));
            size_t num_args = av_count(av_args);
            if (num_args) {
                SV **sv_type = av_fetch(av_args, 0, 0);
                Affix_Type *afx_type;
                if (sv_type &&
                    LIKELY(SvROK(*sv_type) &&
                           sv_derived_from(*sv_type, "Affix::Type"))) { // Expect simple list
                    for (size_t i = 0; i < num_args; i++) {
                        sv_type = av_fetch(av_args, i, 0);
                        if (sv_type &&
                            LIKELY(SvROK(*sv_type) && sv_derived_from(*sv_type, "Affix::Type"))) {
                            prototype += '$';
                            afx_type = sv2type(aTHX_ * sv_type);
                            affix->argtypes.push_back(afx_type);
                        }
                    }
                }
                else { // Expect named pairs
                    if (num_args % 2) croak("Expected an even sized list in argument list");
                    SV **sv_name, **sv_type;
                    for (size_t i = 0; i < num_args; i += 2) {
                        sv_name = av_fetch(av_args, i, 0);
                        sv_type = av_fetch(av_args, i + 1, 0);
                        if (sv_type &&
                            LIKELY(SvROK(*sv_type) && sv_derived_from(*sv_type, "Affix::Type"))) {
                            prototype += '$';
                            afx_type = sv2type(aTHX_ * sv_type);
                            afx_type->field = SvPV_nolen(*sv_name);
                            affix->argtypes.push_back(afx_type);
                        }
                    }
                }
            }
        }
        else
            croak("Malformed argument list");
    }
    {
        // ..., ..., ..., ret
        if (LIKELY((ST(3)) && SvROK(ST(3)) && sv_derived_from(ST(3), "Affix::Type"))) {
            affix->restype = sv2type(aTHX_ ST(3));
            if (!(sv_derived_from(ST(3), "Affix::Type::Void") &&
                  affix->restype->pointer_depth == 0))
                affix->res = newSV(0);
        }
        else
            croak("Unknown return type");
    }

    ST(0) = sv_2mortal(
        sv_bless((UNLIKELY(ix == 1) ? newRV_noinc(MUTABLE_SV(cv)) : newRV_inc(MUTABLE_SV(cv))),
                 gv_stashpv("Affix", GV_ADD)));
    XSRETURN(1);
}

XS_INTERNAL(Affix_DESTROY) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix *affix;
    STMT_START { // peel this grape
        HV *st;
        GV *gvp;
        SV *const xsub_tmp_sv = ST(0);
        SvGETMAGIC(xsub_tmp_sv);
        CV *cv = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
        affix = (Affix *)XSANY.any_ptr;
    }
    STMT_END;
    if (affix != NULL) delete affix;
    affix = NULL;
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_END) {
    dXSARGS;
    dMY_CXT;
    if (MY_CXT.cvm) dcFree(MY_CXT.cvm);
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_pin) {
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "lib");
}

XS_INTERNAL(Affix_unpin) {
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "lib");
}

// Utils
XS_INTERNAL(Affix_sv_dump) {
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "lib");
}

// Cribbed from Perl::Destruct::Level so leak testing works without yet another prereq
XS_INTERNAL(Affix_set_destruct_level) {
    dXSARGS;
    // TODO: report this with a warn(...)
    if (items != 1) croak_xs_usage(cv, "level");
    PL_perl_destruct_level = SvIV(ST(0));
    XSRETURN_EMPTY;
}

XS_EXTERNAL(boot_Affix) {
    dXSBOOTARGSXSAPIVERCHK;
    // PERL_UNUSED_VAR(items);
#ifdef USE_ITHREADS // Windows...
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif

    MY_CXT_INIT;

    // Allow user defined value in a BEGIN{ } block
    SV *vmsize = get_sv("Affix::VMSize", 0);
    MY_CXT.cvm = dcNewCallVM(vmsize == NULL ? 8192 : SvIV(vmsize));
    dcMode(MY_CXT.cvm, DC_CALL_C_DEFAULT);
    dcReset(MY_CXT.cvm);

    // Start exposing API
    // Affix::affix( lib, symbol, [args], return )
    //             ( [lib, version], symbol, [args], return )
    //             ( [lib, version], [symbol, name], [args], return )
    //             ( lib, symbol, [args] ) // default return type is Void
    //             ( lib, symbol ) // use context for parameters, return type is Void
    cv = newXSproto_portable("Affix::affix", Affix_affix, __FILE__, "$$;$$");
    XSANY.any_i32 = 0;
    export_function("Affix", "affix", "core");
    // Affix::wrap(  lib, symbol, [args], return )
    //             ( [lib, version], symbol, [args], return )
    //             ( lib, symbol, [args] ) // default return type is Void
    //             ( lib, symbol ) // use context for parameters, return type is Void
    cv = newXSproto_portable("Affix::wrap", Affix_affix, __FILE__, "$$;$$");
    XSANY.any_i32 = 1;
    export_function("Affix", "wrap", "core");
    // Affix::DESTROY( affix )
    (void)newXSproto_portable("Affix::DESTROY", Affix_DESTROY, __FILE__, "$;$");
    // Affix::END( )
    (void)newXSproto_portable("Affix::END", Affix_END, __FILE__, "");

    // Affix::set_destruct_level
    (void)newXSproto_portable("Affix::set_destruct_level", Affix_set_destruct_level, __FILE__, "$");

    // general purpose flags
    export_constant("Affix", "VOID_FLAG", "flags", VOID_FLAG);
    export_constant("Affix", "BOOL_FLAG", "flags", BOOL_FLAG);
    export_constant("Affix", "SCHAR_FLAG", "flags", SCHAR_FLAG);
    export_constant("Affix", "CHAR_FLAG", "flags", CHAR_FLAG);
    export_constant("Affix", "UCHAR_FLAG", "flags", UCHAR_FLAG);
    export_constant("Affix", "WCHAR_FLAG", "flags", WCHAR_FLAG);
    export_constant("Affix", "SHORT_FLAG", "flags", SHORT_FLAG);
    export_constant("Affix", "USHORT_FLAG", "flags", USHORT_FLAG);
    export_constant("Affix", "INT_FLAG", "flags", INT_FLAG);
    export_constant("Affix", "UINT_FLAG", "flags", UINT_FLAG);
    export_constant("Affix", "LONG_FLAG", "flags", LONG_FLAG);
    export_constant("Affix", "ULONG_FLAG", "flags", ULONG_FLAG);
    export_constant("Affix", "LONGLONG_FLAG", "flags", LONGLONG_FLAG);
    export_constant("Affix", "ULONGLONG_FLAG", "flags", ULONGLONG_FLAG);
    export_constant("Affix", "SIZE_T_FLAG", "flags", SIZE_T_FLAG);
    export_constant("Affix", "FLOAT_FLAG", "flags", FLOAT_FLAG);
    export_constant("Affix", "DOUBLE_FLAG", "flags", DOUBLE_FLAG);
    export_constant("Affix", "WSTRING_FLAG", "flags", WSTRING_FLAG);
    export_constant("Affix", "STDSTRING_FLAG", "flags", STDSTRING_FLAG);
    export_constant("Affix", "STRUCT_FLAG", "flags", STRUCT_FLAG);
    export_constant("Affix", "AFFIX_FLAG", "flags", AFFIX_FLAG);
    export_constant("Affix", "CPPSTRUCT_FLAG", "flags", CPPSTRUCT_FLAG);
    export_constant("Affix", "UNION_FLAG", "flags", UNION_FLAG);
    export_constant("Affix", "CODEREF_FLAG", "flags", CODEREF_FLAG);
    export_constant("Affix", "POINTER_FLAG", "flags", POINTER_FLAG);
    export_constant("Affix", "SV_FLAG", "flags", SV_FLAG);

    // boot other packages
    boot_Affix_Lib(aTHX_ cv);
    boot_Affix_Platform(aTHX_ cv);
    //
    Perl_xs_boot_epilog(aTHX_ ax);
}
