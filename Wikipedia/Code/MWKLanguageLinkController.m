#import <WMF/MWKLanguageLinkController_Private.h>
#import <WMF/WMF-Swift.h>
#import <WMF/MWKDataStore.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFPreferredLanguagesDidChangeNotification = @"WMFPreferredLanguagesDidChangeNotification";

NSString *const WMFAppLanguageDidChangeNotification = @"WMFAppLanguageDidChangeNotification";

static NSString *const WMFPreviousLanguagesKey = @"WMFPreviousSelectedLanguagesKey";

@interface MWKLanguageLinkController ()

@property (weak, nonatomic) NSManagedObjectContext *moc;

@end

@implementation MWKLanguageLinkController

static id _sharedInstance;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
    if (self = [super init]) {
        self.moc = moc;
    }
    return self;
}

#pragma mark - Getters & Setters

+ (NSArray<MWKLanguageLink *> *)allLanguages {
    /// Separate static array here so the array is only bridged once
    static dispatch_once_t onceToken;
    static NSArray<MWKLanguageLink *> *allLanguages;
    dispatch_once(&onceToken, ^{
        allLanguages =  WikipediaLookup.allLanguageLinks;
    });
    return allLanguages;
}

- (NSArray<MWKLanguageLink *> *)allLanguages {
    return [MWKLanguageLinkController allLanguages];
}

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

#pragma mark - Reading/Saving Preferred Language Codes

- (NSArray<NSString *>
   *)readPreferredLanguageCodesWithoutOSPreferredLanguages {
    __block NSArray<NSString *> *preferredLanguages = nil;
    [self.moc performBlockAndWait:^{
        preferredLanguages = [self.moc wmf_arrayValueForKey:WMFPreviousLanguagesKey] ?: @[];
    }];
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
    [self.moc performBlockAndWait:^{
        [self.moc wmf_setValue:languageCodes forKey:WMFPreviousLanguagesKey];
    }];
    [self didChangeValueForKey:WMF_SAFE_KEYPATH(self, allLanguages)];
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFPreferredLanguagesDidChangeNotification object:self];
    if (self.appLanguage.languageCode && ![self.appLanguage.languageCode isEqualToString:previousAppLanguageCode]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WMFAppLanguageDidChangeNotification object:self];
    }
}

// Reminder: "resetPreferredLanguages" is for testing only!
- (void)resetPreferredLanguages {
    [self willChangeValueForKey:WMF_SAFE_KEYPATH(self, allLanguages)];
    [self.moc performBlockAndWait:^{
        [self.moc wmf_setValue:nil forKey:WMFPreviousLanguagesKey];
    }];
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

- (void)getPreferredLanguageCodes:(void (^)(NSArray<NSString *> *))completion {
    [self.moc performBlock:^{
        completion([self readPreferredLanguageCodes]);
    }];
}

// This method can only be safely called from the main app target, as an extension's standard `NSUserDefaults` are independent from the main app and other targets.
+ (void)migratePreferredLanguagesToManagedObjectContext:(NSManagedObjectContext *)moc {
    NSArray *preferredLanguages = [[NSUserDefaults standardUserDefaults] arrayForKey:WMFPreviousLanguagesKey];
    [moc wmf_setValue:preferredLanguages forKey:WMFPreviousLanguagesKey];
}

@end

NS_ASSUME_NONNULL_END
