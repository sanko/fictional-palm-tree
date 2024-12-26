#include "../Affix.h"


DCpointer int2ptr(pTHX_ Affix_Type * type, SV * sv, size_t depth, DCpointer target) {

    return target;
}

SV * ptr2int(pTHX_ Affix_Type * type, DCpointer target, size_t depth) {

    return newSV(0);
}


DCpointer sv2ptr(pTHX_ Affix_Type * type, SV * data, size_t depth, DCpointer target) {
    // Do I really need the Affix_Pointer here? I'm really only after ptr->count
    // DD(data);
    if (depth < type->depth) {
        AV * list = MUTABLE_AV(SvRV(data));
        size_t length = av_count(list);
        if (target == nullptr)
            Newxz(target, length + 1, intptr_t);
        DCpointer next;
        SV ** _tmp;
        for (size_t i = 0; i < length; i++) {
            _tmp = av_fetch(list, i, 0);
            if (UNLIKELY(_tmp == nullptr))
                break;
            next = sv2ptr(aTHX_ type, *_tmp, depth + 1);
            Copy(&next, INT2PTR(intptr_t *, PTR2IV(target) + (i * SIZEOF_INTPTR_T)), 1, intptr_t);
        }
        return target;
    }
    switch (type->numeric) {
    case VOID_FLAG:
        if (SvOK(data)) {
            SV * const xsub_tmp_sv = data;
            SvGETMAGIC(xsub_tmp_sv);
            if ((SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVAV &&
                 sv_derived_from(xsub_tmp_sv, "Affix::Pointer"))) {
                SV * ptr_sv = AXT_POINTER_ADDR(xsub_tmp_sv);
                if (SvOK(ptr_sv)) {
                    IV tmp = SvIV(MUTABLE_SV(SvRV(ptr_sv)));
                    target = INT2PTR(DCpointer, tmp);
                }
            } else if (SvTYPE(data) != SVt_NULL) {
                size_t len = 0;
                DCpointer ptr_ = SvPVbyte(data, len);
                if (target == NULL)
                    Newxz(target, len, char);
                Copy(ptr_, target, len, char);
            } else
                croak("Data type mismatch for %s [%d]", type->stringify.c_str(), SvTYPE(data));
        }
        break;
        /*
#define VOID_FLAG 'v'
#define BOOL_FLAG 'b'
#define SCHAR_FLAG 'a'*/
    case CHAR_FLAG:
        if (SvOK(data)) {
            /*
            SV * const xsub_tmp_sv = data;
            SvGETMAGIC(xsub_tmp_sv);
            if ((SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVAV &&
                 sv_derived_from(xsub_tmp_sv, "Affix::Pointer"))) {
                SV * ptr_sv = AXT_POINTER_ADDR(xsub_tmp_sv);
                if (SvOK(ptr_sv)) {
                    IV tmp = SvIV(MUTABLE_SV(SvRV(ptr_sv)));
                    target = INT2PTR(DCpointer, tmp);
                }
            } else if (SvTYPE(data) != SVt_NULL) {
            */
            size_t len = 0;
            DCpointer ptr_ = SvPVbyte(data, len);
            if (target == NULL)
                Newxz(target, len + 1, char);
            Copy(ptr_, target, len, char);
            /*
        } else
            croak("Data type mismatch for %s [%d]", type->stringify.c_str(), SvTYPE(data));
        */
        }
        break;
        /*
#define UCHAR_FLAG 'h'
#define WCHAR_FLAG 'w'
#define SHORT_FLAG 's'
#define USHORT_FLAG 't'
*/
    case INT_FLAG:
        if (LIKELY(SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVAV)) {
            AV * list = MUTABLE_AV(SvRV(data));
            size_t length = av_count(list);
            if (target == nullptr)
                Newxz(target, length + 1, int);
            IV ptr_iv = PTR2IV(target);
            int n;
            SV ** _tmp;
            for (size_t i = 0; i < length; i++) {
                _tmp = av_fetch(list, i, 0);
                if (UNLIKELY(_tmp == nullptr))
                    break;
                n = SvIV(*_tmp);
                Copy(&n, INT2PTR(int *, ptr_iv + (i * SIZEOF_INT)), 1, int);
            }
        } else if (UNLIKELY(SvIOK(data))) {
            if (target == nullptr)
                Newxz(target, 1, int);
            int n = SvIV(data);
            Copy(&n, target, 1, int);
        } else if (UNLIKELY(!SvOK(data)))
            warn("Data type mismatch for %s [%d]", type->stringify.c_str(), SvTYPE(data));
        break;
    case UINT_FLAG:
        if (LIKELY(SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVAV)) {
            AV * list = MUTABLE_AV(SvRV(data));
            size_t length = av_count(list);
            if (target == nullptr)
                Newxz(target, length + 1, int);
            UV ptr_iv = PTR2UV(target);
            unsigned int n;
            SV ** _tmp;
            for (size_t i = 0; i < length; i++) {
                _tmp = av_fetch(list, i, 0);
                if (UNLIKELY(_tmp == nullptr))
                    break;
                n = SvUV(*_tmp);
                Copy(&n, INT2PTR(int *, ptr_iv + (i * SIZEOF_UINT)), 1, unsigned int);
            }
        } else if (UNLIKELY(SvUOK(data))) {
            if (target == nullptr)
                Newxz(target, 1, unsigned int);
            unsigned int n = SvUV(data);
            Copy(&n, target, 1, unsigned int);
        } else if (UNLIKELY(!SvOK(data)))
            warn("Data type mismatch for %s [%d]", type->stringify.c_str(), SvTYPE(data));
        break;

        /*
        #define LONG_FLAG 'l'
        #define ULONG_FLAG 'm'
        #define LONGLONG_FLAG 'x'
        #define ULONGLONG_FLAG 'y'
        #if SIZEOF_SIZE_T == INTSIZE
        #define SIZE_T_FLAG UINT_FLAG
        #elif SIZEOF_SIZE_T == LONGSIZE
        #define SIZE_T_FLAG ULONG_FLAG
        #elif SIZEOF_SIZE_T == LONGLONGSIZE
        #define SIZE_T_FLAG ULONGLONG_FLAG
        #else  // quadmath is broken
        #define SIZE_T_FLAG ULONGLONG_FLAG
        #endif
        #define FLOAT_FLAG 'f'
        #define DOUBLE_FLAG 'd'
        // #define STRING_FLAG 'z'
        #define WSTRING_FLAG '<'
        #define STDSTRING_FLAG 'Y'
        #define STRUCT_FLAG 'A'
        */

    case STRUCT_FLAG:
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

        /*
         #define CPPSTRUCT_FLAG 'B'
         #define UNION_FLAG 'u'
         #define AFFIX_FLAG '@'
         */
    case CODEREF_FLAG:
        target = cv2dcb(aTHX_(Affix_Type *) type, data);
        break;
        /*
        #define POINTER_FLAG 'P'
        #define SV_FLAG '?'
        */
    default:
        croak("TODO: sv2ptr for everything else [%c]", type->numeric);
    }
    return target;
}

