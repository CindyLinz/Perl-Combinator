#!/usr/bin/perl

use strict;
use warnings;
use Combinator verbose => 1;

use AE;

my $ser_done = AE::cv;
{{com
    print "Begin\n";
    my $a = 'a';
    my $t; $t = AE::timer .5, 0, {{next}};

  --ser
    undef $t;
    print "First $a\n";
    my $b = 'b';

  --ser
    print "Second (no delay) $a $b\n";
    my $c = 'c';
    {{com
        print "Nest begin $a $b $c\n";
        my $t; $t = AE::timer .5, 0, {{next}};
        my $d = 'd';
      --ser
        undef $t;
        print "Nest second $a $b $c $d\n";
        return;
      --ser
        print "Won't be here\n";
    }}com
    print "After nest begin\n";
  --ser
    print "Test par\n";

    for(0..4) {{com
        my $n = $_;
        my $delay = .5 - $_*.02;
        my $t; $t = AE::timer $delay, 0, {{next}};
      --ser
        undef $t;
        print "par1 $n after $delay\n";
        {{next}}->($n); # push args to the next receiver
    }}com

    for(0..4) {{com
        my $n = $_;
        my $delay = $_*.02;
        my $t; $t = AE::timer $delay, 0, {{next}};
      --ser
        undef $t;
        print "par2 $n after $delay\n";
        {{next}}->($n); # push args to the next receiver
    }}com

  --ser
    print "Done $a $b $c @_\n"; # print the received args
    $ser_done->send;
}}com
$ser_done->recv;

my $par_cv = AE::cv;
{{com
    print "Jobs begin\n";
    {{com
        print "Job 1 begin\n";
        my $t; $t = AE::timer 1, 0, {{next}};
      --ser
        undef $t;
        print "Job 1 done\n";
    --com
        print "Job 2 begin\n";
        my $t; $t = AE::timer .5, 0, {{next}};
      --ser
        undef $t;
        print "Job 2 done\n";
    }}com
    print "Jobs begun\n";
  --ser
    print "Jobs done\n";
    $par_cv->send;
}}com
$par_cv->recv;

=comment Expected Output

Begin
First a
Second (no delay) a b
Nest begin a b c
After nest begin
Nest second a b c d
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
Done a b c 0 1 2 3 4 4 3 2 1 0
Jobs begin
Job 1 begin
Job 2 begin
Jobs begun
Job 2 done
Job 1 done
Jobs done

=cut
