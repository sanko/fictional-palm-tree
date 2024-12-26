use v5.40;
use feature qw[class];
no warnings qw[experimental::class experimental::try];
use Data::Printer;
use Carp::Always;
$|++;
#
class Affix::Compiler {
    use Config     qw[%Config];
    use Path::Tiny qw[path tempdir];
    use File::Spec;
    use ExtUtils::MakeMaker;
    #
    field $os : param : reader        //= $^O;
    field $cleanup : param : reader   //= 0;
    field $version : param : reader   //= ();
    field $build_dir : param : reader //= tempdir( CLEANUP => $cleanup );
    field $name : param : reader;
    field $libname : reader
        = $build_dir->child( ( ( $os eq 'MSWin32' || $name =~ /^lib/ ) ? '' : 'lib' ) .
            $name . '.' .
            $Config{so} .
            ( $os eq 'MSWin32' || !defined $version ? '' : '.' . $version ) )->absolute;
    field $platform : reader = ();    # ADJUST
    field $source : param : reader;
    field $flags : param : reader //= {

        #~ ldflags => $Config{ldflags},
        cflags   => $Config{cflags},
        cppflags => $Config{cxxflags}
    };
    field @objs;
    ADJUST {
        $source = [ map { _filemap($_) } @$source ];
    }
    #
    sub _can_run(@cmd) {
        state $paths //= [ map { path($_)->realpath } File::Spec->path ];
        for my $exe (@cmd) {
            grep { return path($_) if $_ = MM->maybe_command($_) } $exe, map { $_->child($exe) } @$paths;
        }
    }
    #
    field $linker : reader : param //= _can_run qw[g++ ld];

    #~ https://gcc.gnu.org/onlinedocs/gcc-3.4.0/gnat_ug_unx/Creating-an-Ada-Library.html
    field $ada : reader : param //= _can_run qw[gnatmake];

    #~ https://fasterthanli.me/series/making-our-own-executable-packer/part-5
    #~ https://stackoverflow.com/questions/71704813/writing-and-linking-shared-libraries-in-assembly-32-bit
    #~ https://github.com/therealdreg/nasm_linux_x86_64_pure_sharedlib
    field $asm : reader : param //= _can_run qw[nasm as];

    #~ https://c3-lang.org/build-your-project/build-commands/
    field $c3 : reader : param //= _can_run qw[c3c];

    #~ https://www.circle-lang.org/site/index.html
    field $circle : reader : param //= _can_run qw[circle];

    #~ https://mazeez.dev/posts/writing-native-libraries-in-csharp
    #~ https://medium.com/@sixpeteunder/how-to-build-a-shared-library-in-c-sharp-and-call-it-from-java-code-6931260d01e5
    field $csharp : reader : param //= _can_run qw[dotnet];

    # cobc: https://gnucobol.sourceforge.io/
    field $cobol : reader : param //= _can_run qw[cobc cobol cob cob2];

    #~ https://github.com/crystal-lang/crystal/issues/921#issuecomment-2413541412
    field $crystal : reader : param //= _can_run qw[crystal];

    #~ https://wiki.liberty-eiffel.org/index.php/Compile
    #~ https://svn.eiffel.com/eiffelstudio-public/branches/Eiffel_54/Delivery/docs/papers/dll.html
    field $eiffel : reader : param //= _can_run qw[se];

    #~ https://dlang.org/articles/dll-linux.html#dso9
    #~ dmd -c dll.d -fPIC
    #~ dmd -oflibdll.so dll.o -shared -defaultlib=libphobos2.so -L-rpath=/path/to/where/shared/library/is
    field $d : reader : param //= _can_run qw[dmd];

    #~ https://futhark.readthedocs.io/en/stable/usage.html
    field $futhark : reader : param //= _can_run qw[futhark];    # .fut => .c

    #~ https://github.com/secana/Native-FSharp-Library
    #~ https://secanablog.wordpress.com/2020/02/01/writing-a-native-library-in-f-which-can-be-called-from-c/
    field $fsharp : reader : param //= _can_run qw[dotnet];

    #~ https://medium.com/@walkert/fun-building-shared-libraries-in-go-639500a6a669
    #~ https://github.com/vladimirvivien/go-cshared-examples
    field $go : reader : param //= _can_run qw[go];

    #~ https://github.com/bennoleslie/haskell-shared-example
    #~ https://www.hobson.space/posts/haskell-foreign-library/
    field $haskell : reader : param //= _can_run qw[ghc cabal];

    #~ https://peterme.net/dynamic-libraries-in-nim.html
    field $nim : reader : param //= _can_run qw[nim];    # .nim => .c

    #~ https://odin-lang.org/news/calling-odin-from-python/
    field $odin : reader : param //= _can_run qw[odin];

    #~ https://p-org.github.io/P/getstarted/install/#step-4-recommended-ide-optional
    #~ https://p-org.github.io/P/getstarted/usingP/#compiling-a-p-program
    field $p : reader : param //= _can_run qw[p];    # .p => C#

    #~ https://blog.asleson.org/2021/02/23/how-to-writing-a-c-shared-library-in-rust/
    field $rust : reader : param //= _can_run qw[cargo];

    #~ swiftc point.swift -emit-module -emit-library
    #~ https://forums.swift.org/t/creating-a-c-accessible-shared-library-in-swift/45329/5
    #~ https://theswiftdev.com/building-static-and-dynamic-swift-libraries-using-the-swift-compiler/#should-i-choose-dynamic-or-static-linking
    field $swift : reader : param //= _can_run qw[swiftc];

    #~ https://www.rangakrish.com/index.php/2023/04/02/building-v-language-dll/
    #~ https://dev.to/piterweb/how-to-create-and-use-dlls-on-vlang-1p13
    field $v : reader : param //= _can_run qw[v];

    #~ https://ziglang.org/documentation/0.13.0/#Exporting-a-C-Library
    #~ zig build-lib mathtest.zig -dynamic
    field $zig : reader : param //= _can_run qw[zig];
    #
    ADJUST {
    }

    sub _filemap( $file, $language //= () ) {
        #
        ($_) = $file =~ m[\.(?=[^.]*\z)([^.]+)\z]i;
        $language //=                                                     #
            /^(?:ada|adb|ads|ali)$/i                  ? 'Ada' :           #
            /^(?:asm|s|a)$/i                          ? 'Assembly' :      #
            /^(?:c(?:c|pp|xx))$/i                     ? 'CPP' :           #
            /^c$/i                                    ? 'C' :             #
            /^c3$/i                                   ? 'C3' :            #
            /^ace$/i                                  ? 'Eiffel' :        #
            /^(?:f(?:or)?|f(?:77|90|95|0[38]|18)?)$/i ? 'Fortran' :       #
            /^m+$/i                                   ? 'ObjectiveC' :    #
            /^p$/i                                    ? 'P' :             #
            /^v$/i                                    ? 'VLang' :         #
            ();
        ( 'Affix::Compiler::File::' . ${language} )->new( path => $file );
    }
    #
    method compile() {
        @objs = grep {defined} map { $_->compile($flags) } @$source;
    }

    method link() {
        use Data::Dump;
        warn join ' ', $linker, $flags->{ldflags} // (), '-shared', ( map { $_->absolute->stringify } @objs ), '-o', $libname->stringify;
        return $libname
            unless system $linker, $flags->{ldflags} // (), '-shared', ( map { $_->absolute->stringify } @objs ), '-o', $libname->stringify;
    }

    #~ field $cxx;
    #~ field $d;
    #~ field $crystal;
};

