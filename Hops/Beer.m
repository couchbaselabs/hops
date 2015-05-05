//
//  Beer.m
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "Beer.h"

@implementation Beer

@dynamic name, brewery, category, style, updated, abv;

- (NSString*) blurb {
    return [self getValueOfProperty: @"description"];
}

- (void) setBlurb:(NSString *)blurb {
    [self setValue: blurb ofProperty: @"description"];
}

- (void) markNeedsSave {
    NSLog(@"Document changed: %@ [%@]", self.name, self.document.documentID);
    [super markNeedsSave];
}

@end
