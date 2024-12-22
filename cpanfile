requires 'Carp';
requires 'XSLoader';
requires 'perl', 'v5.40.0';
on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Requirements::Dynamic';
    requires 'Config';
    requires 'ExtUtils::Helpers', '0.028';
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', '0.002';
    requires 'File::Basename';
    requires 'File::Path';
    requires 'File::Spec::Functions';
    requires 'Getopt::Long', '2.36';
    requires 'JSON::PP',     '2';
    requires 'Path::Tiny',   '0.144';
};
on build => sub {
    requires 'DynaLoader';
    requires 'ExtUtils::CBuilder';
};
on test => sub {
    requires 'Capture::Tiny';
    requires 'Data::Printer';
    requires 'TAP::Harness::Env';
    requires 'Test2::Plugin::UTF8';
    requires 'Test2::Tools::Compare';
    requires 'Test2::V0';
};
on develop => sub {
    requires 'Code::TidyAll';
    requires 'Code::TidyAll::Plugin::ClangFormat';
    requires 'Code::TidyAll::Plugin::JSON';
    requires 'Code::TidyAll::Plugin::PodChecker';
    requires 'Code::TidyAll::Plugin::PodSpell';
    requires 'Code::TidyAll::Plugin::PodTidy';
    requires 'Perl::Tidy';
    requires 'Pod::Markdown::Github';
    requires 'Pod::Tidy';
    requires 'Software::License::Artistic_2_0';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions',   '0.07';
    requires 'Test::Pod',                  '1.41';
    requires 'Test::Spellunker',           'v0.2.7';
    requires 'Version::Next';
    recommends 'App::mii', 'v1.0.0';
    recommends 'CPAN::Uploader';
};
