use Test2::V0 '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[:types wrap affix];
$|++;
use t::lib::helper;
#
ok my $lib = compile_test_lib('236_types_struct'), 'build test lib';

# my $s = Struct [ first => String, second => String, third => Int ];
# use Data::Dump;
# ddx $s;
# done_testing;
# exit;
subtest offsetof => sub {
    isa_ok my $type = Struct [
        name => Struct [ first => String, last => String, middle => Char ],
        dob  => Struct [ y     => Int,    m    => Int,    d      => Int ],
        rate => Double,    # percentage
        term => Int        # months
        ],
        [ 'Affix::Type::Struct', 'Affix::Type' ];
    is $type->offsetof('name'),        wrap( $lib, 'offsetof_name',        [], Size_t )->(), 'offsetof(name)';
    is $type->offsetof('name.first'),  wrap( $lib, 'offsetof_name_first',  [], Size_t )->(), 'offsetof(name.first)';
    is $type->offsetof('name.middle'), wrap( $lib, 'offsetof_name_middle', [], Size_t )->(), 'offsetof(name.middle)';
    is $type->offsetof('name.last'),   wrap( $lib, 'offsetof_name_last',   [], Size_t )->(), 'offsetof(name.last)';
    is $type->offsetof('dob'),         wrap( $lib, 'offsetof_dob',         [], Size_t )->(), 'offsetof(dob)';
    is $type->offsetof('dob.y'),       wrap( $lib, 'offsetof_dob_y',       [], Size_t )->(), 'offsetof(dob.y)';
    is $type->offsetof('dob.m'),       wrap( $lib, 'offsetof_dob_m',       [], Size_t )->(), 'offsetof(dob.m)';
    is $type->offsetof('dob.d'),       wrap( $lib, 'offsetof_dob_d',       [], Size_t )->(), 'offsetof(dob.d)';
    is $type->offsetof('rate'),        wrap( $lib, 'offsetof_rate',        [], Size_t )->(), 'offsetof(rate)';
    is $type->offsetof('term'),        wrap( $lib, 'offsetof_term',        [], Size_t )->(), 'offsetof(term)';
};
typedef Example => Struct [
    bool      => Bool,
    char      => Char,
    uchar     => UChar,
    short     => Short,
    ushort    => UShort,
    int       => Int,
    uint      => UInt,
    long      => Long,
    ulong     => ULong,
    longlong  => LongLong,
    ulonglong => ULongLong,
    float     => Float,
    double    => Double,
    ptr       => Pointer [Void],
    str       => String,
    struct    => Struct [ int  => Int, char => Char ],
    struct2   => Struct [ str2 => String ],
    union     => Union [ i => Int, f   => Float ],
    union2    => Union [ i => Int, str => String ],
    wchar     => WChar,

    #~ TODO:
    #~ WChar
    #~ WString
    #~ CodeRef
    #~ Pointer[SV]
    #~ Array
];
subtest 'real world' => sub {
    ok my $lib = compile_test_lib( <<''), 'build test lib';
#include "std.h"
// ext: .cxx
#include <iostream>
class Point {
public:
  Point(int x = 0, int y = 0) : _x(x), _y(y) {}
  int getX() const { return _x; }
  int getY() const { return _y; }
  void setX(int x) { _x = x; }
  void setY(int y) { _y = y; }
  void display() const {
    std::cout << "Point: (" << _x << ", " << _y << ")" << std::endl;
  }
private:
  int _x;
  int _y;
};
// Function that takes a Point object by value and modifies its coordinates (copy is made)
extern "C"
DLLEXPORT void by_value(Point pt) {
  pt.setX(pt.getX() * 2);
  pt.setY(pt.getY() * 2);
  std::cout << "Point inside by_value: ";
  pt.display();  // Display the modified copy
}
extern "C"
DLLEXPORT void by_reference(Point * pt) {
  pt->setX(pt->getX() * 2);
  pt->setY(pt->getY() * 2);
  std::cout << "Point inside by_reference: ";
  pt->display();  // Display the modified copy
}
extern "C"
DLLEXPORT int init() {
  Point p1(5, 3);  // Create a Point object with x=5, y=3
  std::cout << "Original Point: ";
  p1.display();  // Display the original point
  by_value(p1);  // Pass p1 by value (copy is created)
  std::cout << "Point after by_value: ";
  p1.display();  // Original point remains unchanged
  return 0;
}

    isa_ok typedef( Point => Struct [ x => Int, y => Int ] ), ['Affix::Type'], 'typedef Point => ...';

    # affix $lib, ['init' => 'hit_it'], [], Int;
    isa_ok affix( $lib, 'by_value',     [ Point() ],             Void ), ['Affix'], 'void by_value( Point )';
    isa_ok affix( $lib, 'by_reference', [ Pointer [ Point() ] ], Void ), ['Affix'], 'void by_reference( Point * )';

    # by_value( { x => 1001, y => 1002 } );
    # TODO: I really need a better test here. Maybe it keeps the reference and we later get x from it?
    ok lives { by_reference( { x => 1001, y => 1002 } ) }, 'by_reference';
};
#
note 'TODO: aggregates by value!!!!!!!!!!!!!!!!!!!!!!!!!';
done_testing;
exit;
subtest 'affix functions' => sub {
    isa_ok Affix::affix( $lib, 'SIZEOF', [], Size_t ), [qw[Affix]], 'SIZEOF';
    subtest 'functions with aggregates' => sub {
        plan skip_all 'dyncall does not support passing aggregates by value on this platform' unless Affix::Platform::AggrByValue();
        isa_ok Affix::affix( $lib, 'get_bool',      [ Example() ], Bool ),           [qw[Affix]], 'get_bool';
        isa_ok Affix::affix( $lib, 'get_char',      [ Example() ], Char ),           [qw[Affix]], 'get_char';
        isa_ok Affix::affix( $lib, 'get_uchar',     [ Example() ], UChar ),          [qw[Affix]], 'get_uchar';
        isa_ok Affix::affix( $lib, 'get_short',     [ Example() ], Short ),          [qw[Affix]], 'get_short';
        isa_ok Affix::affix( $lib, 'get_ushort',    [ Example() ], UShort ),         [qw[Affix]], 'get_ushort';
        isa_ok Affix::affix( $lib, 'get_int',       [ Example() ], Int ),            [qw[Affix]], 'get_int';
        isa_ok Affix::affix( $lib, 'get_uint',      [ Example() ], UInt ),           [qw[Affix]], 'get_uint';
        isa_ok Affix::affix( $lib, 'get_long',      [ Example() ], Long ),           [qw[Affix]], 'get_long';
        isa_ok Affix::affix( $lib, 'get_ulong',     [ Example() ], ULong ),          [qw[Affix]], 'get_ulong';
        isa_ok Affix::affix( $lib, 'get_longlong',  [ Example() ], LongLong ),       [qw[Affix]], 'get_longlong';
        isa_ok Affix::affix( $lib, 'get_ulonglong', [ Example() ], ULongLong ),      [qw[Affix]], 'get_ulonglong';
        isa_ok Affix::affix( $lib, 'get_float',     [ Example() ], Float ),          [qw[Affix]], 'get_float';
        isa_ok Affix::affix( $lib, 'get_double',    [ Example() ], Double ),         [qw[Affix]], 'get_double';
        isa_ok Affix::affix( $lib, 'get_ptr',       [ Example() ], Pointer [Void] ), [qw[Affix]], 'get_ptr';
        isa_ok Affix::affix( $lib, 'get_str',       [ Example() ], String ),         [qw[Affix]], 'get_str';
        isa_ok Affix::affix( $lib, 'get_struct',    [],            Example() ),      [qw[Affix]], 'get_struct';
    };
    isa_ok Affix::affix( $lib, 'get_nested_offset',  [], Size_t ), [qw[Affix]], 'get_nested_offset';
    isa_ok Affix::affix( $lib, 'get_nested2_offset', [], Size_t ), [qw[Affix]], 'get_nested2_offset';
    subtest 'more functions with aggregates' => sub {
        plan skip_all 'dyncall does not support passing aggregates by value on this platform' unless Affix::Platform::AggrByValue();
        isa_ok Affix::affix( $lib, 'get_nested_int', [ Example() ], Int ),    [qw[Affix]], 'get_nested_int';
        isa_ok Affix::affix( $lib, 'get_nested_str', [ Example() ], String ), [qw[Affix]], 'get_nested_str';
    };
    isa_ok Affix::affix( $lib, 'get_union2_offset',     [], Size_t ), [qw[Affix]], 'get_union2_offset';
    isa_ok Affix::affix( $lib, 'get_union2_str_offset', [], Size_t ), [qw[Affix]], 'get_union2_str_offset';
    subtest 'more functions with aggregates' => sub {
        plan skip_all 'dyncall does not support passing aggregates by value on this platform' unless Affix::Platform::AggrByValue();
        isa_ok Affix::affix( $lib, 'get_wchar', [ Example() ], WChar ), [qw[Affix]], 'get_wchar';
    };
};
my $struct = {
    bool      => !0,
    char      => 'q',
    uchar     => 'Q',
    short     => 1000,
    ushort    => 100,
    int       => 12345,
    uint      => 999,
    long      => 987654321,
    ulong     => 789,
    longlong  => 2345,
    ulonglong => 11111111,
    float     => 3.14,
    double    => 1.2345,
    ptr       => 'Anything can go here',
    str       => 'Something can go here too',
    struct    => { int  => 4321, char => 'M' },
    struct2   => { str2 => 'Well, this would work.' },
    union     => { f    => 1122233.009988 },
    union2    => { str  => 'sheesh' },
    wchar     => 'ッ'
};
#
#~ die pack 'i', ord 'ッ';
is Affix::Type::sizeof( Example() ), SIZEOF(), 'our size calculation vs platform';
done_testing;
exit;
subtest 'functions with aggregates' => sub {
    plan skip_all 'dyncall does not support passing aggregates by value on this platform' unless Affix::Platform::AggrByValue();
    is get_bool($struct),         T(),                                    'get_bool( $struct )';
    is get_char($struct),         'q',                                    'get_char( $struct )';
    is get_uchar($struct),        'Q',                                    'get_uchar( $struct )';
    is get_short($struct),        1000,                                   'get_short( $struct )';
    is get_ushort($struct),       100,                                    'get_ushort( $struct )';
    is get_int($struct),          12345,                                  'get_int( $struct )';
    is get_uint($struct),         999,                                    'get_uint( $struct )';
    is get_long($struct),         987654321,                              'get_long( $struct )';
    is get_ulong($struct),        789,                                    'get_ulong( $struct )';
    is get_longlong($struct),     2345,                                   'get_longlong( $struct )';
    is get_ulonglong($struct),    11111111,                               'get_ulonglong( $struct )';
    is get_float($struct),        float( 3.14, tolerance => 0.000001 ),   'get_float( $struct )';
    is get_double($struct),       float( 1.2345, tolerance => 0.000001 ), 'get_double( $struct )';
    is get_ptr($struct)->raw(20), 'Anything can go here',                 'get_ptr( $struct )';
    is get_str($struct),          'Something can go here too',            'get_str( $struct )';
    is get_nested_int($struct),   4321,                                   'get_nested_int( $struct )';
    is get_nested_str($struct),   'Well, this would work.',               'get_nested_str( $struct )';
    is get_wchar($struct),        'ッ',                                    'get_wchar( $struct )';
};
is get_nested_offset(),     Example()->offsetof('struct'),     'get_nested_offset()';
is get_nested2_offset(),    Example()->offsetof('struct2'),    'get_nested2_offset()';
is get_union2_offset(),     Example()->offsetof('union2'),     'get_union2_offset()';
is get_union2_str_offset(), Example()->offsetof('union2.str'), 'get_union2_str_offset()';
subtest 'the full monty' => sub {
    plan skip_all 'dyncall does not support passing aggregates by value on this platform' unless Affix::Platform::AggrByValue();
    is get_struct(),
        {
        bool      => T(),
        char      => 'M',
        double    => float( 9.7, tolerance => 0.00001 ),
        float     => float( 2.3, tolerance => 0.00001 ),
        int       => 1123,
        long      => 13579,
        longlong  => 1122334455,
        ptr       => U(),
        short     => 35,
        str       => 'Hello!',
        uchar     => 'm',
        uint      => 8890,
        ulong     => 97531,
        ulonglong => 9988776655,
        ushort    => 88,
        struct    => { int  => 1111, char => 'Q' },
        struct2   => { str2 => 'Alpha' },
        union     => hash { field f   => float( 9876.123, tolerance => 0.001 ); etc; },
        union2    => hash { field str => 'Beta';                                etc; },
        wchar     => '火'
        },
        'get_struct()';
};
done_testing;
