package Combinator;

use strict;
use warnings;

use Filter::Simple;

my %opt;
my $begin_pat;
my $end_pat;
my $ser_pat;
my $par_pat;
my $com_pat;
my $token_pat;
my $line_shift;

our $cv1 = [];

sub import {
    my $self = shift;
    %opt = (
        verbose => 0,
        begin => qr/\{\{com\b/,
        ser => qr/--ser\b/,
        par => qr/--com\b/,
        end => qr/\}\}com\b/,
        next => qr/\{\{next\}\}/,
        @_
    );
    $begin_pat = $opt{begin};
    $end_pat = $opt{end};
    $ser_pat = $opt{ser};
    $par_pat = $opt{par};
    $com_pat = qr/($begin_pat((?:(?-2)|(?!$begin_pat).)*)$end_pat)/s;
    $token_pat = qr/$com_pat|(?!$begin_pat)./s;
    $line_shift = (caller)[2];
}

sub att_sub {
    my($att, $cb) = @_;
    sub {
        unshift @_, $att;
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
    my $out = "local\$Combinator::cv1=[1];$code;--\$Combinator::cv1->[0];Combinator::cv_cb(\$Combinator::cv1,Combinator::att_sub(\$Combinator::cv0,sub{local\$Combinator::cv0=shift;$next}))";
    return $out;
}

sub com { # depth, code
    my($depth, $code) = @_;
    my @ser;
    $code .= "\n" if( substr($code, -1) eq "\n" );
    push @ser, $1 while( $code =~ m/(?:^|$ser_pat)($token_pat*?)(?=$ser_pat|$)/gs );
    my $out = "{local\$Combinator::cv0=\$Combinator::cv1;++\$Combinator::cv0->[0];" .
        ser($depth+1, @ser, "Combinator::cv_end(\$Combinator::cv0,\\\@_)") .
        "}";
    return $out;
}

sub replace_code {
    my $depth = shift;
    $_[0] =~ s[$com_pat]{
        my $code = $2;
        my $out = '';
        $code .= "\n" if( substr($code, -1) eq "\n" );
        while( $code =~ /(?:^|$par_pat)($token_pat*?)(?=$par_pat|$(?!.))/g ) {
            my $code = $1;
            $out .= com($depth, $1);
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
