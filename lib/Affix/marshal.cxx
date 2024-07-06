#include "../Affix.h"

DCpointer sv2ptr(pTHX_ Affix_Type * type, Affix_Pointer * ptr, SV * data, size_t depth, DCpointer target) {
    // Do I really need the Affix_Pointer here? I'm really only after ptr->count
    // DD(data);
    if (depth < type->depth) {
        AV * list = MUTABLE_AV(SvRV(data));
        size_t length = av_count(list);
        IV ptr_iv = PTR2IV(target);
        if (target == nullptr)
            Newxz(target, length + 1, intptr_t);
        DCpointer next;
        SV ** _tmp;
        for (auto i = 0; i < length; i++) {
            _tmp = av_fetch(list, i, 0);
            if (UNLIKELY(_tmp == nullptr))
                break;
            next = sv2ptr(aTHX_ type, ptr, *_tmp, depth + 1);
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
                DCpointer ptr = SvPVbyte(data, len);
                if (target == NULL)
                    Newxz(target, len, char);
                Copy(ptr, target, len, char);
            } else
                croak("Data type mismatch for %s [%d]", type->stringify.c_str(), SvTYPE(data));
        }
        break;
        /*
#define VOID_FLAG 'v'
#define BOOL_FLAG 'b'
#define SCHAR_FLAG 'a'
#define CHAR_FLAG 'c'
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
            for (auto i = 0; i < length; i++) {
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
        /*
        #define UINT_FLAG 'j'
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
        #define CPPSTRUCT_FLAG 'B'
        #define UNION_FLAG 'u'
        #define AFFIX_FLAG '@'
        */
    case CODEREF_FLAG:
        target = cv2dcb(aTHX_ type, data);
        break;
        /*
        #define POINTER_FLAG 'P'
        #define SV_FLAG '?'
        */


    default:
        croak("TODO: sv2ptr for everything else");
    }
    return target;
}

SV * bless_ptr(pTHX_ DCpointer ptr, Affix_Type * type, const char * package) {
    return sv_setref_pv(newSV(0), package, (DCpointer) new Affix_Pointer(type, ptr));
}

SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer target, size_t depth, bool wantlist) {
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
        return bless_ptr(aTHX_ target, type, "Affix::Pointer");
    if (depth < type->depth) {
        // DumpHex(target, 64);
        AV * tmp = newAV();
        IV ptr_iv = PTR2IV(target);
        size_t n = 0;

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
            for (size_t n = 0; n < type->length.at(depth - 1); ++n) {
                DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INT * n));
                if (now == nullptr)
                    return newSV(0);
                av_push(MUTABLE_AV(ret_av), newSViv(*(int *)now));
            }
            sv_setsv(ret, newRV_inc(MUTABLE_SV(ret_av)));
        }
        break;
    default:
        croak("oh, okay...");
    };
    return ret;
}
DCCallback * cv2dcb(pTHX_ Affix_Type * type, SV * cb) {
    DCCallback * ret = NULL;
    // ret = dcbNewCallback("ii)v", cbHandler, new Affix_Callback((std::vector<Affix_Type *>)(type->argtypes)));

    // char cbHandler(DCCallback * cb, DCArgs * args, DCValue * result, DCpointer userdata) {


    return ret;
}
