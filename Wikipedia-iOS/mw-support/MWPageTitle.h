//
//  PageTitle.h
//  Wikipedia-iOS
//
//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import <Foundation/Foundation.h>

@interface MWPageTitle : NSObject

+(MWPageTitle *)titleFromNamespace:(NSString *)namespace text:(NSString *)text;

-(id)initFromNamespace:(NSString *)namespace text:(NSString *)text;

-(NSString *)namespace;
-(NSString *)text;
-(NSString *)prefixedText;

@end
