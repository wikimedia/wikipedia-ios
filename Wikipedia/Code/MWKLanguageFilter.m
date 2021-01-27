#import <WMF/MWKLanguageFilter.h>
#import <WMF/MWKLanguageLink.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/WMF-Swift.h>
#import <WMF/WMFComparison.h>

static const NSString *kvo_MWKLanguageFilter_dataSource_allLanguages = nil;

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
    NSString *keyPath = WMF_SAFE_KEYPATH(_dataSource, allLanguages);
    [(id)_dataSource removeObserver:self forKeyPath:keyPath context:&kvo_MWKLanguageFilter_dataSource_allLanguages];
    _dataSource = dataSource;
    [(id)_dataSource addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:&kvo_MWKLanguageFilter_dataSource_allLanguages];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (context == &kvo_MWKLanguageFilter_dataSource_allLanguages) {
        [self updateFilteredLanguages];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
