#import <WMF/MWKSavedPageEntry+ImageMigration.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/NSMutableDictionary+WMFMaybeSet.h>
#import <WMF/WMFComparison.h>

typedef NS_ENUM(NSUInteger, MWKSavedPageEntrySchemaVersion) {
    MWKSavedPageEntrySchemaVersionUnknown = 0,
    MWKSavedPageEntrySchemaVersion1 = 1,
    MWKSavedPageEntrySchemaVersion2 = 2,
    MWKSavedPageEntrySchemaVersionCurrent = MWKSavedPageEntrySchemaVersion2
};

static NSString *const MWKSavedPageEntrySchemaVersionKey = @"schemaVerison";

static NSString *const MWKSavedPageEntryDidMigrateImageDataKey = @"didMigrateImageData";

@interface MWKSavedPageEntry ()

@property (readwrite, strong, nonatomic) NSDate *date;

@property (nonatomic, readwrite) BOOL didMigrateImageData;

@end

@implementation MWKSavedPageEntry

- (instancetype)initWithURL:(NSURL *)url {
    url = [NSURL wmf_desktopURLForURL:url];
    NSParameterAssert(url.wmf_title);
    self = [super initWithURL:url];
    if (self) {
        self.date = [NSDate date];
        // defaults to true for instances since new image data will go to the correct location
        self.didMigrateImageData = YES;
    }
    return self;
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
        NSNumber *schemaVersion = dict[MWKSavedPageEntrySchemaVersionKey];

        if (schemaVersion.unsignedIntegerValue > MWKSavedPageEntrySchemaVersion1) {
            self.date = [self requiredDate:@"date" dict:dict];
        } else {
            self.date = [NSDate date];
        }

        if (schemaVersion.unsignedIntegerValue >= MWKSavedPageEntrySchemaVersion1) {
            self.didMigrateImageData =
                [[self requiredNumber:MWKSavedPageEntryDidMigrateImageDataKey dict:dict] boolValue];
        } else {
            // entries reading legacy data have not been migrated
            self.didMigrateImageData = NO;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKSavedPageEntry class]]) {
        return [self isEqualToEntry:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToEntry:(MWKSavedPageEntry *)rhs {
    return WMF_RHS_PROP_EQUAL(url, isEqual:);
}

- (NSUInteger)hash {
    return self.url.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@, didMigrateImageData: %d",
                                      [super description], self.url, self.didMigrateImageData];
}

#pragma mark - MWKListObject

- (id<NSCopying>)listIndex {
    return self.url;
}

- (id)dataExport {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    [dict wmf_maybeSetObject:@(MWKSavedPageEntrySchemaVersionCurrent) forKey:MWKSavedPageEntrySchemaVersionKey];
    [dict wmf_maybeSetObject:@(self.didMigrateImageData) forKey:MWKSavedPageEntryDidMigrateImageDataKey];
    [dict wmf_maybeSetObject:[self.url absoluteString] forKey:@"url"];
    [dict wmf_maybeSetObject:[self iso8601DateString:self.date] forKey:@"date"];
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
