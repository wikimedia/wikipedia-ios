
@interface MWKUser ()

@property (readwrite, assign, nonatomic) BOOL anonymous;
@property (readwrite, copy, nonatomic) NSString *name;
@property (readwrite, copy, nonatomic) NSString *gender;

@end

@implementation MWKUser

- (instancetype)initWithSiteURL:(NSURL *)siteURL data:(id)data {
    self = [super initWithURL:siteURL];
    if ([data isKindOfClass:[NSNull class]]) {
        self.anonymous = YES;
        self.name = nil;
        self.gender = nil;
    } else if ([data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)data;
        self.anonymous = NO;
        self.name = [self requiredString:@"name" dict:dict];
        self.gender = [self requiredString:@"gender" dict:dict];
    } else {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"expected null or user info dict, got something else"
                                     userInfo:@{ @"data": data }];
    }
    return self;
}

- (id)dataExport {
    if (self.anonymous) {
        return nil; // don't save!
    } else {
        return @{ @"name": self.name,
                  @"gender": self.gender };
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dataExport]];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKUser class]]) {
        return [self isEqualToUser:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToUser:(MWKUser *)other {
    return self.anonymous == other.anonymous || (WMF_EQUAL(self.name, isEqualToString:, other.name) && WMF_EQUAL(self.gender, isEqualToString:, other.gender));
}

@end
