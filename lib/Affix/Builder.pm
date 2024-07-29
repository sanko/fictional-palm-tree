package Affix::Builder {
    use v5.32.0;
    use Path::Tiny;

    # use bless for now (until perl 5.40 (not 5.38!) is the min requirement)
    # TODO: Move C/CXX builder stuff from t::helper into ::C
    # TODO: Write a wrapper to build libs in Rust, Fortran, and D
    sub new ($%) {
        my ( $class, %args ) = @_;
        bless {
            lang => $args{language} // 'C',
            path => path( $args{path} // '.' )
        }, $class;
    }

    package Affix::Builder::C {
        use Path::Tiny qw[path tempdir tempfile];
        use Config;
        #
        my $OS  = $^O;
        my $Inc = path(__FILE__)->parent->parent->child('src')->absolute;

        #~ Affix::Platform::OS();
        my @cleanup;

        sub compile_test_lib ($;$$) {

# TODO: generalize this beyond building test libs
# TODO: allow libperl to be linked so I could even use this to build Affix itself
            my ( $name, $aggs, $keep ) = @_;
            $aggs //= '';
            $keep //= 0;
            my ($opt) = grep { -f $_ } "t/src/$name.cxx", "t/src/$name.c";
            if ($opt) {
                $opt = path($opt)->absolute;
            }
            else {
                $opt = tempfile(
                    UNLINK => !$keep,
                    SUFFIX => '_'
                      . path( [ caller() ]->[1] )->basename
                      . ( $name =~ m[^\s*//\s*ext:\s*\.c$]ms ? '.c' : '.cxx' )
                )->absolute;
                push @cleanup, $opt unless $keep;
                my ( $package, $filename, $line ) = caller;
                $filename = path($filename)->canonpath;
                $line++;
                $filename =~ s[\\][\\\\]g;    # Windows...
                $opt->spew_utf8(qq[#line $line "$filename"\r\n$name]);
            }
            if ( !$opt ) {

                # diag 'Failed to locate test source';
                return ();
            }
            my $c_file = $opt->canonpath;
            my $o_file =
              tempfile( UNLINK => !$keep, SUFFIX => $Config{_o} )->absolute;
            my $l_file = tempfile(
                UNLINK => !$keep,
                SUFFIX => $opt->basename(qr/\.cx*/) . '.' . $Config{so}
            )->absolute;
            push @cleanup, $o_file, $l_file unless $keep;

            # note sprintf 'Building %s into %s', $opt, $l_file;
            my $compiler = $Config{cc};
            if ( $opt =~ /\.cxx$/ ) {
                if ( Affix::Platform::Compiler() eq 'Clang' ) {
                    $compiler = 'c++';
                }
                elsif ( Affix::Platform::Compiler() eq 'GNU' ) {
                    $compiler = 'g++';
                }
            }
            my @cmds = (
                Affix::Platform::Linux()
                ? "$compiler -Wall -Wformat=0 --shared -fPIC -I$Inc -DBUILD_LIB -o $l_file $aggs $c_file"
                : "$compiler -o $l_file $c_file --shared -fPIC -DBUILD_LIB -I$Inc  $aggs",

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
                note $cmd;
                system $cmd;
                if ( $? == 0 ) {
                    $ok++;
                    last;
                }
                elsif ( $? == -1 ) {
                    warn 'failed to execute: ' . $!;
                }
                elsif ( $? & 127 ) {
                    warn sprintf "child died with signal %d, %s coredump\n",
                      ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
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

        END {
            for my $file ( grep { -f } @cleanup ) {

                # note 'Removing ' . $file;
                unlink $file;
            }
        }
    }

    package Affix::Builder::CXX;

    package Affix::Builder::D;

    package Affix::Bulder::Fortran {
        use Devel::CheckBin;
        use Config;
        use Path::Tiny;

        my ( $compiler, $gnu );

        # https://fortran-lang.org/learn/building_programs/managing_libraries/

        # gfortran, ifort
        sub locate_compiler() {
            return $compiler if defined $compiler;
            $compiler = can_run('gfortran');
            $gnu      = !!$compiler;
            $compiler = can_run('ifort') unless $compiler;    # intel
        }

        sub compile_test_lib ($;$$) {
            my ( $name, $aggs, $keep ) = @_;

            return !warn 'test requires GNUFortran' unless $compiler;
            my $path = path($name);

            my $lib =
                ( $^O eq 'MSWin32' ? '' : 'lib' )
              . 'affix_fortran.'
              . $Config{so};
            my $line =
              sprintf '%s t/src/86_affix_abi_fortran/hello.f90 -fPIC %s -o %s',
              $compiler,
              (
                $gnu ? '-shared'
                : (
                      $^O eq 'MSWin32' ? '/libs:dll'
                    : $^O eq 'darwin'  ? '-dynamiclib'
                    :                    '-shared'
                )
              ), $lib;
            warn $line;
        }
    }

    package Affix::Builder::Rust {
        use Devel::CheckBin;
        use Config;
        my $lib =
          ( $^O eq 'MSWin32' ? '' : 'lib' ) . 'affix_rust.' . $Config{so};
        system
'cargo build --manifest-path=t/src/85_affix_mangle_rust/Cargo.toml --release --quiet';
    }
};
