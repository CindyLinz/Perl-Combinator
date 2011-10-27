package Combinator;

use strict;
use warnings;

use Filter::Simple;
use Guard;
use callee;

my %opt;
my $begin_pat;
my $end_pat;
my $cir_begin_pat;
my $ser_pat;
my $par_pat;
my $cir_par_pat;
my $com_pat;
my $token_pat;
my $line_shift;

our $cv1 = [];

sub import {
    my $self = shift;
    %opt = (
        verbose => 0,
        begin => qr/\{\{com\b/,
        cir_begin => qr/\{\{cir\b/,
        ser => qr/--ser\b/,
        par => qr/--com\b/,
        cir_par => qr/--cir\b/,
        end => qr/\}\}com\b/,
        next => qr/\{\{next\}\}/,
        @_
    );
    $begin_pat = qr/$opt{begin}|$opt{cir_begin}/;
    $end_pat = $opt{end};
    $ser_pat = $opt{ser};
    $par_pat = $opt{par};
    $cir_begin_pat = $opt{cir_begin};
    $cir_par_pat = $opt{cir_par};
    $com_pat = qr/($begin_pat((?:(?-2)|(?!$begin_pat).)*)$end_pat)/s;
    $token_pat = qr/$com_pat|(?!$begin_pat)./s;
    $line_shift = (caller)[2];
}

sub att_sub {
    my($att1, $att2, $cb) = @_;
    sub {
        unshift @_, $att1, $att2;
        &$cb;
    }
}

# $cv = [wait_count, cb, args]
sub cv_end { # (cv, args)
    --$_[0][0];
    push @{$_[0][2]//=[]}, @{$_[1]} if $_[1];
    if( !$_[0][0] && $_[0][1] ) {
        my $cb = delete $_[0][1];
        $cb->(@{$_[0][2]});
    }
}
sub cv_cb { # (cv, cb)
    if( $_[0][0] ) {
        $_[0][1] = $_[1];
    }
    else {
        $_[1](@{$_[0][2]});
    }
}

sub ser {
    my $depth = shift;
    if( @_ <= 1 ) { # next only
        return $_[0];
    }
    my $code = shift;
    unshift @_, $depth;
    my $next = &ser;
    replace_code($depth, $code);
    $code =~ s/$opt{next}/(do{my\$t=\$Combinator::cv1;++\$t->[0];sub{Combinator::cv_end(\$t,\\\@_)}})/g;
    my $out = "local\$Combinator::guard=Guard::guard{Combinator::cv_end(\$Combinator::cv0,\\\@_)};local\$Combinator::cv1=[1];$code;--\$Combinator::cv1->[0];Combinator::cv_cb(\$Combinator::cv1,Combinator::att_sub(\$Combinator::head,\$Combinator::cv0,sub{local\$Combinator::head=shift;local\$Combinator::cv0=shift;$next}));\$Combinator::guard->cancel";
    return $out;
}

sub com { # depth, code, cir
    my($depth, $code, $cir) = @_;
    my @ser;
    $code .= "\n" if( substr($code, -1) eq "\n" );
    push @ser, $1 while( $code =~ m/(?:^|$ser_pat)($token_pat*?)(?=$ser_pat|$)/gs );
    my $out = "{sub{local\$Combinator::head=[1,callee::callee];local\$Combinator::cv0=\$Combinator::cv1;++\$Combinator::cv0->[0];" .
        ser($depth+1, @ser, $cir ? "--\$Combinator::cv0->[0];\$Combinator::cv1=\$Combinator::cv0;Combinator::cv_end(\$Combinator::head,\\\@_)" : "Combinator::cv_end(\$Combinator::cv0,\\\@_)") .
        "}->()}";
    return $out;
}

sub replace_code {
    my $depth = shift;
    $_[0] =~ s[$com_pat]{
        my $code = $1;
        my $out = '';
        while( $code =~ /($begin_pat|$par_pat|$cir_par_pat)($token_pat*?)(?=($par_pat|$cir_par_pat|$end_pat))/g ) {
            my $fragment = $2;
            $out .= com($depth, $fragment, $1 =~ /^(?:$cir_par_pat|$cir_begin_pat)$/);
        }
        $out;
    }ge;
}

FILTER {
    replace_code(0, $_);
    if( $opt{verbose} ) {
        my $verbose_code = $_;
        my $n = $line_shift;
        $verbose_code =~ s/^/sprintf"%6d: ", ++$n/gem;
        print "Code after filtering:\n$verbose_code\nEnd Of Code\n";
    }
};

1;
