#import "NSURLComponents+WMFURLParsing.h"
#import "NSString+WMFPageUtilities.h"

@interface NSURLComponents (WMFURLParsing_Private)

@property (nonatomic, readonly) NSInteger wmf_domainIndex;

@end



@implementation NSURLComponents (WMFURLParsing_Private)

+ (NSRegularExpression*)WMFURLParsingDomainIndexRegularExpression {
    static NSRegularExpression* WMFURLParsingDomainIndexRegularExpression = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError* regexError = nil;
        WMFURLParsingDomainIndexRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"^[^.]*(.m){0,1}[.]" options:NSRegularExpressionCaseInsensitive error:&regexError];
        if (regexError) {
            DDLogError(@"Error creating domain parsing regex: %@", regexError);
        }
    });
    return WMFURLParsingDomainIndexRegularExpression;
}

- (NSInteger)wmf_domainIndex {
    if (self.host == nil) {
        return 0;
    }

    NSTextCheckingResult* regexResult = [[NSURLComponents WMFURLParsingDomainIndexRegularExpression] firstMatchInString:self.host options:NSMatchingAnchored range:NSMakeRange(0, self.host.length)];

    NSInteger index = 0;

    if (regexResult != nil) {
        index = regexResult.range.location + regexResult.range.length;
    }

    return index;
}

@end

@implementation NSURLComponents (WMFURLParsing)

- (NSString*)wmf_domain {
    return [self.host substringFromIndex:self.wmf_domainIndex];
}

- (NSString*)wmf_language {
    NSRange dotRange = [self.host rangeOfString:@"."];
    if (dotRange.length == 1) {
        return [self.host substringToIndex:dotRange.location];
    } else {
        return nil;
    }
}

- (NSString*)wmf_title {
    NSString* title = [[self.path wmf_internalLinkPath] wmf_unescapedNormalizedPageTitle];
    if (title == nil) {
        title = @"";
    }
    return title;
}

@end
