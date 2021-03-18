@import Foundation;

@class MWKLanguageLink;

NS_ASSUME_NONNULL_BEGIN

// Notification sent by an MWKLanguageFilterDataSource when language array values change
extern NSString *const MWKLanguageFilterDataSourceLanguagesDidChangeNotification;

@protocol MWKLanguageFilterDataSource <NSObject>

@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *allLanguages;
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *preferredLanguages;
@property (readonly, copy, nonatomic) NSArray<MWKLanguageLink *> *otherLanguages;

@end

@interface MWKLanguageFilter : NSObject

- (instancetype)initWithLanguageDataSource:(id<MWKLanguageFilterDataSource>)dataSource;

@property (nonatomic, strong, readonly) id<MWKLanguageFilterDataSource> dataSource;

/**
 * String used to filter languages by their @c languageCode or @c languageName.
 *
 * Setting this property to @c nil will disable filtering.
 *
 * @return The string to filter by, or @c nil if disabled.
 */
@property (copy, nullable, nonatomic) NSString *languageFilter;

/**
 * Returns all languages of the languageController, with preferred languages listed first.
 *
 * The languages returned by this property will be filtered if @c languageFilter is non-nil.
 */
@property (nonatomic, copy, readonly) NSArray<MWKLanguageLink *> *filteredLanguages;

/**
 * The user's preferred languages.
 *
 * The languages returned by this property will be filtered if @c languageFilter is non-nil.
 */
@property (nonatomic, copy, readonly) NSArray<MWKLanguageLink *> *filteredPreferredLanguages;

/**
 * All the languages in the languageController minus @c filteredPreferredLanguages.
 *
 * The languages returned by this property will be filtered if @c languageFilter is non-nil.
 */
@property (nonatomic, copy, readonly) NSArray<MWKLanguageLink *> *filteredOtherLanguages;

@end

NS_ASSUME_NONNULL_END
