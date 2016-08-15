#import "MWKLanguageFilter.h"
#import "MWKLanguageLinkController.h"
#import "MWKLanguageLink.h"
#import "NSString+WMFExtras.h"
#import <KVOController/FBKVOController.h>

@interface MWKLanguageFilter ()

@property(nonatomic, strong, readwrite) id<MWKLanguageFilterDataSource> dataSource;
@property(nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredLanguages;
@property(nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredPreferredLanguages;
@property(nonatomic, copy, readwrite) NSArray<MWKLanguageLink *> *filteredOtherLanguages;

@end

@implementation MWKLanguageFilter

- (instancetype)initWithLanguageDataSource:(id<MWKLanguageFilterDataSource>)dataSource {
    self = [super init];
    if (self) {
        self.dataSource = dataSource;
        [self.KVOController observe:dataSource
                            keyPath:WMF_SAFE_KEYPATH(dataSource, allLanguages)
                            options:0
                              block:^(MWKLanguageFilter *observer, id object, NSDictionary *change) {
                                [observer updateFilteredLanguages];
                              }];
        [self updateFilteredLanguages];
    }
    return self;
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
        self.filteredLanguages = [self.dataSource.allLanguages bk_select:^BOOL(MWKLanguageLink *langLink) {
          return [langLink.name wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.localizedName wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.languageCode wmf_caseInsensitiveContainsString:self.languageFilter];
        }];
        self.filteredPreferredLanguages = [self.dataSource.preferredLanguages bk_select:^BOOL(MWKLanguageLink *langLink) {
          return [langLink.name wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.localizedName wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.languageCode wmf_caseInsensitiveContainsString:self.languageFilter];
        }];
        self.filteredOtherLanguages = [self.dataSource.otherLanguages bk_select:^BOOL(MWKLanguageLink *langLink) {
          return [langLink.name wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.localizedName wmf_caseInsensitiveContainsString:self.languageFilter] || [langLink.languageCode wmf_caseInsensitiveContainsString:self.languageFilter];
        }];
    }
}

@end
