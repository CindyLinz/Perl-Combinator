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
    if( @_ <= 1 ) { # next only
        return $_[0];
    }
    my $code = shift;
    my $next = &ser;
    replace_code($code, $next);
    $code =~ s/{{next_def}}/(\$\$Combinator::holder=sub{local\$Combinator::holder=do{\\my\$foo};$next})/ig;
    #$code =~ s/{{next_sub}}/Combinator::lazy_sub(\$Combinator::holder)/ig;
    $code =~ s/{{next_run}}/\$\$Combinator::holder->()/ig;
    $code =~ s/{{next_sub}}/\$\$Combinator::holder/ig;
    #$code =~ s/{{next}}/Combinator::lazy_once(\$Combinator::holder)/ig;
    return $code;
    #return "$code;\$\$Combinator::holder=sub{local\$Combinator::holder=do{\\my\$foo};$next};";
}

my $begin_pat = '\bser\{\{';
my $end_pat = '\bser\}\}';
my $middle_pat = '\bser--';
my $pat = "($begin_pat((?:(?-2)|(?!$begin_pat).)*)$end_pat)";

sub replace_code {
    my $next = $_[1];
    $_[0] =~ s[$pat]{
        my $code = $2;
        #replace_code($code);
        my @code;
        while( $code =~ m/(?:$middle_pat|^)((?:$pat|(?!$begin_pat|$middle_pat).)*)(?=$middle_pat|$)/gis ) {
            push @code, $1;
        }
        #warn join "XXXXXXXXXXXXXX", @code;
        #my @code = split /\bser--/, $code;
        my $out = ser(@code, $next);
        $out = "{local\$Combinator::holder=do{\\my\$foo};$out};";
        #warn $out;
        $out;
    }iges
}

FILTER_ONLY
    code_no_comments => sub {
        replace_code($_, '');
        #warn "{{{{{$_}}}}}";
    };

1;
