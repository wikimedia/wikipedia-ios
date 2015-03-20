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

@protocol OldDataSchemaMigratorProgressDelegate <NSObject>

-(void)oldDataSchema:(OldDataSchemaMigrator *)schema didUpdateProgressWithArticlesCompleted:(NSUInteger)completed total:(NSUInteger)total;

-(void)oldDataSchemaDidFinishMigration:(OldDataSchemaMigrator *)schema;

-(void)oldDataSchema:(OldDataSchemaMigrator *)schema didFinishWithError:(NSError*)error;

@end



@interface OldDataSchemaMigrator : NSObject

@property (weak) id<OldDataSchemaDelegate> delegate;
@property (weak) id<OldDataSchemaMigratorProgressDelegate> progressDelegate;

-(BOOL)exists;

/**
 *  This runs asynchronously. 
 *  Use the progress delegate methods to get notifified when the migration completes.
 */
-(void)migrateData;

@end
