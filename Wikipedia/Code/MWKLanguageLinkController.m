#import <WMF/MWKLanguageLinkController_Private.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFPreferredLanguagesDidChangeNotification = @"WMFPreferredLanguagesDidChangeNotification";

NSString *const WMFAppLanguageDidChangeNotification = @"WMFAppLanguageDidChangeNotification";

static NSString *const WMFPreviousLanguagesKey = @"WMFPreviousSelectedLanguagesKey";

@interface MWKLanguageLinkController ()

@property (copy, nonatomic) NSArray *preferredLanguages;

@property (copy, nonatomic) NSArray *otherLanguages;

@property (copy, nonatomic) NSArray<MWKLanguageLink *> *allLanguages;

@end

@implementation MWKLanguageLinkController

static id _sharedInstance;

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    assert(_sharedInstance == nil);
    self = [super init];
    if (self) {
        [self loadLanguagesFromFile];
    }
    return self;
}

#pragma mark - Loading

- (void)loadLanguagesFromFile {
    self.allLanguages = [[WikipediaLookup allLanguageLinks] sortedArrayUsingSelector:@selector(compare:)];
}

#pragma mark - Getters & Setters

- (nullable MWKLanguageLink *)languageForSiteURL:(NSURL *)siteURL {
    return [self.allLanguages wmf_match:^BOOL(MWKLanguageLink *obj) {
        return [obj.siteURL isEqual:siteURL];
    }];
}

- (nullable MWKLanguageLink *)languageForLanguageCode:(NSString *)languageCode {
    return [self.allLanguages wmf_match:^BOOL(MWKLanguageLink *obj) {
        return [obj.languageCode isEqualToString:languageCode];
    }];
}

- (nullable MWKLanguageLink *)appLanguage {
    return [self.preferredLanguages firstObject];
}

- (NSArray<MWKLanguageLink *> *)preferredLanguages {
    NSArray *preferredLanguageCodes = [self readPreferredLanguageCodes];
    return [preferredLanguageCodes wmf_mapAndRejectNil:^id(NSString *langString) {
        return [self.allLanguages wmf_match:^BOOL(MWKLanguageLink *langLink) {
            return [langLink.languageCode isEqualToString:langString];
        }];
    }];
}

- (NSArray<NSURL *> *)preferredSiteURLs {
    return [[self preferredLanguages] wmf_mapAndRejectNil:^NSURL *_Nullable(MWKLanguageLink *_Nonnull obj) {
        return [obj siteURL];
    }];
}

- (NSArray<MWKLanguageLink *> *)otherLanguages {
    return [self.allLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
        return ![self.preferredLanguages containsObject:langLink];
    }];
}

#pragma mark - Preferred Language Management

// Used for testing only.
- (void)addPreferredLanguage:(MWKLanguageLink *)language {
    NSParameterAssert(language);
    NSMutableArray<NSString *> *langCodes = [[self readPreferredLanguageCodes] mutableCopy];
    [langCodes removeObject:language.languageCode];
    [langCodes insertObject:language.languageCode atIndex:0];
    [self savePreferredLanguageCodes:langCodes];
}

- (void)appendPreferredLanguage:(MWKLanguageLink *)language {
    NSParameterAssert(language);
    NSMutableArray<NSString *> *langCodes = [[self readPreferredLanguageCodes] mutableCopy];
    [langCodes removeObject:language.languageCode];
    [langCodes addObject:language.languageCode];
    self.mostRecentlyModifiedPreferredLanguage = language;
    [self savePreferredLanguageCodes:langCodes];
}

