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
    DCCallVM * cvm;
} my_cxt_t;

START_MY_CXT

extern "C" void Affix_trigger(pTHX_ CV * cv) {
    dXSARGS;

    Affix * affix = (Affix *)XSANY.any_ptr;

    dMY_CXT;
    DCCallVM * cvm = MY_CXT.cvm;
    // dcMode(cvm, DC_CALL_C_DEFAULT);
    dcReset(cvm);

    // TODO: Generate aggregate in type constructor

    if (affix->restype->aggregate != NULL)
        dcBeginCallAggr(cvm, affix->restype->aggregate);
    if (items != affix->argtypes.size())
        croak("Wrong number of arguments to %s; expected: %ld", affix->symbol.c_str(), affix->argtypes.size());

    size_t st_pos = 0;
    for (const auto & type : affix->argtypes) {
        // warn("[%d] %s [ptr:%d]", st_pos, type->stringify.c_str(), type->depth);
        if (type->depth > 0) {
            dcArgPointer(cvm,
                         sv2ptr(aTHX_ type,
                                new Affix_Pointer(type),  // XXX: Should this be here? Do I really need this?
                                ST(st_pos)));
            ++st_pos;
            continue;
        }
        switch (type->numeric) {
        case VOID_FLAG:

            break;  // ...skip?
        case BOOL_FLAG:
            dcArgBool(cvm, SvTRUE(ST(st_pos)));  // Anything can be a bool
            break;
        case CHAR_FLAG:
            {
                SV * arg = ST(st_pos);
                if (SvIOK(arg)) {
                    dcArgChar(cvm, (I8)SvIV(arg));
                } else {
                    STRLEN len;
                    char * value = SvPVbyte(arg, len);
                    if (len > 1) {
                        warn("Expected a single character; found %ld", len);
                    }
                    dcArgChar(cvm, (I8)value[0]);
                }
                break;
            }
        case UCHAR_FLAG:
            {
                SV * arg = ST(st_pos);
                if (SvIOK(arg)) {
                    dcArgChar(cvm, (U8)SvIV(arg));
                } else {
                    STRLEN len;
                    char * value = SvPVbyte(arg, len);
                    if (len > 1) {
                        warn("Expected a single unsigned character; found %ld", len);
                    }
                    dcArgChar(cvm, (U8)value[0]);
                }
                break;
            }
        case WCHAR_FLAG:
            {
                SV * arg = ST(st_pos);
                if (SvOK(arg)) {
                    wchar_t * str = utf2wchar(aTHX_ ST(st_pos), 1);
#if WCHAR_MAX == LONG_MAX
                    // dcArgLong(cvm, str[0]);
#elif WCHAR_MAX == INT_MAX
                    // dcArgInt(cvm, str[0]);
#elif WCHAR_MAX == SHORT_MAX
                    // dcArgShort(cvm, str[0]);
#else
                    // dcArgChar(cvm, str[0]);
#endif
                    dcArgLongLong(cvm, str[0]);
                    safefree(str);
                } else
                    dcArgLongLong(cvm, 0);
                break;
            }
        case SHORT_FLAG:
            dcArgShort(cvm, SvIV(ST(st_pos)));
            break;
        case USHORT_FLAG:
            dcArgShort(cvm, SvUV(ST(st_pos)));
            break;
        case INT_FLAG:
            dcArgInt(cvm, SvIV(ST(st_pos)));
            break;
        case UINT_FLAG:
            dcArgInt(cvm, SvUV(ST(st_pos)));
            break;
        case LONG_FLAG:
            dcArgLong(cvm, SvIV(ST(st_pos)));
            break;
        case ULONG_FLAG:
            dcArgLong(cvm, SvUV(ST(st_pos)));
            break;
        case LONGLONG_FLAG:
            dcArgLongLong(cvm, SvIV(ST(st_pos)));
            break;
        case ULONGLONG_FLAG:
            dcArgLongLong(cvm, SvUV(ST(st_pos)));
            break;
        case FLOAT_FLAG:
            dcArgFloat(cvm, SvNV(ST(st_pos)));
            break;
        case DOUBLE_FLAG:
            dcArgDouble(cvm, SvNV(ST(st_pos)));
            break;
        case WSTRING_FLAG:
            { /*
DCpointer ptr = NULL;
SV *arg = ST(st_pos);
if (SvOK(arg)) {
  if (a->temp_ptrs == NULL) Newxz(affix->temp_ptrs, num_args, DCpointer);
  affix->temp_ptrs[st_pos] =
      sv2ptr(aTHX_ MUTABLE_SV(affix->arg_info[arg_pos]), arg);
  ptr = *(DCpointer *)(affix->temp_ptrs[st_pos]);
}
dcArgPointer(cvm, ptr);*/
                break;
            }
        case STDSTRING_FLAG:
            {
                SV * arg = ST(st_pos);
                std::string tmp = SvOK(arg) ? SvPV_nolen(arg) : NULL;
                dcArgPointer(cvm, static_cast<void *>(&tmp));
                break;
            }
        case CODEREF_FLAG:
            {
                // dcArgPointer(cvm, sv2ptr(aTHX_ * av_fetch(affix->argtypes, st_pos, 0), ST(st_pos)));
                break;
            }

            //~ #define STRING_FLAG 'z'
            //~ #define WSTRING_FLAG '<'
            //~ #define STDSTRING_FLAG 'Y'
            //~ #define STRUCT_FLAG 'A'
            //~ #define CPPSTRUCT_FLAG 'B'
            //~ #define UNION_FLAG 'u'
            //~ #define ARRAY_FLAG '@'
            //~ #define CODEREF_FLAG '&'
        case POINTER_FLAG:
            {
                //~ sv_dump(*av_fetch(affix->argtypes, st_pos, 0));
                //~ sv_dump(AXT_TYPE_SUBTYPE(*av_fetch(affix->argtypes, st_pos, 0)));

                SV * const xsub_tmp_sv = ST(st_pos);
                SvGETMAGIC(xsub_tmp_sv);
                // dcArgPointer(cvm, sv2ptr(aTHX_ AXT_TYPE_SUBTYPE(*av_fetch(affix->argtypes, st_pos, 0)),
                //                          xsub_tmp_sv));
                break;
            }
        case STRUCT_FLAG:
            {
                //~ SV *type = *av_fetch(affix->argtypes, st_pos, 0);
                Affix_Type * type = affix->argtypes[st_pos];
                // dcArgAggr(cvm, _aggregate(aTHX_ type), sv2ptr(aTHX_ type, ST(st_pos)));
                break;
            }
        default:
            //~ sv_dump(*av_fetch(affix->argtypes, st_pos, 0));
            croak("Unhandled argument type: %s", type->stringify);
        }
        ++st_pos;
    }

    switch (affix->restype->numeric) {
    case VOID_FLAG:
        dcCallVoid(cvm, affix->entry_point);
        // sv_set_undef(affix->res);
        break;
    case BOOL_FLAG:
        sv_setsv(affix->res, boolSV(dcCallBool(cvm, affix->entry_point)));
        break;
    case CHAR_FLAG:
    case SCHAR_FLAG:
        {
            char value[1];
            value[0] = dcCallChar(cvm, affix->entry_point);
            sv_setsv(affix->res, newSVpv(value, 1));
            (void)SvUPGRADE(affix->res, SVt_PVIV);
            SvIV_set(affix->res, ((IV)value[0]));
            SvIOK_on(affix->res);
        }
        break;
    case UCHAR_FLAG:
        {
            char value[1];
            value[0] = dcCallChar(cvm, affix->entry_point);
            sv_setsv(affix->res, newSVpv(value, 1));
            (void)SvUPGRADE(affix->res, SVt_PVIV);
            SvIV_set(affix->res, ((UV)value[0]));
            SvIOK_on(affix->res);
        }
        break;
    case WCHAR_FLAG:
        {
            warn(
                "RETURNING WIDE "
                "CHAR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            wchar_t src[1];
            src[0] = (wchar_t)dcCallLongLong(cvm, affix->entry_point);
            affix->res = wchar2utf(aTHX_ src, 1);
        }
        break;
    case SHORT_FLAG:
        sv_setiv(affix->res, (short)dcCallShort(cvm, affix->entry_point));
        break;
    case USHORT_FLAG:
        sv_setuv(affix->res, (unsigned short)dcCallShort(cvm, affix->entry_point));
        break;
    case INT_FLAG:
        PING;

        sv_setiv(affix->res, dcCallInt(cvm, affix->entry_point));
        PING;

        break;
    case UINT_FLAG:
        sv_setuv(affix->res, dcCallInt(cvm, affix->entry_point));
        break;
    case LONG_FLAG:
        sv_setiv(affix->res, dcCallLong(cvm, affix->entry_point));
        break;
    case ULONG_FLAG:
        sv_setuv(affix->res, dcCallLong(cvm, affix->entry_point));
        break;
    case LONGLONG_FLAG:
        sv_setiv(affix->res, dcCallLongLong(cvm, affix->entry_point));
        break;
    case ULONGLONG_FLAG:
        sv_setuv(affix->res, dcCallLongLong(cvm, affix->entry_point));
        break;
    case FLOAT_FLAG:
        sv_setnv(affix->res, dcCallFloat(cvm, affix->entry_point));
        break;
    case DOUBLE_FLAG:
        sv_setnv(affix->res, dcCallDouble(cvm, affix->entry_point));
        break;

        //~ #define STRING_FLAG 'z'
        //~ #define WSTRING_FLAG '<'
        //~ #define STDSTRING_FLAG 'Y'
        //~ #define STRUCT_FLAG 'A'
        //~ #define CPPSTRUCT_FLAG 'B'
        //~ #define UNION_FLAG 'u'
        //~ #define ARRAY_FLAG '@'
        //~ #define CODEREF_FLAG '&'
        //~ #define POINTER_FLAG 'P'

    case POINTER_FLAG:
        /*{
            DCpointer ret = dcCallPointer(cvm, affix->entry_point);
            if (ret == NULL)
                sv_set_undef(affix->res);
            else {
                SV * subtype = AXT_TYPE_SUBTYPE(affix->restype);
                char subtype_c = AXT_TYPE_NUMERIC(subtype);
                switch (subtype_c) {
                case CHAR_FLAG:
                case UCHAR_FLAG:
                case SCHAR_FLAG:
                case WCHAR_FLAG:
                case SV_FLAG:
                    sv_setsv(affix->res, sv_2mortal(ptr2sv(aTHX_ affix->restype, ret)));
                    break;
                default:
                    sv_setsv(affix->res, sv_2mortal(ptr2obj(aTHX_ affix->restype, ret)));
                }
            }
        }*/
        break;
    case CODEREF_FLAG:
        /*{
            DCpointer ret = dcCallPointer(cvm, affix->entry_point);
            sv_setsv(affix->res, sv_2mortal(ptr2sv(aTHX_ affix->restype, ret)));
        }*/
        break;
    case STRUCT_FLAG:
        /*{
            DCpointer ret = safecalloc(1, AXT_TYPE_SIZEOF(affix->restype));
            dcCallAggr(cvm, affix->entry_point, ret_aggr, ret);
            //~ DumpHex(ret, AXT_TYPE_SIZEOF(affix->restype));
            SV * HOLD = ptr2sv(aTHX_ affix->restype, ret);
            //~ sv_setsv(affix->res, sv_2mortal(MUTABLE_SV(HOLD)));
            affix->res = sv_2mortal(HOLD);
        }*/
        break;
    default:
        croak("Unknown or unhandled return type: %s", affix->restype->stringify);
    };
    if (affix->res == NULL)
        XSRETURN_EMPTY;
    PING;

    ST(0) = affix->res;
    PING;

    XSRETURN(1);
}

XS_INTERNAL(Affix_affix) {
    // ix == 0 if Affix::affix
    // ix == 1 if Affix::wrap
    dXSARGS;
    dXSI32;
    Affix * affix = new Affix();
    std::string prototype;

    if (items != 4)
        croak_xs_usage(cv, "$lib, $symbol, \\@arguments, $return");

    {  // lib, ..., ..., ...
        SV * const lib_sv = ST(0);
        SvGETMAGIC(lib_sv);
        // explicit undef
        if (UNLIKELY(!SvOK(lib_sv) && SvREADONLY(lib_sv)))
            affix->lib = _affix_load_library(NULL);

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
                char * _name = POPp;
                affix->lib = _affix_load_library(_name);
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }

        if (affix->lib == NULL) {  // bail out if we fail to load library
            delete affix;
            XSRETURN_EMPTY;
        }
    }

    {                        // ..., symbol, ..., ...
        std::string rename;  // affix(...) allows you to change the name of the perlsub
        if (ix == 0 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
            SV ** symbol_sv = av_fetch(MUTABLE_AV(SvRV(ST(1))), 0, 0);
            SV ** rename_sv = av_fetch(MUTABLE_AV(SvRV(ST(1))), 1, 0);
            if (symbol_sv == NULL || !SvPOK(*symbol_sv))
                croak("Unknown or malformed symbol name");
            affix->symbol = SvPV_nolen(*symbol_sv);
            if (rename_sv && SvPOK(*rename_sv))
                rename = SvPV_nolen(*rename_sv);
            affix->entry_point = dlFindSymbol(affix->lib, SvPV_nolen(*symbol_sv));
        } else
            affix->symbol = rename = SvPV_nolen(ST(1));

        affix->entry_point = dlFindSymbol(affix->lib, affix->symbol.c_str());
        if (!affix->entry_point) {
            croak("Failed to locate symbol named %s", affix->symbol.c_str());
            delete affix;
        }

        STMT_START {
            cv = newXSproto_portable(ix == 0 ? rename.c_str() : NULL, Affix_trigger, __FILE__, prototype.c_str());
            if (affix->symbol.empty())
                affix->symbol = "anonymous subroutine";
            if (UNLIKELY(cv == NULL))
                croak("ARG! Something went really wrong while installing a new XSUB!");
            XSANY.any_ptr = (DCpointer)affix;
        }
        STMT_END;
    }

    {  // ..., ..., args, ...
        if (LIKELY(SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVAV)) {
            AV * av_args = MUTABLE_AV(SvRV(ST(2)));
            size_t num_args = av_count(av_args);
            if (num_args) {
                SV ** sv_type = av_fetch(av_args, 0, 0);
                Affix_Type * afx_type;
                if (sv_type &&
                    LIKELY(SvROK(*sv_type) && sv_derived_from(*sv_type, "Affix::Type"))) {  // Expect simple list
                    for (size_t i = 0; i < num_args; i++) {
                        sv_type = av_fetch(av_args, i, 0);
                        if (sv_type && LIKELY(SvROK(*sv_type) && sv_derived_from(*sv_type, "Affix::Type"))) {
                            prototype += '$';
                            afx_type = sv2type(aTHX_ * sv_type);
                            affix->argtypes.push_back(afx_type);
                        }
                    }
                } else {  // Expect named pairs
                    if (num_args % 2)
                        croak("Expected an even sized list in argument list");
                    SV **sv_name, **sv_type;
                    for (size_t i = 0; i < num_args; i += 2) {
                        sv_name = av_fetch(av_args, i, 0);
                        sv_type = av_fetch(av_args, i + 1, 0);
                        if (sv_type && LIKELY(SvROK(*sv_type) && sv_derived_from(*sv_type, "Affix::Type"))) {
                            prototype += '$';
                            afx_type = sv2type(aTHX_ * sv_type);
                            afx_type->field = SvPV_nolen(*sv_name);
                            affix->argtypes.push_back(afx_type);
                        }
                    }
                }
            }
        } else
            croak("Malformed argument list");
    }
    {
        // ..., ..., ..., ret
        if (LIKELY((ST(3)) && SvROK(ST(3)) && sv_derived_from(ST(3), "Affix::Type"))) {
            affix->restype = sv2type(aTHX_ ST(3));
            if (!(sv_derived_from(ST(3), "Affix::Type::Void") && affix->restype->depth == 0))
                affix->res = newSV(0);
        } else
            croak("Unknown return type");
    }

    ST(0) = sv_2mortal(sv_bless((UNLIKELY(ix == 1) ? newRV_noinc(MUTABLE_SV(cv)) : newRV_inc(MUTABLE_SV(cv))),
                                gv_stashpv("Affix", GV_ADD)));
    XSRETURN(1);
}

