#import "WMFAnnouncementsFetcher.h"
#import "WMFAnnouncement.h"
#import <WMF/WMF-Swift.h>
#import <WMF/WMFLegacySerializer.h>

@implementation WMFAnnouncementsFetcher

- (void)fetchAnnouncementsForURL:(NSURL *)siteURL force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFAnnouncement *> *announcements))success {
    NSParameterAssert(siteURL);
    if (siteURL == nil) {
        NSError *error = [WMFFetcher invalidParametersError];
        failure(error);
        return;
    }
    
    NSURL *url = [self.configuration announcementsAPIURLForURL:siteURL appendingPathComponents:@[@"feed", @"announcements"]];
    [self.session getJSONDictionaryFromURL:url ignoreCache:YES completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            failure(error);
            return;
        }
        
        if (response.statusCode == 304) {
            failure([WMFFetcher noNewDataError]);
            return;
        }
        
        NSError *serializerError = nil;
        NSArray *announcements = [WMFLegacySerializer modelsOfClass:[WMFAnnouncement class] fromArrayForKeyPath:@"announce" inJSONDictionary:result languageVariantCode:url.wmf_languageVariantCode error:&serializerError];
        if (serializerError) {
            failure(serializerError);
            return;
        }

        NSString *geoIPCookie = [self geoIPCookieString];
        NSString *setCookieHeader = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            setCookieHeader = [(NSHTTPURLResponse *)response allHeaderFields][@"Set-Cookie"];
        }
        NSArray<WMFAnnouncement *> *announcementsFilteredByCountry = [self filterAnnouncements:announcements withCurrentCountryInIPHeader:setCookieHeader geoIPCookieValue:geoIPCookie];
        NSArray<WMFAnnouncement *> *filteredAnnouncements = [self filterAnnouncementsForiOSPlatform:announcementsFilteredByCountry];
        success(filteredAnnouncements);
    }];
}

- (NSArray<WMFAnnouncement *> *)filterAnnouncements:(NSArray<WMFAnnouncement *> *)announcements withCurrentCountryInIPHeader:(NSString *)header geoIPCookieValue:(NSString *)cookieValue {

    NSArray<WMFAnnouncement *> *validAnnouncements = [announcements wmf_select:^BOOL(WMFAnnouncement *obj) {
        if (![obj isKindOfClass:[WMFAnnouncement class]]) {
            return NO;
        }
        NSArray *countries = [obj countries];
        if (countries.count == 0) {
            return YES;
        }
        __block BOOL valid = NO;
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
        if ([obj.platforms containsObject:@"iOSAppV5"]) {
            return YES;
        } else {
            return NO;
        }
    }];
    return validAnnouncements;
}

- (NSString *)geoIPCookieString {
    NSArray<NSHTTPCookie *> *cookies = [[WMFSession sharedCookieStorage] cookies];;
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
