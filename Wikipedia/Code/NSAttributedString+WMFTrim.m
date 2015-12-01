//  Created by Monte Hurd on 8/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSAttributedString+WMFTrim.h"
#import "NSCharacterSet+WMFExtras.h"

@implementation NSAttributedString (WMFTrim)

- (NSAttributedString*)wmf_trim {
    if (self.length == 0) {
        return self;
    }

    NSUInteger lastNonWhitespaceLocation = [self locationOfLastNonWhitespaceCharacter];
    if (lastNonWhitespaceLocation == NSNotFound) {
        return [[NSAttributedString alloc] init];
    }

    NSUInteger firstNonWhitespaceLocation = [self locationOfFirstNonWhitespaceCharacter];
    if (firstNonWhitespaceLocation == NSNotFound) {
        return [[NSAttributedString alloc] init];
    }

    return [self attributedSubstringFromRange:NSMakeRange(firstNonWhitespaceLocation, lastNonWhitespaceLocation - firstNonWhitespaceLocation + 1)];
}

- (NSUInteger)locationOfLastNonWhitespaceCharacter {
    return [self.string rangeOfCharacterFromSet:[NSCharacterSet wmf_invertedWhitespaceCharSet] options:NSBackwardsSearch].location;
}

- (NSUInteger)locationOfFirstNonWhitespaceCharacter {
    return [self.string rangeOfCharacterFromSet:[NSCharacterSet wmf_invertedWhitespaceCharSet] options:0].location;
}

@end
