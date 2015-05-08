//
//  MWKSection+WMFSharing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSection.h"
#import "WMFSharing.h"

@interface MWKSection (WMFSharing)
<WMFSharing>

/// @return A share snippet using a particular xpath to get HTML elements from the receiver's `text`.
- (NSString*)shareSnippetFromTextUsingXpath:(NSString*)xpath;

@end
