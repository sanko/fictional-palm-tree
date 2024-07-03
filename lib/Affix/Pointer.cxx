#include "../Affix.h"


XS_INTERNAL(Affix_Pointer_dump) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix_Pointer * pointer;
    pointer = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(0))));
    if (pointer->address == nullptr)
        XSRETURN_EMPTY;
    DumpHex(pointer->address, SvIV(ST(1)));
    XSRETURN_EMPTY;
};


XS_INTERNAL(Affix_Pointer_free) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix_Pointer * pointer;
    pointer = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(0))));
    if (pointer->address != nullptr)
        safefree(pointer->address);
    pointer->address = nullptr;
    XSRETURN_EMPTY;
};

XS_INTERNAL(Affix_Pointer_DESTROY) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix_Pointer * pointer;
    pointer = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(0))));
    if (pointer != nullptr) {
        // if (pointer->address != nullptr)
        // safefree(pointer->address);
        pointer->address = nullptr;
        delete pointer;
    }
    pointer = nullptr;
    XSRETURN_EMPTY;
};

XS_INTERNAL(Affix_Pointer_Unmanaged_DESTROY) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix_Pointer * pointer;
    pointer = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(0))));
    // DO NOTHING HERE! Require users to manually call ->free() instead
    delete pointer;
    pointer = NULL;
    XSRETURN_EMPTY;
};


void boot_Affix_Pointer(pTHX_ CV * cv) {
    PERL_UNUSED_VAR(cv);

    (void)newXSproto_portable("Affix::Pointer::dump", Affix_Pointer_dump, __FILE__, "$$");

    (void)newXSproto_portable("Affix::Pointer::free", Affix_Pointer_free, __FILE__, "$");

    (void)newXSproto_portable("Affix::Pointer::DESTROY", Affix_Pointer_DESTROY, __FILE__, "$");
    (void)newXSproto_portable("Affix::Pointer::Unanaged::DESTROY", Affix_Pointer_Unmanaged_DESTROY, __FILE__, "$");

    set_isa("Affix::Pointer::Unmanaged", "Affix::Pointer");
}
