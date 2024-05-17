 # Read recording into memory
my $bytes = 0;
my $recording = '';
my $total = 0;
if ( open F, "<$mixed" ) {
        binmode F;
        do {
                my $chunk;
                $bytes = read( F, $chunk, 1048576 );
                $recording .= $chunk;
                $total += $bytes;
        } while ( $bytes > 0 );
        close F;
}
print "$$: Read recording $mixed of $total bytes into memory\n";
# Upload to HTTP(S) server
print "$$: Uploading with HTTP POST to $upload->{ 'location' }\n";
my $ua = LWP::UserAgent->new( agent => 'Recording upload', timeout => 5 );
if ( $upload->{ 'password' } && $upload->{ 'username' } ) {
        $ua->default_header( Authorization => 'Basic ' . b64_encode( "$upload->{ 'username' }:$upload->{ 'password' }" ) );
} elsif ( $upload->{ 'username' } ) {
        $ua->default_header( Authorization => $upload->{ 'username' } );
}
$data->{ 'scustomer' } = $r->{ 'scustomer' };
$data->{ 'dcustomer' } = $r->{ 'dcustomer' };
$data->{ 'recording' } = $recording;
my $response = $ua->post( $upload->{ 'location' }, 'Content-Type' => 'multipart/form-data', Content => [ %{ $data } ] );
if ( $response->is_success() ) {
        my $decoded_content = $response->decoded_content();
        my $log_content = substr( $decoded_content, 0, 2000 );
        print "$$: HTTP POST response: $log_content\n";
} else {
        warn "$$: HTTP POST error: " . $response->status_line . "\n";
}
