package Combinator;

use strict;
use warnings;

use Filter::Simple;

sub ser {
    if( !@_ ) {
        return '{}';
    }
    my $code = shift;
    my $next = &ser;
    $code =~ s/{{next}}/sub$next/ig;
    return "{$code}";
}

FILTER_ONLY
    code_no_comments => sub {
        s(\bser{{(.*?)\bser}}){
            my @code = split /\bser--/, $1;
            my $out = ser(@code);
            #warn $out;
            $out;
        }iges
    };

1;
