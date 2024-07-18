#include "../Affix.h"

Affix_Pointer * sv2ptr(pTHX_ Affix_Pointer * pointer, SV * data, size_t depth) {
    // Do I really need the Affix_Pointer here? I'm really only after ptr->count
    // DD(data);
    if (depth < pointer->type->depth) {
        AV * list = MUTABLE_AV(SvRV(data));
        size_t length = av_count(list);
        if (pointer->address == nullptr)
            Newxz(pointer->address, length + 1, intptr_t);
        Affix_Pointer * next;
        SV ** _tmp;
        for (size_t i = 0; i < length; i++) {
            _tmp = av_fetch(list, i, 0);
            if (UNLIKELY(_tmp == nullptr))
                break;
            next = sv2ptr(aTHX_ pointer, *_tmp, depth + 1);
            Copy(&next->address, INT2PTR(intptr_t *, PTR2IV(pointer->address) + (i * SIZEOF_INTPTR_T)), 1, intptr_t);
        }
        return pointer;
    }
    switch (pointer->type->numeric) {
    case VOID_FLAG:
        if (SvOK(data)) {
            SV * const xsub_tmp_sv = data;
            SvGETMAGIC(xsub_tmp_sv);
            if ((SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVAV &&
                 sv_derived_from(xsub_tmp_sv, "Affix::Pointer"))) {
                SV * ptr_sv = AXT_POINTER_ADDR(xsub_tmp_sv);
                if (SvOK(ptr_sv)) {
                    IV tmp = SvIV(MUTABLE_SV(SvRV(ptr_sv)));
                    pointer->address = INT2PTR(DCpointer, tmp);
                }
            }
            // else if (SvMAGICAL(data)&& mg_findext(data, PERL_MAGIC_ext, &pin_vtbl)) {
            //  if (pointer->address == nullptr)
            // Newxz(pointer->address, 1, int);
            // int n = SvIV(data);
            // Copy(n, pointer->address, 1, int);
            // }
            else if (SvTYPE(data) != SVt_NULL) {
                size_t len = 0;
                DCpointer ptr_ = SvPVbyte(data, len);
                if (pointer->address == nullptr)
                    Newxz(pointer->address, len, char);
                Copy(ptr_, pointer->address, len, char);
            } else
                croak("Data type mismatch for %s [%d]", pointer->type->stringify.c_str(), SvTYPE(data));
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
            if (pointer->address == nullptr)
                Newxz(pointer->address, length + 1, int);
            IV ptr_iv = PTR2IV(pointer->address);
            int n;
            SV ** _tmp;
            for (size_t i = 0; i < length; i++) {
                _tmp = av_fetch(list, i, 0);
                if (UNLIKELY(_tmp == nullptr))
                    break;
                n = SvIV(*_tmp);
                Copy(&n, INT2PTR(int *, ptr_iv + (i * SIZEOF_INT)), 1, int);
            }
        } else if (SvMAGICAL(data) && mg_findext(data, PERL_MAGIC_ext, &pin_vtbl)) {
            if (pointer->address == nullptr)
                Newxz(pointer->address, 1, int);
            int n = SvIV(data);
            Copy(n, pointer->address, 1, int);
        } else if (UNLIKELY(SvIOK(data))) {
            if (pointer->address == nullptr)
                Newxz(pointer->address, 1, int);
            int n = SvIV(data);
            Copy(&n, pointer->address, 1, int);
        } else if (UNLIKELY(!SvOK(data)))
            warn("Data type mismatch for %s [%d]", pointer->type->stringify.c_str(), SvTYPE(data));
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
        */

    case STRUCT_FLAG:
        if (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
            // DD(data);
            HV * hv_struct = MUTABLE_HV(SvRV(data));
            if (pointer->address == nullptr)
                pointer->address = safecalloc(pointer->type->size, SIZEOF_CHAR);
            for (const auto & subtype : pointer->type->subtypes) {
                const char * name = subtype->field.c_str();
                SV ** ptr_field = hv_fetch(hv_struct, name, strlen(name), 0);
                if (ptr_field == nullptr)
                    croak("Expected field '%s' is missing", name);
                DCpointer slot = INT2PTR(DCpointer, (int)subtype->offset + PTR2IV(pointer->address));

                sv2ptr(aTHX_ new Affix_Pointer(subtype, slot), *ptr_field, depth);
                // sv_dump(*ptr_field);
                // _pin(aTHX_ SvREFCNT_inc_NN(*ptr_field), new Affix_Pointer(subtype, slot));
                // sv_dump(*ptr_field);
            }
        } else
            pointer->address = nullptr;  // ???: malloc full sized block instead?
        break;

        /*
         #define CPPSTRUCT_FLAG 'B'
         #define UNION_FLAG 'u'
         #define AFFIX_FLAG '@'
         */
    case CODEREF_FLAG:
        pointer->address = cv2dcb(aTHX_ pointer->type, data);
        break;
        /*
        #define POINTER_FLAG 'P'
        #define SV_FLAG '?'
        */
    default:
        croak("TODO: sv2ptr for everything else");
    }
    return pointer;
}

SV * bless_ptr(pTHX_ Affix_Pointer * ptr, const char * package) {
    return sv_setref_pv(newSV(0), package, (DCpointer)ptr);
}

// SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer target, size_t depth) {
//     return ptr2sv(aTHX_ new Affix_Pointer(type, target), depth);
// }
SV * ptr2sv(pTHX_ Affix_Pointer * pointer, size_t depth) {

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
    if (pointer->type->length.at(depth - 1) == -1)  // -1 comes from Affix::Type::Pointer
        return bless_ptr(aTHX_ pointer, "Affix::Pointer");
    if (depth < pointer->type->depth) {
        // DumpHex(target, 64);
        AV * tmp = newAV();
        IV ptr_iv = PTR2IV(pointer->address);
        int n = 0;

        while (1) {
            DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INTPTR_T * n));
            if (now == nullptr) {
                // return newRV_inc(MUTABLE_SV(tmp));
                break;
            }
            if (n >= pointer->type->length.at(depth - 1))
                break;
            av_push(tmp, ptr2sv(aTHX_ new Affix_Pointer(pointer->type, *(DCpointer *)now), depth + 1));
            n++;
        }
        return newRV_inc(MUTABLE_SV(tmp));
    }
    IV ptr_iv = PTR2IV(pointer->address);
    SV * ret = newSV(0);
    switch (pointer->type->numeric) {
    case VOID_FLAG:
        sv_setsv(ret, bless_ptr(aTHX_ pointer));
        break;
    case INT_FLAG:
        if (depth == pointer->type->depth && pointer->type->length.at(depth - 1) == 1)
            return newSViv(*(int *)pointer->address);
        {
            AV * ret_av = newAV_mortal();
            for (auto n = 0; n < pointer->type->length.at(depth - 1); ++n) {
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
    // TODO: Be smart. Check that cb != undef, a CV*, etc.
    auto afxcb = new Affix_Callback(type, SvREFCNT_inc(cb));
    storeTHX(afxcb->perl);
    ret = dcbNewCallback(
        "ii)v", cbHandler, afxcb);  // TODO: generate (somewhat) correct signature even though we don't use it?
    return ret;
}
