
#import "MediaWikiKit.h"
#import "WikipediaAppUtils.h"
#import "NSMutableDictionary+WMFMaybeSet.h"

@interface MWKHistoryEntry ()


@end

@implementation MWKHistoryEntry

- (instancetype)initWithURL:(NSURL*)url {
    NSParameterAssert(url.wmf_title);
    self = [super initWithURL:url];
    if (self) {
        self.dateViewed           = [NSDate date];
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary*)dict {
    NSString* urlString = dict[@"url"];
    NSString* domain    = dict[@"domain"];
    NSString* language  = dict[@"language"];
    NSString* title     = dict[@"title"];

    NSURL* url;

    if ([urlString length]) {
        url = [NSURL URLWithString:urlString];
    } else if (domain && language && title) {
        url = [NSURL wmf_URLWithDomain:domain language:language title:title fragment:nil];
    } else {
        return nil;
    }

    self = [self initWithURL:url];
    if (self) {
        self.dateViewed                        = [self requiredDate:@"date" dict:dict];
        self.scrollPosition              = [[self requiredNumber:@"scrollPosition" dict:dict] floatValue];
        self.titleWasSignificantlyViewed = [[self optionalNumber:@"titleWasSignificantlyViewed" dict:dict] boolValue];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKHistoryEntry class]]) {
        return [self isEqualToHistoryEntry:object];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return self.url.hash ^ self.dateViewed.hash ^ [@(self.scrollPosition)integerValue];
}

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry {
    return WMF_IS_EQUAL(self.url, entry.url)
           && WMF_EQUAL(self.dateViewed, isEqualToDate:, entry.dateViewed)
           && self.scrollPosition == entry.scrollPosition;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@: {\n"
            "\turl: %@,\n"
            "\tdate: %@,\n"
            "\tscrollPosition: %f\n"
            "}",
            [super description],
            self.url.description,
            self.dateViewed,
            self.scrollPosition];
}

#pragma mark - MWKListObject

- (id <NSCopying>)listIndex {
    return self.url;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    [dict wmf_maybeSetObject:[self.url absoluteString] forKey:@"url"];
    [dict wmf_maybeSetObject:[self iso8601DateString:self.dateViewed] forKey:@"date"];
    [dict wmf_maybeSetObject:@(self.scrollPosition) forKey:@"scrollPosition"];
    [dict wmf_maybeSetObject:@(self.titleWasSignificantlyViewed) forKey:@"titleWasSignificantlyViewed"];

    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
