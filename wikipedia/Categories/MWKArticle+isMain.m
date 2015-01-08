//  Created by Monte Hurd on 12/31/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWKArticle+isMain.h"
#import "WikipediaAppUtils.h"

@implementation MWKArticle (isMain)

-(BOOL)isMain
{
    NSString *mainArticleTitle = [WikipediaAppUtils mainArticleTitleForCode: self.site.language];
    // Reminder: Do not do the following instead of the line above:
    //      NSString *mainArticleTitle = self.domainMainArticleTitle;
    // This is because each language domain has its own main page, and self.domainMainArticleTitle
    // is the main article title for the current search domain, but this "isCurrentArticleMain"
    // method needs to return YES if an article is a main page, even if it isn't the current
    // search domain's main page. For example, isCurrentArticleMain is used to decide whether edit
    // pencil icons will be shown for a page (they are not shown for main pages), but if
    // self.domainMainArticleTitle was being used above, the user would see edit icons if they
    // switched their search language from "en" to "fr", then hit back button - the "en" main
    // page would erroneously display edit pencil icons.
    if (!mainArticleTitle) return NO;
    return ([self.title.prefixedText isEqualToString: mainArticleTitle]);
}

@end
