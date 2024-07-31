#ifndef AFFIX_H_SEEN
#define AFFIX_H_SEEN

#include <algorithm>  // for_each
#include <memory>
#include <string>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT 1 /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#define NO_XSLOCKS /* for exceptions */
#include <XSUB.h>

#ifndef sv_setbool_mg
#define sv_setbool_mg(sv, b) sv_setsv_mg(sv, boolSV(b)) /* new in perl 5.36 */
#endif
#ifndef newSVbool
#define newSVbool(b) boolSV(b) /* new in perl 5.36 */
#endif
#ifndef sv_setbool
#define sv_setbool sv_setsv     /* new in perl 5.38 */
#endif

#if __WIN32
#include <cstdint>
#include <windows.h>
#endif

#ifdef MULTIPLICITY
#define storeTHX(var) (var) = aTHX
#define dTHXfield(var) tTHX var;
#else
#define storeTHX(var) dNOOP
#define dTHXfield(var)
#endif

// in CORE as of perl 5.40
// #if PERL_VERSION_LT(5, 40, 0)
#if PERL_VERSION_MINOR < 40
#define newAV_mortal() MUTABLE_AV(sv_2mortal((SV *)newAV()))
#endif
#define newHV_mortal() MUTABLE_HV(sv_2mortal((SV *)newHV()))

/* NOTE: the prototype of newXSproto() is different in versions of perls,
 * so we define a portable version of newXSproto()
 */
#ifdef newXS_flags
#define newXSproto_portable(name, c_impl, file, proto) newXS_flags(name, c_impl, file, proto, 0)
#else
#define newXSproto_portable(name, c_impl, file, proto) \
    (PL_Sv = (SV *)newXS(name, c_impl, file), sv_setpv(PL_Sv, proto), (CV *)PL_Sv)
#endif /* !defined(newXS_flags) */

#define newXS_deffile(a, b) Perl_newXS_deffile(aTHX_ a, b)

// Only in 5.38.0+
#ifndef PERL_ARGS_ASSERT_NEWSV_FALSE
#define newSV_false() newSVsv(&PL_sv_no)
#endif

#ifndef PERL_ARGS_ASSERT_NEWSV_TRUE
#define newSV_true() newSVsv(&PL_sv_yes)
#endif

#define dcAllocMem safemalloc
#define dcFreeMem safefree

#ifndef av_count
#define av_count(av) (AvFILL(av) + 1)
#endif

#include <dyncall/dyncall.h>
#include <dyncall/dyncall_aggregate.h>
#include <dyncall/dyncall_callf.h>
#include <dyncall/dyncall_signature.h>
#include <dyncall/dyncall_value.h>
#include <dyncall/dyncall_version.h>
#include <dyncallback/dyncall_callback.h>
#include <dynload/dynload.h>

#if defined(DC__OS_Win32) || defined(DC__OS_Win64)
#elif defined(DC__OS_MacOS)
#else
#include <dlfcn.h>
//~ #include <iconv.h>
#endif

#include <wchar.h>

#if defined(DC__C_GNU) || defined(DC__C_CLANG)
#include <cxxabi.h>
#endif

#ifdef DC__OS_Win64
#include <cinttypes>
static const char * dlerror(void) {
    static char buf[1024];
    DWORD dw = GetLastError();
    if (dw == 0)
        return NULL;
    snprintf(buf, 32, "error 0x%" PRIx32 "", dw);
    return buf;
}
#endif

#if DEBUG > 1
#define PING warn("Ping at %s line %d", __FILE__, __LINE__);
#else
#define PING ;
#endif

/* Native argument types (core types match Itanium mangling) */
#define VOID_FLAG 'v'
#define BOOL_FLAG 'b'
#define SCHAR_FLAG 'a'
#define CHAR_FLAG 'c'
#define UCHAR_FLAG 'h'
#define WCHAR_FLAG 'w'
#define SHORT_FLAG 's'
#define USHORT_FLAG 't'
#define INT_FLAG 'i'
#define UINT_FLAG 'j'
#define LONG_FLAG 'l'
#define ULONG_FLAG 'm'
#define LONGLONG_FLAG 'x'
#define ULONGLONG_FLAG 'y'
#if SIZEOF_SIZE_T == INTSIZE
#define SIZE_T_FLAG UINT_FLAG
#elif SIZEOF_SIZE_T == LONGSIZE
#define SIZE_T_FLAG ULONG_FLAG
#elif SIZEOF_SIZE_T == LONGLONGSIZE
#define SIZE_T_FLAG ULONGLONG_FLAG
#else  // quadmath is broken
#define SIZE_T_FLAG ULONGLONG_FLAG
#endif
#define FLOAT_FLAG 'f'
#define DOUBLE_FLAG 'd'
// #define STRING_FLAG 'z'
#define WSTRING_FLAG '<'
#define STDSTRING_FLAG 'Y'
#define STRUCT_FLAG 'A'
#define CPPSTRUCT_FLAG 'B'
#define UNION_FLAG 'u'
#define AFFIX_FLAG '@'
#define CODEREF_FLAG '&'
#define POINTER_FLAG 'P'
#define SV_FLAG '?'

