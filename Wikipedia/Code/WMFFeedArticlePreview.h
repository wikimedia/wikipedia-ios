#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedArticlePreview : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *displayTitle;

@property (nonatomic, copy, readwrite) NSString *wikidataDescription;

@property (nonatomic, copy, readwrite) NSString *snippet;

@property (nonatomic, copy, readwrite) NSString *language;

@property (nonatomic, copy, readwrite) NSURL *thumbnailURL;


- (NSURL*)articleURL;

@end



@interface WMFFeedTopReadArticlePreview : WMFFeedArticlePreview

@property (nonatomic, copy, readwrite) NSNumber *numberOfViews;

@property (nonatomic, copy, readwrite) NSNumber *rank;

@end

NS_ASSUME_NONNULL_END
