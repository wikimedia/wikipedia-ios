//
//  MTLValueTransformer+WMFColorTransformer.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/29/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface MTLValueTransformer (WMFColorTransformer)

+ (instancetype)wmf_forwardHexColorTransformer;

@end
