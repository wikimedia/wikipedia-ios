//
//  OldDataSchema.m
//  OldDataSchema
//
//  Created by Brion on 12/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "OldDataSchema.h"

#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSManagedObjectContext+SimpleFetch.h"

@implementation OldDataSchema {
    ArticleDataContextSingleton *context;
}

-(BOOL)exists
{
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentRootPath = [documentPaths objectAtIndex:0];
    NSString *filePath = [documentRootPath stringByAppendingPathComponent:@"articleData6.sqlite"];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

-(void)migrateData
{
    // TODO
}

@end