// Calling conventions
#define RESET_FLAG '>'  // DC_SIGCHAR_CC_DEFAULT
#define THIS_FLAG '*'
#define ELLIPSIS_FLAG 'e'
#define VARARGS_FLAG '.'
#define DCECL_FLAG 'D'
#define STDCALL_FLAG 'T'
#define MSFASTCALL_FLAG '='
#define GNUFASTCALL_FLAG '3'
#define MSTHIS_FLAG '+'
#define GNUTHIS_FLAG '#'
#define ARM_FLAG 'r'
#define THUMB_FLAG 'g'
#define SYSCALL_FLAG 'H'

/* Flag for whether we should free a string after passing it or not. */
#define AFFIX_TYPE_NO_FREE_STR 0
#define AFFIX_TYPE_FREE_STR 1
#define AFFIX_TYPE_FREE_STR_MASK 1

/* Flag for whether we need to refresh a CArray after passing or not. */
#define AFFIX_TYPE_NO_REFRESH 0
#define AFFIX_TYPE_REFRESH 1
#define AFFIX_TYPE_REFRESH_MASK 1
#define AFFIX_TYPE_NO_RW 0
#define AFFIX_TYPE_RW 256
#define AFFIX_TYPE_RW_MASK 256

#define AFFIX_UNMARSHAL_KIND_GENERIC -1
#define AFFIX_UNMARSHAL_KIND_RETURN -2
#define AFFIX_UNMARSHAL_KIND_NATIVECAST -3

// http://www.catb.org/esr/structure-packing/#_structure_alignment_and_padding
/* Returns the amount of padding needed after `offset` to ensure that the
following address will be aligned to `alignment`. */

/* Alignment. */
#if 1
// HAVE_ALIGNOF
/* A GCC extension. */
#define ALIGNOF(t) __alignof__(t)
#elif defined _MSC_VER
/* MSVC extension. */
#define ALIGNOF(t) __alignof(t)
#else
/* Alignment by measuring structure padding. */
#define ALIGNOF(t)         \
    ((char *)(&((struct {  \
                   char c; \
                   t _h;   \
               } *)0)      \
                   ->_h) - \
     (char *)0)
#endif

// MEM_ALIGNBYTES is messed up by quadmath and long doubles
#define AFFIX_ALIGNBYTES 8

/* Some are undefined in perlapi */
#define SIZEOF_BOOL sizeof(bool)  // ha!
#define SIZEOF_CHAR sizeof(char)
#define SIZEOF_SCHAR sizeof(signed char)
#define SIZEOF_UCHAR sizeof(unsigned char)
#define SIZEOF_WCHAR sizeof(wchar_t)
#define SIZEOF_SHORT sizeof(short)
#define SIZEOF_USHORT sizeof(unsigned short)
#define SIZEOF_INT INTSIZE
#define SIZEOF_UINT sizeof(unsigned int)
#define SIZEOF_LONG sizeof(long)
#define SIZEOF_ULONG sizeof(unsigned long)
#define SIZEOF_LONGLONG sizeof(long long)
#define SIZEOF_ULONGLONG sizeof(unsigned long long)
#define SIZEOF_FLOAT sizeof(float)
#define SIZEOF_DOUBLE sizeof(double)  // ugh...
#if SIZEOF_SIZE_T == INTSIZE
#define SIZEOF_SIZE_T SIZEOF_INT
#define SIZEOF_SSIZE_T SIZEOF_UINT
#elif SIZEOF_SIZE_T == LONGSIZE
#define SIZEOF_SIZE_T SIZEOF_LONGLONG
#define SIZEOF_SSIZE_T SIZEOF_ULONG
#elif SIZEOF_SIZE_T == LONGLONGSIZE
#define SIZEOF_SIZE_T SIZEOF_ULONGLONG
#define SIZEOF_SSIZE_T SIZEOF_LONGLONG
#else  // quadmath is broken
#define SIZEOF_SIZE_T SIZEOF_ULONGLONG
#define SIZEOF_SSIZE_T SIZEOF_LONGLONG
#endif
#define SIZEOF_INTPTR_T sizeof(intptr_t)  // ugh...

