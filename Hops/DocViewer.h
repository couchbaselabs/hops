//
//  DocViewer.h
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CBLDocument;


@interface DocViewer : NSWindowController

@property CBLDocument* cblDocument;

@end
