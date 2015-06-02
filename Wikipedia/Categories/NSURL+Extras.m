//  Created by Monte Hurd on 6/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSURL+Extras.h"

@implementation NSURL (Extras)

- (NSString*)wmf_schemelessURLString {
    NSRange dividerRange = [self.absoluteString rangeOfString:@"://"];
    if (dividerRange.location == NSNotFound) {
        return self.absoluteString;
    }
    NSUInteger divide = NSMaxRange(dividerRange) - 2;
    NSString* path    = [self.absoluteString substringFromIndex:divide];
    return path;
}

@end
