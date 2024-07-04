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
    default:
        croak("TODO: sv2ptr for everything else");
    }
    PING;

    return target;
}

SV * bless_ptr(pTHX_ DCpointer ptr, Affix_Type * type, const char * package) {
    return sv_setref_pv(newSV(0), package, (DCpointer) new Affix_Pointer(type, ptr));
}

SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer target, size_t depth, bool wantlist) {
    PING;

    warn(
        "SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer target = %p, size_t depth = %d); [type->depth == %d] [type->length.size "
        "== %d]",
        target,
        depth,
        type->depth,
        type->length.size());
        
            // if (type->length.at(depth ) == -1)  // -1 comes from Affix::Type::Pointer
    // return bless_ptr(aTHX_ target, type, "Affix::Pointer");
PING;
    if (depth < type->depth) {
PING;

          DumpHex(target, 64);
        AV * tmp = newAV();
        IV ptr_iv = PTR2IV(target);
        size_t n = 0;
PING;

        while (1) {
            warn("tick: %d", n);
            DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INTPTR_T * n));
            warn("r: %p", now);
            if (now == nullptr) {
                // warn("Null?!?!?");
                // return newRV_inc(MUTABLE_SV(tmp));
                break;
            }
            // warn("n: %d, depth: %d, .at: %d", n, depth, type->length.at(depth));
            if (n >= type->length.at(depth-1))
                break;
            // warn("Not null?");
            av_push(tmp, ptr2sv(aTHX_ type, *(DCpointer *)now, depth + 1));
PING;

            n++;
        }
        PING;
        // DD(MUTABLE_SV(tmp));
        return newRV_inc(MUTABLE_SV(tmp));

        // return MUTABLE_SV(tmp);
    }
    // DumpHex(target, 64);
    IV ptr_iv = PTR2IV(target);
PING;

    SV * ret = newSV(0);
    switch (type->numeric) {
    case VOID_FLAG:
        sv_setsv(ret, bless_ptr(aTHX_ target, type));
        break;
    case INT_FLAG:
    PING;

        if (wantlist) {
            PING;

            AV * ret_av = newAV_mortal();
            PING;

            for (size_t n = 0; n < type->length.at(depth-1); ++n) {
                PING;

                DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INT * n));
                PING;

                if (now == nullptr)
                    return newSV(0);
                    PING;

                SV * retlll = newSViv(*(int *)now);
                PING;

                av_push(MUTABLE_AV(ret_av), retlll);
            }
            PING;

            sv_setsv(ret, newRV_inc(MUTABLE_SV(ret_av)));
            PING;

        } else
            sv_setsv(ret, newSViv(*(int *)target));
            PING;

        break;
    default:
        croak("oh, okay...");
    };
    // av_push(MUTABLE_AV(ret), retlll);
    // PING;
    // DD(ret);
    return ret;
}