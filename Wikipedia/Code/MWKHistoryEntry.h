
#import "MWKSiteDataObject.h"
#import "MWKList.h"

@class MWKTitle;

@interface MWKHistoryEntry : MWKSiteDataObject
    <MWKListObject>

@property (readonly, strong, nonatomic) MWKTitle* title;
@property (readwrite, strong, nonatomic) NSDate* date;
@property (readwrite, assign, nonatomic) CGFloat scrollPosition;
@property (readwrite, assign, nonatomic) BOOL titleWasSignificantlyViewed;

- (instancetype)initWithTitle:(MWKTitle*)title;
- (instancetype)initWithDict:(NSDictionary*)dict;

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry;

@end
