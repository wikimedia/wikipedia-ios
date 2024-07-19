#import <Foundation/Foundation.h>
#import "Mantle.h"

NS_ASSUME_NONNULL_BEGIN

/// WMFMTLModel allows us to implement NSSecureCoding for all of our MTLModel objects in one place
/// Long term, Mantle should likely be removed and replaced with Codable Swift structs.
@interface WMFMTLModel : MTLModel <NSSecureCoding>
- (instancetype)initWithLanguageVariantCode:(nullable NSString *)languageVariantCode;

/// Keys of URL properties to have their language variant code set when propagating language variant codes.
/// Defaults to empty array.
+ (NSArray<NSString *> *)languageVariantCodePropagationURLKeys;

/// Keys of subelements to be accessed to propagate language variant codes.
/// The properties represented are expected to be WMFMTLModel subclasses or arrays of WMFMTLModel subclasses
/// Defaults to empty array.
+ (NSArray<NSString *> *)languageVariantCodePropagationSubelementKeys;

/// Propagates the provided language variant code to the URLs in the properties returned by urlKeys.
/// Further propagates by calling -propagateLanguageVariantCode: on the subelement values of the subelementKeys.
- (void)propagateLanguageVariantCode:(nullable NSString *)languageVariantCode;
@end

@interface MTLJSONAdapter (LanguageVariantExtensions)
/// Allows creation of a model instance from a JSONDictionary that propagates the provided language variant code through the created instance and its graph of subelements
+ (nullable id)modelOfClass:(Class)modelClass fromJSONDictionary:(NSDictionary *)JSONDictionary languageVariantCode:(nullable NSString *)languageVariantCode error:(NSError **)error;

/// Allows creation of an array of model instances from a JSONDictionary that propagates the provided language variant code through each created instance and its graph of subelements
+ (NSArray *)modelsOfClass:(Class)modelClass fromJSONArray:(NSArray *)JSONArray languageVariantCode:(nullable NSString *)languageVariantCode error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
