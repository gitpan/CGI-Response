#!/usr/local/bin/perl

package CGI::Response;

# use strict;

use Carp;
use Exporter;
use SelfLoader;

@ISA    = qw( Exporter );
@EXPORT = qw( ContentType NoCache NoContent Redirect RetryAfter );

$CGI::Response::VERSION          = '0.021';
$CGI::Response::http_version     = '1.0';
$CGI::Response::line_end         = "\n";
$CGI::Response::DefaultInterface = '';

### Simple Interface

sub ContentType {
  "Content-Type: " .
    ( (@_) ? ($_[0]) : 'text/html' ) .
      ("$line_end" x 2);
}

sub NoCache {
  "Pragma: no-cache" . "$line_end" .
    "Content-Type: " . ( @_ ? $_[0] : 'text/html' ) . "$line_end" .
      "Expires: " . &_date_string . ("$line_end" x 2);
}

sub NoContent {
  "Status: 204 No Content" . ("$line_end" x 2);
}

sub Redirect {
  croak ("Redirect requested but destination URL not specified")
    unless $_[0];
  "Location: $_[0]" . "$line_end" .
    "Status: " . ( $_[1] ? '301 Moved Permanently' :
		  '302 Moved Temporarily' ) . ("$line_end" x 2);
}

sub RetryAfter {
  "Retry-After: " . &_date_string( @_ ? $_[0] : '300' ) . 
    "$line_end" .
      "Status: 503 Service Unavailable" . ("$line_end" x 2);
}

sub CGI::Response::new;
sub CGI::Response::status;
sub CGI::Response::date;
sub CGI::Response::forwarded;
sub CGI::Response::mime_version;
sub CGI::Response::pragma;
sub CGI::Response::location;
sub CGI::Response::public;
sub CGI::Response::retry_after;
sub CGI::Response::server;
sub CGI::Response::www_authenticate;
sub CGI::Response::allow;
sub CGI::Response::content_encoding;
sub CGI::Response::content_language;
sub CGI::Response::content_transfer_encoding;
sub CGI::Response::content_type;
sub CGI::Response::expires;
sub CGI::Response::link;
sub CGI::Response::uri;
sub CGI::Response::as_string;
sub CGI::Response::Interface;
sub CGI::Response::cgi;
sub CGI::Response::_one;
sub CGI::Response::_many;
sub CGI::Response::_date_string;
sub CGI::Response::_my_uri;
sub CGI::Response::_no_default;

1;

__DATA__

### Full Interface

sub new {
  require HTTP::Headers;
  
  my( $class ) = shift;
  my $self = {};
  bless $self;
  $self->{'_header'} = new HTTP::Headers;
  
  my( $status )  = ( shift || '' );
  return $self unless $status;
  my( $message ) = ( shift || '' );
  $self->status("$status", "$message");
  $self;
}

sub status {
  require HTTP::Status;

  my( $self )    = shift;
  my( $status )  = ( shift || '' );
  unless ("$status") {
    return ( $self->{'_header'}->header('Status') || '200 OK' );
  }
  my( $message ) = ( shift || '' );
  unless ("$message") {
    $message = HTTP::Status::statusMessage("$status");
  }
  $self->_one( 'Status' => "$status $message" );
}

# General Headers

sub date {
  my( $self ) = shift;
  my( $date ) = &_date_string;
  $self->_one( 'Date' => "$date" );
}

sub forwarded {
  my( $self ) = shift;
  my( $value ) = ( shift || 
		  ( 'by ' . $self->_my_uri .
		   ' for ' . 
		   ( $ENV{"REMOTE_HOST"} ||
		    '[host unknown]' ) ) );
  $self->_many( 'Forwarded' => "$value" );
}

sub mime_version {
  my( $self ) = shift;
  my( $value ) = ( shift || '1.0');
  $self->_one( 'MIME-Version' => "$value" );
}

sub pragma {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('Pragma' => 'no-cache, max-age=[seconds]');
  }
  $self->_many( 'Pragma' => "$value" );
}

# Response Headers

sub location {
  my( $self ) = shift;
  my( $value ) = ( shift || $self->_my_uri );
  $self->_one( 'Location' => "$value" );
}

sub public {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('Public' => 'OPTIONS, MGET, MHEAD');
  }
  $self->_many( 'Public' => "$value" );
}

sub retry_after {
  my( $self ) = shift;
  my( $delta ) = ( shift || '300');
  my( $value ) = &_date_string("$delta");
  $self->_one( 'Retry-After' => "$value" );
}

sub server {
  my( $self )   = shift;
  my( $value ) = ( shift || 
		  $ENV{"SERVER_SOFTWARE"} ||
		  ('CGI-Response/' . "$VERSION") );
  $self->_one( 'Server' => "$value" );
}

sub www_authenticate {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('WWW-Authenticate' => 'Basic [realm]');
  }
  $self->_one( 'WWW-Authenticate' => "$value" );
}

# Entity Headers

sub allow {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('Allow' => 'GET, HEAD, PUT');
  }
  $self->_many( 'Allow' => "$value" );
}

sub content_encoding {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('Content-Encoding' => 'gzip');
  }
  $self->_many( 'Content-Encoding' => "$value" );
}

sub content_language {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('Content-Language' => 'en, dk, mi');
  }
  $self->_many( 'Content-Language' => "$value" );
}

