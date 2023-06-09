#import "NSString+Localized.h"

@implementation NSString (Localized)

- (NSString *)localized {
    NSBundle *unitTestBundle = [NSBundle bundleWithIdentifier:@"org.wikimedia.WikipediaUnitTests"];
    return [unitTestBundle localizedStringForKey:self value:nil table:nil];
}

@end
