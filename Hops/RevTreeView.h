//
//  RevTreeView.h
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CBLDocument, CBLRevision, CBLUnsavedRevision;


@interface RevTreeView : NSView

@property CBLDocument* cblDocument;

@property CBLRevision* selectedRev;

- (CBLUnsavedRevision*) createDraftRevision;
- (void) removeDraftRevision;

@end
