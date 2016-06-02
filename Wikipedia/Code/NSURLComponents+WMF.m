#import "NSURLComponents+WMF.h"

@interface NSURLComponents (WMF_Private)

@property (nonatomic, readonly) NSInteger WMFDomainIndex;

@end

@implementation NSURLComponents (WMF_Private)

- (NSInteger)WMFDomainIndex {
    NSError* regexError                   = nil;
    NSRegularExpression* domainIndexRegex = [NSRegularExpression regularExpressionWithPattern:@"^[^.]*(.m){0,1}[.]" options:NSRegularExpressionCaseInsensitive error:&regexError];
    if (regexError) {
        DDLogError(@"Error creating domain parsing regex: %@", regexError);
    }

    if (self.host == nil) {
        return 0;
    }

    NSTextCheckingResult* regexResult = [domainIndexRegex firstMatchInString:self.host options:NSMatchingAnchored range:NSMakeRange(0, self.host.length)];

    NSInteger index = 0;

    if (regexResult != nil) {
        index = regexResult.range.location + regexResult.range.length;
    }

    return index;
}

@end

@implementation NSURLComponents (WMF)

- (NSString*)WMFDomain {
    return [self.host substringFromIndex:self.WMFDomainIndex];
}

- (NSString*)WMFLanguage {
    NSRange dotRange = [self.host rangeOfString:@"."];
    if (dotRange.length == 1) {
        return [self.host substringToIndex:dotRange.location];
    } else {
        return nil;
    }
}

@end