#define ALIGNOF_BOOL ALIGNOF(bool)
#define ALIGNOF_CHAR ALIGNOF(char)
#define ALIGNOF_SCHAR ALIGNOF(signed char)
#define ALIGNOF_UCHAR ALIGNOF(unsigned char)
#define ALIGNOF_WCHAR ALIGNOF(wchar_t)
#define ALIGNOF_SHORT ALIGNOF(short)
#define ALIGNOF_USHORT ALIGNOF(unsigned short)
#define ALIGNOF_INT ALIGNOF(int)
#define ALIGNOF_UINT ALIGNOF(unsigned int)
#define ALIGNOF_LONG ALIGNOF(long)
#define ALIGNOF_ULONG ALIGNOF(unsigned long)
#define ALIGNOF_LONGLONG ALIGNOF(long long)
#define ALIGNOF_ULONGLONG ALIGNOF(unsigned long long)
#define ALIGNOF_FLOAT ALIGNOF(float)
#define ALIGNOF_DOUBLE ALIGNOF(double)
#define ALIGNOF_INTPTR_T ALIGNOF(intptr_t)
#define ALIGNOF_SIZE_T ALIGNOF(size_t)

#define SLOT_TYPE_STRINGIFY 0
#define SLOT_TYPE_NUMERIC 1
#define SLOT_TYPE_SIZEOF 2
#define SLOT_TYPE_ALIGNMENT 3
#define SLOT_TYPE_OFFSET 4
#define SLOT_TYPE_SUBTYPE 5
#define SLOT_TYPE_ARRAYLEN 6
#define SLOT_TYPE_CONST 7
#define SLOT_TYPE_VOLATILE 8
#define SLOT_TYPE_RESTRICT 9
#define SLOT_TYPE_TYPEDEF 10
#define SLOT_TYPE_AGGREGATE 11
#define SLOT_TYPE_FIELD 12    // Field name if in a Struct or Union
#define SLOT_TYPE_POINTER 13  //

#define SLOT_CODEREF_RET SLOT_TYPE_SUBTYPE
#define SLOT_CODEREF_ARGS 12
#define SLOT_CODEREF_SIG 13

#define SLOT_POINTER_ADDR 0
#define SLOT_POINTER_SUBTYPE 1
#define SLOT_POINTER_COUNT 2
#define SLOT_POINTER_POSITION 3

#define AXT_TYPE_STRINGIFY(t) SvPV_nolen(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_STRINGIFY, 0))
#define AXT_TYPE_NUMERIC(t) SvIV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_NUMERIC, 0))
#define AXT_TYPE_SIZEOF(t) SvIV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_SIZEOF, 0))
#define AXT_TYPE_ALIGN(t) SvIV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_ALIGNMENT, 0))
#define AXT_TYPE_OFFSET(t) SvIV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_OFFSET, 0))
#define AXT_TYPE_SUBTYPE(t) *av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_SUBTYPE, 0)
#define AXT_TYPE_ARRAYLEN(t) SvIV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_ARRAYLEN, 0))
#define AXT_TYPE_AGGREGATE(t) av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_AGGREGATE, 0)
#define AXT_TYPE_TYPEDEF(t) av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_TYPEDEF, 0)
#define AXT_TYPE_CAST(t) av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_CAST, 0)
#define AXT_TYPE_FIELD(t) av_fetch(MUTABLE_AV(SvRV(t)), SLOT_TYPE_FIELD, 0)

#define AXT_CODEREF_ARGS(t) MUTABLE_AV(SvRV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_CODEREF_ARGS, 0)))
#define AXT_CODEREF_RET(t) *av_fetch(MUTABLE_AV(SvRV(t)), SLOT_CODEREF_RET, 0)
#define AXT_CODEREF_SIG(t) *av_fetch(MUTABLE_AV(SvRV(t)), SLOT_CODEREF_SIG, 0)

