#import <WMF/MWKLicense.h>

static NSString *const MWKLicenseCodeKey = @"code";
static NSString *const MWKLicenseShortDescKey = @"shortDescription";
static NSString *const MWKLicenseURLKey = @"URL";

@interface MWKLicense ()

@property (nonatomic, readwrite, copy) NSString *code;
@property (nonatomic, readwrite, copy) NSString *shortDescription;
@property (nonatomic, readwrite, copy) NSURL *URL;

@end

@implementation MWKLicense

- (instancetype)initWithCode:(NSString *)code
            shortDescription:(NSString *)shortDescription
                         URL:(NSURL *)URL {
    self = [super init];
    if (self) {
        self.code = code;
        self.shortDescription = shortDescription;
        self.URL = URL;
    }
    return self;
}

+ (instancetype)licenseWithExportedData:(NSDictionary *)exportedData {
    if (!exportedData) {
        return nil;
    }
    return [[MWKLicense alloc] initWithCode:exportedData[MWKLicenseCodeKey]
                           shortDescription:exportedData[MWKLicenseShortDescKey]
                                        URL:[NSURL URLWithString:exportedData[MWKLicenseURLKey]]];
}

- (id)dataExport {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:self.code forKey:MWKLicenseCodeKey];
    [dict setValue:self.shortDescription forKey:MWKLicenseShortDescKey];
    [dict setValue:self.URL.absoluteString forKey:MWKLicenseURLKey];
    return dict;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKLicense class]]) {
        return [self isEqualToLicense:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToLicense:(MWKLicense *)other {
    return [self.code isEqualToString:other.code];
}

- (NSUInteger)hash {
    return [self.code hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], self.code, self.shortDescription];
}

@end
