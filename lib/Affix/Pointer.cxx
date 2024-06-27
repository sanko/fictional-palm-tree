#include "../Affix.h"

void boot_Affix_Pointer(pTHX_ CV * cv) {
    PERL_UNUSED_VAR(cv);

    set_isa("Affix::Pointer::Unmanaged", "Affix::Pointer");
}
