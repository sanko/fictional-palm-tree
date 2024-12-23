use v5.40;
use feature qw[class];
no warnings qw[experimental::class];

class Affix::Builder 1.00 {
    use Carp       qw[confess];
    use Config     qw[%Config];
    use Path::Tiny qw[tempdir path];
    $Carp::Internal{ (__PACKAGE__) }++;
    field $source : reader : param;
    field $name : param //= ();
    field $version : reader : param //= ();
    #
    field $test = __CLASS__->can('test') ? __CLASS__->test : ();
    #
    field $os : reader : param        //= $^O;
    field $cleanup : param            //= 0;
    field $build_dir : reader : param //= tempdir( CLEANUP => $cleanup );
    field $verbose : param            //= 0;
    field $libname : reader : param   //= ();
    #
    field $compiler = __CLASS__->can('find_compiler') ? __CLASS__->find_compiler : ();
    #
    #~ method build() {...}
    method build() {
        return $self->libname if $self->libname->exists && !grep { $self->libname->stat->mtime < $_->stat->mtime } @{ $self->source };
        $self->$compiler;
    }
    ADJUST {
        confess 'subclass ' . __PACKAGE__ if __CLASS__ eq __PACKAGE__;
        $source = [$source] unless ref $source eq 'ARRAY';
        $source = [ map { builtin::blessed($_) ? $_ : path($_) } @$source ];
        $name //= $source->[0]->basename(qr[\..*?$]);
        $build_dir = path($build_dir)->absolute unless builtin::blessed $build_dir;
        $libname
            //= $build_dir->child( ( $os ne 'MSWin32' && $name !~ /^lib/ ? 'lib' : '' ) .
                $name . '.' .
                $Config{so} .
                ( $os ne 'MSWin32' && defined $version ? '.' . $version : '' ) );
    }
    method DESTROY { }
}

class Affix::Builder::C 1.00 : isa(Affix::Builder) {
    use Config qw[%Config];
    use Carp   qw[confess];
    $Carp::Internal{ (__PACKAGE__) }++;
    field $cflags : reader : param  //= $Config{cccdlflags} // '';
    field $ldflags : reader : param //= $Config{ccdlflags}  // '';

    sub find_compiler($pkg) {
        return method() {
            my @objs;

            # compile
            for my $source ( @{ $self->source } ) {
                my $obj = $self->build_dir->child( $source->basename(qr[\..*?$]) . $Config{_o} );
                push @objs, $obj
                    if !system grep { length $_ && /\w/ } $Config{cc}, $self->cflags, '-c', $source->absolute->stringify, '-o',
                    $obj->absolute->stringify;
            }

            # link/archive
            return $self->libname
                if !system grep { length $_ && /\w/ } $Config{cc}, $self->ldflags, '-shared', '-o', map { $_->absolute->stringify } $self->libname,
                @objs
        };
        return method() {
            my @objs;

            # compile
            for my $source ( @{ $self->source } ) {
                my $obj = $self->build_dir->child( $source->basename(qr[\..*?$]) . $Config{_o} );
                push @objs, $obj
                    if !system grep { length $_ && /\w/ } $Config{cc}, $self->cflags, '-c', $source->absolute->stringify, '-o',
                    $obj->absolute->stringify;
            }

            # link/archive
            return $self->libname
                if !system grep { length $_ && /\w/ } $Config{cc}, '/DLL', '/OUT:' . $self->libname, map { $_->absolute->stringify } @objs,
                @objs,    # twice
                $self->ldflags, map { $_->absolute->stringify } $self->libname, @objs
        }
        if ( ( $Config{cc} =~ /cl/ && `$Config{cc} /?` =~ /Microsoft/ ) ||
            ( $Config{cc} =~ /icl|icc/ && `$Config{cc} /version` =~ /Intel/ ) ||
            ( $Config{cc} =~ /dmc/     && `$Config{cc} -v`       =~ /Mars/ ) );
        method() { confess 'Failed to locate C compiler' };
    }
}

class Affix::Builder::CPP 1.00 : isa(Affix::Builder::C) {
    use Config qw[%Config];
    use Carp   qw[confess];
    $Carp::Internal{ (__PACKAGE__) }++;

