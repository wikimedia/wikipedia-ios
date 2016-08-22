#import "WMFCodingStyle.h"

NSString *const WMFCodingStyleConstant = @"WMFCodingStyleConstant";

NSString *WMFCodingStyleAsString(WMFCodingStyle style) {
    switch (style) {
        case WMFCodingStyleDefault: {
            return @"default";
        }
        case WMFCodingStyleValue: {
            return @"value";
        }
    }
}

extern void WMFMultilineFunctionDeclaration(int arg1,
                                            NSString *arg2,
                                            WMFCodingStyle arg3) {
    // body
}

@implementation WMFCodingStyleModel

- (instancetype)initWithModelIdentifier:(NSString *)modelIdentifier
                            codingStyle:(WMFCodingStyle)codingStyle {
    self = [super init];
    if (self) {
        _modelIdentifier = [modelIdentifier copy];
        _codingStyle = codingStyle;
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    } else if ([other isKindOfClass:[WMFCodingStyleModel class]]) {
        return [self isEqualToCodingStyleModel:other];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToCodingStyleModel:(WMFCodingStyleModel *)other {
    return self.modelIdentifier == other.modelIdentifier && [self.modelIdentifier isEqualToString:other.modelIdentifier] && self.codingStyle == other.codingStyle;
}

- (NSString *)codingStyleDefaultString {
    return WMFCodingStyleAsString(self.codingStyle);
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithModelIdentifier:self.modelIdentifier
                                                          codingStyle:self.codingStyle];
}

- (NSArray *)multiLineArrayExample {
    return @[@0,
             @1,
             @2,
             @3];
}

- (NSDictionary *)multiLineDictionaryExample {
    return @{ @"foo": @0,
              @"bar": @1 };
}

- (void)simpleBlockExample {
    [[self multiLineArrayExample] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        // block body
        // goes here
    }];
}

- (void)chainedBlockExample {
    [[[self multiLineArrayExample]
        filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            // block body
            // goes here
            return YES;
        }]]
        filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            // block body
            // goes here
            return YES;
        }]];
}

- (void)animationExample {
    [UIView animateWithDuration:0
        animations:^{
            if (YES) {
                NSLog(@"Foo!");
            }
        }
        completion:^(BOOL finished) {
            if (YES) {
                NSLog(@"Foo!");
            }
        }];
}

- (void)animationExampleWithInternalBlocks {
    [UIView animateWithDuration:0
        animations:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // body

                if (YES) {
                    NSLog(@"Foo!");
                }
            });
        }
        completion:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                               // body
                           });
        }];
}

- (void)methodSignature:(id)foo
    withReallyReallyReallyReallyReallyReallyReallyLongSecondParameter:(id)arg {
}

- (CGRect)multiLineFunctionExample {
    return CGRectMake(0,
                      0,
                      0,
                      0);
}

- (void)multiLineMacroExample {
    NSAssert(YES,
             @"Testing a macro invocation across multiple lines. %@ %@ %@",
             @"Another line.",
             @"Then another.",
             @"And yet, another.");
}

- (BOOL)multiLineAssignmentExample {
    BOOL foo =
        [[self multiLineArrayExample] containsObject:[NSString stringWithFormat:@"Some really long assigment %d", 0]];
    return foo;
}

- (BOOL)multiLineConditionalExample {
    if (YES || NO && YES) {
        return YES;
    } else {
        return NO;
    }
}

@end
