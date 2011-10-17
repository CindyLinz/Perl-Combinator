#!/usr/bin/perl

use strict;
use warnings;
use Combinator;

use AE;

my $ser_done = AE::cv;
ser{{
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
    my $t; $t = AE::timer .5, 0, {{next_def}};
ser--
    undef $t;
    print "Done $a $b $c\n";
    $ser_done->send;
ser}}
$ser_done->recv;

=comment

(Out of date)

my $ser_done = AE::cv;
Combinator::once sub { local $Combinator::holder = do { \ my $foo };
    my $a = 'a';
    my $t; $t = AE::timer .5, 0, Combinator::lazy_sub($Combinator::holder);

    $$Combinator::holder = sub { local $Combinator::holder = do { \ my $foo };
        undef $t;
        print "First $a\n";
        my $b = 'b';
        Combinator::lazy_once($Combinator::holder);
        print "After Second $a\n";

        $$Combinator::holder = sub { local $Combinator::holder = do { \ my $foo };
            print "Second (no delay) $a $b\n";
            my $c = 'c';
            my $t; $t = AE::timer .5, 0, Combinator::lazy_sub($Combinator::holder);
            $$Combinator::holder = sub { local $Combinator::holder = do { \ my $foo };
                undef $t;
                print "Done $a $b $c\n";
                $ser_done->send;
            };
        };
    };
};
$ser_done->recv;

=cut

#my $nest_ser_done = AE::cv;
#ser{{
#    print "nest begin\n";
#    my $t; $t = AE::timer .5, 0, {{next}};
#ser--
#    undef $t;
#    print "nest second\n";
#    ser{{
#        print "inner begin\n";
#        my $t; $t = AE::timer .5, 0, {{next}};
#    ser--
#        undef $t;
#        print "inner second\n";
#        {{next}}->();
#    ser}}
#    print "after inner begin (at outer)\n";
#ser--
#    print "inner end (at outer)\n";
#    $nest_ser_done->send;
#ser}}
#$nest_ser_done->recv;

=comment
my $nest_ser_done = AE::cv;
{
    print "nest begin\n";
    my $t; $t = AE::timer .5, 0, sub {
        undef $t;
        print "nest second\n";
        my $next;
        {
            print "inner begin\n";
            my $t; $t = AE::timer .5, 0, sub {
                undef $t;
                print "inner second\n";
                $next->();
            };
        }
        print "after inner begin (at outer)\n";
        $next = sub {
            print "inner end (at outer)\n";
            $nest_ser_done->send;
        };
    };
}
$nest_ser_done->recv;
=cut

#ser{{
#    print "AB begin\n";
#    my $t; $t = AE::timer .5, 0, {{next}};
#ser--
#    undef $t;
#    par{{
#        ser{{
#            print "A begin\n";
#            my $t; $t = AE::timer 2, 0, {{next}};
#        ser--
#            undef $t;
#            print "A end\n";
#            {{next}}->();
#        ser}}
#    par--
#        ser{{
#            my $t; $t = AE::timer 1, 0, {{next}};
#            print "B begin\n";
#        ser--
#            undef $t;
#            print "B end\n";
#            {{next}}->();
#        ser}}
#    par}}
#ser--
#    print "AB end\n";
#ser}}

=comment
$par_done = AE::cv;
{
    print "AB begin\n";
    my $t; $t = AE::timer .5, 0, sub {
        undef $t;

        my $par_cv;

        $par_cv->begin;
        {
            print "A begin\n";
            my $t; $t = AE::timer 2, 0, sub {
                undef $t;
                print "A end\n";
                $par_cv->end;
            };
        }
        $par_cv->begin;
        {
            print "B begin\n";
            my $t; $t = AE::timer 1, 0, sub {
                undef $t;
                print "B end\n";
                $par_cv->end;
            };
        }
    };
}
$par_done->recv;
=cut

