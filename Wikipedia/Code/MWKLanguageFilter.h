#import <Foundation/Foundation.h>

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
 * Returns all languages of the languageController. If the data source preferred languages contains one or more
 * language variants, the variants for those languages will appear first in the array.
 *
 * Note that this property is currently only used in the 'Add Langugages' configuration of WMFLanguagesViewController.
 * That view controller requires this particular sorting scheme.
 *
 * If additional clients in the future require a different sorting scheme, a per-instance configuration property
 * that specifies a sorting style would probably be the best approach.
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
