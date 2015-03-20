//
//  OldDataSchema.h
//  OldDataSchema
//
//  Created by Brion on 12/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OldDataSchemaMigrator, MWKArticle, MWKTitle, MWKImage;

@protocol OldDataSchemaDelegate

- (MWKArticle*)oldDataSchema:(OldDataSchemaMigrator*)schema migrateArticle:(NSDictionary*)articleDict;

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema
         migrateImage:(NSDictionary*)imageDict
           newArticle:(MWKArticle*)newArticle;

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema migrateHistoryEntry:(NSDictionary*)historyDict;

- (void)oldDataSchema:(OldDataSchemaMigrator*)schema migrateSavedEntry:(NSDictionary*)savedDict;

@end


@interface OldDataSchemaMigrator : NSObject

@property (weak) id<OldDataSchemaDelegate> delegate;

- (BOOL)exists;
- (void)migrateData;
- (void)removeOldData;

@end
