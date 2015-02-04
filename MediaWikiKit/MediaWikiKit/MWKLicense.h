//
//  MWKLicense.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/10/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@interface MWKLicense : MWKDataObject

@property (nonatomic, readonly, copy) NSString *code;

@property (nonatomic, readonly, copy) NSString *shortDescription;

@property (nonatomic, readonly) NSURL *URL;

+ (instancetype)licenseWithExportedData:(NSDictionary*)exportedData;

- (instancetype)initWithCode:(NSString*)code
            shortDescription:(NSString*)shortDescription
                         URL:(NSURL*)URL;

- (BOOL)isEqualToLicense:(MWKLicense*)other;

@end
