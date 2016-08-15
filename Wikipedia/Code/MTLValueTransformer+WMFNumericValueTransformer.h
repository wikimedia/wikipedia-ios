//
//  MTLValueTransformer+WMFNumericValueTransformer.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/12/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Mantle/MTLValueTransformer.h>

/**
 *  Transformer which can handle both numbers or strings on input, and produces
 * numbers on ouput.
 */
@interface MTLValueTransformer (WMFNumericValueTransformer)

+ (instancetype)wmf_numericValueTransformer;

@end
