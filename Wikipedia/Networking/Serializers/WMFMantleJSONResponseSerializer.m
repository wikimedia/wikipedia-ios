//
//  WMFMantleJSONResponseSerializer.m
//  Wikipedia
//
//  Created by Brian Gerstle on 8/27/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFMantleJSONResponseSerializer.h"
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFMantleJSONResponseSerializer ()

@property (nonatomic, strong, readonly) Class modelClass;
@property (nonatomic, copy, readonly) NSString* jsonKeypath;

- (instancetype)initWithModelClass:(Class)modelClass jsonKeypath:(NSString*)keypath NS_DESIGNATED_INITIALIZER;

@end

@interface WMFMantleJSONObjectResponseSerializer : WMFMantleJSONResponseSerializer

@end

@interface WMFMantleJSONCollectionResponseSerializer : WMFMantleJSONResponseSerializer

@end

@implementation WMFMantleJSONResponseSerializer

+ (instancetype)serializerForCollectionsOf:(Class __nonnull)model fromKeypath:(NSString * __nonnull)keypath {
    return [[WMFMantleJSONCollectionResponseSerializer alloc] initWithModelClass:model jsonKeypath:keypath];
}

+ (instancetype)serializerForInstancesOf:(Class __nonnull)model fromKeypath:(NSString * __nonnull)keypath {
    return [[WMFMantleJSONObjectResponseSerializer alloc] initWithModelClass:model jsonKeypath:keypath];
}

- (instancetype)initWithModelClass:(Class __nonnull)modelClass jsonKeypath:(NSString * __nonnull)keypath {
    self = [super init];
    if (self) {
        _modelClass = modelClass;
        _jsonKeypath = [keypath copy];
    }
    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    NSDictionary* json = [super responseObjectForResponse:response data:data error:error];
    if (!json) {
        return nil;
    }
    id value = self.jsonKeypath.length ? [json valueForKeyPath:self.jsonKeypath] : json;
    if (!value && self.jsonKeypath.length) {
        DDLogWarn(@"No value returned when serializing %@ with keypath %@ from response: %@",
                  self.modelClass, self.jsonKeypath, json);
    }
    return value;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], self.modelClass, self.jsonKeypath];
}

@end

@implementation WMFMantleJSONObjectResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    NSDictionary* jsonObject = [super responseObjectForResponse:response data:data error:error];
    if (!jsonObject) {
        return nil;
    } else if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        DDLogError(@"%@ expected dictionary value, got: %@", self, jsonObject);
    }
    return [MTLJSONAdapter modelOfClass:self.modelClass fromJSONDictionary:jsonObject error:error];
}

@end

@implementation WMFMantleJSONCollectionResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
    id value = [super responseObjectForResponse:response data:data error:error];
    if ([value isKindOfClass:[NSArray class]]) {
        return [MTLJSONAdapter modelsOfClass:self.modelClass fromJSONArray:value error:error];
    } else if (value) {
        // most MW API responses are indexed by page ID, just grab all the values in the dictionary
        return [MTLJSONAdapter modelsOfClass:self.modelClass
                               fromJSONArray:[(NSDictionary*)value allValues]
                                       error:error];
    } else {
        if (value) {
            DDLogError(@"%@ expected JSON value to be an array or dictionary, got %@", self, value);
        }
        return nil;
    }
}

@end


NS_ASSUME_NONNULL_END