#define AXT_POINTER_ADDR(t) *av_fetch(MUTABLE_AV(SvRV(t)), SLOT_POINTER_ADDR, 0)
#define AXT_POINTER_SUBTYPE(t) *av_fetch(MUTABLE_AV(SvRV(t)), SLOT_POINTER_SUBTYPE, 0)
#define AXT_POINTER_COUNT(t) SvIV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_POINTER_COUNT, 0))
#define AXT_POINTER_POSITION(t) SvIV(*av_fetch(MUTABLE_AV(SvRV(t)), SLOT_POINTER_POSITION, 0))

// wchar_t.cxx
SV * wchar2utf(pTHX_ wchar_t * src, size_t len);
wchar_t * utf2wchar(pTHX_ SV * src, size_t len);

// Affix/Aggregate.cxx
DCaggr * _aggregate(pTHX_ SV * type);

// Affix/Utils.cxx
#define export_function(package, what, tag) \
    _export_function(aTHX_ get_hv(form("%s::EXPORT_TAGS", package), GV_ADD), what, tag)
void register_constant(const char * package, const char * name, SV * value);
void _export_function(pTHX_ HV * _export, const char * what, const char * _tag);
void export_constant_char(const char * package, const char * name, const char * _tag, char val);
void export_constant(const char * package, const char * name, const char * _tag, double val);
void set_isa(const char * klass, const char * parent);

#define DumpHex(addr, len) _DumpHex(aTHX_ addr, len, __FILE__, __LINE__)
void _DumpHex(pTHX_ const void * addr, size_t len, const char * file, int line);
#define DD(scalar) _DD(aTHX_ scalar, __FILE__, __LINE__)
void _DD(pTHX_ SV * scalar, const char * file, int line);

int type_as_dc(int type);  // TODO: Find a better place for this

// Affix/Lib.cxx
char * locate_lib(pTHX_ SV * _lib, SV * _ver);
char * mangle(pTHX_ const char * abi, SV * affix, const char * symbol, SV * args);

class Affix_Type {
public:
    // Fundamental
    Affix_Type(const std::string & stringify,
               char numeric,
               size_t size,
               size_t alignment,
               size_t depth,
               size_t offset,
               std::vector<SSize_t> length)
        : numeric(numeric),
          size(size),
          _alignment(alignment),
          depth(depth),
          offset(offset),
          length(length),
          stringify(stringify) {};

    // Struct, Union
    Affix_Type(const std::string & stringify,
               char numeric,
               size_t size,
               size_t alignment,
               size_t depth,
               size_t offset,

               std::vector<SSize_t> length,
               std::vector<Affix_Type *> subtypes)
        : numeric(numeric),
          size(size),
          _alignment(alignment),
          depth(depth),
          offset(offset),

          length(length),
          stringify(stringify),
          subtypes(subtypes) {};
    // Callbacks
    Affix_Type(const std::string & stringify,
               char numeric,
               size_t size,
               size_t alignment,
               size_t depth,
               size_t offset,
               std::vector<SSize_t> length,
               std::vector<Affix_Type *> subtypes,
               Affix_Type * restype)
        : numeric(numeric),
          size(size),
          _alignment(alignment),
          depth(depth),
          offset(offset),
          length(length),
          stringify(stringify),
          subtypes(subtypes),
          restype(restype) {};


    ~Affix_Type() {
        std::for_each(subtypes.begin(), subtypes.end(), [](auto argtype) { delete argtype; });

        subtypes.clear();
        if (restype != nullptr)
            delete restype;

        length.clear();
        if (_typedef != nullptr)
            free(_typedef);
    };

    size_t alignment(size_t _depth = 0) {
        return depth > _depth ? ALIGNOF_INTPTR_T : _alignment;
    }

public:  // for now...
    char numeric;
    bool const_flag = false;
    bool volitile_flag = false;
    bool restrict_flag = false;

    size_t size;
    size_t _alignment;
    size_t offset;
    size_t depth;  // pointer depth
    std::vector<SSize_t> length;
    std::string stringify;

    //
    void * subtype = nullptr;  // Affix_Type

    char * _typedef = nullptr;
    DCaggr * aggregate = nullptr;
    std::string field;  // If part of a struct

    std::vector<Affix_Type *> subtypes;  // list of Affix_Type for a callback
    Affix_Type * restype = nullptr;      // result type for a callback
};

