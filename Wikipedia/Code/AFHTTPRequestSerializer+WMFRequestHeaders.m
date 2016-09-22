#import "AFHTTPRequestSerializer+WMFRequestHeaders.h"
#import "SessionSingleton.h"
#import "ReadingActionFunnel.h"
#import "WikipediaAppUtils.h"
#import "NSString+WMFExtras.h"

@implementation AFHTTPRequestSerializer (WMFRequestHeaders)


+ (NSString *)wmf_acceptLanguageHeader {
    static NSString *acceptLanguageHeader = nil;
    static dispatch_once_t onceToken;
    //we can assume at this point that the app will be re-launched when [NSLocale preferredLanguages] changes, so this only needs to be done once
    dispatch_once(&onceToken, ^{
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        NSUInteger count = [preferredLanguages count];
        CGFloat q = 1.0;
        CGFloat qDelta = q/count;
        NSMutableString *acceptLanguageString = [NSMutableString stringWithString:@""];
        for (NSString *preferredLanguage in preferredLanguages) {
            NSMutableArray *components = [[preferredLanguage componentsSeparatedByString:@"-"] mutableCopy];
            if ([components count] > 1) {
                [components removeLastObject];
            }
            NSString *languageCode = [[components componentsJoinedByString:@"-"] lowercaseString];
            if (!languageCode) {
                continue;
            }
            if (q < 1.0) {
                [acceptLanguageString appendString:@", "];
            }
            [acceptLanguageString appendString:languageCode];
            if (q < 1.0) {
                NSString *qString = [NSString stringWithFormat:@";q=%g", q];
                [acceptLanguageString appendString:qString];
            }
            q -= qDelta;
        }
        acceptLanguageHeader = [acceptLanguageString copy];
    });
    
    return acceptLanguageHeader;
}

- (void)wmf_applyAppRequestHeaders {
    [self setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [self setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // Add the app install ID to the header, but only if the user has not opted out of logging
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        ReadingActionFunnel *funnel = [[ReadingActionFunnel alloc] init];
        [self setValue:funnel.appInstallID forHTTPHeaderField:@"X-WMF-UUID"];
    }
    
    [self setValue:[AFHTTPRequestSerializer wmf_acceptLanguageHeader]  forHTTPHeaderField:@"Accept-Language"];
}

@end