XS_INTERNAL(Affix_DESTROY) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix * affix;
    STMT_START {  // peel this grape
        HV * st;
        GV * gvp;
        SV * const xsub_tmp_sv = ST(0);
        SvGETMAGIC(xsub_tmp_sv);
        CV * cv = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
        affix = (Affix *)XSANY.any_ptr;
    }
    STMT_END;
    if (affix != NULL)
        delete affix;
    affix = NULL;
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_END) {
    dXSARGS;
    dMY_CXT;
    if (MY_CXT.cvm)
        dcFree(MY_CXT.cvm);
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_pin) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "lib");
}

XS_INTERNAL(Affix_unpin) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "lib");
}

// Utils
XS_INTERNAL(Affix_sv_dump) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "$sv");
    sv_dump(ST(0));
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_sv2ptr) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "$type, $sv");
    Affix_Pointer * ret = new Affix_Pointer(sv2type(aTHX_ ST(0)));
    ret->address = sv2ptr(aTHX_ ret->type, ret, ST(1));
    warn(">>>>> %p", ret->address);
    if (ret->address == nullptr) {
        delete ret;
        XSRETURN_EMPTY;
    }
    {
        SV * RETVAL = newRV_noinc(newSViv(PTR2IV(ret)));  // Create a reference to the AV
        sv_bless(RETVAL, gv_stashpvn("Affix::Pointer::Unmanaged", 25, GV_ADD));
        ST(0) = sv_2mortal(RETVAL);
    }
    XSRETURN(1);
}

