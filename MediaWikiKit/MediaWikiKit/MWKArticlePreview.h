
#import <Mantle/Mantle.h>

@interface MWKArticlePreview : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign, readonly) NSInteger articleID;

@property (nonatomic, copy, readonly) NSString* displayTitle;

@property (nonatomic, copy, readonly) NSString* wikidataDescription;
@property (nonatomic, copy, readonly) NSString* htmlSummary;

//An array of MWKSectionMetaData objects
@property (nonatomic, strong, readonly) NSArray* sections;

@property (nonatomic, strong, readonly) NSDate* lastModified;
@property (nonatomic, copy, readonly) NSString* lastModifiedBy;

@property (nonatomic, assign, readonly) BOOL editiable;
@property (nonatomic, assign, readonly) NSInteger numberOfLanguages;

@end
