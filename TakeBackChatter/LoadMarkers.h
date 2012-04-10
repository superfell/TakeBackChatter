//
//  LoadMarkers.h
//  TakeBackChatter
//
//  Created by Simon Fell on 4/9/12.
//

#import <Foundation/Foundation.h>
#import "CollectionViews.h"

@protocol LoadNewerDelegate <NSObject>
-(IBAction)loadNewerRows:(id)sender;
@end

@protocol LoadOlderDelegate <NSObject>
-(IBAction)loadOlderRows:(id)sender;
@end

@interface LoadNewer : NSObject<CollectionViewItemType> {
    NSObject<LoadNewerDelegate> *controller; // weak ref
}
-(id)initWithController:(NSObject<LoadNewerDelegate> *)c;
-(NSObject<LoadNewerDelegate> *)controller;
@end

@interface LoadOlder : NSObject<CollectionViewItemType> {
    NSObject<LoadOlderDelegate> *controller; // weak ref
}
-(id)initWithController:(NSObject<LoadOlderDelegate> *)c;
-(NSObject<LoadOlderDelegate> *)controller;
@end