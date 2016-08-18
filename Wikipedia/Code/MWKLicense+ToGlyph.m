#import "MWKLicense+ToGlyph.h"
#import "WikiGlyph_Chars.h"

@implementation MWKLicense (ToGlyph)

- (NSString *)toGlyph {
    if ([self.code isEqualToString:@"pd"]) {
        return WIKIGLYPH_PUBLIC_DOMAIN;
    } else if ([self.code hasPrefix:@"cc"]) {
        return WIKIGLYPH_CC;
    } else {
        return nil;
    }
}

@end
