#include "Affix.h"

XS_EXTERNAL(boot_Affix) {
    dVAR;

    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);

#ifdef USE_ITHREADS
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif

    //~ MY_CXT_INIT;

    Perl_xs_boot_epilog(aTHX_ ax);
}
