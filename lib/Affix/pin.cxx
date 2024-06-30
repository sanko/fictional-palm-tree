#include "../Affix.h"

/* Affix::pin( ... ) System
Bind an exported variable to a perl var */

typedef struct {  // Used in CUnion and pin()
    Affix_Pointer * ptr;
    Affix_Type * type;
} var_ptr;

int get_pin(pTHX_ SV * sv, MAGIC * mg) {
    var_ptr * ptr = (var_ptr *)mg->mg_ptr;
    SV * val = ptr2sv(aTHX_ ptr->type, ptr->ptr, 1, false);
    sv_setsv((sv), val);
    return 0;
}

int set_pin(pTHX_ SV * sv, MAGIC * mg) {
    var_ptr * ptr = (var_ptr *)mg->mg_ptr;
    if (SvOK(sv)) {
        DCpointer block = sv2ptr(aTHX_ ptr->type, ptr->ptr, sv);
        Move(block, ptr->ptr, ptr->type->size, char);
        safefree(block);
    }
    return 0;
}

int free_pin(pTHX_ SV * sv, MAGIC * mg) {
    PERL_UNUSED_VAR(sv);
    var_ptr * ptr = (var_ptr *)mg->mg_ptr;
    delete ptr->type;
    safefree(ptr);
    return 0;
}

static MGVTBL pin_vtbl = {
    get_pin,   // get
    set_pin,   // set
    NULL,      // len
    NULL,      // clear
    free_pin,  // free
    NULL,      // copy
    NULL,      // dup
    NULL       // local
};

void _pin(pTHX_ SV * sv, SV * type, DCpointer ptr) {
    MAGIC * mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, &pin_vtbl, NULL, 0);
    {
        var_ptr * _ptr;
        Newx(_ptr, 1, var_ptr);
        _ptr->ptr = (Affix_Pointer *)ptr;
        _ptr->type = sv2type(aTHX_ type);
        if (_ptr->type->depth == 0) {
            _ptr->type->depth = 1;
            _ptr->type->length.assign(0, 1);
        }
        mg->mg_ptr = (char *)_ptr;
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

    const char * symbol = (const char *)SvPV_nolen(ST(2));
    DCpointer ptr = dlFindSymbol(_lib, symbol);
    if (ptr == NULL) {
        croak("Failed to locate '%s'", symbol);
    }
    _pin(aTHX_ ST(0), ST(3), ptr);
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
