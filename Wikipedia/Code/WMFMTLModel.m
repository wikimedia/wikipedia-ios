#import "WMFMTLModel.h"

@implementation WMFMTLModel

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
}

+ (NSMutableDictionary <NSString *, NSDictionary *>*)allowedSecureCodingClassesByPropertyKeyCache {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *cache;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary new];
    });
    return cache;
}

/// We allow other WMFMTLModels to be decoded as values for properties on our model objects, so WMFMTLModel needs to be added to allowedSecureCodingClassesByPropertyKey. It seemed simpler to implement in one place and allow it for any property rather than re-implementing on every class.
+ (NSDictionary *)allowedSecureCodingClassesByPropertyKey {
    NSString *className = NSStringFromClass([self class]);
    NSMutableDictionary *cache = [self allowedSecureCodingClassesByPropertyKeyCache];
    NSDictionary *cached = cache[className];
    if (cached) {
        return cached;
    }
    NSMutableDictionary *superAllowed = [[super allowedSecureCodingClassesByPropertyKey] mutableCopy];
    NSArray *keys = [superAllowed allKeys];
    for (NSString *key in keys) {
        NSMutableArray *superArray = [superAllowed[key] mutableCopy];
        [superArray addObject:[WMFMTLModel class]];
        superAllowed[key] = superArray;
    }
    NSDictionary *allowed = [superAllowed copy];
    [cache setValue:allowed forKey:className];
    return allowed;
}

- (instancetype)initWithLanguageVariantCode:(nullable NSString *)languageVariantCode {
    if (self = [super init]) {
        [self propagateLanguageVariantCode:languageVariantCode];
    }
    return self;
}

#pragma mark - Language Variant Code Propagation

+ (NSArray<NSString *> *)languageVariantCodePropagationURLKeys { return @[]; }

+ (NSArray<NSString *> *)languageVariantCodePropagationSubelementKeys { return @[]; }

- (void)propagateLanguageVariantCode:(nullable NSString *)languageVariantCode {
    for (NSString *urlKey in [[self class] languageVariantCodePropagationURLKeys]) {
        NSString *keyPath = [urlKey stringByAppendingString:@".wmf_languageVariantCode"];
        [self setValue:languageVariantCode forKeyPath:keyPath];
    }
    for (NSString *subelementKey in [[self class] languageVariantCodePropagationSubelementKeys]) {
        id value = [self valueForKey:subelementKey];
        if ([value isKindOfClass:[NSArray class]]) {
            NSArray *subelements = value;
            for (id subelement in subelements) {
                [self propagateLanguageVariantCode:languageVariantCode toSubelement:subelement];
            }
        } else {
            [self propagateLanguageVariantCode:languageVariantCode toSubelement:value];
        }
    }
}
- (void)propagateLanguageVariantCode:(nullable NSString *)languageVariantCode toSubelement:(id)subelement {
    if (!subelement) {
        return;
    } else if ([subelement respondsToSelector:@selector(propagateLanguageVariantCode:)]) {
        [subelement propagateLanguageVariantCode:languageVariantCode];
    } else {
        [NSException raise:NSInternalInconsistencyException format:@"Object %@ does not respond to selector -propagateLanguageVariantCode:", subelement];
    }
}


@end


#pragma mark - MTLJSONAdapter Language Variant Extensions

@implementation MTLJSONAdapter (LanguageVariantExtensions)
+ (nullable id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary languageVariantCode:(nullable NSString *) languageVariantCode error:(NSError **)error {
    id model = [[self class] modelOfClass:modelClass fromJSONDictionary:JSONDictionary error:error];
    if (model && [model respondsToSelector:@selector(propagateLanguageVariantCode:)]) {
        [model propagateLanguageVariantCode: languageVariantCode];
    }
    return model;
}

+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray languageVariantCode:(nullable NSString *) languageVariantCode error:(NSError **)error {
    NSArray *models = [[self class] modelsOfClass:modelClass fromJSONArray:JSONArray error:error];
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    for (id model in models) {
        if (model && [model respondsToSelector:@selector(propagateLanguageVariantCode:)]) {
            [model propagateLanguageVariantCode: languageVariantCode];
        }
        [tempArray addObject:model];
    }
    return [tempArray copy];
}
@end
