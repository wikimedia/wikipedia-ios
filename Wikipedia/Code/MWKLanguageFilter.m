#import <WMF/MWKLanguageFilter.h>
#import <WMF/MWKLanguageLink.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/WMF-Swift.h>
#import <WMF/WMFComparison.h>

NSString *const MWKLanguageFilterDataSourceLanguagesDidChangeNotification = @"MWKLanguageFilterDataSourceLanguagesDidChangeNotification";

@interface MWKLanguageFilter ()

@property (nonatomic, strong, readwrite) id<MWKLanguageFilterDataSource> dataSource;
@property (nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredLanguages;
@property (nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredPreferredLanguages;
@property (nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredOtherLanguages;

@end

/* Note that multiple MWKLanguageFilter instances can be active at the same time.
 * For instance, when adding a language in settings, the WMFPreferredLanguagesViewController
 * and the language-choosing WMFLanguagesViewController each have an instance of MWKLanguageFilter.
 * Multiple active instances need to be notified of changes in the data source,
 * so a notification is used instead of a delegate.
*/
@implementation MWKLanguageFilter

- (instancetype)initWithLanguageDataSource:(id<MWKLanguageFilterDataSource>)dataSource {
    self = [super init];
    if (self) {
        self.dataSource = dataSource;
        [self updateFilteredLanguages];
    }
    return self;
}

- (void)dealloc {
    self.dataSource = nil;
}

- (void)setDataSource:(id<MWKLanguageFilterDataSource>)dataSource {
    if (_dataSource == dataSource) {
        return;
    }
    if (_dataSource) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKLanguageFilterDataSourceLanguagesDidChangeNotification object:_dataSource];
    }
    _dataSource = dataSource;
    if (_dataSource) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceLanguagesDidChange:) name:MWKLanguageFilterDataSourceLanguagesDidChangeNotification object:_dataSource];
    }
}

- (void)setLanguageFilter:(NSString *__nullable)filterString {
    if (WMF_EQUAL(self.languageFilter, isEqualToString:, filterString)) {
        return;
    }
    _languageFilter = [filterString copy];
    [self updateFilteredLanguages];
}

/* This method will sort the provided array of languages in the following way:
 * If the data source preferred languages contains a language variant,
 * all variants for that language are moved to the beginning of resulting array.
 *
 * If language variants of multiple languages are present in the data source preferred langugages,
 * all variants for each language are moved to the beginning of the resulting array in the same
 * relative order as the variants appear in the original array.
 */
- (NSArray<MWKLanguageLink *> *)languagesSortedWithPreferredLanguageVariantLanguagesFirst:(NSArray<MWKLanguageLink *> *)unsortedLanguages {
    
    NSMutableArray<MWKLanguageLink *> *temporaryLanguages = [unsortedLanguages mutableCopy];

    // Gather all the preferred languages that support variants
    // Maintain the preference order so variants are presented using same order
    NSMutableArray<NSString *> *preferredVariantAwareLanguageCodes = [NSMutableArray array];
    for (MWKLanguageLink *language in self.dataSource.preferredLanguages) {
        if (language.languageVariantCode && ![preferredVariantAwareLanguageCodes containsObject:language.languageCode]) {
            [preferredVariantAwareLanguageCodes addObject:language.languageCode];
        }
    }
    
    // Process language codes in reverse order so the earlier items are placed earlier in the resulting array
    for (NSString *languageCode in preferredVariantAwareLanguageCodes.reverseObjectEnumerator) {
        NSIndexSet *foundIndexes = [temporaryLanguages indexesOfObjectsPassingTest:^BOOL(MWKLanguageLink * _Nonnull language, NSUInteger idx, BOOL * _Nonnull stop) {
            return [language.languageCode isEqualToString: languageCode];
        }];
        NSArray<MWKLanguageLink *> *foundLanguages = [temporaryLanguages objectsAtIndexes:foundIndexes];
        [temporaryLanguages removeObjectsAtIndexes:foundIndexes];
        [temporaryLanguages insertObjects:foundLanguages atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, foundLanguages.count)]];
    }
    
    return [temporaryLanguages copy];
}

- (void)updateFilteredLanguages {
    NSArray<MWKLanguageLink *> *unsortedFilteredLanguages = nil;
    if ([self.languageFilter length] == 0) {
        unsortedFilteredLanguages = self.dataSource.allLanguages;
        self.filteredPreferredLanguages = self.dataSource.preferredLanguages;
        self.filteredOtherLanguages = self.dataSource.otherLanguages;
    } else {
        unsortedFilteredLanguages = [self.dataSource.allLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
            return [self langLinkMatchesFilter:langLink];
        }];
        self.filteredPreferredLanguages = [self.dataSource.preferredLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
            return [self langLinkMatchesFilter:langLink];
        }];
        self.filteredOtherLanguages = [self.dataSource.otherLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
            return [self langLinkMatchesFilter:langLink];
        }];
    }
        
    self.filteredLanguages = [self languagesSortedWithPreferredLanguageVariantLanguagesFirst:unsortedFilteredLanguages];
}

- (BOOL)langLinkMatchesFilter:(MWKLanguageLink *) langLink {
    return [langLink.name wmf_caseInsensitiveContainsString:self.languageFilter] ||
        [langLink.localizedName wmf_caseInsensitiveContainsString:self.languageFilter] ||
        [langLink.languageCode wmf_caseInsensitiveContainsString:self.languageFilter] ||
        // Farsi/Perisan hack: To fix https://phabricator.wikimedia.org/T107530, explicitly checking for Farsi in search box.
        ([@"Farsi" wmf_caseInsensitiveContainsString:self.languageFilter] && [langLink.languageCode wmf_isEqualToStringIgnoringCase:@"fa"]);
}

- (void)dataSourceLanguagesDidChange:(NSNotification *)note {
    [self updateFilteredLanguages];
}

@end
