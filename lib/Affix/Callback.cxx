#include "../Affix.h"

DCsigchar cbHandler(DCCallback * cb, DCArgs * args, DCValue * result, DCpointer userdata) {
    PERL_UNUSED_VAR(cb);
    auto afxcb = (Affix_Callback *)userdata;
    dTHXa(afxcb->perl);
    char restype_c = afxcb->type->restype->numeric;
    // if (afxcb->cv == nullptr || !SvPOK(afxcb->cv))
    //     return DC_SIGCHAR_VOID;
    {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, (int)afxcb->type->subtypes.size());

        for (const auto & type : afxcb->type->subtypes) {  
            if (type->depth) {
                mPUSHs(ptr2sv(aTHX_ type, dcbArgPointer(args)));
                continue;
            }

            switch (type->numeric) {
            case VOID_FLAG:
                // ...skip?
                break;
            case BOOL_FLAG:
                mPUSHs(boolSV(dcbArgBool(args)));
                break;
            case CHAR_FLAG:
                {
                    char value[1];
                    value[0] = dcbArgChar(args);
                    SV * sv = newSVpvn_flags(value, 1, SVs_TEMP);
                    (void)SvUPGRADE(sv, SVt_PVIV);
                    SvIV_set(sv, ((IV)value[0]));
                    SvIOK_on(sv);
                    PUSHs(sv);
                }
                break;
            case UCHAR_FLAG:
                {
                    char value[1];
                    value[0] = dcbArgChar(args);
                    SV * sv = newSVpvn_flags(value, 1, SVs_TEMP);
                    (void)SvUPGRADE(sv, SVt_PVIV);
                    SvIV_set(sv, ((UV)value[0]));
                    SvIOK_on(sv);
                    PUSHs(sv);
                }
                break;
            case WCHAR_FLAG:
                {
                    wchar_t * c;
                    Newxz(c, 1, wchar_t);
                    c[0] = (wchar_t)dcbArgLong(args);
                    SV * w = wchar2utf(aTHX_ c, 1);
                    SvUPGRADE(w, SVt_PVNV);
                    SvIVX(w) = SvIV(newSViv(c[0]));
                    SvIOK_on(w);
                    PUSHs(w);
                    safefree(c);
                }
                break;
            case SHORT_FLAG:
                mPUSHs(newSViv(dcbArgShort(args)));
                break;
            case USHORT_FLAG:
                mPUSHs(newSVuv(dcbArgShort(args)));
                break;
            case INT_FLAG:
                mPUSHs(newSViv(dcbArgInt(args)));
                break;
            case UINT_FLAG:
                mPUSHs(newSVuv(dcbArgInt(args)));
                break;
            case LONG_FLAG:
                mPUSHs(newSViv(dcbArgLong(args)));
                break;
            case ULONG_FLAG:
                mPUSHs(newSVuv(dcbArgLong(args)));
                break;
            case LONGLONG_FLAG:
                mPUSHs(newSViv(dcbArgLongLong(args)));
                break;
            case ULONGLONG_FLAG:
                mPUSHs(newSVuv(dcbArgLongLong(args)));
                break;
            case FLOAT_FLAG:
                mPUSHs(newSVnv(dcbArgFloat(args)));
                break;
            case DOUBLE_FLAG:
                mPUSHs(newSVnv(dcbArgDouble(args)));
                break;


                //~ #define STRING_FLAG 'z'
                //~ #define WSTRING_FLAG '<'
                //~ #define STDSTRING_FLAG 'Y'
                //~ #define STRUCT_FLAG 'A'
                //~ #define CPPSTRUCT_FLAG 'B'
                //~ #define UNION_FLAG 'u'
                //~ #define ARRAY_FLAG '@'
                //~ #define CODEREF_FLAG '&'


            /*case DC_SIGCHAR_POINTER:
                {
                    DCpointer ptr = dcbArgPointer(args);
                    if (ptr != NULL) {
                        switch (type->numeric) {
                        case CODEREF_FLAG:
                            mPUSHs(((Affix_Callback *)dcbGetUserData((DCCallback *)ptr))->cv);
                            break;
                        default:
                            mPUSHs(ptr2sv(aTHX_ type, ptr));
                            break;
                        }
                    } else {
                        mPUSHs(newSV(0));
                    }
                }
                break;*/
            case DC_SIGCHAR_STRING:
                {
                    DCpointer ptr = dcbArgPointer(args);
                    PUSHs(newSVpv((char *)ptr, 0));
                }
                break;
            case WSTRING_FLAG:
                {
                    DCpointer ptr = dcbArgPointer(args);
                    mPUSHs(ptr2sv(aTHX_ type, ptr));
                }
                break;
            //~ case DC_SIGCHAR_INSTANCEOF: {
            //~ DCpointer ptr = dcbArgPointer(args);
            //~ HV *blessed = MUTABLE_HV(SvRV(*av_fetch(cbx->args, i, 0)));
            //~ SV **package = hv_fetchs(blessed, "package", 0);
            //~ PUSHs(sv_setref_pv(newSV(1), SvPV_nolen(*package), ptr));
            //~ } break;
            //~ case DC_SIGCHAR_ENUM:
            //~ case DC_SIGCHAR_ENUM_UINT: {
            //~ PUSHs(enum2sv(aTHX_ * av_fetch(cbx->args, i, 0), dcbArgInt(args)));
            //~ } break;
            //~ case DC_SIGCHAR_ENUM_CHAR: {
            //~ PUSHs(enum2sv(aTHX_ * av_fetch(cbx->args, i, 0), dcbArgChar(args)));
            //~ } break;
            //~ case DC_SIGCHAR_ANY: {
            //~ DCpointer ptr = dcbArgPointer(args);
            //~ SV *sv = newSV(0);
            //~ if (ptr != NULL && SvOK(MUTABLE_SV(ptr))) { sv = MUTABLE_SV(ptr); }
            //~ PUSHs(sv);
            //~ } break;
            default:
                croak("Unhandled callback arg. Type: %c [%s]", type->numeric, afxcb->signature.c_str());
                break;
            }
        }

        PING;

        PUTBACK;
        PING;


        if (restype_c == DC_SIGCHAR_VOID) {
            call_sv(afxcb->cv, G_DISCARD);
            restype_c = DC_SIGCHAR_VOID;
        } else {
            int count = call_sv(afxcb->cv, G_SCALAR);
            SPAGAIN;

            if (count != 1)
                warn("Big trouble: callback returned %d items", count);

                
 if (afxcb->type->restype->depth) {
                        result->p = sv2ptr(aTHX_ afxcb->type->restype, POPs);
                    restype_c = DC_SIGCHAR_POINTER;
 }
 else
            switch (restype_c) {
            case BOOL_FLAG:
                result->B = SvTRUEx(POPs);
                restype_c = DC_SIGCHAR_BOOL;
                break;
            case CHAR_FLAG:
            case SCHAR_FLAG:
                {
                    SV * sv = POPs;
                    result->c = SvIOK(sv) ? SvIV(sv) : (char)*SvPV_nolen(sv);
                    restype_c = DC_SIGCHAR_CHAR;
                }
                break;
            case UCHAR_FLAG:
                {
                    SV * sv = POPs;
                    result->C = SvIOK(sv) ? SvUV(sv) : (unsigned char)*SvPV_nolen(sv);
                    restype_c = DC_SIGCHAR_UCHAR;
                }
                break;
            case WCHAR_FLAG:
                {
                    SV * sv = POPs;
                    if (SvPOK(sv)) {
                        STRLEN len;
                        (void)SvPVutf8x(sv, len);
                        wchar_t * wc = utf2wchar(aTHX_ sv, len);
                        result->j = wc[0];
                        safefree(wc);
                    } else {
                        result->j = 0;
                    }
                    restype_c = DC_SIGCHAR_LONG;  // Fake it
                }
                break;
            case SHORT_FLAG:
                result->s = POPi;
                restype_c = DC_SIGCHAR_SHORT;
                break;
            case USHORT_FLAG:
                result->S = POPi;
                restype_c = DC_SIGCHAR_USHORT;
                break;
            case INT_FLAG:
                result->i = POPi;
                restype_c = DC_SIGCHAR_INT;
                break;
            case UINT_FLAG:
                result->I = POPi;
                restype_c = DC_SIGCHAR_UINT;
                break;
            case LONG_FLAG:
                result->j = POPl;
                restype_c = DC_SIGCHAR_LONG;
                break;
            case ULONG_FLAG:
                result->J = POPi;
                restype_c = DC_SIGCHAR_ULONG;
                break;
            case LONGLONG_FLAG:
                result->l = POPl;
                restype_c = DC_SIGCHAR_LONGLONG;
                break;
            case ULONGLONG_FLAG:
                result->L = POPi;
                restype_c = DC_SIGCHAR_ULONGLONG;
                break;
            case FLOAT_FLAG:
                result->f = POPn;
                restype_c = DC_SIGCHAR_FLOAT;
                break;
            case DOUBLE_FLAG:
                result->d = POPn;
                restype_c = DC_SIGCHAR_DOUBLE;
                break;
                //~ #define STRING_FLAG 'z'
                //~ #define WSTRING_FLAG '<'
                //~ #define STDSTRING_FLAG 'Y'
                //~ #define STRUCT_FLAG 'A'
                //~ #define CPPSTRUCT_FLAG 'B'
                //~ #define UNION_FLAG 'u'
                //~ #define ARRAY_FLAG '@'
                //~ #define CODEREF_FLAG '&'
          
                //~ #define SV_FLAG '?'
            default:
                croak("Attempt to return unknown or unhandled type from CodeRef: %s",
                      afxcb->type->restype->stringify.c_str());
                break;
            }
        }
        PING;

        PUTBACK;
        PING;

        FREETMPS;
        LEAVE;
        PING;
    }

    return restype_c;
}

XS_INTERNAL(Affix_Callback_DESTROY) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    IV ptr_iv = CvXSUBANY(SvRV(ST(0))).any_iv;
    auto cb = INT2PTR(DCCallback *, ptr_iv);
    auto afxcb = (Affix_Callback *)dcbGetUserData(cb);
    delete afxcb;
    afxcb = nullptr;
    dcbFreeCallback(cb);
    cb = nullptr;
    XSRETURN_EMPTY;
};

void boot_Affix_Callback(pTHX_ CV * cv) {
    PERL_UNUSED_VAR(cv);

    (void)newXSproto_portable("Affix::Callback::DESTROY", Affix_Callback_DESTROY, __FILE__, "$");
}
