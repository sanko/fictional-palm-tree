use v5.38;
use experimental 'class';

class Affix::Type 1.234 {
    field $stringify : param;
    field $numeric : param;
    field $sizeof : param;
    field $alignment : param;
    field $offset : param  //= 0;
    field $length : param  //= ();    # array length
    field $typedef : param //= ();
    field $const : param   //= !1;

    #~ volitile  => !1,
    #~ restrict  => !1
    use overload '""' => sub { shift->stringify }, '0+' => sub { shift->numeric };

    method stringify {
        my $ret = $stringify;
        $ret = 'Const[ ' . $ret . ' ]'               if $const;
        $ret = 'typedef ' . $typedef . ' => ' . $ret if $typedef;
        $ret;
    }
    method numeric {$numeric}    # This needs :reader in perl 5.40
    method typedef ($type)       { $typedef = $type }
    method const   ( $tf //= 1 ) { $const   = $tf }
}

class Affix::Type::Void : isa(Affix::Type) { }

class Affix::Type::Bool : isa(Affix::Type) { }

class Affix::Type::Char : isa(Affix::Type) { }

class Affix::Type::UChar : isa(Affix::Type) { }

class Affix::Type::Int : isa(Affix::Type) { }

class Affix::Type::Pointer : isa(Affix::Type) {
    field $subtype : param;
    ADJUST {
        die 'Expected a known type' unless $subtype->isa('Affix::Type')
    }

    method stringify {
        'Pointer[ ' . $subtype->stringify . ' ]';
    }
}

sub Char() {
    Affix::Type::Char->new( stringify => 'Char', numeric => 'c', sizeof => 1, alignment => 1 );
}

sub Int() {
    Affix::Type::Int->new( stringify => 'Int', numeric => 'i', sizeof => 4, alignment => 4 );
}

sub Pointer ($subtype) {
    Affix::Type::Pointer->new( stringify => 'Pointer', numeric => 'p', sizeof => 8, alignment => 8, subtype => @$subtype );
}

sub typedef ( $name, $type ) {
    $type->typedef($name);
    my $fqn = $name =~ /::/ ? $name : [caller]->[0] . '::' . $name;
    {
        no strict 'refs';
        no warnings 'redefine';
        *{$fqn} = sub {$type};
        @{ $fqn . '::ISA' } = ref $type;
    }
    $type;
}

sub Const ($type) {
    $type->[0]->const(1);
    $type->[0];
}

# Test API
my $type = typedef Wow => Int;
warn $type;
warn Pointer [Int];
my $str = Pointer [ Const [Char] ];
warn $str;
typedef String => Pointer [ Const [Char] ];
warn String();
