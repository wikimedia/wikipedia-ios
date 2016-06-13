//  Created by Monte Hurd on 5/31/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MediaWikiKit.h"
@interface MWKSection (DisplayHtml)

/*
   Just before section html is sent to the web view, add
   section identifiers around each section. This will make it easy to
   identify section offsets for the purpose of scrolling the web view to a
   given section. Do not save this html to the data store - this way
   it can be changed later if necessary (to a div etc).
 */

- (NSString*)displayHTML;

@end
