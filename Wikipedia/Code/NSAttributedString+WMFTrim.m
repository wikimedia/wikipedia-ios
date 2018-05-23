#import <WMF/NSAttributedString+WMFTrim.h>
#import <WMF/NSCharacterSet+WMFExtras.h>

@implementation NSAttributedString (WMFTrim)

- (NSAttributedString *)wmf_trim {
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
