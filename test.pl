#!/usr/bin/perl

use strict;
use warnings;
use Combinator verbose => 1;

use AE;

my $_dserone = AE::cv;
{{ser
    print "Begin\n";
    my $a = 'a';
    my $t; $t = AE::timer .5, 0, {{next_def}};
    # or
    # my $t; {{next_def }}; $t = AE::timer .5, 0, {{next_sub }};
--ser
    undef $t;
    print "First $a\n";
    my $b = 'b';
    {{next_def}}->();
    # or
    # {{next_def }}; {{next_run }};
    print "After Second $a\n";
--ser
    print "Second (no delay) $a $b\n";
    my $c = 'c';
    {{ser
        print "Nest begin $a $b $c\n";
        my $t; $t = AE::timer .5, 0, {{next_def}};
    --ser
        undef $t;
        print "Nest second $a $b $c\n";
        my $d = 'd';
        my $t; $t = AE::timer .5, 0, {{next_def}};
    }}ser
    print "After nest begin\n";
--ser
    undef $t;
    print "Test par\n";

    my $par_cv = AE::cv;
    $par_cv->begin {{next_def}};

    for(0..4) {{ser
        $par_cv->begin;
        my $n = $_;
        my $delay = .5 - $_*.02;
        my $t; $t = AE::timer $delay, 0, {{next_def}};
    --ser
        undef $t;
        print "par1 $n after $delay\n";
        $par_cv->end;
    }}ser

    for(0..4) {{ser
        $par_cv->begin;
        my $n = $_;
        my $delay = $_*.02;
        my $t; $t = AE::timer $delay, 0, {{next_def}};
    --ser
        undef $t;
        print "par2 $n after $delay\n";
        $par_cv->end;
    }}ser

    $par_cv->end;
--ser
    print "Done $a $b $c $d\n";
    $_dserone->send;
}}ser
$_dserone->recv;

=comment Expected Output

Begin
First a
Second (no delay) a b
Nest begin a b c
After nest begin
After Second a
Nest second a b c
Test par
par2 0 after 0
par2 1 after 0.02
par2 2 after 0.04
par2 3 after 0.06
par2 4 after 0.08
par1 4 after 0.42
par1 3 after 0.44
par1 2 after 0.46
par1 1 after 0.48
par1 0 after 0.5
Done a b c d

=cut
