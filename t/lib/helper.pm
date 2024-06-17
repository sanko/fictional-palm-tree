package t::lib::helper {
    use Test2::V0 '!subtest';
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
        my ($opt) = grep { -f $_ } "t/src/$name.cxx", "t/src/$name.c";
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
                diag 'Valgrind v', ( $stdout =~ m[valgrind-(.+)$] ), ' found';
                diag 'Generating suppressions...';
                my @cmd = (
                    qw[valgrind --leak-check=full --show-reachable=yes --error-limit=no
                        --gen-suppressions=all --log-fd=1], $^X, '-e',
                    sprintf
                        'use strict;use warnings;use lib %s;use Affix;no Test2::Plugin::ExitSummary;use Test2::V0;pass "generate valgrind suppressions";done_testing;',
                    ( join ', ', map {"'$_'"} sort { length $a <=> length $b } map { path($_)->absolute->canonpath } @INC )
                );

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
                $supp = Path::Tiny::tempfile( { realpath => 1 }, 'valgrind_suppression_XXXXXXXXXX' );
                diag 'spewing to ' . $supp;
                diag $supp->spew( join "\n\n", values %$known );
                push @cleanup, $supp;
                Test2::API::test2_stack()->top->{count};

                #~ Test2::API::test2_stack()->top->{count}++;
            }
        }

        sub valgrind($&) {
            init_valgrind();
            my ( $name, $code ) = @_;
            if ( !defined $test ) {
                my @cmd = (
                    'valgrind',                          '-q',
                    '--suppressions=' . $supp->realpath, '--leak-check=full',
                    '--show-leak-kinds=all',             '--show-reachable=yes',
                    '--demangle=yes',                    '--error-limit=no',
                    '--xml=yes',                         '--xml-fd=2',
                    $^X,                                 $file,
                    '--test=' . $name,                   '--count=' . Test2::API::test2_stack()->top->{count}
                );

                #~ diag join ' ', @cmd;
                my ( $out, $err, $exit ) = Capture::Tiny::capture( sub { system @cmd } );
                print $out;
                my $xml = parse_xml($err);
                Test2::API::test2_stack()->top->{count}++;

                #~ use Data::Dump;
                #~ ddx
                #~ $xml;
                #~ ddx $xml->{valgrindoutput}{error};
                is $xml->{valgrindoutput}{error}, U(), 'no leaks in subtest "' . $name . '"';
                if ( $xml->{valgrindoutput}{error} ) {
                    require Test2::Util::Table;

                    #~ use Data::Dump;
                    #~ ddx $xml;
                    #~ ddx $xml->{valgrindoutput}{error};
                    my @table = Test2::Util::Table::table(
                        max_width => 120,
                        collapse  => 1,                                # Do not show empty columns
                        header    => [ 'kind', 'size', 'location' ],
                        rows      => [
                            map {
                                #~ use Data::Dump;
                                #~ ddx $_;
                                [   $_->{kind},     $_->{xwhat}{leakedbytes},
                                    join " =>\n  ", map { $_->{fn} // $_->{obj} } reverse @{ $_->{stack}{frame} }
                                ]
                            } @{ $xml->{valgrindoutput}{error} }
                        ],
                    );
                    diag $_ for @table;
                }
                return $xml->{valgrindoutput}{error};
                return !$exit;
            }
            return unless $name eq $test;
            no Test2::Plugin::ExitSummary;
            Affix::set_destruct_level(3);
            my $exit = subtest $test => $code;
            Test2::API::test2_stack()->top->{count}++;

            #~ done_testing;
            exit !$exit;
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

        sub parse_xml {
            my ($xml) = @_;
            my $hash  = {};
            my $re    = qr{<([^>]+)>\s*(.*?)\s*</\1>}sm;
            while ( $xml =~ m/$re/g ) {
                my ( $tag, $content ) = ( $1, $2 );
                $content = parse_xml($content) if $content =~ /$re/;
                $hash->{$tag}
                    = defined $content ? (
                    defined $hash->{$tag} ?
                        ref $hash->{$tag} eq 'HASH' ? [ $hash->{$tag}, $content ] :
                            ref $hash->{$tag} eq 'ARRAY' ? [ @{ $hash->{$tag} }, $content ] :
                            [$content] :
                        $tag eq 'error' ? [$content] :
                        $content ) :
                    undef;
            }
            $hash;
        }

        # Function to run anonymous sub in a new process with valgrind
        sub leaks(&) {
            init_valgrind();
            my ($code_ref) = @_;
            #
            # Get source code of the anonymous sub (using B::Deparse)
            #~ my $source = deparse($code_ref);
            require B::Deparse;
            my $deparse = B::Deparse->new( "-p", "-sC" );
            my ( $package, $file, $line ) = caller;
            my $source = sprintf
                <<'', ( join ', ', map {"'$_'"} sort { length $a <=> length $b } map { path($_)->absolute->canonpath } @INC ), Test2::API::test2_stack()->top->{count}, $line + 2, $file, $deparse->coderef2text($code_ref);
use lib %s;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Plugin::UTF8;
no Test2::Plugin::ExitSummary;
use Affix;
Affix::set_destruct_level(3);
no Test2::Plugin::ExitSummary;
Test2::API::test2_stack()->top->{count} = %d;
$|++;
#line %d %s
my $exit = subtest 'leaks' => sub %s;
Test2::API::test2_stack()->top->{count}++;
exit !$exit;

            my $report = Path::Tiny->tempfile( { realpath => 1 }, 'valgrind_report_XXXXXXXXXX' );
            push @cleanup, $report;
            my @cmd = (
                'valgrind', '-q', '--suppressions=' . $supp->canonpath,
                '--leak-check=full', '--show-leak-kinds=all', '--show-reachable=yes', '--demangle=yes', '--error-limit=no', '--xml=yes',
                '--xml-file=' . $report->stringify,
                $^X, '-e', $source
            );

            #~ my ( $out, $err, $exit ) = Capture::Tiny::capture( sub {
            system @cmd;

            #~ } );
            #~ print $out;
            #~ diag $err;
            #~ diag $exit;
            my $xml = parse_xml( $report->slurp_utf8 );
            Test2::API::test2_stack()->top->{count}++;
            $xml->{valgrindoutput};
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
