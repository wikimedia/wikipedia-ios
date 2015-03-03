//  Created by Monte Hurd on 3/26/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSString+FormattedAttributedString.h"

@implementation NSString (FormattedAttributedString)

- (NSAttributedString*)attributedStringWithAttributes:(NSDictionary*)attributes
                                  substitutionStrings:(NSArray*)substitutionStrings
                               substitutionAttributes:(NSArray*)substitutionAttributes {
    NSMutableAttributedString* returnString =
        [[NSMutableAttributedString alloc] initWithString:self
                                               attributes:attributes];

    for (NSUInteger i = 0; i < substitutionStrings.count; i++) {
        NSRegularExpression* regex =
            [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\$%lu+", (unsigned long)i + 1]
                                                      options:0
                                                        error:nil];
        NSArray* matches =
            [regex matchesInString:returnString.string
                           options:0
                             range:NSMakeRange(0, returnString.string.length)];

        for (NSTextCheckingResult* checkingResult in [matches reverseObjectEnumerator]) {
            [returnString setAttributes:substitutionAttributes[i] range:checkingResult.range];
            [returnString replaceCharactersInRange:checkingResult.range withString:substitutionStrings[i]];
        }
    }
    return returnString;
}

@end
