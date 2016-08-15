#import <Mantle/Mantle.h>

@interface MWKSearchResult : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign, readonly) NSInteger articleID;

@property (nonatomic, assign, readonly) NSInteger revID;

@property (nonatomic, copy, readonly) NSString* displayTitle;

@property (nonatomic, copy, readonly) NSString* wikidataDescription;

@property (nonatomic, copy, readonly) NSString* extract;

@property (nonatomic, copy, readonly) NSURL* thumbnailURL;

@property (nonatomic, copy, readonly) NSNumber* index;

@property (nonatomic, copy, readonly) NSNumber* titleNamespace;

@property (nonatomic, assign, readonly) BOOL isDisambiguation;

@property (nonatomic, assign, readonly) BOOL isList;

- (instancetype)initWithArticleID:(NSInteger)articleID
                            revID:(NSInteger)revID
                     displayTitle:(NSString*)displayTitle
              wikidataDescription:(NSString*)wikidataDescription
                          extract:(NSString*)extract
                     thumbnailURL:(NSURL*)thumbnailURL
                            index:(NSNumber*)index
                 isDisambiguation:(BOOL)isDisambiguation
                           isList:(BOOL)isList
                   titleNamespace:(NSNumber*)titleNamespace;

@end
