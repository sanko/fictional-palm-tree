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

bool init_resetvm(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcReset(cvm);
    return false;
}
bool init_aggregate(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcBeginCallAggr(cvm, affix->restype->aggregate);
    return false;
}
bool push_void(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    // Nothing to do here...
    return true;
}
bool pop_void(pTHX_ Affix * affix, DCCallVM * cvm) {
    dcCallVoid(cvm, affix->entry_point);
    //~ sv_set_undef(affix->res);
    return false;
}
bool push_bool(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgBool(cvm, SvTRUE(sv));  // Anything can be a bool
    return true;
}
bool pop_bool(pTHX_ Affix * affix, DCCallVM * cvm) {
    sv_setbool(affix->res, boolSV(dcCallBool(cvm, affix->entry_point)));
    return true;
}
bool push_char(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    if (SvIOK(sv)) {
        dcArgChar(cvm, (I8)SvIV(sv));
    } else {
        STRLEN len;
        char * value = SvPVbyte(sv, len);
        if (len > 1) {
            warn("Expected a single character; found %ld", len);
        }
        dcArgChar(cvm, (I8)value[0]);
    }

    return true;
}
bool pop_char(pTHX_ Affix * affix, DCCallVM * cvm) {
    char value[1];
    value[0] = dcCallChar(cvm, affix->entry_point);
    sv_setsv(affix->res, newSVpv(value, 1));
    (void)SvUPGRADE(affix->res, SVt_PVIV);
    SvIV_set(affix->res, ((IV)value[0]));
    // SvIOK_on(affix->res);
    return true;
}
bool push_uchar(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    if (SvIOK(sv)) {
        dcArgChar(cvm, (U8)SvIV(sv));
    } else {
        STRLEN len;
        char * value = SvPVbyte(sv, len);
        if (len > 1) {
            warn("Expected a single unsigned character; found %ld", len);
        }
        dcArgChar(cvm, (U8)value[0]);
    }
    return true;
}
bool pop_uchar(pTHX_ Affix * affix, DCCallVM * cvm) {
    char value[1];
    value[0] = dcCallChar(cvm, affix->entry_point);
    sv_setsv(affix->res, newSVpv(value, 1));
    (void)SvUPGRADE(affix->res, SVt_PVIV);
    SvUV_set(affix->res, ((UV)value[0]));
    // SvIOK_on(affix->res);
    return true;
}
bool push_wchar(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    if (SvOK(sv)) {
        wchar_t * str = utf2wchar(aTHX_ sv, 1);
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
    return true;
}
bool pop_wchar(pTHX_ Affix * affix, DCCallVM * cvm) {
    wchar_t src[1];
    src[0] = (wchar_t)dcCallLongLong(cvm, affix->entry_point);
    affix->res = wchar2utf(aTHX_ src, 1);
    return true;
}
bool push_short(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgShort(cvm, SvIV(sv));
    return true;
}
bool pop_short(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvIV_set(affix->res, (short)dcCallShort(cvm, affix->entry_point));
    return true;
}
bool push_ushort(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgShort(cvm, SvUV(sv));
    return true;
}
bool pop_ushort(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvUV_set(affix->res, (unsigned short)dcCallShort(cvm, affix->entry_point));
    return true;
}
bool push_int(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgInt(cvm, SvIV(sv));
    return true;
}
bool pop_int(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvIV_set(affix->res, dcCallInt(cvm, affix->entry_point));
    return true;
}
bool push_uint(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgInt(cvm, SvUV(sv));
    return true;
}
bool pop_uint(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvUV_set(affix->res, (unsigned int)dcCallInt(cvm, affix->entry_point));
    return true;
}
bool push_long(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgLong(cvm, SvIV(sv));
    return true;
}
bool pop_long(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvIV_set(affix->res, dcCallLong(cvm, affix->entry_point));
    return true;
}
bool push_ulong(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgLong(cvm, SvUV(sv));
    return true;
}
bool pop_ulong(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvUV_set(affix->res, dcCallLong(cvm, affix->entry_point));
    return true;
}
bool push_longlong(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgLongLong(cvm, SvIV(sv));
    return true;
}
bool pop_longlong(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvIV_set(affix->res, dcCallLongLong(cvm, affix->entry_point));
    return true;
}
bool push_ulonglong(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgLongLong(cvm, SvUV(sv));
    return true;
}
bool pop_ulonglong(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvUV_set(affix->res, dcCallLongLong(cvm, affix->entry_point));
    return true;
}
bool push_float(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    SvNV_set(affix->res, dcCallFloat(cvm, affix->entry_point));
    return true;
}
bool pop_float(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvUV_set(affix->res, dcCallLongLong(cvm, affix->entry_point));
    return true;
}
bool push_double(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    dcArgDouble(cvm, SvNV(sv));
    return true;
}
bool pop_double(pTHX_ Affix * affix, DCCallVM * cvm) {
    SvNV_set(affix->res, dcCallDouble(cvm, affix->entry_point));
    return true;
}
bool push_wstring(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    sv_dump(sv);
    return true;
}
bool pop_wstring(pTHX_ Affix * affix, DCCallVM * cvm) {
    return false;
}
bool push_stdstring(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    std::string tmp = SvOK(sv) ? SvPV_nolen(sv) : NULL;
    dcArgPointer(cvm, static_cast<void *>(&tmp));
    return true;
}
bool pop_stdstring(pTHX_ Affix * affix, DCCallVM * cvm) {
    return false;
}
bool push_pointer(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    //~ dSP;
    //~ dAXMARK;
    dcArgPointer(cvm, sv2ptr(aTHX_ affix->subtypes[st_pos], sv));
    return true;
}
bool pop_pointer(pTHX_ Affix * affix, DCCallVM * cvm) {
    DCpointer ret = dcCallPointer(cvm, affix->entry_point);
    //~ if (ret == NULL)
    //~ sv_set_undef(affix->res);
    //~ else
    sv_setsv(affix->res, sv_2mortal(ptr2sv(aTHX_ affix->restype, ret)));
    return true;
}
bool push_struct(pTHX_ Affix * affix, DCCallVM * cvm, SV * sv, size_t st_pos) {
    //~ dSP;
    //~ dAXMARK;
    PING;
    sv_dump(sv);
    //~ SV *type = *av_fetch(affix->subtypes, st_pos, 0);
    //~ Affix_Type * type = affix->subtypes[st_pos];
    // dcArgAggr(cvm, _aggregate(aTHX_ type), sv2ptr(aTHX_ type, ST(st_pos)));
    return true;
}
bool pop_struct(pTHX_ Affix * affix, DCCallVM * cvm) {
    /*{
           DCpointer ret = safecalloc(1, AXT_TYPE_SIZEOF(affix->restype));
           dcCallAggr(cvm, affix->entry_point, ret_aggr, ret);
           //~ DumpHex(ret, AXT_TYPE_SIZEOF(affix->restype));
           SV * HOLD = ptr2sv(aTHX_ affix->restype, ret);
           //~ sv_setsv(affix->res, sv_2mortal(MUTABLE_SV(HOLD)));
           affix->res = sv_2mortal(HOLD);
       }*/
    return false;
}

extern "C" void Affix_trigger(pTHX_ CV * cv) {
    dXSARGS;
    Affix * affix = (Affix *)XSANY.any_ptr;

    if (items != affix->subtypes.size())
        croak("Wrong number of arguments to %s; expected: %ld, found %d",
              affix->symbol.c_str(),
              affix->subtypes.size(),
              items);

    dMY_CXT;
    DCCallVM * cvm = MY_CXT.cvm;

    size_t st_pos = 0;
    for (auto && fn : affix->push_pointers)
        if (fn(aTHX_ affix, cvm, ST(st_pos), st_pos))
            st_pos++;

    /*
        for (const auto & type : affix->subtypes) {
            // warn("[%d] %s [ptr:%d]", st_pos, type->stringify.c_str(), type->depth);
            if (type->depth) {
                if (SvROK(ST(st_pos)) && sv_derived_from(ST(st_pos), "Affix::Pointer")) {
                    Affix_Pointer * pointer = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(st_pos))));
                    dcArgPointer(cvm, pointer->address);  // Even if it's NULL
                } else {
                    dcArgPointer(cvm, sv2ptr(aTHX_ type, ST(st_pos)));
                }
                ++st_pos;
                continue;
            }
        }*/

    /*if (affix->restype->depth)
        sv_setsv(affix->res, ptr2sv(aTHX_ affix->restype, dcCallPointer(cvm, affix->entry_point), 1));
    else */
    if (!affix->pop_pointer(aTHX_ affix, cvm))
        XSRETURN_EMPTY;
    ST(0) = affix->res;
    PL_stack_sp = PL_stack_base + ax;  //~ XSRETURN(1);
    return;
}

XS_INTERNAL(Affix_affix) {
    // ix == 0 if Affix::affix
    // ix == 1 if Affix::wrap
    dXSARGS;
    dXSI32;
    Affix * affix = new Affix();

    affix->push_pointers.push_back(init_resetvm);

    std::string prototype;
    std::string rename;  // affix(...) allows you to change the name of the perlsub

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
    {  // ..., symbol, ..., ...
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
    }
    {
        // ..., ..., ..., ret
        if (LIKELY((ST(3)) && SvROK(ST(3)) && sv_derived_from(ST(3), "Affix::Type"))) {
            affix->restype = sv2type(aTHX_ ST(3));
            if (affix->restype->aggregate != nullptr)
                affix->push_pointers.push_back(init_aggregate);
            if (affix->restype->depth != 0) {
                affix->pop_pointer = pop_pointer;
                affix->res = newSV(0);
            } else
                switch (affix->restype->numeric) {
                case VOID_FLAG:
                    affix->pop_pointer = pop_void;
                    affix->res = newSV(0);
                    break;
                case BOOL_FLAG:
                    affix->pop_pointer = pop_bool;
                    affix->res = newSVbool(0);
                    break;
                case CHAR_FLAG:
                case SCHAR_FLAG:
                    affix->pop_pointer = pop_char;
                    affix->res = newSViv(0);
                    break;
                case UCHAR_FLAG:
                    affix->pop_pointer = pop_uchar;
                    affix->res = newSVuv(0);
                    break;
                case WCHAR_FLAG:
                    affix->pop_pointer = pop_wchar;
                    affix->res = newSViv(0);
                    break;
                case SHORT_FLAG:
                    affix->pop_pointer = pop_short;
                    affix->res = newSViv(0);
                    break;
                case USHORT_FLAG:
                    affix->pop_pointer = pop_ushort;
                    affix->res = newSVuv(0);
                    break;
                case INT_FLAG:
                    affix->pop_pointer = pop_int;
                    affix->res = newSViv(0);
                    break;
                case UINT_FLAG:
                    affix->pop_pointer = pop_uint;
                    affix->res = newSVuv(0);
                    break;
                case LONG_FLAG:
                    affix->pop_pointer = pop_long;
                    affix->res = newSViv(0);
                    break;
                case ULONG_FLAG:
                    affix->pop_pointer = pop_ulong;
                    affix->res = newSVuv(0);
                    break;
                case LONGLONG_FLAG:
                    affix->pop_pointer = pop_longlong;
                    affix->res = newSViv(0);
                    break;
                case ULONGLONG_FLAG:
                    affix->pop_pointer = pop_ulonglong;
                    affix->res = newSVuv(0);
                    break;
                case FLOAT_FLAG:
                    affix->pop_pointer = pop_float;
                    affix->res = newSVnv(0);
                    break;
                case DOUBLE_FLAG:
                    affix->pop_pointer = pop_double;
                    affix->res = newSVnv(0);
                    break;
                case WSTRING_FLAG:
                    affix->pop_pointer = pop_wstring;
                    affix->res = newSV(0);
                    break;
                case STDSTRING_FLAG:
                    affix->pop_pointer = pop_stdstring;
                    affix->res = newSV(0);
                    break;
                case POINTER_FLAG:  // Actually handled above but...
                    affix->pop_pointer = pop_pointer;
                    affix->res = newSV(0);
                    break;
                case STRUCT_FLAG:
                    affix->pop_pointer = pop_struct;
                    affix->res = newSV(0);
                    break;
                default:
                    croak("Unknown or unhandled return type: %s", affix->restype->stringify.c_str());
                    // XXX: This should be a fatal error?
                    //~ affix->pop_pointer = pop_int;
                    //~ affix->res = newSV(0);
                    break;
                }
        } else
            croak("Unknown return type");
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
                            if (sv_derived_from(*sv_type, "Affix::Type::CodeRef"))
                                prototype += '&';
                            else
                                prototype += '$';
                            afx_type = sv2type(aTHX_ * sv_type);
                            affix->subtypes.push_back(afx_type);
                            if (afx_type->depth)
                                affix->push_pointers.push_back(push_pointer);
                            else
                                switch (afx_type->numeric) {
                                case VOID_FLAG:
                                    affix->push_pointers.push_back(push_void);
                                    break;
                                case BOOL_FLAG:
                                    affix->push_pointers.push_back(push_bool);
                                    break;
                                case CHAR_FLAG:
                                    affix->push_pointers.push_back(push_char);
                                    break;
                                case UCHAR_FLAG:
                                    affix->push_pointers.push_back(push_uchar);
                                    break;
                                case WCHAR_FLAG:
                                    affix->push_pointers.push_back(push_wchar);
                                    break;
                                case SHORT_FLAG:
                                    affix->push_pointers.push_back(push_short);
                                    break;
                                case USHORT_FLAG:
                                    affix->push_pointers.push_back(push_ushort);
                                    break;
                                case INT_FLAG:
                                    affix->push_pointers.push_back(push_int);
                                    break;
                                case UINT_FLAG:
                                    affix->push_pointers.push_back(push_uint);
                                    break;
                                case LONG_FLAG:
                                    affix->push_pointers.push_back(push_long);
                                    break;
                                case ULONG_FLAG:
                                    affix->push_pointers.push_back(push_ulong);
                                    break;
                                case LONGLONG_FLAG:
                                    affix->push_pointers.push_back(push_longlong);
                                    break;
                                case ULONGLONG_FLAG:
                                    affix->push_pointers.push_back(push_ulonglong);
                                    break;
                                case FLOAT_FLAG:
                                    affix->push_pointers.push_back(push_float);
                                    break;
                                case DOUBLE_FLAG:
                                    affix->push_pointers.push_back(push_double);
                                    break;
                                case WSTRING_FLAG:
                                    affix->push_pointers.push_back(push_wstring);
                                    break;
                                case STDSTRING_FLAG:
                                    affix->push_pointers.push_back(push_stdstring);
                                    break;
                                case CODEREF_FLAG:  // Should be a CV* stuffed in a wrapper
                                case POINTER_FLAG:  // Should be handled way up there based on depth
                                    affix->push_pointers.push_back(push_pointer);
                                    break;
                                case STRUCT_FLAG:
                                    affix->push_pointers.push_back(push_struct);
                                    break;
                                case CPPSTRUCT_FLAG:
                                case UNION_FLAG:
                                default:
                                    croak("Unhandled argument type: %s", afx_type->stringify.c_str());
                                }
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
                            if (sv_derived_from(*sv_type, "Affix::Type::CodeRef"))
                                prototype += '&';
                            else
                                prototype += '$';
                            afx_type = sv2type(aTHX_ * sv_type);
                            afx_type->field = SvPV_nolen(*sv_name);
                            affix->subtypes.push_back(afx_type);
                        }
                    }
                }
            }
        } else
            croak("Malformed argument list");
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
    if (MY_CXT.cvm) {
        dcReset(MY_CXT.cvm);
        dcFree(MY_CXT.cvm);
    }
    XSRETURN_EMPTY;
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
    Affix_Pointer * ret = new Affix_Pointer(sv2type(aTHX_ ST(0)), sv2ptr(aTHX_ ret->type, ST(1)));
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

