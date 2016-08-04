
#import "MWKSiteDataObject.h"
#import "MWKList.h"

@interface MWKHistoryEntry : MWKSiteDataObject
    <MWKListObject>

@property (readwrite, strong, nonatomic) NSDate* dateViewed;
@property (readwrite, assign, nonatomic) CGFloat scrollPosition;
@property (readwrite, assign, nonatomic) BOOL titleWasSignificantlyViewed;

- (instancetype)initWithURL:(NSURL*)url NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDict:(NSDictionary*)dict;

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry;

@end
