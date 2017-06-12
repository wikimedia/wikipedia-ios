#import <WMF/MWKDataObject.h>

@class MWKUser;

@interface MWKSiteDataObject : MWKDataObject

@property (readonly, strong, nonatomic) NSURL *url;

- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (NSURL *)optionalURL:(NSString *)key dict:(NSDictionary *)dict;
- (NSURL *)requiredURL:(NSString *)key dict:(NSDictionary *)dict;
- (NSURL *)requiredURL:(NSString *)key dict:(NSDictionary *)dict allowEmpty:(BOOL)allowEmpty;

- (MWKUser *)optionalUser:(NSString *)key dict:(NSDictionary *)dict;
- (MWKUser *)requiredUser:(NSString *)key dict:(NSDictionary *)dict;

@end
