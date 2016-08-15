#import <Mantle/Mantle.h>

@interface WMFMostReadTitlesResponseItemArticle : MTLModel
    <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSString* titleText;
@property (nonatomic, assign, readonly) NSUInteger rank;
@property (nonatomic, assign, readonly) NSUInteger views;

@end

@interface WMFMostReadTitlesResponseItem : MTLModel
    <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSDate* date;
@property (nonatomic, strong, readonly) NSArray<WMFMostReadTitlesResponseItemArticle*>* articles;
@property (nonatomic, strong, readonly) NSURL* siteURL;

@end

@interface WMFMostReadTitlesResponse : MTLModel
    <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSArray<WMFMostReadTitlesResponseItem*>* items;

@end
