#import "NSCharacterSet+WMFExtras.h"

@implementation NSCharacterSet (WMFExtras)

+ (NSCharacterSet *)wmf_invertedWhitespaceCharSet {
    static NSCharacterSet *invertedWhitespaceCharSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        invertedWhitespaceCharSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    });
    return invertedWhitespaceCharSet;
}

@end
