//  Created by Monte Hurd on 3/26/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface NSString (FormattedAttributedString)

/*

   Returns attributed string version of string with "attributes" applied to it and
   does dollar-sign-number substitutions (eg $1, $2 etc) replacing dollar-sign-number
   occurences in string with respective strings from "substitutionStrings" and applying
   respective attributes from "substitutionAttributes" to the substituted string.

   Super handy for quickly creating a string which has many different style attributes
   set to many of its different letters.

   Example:
    NSDictionary *largeOrangeText = @{
                                   NSFontAttributeName : [UIFont fontWithName:@"Georgia" size:20],
                                   NSForegroundColorAttributeName : [UIColor orangeColor]
                                   };
    NSDictionary *smallGreenText = @{
                                   NSFontAttributeName : [UIFont boldSystemFontOfSize:8],
                                   NSForegroundColorAttributeName : [UIColor greenColor]
                                   };
    NSDictionary *mediumBlueText = @{
                                   NSFontAttributeName : [UIFont systemFontOfSize:14],
                                   NSForegroundColorAttributeName : [UIColor blueColor],
                                   NSStrikethroughStyleAttributeName : @YES
                                   };

    NSString *string = @"Large orange text and some $1 and $2 text. More $1 text.";

    NSAttributedString *attributedString =
    [string attributedStringWithAttributes: largeOrangeText
                       substitutionStrings: @[@"small green", @"medium blue"]
                    substitutionAttributes: @[smallGreenText, mediumBlueText]
     ];
 */

- (NSAttributedString*)attributedStringWithAttributes:(NSDictionary*)attributes
                                  substitutionStrings:(NSArray*)substitutionStrings
                               substitutionAttributes:(NSArray*)substitutionAttributes;

@end
