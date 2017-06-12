#import <WMF/NSDictionary+WMFRequiredValueForKey.h>
#import <WMF/WMFLogging.h>
#import <WMF/WMFOutParamUtils.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFInvalidValueForKeyErrorDomain = @"WMFInvalidValueForKeyErrorDomain";
NSString *const WMFFailingDictionaryUserInfoKey = @"WMFFailingDictionaryUserInfoKey";

@implementation NSDictionary (WMFRequiredValueForKey)

- (nullable id)wmf_instanceOfClass:(Class)aClass
                            forKey:(NSString *)key
                             error:(NSError *_Nullable __autoreleasing *)outError {
    NSParameterAssert(key);
    NSError * (^errorWithCode)(WMFInvalidValueForKeyError) = ^(WMFInvalidValueForKeyError code) {
        return [NSError errorWithDomain:WMFInvalidValueForKeyErrorDomain
                                   code:code
                               userInfo:@{
                                   WMFFailingDictionaryUserInfoKey: self
                               }];
    };
    id value = self[key];
    if (!value) {
        DDLogError(@"Unexpected nil for key %@ in %@.", key, self);
        WMFSafeAssign(outError, errorWithCode(WMFInvalidValueForKeyErrorNoValue));
        return nil;
    } else if (![value isKindOfClass:aClass]) {
        DDLogError(@"Expected instance of %@, but got %@ for key %@", aClass, [value class], key);
        WMFSafeAssign(outError, errorWithCode(WMFInvalidValueForKeyErrorIncorrectType));
        return nil;
    } else {
        return value;
    }
}

@end

NS_ASSUME_NONNULL_END
