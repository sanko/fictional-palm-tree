package t::lib::helper {
    use Test2::V0 -no_srand => 1, '!subtest';
    use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
    use Test2::Plugin::UTF8;
    use Path::Tiny qw[path tempdir tempfile];
    use Exporter 'import';
    our @EXPORT = qw[compile_test_lib compile_cpp_test_lib is_approx leaktest leaks];
    use Config;
    use Affix qw[];
    #
    my $OS  = $^O;
    my $Inc = path(__FILE__)->parent->parent->child('src')->absolute;

    #~ Affix::Platform::OS();
    my @cleanup;
    #
    #~ note $Config{cc};
    #~ note $Config{cccdlflags};
    #~ note $Config{ccdlflags};
    #~ note $Config{ccflags};
    #~ note $Config{ccname};
    #~ note $Config{ccsymbols};
    sub compile_test_lib ($;$$) {
        my ( $name, $aggs, $keep ) = @_;
        $aggs //= '';
        $keep //= 0;
        my ($opt) = grep { -f $_ } "t/src/$name.cxx", "t/src/$name.c", "src/$name.cxx", "src/$name.c";
        if ($opt) {
            $opt = path($opt)->absolute;
        }
        else {
            $opt = tempfile(
                UNLINK => !$keep,
                SUFFIX => '_' . path( [ caller() ]->[1] )->basename . ( $name =~ m[^\s*//\s*ext:\s*\.c$]ms ? '.c' : '.cxx' )
            )->absolute;
            push @cleanup, $opt unless $keep;
            my ( $package, $filename, $line ) = caller;
            $filename = path($filename)->canonpath;
            $line++;
            $filename =~ s[\\][\\\\]g;    # Windows...
            $opt->spew_utf8(qq[#line $line "$filename"\r\n$name]);
        }
        if ( !$opt ) {
            diag 'Failed to locate test source';
            return ();
        }
        my $c_file = $opt->canonpath;
        my $o_file = tempfile( UNLINK => !$keep, SUFFIX => $Config{_o} )->absolute;
        my $l_file = tempfile( UNLINK => !$keep, SUFFIX => $opt->basename(qr/\.cx*/) . '.' . $Config{so} )->absolute;
        push @cleanup, $o_file, $l_file unless $keep;
        note sprintf 'Building %s into %s', $opt, $l_file;
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
            note $cmd;
            system $cmd;
            if ( $? == 0 ) {
                $ok++;
                last;
            }
            elsif ( $? == -1 ) {
                diag 'failed to execute: ' . $!;
            }
            elsif ( $? & 127 ) {
                diag sprintf "child died with signal %d, %s coredump\n", ( $? & 127 ), ( $? & 128 ) ? 'with' : 'without';
            }
            else {
                note 'child exited with value ' . ( $? >> 8 );
            }
        }
        if ( !-f $l_file ) {
            diag 'Failed to build test lib';
            return;
        }
        $l_file;
    }
    {
        my $supp;    # defined later
        my ( $test, $generate_suppressions, $count );
        my $valgrind = 0;
        my $file;

        sub init_valgrind {
            return if $valgrind;
            require Path::Tiny;
            $file     = Path::Tiny::path($0)->absolute;
            $valgrind = 1;
            return plan skip_all 'Capture::Tiny is not installed' unless eval 'require Capture::Tiny';
            return plan skip_all 'Path::Tiny is not installed'    unless eval 'require Path::Tiny';
            require Getopt::Long;
            Getopt::Long::GetOptions( 'test=s' => \$test, 'generate' => \$generate_suppressions, 'count=i' => \$count );
            Test2::API::test2_stack()->top->{count} = $count if defined $count;

            if ( defined $test ) {

                #~ Affix::set_destruct_level(3);
                #~ die 'I should be running a test named ' . $test;
            }
            elsif ( defined $generate_suppressions ) {
                no Test2::Plugin::ExitSummary;
                pass 'exiting...';
                done_testing;
                exit;
            }
            else {
                my ( $stdout, $stderr, $exit_code ) = Capture::Tiny::capture(
                    sub {
                        system('valgrind --version');
                    }
                );
                plan skip_all 'Valgrind is not installed' if $exit_code;
                diag 'Valgrind v', ( $stdout =~ m/valgrind-(.+)$/ ), ' found';
                diag 'Generating suppressions...';
                my @cmd = (
                    qw[valgrind --leak-check=full --show-reachable=yes --error-limit=no
                        --gen-suppressions=all --log-fd=1], $^X, '-e',
                    sprintf <<'', ( join ', ', map {"'$_'"} sort { length $a <=> length $b } map { path($_)->absolute->canonpath } @INC ) );
    use strict;
    use warnings;
    use lib %s;
    use Affix;
    no Test2::Plugin::ExitSummary;
    use Test2::V0;
    pass "generate valgrind suppressions";
    done_testing;


                #~ use Data::Dump;
                #~ ddx \@cmd;
                my ( $out, $err, @res ) = Capture::Tiny::capture(
                    sub {
                        system @cmd;
                    }
                );
                my ( $known, $dups ) = parse_suppression($out);

                #~ diag $out;
                #~ diag $err;
                diag scalar( keys %$known ) . ' suppressions found';
                diag $dups . ' duplicates have been filtered out';
                $known->{'BSD is trash'} = <<'';
{
    <insert_a_suppression_name_here>
    Memcheck:Free
    fun:~vector
}

                $known->{'chaotic access'} = <<'';
{
    <insert_a_suppression_name_here>
    Memcheck:Addr1
    fun:_DumpHex
}


                # https://bugs.kde.org/show_bug.cgi?id=453084
                # https://github.com/Perl/perl5/issues/19949
                # https://github.com/Perl/perl5/issues/20970
                $known->{'https://github.com/Perl/perl5/issues/19949'} = <<'';
{
   <insert_a_suppression_name_here>
   Memcheck:Overlap
   fun:__memcpy_chk
   fun:XS_Cwd_abs_path
   fun:Perl_pp_entersub
   fun:Perl_runops_standard
   fun:S_docatch
   fun:Perl_runops_standard
   fun:Perl_call_sv
}

                $supp = Path::Tiny::tempfile( { realpath => 1 }, 'valgrind_suppression_XXXXXXXXXX' );
                diag 'spewing to ' . $supp;
                diag $supp->spew( join "\n\n", values %$known );
                push @cleanup, $supp;
                Test2::API::test2_stack()->top->{count};

                #~ Test2::API::test2_stack()->top->{count}++;
            }
        }

        sub parse_suppression {
            my $dups  = 0;
            my $known = {};
            require Digest::MD5;
            my @in = split /\R/, shift;
            my $l  = 0;
            while ( $_ = shift @in ) {
                $l++;
                next unless (/^\{/);
                my $block = $_ . "\n";
                while ( $_ = shift @in ) {
                    $l++;
                    $block .= $_ . "\n";
                    last if /^\}/;
                }
                $block // last;
                if ( $block !~ /\}\n/ ) {
                    diag "Unterminated suppression at line $l";
                    last;
                }
                my $key = $block;
                $key =~ s/(\A\{[^\n]*\n)\s*[^\n]*\n/$1/;
                my $sum = Digest::MD5::md5_hex($key);
                $dups++ if exists $known->{$sum};
                $known->{$sum} = $block;
            }
            return ( $known, $dups );
        }

        sub dec_ent {
            return $1 if $_[0] =~ m/^<!\[CDATA\[\{(.*)}]]>$/smg;
            $_[0]              =~ s[&lt;][<]g;
            $_[0]              =~ s[&gt;][>]g;
            $_[0]              =~ s[&amp;][&]g;
            shift;
        }

        sub stacktrace($) {
            use Test2::Util::Table qw[table];
            my $blah = shift;
            $blah ?
                join "\n", table(
                max_width => 120,
                collapse  => 1,                                # Do not show empty columns
                header    => [ 'function', 'path', 'line' ],
                rows      => [
                    map { [ $_->{fn}, ( defined $_->{dir} && defined $_->{file} ) ? join '/', $_->{dir}, $_->{file} : '', $_->{line} // '' ] } @$blah
                ],
                ) :
                '';
        }

        sub parse_xml {
            my ($xml) = @_;
            my $hash  = {};
            my $re    = qr{<([^>]+)>\s*(.*?)\s*</\1>}sm;
            while ( $xml =~ m/$re/g ) {
                my ( $tag, $content ) = ( $1, $2 );
                $content = parse_xml($content) if $content =~ /$re/;
                $content = dec_ent($content) unless ref $content;
                if ( $tag eq 'error' ) {

                    # use Data::Dump;
                    # ddx $content;
                    diag $content->{what} // $content->{xwhat}{text};
                    for my $i ( 0 .. scalar @{ $content->{stack} } ) {
                        note $content->{auxwhat}[$i] if $content->{auxwhat}[$i];
                        note stacktrace $content->{stack}[$i]{frame};
                    }
                }
                $hash->{$tag}
                    = defined $content ? (
                    defined $hash->{$tag} ?
                        ref $hash->{$tag} eq 'ARRAY' ?
                            [ @{ $hash->{$tag} }, $content ] :
                            [ $hash->{$tag}, $content ] :
                        $tag =~ m/^(error|stack)$/ ? [$content] :
                        dec_ent($content) ) :
                    undef;
            }
            $hash;
        }

        # Function to run anonymous sub in a new process with valgrind
        sub leaks($&) {
            init_valgrind();
            my ( $name, $code_ref ) = @_;
            #
            require B::Deparse;
            CORE::state $deparse //= B::Deparse->new(qw[-l]);
            my ( $package, $file, $line ) = caller;
            my $source = sprintf
                <<'', ( join ', ', map {"'$_'"} sort { length $a <=> length $b } grep {defined} map { my $dir = path($_); $dir->exists ? $dir->absolute->realpath : () } @INC, 't/lib' ), Test2::API::test2_stack()->top->{count}, $deparse->coderef2text($code_ref);
use lib %s;
use Test2::V0 -no_srand => 1, '!subtest';
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
no Test2::Plugin::ExitSummary; # I wish
use t::lib::helper;
# Test2::API::test2_stack()->top->{count} = %d;
$|++;
my $exit = sub {use Affix; Affix::set_destruct_level(3); %s;}->();
# Test2::API::test2_stack()->top->{count}++;
done_testing;
exit !$exit;

            my $report = Path::Tiny->tempfile( { realpath => 1 }, 'valgrind_report_XXXXXXXXXX' );
            push @cleanup, $report;
            my @cmd = (
                'valgrind',               '-q', '--suppressions=' . $supp->canonpath,
                '--leak-check=full',      '--show-leak-kinds=all', '--show-reachable=yes', '--demangle=yes', '--error-limit=no', '--xml=yes',
                '--gen-suppressions=all', '--xml-file=' . $report->stringify,
                $^X,                      '-e', $source
            );
            my ( $out, $err, $exit ) = Capture::Tiny::capture(
                sub {
                    system @cmd;
                }
            );

            # $out =~ s[# Seeded srand with seed .+$][]m;
            # $err =~ s[# Tests were run .+$][];
            if ( $out =~ m[\S] ) {
                $out =~ s[^((?:[ \t]*))(?=\S)][$1  ]gm;
                print $out;
            }
            if ( $err =~ m[\S] ) {
                $err =~ s[^((?:[ \t]*))(?=\S)][$1  ]gm;
                print STDERR $err;
            }
            my $parsed = parse_xml( $report->slurp_utf8 );

            # use Data::Dump;
            # ddx $parsed;
            # diag 'exit: '. $exit;
            # Test2::API::test2_stack()->top->{count}++;
            ok !$exit && !$parsed->{valgrindoutput}{errorcounts}, $name;
        }
    }

    END {
        for my $file ( grep {-f} @cleanup ) {
            note 'Removing ' . $file;
            unlink $file;
        }
    }
};
1;
