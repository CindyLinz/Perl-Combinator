#!/usr/bin/perl

use strict;
use warnings;
use Combinator;

use AE;

my $ser_done = AE::cv;
ser{{
    my $t; $t = AE::timer .5, 0, {{next_sub}};
    my $a = 'a';
ser--
    undef $t;
    print "First $a\n";
    {{next}};
    my $b = 'b';
ser--
    print "Second (no delay) $a $b\n";
    my $t; $t = AE::timer .5, 0, {{next_sub}};
    my $c = 'c';
ser--
    undef $t;
    print "Done $a $b $c\n";
    $ser_done->send;
ser}}
$ser_done->recv;

=comment

my $ser_done = AE::cv;
Combinator::once sub { local $Combinator::holder = do { \ my $foo };
    my $t; $t = AE::timer .5, 0, Combinator::lazy_sub($Combinator::holder);
    my $a = 'a';

    $$Combinator::holder = sub { local $Combinator::holder = do { \ my $foo };
        undef $t;
        print "First $a\n";
        Combinator::lazy_once($Combinator::holder);
        my $b = 'b';

        $$Combinator::holder = sub { local $Combinator::holder = do { \ my $foo };
            print "Second (no delay) $a $b\n";
            my $t; $t = AE::timer .5, 0, Combinator::lazy_sub($Combinator::holder);
            my $c = 'c';
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
