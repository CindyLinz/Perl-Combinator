#!/usr/bin/perl

use strict;
use warnings;
use Combinator;

use AE;

my $ser_done = AE::cv;
ser{{
    my $a = 'a';
    my $t; $t = AE::timer .5, 0, {{next_sub}};
ser--
    undef $t;
    my $b = 'b';
    print "First $a\n";
    {{next}};
ser--
    print "Second (no delay) $a $b\n";
    my $c = 'c';
    my $t; $t = AE::timer .5, 0, {{next_sub}};
ser--
    undef $t;
    print "Done $a $b $c\n";
    $ser_done->send;
ser}}
$ser_done->recv;

=comment

my $ser_done = AE::cv;
Combinator::once sub { local $Combinator::holder = do { \ my $foo };
    my $a = 'a';
    my $t; $t = AE::timer .5, 0, Combinator::lazy_sub($Combinator::holder);

    $$Combinator::holder = sub { local $Combinator::holder = do { \ my $foo };
        undef $t;
        my $b = 'b';
        print "First $a\n";
        Combinator::lazy_once($Combinator::holder);

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
