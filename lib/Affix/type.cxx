#include "../Affix.h"
Affix_Type * sv2type(pTHX_ SV * perl_type) {  // This is it until we get to parameterized types
    SV ** ptr_stringify = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "stringify", 9, 0);
    SV ** ptr_numeric = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "numeric", 7, 0);
    SV ** ptr_sizeof = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "sizeof", 6, 0);
    SV ** ptr_alignment = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "alignment", 9, 0);
    SV ** ptr_depth = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "depth", 5, 0);
    SV ** ptr_length = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "length", 6, 0);

    std::vector<SSize_t> lengths;
    if (ptr_length != nullptr && SvROK(*ptr_length) && SvTYPE(SvRV(*ptr_length)) == SVt_PVAV) {
        AV * av_length = MUTABLE_AV(SvRV(*ptr_length));
        for (auto i = 0; i < av_count(av_length); i++)
            lengths.push_back(SvIV(*av_fetch(av_length, i, -1)));
    }

    // TODO: check each value is valid because I'm human
    return new Affix_Type(SvPV_nolen(*ptr_stringify),
                          SvIV(*ptr_numeric),
                          SvIV(*ptr_sizeof),
                          SvIV(*ptr_alignment),
                          ptr_depth != nullptr ? SvIV(*ptr_depth) : 0,
                          lengths);
}
