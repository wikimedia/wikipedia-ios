
#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"


@interface WMFAnnouncementsFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFAnnouncementsFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createDefaultManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForArrayOf:[WMFAnnouncement class] fromKeypath:@"announce"];
        self.operationManager = manager;
        [self set304sEnabled:NO];
    }
    return self;
}

- (void)set304sEnabled:(BOOL)enabled{
    NSMutableIndexSet* set = [self.operationManager.responseSerializer.acceptableStatusCodes mutableCopy];
    if(enabled){
        [set addIndex:304];
    }else{
        [set removeIndex:304];
    }
    self.operationManager.responseSerializer.acceptableStatusCodes = set;
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchAnnouncementsForURL:(NSURL *)siteURL force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFAnnouncement *> *announcements))success{
    NSParameterAssert(siteURL);
    if (siteURL == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        failure(error);
        return;
    }
    
    [self set304sEnabled:force];

    NSURL *url = [siteURL wmf_URLWithPath:@"/api/rest_v1/feed/announcements" isMobile:NO];

    [self.operationManager GET:[url absoluteString]
                    parameters:nil
                      progress:NULL
                       success:^(NSURLSessionDataTask *operation, NSArray<WMFAnnouncement *> *responseObject) {
                           
                           if (![responseObject[0] isKindOfClass:[WMFAnnouncement class]]) {
                               failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                                         userInfo:nil]);
                               
                           } else {
                               NSString* setCookieHeader = [(NSHTTPURLResponse*)operation.response allHeaderFields][@"Set-Cookie"];
                               success([self filterAnnouncementsForiOSPlatform: [self filterAnnouncements:responseObject withCurrentCountryInIPHeader:setCookieHeader]]);
                           }
                       }
                       failure:^(NSURLSessionDataTask *operation, NSError *error) {
                           failure(error);
                       }];
}

- (NSArray<WMFAnnouncement *> *)filterAnnouncements:(NSArray<WMFAnnouncement *> *)announcements withCurrentCountryInIPHeader:(NSString*)header {
    
    NSArray<WMFAnnouncement *> *validAnnouncements = [announcements bk_select:^BOOL(WMFAnnouncement* obj) {
        __block BOOL valid = NO;
        [[obj countries] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([header containsString:[NSString stringWithFormat:@"GeoIP=%@", obj]]){
                valid = YES;
                *stop = YES;
            }
        }];
        return valid;
    }];
    return validAnnouncements;
}

- (NSArray<WMFAnnouncement *> *)filterAnnouncementsForiOSPlatform:(NSArray<WMFAnnouncement *> *)announcements{
    
    NSArray<WMFAnnouncement *> *validAnnouncements = [announcements bk_select:^BOOL(WMFAnnouncement* obj) {
        if([obj.platforms containsObject:@"iOSApp"]){
            return YES;
        }else{
            return NO;
        }
    }];
    return validAnnouncements;
}


@end