#include "proto.h"

// TESTING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
XS_INTERNAL(Affix_Test_Type_Int) {
    dXSARGS;
    if (items != 0)
        croak_xs_usage(cv, "");

    /*
    {
        SV * RETVAL = newRV_noinc(newSViv(PTR2IV(ret)));  // Create a reference to the AV
        sv_bless(RETVAL, gv_stashpvn("Affix::Pointer", 14, GV_ADD));
        ST(0) = sv_2mortal(RETVAL);
    }
    XSRETURN(1);*/
    XSRETURN_EMPTY;
}

//~ typedef DCpointer (*push_field)(pTHX_ Affix_Type *, SV *, size_t, DCpointer);
//~ typedef SV * (*pop_field)(pTHX_ Affix_Type *, DCpointer, size_t);

DCpointer push_int(pTHX_ Affix_Type *, SV *, size_t, DCpointer) {}

XS_INTERNAL(Affix_Test_Struct) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "$type");
    warn("here A");
    SSize_t size = (SSize_t)0;
    warn("here B");

    std::vector<SSize_t> lengths;
    warn("here C");

    lengths.push_back(size);
    warn("here D");

    Affix_Type * ret = sv2type(aTHX_ ST(0));
    warn("here E");

    std::unordered_map<std::string, push_field> m;
    for (const auto & subtype : ret->subtypes)
        m[subtype->field] = push_int;

    for (const auto & [key, value] : m)
        warn("...field %s", key.c_str());

    for (const auto & subtype : ret->subtypes) {
        const char * name = subtype->field.c_str();
        warn("field %s;", name);
    }
    warn("here Z");

    /*
    if (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
                // DD(data);
                HV * hv_struct = MUTABLE_HV(SvRV(data));
                if (target == nullptr)
                    target = safecalloc(type->size, SIZEOF_CHAR);
                for (const auto & subtype : type->subtypes) {
                    const char * name = subtype->field.c_str();
                    SV ** ptr_field = hv_fetch(hv_struct, name, strlen(name), 0);
                    if (ptr_field == nullptr)
                        croak("Expected field '%s' is missing", name);
                    DCpointer slot = INT2PTR(DCpointer, (int)subtype->offset + PTR2IV(target));

                    sv2ptr(aTHX_ subtype, *ptr_field, depth, slot);
                    // sv_dump(*ptr_field);
                    _pin(aTHX_ SvREFCNT_inc_NN(*ptr_field), subtype, slot);
                    // sv_dump(*ptr_field);
                }
            } else
                target = nullptr;  // ???: malloc full sized block instead?
            break;
            */


    /*
    Affix_Pointer * ret = new Affix_Pointer(sv2type(aTHX_ ST(0)), sv2ptr(aTHX_ ret->type, ST(1)));
    warn(">>>>> %p", ret->address);
    if (ret->address == nullptr) {
        delete ret;
        XSRETURN_EMPTY;
    }
    */
    {
        SV * RETVAL = newRV_noinc(newSViv(PTR2IV(ret)));  // Create a reference to the AV
        sv_bless(RETVAL, gv_stashpvn("Affix::Pointer::Unmanaged", 14, GV_ADD));
        ST(0) = sv_2mortal(RETVAL);
    }
    XSRETURN(1);
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

    // dcReset(MY_CXT.cvm);

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
    // Affix::sv_dump( sv )
    (void)newXSproto_portable("Affix::sv_dump", Affix_sv_dump, __FILE__, "$");

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


    // Testing!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    (void)newXSproto_portable("Affix::Test::Struct", Affix_Test_Struct, __FILE__, "$");
    (void)newXSproto_portable("Affix::Test::Type", Affix_Test_Type_Int, __FILE__, "");


    // boot other packages
    boot_Affix_Lib(aTHX_ cv);
    boot_Affix_Platform(aTHX_ cv);
    boot_Affix_Pointer(aTHX_ cv);
    boot_Affix_pin(aTHX_ cv);
    boot_Affix_Callback(aTHX_ cv);
    //
    Perl_xs_boot_epilog(aTHX_ ax);
}
