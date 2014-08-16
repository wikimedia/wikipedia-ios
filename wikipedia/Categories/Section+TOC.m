//  Created by Monte Hurd on 8/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "Section+TOC.h"
#import "Section+LeadSection.h"
#import "Article.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "NSString+FormattedAttributedString.h"
#import "NSString+Extras.h"

@implementation Section (TOC)

-(id)tocTitle
{
    BOOL isLead = [self isLeadSection];
    
    NSString *title = isLead ? self.article.title : self.title;

    NSString *noHtmlTitle = [title getStringWithoutHTML];

    id titleToUse = isLead ? [self getLeadSectionAttributedTitleForString:noHtmlTitle] : noHtmlTitle;

    return titleToUse;
}

-(NSAttributedString *)getLeadSectionAttributedTitleForString:(NSString *)string
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 8;
    
    NSDictionary *contentsHeaderAttributes = @{
                                    NSFontAttributeName : [UIFont boldSystemFontOfSize:10.5],
                                    NSKernAttributeName : @(1.25),
                                    NSParagraphStyleAttributeName : paragraphStyle
                                    };
    NSDictionary *sectionTitleAttributes = @{
                                       NSFontAttributeName : [UIFont fontWithName:@"Times New Roman" size:24]
                                       };
    
    NSString *heading = MWLocalizedString(@"table-of-contents-heading", nil);
    
    if ([[SessionSingleton sharedInstance].domain isEqualToString:@"en"]) {
        heading = [heading uppercaseString];
    }
    
    return [@"$1\n$2" attributedStringWithAttributes: @{}
                                 substitutionStrings: @[heading, string]
                              substitutionAttributes: @[contentsHeaderAttributes, sectionTitleAttributes]
            ];
    
}

@end
