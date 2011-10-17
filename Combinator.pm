package Combinator;

use strict;
use warnings;

use Filter::Simple;
use AE;

sub once {
    my $sub = shift;
    my $args_ref = \@_;
    my $t;
    $t = AE::idle sub {
        undef $t;
        $sub->(@$args_ref);
    };
    return;
}

sub lazy_sub {
    my $sub_ref = shift;
    my $args_ref = \@_;
    return sub { $$sub_ref->(@$args_ref) };
}

sub lazy_once {
    my $sub_ref = shift;
    my $args_ref = \@_;
    my $t;
    $t = AE::idle sub {
        undef $t;
        $$sub_ref->(@$args_ref);
    };
    return;
}

sub ser {
    if( !@_ ) {
        return '';
    }
    my $code = shift;
    my $next = &ser;
    $code =~ s/{{next_def}}/(\$\$Combinator::holder=sub{local\$Combinator::holder=do{\\my\$foo};$next})/ig;
    #$code =~ s/{{next_sub}}/Combinator::lazy_sub(\$Combinator::holder)/ig;
    $code =~ s/{{next_run}}/\$\$Combinator::holder->()/ig;
    $code =~ s/{{next_sub}}/\$\$Combinator::holder/ig;
    #$code =~ s/{{next}}/Combinator::lazy_once(\$Combinator::holder)/ig;
    return $code;
    #return "$code;\$\$Combinator::holder=sub{local\$Combinator::holder=do{\\my\$foo};$next};";
}

FILTER_ONLY
    code_no_comments => sub {
        s(\bser{{(.*?)\bser}}){
            my @code = split /\bser--/, $1;
            my $out = ser(@code);
            $out = "Combinator::once sub{local\$Combinator::holder=do{\\my\$foo};$out};";
            #warn $out;
            $out;
        }iges
    };

1;
