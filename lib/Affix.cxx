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

XS_INTERNAL(Affix_affix) { // and Affix::wrap
    dXSARGS;
    dXSI32;
    // ix == 0 if affix
    // ix == 1 if wrap
    Affix *affix = new Affix();
    std::string prototype;
    switch (items) {
    case 4:
        // ..., ..., ..., ret
        if (LIKELY((ST(3)) && SvROK(ST(3)) && sv_derived_from(ST(3), "Affix::Type")))
            affix->restype = INT2PTR(Affix_Type *, SvIV(SvRV(ST(3))));
        else
            croak("Unknown return type");
        // fallthrough
    case 3:
        // ..., ..., args
        if (items == 3)
            affix->restype =
                new Affix_Type("Void", VOID_FLAG, 0, 0); // Default ret type is Void (for now)
        if (LIKELY(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV)) {
            AV *av_args = MUTABLE_AV(SvRV(ST(2)));
            size_t num_args = av_count(av_args);
            if (num_args) {
                if (num_args % 2) croak("Expected an even sized list in argument list");
                SV **sv_arg_name_ptr, **sv_arg_type_ptr = av_fetch(av_args, 0, 0);
                Affix_Type *afx_type;
                if (sv_arg_type_ptr &&
                    LIKELY(
                        SvROK(*sv_arg_type_ptr) &&
                        sv_derived_from(*sv_arg_type_ptr, "Affix::Type"))) { // Expect simple list
                    for (size_t i = 0; i < num_args; i++) {
                        sv_arg_type_ptr = av_fetch(av_args, i, 0);
                        if (sv_arg_type_ptr &&
                            LIKELY(SvROK(*sv_arg_type_ptr) &&
                                   sv_derived_from(*sv_arg_type_ptr, "Affix::Type"))) {
                            prototype += '$';
                            afx_type = INT2PTR(Affix_Type *, SvIV(SvRV(*sv_arg_type_ptr)));
                            affix->argtypes.push_back(afx_type);
                        }
                    }
                }
                else { // Expect named pairs
                    for (size_t i = 0; i < num_args; i += 2) {
                        sv_arg_name_ptr = av_fetch(av_args, i, 0);
                        sv_arg_type_ptr = av_fetch(av_args, i + 1, 0);
                        if (sv_arg_type_ptr &&
                            LIKELY(SvROK(*sv_arg_type_ptr) &&
                                   sv_derived_from(*sv_arg_type_ptr, "Affix::Type"))) {
                            prototype += '$';
                            afx_type = INT2PTR(Affix_Type *, SvIV(SvRV(*sv_arg_type_ptr)));
                            afx_type->field = SvPV_nolen(*sv_arg_name_ptr);
                            affix->argtypes.push_back(afx_type);
                        }
                    }
                }
            }
        }
        else
            croak("Malformed argument list");
    // fallthrough
    case 2:
        // lib, symbol
        if (items == 2) {
            affix->context_args = true;
            prototype = "@";
        } // Use context to figure out arg types
        { // lib might be...
            if (LIKELY(SvROK(ST(0)) && sv_derived_from(ST(0), "Affix::Lib"))) {
                //  ... Affix::Lib object
            }
            // ... filename (might even be an object that stringifies)
            // ... a libname (which we'll need to figure out)
            // ... a libname and version (which we'll need to figure out)
            // ... explicit undef (current process)
        }

        warn("two");
        break;
    default:
        delete affix;
        croak_xs_usage(cv, "$lib, $symbol, $arguments // [], $return // Void");
    }

    warn("prototype: %s", prototype.c_str());

    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_DESTROY) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "$affix");
    Affix *affix;
    affix = INT2PTR(Affix *, SvIV(SvRV(ST(0))));
    if (affix) delete affix;
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_END) {
    dXSARGS;
    dMY_CXT;
    if (MY_CXT.cvm) dcFree(MY_CXT.cvm);
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_pin) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "lib");
}

XS_INTERNAL(Affix_unpin) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "lib");
}

// Utils
XS_INTERNAL(Affix_sv_dump) {
    dVAR;
    dXSARGS;
    if (items != 1) croak_xs_usage(cv, "lib");
}

// Cribbed from Perl::Destruct::Level so leak testing works without yet another prereq
XS_INTERNAL(Affix_set_destruct_level) {
    dVAR;
    dXSARGS;
    // TODO: report this with a warn(...)
    if (items != 1) croak_xs_usage(cv, "level");
    PL_perl_destruct_level = SvIV(ST(0));
    XSRETURN_EMPTY;
}

XS_EXTERNAL(boot_Affix) {
    dVAR;
    dXSBOOTARGSXSAPIVERCHK;
    // PERL_UNUSED_VAR(items);
#ifdef USE_ITHREADS // Windows...
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif

    MY_CXT_INIT;

    // Allow user defined value in a BEGIN{ } block
    SV *vmsize = get_sv("Affix::VMSize", 0);
    MY_CXT.cvm = dcNewCallVM(vmsize == NULL ? 8192 : SvIV(vmsize));

    // Start exposing API
    // Affix::affix( lib, symbol, [args], return )
    //             ( [lib, version], symbol, [args], return )
    //             ( [lib, version], [symbol, name], [args], return )
    //             ( lib, symbol, [args] ) // default return type is Void
    //             ( lib, symbol ) // use context for parameters, return type is Void
    EXPI(Affix_affix, "Affix::affix", "$$;$$", "default", 0);
    // Affix::wrap(  lib, symbol, [args], return )
    //             ( [lib, version], symbol, [args], return )
    //             ( lib, symbol, [args] ) // default return type is Void
    //             ( lib, symbol ) // use context for parameters, return type is Void
    EXPI(Affix_affix, "Affix::wrap", "$$;$$", "default", 1);
    // Affix::DESTROY( affix )
    EX(Affix_DESTROY, "Affix::DESTROY", "$;$");
    // Affix::END( )
    EX(Affix_END, "Affix::END", "");

    // EXP_I(Affix_affix, "wrap", "$$;$$", "default", 1);

    // boot other packages
    boot_Affix_Lib(aTHX_ cv);
    boot_Affix_Platform(aTHX_ cv);
    boot_Affix_Type(aTHX_ cv);
    //
    Perl_xs_boot_epilog(aTHX_ ax);
}
