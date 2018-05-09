@import Foundation;
@import CoreLocation;
@import Mantle;

@interface MWKSearchResult : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign, readonly) NSInteger articleID;

@property (nonatomic, assign, readonly) NSInteger revID;

@property (nullable, nonatomic, copy, readonly) NSString *displayTitle;

@property (nullable, nonatomic, copy, readonly) NSString *displayTitleHTML;

@property (nullable, nonatomic, copy, readonly) NSString *title;

@property (nullable, nonatomic, copy, readonly) NSString *wikidataDescription;

@property (nullable, nonatomic, copy, readonly) NSString *extract;

@property (nullable, nonatomic, copy, readonly) NSURL *thumbnailURL;

@property (nullable, nonatomic, copy, readonly) NSNumber *index;

@property (nullable, nonatomic, copy, readonly) NSNumber *titleNamespace;

@property (nullable, nonatomic, copy) NSArray<NSNumber *> *viewCounts;

@property (nonatomic, assign, readonly) BOOL isDisambiguation;

@property (nonatomic, assign, readonly) BOOL isList;

- (nullable NSURL *)articleURLForSiteURL:(nullable NSURL *)siteURL;

/**
 *  Location serialized from the first set of coordinates in the response.
 */
@property (nullable, nonatomic, copy, readonly) CLLocation *location;

@property (nullable, nonatomic, copy) NSNumber *geoDimension;
@property (nullable, nonatomic, copy) NSNumber *geoType;

- (nullable instancetype)initWithArticleID:(NSInteger)articleID
                                     revID:(NSInteger)revID
                                     title:(nullable NSString *)title
                              displayTitle:(nullable NSString *)displayTitle
                          displayTitleHTML:(nullable NSString *)displayTitleHTML
                       wikidataDescription:(nullable NSString *)wikidataDescription
                                   extract:(nullable NSString *)extract
                              thumbnailURL:(nullable NSURL *)thumbnailURL
                                     index:(nullable NSNumber *)index
                          isDisambiguation:(BOOL)isDisambiguation
                                    isList:(BOOL)isList
                            titleNamespace:(nullable NSNumber *)titleNamespace;

@end
