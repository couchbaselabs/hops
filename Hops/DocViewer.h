//
//  DocViewer.h
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CBLDocument, RevTreeView;


@interface DocViewer : NSWindowController

@property CBLDocument* cblDocument;

@property RevTreeView* revTreeView;

@end
