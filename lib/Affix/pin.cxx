#include "../Affix.h"

/* Affix::pin( ... ) System

Bind an exported variable to a perl var */

int get_pin(pTHX_ SV * sv, MAGIC * mg) {
    warn("get_pin");
    Affix_Pin * pin = (Affix_Pin *)mg->mg_ptr;
    SV * val = ptr2sv(aTHX_ pin->ptr, 1);
    sv_setsv((sv), val);
    return 0;
}
int set_pin(pTHX_ SV * sv, MAGIC * mg) {
    warn("set_pin");
    Affix_Pin * pin = (Affix_Pin *)mg->mg_ptr;
    (void)sv2ptr(aTHX_ pin->ptr, sv, 1);
    return 0;
}

int free_pin(pTHX_ SV * sv, MAGIC * mg) {
    warn("free_pin");
    PERL_UNUSED_VAR(sv);
    Affix_Pin * pin = (Affix_Pin *)mg->mg_ptr;
    delete pin;
    pin = nullptr;
    return 0;
}

void _pin(pTHX_ SV * sv, Affix_Pointer * pointer) {
    warn("void _pin(pTHX_ SV * sv, Affix_Type * type = %s, DCpointer ptr = %p) {...",
         pointer->type->stringify.c_str(),
         pointer->address);
    MAGIC * mg;
    Affix_Pin * pin;
    if (SvMAGICAL(sv)) {
        mg = mg_findext(sv, PERL_MAGIC_ext, &pin_vtbl);
        if (mg != nullptr) {
            pin = (Affix_Pin *)mg->mg_ptr;
            if (pin->ptr->address == nullptr)
                croak("Oh, we messed up");

            warn("[O] Set pointer from %p to %p", pin->ptr->address, pointer->address);
            DumpHex(pin->ptr->address, 16);
            //    int i = 9999;
            //  Copy(&i, pin->ptr->address, 1, int);
            sv2ptr(aTHX_ pin->ptr, sv);
            DumpHex(pin->ptr->address, 16);
            warn("------------------ %d", *(int*)pin->ptr->address);

            // set_pin(aTHX_ sv, mg_);
            // sv_dump(sv);
            // sv_unmagicext(sv, PERL_MAGIC_ext, &pin_vtbl);
            // int x = 99999;
            // sv2ptr(aTHX_ type, sv, 1, pin->ptr->address);
            // Copy( ptr, pin->ptr->address,1, int_ptr);
            // pin->ptr->address = & ptr;
            // pin->ptr->address = *(DCpointer*) ptr;
            // return;
        }
    }
    pin = new Affix_Pin(NULL, pointer);
    warn("[N] Set pointer from %p to %p", pin->ptr->address, pointer->address);

    mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, &pin_vtbl, (char *)pin, 0);
    // SvREFCNT_dec(sv);              /* refcnt++ in sv_magicext */
    if (pointer->type->depth == 0) {  // Easy to forget to pass a size to Pointer[...]
        pointer->type->depth = 1;
        pointer->type->length.push_back(1);
    }
}

XS_INTERNAL(Affix_pin) {
    dXSARGS;
    if (items != 4)
        croak_xs_usage(cv, "var, lib, symbol, type");

    DLLib * _lib;
    // pin( my $integer, 't/src/58_affix_import_vars', 'integer', Int );
    {
        SV * const xsub_tmp_sv = ST(1);
        SvGETMAGIC(xsub_tmp_sv);
        if (!SvOK(xsub_tmp_sv) && SvREADONLY(xsub_tmp_sv))  // explicit undef
            _lib = _affix_load_library(NULL);
        else if (sv_isobject(xsub_tmp_sv) && sv_derived_from(xsub_tmp_sv, "Affix::Lib")) {
            IV tmp = SvIV((SV *)SvRV(xsub_tmp_sv));
            _lib = INT2PTR(DLLib *, tmp);
        } else if (NULL == (_lib = _affix_load_library(SvPV_nolen(xsub_tmp_sv)))) {
            Stat_t statbuf;
            Zero(&statbuf, 1, Stat_t);
            if (PerlLIO_stat(SvPV_nolen(xsub_tmp_sv), &statbuf) < 0) {
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(xsub_tmp_sv);
                PUTBACK;
                int count = call_pv("Affix::find_library", G_SCALAR);
                SPAGAIN;
                _lib = _affix_load_library(SvPV_nolen(POPs));
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
        }
        if (!_lib) {
            // TODO: Throw an error
            safefree(_lib);
            croak("Failed to load library");
            XSRETURN_UNDEF;
        }
    }
    char * symbol = (char *)SvPV_nolen(ST(2));
    DCpointer ptr = dlFindSymbol(_lib, symbol);
    if (ptr == NULL)
        croak("Failed to locate '%s'", symbol);

    _pin(aTHX_ ST(0), new Affix_Pointer(sv2type(aTHX_ ST(3)), ptr));

    XSRETURN_YES;
}

XS_INTERNAL(Affix_unpin) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "var");
    if (mg_findext(ST(0), PERL_MAGIC_ext, &pin_vtbl) && !sv_unmagicext(ST(0), PERL_MAGIC_ext, &pin_vtbl))
        XSRETURN_YES;
    XSRETURN_NO;
}

void boot_Affix_pin(pTHX_ CV * cv) {
    PERL_UNUSED_VAR(cv);
    (void)newXSproto_portable("Affix::pin", Affix_pin, __FILE__, "$$$$");
    export_function("Affix", "pin", "base");
    (void)newXSproto_portable("Affix::unpin", Affix_unpin, __FILE__, "$");
    export_function("Affix", "unpin", "base");
}
