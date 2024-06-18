requires perl => v5.32.0;
on build => sub { };
on test  => sub {
    requires 'Test2::V0';
    requires 'Capture::Tiny';    # For valgrind tests
};
on configure => sub {
    requires 'JSON::Tiny';
    requires 'Path::Tiny';
    requires 'ExtUtils::Helpers', 0.020;
    requires 'ExtUtils::Install';
    requires 'ExtUtils::InstallPaths', 0.002;
    requires 'File::Spec::Functions';
    requires 'Getopt::Long', 2.36;
    requires 'JSON::Tiny';
    requires 'Path::Tiny';
    requires 'Config';
    requires 'Devel::CheckBin'; # For locating compiler on Windows
};
on runtime => sub { };