class Affix::Compiler::File {
    use Config     qw[%Config];
    use Path::Tiny qw[];
    field $path : reader : param;
    field $flags : reader : param //= ();
    field $obj : reader : param   //= ();
    ADJUST {
        $path = Path::Tiny::path($path)->absolute unless builtin::blessed $path;
        $obj //= $path->sibling( $path->basename(qr/\..+?$/) . $Config{_o} );
    }
    method compile() {...}
}

class Affix::Compiler::File::CPP : isa(Affix::Compiler::File) {

    # https://learn.microsoft.com/en-us/cpp
    # https://gcc.gnu.org/
    # https://clang.llvm.org/
    #~ https://www.intel.com/content/www/us/en/developer/tools/oneapi/dpc-compiler.html
    #~ https://www.ibm.com/products/c-and-c-plus-plus-compiler-family
    #~ https://docs.oracle.com/cd/E37069_01/html/E37073/gkobs.html
    #~ https://www.edg.com/c
    #~ https://www.circle-lang.org/site/index.html
    field $compiler : reader : param //= Affix::Compiler::_can_run qw[g++]

        #~ clang++ cl icpx ibm-clang++ CC eccp circle]
        ;

    method compile($flags) {
        $self->obj unless system $compiler, '-g', '-c', '-fPIC', $flags->{cxxflags} // (), $self->path, '-o', $self->obj;
    }
}

