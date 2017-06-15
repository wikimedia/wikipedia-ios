@import CoreGraphics;
#import <WMF/MWKSiteDataObject.h>
#import <WMF/MWKList.h>

@interface MWKHistoryEntry : MWKSiteDataObject <MWKListObject>

@property (readwrite, strong, nonatomic) NSDate *dateViewed;
@property (readonly, assign, nonatomic) BOOL isInHistory;

@property (readwrite, strong, nonatomic) NSDate *dateSaved;
@property (readonly, assign, nonatomic) BOOL isSaved;

@property (readwrite, assign, nonatomic) CGFloat scrollPosition;
@property (readwrite, copy, nonatomic) NSString *fragment;

@property (readwrite, assign, nonatomic, getter=isBlackListed) BOOL blackListed;
@property (readwrite, assign, nonatomic) BOOL titleWasSignificantlyViewed;

@property (readwrite, strong, nonatomic) NSDate *inTheNewsNotificationDate;

- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDict:(NSDictionary *)dict;

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry *)entry;

@end
