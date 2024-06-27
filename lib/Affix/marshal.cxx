#include "../Affix.h"

DCpointer sv2ptr(pTHX_ Affix_Type * type, Affix_Pointer * ptr, SV * data, size_t depth, DCpointer target) {
    // Do I really need the Affix_Pointer here? I'm really only after ptr->count
    DD(data);
    if (depth < type->depth) {
        AV * list = MUTABLE_AV(SvRV(data));
        size_t length = av_count(list);
        IV ptr_iv = PTR2IV(target);
        if (target == nullptr)
            Newxz(target, length + 1, intptr_t);
        DCpointer next;
        SV ** _tmp;
        for (auto i = 0; i < length; i++) {
            PING;
            _tmp = av_fetch(list, i, 0);
            PING;

            if (UNLIKELY(_tmp == nullptr))
                break;
            PING;
            PING;

            PING;

            next = sv2ptr(aTHX_ type, ptr, *_tmp, depth + 1);
            PING;

            Copy(&next, INT2PTR(intptr_t *, PTR2IV(target) + (i * SIZEOF_INTPTR_T)), 1, intptr_t);
            PING;
        }
        return target;
    }
    PING;
    switch (type->numeric) {
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
                PING;
                Copy(&n, INT2PTR(int *, ptr_iv + (i * SIZEOF_INT)), 1, int);
                PING;
            }
        } else if (UNLIKELY(SvIOK(data))) {
            if (target == nullptr)
                Newxz(target, 1, int);
            int n = SvIV(data);
            Copy(&n, target, 1, int);
        } else if (UNLIKELY(!SvOK(data)))
            warn("Data type mismatch for %s [%d]", type->stringify, SvTYPE(data));
        PING;

        break;
    default:
        croak("TODO: sv2ptr for everything else");
    }
    PING;

    return target;
}

SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer target, size_t depth) {
    // warn("SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer %p, size_t depth)", target);

    if (depth < type->depth) {
        //   DumpHex(target, 64);
        AV * tmp = newAV();
        IV ptr_iv = PTR2IV(target);
        size_t n;

        while (1) {
            // warn("tick: %d", n);
            DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INTPTR_T * n));
            warn("r: %p", now);
            if (now == nullptr) {
                // warn("Null?!?!?");
                return MUTABLE_SV(tmp);
            }
            // warn("Not null?");
            av_push(tmp, ptr2sv(aTHX_ type, now, depth + 1));
            if (n == 20)
                break;
            n++;
        }
        return MUTABLE_SV(tmp);
    }
    DumpHex(target, 64);
    IV ptr_iv = PTR2IV(target);
    size_t n;
    AV * ret_av = newAV();
    while (1) {
        // warn("tick: %d", n);
        DCpointer now = INT2PTR(DCpointer, ptr_iv + (SIZEOF_INT * n));
        warn("r: %p", now);
        DumpHex(now, SIZEOF_INT);
        if (now == nullptr) {
            PING;
            // warn("Null?!?!?");
            return newSV(0);
        }
        // warn("Not null?");
        // PING;
        SV * retlll = newSViv(*(int *)now);
        // DD(retlll);
        // PING;
        av_push(ret_av, retlll);
        // av_push(MUTABLE_AV(ret), retlll);
        // PING;
        if (n == 5)
            break;
        // PING;
        n++;
    }
    return MUTABLE_SV(ret_av);
}