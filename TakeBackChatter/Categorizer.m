//
//  Categorizer.m
//  TakeBackChatter
//
//  Created by Simon Fell on 6/7/11.
//

#import "Categorizer.h"
#import "FeedItem.h"
#import "prefs.h"
#import <BayesianKit/BayesianKit.h>

@interface Categorizer ()
-(NSString *)categorizerFilePath;

-(NSString *)categorizerFile:(NSString *)fn;
-(NSString *)classifierFilename;
-(NSString *)goodIdsFilename;
-(NSString *)junkIdsFilename;
@end

@implementation Categorizer

static NSString *POOL_NAME_GOOD = @"Good";
static NSString *POOL_NAME_JUNK = @"Junk";

static NSString *CORPUS_FN   = @"corpus.bks";
static NSString *GOOD_IDS_FN = @"good.ids";
static NSString *JUNK_IDS_FN = @"junk.ids";

+(void)addToDefaults:(NSMutableDictionary *)defaults {
    [defaults setObject:[NSNumber numberWithInt:10] forKey:PREFS_TRAINING_COUNT];
}

+(NSSet *)keyPathsForValuesAffectingTrainingLeft {
    return [NSSet setWithObject:@"categorizedCount"];
}

+(NSSet *)keyPathsForValuesAffectingIsTraining {
    return [NSSet setWithObject:@"categorizedCount"];
}

-(void)initClassifier {
    NSString *corpusFile = [self classifierFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:corpusFile])
        classifier = [[BKClassifier alloc] initWithContentsOfFile:corpusFile];
    else
        classifier = [[BKClassifier alloc] init];
}

-(NSMutableSet *)initIds:(NSString *)fn {
    NSString *file = [self categorizerFile:fn];
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) 
        return [NSMutableSet setWithArray:[NSArray arrayWithContentsOfFile:file]];
    return [NSMutableSet set];
}

-(id)init {
    self = [super init];
    [self initClassifier];
    goodIds = [[self initIds:GOOD_IDS_FN] retain];
    junkIds = [[self initIds:JUNK_IDS_FN] retain];
    return self;
}

-(void)dealloc {
    [classifier release];
    [goodIds release];
    [junkIds release];
    [super dealloc];
}

-(NSString *)categorizerFilePath {
    NSArray * dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appDir = [[dirs objectAtIndex:0] stringByAppendingPathComponent:@"TakeBackChatter"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:appDir withIntermediateDirectories:YES attributes:nil error:nil];
    return appDir;
}

-(NSString *)categorizerFile:(NSString *)fn {
    return [self.categorizerFilePath stringByAppendingPathComponent:fn];
}

-(NSString *)classifierFilename {
    return [self categorizerFile:CORPUS_FN];
}

-(NSString *)goodIdsFilename {
    return [self categorizerFile:GOOD_IDS_FN];
}

-(NSString *)junkIdsFilename {
    return [self categorizerFile:JUNK_IDS_FN];
}

-(void)persist {
    [classifier writeToFile:[self classifierFilename]];
    [[goodIds allObjects] writeToFile:[self goodIdsFilename] atomically:YES];
    [[junkIds allObjects] writeToFile:[self junkIdsFilename] atomically:YES];
}

-(int)chanceIsJunk:(FeedItem *)item {
    if ([junkIds containsObject:[item rowId]]) return 100;
    if ([goodIds containsObject:[item rowId]]) return 0;
    NSDictionary *cl = [ classifier guessWithString:item.classificationText];
    NSNumber *g = [cl objectForKey:@"Junk"];
    return [g floatValue] * 100;
}

-(void)categorize:(NSArray *)items 
               as:(NSString *)poolname 
         addIdsTo:(NSMutableSet *)addTo 
    removeIdsFrom:(NSMutableSet *)removeFrom {

    [self willChangeValueForKey:@"categorizedCount"];
    for (FeedItem *item in items) {
        [classifier trainWithString:item.classificationText forPoolNamed:poolname];
        [addTo addObject:[item rowId]];
        [removeFrom removeObject:[item rowId]];
    }
    [self didChangeValueForKey:@"categorizedCount"];
}

-(void)categorizeItemsAsJunk:(NSArray *)items {
    [self categorize:items as:POOL_NAME_JUNK addIdsTo:junkIds removeIdsFrom:goodIds];
}

-(void)categorizeItemsAsGood:(NSArray *)items {
    [self categorize:items as:POOL_NAME_GOOD addIdsTo:goodIds removeIdsFrom:junkIds];
}

-(BOOL)isTraining {
    return self.trainingLeft > 0;
}

-(NSUInteger)categorizedCount {
    return goodIds.count + junkIds.count;
}

-(NSUInteger)trainingLeft {
    NSUInteger c = self.categorizedCount;
    NSInteger t = [[NSUserDefaults standardUserDefaults] integerForKey:PREFS_TRAINING_COUNT];
    return t > c ? t-c : 0;
}

@end
