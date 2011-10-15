#!/usr/bin/perl

use strict;
use warnings;
use Combinator;

use AE;

print "1\n"; # 2

my $done = AE::cv;

ser{{
    my $t; $t = AE::timer .5, 0, {{next}};
ser--
    undef $t;
    print "First\n";
    {{next}}->();
ser--
    print "Second (no delay)\n";
    my $t; $t = AE::timer .5, 0, {{next}};
ser--
    undef $t;
    print "Done\n";
    $done->send;
ser}}

$done->recv;

=comment

{
    my $t; $t = AE::timer 2, 0, sub {
        undef $t;
        print "First\n";
        my $t; $t = AE::timer 2, 0, sub {
            undef $t;
            print "Done\n";
            $done->send;
        };
    };
}

{
    my $t; $t = AE::timer 2, 0, $next;
    $next = sub {
        undef $t;
        print "First\n";
        my $t; $t = AE::timer 2, 0, sub {
            undef $t;
            print "Done\n";
            $done->send;
        };
    };
}

=cut
