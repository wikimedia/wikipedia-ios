
#import <Mantle/Mantle.h>

@interface WMFArticlePreview : MTLModel

@property (nonatomic, copy, readwrite) NSURL *url;

@property (nonatomic, copy, readwrite) NSString *displayTitle;

@property (nonatomic, copy, readwrite) NSString *wikidataDescription;

@property (nonatomic, copy, readwrite) NSString *snippet;

@property (nonatomic, copy, readwrite) NSURL *thumbnailURL;

@property (nonatomic, strong, readwrite) CLLocation *location;

@end