    sub find_compiler($pkg) {
        return method() {
            my @objs;

            # compile
            for my $source ( @{ $self->source } ) {
                my $obj = $self->build_dir->child( $source->basename(qr[\..*?$]) . $Config{_o} );
                push @objs, $obj
                    if !system grep { length $_ && /\w/ } 'g++', $self->cflags, '-fPIC', '-c', $source->absolute->stringify, '-o',
                    $obj->absolute->stringify;
            }

            # link/archive
            return $self->libname
                if !system grep { length $_ && /\w/ } 'g++', $self->ldflags, '-shared', '-o', map { $_->absolute->stringify } $self->libname, @objs
        };
        return method() {
            my @objs;

            # compile
            for my $source ( @{ $self->source } ) {
                my $obj = $self->build_dir->child( $source->basename(qr[\..*?$]) . $Config{_o} );
                push @objs, $obj
                    if !system grep { length $_ && /\w/ } $Config{cc}, $self->cflags, '-c', $source->absolute->stringify, '-o',
                    $obj->absolute->stringify;
            }

            # link/archive
            return $self->libname
                if !system grep { length $_ && /\w/ } $Config{cc}, '/DLL', '/OUT:' . $self->libname, map { $_->absolute->stringify } @objs,
                @objs,    # twice
                $self->ldflags, map { $_->absolute->stringify } $self->libname, @objs
        }
        if ( ( $Config{cc} =~ /cl/ && `$Config{cc} /?` =~ /Microsoft/ ) ||
            ( $Config{cc} =~ /icl|icc/ && `$Config{cc} /version` =~ /Intel/ ) ||
            ( $Config{cc} =~ /dmc/     && `$Config{cc} -v`       =~ /Mars/ ) );
        method() { confess 'Failed to locate C compiler' };
    }
}

class Affix::Builder::Crystal 1.00 : isa(Affix::Builder) { }

class Affix::Builder::D 1.00 : isa(Affix::Builder) { }

class Affix::Builder::Fortran 1.00 : isa(Affix::Builder) {    # https://fortran-lang.org/learn/building_programs/managing_libraries/
    use Config qw[%Config];
    use Carp   qw[confess];
    $Carp::Internal{ (__PACKAGE__) }++;

    sub find_compiler($pkg) {                                 # GNU
        return method() {
            my @objs;

            # compile
            for my $source ( @{ $self->source } ) {
                my $obj = $self->build_dir->child( $source->basename(qr[\..*?$]) . $Config{_o} );
                push @objs, $obj if !system grep { length $_ && /\w/ } 'gfortran', '-c', $source->absolute->stringify,

                    #~ '-fno-underscoring', # XXX: should I be lazy and force bind(C, name="symbol")
                    ( $self->os eq 'darwin' ? '-dynamiclib' : '-shared' ), '-o', $obj->absolute->stringify;
            }

            # link/archive
            return $self->libname
                if !system grep { length $_ && /\w/ } 'gfortran', '-shared', '-o', map { $_->absolute->stringify } $self->libname, @objs
        }
        if `gfortran --version` =~ /GNU Fortran/;
        return method() {
            my @objs;

            # compile
            for my $source ( @{ $self->source } ) {
                my $obj = $self->build_dir->child( $source->basename(qr[\..*?$]) . $Config{_o} );
                push @objs, $obj
                    if !system grep { length $_ && /\w/ } 'ifx', '-c', $source->absolute->stringify, qw[/compile-only /nologo /Fo],
                    ( $self->os eq 'MSWin32' ? '/dll' : '-shared' ), '-o', $obj->absolute->stringify, $source->absolute->stringify;
            }

            # link/archive
            return $self->libname if !system grep { length $_ && /\w/ } 'ifx', '/dll', '-o', map { $_->absolute->stringify } $self->libname, @objs
        }
        if `ifx /QV` =~ /Intel/;    # Intel's latest

        # TODO: ( `ifort --version`    =~ /Intel/ )   # Classic
        return method() { confess 'Failed to locate Fortran compiler' };
    }
}

class Affix::Builder::Go 1.00 : isa(Affix::Builder 1.00) { }

class Affix::Builder::Rust 1.00 : isa(Affix::Builder 1.00) { }

class Affix::Builder::Julia 1.00 : isa(Affix::Builder 1.00) { }

class Affix::Builder::Nim 1.00 : isa(Affix::Builder 1.00) { }
1;
__END__
use Data::Printer;

