#import <WMF/MWKProtectionStatus.h>

@interface MWKProtectionStatus ()

@property (nonatomic, strong) NSDictionary *protection;

@end

@implementation MWKProtectionStatus

- (instancetype)initWithData:(id)data {
    self = [self init];
    if (self) {
        NSDictionary *wrapper = @{@"protection": data};
        self.protection = [self requiredDictionary:@"protection" dict:wrapper];
    }
    return self;
}

- (NSArray *)protectedActions {
    return [self.protection allKeys];
}

- (NSArray *)allowedGroupsForAction:(NSString *)action {
    return self.protection[action];
}

- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    } else if (![object isKindOfClass:[MWKProtectionStatus class]]) {
        return NO;
    } else {
        MWKProtectionStatus *other = (MWKProtectionStatus *)object;

        NSArray *myActions = [self protectedActions];
        NSArray *otherActions = [other protectedActions];
        if ([myActions count] != [otherActions count]) {
            return NO;
        }
        for (NSString *action in myActions) {
            if (![[self allowedGroupsForAction:action] isEqualToArray:[other allowedGroupsForAction:action]]) {
                return NO;
            }
        }
        return YES;
    }
}

- (id)dataExport {
    return self.protection;
}

- (id)copyWithZone:(NSZone *)zone {
    // immutable
    return self;
}

- (NSString *)description {
    //Do not use MTLModel's description as it will cause recursion since this instance has a reference to the article, which also has a reference to this image
    return [NSString stringWithFormat:@"Protection Status: %@", [self.protection description]];
}

@end
