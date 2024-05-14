#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Server::Simple::CGI;
use CGI;
use Data::Dumper;
use POSIX qw(strftime);

{
    package MyWebServer;
    use base qw(HTTP::Server::Simple::CGI);
    use Data::Dumper;

    # Open a log file for debugging
    open my $log_fh, '>>', '/tmp/server.log' or die "Could not open log file: $!";

    sub log_message {
        my ($message) = @_;
        print $log_fh $message . "\n";
        warn $message . "\n";
    }

    my %dispatch = (
        '/' => \&resp_cgi,
    );

    sub handle_request {
        my $self = shift;
        my $cgi  = shift;

        my $path = $cgi->path_info();
        my $handler = $dispatch{$path};

        if (ref($handler) eq "CODE") {
            print "HTTP/1.0 200 OK\r\n";
            $handler->($cgi);
        } else {
            print "HTTP/1.0 404 Not Found\r\n";
            print $cgi->header,
                  $cgi->start_html('Not Found'),
                  $cgi->h1('Not Found'),
                  $cgi->end_html;
        }
    }

    sub resp_cgi {
        my $cgi  = shift;   # CGI.pm object
        return if !ref $cgi;

        log_message("---- NEW WEB REQUEST ----");

        log_message("Headers:");
        my %headers = map { $_ => $cgi->http($_) } $cgi->http();
        log_message(Dumper(\%headers));

        log_message("Parameters:");
        my %params = $cgi->Vars;
        log_message(Dumper(\%params));

        my $response = {
            headers => \%headers,
            params  => \%params,
        };

        if ( my $upload = $cgi->upload('recording') ) {
            my $filename = $cgi->param('recording');
            my ($basename, $ext) = $filename =~ /^(.*?)(\.[^.]+)$/;  # Split the filename into base and extension
            my $timestamp = POSIX::strftime("%Y%m%d%H%M%S", localtime);
            my $new_filename = "${basename}_${timestamp}${ext}";
            if ( open my $fh, '>', "/tmp/$new_filename" ) {
                binmode $fh;
                while ( my $bytesread = read($upload, my $buffer, 1024) ) {
                    print $fh $buffer;
                }
                close $fh;
                log_message("Wrote recording file: /tmp/$new_filename");
            } else {
                log_message("Cannot write recording file: /tmp/$new_filename");
            }
        }

        print $cgi->header('text/plain');
        print Dumper($response);
    }
}

my $port = shift || 8080;
my $server = MyWebServer->new($port);
MyWebServer::log_message("Server running on port $port...");
$server->run();
