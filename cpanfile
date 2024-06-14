requires perl => v5.38.0;
on configure => sub { };
on build     => sub { };
on test      => sub {
    requires 'Test2::V0';
};
on configure => sub { };
on runtime   => sub { };
