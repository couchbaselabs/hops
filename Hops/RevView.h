//
//  RevView.h
//  Hops
//
//  Created by Jens Alfke on 5/7/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CBLRevision;


#define kRevWidth 100
#define kRevHeight 75


@interface RevView : NSView

- (instancetype) initWithRevision: (CBLRevision*)revision isLeaf: (BOOL)isLeaf;

@property (readonly) CBLRevision* revision;
@property (readonly) BOOL isLeaf;

@property BOOL selected;

@end
