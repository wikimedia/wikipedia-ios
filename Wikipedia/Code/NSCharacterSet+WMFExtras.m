//  Created by Monte Hurd on 8/20/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSCharacterSet+WMFExtras.h"

@implementation NSCharacterSet (WMFExtras)

+ (NSCharacterSet*)wmf_invertedWhitespaceCharSet {
    static NSCharacterSet* invertedWhitespaceCharSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        invertedWhitespaceCharSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    });
    return invertedWhitespaceCharSet;
}

@end
