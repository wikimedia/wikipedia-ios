#import "MWKCitation.h"
#import <hpple/TFHpple.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface MWKCitation ()
@property (nonatomic, copy) NSString *citationIdentifier;
@property (nonatomic, copy) NSArray *backlinkIdentifiers;
@property (nonatomic, copy) NSString *rawHTML;
@end

@implementation MWKCitation
@synthesize citationHTML = _citationHTML;
@synthesize backlinkIdentifiers = _backlinkIdentifiers;

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    if ([propertyKey isEqualToString:WMF_SAFE_KEYPATH([MWKCitation new], citationHTML)] || [propertyKey isEqualToString:WMF_SAFE_KEYPATH([MWKCitation new], backlinkIdentifiers)]) {
        return MTLPropertyStorageTransitory;
    }
    return MTLPropertyStoragePermanent;
}

- (MWKCitation *__nullable)initWithCitationIdentifier:(NSString *__nonnull)citationIdentifier
                                              rawHTML:(NSString *__nonnull)rawHTML {
    return [self initWithCitationIdentifier:citationIdentifier
                                    rawHTML:rawHTML
                                      error:nil];
}

- (MWKCitation *__nullable)initWithCitationIdentifier:(NSString *__nonnull)citationIdentifier
                                              rawHTML:(NSString *__nonnull)rawHTML
                                                error:(out NSError *__nullable __autoreleasing *__nullable)error {
    self = [super init];
    if (self) {
        self.rawHTML = rawHTML;
        self.citationIdentifier = citationIdentifier;
    }
    if ([self validate:error]) {
        return self;
    } else {
        DDLogError(@"Failed to create citation object with identifier %@ and rawHTML %@", citationIdentifier, rawHTML);
        return nil;
    }
}

- (BOOL)validateCitationIdentfier:(inout NSString *__autoreleasing *)inoutCitationIdentifier
                            error:(out NSError *__autoreleasing *)error {
    return [(*inoutCitationIdentifier)length] > 0;
}

- (BOOL)validateRawHTML:(inout NSString *__autoreleasing *)inoutRawHTML
                  error:(out NSError *__autoreleasing *)error {
    return [(*inoutRawHTML)length] > 0;
}

- (NSString *)citationHTML {
    if (_citationHTML) {
        _citationHTML = [[[[TFHpple hppleWithHTMLData:[self.rawHTML dataUsingEncoding:NSUTF8StringEncoding]]
                            searchWithXPathQuery:@"/html/body/*[not(contains(@class, 'mw-cite-backlink')]"]
                            valueForKey:WMF_SAFE_KEYPATH(TFHppleElement.new, raw)] componentsJoinedByString:@""]
                            ?: @"";
        NSAssert(_citationHTML.length, @"Failed to parse citation from raw HTML: %@", self.rawHTML);
    }
    return _citationHTML;
}

- (NSArray *)backlinkIdentifiers {
    if (_backlinkIdentifiers) {
        _backlinkIdentifiers = [[[[TFHpple hppleWithHTMLData:[self.rawHTML dataUsingEncoding:NSUTF8StringEncoding]]
            searchWithXPathQuery:@"/html/body//*[contains(@class,'mw-cite-backlink')]//a"]
            wmf_map:^NSString *(TFHppleElement *el) {
                return el.attributes[@"id"];
            }]
            wmf_reject:^BOOL(id obj) {
                return WMF_IS_EQUAL(obj, [NSNull null]);
            }];
        if (!_backlinkIdentifiers) {
            _backlinkIdentifiers = @[];
        }
        NSAssert(_backlinkIdentifiers.count, @"Failed to parse backlinks from raw HTML: %@", self.rawHTML);
    }
    return _backlinkIdentifiers;
}

- (NSString *)description {
    //Do not use MTLModel's description as it will cause recursion since this instance has a reference to the article, which also has a reference to this citation
    return [NSString stringWithFormat:@"citation: %@", self.citationIdentifier];
}

@end

NS_ASSUME_NONNULL_END
