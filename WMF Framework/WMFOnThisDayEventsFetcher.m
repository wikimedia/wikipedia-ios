#import "WMFOnThisDayEventsFetcher.h"
#import "WMFFeedOnThisDayEvent.h"
#import <WMF/WMF-Swift.h>
#import <WMF/WMFLegacySerializer.h>

@implementation WMFOnThisDayEventsFetcher

+ (NSSet<NSString *> *)supportedLanguages {
    static dispatch_once_t onceToken;
    static NSSet<NSString *> *supportedLanguages;
    dispatch_once(&onceToken, ^{
        supportedLanguages = [NSSet setWithObjects:@"en", @"de", @"sv", @"fr", @"es", @"ru", @"pt", @"ar", @"uk", @"tr", nil];
    });
    return supportedLanguages;
}

+ (BOOL)isOnThisDaySupportedByLanguage:(NSString *)languageCode {
    return [[WMFOnThisDayEventsFetcher supportedLanguages] containsObject:languageCode];
}

- (void)fetchOnThisDayEventsForURL:(NSURL *)siteURL month:(NSUInteger)month day:(NSUInteger)day failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFFeedOnThisDayEvent *> *announcements))success {
    NSParameterAssert(siteURL);
    if (siteURL == nil || siteURL.wmf_languageCode == nil || ![WMFOnThisDayEventsFetcher isOnThisDaySupportedByLanguage:siteURL.wmf_languageCode] || month < 1 || day < 1) {
        NSError *error = [WMFFetcher invalidParametersError];
        failure(error);
        return;
    }

    NSString *monthString = [NSString stringWithFormat:@"%lu", (unsigned long)month];
    NSString *dayString = [NSString stringWithFormat:@"%lu", (unsigned long)day];
    NSArray<NSString *> *path = @[@"feed", @"onthisday", @"events", monthString, dayString];
    NSURL *url = [self.configuration feedContentAPIURLForURL:siteURL appendingPathComponents:path];
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
        NSArray *events = [WMFLegacySerializer modelsOfClass:[WMFFeedOnThisDayEvent class] fromArrayForKeyPath:@"events" inJSONDictionary:result languageVariantCode: url.wmf_languageVariantCode error:&serializerError];
        if (serializerError) {
            failure(serializerError);
            return;
        }
        
        success(events);
    }];
}

@end
