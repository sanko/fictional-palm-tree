#include "../Affix.h"

// Perl utils
void register_constant(const char * package, const char * name, SV * value) {
    dTHX;
    HV * _stash = gv_stashpv(package, TRUE);
    newCONSTSUB(_stash, (char *)name, value);
}

#define export_function(package, what, tag) \
    _export_function(aTHX_ get_hv(form("%s::EXPORT_TAGS", package), GV_ADD), what, tag)

void _export_function(pTHX_ HV * _export, const char * what, const char * _tag) {
    SV ** tag = hv_fetch(_export, _tag, strlen(_tag), TRUE);
    if (tag && SvOK(*tag) && SvROK(*tag) && (SvTYPE(SvRV(*tag))) == SVt_PVAV)
        av_push((AV *)SvRV(*tag), newSVpv(what, 0));
    else {
        SV * av;
        av = (SV *)newAV();
        av_push((AV *)av, newSVpv(what, 0));
        (void)hv_store(_export, _tag, strlen(_tag), newRV_noinc(av), 0);
    }
}

void export_constant_char(const char * package, const char * name, const char * _tag, char val) {
    dTHX;
    register_constant(package, name, newSVpv(&val, 1));
    export_function(package, name, _tag);
}

void export_constant(const char * package, const char * name, const char * _tag, double val) {
    dTHX;
    register_constant(package, name, newSVnv(val));
    export_function(package, name, _tag);
}

void set_isa(const char * package, const char * parent) {
    dTHX;
    gv_stashpv(parent, GV_ADD | GV_ADDMULTI);
    av_push(get_av(form("%s::ISA", package), TRUE), newSVpv(parent, 0));
}

// Debugging
void _DumpHex(pTHX_ const void * addr, size_t len, const char * file, int line) {
    if (addr == nullptr) {
        printf("Dumping %lu bytes from null pointer %p at %s line %d\n", len, addr, file, line);
        fflush(stdout);
        return;
    }
    fflush(stdout);
    int perLine = 16;
    // Silently ignore silly per-line values.
    if (perLine < 4 || perLine > 64)
        perLine = 16;
    size_t i;
    U8 * buff;
    Newxz(buff, perLine + 1, U8);
    const U8 * pc = (const U8 *)addr;
    printf("Dumping %lu bytes from %p at %s line %d\n", len, addr, file, line);
    // Length checks.
    if (len == 0)
        croak("ZERO LENGTH");
    for (i = 0; i < len; i++) {
        if ((i % perLine) == 0) {  // Only print previous-line ASCII buffer for
            // lines beyond first.
            if (i != 0)
                printf(" | %s\n", buff);
            printf("#  %03zu ", i);  // Output the offset of current line.
        }
        // Now the hex code for the specific character.
        printf(" %02x", pc[i]);
        // And buffer a printable ASCII character for later.
        if ((pc[i] < 0x20) || (pc[i] > 0x7e))  // isprint() may be better.
            buff[i % perLine] = '.';
        else
            buff[i % perLine] = pc[i];
        buff[(i % perLine) + 1] = '\0';
    }
    // Pad out last line if not exactly perLine characters.
    while ((i % perLine) != 0) {
        printf("   ");
        i++;
    }
    printf(" | %s\n", buff);
    safefree(buff);
    fflush(stdout);
}

#define DD(scalar) _DD(aTHX_ scalar, __FILE__, __LINE__)
void _DD(pTHX_ SV * scalar, const char * file, int line) {
    Perl_load_module(aTHX_ PERL_LOADMOD_NOIMPORT, newSVpvs("Data::Printer"), NULL, NULL, NULL);
    if (!get_cvs("Data::Printer::p", GV_NOADD_NOINIT | GV_NO_SVGMAGIC))
        return;

    fflush(stdout);
    dSP;
    int count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(scalar);
    PUTBACK;

    count = call_pv("Data::Printer::p", G_SCALAR);

    SPAGAIN;

    if (count != 1)
        croak("Big trouble\n");

    STRLEN len;
    const char * s = SvPVx(POPs, len);

    printf("%s at %s line %d\n", s, file, line);
    fflush(stdout);

    PUTBACK;
    FREETMPS;
    LEAVE;
}

DLLib * _affix_load_library(const char * lib) {
    return
#if defined(DC__OS_Win64) || defined(DC__OS_MacOSX)
        dlLoadLibrary(lib);
#else
        (DLLib *)dlopen(lib, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
}

SV * call_sub(pTHX_ const char * sub, SV * arg) {
    dSP;
    SV * retval = sv_newmortal();

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(arg);
    PUTBACK;

    int count = call_pv(sub, G_SCALAR);
    SPAGAIN;

    if (count == 1)
        sv_setsv(retval, POPs);

    PUTBACK;

    FREETMPS;
    LEAVE;
    return retval;
}
