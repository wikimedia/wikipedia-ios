@import WMF;

/**
 *  Transformer which can handle both numbers or strings on input, and produces numbers on ouput.
 */
@interface MTLValueTransformer (WMFNumericValueTransformer)

+ (instancetype)wmf_numericValueTransformer;

@end
