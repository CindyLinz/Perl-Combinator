#!/usr/bin/perl

use strict;
use warnings;
use Combinator;

use AE;

my $ser_done = AE::cv;
ser{{
    print "Begin\n";
    my $a = 'a';
    my $t; $t = AE::timer .5, 0, {{next_def}};
    # or
    # my $t; {{next_def}}; $t = AE::timer .5, 0, {{next_sub}};
ser--
    undef $t;
    print "First $a\n";
    my $b = 'b';
    {{next_def}}->();
    # or
    # {{next_def}}; {{next_run}};
    print "After Second $a\n";
ser--
    print "Second (no delay) $a $b\n";
    my $c = 'c';
    ser{{
        print "Nest begin $a $b $c\n";
        my $t; $t = AE::timer .5, 0, {{next_def}};
    ser--
        undef $t;
        print "Nest second $a $b $c\n";
        my $d = 'd';
        my $t; $t = AE::timer .5, 0, {{next_def}};
    ser}}
    print "After nest begin\n";
ser--
    undef $t;
    print "Done $a $b $c $d\n";
    $ser_done->send;
ser}}
$ser_done->recv;

=comment Expected Output

Begin
First a
Second (no delay) a b
Nest begin a b c
After nest begin
After Second a
Nest second a b c
Done a b c d

=cut

