#import "AFHTTPRequestSerializer+WMFRequestHeaders.h"
#import "SessionSingleton.h"
#import "ReadingActionFunnel.h"
#import "WikipediaAppUtils.h"

@implementation AFHTTPRequestSerializer (WMFRequestHeaders)

- (void)wmf_applyAppRequestHeaders {
    [self setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [self setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    // Add the app install ID to the header, but only if the user has not opted out of logging
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        ReadingActionFunnel *funnel = [[ReadingActionFunnel alloc] init];
        [self setValue:funnel.appInstallID forHTTPHeaderField:@"X-WMF-UUID"];
    }
}

@end
