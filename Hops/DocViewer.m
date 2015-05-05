//
//  DocViewer.m
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "DocViewer.h"
#import "RevTreeView.h"


@interface DocViewer ()
@end


@implementation DocViewer
{
    CBLDocument* _cblDocument;

    IBOutlet RevTreeView* _revTreeView;
}


- (instancetype)init
{
    self = [super initWithWindowNibName: @"DocViewer"];
    if (self) {

    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    _revTreeView.cblDocument = _cblDocument;
}


- (CBLDocument*) cblDocument {
    return _cblDocument;
}


- (void) setCblDocument:(CBLDocument *)cblDocument {
    _revTreeView.cblDocument = cblDocument;
    _cblDocument = cblDocument;
}


@end
