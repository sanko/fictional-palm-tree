# NAME

Affix - A Foreign Function Interface eXtension

# SYNOPSIS

```perl
use Affix;
```

# DESCRIPTION

Affix is brand new, baby!

# Stack Size

You may control the max size of the internal stack that will be allocated and used to bind the arguments to by setting
the `$VMSize` variable before using Affix.

```
BEGIN{ $Affix::VMSize = 2 ** 16; }
```

This value is `4096` by default and probably should not be changed.

# See Also

# LICENSE

This software is Copyright (c) 2024 by Sanko Robinson <sanko@cpan.org>.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

See [http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0).

# AUTHOR

Sanko Robinson <sanko@cpan.org>