class Affix::Compiler::File::C : isa(Affix::Compiler::File) {
    use Config qw[%Config];
    field $compiler : reader : param //= Affix::Compiler::_can_run $Config{cc}, qw[gcc]

        #~ clang cl icx ibm-clang CC eccp circle]
        ;

    method compile($flags) {
        $self->obj unless system $compiler, '-g', '-c', '-Wall', '-fPIC', $flags->{cflags} // (), $self->path, '-o', $self->obj;
    }
}

class Affix::Compiler::File::Fortran : isa(Affix::Compiler::File) {

    # GNU, Intel, Intel Classic
    my $compiler = Affix::Compiler::_can_run qw[gfortran ifx ifort];

    method compile($flags) {
        $self->obj unless system $compiler, '-shared', '-fPIC', $flags->{fflags} // (), $self->path, '-o', $self->obj;
    }
}

class Affix::Compiler::FortranXXXXXX : isa(Affix::Compiler) {
    use Config     qw[%Config];
    use IPC::Cmd   qw[can_run];
    use Path::Tiny qw[path];
    field $exe : reader;
    field $compiler : reader;
    field $linker : reader;
    #
    ADJUST {
        if ( $exe = can_run('gfortran') ) {
            $compiler = method( $file, $obj, $flags ) {
                system $self->exe, qw[-c -fPIC], $file;
                die "failed to execute: $!\n"                                                                           if $? == -1;
                die sprintf "child died with signal %d, %s coredump\n", ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without' if $? & 127;
                $obj
            };
            $linker = method($objs) {
                system $self->exe, qw[-shared], ( map { $_->stringify } @$objs ), '-o blah.so';
                die "failed to execute: $!\n"                                                                           if $? == -1;
                die sprintf "child died with signal %d, %s coredump\n", ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without' if $? & 127;
                'ok!'
            };
        }
        elsif ( $exe = can_run('ifx') )   { }
        elsif ( $exe = can_run('ifort') ) { }
    }
    #
    method compile( $file, $obj //= (), $flags //= '' ) {
        $file = path($file)->absolute unless builtin::blessed $file;
        $obj //= $file->sibling( $file->basename(qr/\..+?$/) . $Config{_o} );
        try {
            return $compiler->( $self, $file, $obj, $flags );
        }
        catch ($err) { warn $err; }
    }

    method link($objs) {
        $objs = [ map { builtin::blessed $_ ? $_ : path($_)->absolute } @$objs ];
        try {
            return $linker->( $self, $objs );
        }
        catch ($err) { warn $err; }
    }
}

#~ "..\t\src\99_preview.cxx"
#~ "..\t\src\237_types_struct.c"
#~ '..\t\src\86_affix_abi_fortran\hello.f90'
class Affix::Compiler::D { }
#
my $compiler = Affix::Compiler->new(
    name    => 'testing',
    version => '1.0',
    source  => [ '..\t\src\86_affix_abi_fortran\hello.f90', '..\t\src\99_preview.cxx', '..\t\src\237_types_struct.c' ]
);
p $compiler;
p $compiler->ada;
p $compiler->asm;
p $compiler->c3;
p $compiler->circle;
p $compiler->cobol;
p $compiler->crystal;
p $compiler->csharp;
p $compiler->d;
p $compiler->eiffel;
p $compiler->futhark;
p $compiler->fsharp;
p $compiler->go;
p $compiler->haskell;
p $compiler->nim;
p $compiler->odin;
p $compiler->p;
p $compiler->rust;
p $compiler->swift;
p $compiler->zig;
p $compiler->source;
use Data::Dump;
ddx $compiler->compile;
system 'nm', $compiler->link;
#
#~ p $fortran;
#~ warn my $obj = $fortran->compile(
#~ '..\t\src\86_affix_abi_fortran\hello.f90', );
#~ warn $obj;
#~ warn $fortran->link( [$obj] );
__END__

class My::Builder 1.0 {
    use Path::Tiny;
    use Config;
    field $linker : param  = 'g++';             # Default linker
    field $cxx : param     = 'g++ -mconsole';
    field $c : param       = 'gcc';             # GNU (Digital Mars: ldc2)
    field $rust : param    = 'rustc';
    field $fortran : param = 'gfortran -c';     # GNU (Intel: ifort)
    field $d : param       = 'dmd -c';

    method c ($input) {
        my ( $fh, $output ) = tempfile( SUFFIX => '.o', UNLINK => 1 );
        close $fh;
        return $self->compile( 'gcc', $input, $output );
    }

