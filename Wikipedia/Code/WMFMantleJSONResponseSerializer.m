#import <WMF/WMFMantleJSONResponseSerializer.h>
@import Mantle;
#import <WMF/NSError+WMFExtensions.h>
#import <WMF/WMFLogging.h>
#import <WMF/WMFOutParamUtils.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Retrieve JSON response objects' value at @c jsonKeypath in order to deserialize one or more instances of @c modelClass.
 */
@interface WMFMantleJSONResponseSerializer ()

@property (nonatomic, strong, readonly) Class modelClass;
@property (nonatomic, copy, readonly) NSString *jsonKeypath;
@property (nonatomic, getter=isEmptyValueForJSONKeypathAllowed) BOOL emptyValueForJSONKeypathAllowed;

- (instancetype)initWithModelClass:(Class)modelClass jsonKeypath:(NSString *__nullable)keypath emptyValueForJSONKeypathAllowed:(BOOL)emptyValueAllowed NS_DESIGNATED_INITIALIZER;

@end

/**
 *  Implementation of @c +serializerForInstancesOf:fromKeypath
 */
@interface WMFMantleJSONObjectResponseSerializer : WMFMantleJSONResponseSerializer

@end

/**
 *  Implementation of @c +serializerForValuesInDictionaryOfType:fromKeypath:
 */
@interface WMFMantleJSONDictionaryValueResponseSerializer : WMFMantleJSONResponseSerializer

@end

@interface WMFMantleArrayResponseSerializer : WMFMantleJSONResponseSerializer

@end

@implementation WMFMantleJSONResponseSerializer

+ (instancetype)serializerForValuesInDictionaryOfType:(Class)model fromKeypath:(NSString *__nullable)keypath emptyValueForJSONKeypathAllowed:(BOOL)emptyValueAllowed {
    return [[WMFMantleJSONDictionaryValueResponseSerializer alloc] initWithModelClass:model jsonKeypath:keypath emptyValueForJSONKeypathAllowed:emptyValueAllowed];
}

+ (instancetype)serializerForInstancesOf:(Class __nonnull)model fromKeypath:(NSString *__nullable)keypath emptyValueForJSONKeypathAllowed:(BOOL)emptyValueAllowed {
    return [[WMFMantleJSONObjectResponseSerializer alloc] initWithModelClass:model jsonKeypath:keypath emptyValueForJSONKeypathAllowed:emptyValueAllowed];
}

+ (instancetype)serializerForArrayOf:(Class)model fromKeypath:(NSString *__nullable)keypath emptyValueForJSONKeypathAllowed:(BOOL)emptyValueAllowed {
    return [[WMFMantleArrayResponseSerializer alloc] initWithModelClass:model jsonKeypath:keypath emptyValueForJSONKeypathAllowed:emptyValueAllowed];
}

- (instancetype)initWithModelClass:(Class __nonnull)modelClass jsonKeypath:(NSString *__nullable)keypath emptyValueForJSONKeypathAllowed:(BOOL)emptyValueAllowed {
    self = [super init];
    if (self) {
        NSAssert([modelClass isSubclassOfClass:[MTLModel class]],
                 @"%@ must be a subclass of %@ to be used with %@",
                 modelClass, NSStringFromClass([MTLModel class]), self);
        NSAssert([modelClass conformsToProtocol:@protocol(MTLJSONSerializing)],
                 @"%@ must conform to %@ to be used with %@",
                 modelClass, NSStringFromProtocol(@protocol(MTLJSONSerializing)), self);
        _modelClass = modelClass;
        _jsonKeypath = [keypath copy] ?: @"";
        _emptyValueForJSONKeypathAllowed = emptyValueAllowed;
    }
    return self;
}

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError *__autoreleasing *)error {
    NSDictionary *json = [super responseObjectForResponse:response data:data error:error];
    if (!json) {
        return nil;
    }
    id value = self.jsonKeypath.length ? [json valueForKeyPath:self.jsonKeypath] : json;
    if (!self.isEmptyValueForJSONKeypathAllowed && !value && self.jsonKeypath.length) {
        DDLogWarn(@"No value returned when serializing %@ with keypath %@ from response: %@",
                  self.modelClass, self.jsonKeypath, json);
    }
    return value;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], self.modelClass, self.jsonKeypath];
}

@end

@implementation WMFMantleJSONObjectResponseSerializer

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError *__autoreleasing *)error {
    NSDictionary *jsonObject = [super responseObjectForResponse:response data:data error:error];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        if (jsonObject) {
            DDLogError(@"%@ expected dictionary value, got: %@", self, jsonObject);
            NSError *unexpectedResponseError =
                [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                  userInfo:@{
                                      NSURLErrorFailingURLErrorKey: response.URL
                                  }];
            WMFSafeAssign(error, unexpectedResponseError);
        }
        return nil;
    }
    return [MTLJSONAdapter modelOfClass:self.modelClass fromJSONDictionary:jsonObject error:error];
}

@end

@implementation WMFMantleJSONDictionaryValueResponseSerializer

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError *__autoreleasing *)error {
    id value = [super responseObjectForResponse:response data:data error:error];
    if (![value isKindOfClass:[NSDictionary class]]) {
        if (value) {
            DDLogError(@"%@ expected JSON value to be a dictionary, got %@", self, value);
            NSError *unexpectedResponseError =
                [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                  userInfo:@{
                                      NSURLErrorFailingURLErrorKey: response.URL
                                  }];
            WMFSafeAssign(error, unexpectedResponseError);
        }
        return nil;
    }
    return [MTLJSONAdapter modelsOfClass:self.modelClass fromJSONArray:[(NSDictionary *)value allValues] error:error];
}

@end

@implementation WMFMantleArrayResponseSerializer

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError *__autoreleasing *)error {
    id value = [super responseObjectForResponse:response data:data error:error];
    if (![value isKindOfClass:[NSArray class]]) {
        if (value) {
            DDLogError(@"%@ expected JSON value to be an array, got %@", self, value);
            NSError *unexpectedResponseError =
                [NSError wmf_errorWithType:WMFErrorTypeUnexpectedResponseType
                                  userInfo:@{
                                      NSURLErrorFailingURLErrorKey: response.URL
                                  }];
            WMFSafeAssign(error, unexpectedResponseError);
        }
        return nil;
    }
    return [MTLJSONAdapter modelsOfClass:self.modelClass fromJSONArray:value error:error];
}

@end

NS_ASSUME_NONNULL_END