SV * bless_ptr(pTHX_ DCpointer ptr, Affix_Type * type, const char * package) {
    return sv_setref_pv(newSV(0), package, (DCpointer) new Affix_Pointer(type, ptr));
}

SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer target, size_t depth) {
#if DEBUG > 1
// warn(
//     "SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer target = %p, size_t depth = %d); [type->depth == "
//     "%d][type->length.size "
//     "== %d][type->length.at(%d) == %d]",
//     target,
//     depth,
//     type->depth,
//     type->length.size(),
//     depth - 1,
//     type->length.at(depth - 1));
#endif
    if (type->length.at(depth - 1) == -1)  // -1 comes from Affix::Type::Pointer
        return bless_ptr(aTHX_ target, type);
    if (depth < type->depth) {
        // DumpHex(target, 64);
        AV * tmp = newAV();
        IV ptr_iv = PTR2IV(target);
        int n = 0;

        while (1) {
            DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INTPTR_T * n));
            if (now == nullptr) {
                // return newRV_inc(MUTABLE_SV(tmp));
                break;
            }
            if (n >= type->length.at(depth - 1))
                break;
            av_push(tmp, ptr2sv(aTHX_ type, *(DCpointer *)now, depth + 1));
            n++;
        }
        return newRV_inc(MUTABLE_SV(tmp));
    }
    IV ptr_iv = PTR2IV(target);
    SV * ret = newSV(0);
    switch (type->numeric) {
    case VOID_FLAG:
        sv_setsv(ret, bless_ptr(aTHX_ target, type));
        break;
    case INT_FLAG:
        if (depth == type->depth && type->length.at(depth - 1) == 1)
            return newSViv(*(int *)target);
        {
            AV * ret_av = newAV_mortal();
            for (auto n = 0; n < type->length.at(depth - 1); ++n) {
                DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INT * n));
                if (now == nullptr)
                    return newSV(0);
                av_push(MUTABLE_AV(ret_av), newSViv(*(int *)now));
            }
            sv_setsv(ret, newRV_inc(MUTABLE_SV(ret_av)));
        }
        break;
    case UINT_FLAG:
        if (depth == type->depth && type->length.at(depth - 1) == 1)
            return newSVuv(*(unsigned int *)target);
        {
            AV * ret_av = newAV_mortal();
            for (auto n = 0; n < type->length.at(depth - 1); ++n) {
                DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_UINT * n));
                if (now == nullptr)
                    return newSV(0);
                av_push(MUTABLE_AV(ret_av), newSVuv(*(unsigned int *)now));
            }
            sv_setsv(ret, newRV_inc(MUTABLE_SV(ret_av)));
        }
        break;
    default:
        croak("oh, okay... I need to finish ptr2sv");
    };
    return ret;
}

DCCallback * cv2dcb(pTHX_ Affix_Type * type, SV * cb) {
    DCCallback * ret = NULL;
    // TODO: Be smart. Check that cb != undef, a CV*, etc.
    auto afxcb = new Affix_Callback(type, SvREFCNT_inc(cb));
    storeTHX(afxcb->perl);
    ret = dcbNewCallback(
        "ii)v", cbHandler, afxcb);  // TODO: generate (somewhat) correct signature even though we don't use it?
    return ret;
}
