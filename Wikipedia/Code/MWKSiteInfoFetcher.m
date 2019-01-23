#import <WMF/MWKSiteInfoFetcher.h>
#import <WMF/AFHTTPSessionManager+WMFConfig.h>
#import <WMF/WMFNetworkUtilities.h>
#import <WMF/WMFApiJsonResponseSerializer.h>
#import <WMF/MWKSiteInfo.h>
#import <WMF/WMF-Swift.h>

@implementation MWKSiteInfoFetcher

- (void)fetchSiteInfoForSiteURL:(NSURL *)siteURL completion:(void (^)(MWKSiteInfo *data))completion failure:(void (^)(NSError *error))failure {
    NSDictionary *params = @{
        @"action": @"query",
        @"meta": @"siteinfo",
        @"format": @"json",
        @"siprop": @"general"
    };
    [self performMediaWikiAPIGETForURL:siteURL
                   withQueryParameters:params
                     completionHandler:^(NSDictionary<NSString *, id> *_Nullable result, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
                         if (error) {
                             failure(error);
                             return;
                         }
                         NSDictionary *generalProps = [result valueForKeyPath:@"query.general"];
                         NSDictionary *readingListsConfig = generalProps[@"readinglists-config"];
                         MWKSiteInfo *info = [[MWKSiteInfo alloc] initWithSiteURL:siteURL mainPageTitleText:generalProps[@"mainpage"] readingListsConfigMaxEntriesPerList:readingListsConfig[@"maxEntriesPerList"] readingListsConfigMaxListsPerUser:readingListsConfig[@"maxListsPerUser"]];
                         completion(info);
                     }];
}

@end
