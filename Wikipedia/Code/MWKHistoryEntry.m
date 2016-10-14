@interface MWKHistoryEntry ()

@end

@implementation MWKHistoryEntry

- (instancetype)initWithURL:(NSURL *)url {
    url = [NSURL wmf_desktopURLForURL:url];
    NSParameterAssert(url.wmf_title);
    self = [super initWithURL:url];
    if (self) {
    }
    return self;
}

+ (NSUInteger)modelVersion {
    return 3;
}

- (instancetype)initWithDict:(NSDictionary *)dict {
    NSString *urlString = dict[@"url"];
    NSString *domain = dict[@"domain"];
    NSString *language = dict[@"language"];
    NSString *title = dict[@"title"];

    NSURL *url;

    if ([urlString length]) {
        url = [NSURL URLWithString:urlString];
    } else if (domain && language && title) {
        url = [NSURL wmf_URLWithDomain:domain language:language title:title fragment:nil];
    } else {
        return nil;
    }

    self = [self initWithURL:url];
    if (self) {
        self.fragment = [self optionalString:@"fragment" dict:dict];
        self.dateViewed = [self requiredDate:@"date" dict:dict];
        self.scrollPosition = [[self requiredNumber:@"scrollPosition" dict:dict] floatValue];
        self.titleWasSignificantlyViewed = [[self optionalNumber:@"titleWasSignificantlyViewed" dict:dict] boolValue];
        self.inTheNewsNotificationDate = [self optionalDate:@"inTheNewsNotificationDate" dict:dict];
    }
    return self;
}

- (BOOL)isInHistory {
    return self.dateViewed != nil;
}

- (BOOL)isSaved {
    return self.dateSaved != nil;
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
    return self.url.hash ^ self.dateViewed.hash ^ [@(self.scrollPosition) integerValue] ^ self.fragment.hash ^ self.inTheNewsNotificationDate.hash;
}

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry *)entry {
    return WMF_IS_EQUAL(self.url, entry.url) && WMF_EQUAL(self.dateViewed, isEqualToDate:, entry.dateViewed) && self.scrollPosition == entry.scrollPosition && ((self.fragment == entry.fragment) || (self.fragment && entry.fragment && [self.fragment isEqualToString:entry.fragment])) && WMF_EQUAL(self.inTheNewsNotificationDate, isEqualToDate:, entry.inTheNewsNotificationDate);
}

#pragma mark - MWKListObject

- (id<NSCopying>)listIndex {
    return self.url;
}

- (id)dataExport {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    [dict wmf_maybeSetObject:[self.url absoluteString] forKey:@"url"];
    [dict wmf_maybeSetObject:[self iso8601DateString:self.dateViewed] forKey:@"date"];
    [dict wmf_maybeSetObject:@(self.scrollPosition) forKey:@"scrollPosition"];
    [dict wmf_maybeSetObject:@(self.titleWasSignificantlyViewed) forKey:@"titleWasSignificantlyViewed"];
    [dict wmf_maybeSetObject:self.fragment forKey:@"fragment"];
    [dict wmf_maybeSetObject:[self iso8601DateString:self.inTheNewsNotificationDate] forKey:@"inTheNewsNotificationDate"];

    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
