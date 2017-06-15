#import <WMF/MWKSiteDataObject.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/MWKUser.h>

@interface MWKSiteDataObject ()

@property (readwrite, strong, nonatomic) NSURL *url;

@end

@implementation MWKSiteDataObject

- (instancetype)initWithURL:(NSURL *)url {
    NSParameterAssert(url);
    self = [super init];
    if (self) {
        self.url = url;
    }
    return self;
}

#pragma mark - title methods

- (NSURL *)optionalURL:(NSString *)key dict:(NSDictionary *)dict {
    if ([dict[key] isKindOfClass:[NSNumber class]] && ![dict[key] boolValue]) {
        // false sometimes happens. Thanks PHP and weak typing!
        return nil;
    }
    NSString *str = [self optionalString:key dict:dict];
    if (str == nil || str.length == 0) {
        return nil;
    } else {
        return [self.url wmf_URLWithTitle:str];
    }
}

- (NSURL *)requiredURL:(NSString *)key dict:(NSDictionary *)dict {
    return [self requiredURL:key dict:dict allowEmpty:YES];
}

- (NSURL *)requiredURL:(NSString *)key dict:(NSDictionary *)dict allowEmpty:(BOOL)allowEmpty {
    NSString *str = [self requiredString:key dict:dict allowEmpty:allowEmpty];
    return [self.url wmf_URLWithTitle:str];
}

#pragma mark - user methods

- (MWKUser *)optionalUser:(NSString *)key dict:(NSDictionary *)dict {
    id user = dict[key];
    if (user == nil) {
        return nil;
    } else {
        return [[MWKUser alloc] initWithSiteURL:self.url data:user];
    }
}

- (MWKUser *)requiredUser:(NSString *)key dict:(NSDictionary *)dict {
    MWKUser *user = [self optionalUser:key dict:dict];
    if (user == nil) {
        return [self optionalUser:key dict:@{key: [NSNull null]}];
        /*
           @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"missing required user field"
                                     userInfo:@{@"key": key}];
         */
    } else {
        return user;
    }
}

@end
