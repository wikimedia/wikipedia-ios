#!/usr/bin/php -q
<?php

/**
 * AppleFFS class implements support for Apple .strings files.
 * This class reads and writes only UTF-8 files.
 *
 * @author Brion Vibber <bvibber@wikimedia.org>
 *
 * derived from the AppleFFS in Translate extension, but hacked down
 */
class AppleStringsFile {
	// READ

	public function readFromFile( $path ) {
		$data = file_get_contents( $path );
		return $this->readFromVariable( $data );
	}

	public function write( $data ) {
		return $this->writeReal( $data );
	}

	/**
	 * @param array $data
	 * @return array Parsed data.
	 * @throws Exception
	 */
	public function readFromVariable( $data ) {
		$lines = explode( "\n", $data );
		$authors = $messages = array();
		$linecontinuation = false;

		$value = '';
		foreach ( $lines as $line ) {
			if ( $linecontinuation ) {
				$linecontinuation = false;
				$valuecont = $line;
				$value .= $valuecont;
			} else {
				if ( $line === '' ) {
					continue;
				}

				if ( substr( $line, 0, 2 ) === '//' ) {
					// Single-line comment
					$match = array();
					$ok = preg_match( '~//\s*Author:\s*(.*)~', $line, $match );
					if ( $ok ) {
						$authors[] = $match[1];
					}
					continue;
				}

				if ( substr( $line, 0, 2 ) === '/*' ) {
					if ( strpos( $line, '*/', 2 ) === false ) {
						$linecontinuation = true;
					}
					continue;
				}

				list( $key, $value ) = self::readRow( $line );
				$messages[$key] = $value;
			}
		}

		return array(
			'AUTHORS' => $authors,
			'MESSAGES' => $messages,
		);
	}

	/**
	 * Parses non-empty strings file row to key and value.
	 * @param string $line
	 * @throws Exception
	 * @return array( string $key, string $val )
	 */
	public static function readRow( $line ) {
		$match = array();
		if ( preg_match( '/^"((?:\\\"|[^"])*)"\s*=\s*"((?:\\\"|[^"])*)"\s*;\s*$/', $line, $match ) ) {
			$key = self::unescapeString( $match[1] );
			$value = self::unescapeString( $match[2] );
			if ( $key === '' ) {
				throw new Exception( "Empty key in line $line" );
			}
			return array( $key, $value );
		} else {
			throw new Exception( "Unrecognized line format: $line" );
		}
	}

	// Write

	/**
	 * @param MessageCollection $collection
	 * @return string
	 */
	protected function writeReal( array $collection ) {
		$header = $this->doHeader( $collection );
		$header .= $this->doAuthors( $collection );
		$header .= "\n";

		$output = '';

		/**
		 * @var TMessage $m
		 */
		foreach ( $collection['MESSAGES'] as $key => $m ) {
			$value = $m;

			if ( $value === '' ) {
				continue;
			}

			$output .= self::writeRow( $key, $value );
		}

		if ( $output ) {
			$data = $header . $output;
		} else {
			$data = $header;
		}

		return $data;
	}

	/**
	 * Writes well-formed properties file row with key and value.
	 * @param string $key
	 * @param string $value
	 * @return string
	 */
	public static function writeRow( $key, $value ) {
		return self::quoteString( $key ) . ' = ' . self::quoteString( $value ) . ';' . "\n";
	}

	/**
	 * Quote and escape Obj-C-style strings for .strings format
	 */
	protected static function quoteString( $str ) {
		return '"' . self::escapeString( $str ) . '"';
	}

	/**
	 * Escape Obj-C-style strings; use backslash-escapes etc.
	 *
	 * @param string $str
	 * @return string
	 */
	protected static function escapeString( $str ) {
		$str = addcslashes( $str, '\\"' );
		$str = str_replace( "\n", '\\n', $str );
		return $str;
	}

	/**
	 * Unescape Obj-C-style strings; can include backslash-escapes
	 *
	 * @todo support \UXXXX
	 *
	 * @param string $str
	 * @return string
	 */
	protected static function unescapeString( $str ) {
		return stripcslashes( $str );
	}

	/**
	 * @param MessageCollection $collection
	 * @return string
	 */
	protected function doHeader( array $collection ) {
		if ( isset( $this->extra['header'] ) ) {
			$output = $this->extra['header'];
		} else {
			$wgSitename = 'translatewiki.net';

			$name = 'Message documentation';
			$native = 'Message documentation';
			$output = "// Messages for $name ($native)\n";
			$output .= "// Exported from $wgSitename\n";
		}

		return $output;
	}

	/**
	 * @param MessageCollection $collection
	 * @return string
	 */
	protected function doAuthors( array $collection ) {
		$output = '';
		$authors = $collection['AUTHORS'];

		foreach ( $authors as $author ) {
			$output .= "// Author: $author\n";
		}

		return $output;
	}
}

function fillStubs( &$en, &$qqq ) {
	$enKeys = array_keys( $en['MESSAGES'] );
	$qqqKeys = array_keys( $qqq['MESSAGES'] );
	$missing = array_diff( $enKeys, $qqqKeys );
	$extra = array_diff( $qqqKeys, $enKeys );

	if (count( $missing ) > 0 || count( $extra ) > 0 ) {
		foreach( $missing as $key ) {
			$qqq['MESSAGES'][$key] = 'MISSING DESCRIPTION; DO NOT COMMIT FILE YET';
		}
		foreach( $extra as $key ) {
			unset($qqq['MESSAGES'][$key]);
		}
		return true;
	} else {
		return false;
	}
}

function processStubs( $filename ) {
	$base = realpath( dirname( __DIR__ ) ) . "/Wikipedia/Localizations";

	$parser = new AppleStringsFile();

	$file_en = "$base/en.lproj/$filename.strings";
	$file_qqq = "$base/qqq.lproj/$filename.strings";

	$data_en = $parser->readFromFile( $file_en );
	$data_qqq = $parser->readFromFile( $file_qqq );

	if (fillStubs( $data_en, $data_qqq )) {
		$out = $parser->write( $data_qqq );
		file_put_contents( $file_qqq, $out );
		echo "Updated qqq.lproj/$filename.strings\n";
	}
}

processStubs('InfoPlist');
processStubs('Localizable');