class Affix_Pointer {
public:
    // Affix_Pointer(Affix_Type * type) : type(type) {};
    Affix_Pointer(Affix_Type * type, DCpointer address) : address(address), type(type) {};
    ~Affix_Pointer() = default;
    DCpointer address = nullptr;
    Affix_Type * type;
    size_t count;
    size_t position;
};

class Affix_Callback {
public:
    Affix_Callback(Affix_Type * type, SV * cv) : type(type), cv(cv) {};
    // Affix_Callback(const std::string & signature, SV * cv) : signature(signature) {};
    ~Affix_Callback() {
        // dTHXa(perl);
        // warn("DESTROY Affix_Callback*");
        return;
        /*
        SvREFCNT_dec(cv);  // allow it to be cleaned up
    if (cv != nullptr)
            sv_2mortal(cv);
        delete type;

        safefree(cv);
        if (retval != nullptr)
            sv_2mortal(retval);
        safefree(retval);*/
    };

public:  // for now
    std::string signature;
    std::string perl_sig;
    Affix_Type * type;
    SV * retval;
    SV * cv;
    dTHXfield(perl)
};

// Affix::affix(...) and Affix::wrap(...) System
class Affix {
public:  // for now
    Affix() {};

    ~Affix() {
        if (lib != nullptr)
            dlFreeLibrary(lib);
        // if (entry_point != nullptr) safefree(entry_point);
        std::for_each(subtypes.begin(), subtypes.end(), [](auto argtype) { delete argtype; });
        subtypes.clear();
        if (restype != nullptr)
            delete restype;
        // pointers.clear();
    };
    DLLib * lib = nullptr;            // safefree
    DCpointer entry_point = nullptr;  // not malloc'd
    std::string symbol;
    std::vector<Affix_Type *> subtypes;
    Affix_Type * restype = nullptr;
    SV * res = nullptr;  // time over ram
    // std::vector<Affix_Pointer *> pointers;
};

// var pin system
class Affix_Pin {  // Used in CUnion and pin()
public:
    Affix_Pointer * ptr;
    Affix_Type * type;
    DLLib * lib;
    Affix_Pin(DLLib * lib, Affix_Pointer * ptr, Affix_Type * type) : ptr(ptr), type(type), lib(lib) {};
    ~Affix_Pin() {
        ptr = nullptr;  // DO NOT FREE
        delete type;
        type = NULL;
        dlFreeLibrary(lib);
        lib = NULL;
    };
};
int get_pin(pTHX_ SV *, MAGIC *);
int set_pin(pTHX_ SV *, MAGIC *);
int free_pin(pTHX_ SV *, MAGIC *);
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

void _pin(pTHX_ SV * sv, Affix_Type * type, DCpointer ptr);  // pin.cxx

// Type system
SV * bless_ptr(pTHX_ DCpointer, Affix_Type *, const char * = "Affix::Pointer::Unmanaged");
Affix_Type * sv2type(pTHX_ SV * perl_type);

// marshal.cxx
SV * ptr2sv(pTHX_ Affix_Type *, DCpointer, size_t = 1);
DCpointer sv2ptr(pTHX_ Affix_Type *, SV *, size_t = 1, DCpointer = nullptr);
DCCallback * cv2dcb(pTHX_ Affix_Type *, SV *);  // callback system

// // Callback system
// struct CodeRefWrapper {
//     DCCallback * cb;
// };
DCsigchar cbHandler(DCCallback * cb, DCArgs * args, DCValue * result, DCpointer userdata);

// XS Boot
void boot_Affix_pin(pTHX_ CV *);
void boot_Affix_Pointer(pTHX_ CV *);
void boot_Affix_Lib(pTHX_ CV *);
void boot_Affix_Aggregate(pTHX_ CV *);
void boot_Affix_Platform(pTHX_ CV *);
void boot_Affix_Type(pTHX_ CV *);
void boot_Affix_Callback(pTHX_ CV *);

//
DLLib * load_library(const char * lib);
void free_library(DLLib * plib);
DCpointer find_symbol(DLLib * lib, const char * name);

extern "C" void Fiction_trigger(pTHX_ CV * cv);

#ifdef __cplusplus
} /* extern "C" */
#endif

// utils.cxx
DLLib * _affix_load_library(const char * lib);
SV * call_sub(pTHX_ const char * sub, SV * arg);

#endif  // AFFIX_H_SEEN