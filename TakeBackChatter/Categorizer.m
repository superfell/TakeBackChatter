//
//  Categorizer.m
//  TakeBackChatter
//
//  Created by Simon Fell on 6/7/11.
//

#import "Categorizer.h"
#import "FeedItem.h"
#import <BayesianKit/BayesianKit.h>

@interface Categorizer ()
-(NSString *)classifierFilename;
@end

@implementation Categorizer

static NSString *POOL_NAME_GOOD = @"Good";
static NSString *POOL_NAME_JUNK = @"Junk";

- (id)init {
    self = [super init];
    NSString *corpusFile = [self classifierFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:corpusFile])
        classifier = [[BKClassifier alloc] initWithContentsOfFile:corpusFile];
    else
        classifier = [[BKClassifier alloc] init];
    return self;
}

- (void)dealloc {
    [classifier release];
    [super dealloc];
}

-(NSString *)classifierFilename {
    NSArray * dirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appDir = [[dirs objectAtIndex:0] stringByAppendingPathComponent:@"TakeBackChatter"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appDir])
        [[NSFileManager defaultManager] createDirectoryAtPath:appDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *corpusFile = [appDir stringByAppendingPathComponent:@"corpus.bks"];
    return corpusFile;
}

-(void)persist {
    if (classifier != nil)
        [classifier writeToFile:[self classifierFilename]];
}

-(int)chanceIsJunk:(FeedItem *)item {
    NSDictionary *cl = [ classifier guessWithString:item.classificationText];
    NSNumber *g = [cl objectForKey:@"Junk"];
    return [g floatValue] * 100;
}

-(void)categorize:(NSArray *)items as:(NSString *)poolname {
    NSMutableString *text = [NSMutableString string];
    for (FeedItem *item in items)
        [text appendString:item.classificationText];
    
    [classifier trainWithString:text forPoolNamed:poolname];
}

-(void)categorizeItemsAsJunk:(NSArray *)items {
    [self categorize:items as:POOL_NAME_JUNK];
}

-(void)categorizeItemsAsGood:(NSArray *)items {
    [self categorize:items as:POOL_NAME_GOOD];
}

@end
