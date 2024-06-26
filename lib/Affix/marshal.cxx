#include "../Affix.h"

DCpointer sv2ptr(pTHX_ Affix_Type * type, SV * data, size_t depth, DCpointer ptr) {
    DD(data);
    if (depth) {
        // sv2ptr();
    }
    return ptr;
}

SV * ptr2sv(pTHX_ Affix_Type * type, DCpointer ptr) {

    return NULL;
}