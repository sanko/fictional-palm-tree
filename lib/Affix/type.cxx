#include "../Affix.h"

Affix_Type *sv2type(pTHX_ SV *perl_type) {
    // This is it until we get to parameterized types
    SV **ptr_stringify = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "stringify", 9, 0);
    SV **ptr_numeric = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "numeric", 7, 0);
    SV **ptr_sizeof = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "sizeof", 6, 0);
    SV **ptr_alignment = hv_fetch(MUTABLE_HV(SvRV(perl_type)), "alignment", 9, 0);
    // TODO: check each value is valid
    Affix_Type *ret = new Affix_Type(SvPV_nolen(*ptr_stringify), SvIV(*ptr_numeric),
                                     SvIV(*ptr_sizeof), SvIV(*ptr_alignment));
    return ret;
}