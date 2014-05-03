//  Created by Monte Hurd on 5/1/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "Section+LeadSection.h"

@implementation Section (LeadSection)

-(BOOL)isLeadSection
{
    return (self.sectionId.integerValue == 0);
}

@end