    method cpp ( $input, @etc ) {
        map {
            my $source = builtin::blessed $_ ? $_ : Path::Tiny::path($_);
            my $output = Path::Tiny->tempfile( { realpath => 1 }, TEMPLATE => $source->basename . 'XXXXXXXX', SUFFIX => $Config{_o} );
            system( join ' ', $cxx, $_, '-o', $output ) ? () : $output->absolute;
        } $input, @etc;
    }

    method fortran ( $input, @etc ) {
        map {
            my $source = builtin::blessed $_ ? $_ : Path::Tiny::path($_);
            my $output = Path::Tiny->tempfile( { realpath => 1 }, TEMPLATE => $source->basename . 'XXXXXXXX', SUFFIX => $Config{_o} );
            system( join ' ', $fortran, $_, '-o', $output ) ? () : $output->absolute;
            } $input, @etc

        #~ '-fno-underscoring', # XXX: should I be lazy and force bind(C, name="symbol")
        #~ ( ref $source ? @$source : $source ), '-fPIC',
        #~ ( $gnu ? '-shared' : ( $^O eq 'MSWin32' ? '/libs:dll' :
        #~ $^O eq 'darwin' ? '-dynamiclib' : '-shared' ) ), '-o', $self->output
    }

    method d ( $input, @etc ) {
        map {
            my $source = builtin::blessed $_ ? $_ : Path::Tiny::path($_);
            my $output = Path::Tiny->tempfile( { realpath => 1 }, TEMPLATE => $source->basename . 'XXXXXXXX', SUFFIX => $Config{_o} );
            system( join ' ', $d, $_, '-o', $output ) ? () : $output->absolute;
        } $input, @etc;
    }

    method rust ($input) {
        my ( $fh, $output ) = tempfile( SUFFIX => '.o', UNLINK => 1 );
        close $fh;
        my $tmp_rs  = path($input);
        my $tmp_out = path($output);
        my $cmd     = "rustc --crate-type=staticlib $tmp_rs -o $tmp_out";
        print "Executing: $cmd\n";
        system($cmd) == 0 or die "Rust compilation failed: $!";
        return $output;
    }

    method link (@objects) {
        die "No objects to link" unless @objects;
        my $lib = Path::Tiny->tempfile( { realpath => 1 }, TEMPLATE => ( $^O eq 'MSWin32' ? '' : 'lib' ) . 'XXXXXXXX', SUFFIX => '.' . $Config{so} );
        my @cmd = ( $linker, qw[-shared -o], $lib, @objects );
        warn join ' ', @cmd;
        die "Linking failed: $!" if system @cmd;
        return $lib;
    }
}

#~ my $compiler = My::Builder->new();
#~ p $compiler;
#~ my @libs = (
#~ $compiler->cpp('..\t\src\99_preview.cxx'),
#~ $compiler->fortran('..\t\src\86_affix_abi_fortran\hello.f90')
#~ );
#~ p @libs;
#~ my $lib = $compiler->link(@libs);
#~ warn $lib;
#~ system 'nm', $lib;
#~ "..\t\src\99_preview.cxx"
#~ "..\t\src\237_types_struct.c"
#~ '..\t\src\86_affix_abi_fortran\hello.f90'
1;
#
use Data::Printer;
use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix::Builder;
my $c   = Affix::Builder::C->new( version => '1.0', source => '..\t\src\237_types_struct.c' );
my $cxx = Affix::Builder::CPP->new(

    #~ version => '1.0',
    source => '..\t\src\99_preview.cxx'
);

my $b           = Affix::Builder->new;
my $o           = $b->compile( source => '..\t\src\237_types_struct.c', obj => 'something.obj', cflags => '' );
my $l           = $o->link( ldflags => '', name => '' );




my $fortran     = Affix::Builder::Fortran->new( source => ['../t/src/86_affix_abi_fortran/hello.f90'] );
my $lib_fortran = $fortran->build;

#~ warn $b->libname;
my $lib_c   = $c->build;
my $lib_cxx = $cxx->build;
warn $lib_fortran;

#~ system 'nm', $lib_c;
#~ warn $lib;
#~ p $b;
use Affix;
affix $lib_c,       'offsetof_dob_d',                 [],    Size_t;
affix $lib_cxx,     [ '_Z8negativei' => 'negative' ], [Int], Int;
affix $lib_fortran, 'func',                           [Int], Int;
warn offsetof_dob_d();
warn negative(-4);
warn negative(4);
warn func(3);

