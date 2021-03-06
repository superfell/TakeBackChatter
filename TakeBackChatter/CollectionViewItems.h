//
//  CollectionViewFeedItem.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/21/11.
//

#import <Foundation/Foundation.h>
#import "AMCollectionViewItem.h"

@interface CollectionViewFeedItem : AMCollectionViewItem {
    IBOutlet NSTextField *bodyTextField;
    IBOutlet NSImageView *actorPhoto;
    CGFloat               heightExtra;
}

-(IBAction)showContent:(id)sender;

@end


@interface CollectionViewLoadNewerItem : AMCollectionViewItem {
}

-(IBAction)loadNewer:(id)sender;
@end

@interface CollectionViewLoadOlderItem : AMCollectionViewItem {
}

-(IBAction)loadOlder:(id)sender;
@end

@interface CollectionViewPersonItem : AMCollectionViewItem {
}
@end