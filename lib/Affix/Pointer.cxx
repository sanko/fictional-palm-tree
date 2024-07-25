#include "../Affix.h"

XS_INTERNAL(Affix_malloc) {
    dXSARGS;
    SSize_t size = (SSize_t)SvIV(ST(0));
    std::vector<SSize_t> lengths;
    lengths.push_back(size);
    Affix_Type * type =
        new Affix_Type(std::string("Pointer[ Void ]"), POINTER_FLAG, SIZEOF_INTPTR_T, ALIGNOF_INTPTR_T, 1, 0, lengths);
    ST(0) = bless_ptr(aTHX_ safemalloc(size), type, "Affix::Pointer");
    XSRETURN(1);
};

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

XS_INTERNAL(Affix_Pointer_raw) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix_Pointer * pointer;
    pointer = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(0))));
    if (pointer->address == nullptr)
        XSRETURN_EMPTY;
        ST(0) = newSVpv((const char *)pointer->address, SvIV(ST(1)));
    XSRETURN(1);
};

XS_INTERNAL(Affix_Pointer_free) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix_Pointer * pointer;
    pointer = INT2PTR(Affix_Pointer *, SvIV(SvRV(ST(0))));
    // if(pointer->type != nullptr)
    // delete pointer->type;
    // pointer->type = nullptr;
    safefree(pointer->address);
    ST(0) = &PL_sv_undef;
    XSRETURN(1);
    // XSRETURN_EMPTY;
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
    pointer = nullptr;
    XSRETURN_EMPTY;
};

XS_INTERNAL(Affix_Pointer_as_string) {
    dVAR;
    dXSARGS;
    if (items < 1)
        croak_xs_usage(cv, "$pointer");
    {
        char * RETVAL;
        dXSTARG;
        Affix_Pointer * ptr;

        if (sv_derived_from(ST(0), "Affix::Pointer")) {
            IV tmp = SvIV((SV *)SvRV(ST(0)));
            ptr = INT2PTR(Affix_Pointer *, tmp);
        } else
            croak("ptr is not of type Affix::Pointer");
        RETVAL = (char *)ptr->address;
        sv_setpv(TARG, RETVAL);
        XSprePUSH;
        PUSHTARG;
    }
    XSRETURN(1);
};

XS_INTERNAL(Affix_Pointer_deref_hash) {
    dVAR;
    dXSARGS;
    if (items < 1)
        croak_xs_usage(cv, "$pointer");
    warn("DEREF HASH!!!!!!!!!!!!!!!!!!!!!!");

    {
        char * RETVAL;
        dXSTARG;
        Affix_Pointer * ptr;

        if (sv_derived_from(ST(0), "Affix::Pointer")) {
            IV tmp = SvIV((SV *)SvRV(ST(0)));
            ptr = INT2PTR(Affix_Pointer *, tmp);
        } else
            croak("ptr is not of type Affix::Pointer");
        //     RETVAL = (char *)ptr->address;
        //     sv_setpv(TARG, RETVAL);
        //     XSprePUSH;
        //     PUSHTARG;
        if (ptr->type->numeric != STRUCT_FLAG)
            XSRETURN(1);  // Just toss back garbage
        ST(0) = newRV(MUTABLE_SV(newHV_mortal()));
    }
    XSRETURN(1);
};

void boot_Affix_Pointer(pTHX_ CV * cv) {
    PERL_UNUSED_VAR(cv);

    //(void)newXSproto_portable("Affix::Type::Pointer::(|", Affix_Type_Pointer, __FILE__, "");
    /* The magic for overload gets a GV* via gv_fetchmeth as */
    /* mentioned above, and looks in the SV* slot of it for */
    /* the "fallback" status. */
    sv_setsv(get_sv("Affix::Pointer::()", TRUE), &PL_sv_yes);
    /* Making a sub named "Affix::Pointer::()" allows the package */
    /* to be findable via fetchmethod(), and causes */
    /* overload::Overloaded("Affix::Pointer") to return true. */
    // (void)newXS_deffile("Affix::Pointer::()", Affix_Pointer_as_string);
    (void)newXSproto_portable("Affix::Pointer::()", Affix_Pointer_as_string, __FILE__, "$;@");
    (void)newXSproto_portable("Affix::Pointer::(\"\"", Affix_Pointer_as_string, __FILE__, "$;@");
    (void)newXSproto_portable("Affix::Pointer::as_string", Affix_Pointer_as_string, __FILE__, "$;@");
    (void)newXSproto_portable("Affix::Pointer::(%{}", Affix_Pointer_deref_hash, __FILE__, "$;@");
    //  ${}  @{}  %{}  &{}  *{}

    (void)newXSproto_portable("Affix::malloc", Affix_malloc, __FILE__, "$");


    (void)newXSproto_portable("Affix::Pointer::dump", Affix_Pointer_dump, __FILE__, "$$");

    (void)newXSproto_portable("Affix::Pointer::raw", Affix_Pointer_raw, __FILE__, "$$");

    (void)newXSproto_portable("Affix::Pointer::free", Affix_Pointer_free, __FILE__, "$");

    (void)newXSproto_portable("Affix::Pointer::DESTROY", Affix_Pointer_DESTROY, __FILE__, "$");
    (void)newXSproto_portable("Affix::Pointer::Unanaged::DESTROY", Affix_Pointer_Unmanaged_DESTROY, __FILE__, "$");

    set_isa("Affix::Pointer::Unmanaged", "Affix::Pointer");
}
