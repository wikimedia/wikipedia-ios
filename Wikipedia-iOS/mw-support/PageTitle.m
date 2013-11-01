//
//  PageTitle.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "PageTitle.h"

@implementation PageTitle {
    NSString *_namespace;
    NSString *_text;
}

+(PageTitle *)titleFromNamespace:(NSString *)namespace text:(NSString *)text
{
    return [[PageTitle alloc] initFromNamespace:namespace text:text];
}

-(id)initFromNamespace:(NSString *)namespace text:(NSString *)text
{
    self = [self init];
    if (self) {
        _namespace = namespace;
        _text = text;
    }
    return self;
}

-(NSString *)namespace
{
    return _namespace;
}

-(NSString *)text
{
    return _text;
}

@end