#~ my $b2 = Affix::Builder::CPP->new( source => ['..\t\src\99_preview.cxx'] );
#~ warn $b2->name;
__END__

my $lib = My::Builder::Fortran->new(
# https://fortran-lang.org/en/learn/building_programs/managing_libraries/
    version => (),
    platform => 'GNU',  # or 'Intel' (ifort); 'GNU' (gfortran) is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
)->lib;

my $lib = My::Builder::CPP->new(
    compiler => 'gcc',  # or MSVC or BCC
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

my $lib = My::Builder::C->new(
    compiler => 'gcc',  # or ; gfortran is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

my $lib = My::Builder::D->new(
    compiler => 'gcc',  # or ; gfortran is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

my $lib = My::Builder::Rust->new(
# https://blog.asleson.org/2021/02/23/how-to-writing-a-c-shared-library-in-rust/
# https://ericchiang.github.io/post/rust-libs/
    compiler => 'gcc',  # or ; gfortran is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

my $lib = My::Builder::Go->new(
# https://medium.com/learning-the-go-programming-language/calling-go-functions-from-other-languages-4c7d8bcc69bf#.n73as5d6d
    compiler => 'gcc',  # or ; gfortran is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

my $lib = My::Builder::Crystal->new(
# https://crystal-lang.org/reference/1.14/man/crystal/index.html
    compiler => 'gcc',  # or ; gfortran is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

my $lib = My::Builder::Julia->new(
# https://github.com/tshort/StaticCompiler.jl Only works on Unix
    compiler => 'gcc',  # or ; gfortran is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

my $lib = My::Builder::Nim->new(
    compiler => 'gcc',  # or ; gfortran is default
    source => ['hello.f90', 'goodbye.f90'],
    flags  => '', # '-fpic' by default
    static => 1, # false, makes name .a rather than .so or .dll
    name   => 'blah' # lib's name. Becomes 'libblah.so' on Unix, 'blah.dll' on Windows
);

















{

    package My::Builder;
    use strict;
    use warnings;
    use Moo;
    use Path::Tiny;
    use File::Temp qw/tempfile/;
    has 'compiler_paths' => (
        is      => 'ro',
        default => sub {
            {   c       => '/usr/bin/gcc',        # Adjust paths as needed
                cpp     => '/usr/bin/g++',
                fortran => '/usr/bin/gfortran',
                d       => '/usr/bin/ldc2',
                rust    => '/usr/bin/rustc',
                linker  => '/usr/bin/g++',        # or ld, or clang++
            }
        },
    );

    sub compile {
        my ( $self, $lang, $source ) = @_;
        my $compiler    = $self->compiler_paths->{$lang} or die "No compiler configured for language: $lang";
        my $source_path = path($source)->absolute;
        die "Source file not found: $source_path" unless $source_path->exists;
        my ( $fh, $obj_path ) = tempfile( SUFFIX => '.o', UNLINK => 1 );
        close $fh;
        my @cmd;
        if ( $lang eq 'rust' ) {
            @cmd = ( $compiler, '--crate-type=rlib', '-o', $obj_path, $source_path );
        }
        elsif ( $lang eq 'd' ) {
            @cmd = ( $compiler, '-c', '-o', $obj_path, $source_path );
        }
        else {
            @cmd = ( $compiler, '-c', '-o', $obj_path, $source_path );
        }
        my $cmd_str = join " ", @cmd;
        print "Executing: $cmd_str\n";
        system(@cmd) == 0 or die "Compilation failed for $source: $?";
        return $obj_path;
    }
    sub c       { shift->compile( 'c',       @_ ); }
    sub cpp     { shift->compile( 'cpp',     @_ ); }
    sub fortran { shift->compile( 'fortran', @_ ); }
    sub d       { shift->compile( 'd',       @_ ); }
    sub rust    { shift->compile( 'rust',    @_ ); }

    sub link {
        my ( $self, @objs ) = @_;
        die "No objects to link" unless @objs;
        my $linker = $self->compiler_paths->{linker} or die "No linker configured";
        my ( $fh, $lib_path ) = tempfile( SUFFIX => '.so', UNLINK => 1 );
        close $fh;
        my @cmd     = ( $linker, '-shared', '-o', $lib_path, @objs );
        my $cmd_str = join " ", @cmd;
        print "Executing: $cmd_str\n";
        system(@cmd) == 0 or die "Linking failed: $?";
        return $lib_path;
    }
    1;
}