use Affix::Builder;
my $c   = Affix::Builder::C->new( version => '1.0', source => '..\t\src\236_types_struct.c' );
my $cxx = Affix::Builder::CPP->new(

    #~ version => '1.0',
    source => '..\t\src\99_preview.cxx'
);
my $fortran = Affix::Builder::Fortran->new( source => ['../t/src/86_affix_abi_fortran/hello.f90'] );

#~ warn $b->libname;
my $lib_c       = $c->build;
my $lib_cxx     = $cxx->build;
my $lib_fortran = $fortran->build;

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

__END__
package Affix::Builder {
    use v5.40;
    use Path::Tiny qw[];
    use Config     qw[%Config];

    #~ use Test2::V0 '!subtest';
    #~ use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
    use feature 'class';
    no warnings 'experimental::class';



    class Affix::Builder {

        # use bless for now (until perl 5.40 (not 5.38!) is the min requirement)
        # TODO: Move C/CXX builder stuff from t::helper into ::C
        # TODO: Write a wrapper to build libs in Rust, Fortran, and D
        field $verbose : reader //= 0;
        field $os : reader = $^O;
        field $path : reader : param   //= '.';
        field $output : reader : param //= Path::Tiny->tempfile( { realpath => 1 },
            TEMPLATE => ( $os eq 'MSWin32' ? '' : 'lib' ) . 'affix_lib.' . $Config{so} . '.XXXX' );
        field @steps : reader;
        ADJUST {
            $output = Path::Tiny::path($output) unless builtin::blessed $output;
            $path   = Path::Tiny::path($path)   unless builtin::blessed $path;
        }

        method lib () {
            $_ || $_->run for @steps;
            -s $output ? $output : ();
        }
        method push_step($step) { push @steps, $step }
        method config ($key)    { $Config{$key} }

        method run_command( $cmd, @etc ) {
            system $cmd, @etc, '&';
            if ( $? == 0 ) {
                return 1;
                last;
            }
            elsif ( $? == -1 ) {
                warn 'failed to execute: ' . $!;
            }
            elsif ( $? & 127 ) {
                warn sprintf "child died with signal %d, %s coredump\n", ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
            }
            else {
                warn 'child exited with value ' . ( $? >> 8 );
            }
            0;
        }
    }

    class Affix::Builder::Step {
        field $status : reader //= 0;
        field $output : reader;
        use overload bool => sub { shift->status };
        method run()           {...}
        method _set_status($s) { $status = $s }
    }

    class Affix::Builder::Step::Perl : isa(Affix::Builder::Step) {
        field $execute : param;
        method run() { $execute->(); }
    }

    class Affix::Builder::Step::Shell : isa(Affix::Builder::Step) {
        field $execute : param;
        ADJUST {
            $execute = join ' ', @$execute if ref $execute;
        }

        method run() {
            return $self->output if !!$self;
            CORE::say $execute;
            $self->_set_status( !system $execute );
            $self->status ? $self->output : ();
        }
    }

    class Affix::Builder::C : isa(Affix::Builder) {
        field $Inc = Path::Tiny::cwd->parent->parent->child('src')->absolute;
        #
        field $source : param;
        field $output : reader;
        field $include : reader          //= [];
        field $libperl : param : reader  //= 0;    # Links with perl if true
        field $cxxflags : param : reader //= [];
        field $ldflags : param : reader  //= [];
        field $libs : param : reader     //= [];
        #
        field @cleanup;
        field @objs;

        #~ Affix::Platform::OS();
        ADJUST {
            # use Data::Dump;
            # ddx \%args;
            my @objs;
            for my $file ( map { Path::Tiny::path($_)->realpath } @$source ) {
                $output = $file->sibling( $file->basename(qw[.cxx .cpp c++]) . $self->config('_o') );
                push @objs, $self->{output};
                push @{ $self->{steps} },
                    Affix::Builder::Step::Shell->new(
                    execute => [
                        'c++',
                        ( map { '-I' . Path::Tiny::path($_)->realpath->stringify } @$include ),
                        ( $libperl ? '-I' . Path::Tiny::path( $self->config('installarchlib') )->child('CORE')->realpath->stringify : () ),
                        @$cxxflags,
                        '-o',
                        $output->stringify,
                        $file->stringify
                    ]
                    );
            }
            push @{ $self->{steps} },
                Affix::Builder::Step::Shell->new(
                execute => [
                    'c++',
                    '-shared',
                    ( map { '-L' . Path::Tiny::path($_)->realpath->stringify } @$libs ),
                    ( $libperl ? '-L' . Path::Tiny::path( $self->config('installarchlib') )->child('CORE')->realpath->stringify : () ),
                    @objs,
                    @{ $ldflags // () },
                    '-o',
                    Path::Tiny::path( $output // 'output.' . $self->config('so') )->absolute->stringify
                ]
                );

            # cc -shared -O2 -L/usr/local/lib -fstack-protector-strong
            #-o blib/arch/auto/Affix/Affix.so
            #/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix.o
            # /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/Callback.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/Lib.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/Platform.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/Pointer.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/marshal.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/pin.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/type.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/utils.o
            #  /home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/wchar_t.o
            #  -flto -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/lib/Affix/
            #   -L/home/runner/work/fictional-palm-tree/fictional-palm-tree/blib/arch/auto/Affix/lib
            #   -lstdc++ -ldyncall_s -ldyncallback_s -ldynload_s
            $self;
        }

        method compile_test_lib ( $name, $aggs //= '', $keep //= 0 ) {

            # TODO: generalize this beyond building test libs
            # TODO: allow libperl to be linked so I could even use this to build Affix itself
            my ($opt) = grep { -f $_ } "t/src/$name.cxx", "t/src/$name.c";
            if ($opt) {
                $opt = Path::Tiny::path($opt)->absolute;
            }
            else {
                $opt = tempfile(
                    UNLINK => !$keep,
                    SUFFIX => '_' . Path::Tiny::path( [ caller() ]->[1] )->basename . ( $name =~ m[^\s*//\s*ext:\s*\.c$]ms ? '.c' : '.cxx' )
                )->absolute;
                push @cleanup, $opt unless $keep;
                my ( $package, $filename, $line ) = caller;
                $filename = Path::Tiny::path($filename)->canonpath;
                $line++;
                $filename =~ s[\\][\\\\]g;    # Windows...
                $opt->spew_utf8(qq[#line $line "$filename"\r\n$name]);
            }
            if ( !$opt ) {

                # diag 'Failed to locate test source';
                return ();
            }
            my $c_file = $opt->canonpath;
            my $o_file = tempfile( UNLINK => !$keep, SUFFIX => $self->config('_o') )->absolute;
            my $l_file = tempfile( UNLINK => !$keep, SUFFIX => $opt->basename(qr/\.cx*/) . '.' . $self->config('so') )->absolute;
            push @cleanup, $o_file, $l_file unless $keep;

            # note sprintf 'Building %s into %s', $opt, $l_file;
            my $compiler = $self->config('cc');
            if ( $opt =~ /\.cxx$/ ) {
                if ( Affix::Platform::Compiler() eq 'Clang' ) {
                    $compiler = 'c++';
                }
                elsif ( Affix::Platform::Compiler() eq 'GNU' ) {
                    $compiler = 'g++';
                }
            }
            my @cmds = (
                Affix::Platform::Linux() ? "$compiler -Wall -Wformat=0 --shared -fPIC -I$Inc -DBUILD_LIB -o $l_file $aggs $c_file" :
                    "$compiler -o $l_file $c_file --shared -fPIC -DBUILD_LIB -I$Inc  $aggs",

#~ "$compiler $c_file --shared -fPIC -DBUILD_LIB -I$Inc $aggs -o $l_file ",
#  cc -o /tmp/46XFR9cfv9nzaeq812c2.so /tmp/nzaeq812c2.c --shared -fPIC -DBUILD_LIB -I/home/runner/work/Fiction/Fiction/t/src  -Wl,-E  -fstack-protector-strong -L/usr/local/lib  -L/home/runner/perl5/perlbrew/perls/cache-ubuntu-22.04-5.38.2-Dusethreads/lib/5.38.2/x86_64-linux-thread-multi/CORE -lperl -lpthread -ldl -lm -lcrypt -lutil -lc  -D_REENTRANT -D_GNU_SOURCE -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64  -I/home/runner/perl5/perlbrew/perls/cache-ubuntu-22.04-5.38.2-Dusethreads/lib/5.38.2/x86_64-linux-thread-multi/CORE
#~ cc -Wall -Wformat=0 --shared -fPIC -I/home/runner/work/Fiction/Fiction/t/src -DBUILD_LIB -o /tmp/yDtGm6LBct7NtmfrXFDE.so   -Wl,-E  -fstack-protector-strong -L/usr/local/lib  -L/home/runner/perl5/perlbrew/perls/cache-ubuntu-22.04-5.38.2/lib/5.38.2/x86_64-linux/CORE                          -lperl -lpthread -ldl -lm -lcrypt -lutil -lc                             -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64  -I/home/runner/perl5/perlbrew/perls/cache-ubuntu-22.04-5.38.2/lib/5.38.2/x86_64-linux/CORE  /tmp/7NtmfrXFDE.c
#~ (
#~ $OS eq 'MSWin32' ? "cl /LD /EHsc /Fe$l_file $c_file" :
#~ "clang -stdlib=libc --shared -fPIC -o $l_file $c_file"
#~ )
            );
            my ( @fails, $succeeded );
            my $ok;
            for my $cmd (@cmds) {
                warn $cmd;
                system $cmd;
                if ( $? == 0 ) {
                    $ok++;
                    last;
                }
                elsif ( $? == -1 ) {
                    warn 'failed to execute: ' . $!;
                }
                elsif ( $? & 127 ) {
                    warn sprintf "child died with signal %d, %s coredump\n", ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
                }
                else {
                    warn 'child exited with value ' . ( $? >> 8 );
                }
            }
            if ( !-f $l_file ) {
                warn 'Failed to build test lib';
                return;
            }
            $l_file;
        }

        method DESTROY {
            for my $file ( grep {-f} @cleanup ) {

                # note 'Removing ' . $file;
                unlink $file;
            }
        }
    }

    class Affix::Builder::CXX : isa(Affix::Builder::C) {
    }

    class Affix::Builder::CXX::MSVC : isa(Affix::Builder::CXX) {
    }

    class Affix::Builder::CXX::GNU : isa(Affix::Builder::CXX) {
    }

    class Affix::Builder::Go : isa(Affix::Builder) {

        # go build -buildmode=c-shared
        # https://pkg.go.dev/cmd/go#hdr-Build_modes
    }

    class Affix::Builder::D : isa(Affix::Builder) {
    }

    class Affix::Builder::Fortran : isa(Affix::Builder) {
        field $compiler : reader : param //= ();
        field $gnu = 0;
        field $source : param;

        # https://fortran-lang.org/learn/building_programs/managing_libraries/
        ADJUST {
            # locate_compiler
            if ( !defined $compiler ) {
                for my $exe (qw[gfortran ifort]) {    # gnu, intel
                    if ( $self->run_command( $exe, '--version' ) ) {
                        $compiler = $exe;
                        last;
                    }
                }
                $gnu = $compiler eq 'gfortran';
            }

            #~ $self->compile_test_lib();
            $self->push_step(
                Affix::Builder::Step::Shell->new(
                    execute => [
                        $compiler,

                        #~ '-fno-underscoring', # XXX: should I be lazy and force bind(C, name="symbol")
                        ( ref $source ? @$source : $source ), '-fPIC',
                        ( $gnu ? '-shared' : ( $^O eq 'MSWin32' ? '/libs:dll' : $^O eq 'darwin' ? '-dynamiclib' : '-shared' ) ), '-o', $self->output
                    ]
                )
            ) if $compiler;
        }

        #~ method lib() {    ...    }
        #~ method add_source(@files) {...        }
        #~ method compile_test_lib ( $name //= 'affix_fortran', $aggs //= (), $keep //= 0 ) {
        #~ return !warn 'test requires GNUFortran' unless $compiler;
        #~ my $path = Path::Tiny::path($name);
        #~ my $lib  = ( $^O eq 'MSWin32' ? '' : 'lib' ) . $name . '.' . $self->config('so');
        #~ my $line = sprintf '%s  -fPIC %s -o %s', $compiler,
        #~ ( $gnu ? '-shared' : ( $^O eq 'MSWin32' ? '/libs:dll' : $^O eq 'darwin' ? '-dynamiclib' : '-shared' ) ), $lib;
        #~ system $line;
        #~ }
    }

    class Affix::Builder::Rust : isa(Affix::Builder) {
        field $quiet : param //= 0;
        field $manifest : param;
        ADJUST {
            $self->push_step(
                Affix::Builder::Step::Shell->new(
                    execute =>
                    'cargo build --manifest-path=' . $manifest . ' --release ' . ( $quiet ? '--quiet' : '' )
                )
            );
        }
    }
};
1;