XS_INTERNAL(Affix_ptr2sv) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "$type, $ptr");
    Affix_Type * type = sv2type(aTHX_ ST(0));
    if (UNLIKELY(!sv_derived_from(ST(1), "Affix::Pointer")))
        croak("Expected an Affix::Pointer object");
    Affix_Pointer * ptr = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(1))));
    warn("<<<<< %p", ptr->address);
    ST(0) = ptr2sv(aTHX_ type, ptr->address);
    XSRETURN(1);
}

// Cribbed from Perl::Destruct::Level so leak testing works without yet another prereq
XS_INTERNAL(Affix_set_destruct_level) {
    dXSARGS;
    // TODO: report this with a warn(...)
    if (items != 1)
        croak_xs_usage(cv, "level");
    PL_perl_destruct_level = SvIV(ST(0));
    XSRETURN_EMPTY;
}

XS_EXTERNAL(boot_Affix) {
    dXSBOOTARGSXSAPIVERCHK;
    // PERL_UNUSED_VAR(items);
#ifdef USE_ITHREADS  // Windows...
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif

    MY_CXT_INIT;

    // Allow user defined value in a BEGIN{ } block
    SV * vmsize = get_sv("Affix::VMSize", 0);
    MY_CXT.cvm = dcNewCallVM(vmsize == NULL ? 8192 : SvIV(vmsize));
    dcMode(MY_CXT.cvm, DC_CALL_C_DEFAULT);
    dcReset(MY_CXT.cvm);

    // Start exposing API
    // Affix::affix( lib, symbol, [args], return )
    //             ( [lib, version], symbol, [args], return )
    //             ( lib, [symbol, name], [args], return )
    //             ( [lib, version], [symbol, name], [args], return )
    cv = newXSproto_portable("Affix::affix", Affix_affix, __FILE__, "$$$$");
    XSANY.any_i32 = 0;
    export_function("Affix", "affix", "core");
    // Affix::wrap(  lib, symbol, [args], return )
    //             ( [lib, version], symbol, [args], return )
    cv = newXSproto_portable("Affix::wrap", Affix_affix, __FILE__, "$$$$");
    XSANY.any_i32 = 1;
    export_function("Affix", "wrap", "core");
    // Affix::DESTROY( affix )
    (void)newXSproto_portable("Affix::DESTROY", Affix_DESTROY, __FILE__, "$;$");
    // Affix::END( )
    (void)newXSproto_portable("Affix::END", Affix_END, __FILE__, "");

    // Affix Utils!
    // Affix::set_destruct_level
    (void)newXSproto_portable("Affix::set_destruct_level", Affix_set_destruct_level, __FILE__, "$");
    // Affix::sv2ptr( type, sv )
    (void)newXSproto_portable("Affix::sv2ptr", Affix_sv2ptr, __FILE__, "$$");
    // Affix::ptr2sv( type, ptr )
    (void)newXSproto_portable("Affix::ptr2sv", Affix_ptr2sv, __FILE__, "$$");

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
    boot_Affix_Pointer(aTHX_ cv);
    //
    Perl_xs_boot_epilog(aTHX_ ax);
}
