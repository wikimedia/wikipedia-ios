extern NSString *const WMFCodingStyleConstant;

typedef NS_ENUM(NSInteger, WMFCodingStyle) {
    WMFCodingStyleDefault = 0,
    WMFCodingStyleValue = 1
};

extern NSString *WMFCodingStyleAsString(WMFCodingStyle style);

extern void WMFMultilineFunctionDeclaration(int arg1,
                                            NSString *arg2,
                                            WMFCodingStyle arg3);

@interface WMFCodingStyleModel : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSString *modelIdentifier;

@property (nonatomic, readonly) WMFCodingStyle codingStyle;
@property (nonatomic, readonly) NSString *codingStyleString;

- (instancetype)initWithModelIdentifier:(NSString *)modelIdentifier
                            codingStyle:(WMFCodingStyle)codingStyle;

- (BOOL)isEqualToCodingStyleModel:(WMFCodingStyleModel *)otherModel;

- (NSString *)codingStyleDefaultString;

- (void)methodSignature:(id)foo
    withReallyReallyReallyReallyReallyReallyReallyLongSecondParameter:(id)arg;

@end
