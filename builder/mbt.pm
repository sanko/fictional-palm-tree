package builder::mbt v0.0.1 {    # inspired by Module::Build::Tiny 0.047
    use v5.26;
    use CPAN::Meta;
    use ExtUtils::Config 0.003;
    use ExtUtils::Helpers 0.020 qw/make_executable split_like_shell detildefy/;
    use ExtUtils::Install qw/pm_to_blib install/;
    use ExtUtils::InstallPaths 0.002;
    use File::Spec::Functions qw/catfile catdir rel2abs abs2rel/;
    use Getopt::Long 2.36     qw/GetOptionsFromArray/;
    use JSON::Tiny            qw[encode_json decode_json];          # Not in CORE
    use Path::Tiny            qw[path];                             # Not in CORE
    use Config;
    my $cwd = path('.')->realpath;
    my $libver;
    my $DEBUG = 0;
    my $CFLAGS
        = $DEBUG                     ? '-DDEBUG=' . $DEBUG :
        $Config{osname} eq 'MSWin32' ? '' :
        ' -DNDEBUG -DBOOST_DISABLE_ASSERTS -O2 -ffast-math -fno-align-functions -fno-align-loops -fno-omit-frame-pointer ';
    my $LDFLAGS = ' ';                                              # https://wiki.freebsd.org/LinkTimeOptimization

    #
    sub get_meta {
        state $metafile //= path('META.json');
        exit say "No META information provided\n" unless $metafile->is_file;
        return CPAN::Meta->load_file( $metafile->realpath );
    }

    sub find {
        my ( $pattern, $dir ) = @_;

        #~ $dir = path($dir) unless $dir->isa('Path::Tiny');
        sort values %{
            $dir->visit(
                sub {
                    my ( $path, $state ) = @_;
                    $state->{$path} = $path if $path->is_file && $path =~ $pattern;
                },
                { recurse => 1 }
            )
        };
    }
    my %actions;
    %actions = (
        build => sub {
            my %opt     = @_;
            my %modules = map { $_->relative => $cwd->child( 'blib', $_->relative )->relative } find( qr/\.pm$/,  $cwd->child('lib') );
            my %docs    = map { $_->relative => $cwd->child( 'blib', $_->relative )->relative } find( qr/\.pod$/, $cwd->child('lib') );
            my %scripts = map { $_->relative => $cwd->child( 'blib', $_->relative )->relative } find( qr/(?:)/,   $cwd->child('script') );
            my %sdocs   = map { $_           => delete $scripts{$_} } grep {/.pod$/} keys %scripts;
            build_dyncall(%opt);
            build_affix( [ find( qr/\.c(?:xx)?$/, $cwd->child('lib') ) ], %opt );
            my %shared = map { $_->relative => $cwd->child( qw[blib lib auto share dist], $opt{meta}->name )->relative }
                find( qr/(?:)/, $cwd->child('share') );
            pm_to_blib( { %modules, %docs, %scripts, %shared }, $cwd->child(qw[blib lib auto]) );
            make_executable($_) for values %scripts;
            $cwd->child(qw[blib arch])->mkdir( { verbose => $opt{verbose} } );
            return 0;
        },
        test => sub {
            my %opt = @_;
            $actions{build}->(%opt) if not -d 'blib';
            require TAP::Harness::Env;
            TAP::Harness::Env->create(
                {   verbosity => $opt{verbose},
                    jobs      => $opt{jobs} // 1,
                    color     => !!-t STDOUT,
                    lib       => [ map { $cwd->child( 'blib', $_ )->canonpath } qw[arch lib] ]
                }
            )->runtests( map { $_->relative->stringify } find( qr/\.t$/, $cwd->child('t') ) )->has_errors;
        },
        install => sub {
            my %opt = @_;
            $actions{build}->(%opt) if not -d 'blib';
            install( $opt{install_paths}->install_map, @opt{qw[verbose dry_run uninst]} );
            return 0;
        },
        clean => sub {
            my %opt = @_;
            path($_)->remove_tree( { verbose => $opt{verbose}, safe => 0 } ) for qw[blib temp Build _build_params MYMETA.json];
            return 0;
        },
    );

    sub Build {
        my $action = @ARGV && $ARGV[0] =~ /\A\w+\z/ ? shift @ARGV : 'build';
        $actions{$action} // exit say "No such action: $action";
        my $build_params = path('_build_params');
        my ( $env, $bargv ) = $build_params->is_file ? @{ decode_json( $build_params->slurp ) } : ();
        GetOptionsFromArray(
            $_,
            \my %opt,
            qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s config=s% uninst:1 verbose:1 dry_run:1 pureperl-only:1 create_packlist=i jobs=i/
        ) for grep {defined} $env, $bargv, \@ARGV;
        $_ = detildefy($_) for grep {defined} @opt{qw[install_base destdir prefix]}, values %{ $opt{install_path} };
        @opt{qw[config meta]} = ( ExtUtils::Config->new( $opt{config} ), get_meta() );
        exit $actions{$action}->( %opt, install_paths => ExtUtils::InstallPaths->new( %opt, dist_name => $opt{meta}->name ) );
    }

    sub Build_PL {
        my $meta = get_meta();
        printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
        $cwd->child('Build')->spew( sprintf "#!%s\nuse lib '%s', '.';\nuse %s;\n%s::Build();\n", $^X, $cwd->canonpath, __PACKAGE__, __PACKAGE__ );
        make_executable('Build');
        my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell( $ENV{PERL_MB_OPT} ) : ();
        $cwd->child('_build_params')->spew( encode_json( [ \@env, \@ARGV ] ) );
        $meta->save('MYMETA.json');
    }

    sub build_dyncall {
        my (%opt) = @_;
        my $pre = Path::Tiny->cwd->child( qw[blib arch auto], $opt{meta}->name )->absolute;
        return                                             if -d $pre;
        die "Can't build xs files under --pureperl-only\n" if $opt{'pureperl-only'};
        my ($kid) = Path::Tiny->cwd->child('dyncall');
        my $cwd = Path::Tiny->cwd->absolute;
        chdir $kid->absolute->stringify;
        my $make = $opt{config}->get('make');
        my $configure
            = 'sh ./configure --prefix=' .
            $pre->absolute .
            ' CFLAGS="-fPIC ' .
            ( $opt{config}->get('osname') =~ /bsd/ ? '' : $CFLAGS ) .
            '" LDFLAGS="' .
            ( $opt{config}->get('osname') =~ /bsd/ ? '' : $LDFLAGS ) . '"';

        if ( $opt{config}->get('osname') eq 'MSWin32' ) {
            require Devel::CheckBin;
            for my $exe ( $make, qw[gmake nmake mingw32-make] ) {
                next unless Devel::CheckBin::check_bin($exe);
                $make      = $exe;
                $configure = '.\configure.bat /target-x64 /tool-' . $opt{config}->get('cc') . ' /make-';
                if ( $exe eq 'nmake' ) {
                    $configure .= 'nmake';
                    $make      .= ' -f Nmakefile';
                }
                else {
                    $configure .= 'make';
                    $make = 'gmake AS="gcc    -c " CC=gcc VPATH=. PREFIX="' . $pre->absolute . '"';
                }
                last;
            }
            CORE::say($_) && system($_) for $configure, $make;

            # TODO: use Path::Tiny to visit all headers instead
            my %libs = (
                dyncall => [
                    qw[dyncall_version.h dyncall_macros.h dyncall_config.h
                        dyncall_types.h dyncall.h dyncall_signature.h
                        dyncall_value.h dyncall_callf.h dyncall_alloc.h
                    ]
                ],
                dyncallback => [
                    qw[dyncall_thunk.h dyncall_thunk_x86.h
                        dyncall_thunk_ppc32.h dyncall_thunk_x64.h
                        dyncall_thunk_arm32.h dyncall_thunk_arm64.h
                        dyncall_thunk_mips.h dyncall_thunk_mips64.h
                        dyncall_thunk_ppc64.h dyncall_thunk_sparc32.h
                        dyncall_thunk_sparc64.h dyncall_args.h
                        dyncall_callback.h
                    ]
                ],
                dynload => [qw[dynload.h]],
            );
            $pre->child('include')->mkdir;
            $pre->child('lib')->mkdir;
            for my $lib ( keys %libs ) {
                $kid->child( $lib, 'lib' . $lib . '_s' . $opt{config}->get('_a') )->copy( $pre->child('lib')->absolute );
                for ( @{ $libs{$lib} } ) {
                    $kid->child( $lib, $_ )->copy( $pre->child( 'include', $_ )->absolute );
                }
            }
            $make = $opt{config}->get('make');
        }
        else {
            $make = $opt{config}->get('make');
            system($_) for $configure, $make, $make . ' install';
        }
        chdir $cwd->stringify;
    }

    sub build_affix {
        my ( $sources, %opt ) = @_;
        die "Can't build xs files under --pureperl-only\n" if $opt{'pureperl-only'};
        warn $@                                            if $@;
        my @objs;
        require ExtUtils::CBuilder;
        my $builder = ExtUtils::CBuilder->new(
            config => {

                #~ (
                #~ $opt{config}->get('osname') !~ /bsd/ &&
                #~ $opt{config}->get('ld') eq 'cc' ? ( ld => 'g++' ) : ()
                #~ ),
                %{ $opt{config}->values_set }
            }
        );
        my $pre = Path::Tiny->cwd->child(qw[blib arch auto])->absolute;
        my $source;
        require DynaLoader;
        my $mod2fname = defined &DynaLoader::mod2fname ? \&DynaLoader::mod2fname : sub { return $_[0][-1] };
        my @parts     = ('Affix');
        my $archdir   = catdir( qw/blib arch auto/, @parts );
        mkpath( $archdir, $opt{verbose}, oct '755' ) unless -d $archdir;
        my $lib_file = catfile( $archdir, $mod2fname->( \@parts ) . '.' . $opt{config}->get('dlext') );
        my @dirs;

        for my $source (@$sources) {
            my $file_base = $source->basename(qr[.cx*$]);
            my $tempdir   = path('lib');
            $tempdir->mkpath( $opt{verbose}, oct '755' );
            my $version = $opt{meta}->version;
            my $obj     = $builder->object_file($source);
            push @dirs, $source->dirname();
            push @objs,    # misses headers but that's okay
                ( ( !-f $obj ) || ( $source->stat->mtime > path($obj)->stat->mtime ) || ( path(__FILE__)->stat->mtime > path($obj)->stat->mtime ) ) ?
                $builder->compile(
                'C++'        => ( $source =~ /\.cxx$/ ? 1 : 0 ),
                source       => $source->stringify,
                defines      => { VERSION => qq/"$version"/, XS_VERSION => qq/"$version"/ },
                include_dirs => [
                    $cwd->stringify,  path('./dyncall')->realpath->stringify,
                    $source->dirname, $pre->child( $opt{meta}->name, 'include' )->stringify
                ],
                extra_compiler_flags => (
                    '-fPIC -std=c++14 ' .
                        ( $opt{config}->get('osname') =~ /bsd/ ? ''                                   : $CFLAGS ) .
                        ( $DEBUG                               ? ' -ggdb3 -g -Wall -Wextra -pedantic' : '' )
                )
                ) :
                $obj;

            #my $op_lib_file = catfile(
            #    $paths->install_destination('arch'),
            #qw[auto Object],
            #'Pad' . $opt{config}->get('dlext')
            #);
        }

        #~ warn join ', ', @dirs;
        #~ warn join ', ', @parts;
        #~ warn $lib_file;
        return (
            ( ( !-f $lib_file ) || grep { path($_)->stat->mtime > path($lib_file)->stat->mtime } @objs ) ?
                $builder->link(
                extra_linker_flags => (
                    ( $opt{config}->get('osname') =~ /bsd/ ? '' : $LDFLAGS ) .
                        ( join ' ', map { ' -L' . $_ } @dirs ) . ' -L' .
                        $pre->child( $opt{meta}->name, 'lib' )->stringify .
                        ' -lstdc++ -ldyncall_s -ldyncallback_s -ldynload_s'
                ),
                objects     => [@objs],
                lib_file    => $lib_file,
                module_name => join '::',
                @parts
                ) :
                $lib_file
        );
    }
}
1;
