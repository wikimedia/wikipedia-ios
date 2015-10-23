
#import <Mantle/Mantle.h>

@interface MWKSearchResult : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign, readonly) NSInteger articleID;

@property (nonatomic, copy, readonly) NSString* displayTitle;

@property (nonatomic, copy, readonly) NSString* wikidataDescription;

@property (nonatomic, copy, readonly) NSString* extract;

@property (nonatomic, copy, readonly) NSURL* thumbnailURL;

@end
