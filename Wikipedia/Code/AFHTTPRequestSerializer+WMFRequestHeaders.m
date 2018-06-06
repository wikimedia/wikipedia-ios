#import <WMF/AFHTTPRequestSerializer+WMFRequestHeaders.h>
#import <WMF/WikipediaAppUtils.h>
#import <WMF/WMF-Swift.h>

@implementation AFHTTPRequestSerializer (WMFRequestHeaders)

- (void)wmf_applyAppRequestHeaders {
    [self setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [self setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    WMFEventLoggingService *eventLoggingService = [WMFEventLoggingService sharedInstance];
    if (eventLoggingService.isEnabled) {
        NSString *appInstallID = [eventLoggingService appInstallID];
        assert(appInstallID);
        [self setValue:appInstallID forHTTPHeaderField:@"X-WMF-UUID"];
    }
    [self setValue:[NSLocale wmf_acceptLanguageHeaderForPreferredLanguages] forHTTPHeaderField:@"Accept-Language"];
}

@end
