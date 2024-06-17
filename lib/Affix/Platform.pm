package Affix::Platform 0.5 {

    # ctypes util
    sub padding_needed_for {
        my ( $offset, $alignment ) = @_;

        #~ warn sprintf 'padding_needed_for( %d, %d )', $offset, $alignment;
        return $alignment unless $offset;
        return 0          unless $alignment;
        my $misalignment = $offset % $alignment;
        return $alignment - $misalignment if $misalignment;    # round to the next multiple of $alignment
        return 0;                                              # already a multiple of $alignment
    }
};
1;
