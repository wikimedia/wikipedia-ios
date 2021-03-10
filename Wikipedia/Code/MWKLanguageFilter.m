#import <WMF/MWKLanguageFilter.h>
#import <WMF/MWKLanguageLink.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/WMF-Swift.h>
#import <WMF/WMFComparison.h>

@interface MWKLanguageFilter ()

@property (nonatomic, strong, readwrite) id<MWKLanguageFilterDataSource> dataSource;
@property (nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredLanguages;
@property (nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredPreferredLanguages;
@property (nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredOtherLanguages;

@end

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
    _dataSource.languageFilterDelegate = nil;
    _dataSource = dataSource;
    _dataSource.languageFilterDelegate = self;
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

- (void)noteLanguagesDidChange {
    [self updateFilteredLanguages];
}

@end
