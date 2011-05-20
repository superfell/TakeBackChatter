//
//  NSDate_iso8601.m
//  TakeBackChatter
//
//  Created by Simon Fell on 5/19/11.
//

#import "NSDate_iso8601.h"


@implementation NSDate (NSDate_iso8601)

static NSDateFormatter *dateTimeFormatter;

+(void)initialize {
	dateTimeFormatter = [[NSDateFormatter alloc] init];
	[dateTimeFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSZ"];
}

-(NSString *)iso8601formatted {
    NSMutableString *dt = [NSMutableString stringWithString:[dateTimeFormatter stringFromDate:self]];
	// meh, insert the : in the TZ offset, to make it xsd:dateTime
	[dt insertString:@":" atIndex:[dt length]-2];
    return dt;
}

@end
