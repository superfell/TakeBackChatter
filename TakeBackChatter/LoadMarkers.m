//
//  LoadMarkers.m
//  TakeBackChatter
//
//  Created by Simon Fell on 4/9/12.
//

#import "LoadMarkers.h"
#import "CollectionViewItems.h"

@implementation LoadNewer

-(id)initWithController:(NSObject<LoadNewerDelegate> *)c {
    self = [super init];
    controller = c;
    return self;
}

-(NSObject<LoadNewerDelegate> *)controller {
    return controller;
}

-(Class)classOfItemForCollectionView:(AMCollectionView *)cv {
    return [CollectionViewLoadNewerItem class];
}

@end

@implementation LoadOlder

-(id)initWithController:(NSObject<LoadOlderDelegate> *)c {
    self = [super init];
    controller = c;
    return self;
}

-(NSObject<LoadOlderDelegate> *)controller {
    return controller;
}

-(Class)classOfItemForCollectionView:(AMCollectionView *)cv {
    return [CollectionViewLoadOlderItem class];
}

@end