package Combinator;

use strict;
use warnings;

use Filter::Simple;
use AE;

my %opt;
my $begin_pat;
my $end_pat;
my $middle_pat;
my $pat;
my $line_shift;

sub import {
    my $self = shift;
    %opt = (
        verbose => 0, # 設為 1 會印出 Filter 後的程式碼
        begin => qr/\{\{ser\b/,
        middle => qr/--ser\b/,
        end => qr/\}\}ser\b/,
        def => qr/\{\{next_def\}\}/,
        run => qr/\{\{next_run\}\}/,
        sub => qr/\{\{next_sub\}\}/,
        @_
    );
    $begin_pat = $opt{begin};
    $end_pat = $opt{end};
    $middle_pat = $opt{middle};
    $pat = "($begin_pat((?:(?-2)|(?!$begin_pat).)*)$end_pat)";
    $line_shift = (caller)[2];
}

sub ser {
    if( @_ <= 1 ) { # next only
        return $_[0];
    }
    my $code = shift;
    my $next = &ser;
    replace_code($code, $next);
    $code =~ s/$opt{def}/(\$Combinator::holder=sub{local\$Combinator::holder;$next})/g;
    $code =~ s/$opt{run}/\$Combinator::holder->()/g;
    $code =~ s/$opt{sub}/\$Combinator::holder/g;
    return $code;
}

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
        my $n = $line_shift;
        $verbose_code =~ s/^/sprintf"%6d: ", ++$n/gem;
        print "Code after filtering:\n$verbose_code\nEnd Of Code\n";
    }
};

1;
