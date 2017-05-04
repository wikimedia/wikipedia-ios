#import "NSString+FormattedAttributedString.h"

@implementation NSString (FormattedAttributedString)

- (NSAttributedString *)attributedStringWithAttributes:(NSDictionary *)attributes
                                   substitutionStrings:(NSArray *)substitutionStrings
                                substitutionAttributes:(NSArray *)substitutionAttributes {
    NSMutableAttributedString *returnString = nil;

    static NSMutableArray *regexArray = nil;
    if (!regexArray) {
        regexArray = @[].mutableCopy;
    }

    @synchronized(regexArray) {
        if (regexArray.count < substitutionStrings.count) {
            NSInteger regexCountNeeded = substitutionStrings.count - regexArray.count;
            NSInteger regexCountPrevious = regexArray.count;
            for (NSUInteger i = 0; i < regexCountNeeded; i++) {
                NSString *pattern = [NSString stringWithFormat:@"\\%%%lu+\\$@", (unsigned long)i + regexCountPrevious + 1];
                NSRegularExpression *newRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
                [regexArray addObject:newRegex];
            }
        }

        BOOL neededRegexesArePresent = regexArray.count >= substitutionStrings.count;
        NSAssert(neededRegexesArePresent, @"Not enough NSRegularExpression objects.");
        if (!neededRegexesArePresent) {
            // Bail returning unmolested string.
            return [[NSAttributedString alloc] initWithString:self attributes:nil];
        }

        returnString = [[NSMutableAttributedString alloc] initWithString:self
                                                              attributes:attributes];

        for (NSUInteger i = 0; i < substitutionStrings.count; i++) {
            NSArray *matches = [regexArray[i] matchesInString:returnString.string
                                                      options:0
                                                        range:NSMakeRange(0, returnString.string.length)];

            for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
                [returnString setAttributes:substitutionAttributes[i] range:match.range];
                [returnString replaceCharactersInRange:match.range withString:substitutionStrings[i]];
            }
        }
    }

    return returnString;
}

@end
