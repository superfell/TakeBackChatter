//
//  NSString_extras.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/30/11.
//

#import "NSString_extras.h"


@implementation NSString (NSString_extras)

-(NSAttributedString *)attributedString {
    return [NSAttributedString attributedStringWithString:self];
}

@end

@implementation NSAttributedString (NSAttributedString_extras)

+(id)attributedStringWithString:(NSString *)s {
    return [[[NSAttributedString alloc] initWithString:s] autorelease];
}

+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL {
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    
    // next make the text appear with an underline
    [attrString addAttribute:
     NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    
    [attrString endEditing];
    
    return [attrString autorelease];
}
@end

