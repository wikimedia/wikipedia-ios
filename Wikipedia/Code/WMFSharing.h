//
//  WMFSharing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Protocol for shareable Wikipedia entities.
 */
@protocol WMFSharing <NSObject>

/// @return A plain text string which is a snippet of the article's text, or an empty string on failure.
- (NSString *)shareSnippet;

@end
