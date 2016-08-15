//
//  WMFMantleJSONResponseSerializer.h
//  Wikipedia
//
//  Created by Brian Gerstle on 8/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFApiJsonResponseSerializer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMantleJSONResponseSerializer : WMFApiJsonResponseSerializer

/**
 *  Create a serializer for converting a value in a JSON response into a single instance of @c model.
 *
 *  @param model   Class which response objects should be converted into. Must subclass @c MTLModel and conform to
 *                 @c MTLJSONSerializing.
 *
 *  @param keypath Keypath used to extract the JSON object which is deserialized into @c model.
 *
 *  @return A response serializer.
 */
+ (instancetype)serializerForInstancesOf:(Class)model fromKeypath:(NSString* __nullable)keypath;


/**
 *  Create a serializer for converting a value in a JSON response into an array @c model objects.
 *
 *  @param model   Class which response objects should be converted into. Must subclass @c MTLModel and conform to
 *                 @c MTLJSONSerializing.
 *
 *  @param keypath Keypath used to extract the JSON object which is deserialized into @c model.
 *
 *  @return A response serializer.
 */
+ (instancetype)serializerForArrayOf:(Class)model fromKeypath:(NSString* __nullable)keypath;

/**
 *  Create a serializer for converting a dictionary value in a JSON response into a collection of objects of type @c model.
 *
 *  This requires that the value at @c jsonKeypath is a dictionary, from which @c allValues are retrieved and parsed
 *  into an array whose objects are instances of @c model.
 *
 *  @param model   Class which response objects should be converted into. Must subclass @c MTLModel and conform to
 *                 @c MTLJSONSerializing.
 *
 *  @param keypath Keypath used to extract the JSON object which is deserialized into @c model.
 *
 *  @return A response serializer.
 */
+ (instancetype)serializerForValuesInDictionaryOfType:(Class)model fromKeypath:(NSString* __nullable)keypath;

@end

NS_ASSUME_NONNULL_END
