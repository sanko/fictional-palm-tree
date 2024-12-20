requires 'perl', 'v5.32.0';
on configure => sub {
    requires 'Config';
    requires 'Devel::CheckBin';
    requires 'ExtUtils::Helpers', '0.02';
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', '0.002';
    requires 'File::Spec::Functions';
    requires 'Getopt::Long', '2.36';
    requires 'JSON::Tiny';
    requires 'Path::Tiny';
};
on test => sub {
    requires 'Capture::Tiny';
    requires 'Data::Dump';
    requires 'Test2::Plugin::UTF8';
    requires 'Test2::Tools::Compare';
    requires 'Test2::V0';
};
on develop => sub {
    requires 'CPAN::Uploader';
    requires 'Code::TidyAll';
    requires 'Code::TidyAll::Plugin::ClangFormat';
    requires 'Code::TidyAll::Plugin::PodTidy';
    requires 'Perl::Tidy';
    requires 'Pod::Tidy';
    requires 'Software::License::Artistic_2_0';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
};
