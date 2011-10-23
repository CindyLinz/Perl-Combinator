package Combinator;

use strict;
use warnings;

use Filter::Simple;
use AE;

my %opt;

sub import {
    my $self = shift;
    %opt = @_;
}

sub ser {
    if( @_ <= 1 ) { # next only
        return $_[0];
    }
    my $code = shift;
    my $next = &ser;
    replace_code($code, $next);
    $code =~ s/{{next_def}}/(\$Combinator::holder=sub{local\$Combinator::holder;$next})/ig;
    $code =~ s/{{next_run}}/\$Combinator::holder->()/ig;
    $code =~ s/{{next_sub}}/\$Combinator::holder/ig;
    return $code;
}

my $begin_pat = '\{\{ser\b';
my $end_pat = '\}\}ser\b';
my $middle_pat = '--ser\b';
my $pat = "($begin_pat((?:(?-2)|(?!$begin_pat).)*)$end_pat)";

sub replace_code {
    my $next = $_[1];
    $_[0] =~ s[$pat]{
        my $code = $2;
        my @code;
        while( $code =~ m/(?:$middle_pat|^)((?:$pat|(?!$begin_pat|$middle_pat).)*)(?=$middle_pat|$)/gis ) {
            push @code, $1;
        }
        my $out = ser(@code, $next);
        "{local\$Combinator::holder;$out}";
    }iges
}

FILTER {
    replace_code($_, '');
    if( $opt{verbose} ) {
        my $verbose_code = $_;
        my $n = 0;
        $verbose_code =~ s/^/sprintf"%6d: ", ++$n/gem;
        print "Code after filtering:\n$verbose_code\nEnd Of Code\n";
    }
};

1;
