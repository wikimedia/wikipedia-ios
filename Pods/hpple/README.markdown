# DESCRIPTION

Hpple: A nice Objective-C wrapper on the XPathQuery library for parsing HTML.

Inspired by why the lucky stiff's [Hpricot](http://github.com/why/hpricot/tree/master).

# CREDITS

Hpple was created by Geoffrey Grosenbach, [Topfunky Corporation](http://topfunky.com) and [PeepCode Screencasts](http://peepcode.com).

[Contributors](https://github.com/topfunky/hpple/graphs/contributors)

# FEATURES

* Easy searching by XPath (CSS selectors are planned)
* Parses HTML (XML coming soon)
* Easy access to tag content, name, and attributes.

# INSTALLATION

* Open your XCode project and the Hpple project.
* Drag the "Hpple" directory to your project.
* Add the libxml2.2.dylib framework to your project and search paths as described at [Cocoa with Love](http://cocoawithlove.com/2008/10/using-libxml2-for-parsing-and-xpath.html)

More documentation and short screencast coming soon...

# USAGE

See TFHppleHTMLTest.m in the Hpple project for samples.

<pre>
#import "TFHpple.h"

NSData  * data      = [NSData dataWithContentsOfFile:@"index.html"];

TFHpple * doc       = [[TFHpple alloc] initWithHTMLData:data];
NSArray * elements  = [doc search:@"//a[@class='sponsor']"];

TFHppleElement * element = [elements objectAtIndex:0];
[e text];                       // The text inside the HTML element (the content of the first text node)
[e tagName];                    // "a"
[e attributes];                 // NSDictionary of href, class, id, etc.
[e objectForKey:@"href"];       // Easy access to single attribute
[e firstChildWithTagName:@"b"]; // The first "b" child node

</pre>

# TODO

* Internal error catching and messages
* CSS3 selectors in addition to XPath