- (void)reorderPreferredLanguage:(MWKLanguageLink *)language toIndex:(NSInteger)newIndex {
    NSMutableArray<NSString *> *langCodes = [[self readPreferredLanguageCodes] mutableCopy];
    NSAssert(newIndex < (NSInteger)[langCodes count], @"new language index is out of range");
    if (newIndex >= (NSInteger)[langCodes count]) {
        return;
    }
    NSInteger oldIndex = (NSInteger)[langCodes indexOfObject:language.languageCode];
    NSAssert(oldIndex != NSNotFound, @"Language is not a preferred language");
    if (oldIndex == NSNotFound) {
        return;
    }
    [langCodes removeObject:language.languageCode];
    [langCodes insertObject:language.languageCode atIndex:(NSUInteger)newIndex];
    self.mostRecentlyModifiedPreferredLanguage = language;
    [self savePreferredLanguageCodes:langCodes];
}

- (void)removePreferredLanguage:(MWKLanguageLink *)language {
    NSMutableArray<NSString *> *langCodes = [[self readPreferredLanguageCodes] mutableCopy];
    [langCodes removeObject:language.languageCode];
    self.mostRecentlyModifiedPreferredLanguage = language;
    [self savePreferredLanguageCodes:langCodes];
}

#pragma mark - Reading/Saving Preferred Language Codes to NSUserDefaults

- (NSArray<NSString *> *)readPreferredLanguageCodesWithoutOSPreferredLanguages {
    NSArray<NSString *> *preferredLanguages = [[NSUserDefaults standardUserDefaults] arrayForKey:WMFPreviousLanguagesKey] ?: @[];
    return preferredLanguages;
}

- (NSArray<NSString *> *)readOSPreferredLanguageCodes {
    NSArray<NSString *> *osLanguages = [[NSLocale preferredLanguages] wmf_mapAndRejectNil:^NSString *(NSString *languageCode) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:languageCode];
        // use language code when determining if a langauge is preferred (e.g. "en_US" is preferred if "en" was selected)
        return [locale objectForKey:NSLocaleLanguageCode];
    }];
    return osLanguages;
}

- (NSArray<NSString *> *)readPreferredLanguageCodes {
    NSMutableArray<NSString *> *preferredLanguages = [[self readPreferredLanguageCodesWithoutOSPreferredLanguages] mutableCopy];
    NSArray<NSString *> *osLanguages = [self readOSPreferredLanguageCodes];

    if (preferredLanguages.count == 0) {
        [osLanguages enumerateObjectsWithOptions:0
                                      usingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                          if (![preferredLanguages containsObject:obj]) {
                                              [preferredLanguages addObject:obj];
                                          }
                                      }];
    }
    return [preferredLanguages wmf_reject:^BOOL(id obj) {
        return [obj isEqual:[NSNull null]];
    }];
}

- (void)savePreferredLanguageCodes:(NSArray<NSString *> *)languageCodes {
    self.previousPreferredLanguages = self.preferredLanguages;
    NSString *previousAppLanguageCode = self.appLanguage.languageCode;
    [self willChangeValueForKey:WMF_SAFE_KEYPATH(self, allLanguages)];
    [[NSUserDefaults standardUserDefaults] setObject:languageCodes forKey:WMFPreviousLanguagesKey];
    [self didChangeValueForKey:WMF_SAFE_KEYPATH(self, allLanguages)];
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFPreferredLanguagesDidChangeNotification object:self];
    if (self.appLanguage.languageCode && ![self.appLanguage.languageCode isEqualToString:previousAppLanguageCode]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WMFAppLanguageDidChangeNotification object:self];
    }
}

// Reminder: "resetPreferredLanguages" is for testing only!
- (void)resetPreferredLanguages {
    [self willChangeValueForKey:WMF_SAFE_KEYPATH(self, allLanguages)];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WMFPreviousLanguagesKey];
    [self didChangeValueForKey:WMF_SAFE_KEYPATH(self, allLanguages)];
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFPreferredLanguagesDidChangeNotification object:self];
}

- (BOOL)languageIsOSLanguage:(MWKLanguageLink *)language {
    NSArray *languageCodes = [self readOSPreferredLanguageCodes];
    return [languageCodes wmf_match:^BOOL(NSString *obj) {
               BOOL answer = [obj isEqualToString:language.languageCode];
               return answer;
           }] != nil;
}

@end

NS_ASSUME_NONNULL_END
