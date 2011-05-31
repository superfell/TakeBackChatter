//
//  NSString_extras.h
//  TakeBackChatter
//
//  Created by Simon Fell on 5/30/11.
//

#import <Foundation/Foundation.h>


@interface NSString (NSString_extras)
-(NSAttributedString *)attributedString;
@end

@interface NSAttributedString (NSAttributedString_extras)
+(id)attributedStringWithString:(NSString *)s;
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end