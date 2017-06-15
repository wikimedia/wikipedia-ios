#import <WMF/MWKSiteDataObject.h>

@interface MWKUser : MWKSiteDataObject

@property (readonly, assign, nonatomic) BOOL anonymous;
@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, copy, nonatomic) NSString *gender;

- (instancetype)initWithSiteURL:(NSURL *)siteURL data:(id)data;

- (BOOL)isEqualToUser:(MWKUser *)user;

@end
