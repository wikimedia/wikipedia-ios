#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"
#import <WMF/WMF-Swift.h>

@interface WMFAnnouncementsFetcher ()

@property (nonatomic, strong) AFHTTPSessionManager *operationManager;

@end

@implementation WMFAnnouncementsFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager wmf_createIgnoreCacheManager];
        manager.responseSerializer = [WMFMantleJSONResponseSerializer serializerForArrayOf:[WMFAnnouncement class] fromKeypath:@"announce"];
        NSMutableIndexSet *set = [manager.responseSerializer.acceptableStatusCodes mutableCopy];
        [set removeIndex:304];
        manager.responseSerializer.acceptableStatusCodes = set;
        self.operationManager = manager;
    }
    return self;
}

- (void)dealloc {
    [self.operationManager invalidateSessionCancelingTasks:YES];
}

- (BOOL)isFetching {
    return [[self.operationManager operationQueue] operationCount] > 0;
}

- (void)fetchAnnouncementsForURL:(NSURL *)siteURL force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFAnnouncement *> *announcements))success {
    NSParameterAssert(siteURL);
    if (siteURL == nil) {
        NSError *error = [NSError wmf_errorWithType:WMFErrorTypeInvalidRequestParameters
                                           userInfo:nil];
        failure(error);
        return;
    }

    NSURL *url = [siteURL wmf_URLWithPath:@"/api/rest_v1/feed/announcements" isMobile:NO];

    [self.operationManager GET:[url absoluteString]
        parameters:nil
        progress:NULL
        success:^(NSURLSessionDataTask *operation, NSArray<WMFAnnouncement *> *responseObject) {
            if (![responseObject isKindOfClass:[NSArray class]]) {
                failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                          userInfo:nil]);
                return;
            }

            WMFAnnouncement *announcement = responseObject.firstObject;
            if (![announcement isKindOfClass:[WMFAnnouncement class]]) {
                failure([NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                          userInfo:nil]);
                return;
            }

            NSString *geoIPCookie = [self geoIPCookieString];
            NSString *setCookieHeader = [(NSHTTPURLResponse *)operation.response allHeaderFields][@"Set-Cookie"];
            success([self filterAnnouncementsForiOSPlatform:[self filterAnnouncements:responseObject withCurrentCountryInIPHeader:setCookieHeader geoIPCookieValue:geoIPCookie]]);
        }
        failure:^(NSURLSessionDataTask *operation, NSError *error) {
            failure(error);
        }];
}

- (NSArray<WMFAnnouncement *> *)filterAnnouncements:(NSArray<WMFAnnouncement *> *)announcements withCurrentCountryInIPHeader:(NSString *)header geoIPCookieValue:(NSString *)cookieValue {

    NSArray<WMFAnnouncement *> *validAnnouncements = [announcements wmf_select:^BOOL(WMFAnnouncement *obj) {
        if (![obj isKindOfClass:[WMFAnnouncement class]]) {
            return NO;
        }
        __block BOOL valid = NO;
        NSArray *countries = [obj countries];
        if (countries.count == 0) {
            return YES;
        }
        [countries enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([header containsString:[NSString stringWithFormat:@"GeoIP=%@", obj]]) {
                valid = YES;
                *stop = YES;
            }
            if ([header length] < 1 && [cookieValue hasPrefix:obj]) {
                valid = YES;
                *stop = YES;
            }
        }];
        return valid;
    }];
    return validAnnouncements;
}

- (NSArray<WMFAnnouncement *> *)filterAnnouncementsForiOSPlatform:(NSArray<WMFAnnouncement *> *)announcements {

    NSArray<WMFAnnouncement *> *validAnnouncements = [announcements wmf_select:^BOOL(WMFAnnouncement *obj) {
        if (![obj isKindOfClass:[WMFAnnouncement class]]) {
            return NO;
        }
        if ([obj.platforms containsObject:@"iOSApp"]) {
            return YES;
        } else {
            return NO;
        }
    }];
    return validAnnouncements;
}

- (NSString *)geoIPCookieString {
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    NSHTTPCookie *cookie = [cookies wmf_match:^BOOL(NSHTTPCookie *obj) {
        if ([[obj name] containsString:@"GeoIP"]) {
            return YES;
        } else {
            return NO;
        }
    }];

    return [cookie value];
}

@end
