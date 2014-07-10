#!/usr/bin/php -q
<?php

# Xcode 5 doesn't update the Main_iPhone.strings file extracted from the
# base localization's storyboard. Let's update it manually for the moment.
#
# @todo: add new strings to qqq.lproj/Main_iPhone.strings as well

$base = realpath( dirname( __DIR__) );

$tmpfile = tempnam( "/var/tmp", "apps-ios-wikipedia-storyboard-strings");
$infile = "$base/wikipedia/Base.lproj/Main_iPhone.storyboard";
$outfile = "$base/wikipedia/en.lproj/Main_iPhone.strings";

$encInfile = escapeshellarg( $infile );
$encTmpfile = escapeshellarg( $tmpfile );
$cmd = "ibtool --export-strings-file $encTmpfile $encInfile";

$result = exec( $cmd );

if ($result != 0) {
	echo "ERROR $result FROM ibtool!\n";
	exit( 1 );
} else {
	# ibtool produces .strings files in UTF-16 but we want them in UTF-8
	$utf16 = file_get_contents( $tmpfile );
	if ($utf16 === false) {
		echo "Could not load $tmpfile\n";
		exit( 1 );
	}
	
	$utf8 = mb_convert_encoding( $utf16, "UTF-8", "UTF-16" );
	if ( $utf8 === false ) {
		echo "Could not convert UTF-16 to UTF-8\n";
		exit( 1 );
	}

	$ok = file_put_contents( $outfile, $utf8 );
	if (!$ok) {
		echo "Could not write $outfile\n";
		exit( 1 );
	}
	
	unlink( $tmpfile );
	
	exit( 0 );
}
