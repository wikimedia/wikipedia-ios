//  Created by Monte Hurd on 12/31/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKArticle+isMain.h"
#import "SessionSingleton.h"

@implementation MWKArticle (isMain)

- (BOOL)isMain {
    return [[SessionSingleton sharedInstance] articleIsAMainArticle:self];
}

@end
