
#import <Mantle/Mantle.h>

@interface MWKArticlePreview : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger articleID;

@property (nonatomic, copy) NSString* displayTitle;

@property (nonatomic, copy) NSString* wikidataDescription;
@property (nonatomic, copy) NSString* htmlSummary;

//An array of MWKSectionMetaData
@property (nonatomic, strong) NSArray* sections;

@property (nonatomic, strong) NSDate* lastModified;
@property (nonatomic, copy) NSString* lastModifiedBy;

@property (nonatomic, assign) BOOL editiable;
@property (nonatomic, assign) NSInteger numberOfLanguages;

@end