# sub content_length {
# 	my( $self ) = shift;
# 	my( $ ) = ( shift || '');
# 	$self->_one( '' => "$" );
# }

sub content_transfer_encoding {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('Content-Transfer-Encoding' =>
		       'quoted-printable');
  }
  $self->_one( 'Content-Transfer-Encoding' => "$value" );
}

sub content_type {
  my( $self ) = shift;
  my( $value ) = ( shift || 'text/html');
  $self->_one( 'Content-Type' => "$value" );
}

sub expires {
  my( $self )  = shift;
  my( $delta ) = ( shift || '0' );
  my( $value ) = &_date_string("$delta");
  $self->_one( 'Expires' => "$value" );
}

# sub last_modified {
# 	my( $self ) = shift;
# 	my( $ ) = ( shift || '');
# 	$self->_one( '' => "$" );
# }

sub link {
  my( $self ) = shift;
  my( $value ) = ( shift || '');
  unless ("$value") {
    $self->_no_default('Link', '<mailto:timbl@w3.org>; rev="Made"');
  }
  $self->_many( 'Link' => "$value" );
}

# sub title {
# 	my( $self ) = shift;
# 	my( $title ) = ( shift || '');
# 	unless ("$title") {
# 		$self->_no_default('Title', 'My Home Page');
# 	}
# 	my( $getit ) = ( shift || '' );
# 	if ("$getit") {
# 		my( @contents, $contents, $title );
# 		open(FILE, "$file") ||
# 			croak "Couldn\'t open $file to get its title:\n$!\n";
# 		@contents = <FILE>;
# 		close(FILE);
# 		
# 		$contents = join('', @contents);
# 		$contents =~ /<title>([^<]*)<\/title>/im ||
# 			croak "Couldn\'t find a title in $file:\n$!\n";
# 		$title = "$1";
# 		$title =~ s/\n//g;
# 	}
# 	$self->_one( 'Title' => "$title" );
# }

sub uri {
  my( $self ) = shift;
  my( $value ) = ( shift || 
		  '<' . $self->_my_uri . '>' );
  $self->_many( 'URI' => "$value" );
}

# Header Output

sub as_string {
  my( $self )     = shift;
  my( $nph )      = ( shift || '' );
  my( $response ) = '';
  if ("$nph") {
    my( $status ) = '';
    $status = ( $self->{'_header'}->header('Status') || '200 OK' );
    $response = "HTTP/$http_version " . "$status" . "$line_end";
    $self->{'_header'}->removeHeader('Status');
    $response .= $self->{'_header'}->asString("$line_end");
    $self->_one( 'Status' => "$status" ) unless ( $status =~ /^200/ );
  } else {
    $response = $self->{'_header'}->asString("$line_end");
  }
  $response .= "$line_end";
  $response;
}

# sub as_hash {
# 
# }

### Utilites

sub Env {
  my( $cgi ) = Interface();
  $cgi->get_vars_from_env;
  $self->cgi($cgi);
}

sub Interface {
  use CGI::Base;

  if (!$DefaultInterface) {
    $DefaultInterface = new CGI::Base;
  }
  return $DefaultInterface;
}

sub cgi {
  $DefaultInterface;
}

### Private Methods

sub _one {
  my( $self, $header, $value ) = @_;
  $self->{'_header'}->header( "$header" => "$value" );
}

sub _many {
  my( $self, $header, $value ) = @_;
  $self->{'_header'}->pushHeader( "$header" => "$value" );
}

sub _date_string {
  use HTTP::Date;

  my( $delta ) = ( shift || '0' );
  my( $value );
  if ( $delta =~ /^\d+$/ ) {
    $value = time2str( time + $delta );
  } else {
    $value = "$delta";
  }
  return "$value";
}

sub _my_uri {
  my( $self ) = shift;
  my( $uri );
  if ( $ENV{'HTTP_ORIG_URI'} ) {
    $uri = $ENV{'HTTP_ORIG_URI'};
  } elsif ( $ENV{'SERVER_NAME'} ) {
    $uri = 	'http://'.$ENV{'SERVER_NAME'};
    if ( $ENV{'SERVER_PORT'} != (80|0) ) {
      $uri .= ':'.$ENV{'SERVER_PORT'};
    }
    $uri .= $ENV{'SCRIPT_NAME'};
    if ( $ENV{'QUERY_STRING'} ) {
      $uri .= '?'.$ENV{'QUERY_STRING'};
    }
  } else {
    $uri = '[URI unknown]';
  }
  return $uri;
}

sub _no_default {
  my( $self )   = shift;
  my( $header ) = shift;
  my( $values ) = shift;
  my( $method ) = $header;
  $method =~ tr/[A-Z]-/[a-z]_/;
  croak("CGI::Response::$method() must be called with a value;\n" .
	"no default value is provided for it.\n" .
	"Legal values for $header include: $values.\n" . 
	"See the HTTP/$http_version specification, section 8, " .
	"for more information.\n" .
	"$header was added to your header without a value:\n"
	# croak will now insert location of error, "at..."
       );
}

__END__

=head1 NAME

CGI::Response

=head1 VERSION

Version 0.021 (alpha release).

Please note that future versions are not guaranteed to be
backwards-compatible with this version.  The interface will
be frozen at version 0.1 (first beta release).

=head1 AUTHOR

  Marc Hedlund <hedlund@best.com>
  Copyright 1995, All rights reserved

=cut



