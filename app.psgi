#!/usr/bin/env perl
use 5.10.1;
use strict;
use warnings;
use Imager;
use Digest::MD5 qw(md5);
use POSIX qw(floor);
use Plack::Request;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $img = Imager->new( xsize => 64, ysize => 64 );

    my $n     = 0;
    my $email = $req->param('email') // '';
    my $mask  = $req->param('mask') // 'ffffff';
    my ( $r, $g, $b ) = unpack 'C*', pack 'H*', $mask;
    foreach my $val ( unpack( "C16", md5($email) ) ) {
        $img->box(
            color => Imager::Color->new( $val & $r, $val & $g, $val & $b ),
            xmin  => 16 * int( $n / 4 ),
            ymin => 16 * ( $n % 4 ),
            xmax => 16 * ( floor( $n / 4 ) + 1 ),
            ymax => 16 * ( ( $n % 4 ) + 1 ),
            filled => 1,
        );
        $n++;
    }

    my $buffer;
    $img->write( type => 'png', data => \$buffer );

    return [ 200, [ 'Content-Type' => 'image/png', 'Content-Length' => length($buffer) ], [$buffer] ];
};

