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

- (void)updateFilteredLanguages {
    if ([self.languageFilter length] == 0) {
        self.filteredLanguages = self.dataSource.allLanguages;
        self.filteredPreferredLanguages = self.dataSource.preferredLanguages;
        self.filteredOtherLanguages = self.dataSource.otherLanguages;
    } else {
        self.filteredLanguages = [self.dataSource.allLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
            return [langLink.name wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.localizedName wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.languageCode wmf_caseInsensitiveContainsString:self.languageFilter];
        }];
        self.filteredPreferredLanguages = [self.dataSource.preferredLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
            return [langLink.name wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.localizedName wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.languageCode wmf_caseInsensitiveContainsString:self.languageFilter];
        }];
        self.filteredOtherLanguages = [self.dataSource.otherLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
            return [langLink.name wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.localizedName wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.languageCode wmf_caseInsensitiveContainsString:self.languageFilter];
        }];
    }
}

- (void)dataSourceLanguagesDidChange:(NSNotification *)note {
    [self updateFilteredLanguages];
}

@end
