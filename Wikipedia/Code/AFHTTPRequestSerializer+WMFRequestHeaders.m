#import <WMF/AFHTTPRequestSerializer+WMFRequestHeaders.h>
#import <WMF/SessionSingleton.h>
#import <WMF/WikipediaAppUtils.h>
#import <WMF/WMF-Swift.h>

@implementation AFHTTPRequestSerializer (WMFRequestHeaders)

- (void)wmf_applyAppRequestHeaders {
    [self setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [self setValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        [self setValue:[[NSUserDefaults wmf_userDefaults] wmf_appInstallID] forHTTPHeaderField:@"X-WMF-UUID"];
    }
    [self setValue:[NSLocale wmf_acceptLanguageHeaderForPreferredLanguages] forHTTPHeaderField:@"Accept-Language"];
}

@end
