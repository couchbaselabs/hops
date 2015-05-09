//
//  RevTreeView.m
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "RevTreeView.h"
#import "RevView.h"
#import "DocHistory.h"
#import <CouchbaseLite/CouchbaseLite.h>
@import QuartzCore;


#define kNodeGapX 30
#define kNodeGapY 20


@interface RevTreeView ()
@end


@implementation RevTreeView
{
    CBLDocument* _cblDocument;
    CBLRevision* _selectedRev;
    CBLUnsavedRevision* _draftRevision;
    NSTreeNode* _rootNode;
    NSMutableArray* _arrows;
    NSSize _contentSize;
}


- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame: frame];
    if (self) {
        self.autoresizingMask = NSViewNotSizable;
    }
    return self;
}


#pragma mark - MODEL:


- (CBLDocument*) cblDocument {
    return _cblDocument;
}

- (void) setCblDocument:(CBLDocument *)cblDocument {
    if (cblDocument == _cblDocument)
        return;
    if (_cblDocument)
        [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: _cblDocument];
    _cblDocument = cblDocument;
    self.selectedRev = _cblDocument.currentRevision;
    _rootNode = _cblDocument ? GetDocRevisionTree(_cblDocument) : nil;
    [self rebuild];
    if (_cblDocument) {
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(docChanged:)
                                                     name: kCBLDocumentChangeNotification
                                                   object: _cblDocument];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(rebuild)
                                                     name: @"Compacted"
                                                   object: _cblDocument.database];
    }
}


- (void) docChanged: (NSNotification*)n {
    NSString* selectedRevID = _selectedRev.revisionID;
    _selectedRev = nil;
    _draftRevision = nil;
    _rootNode = GetDocRevisionTree(_cblDocument);
    [self rebuild];
    if (selectedRevID)
        self.selectedRev = _cblDocument.currentRevision;
}


- (CBLUnsavedRevision*) createDraftRevision {
    if (![_selectedRev isKindOfClass: [CBLSavedRevision class]])
        return nil;
    if (_draftRevision.parentRevision == _selectedRev)
        return _draftRevision;
    if (_draftRevision)
        [self removeDraftRevision];
    _draftRevision = [(CBLSavedRevision*)_selectedRev createRevision];
    if (!_draftRevision)
        return nil;
    NSTreeNode* node = [NSTreeNode treeNodeWithRepresentedObject: _draftRevision];
    NSTreeNode* parentNode = GetNodeForRevision(_rootNode, _selectedRev);
    [parentNode.mutableChildNodes addObject: node];
    self.selectedRev = _draftRevision;
    [self rebuild];
    [self scrollRectToVisible: [self viewForRevision: _draftRevision].frame];
    return _draftRevision;
}


- (void) removeDraftRevision {
    if (!_draftRevision)
        return;
    NSTreeNode* node = GetNodeForRevision(_rootNode, _draftRevision);
    NSTreeNode* parent = node.parentNode;
    [parent.mutableChildNodes removeObject: node];
    _draftRevision = nil;
    self.selectedRev = parent.representedObject;
    [self rebuild];
}


#pragma mark - DISPLAY:


- (void) drawRect:(NSRect)dirtyRect {
    // Draw the lines between revisions:
    NSBezierPath* path = [NSBezierPath new];
    for (NSArray* arrow in _arrows) {
        NSPoint p0 = [arrow[0] pointValue];
        NSPoint p1 = [arrow[1] pointValue];
        [path moveToPoint: p0];
        [path lineToPoint: p1];
    }
    path.lineWidth = 2;
    [[NSColor lightGrayColor] set];
    [path stroke];
}


- (CBLRevision*) selectedRev {
    return _selectedRev;
}

- (void) setSelectedRev:(CBLRevision *)selectedRev {
    if (selectedRev == _selectedRev)
        return;
    if (_selectedRev)
        [self viewForRevision: _selectedRev].selected = NO;
    _selectedRev = selectedRev;
    if (_selectedRev)
        [self viewForRevision: _selectedRev].selected = YES;
}


#pragma mark - LAYOUT:


- (void) rebuild {
    for (NSView* view in self.subviews.copy)
        if ([view isKindOfClass: [RevView class]])
            [view removeFromSuperview];

    _arrows = [NSMutableArray array];
    CGPoint origin = {kRevWidth/2,
                      (DepthOfTree(_rootNode)-1) * (kRevHeight + kNodeGapY) + kNodeGapY + kRevHeight/2};
    [self addBranch: _rootNode atPoint: origin];

    CGRect frame = NSZeroRect;
    for (RevView* view in self.subviews)
        if ([view isKindOfClass: [RevView class]])
            frame = CGRectUnion(frame, view.frame);
    _contentSize = frame.size;
    self.frameSize = _contentSize;
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay: YES];
}


- (NSSize) intrinsicContentSize {
    return _contentSize;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    // no-op
}

- (void) addBranch: (NSTreeNode*)node atPoint: (CGPoint)position {
    BOOL atRoot = (node == _rootNode);
    while (node) {
        [self addViewForRevision: node atPoint: position];
        NSArray* children = node.childNodes;
        CGPoint nextPos = {position.x, position.y - kRevHeight - kNodeGapY};
        CGPoint childPos = nextPos;
        for (int i = 1; i < children.count; i++) {
            childPos.x += kRevWidth + kNodeGapX;
            [self addBranch: children[i] atPoint: childPos];
            if (!atRoot)
                [_arrows addObject: @[ [NSValue valueWithPoint: position],
                                       [NSValue valueWithPoint: childPos] ]];
        }
        node = node.childNodes.firstObject;
        if (!atRoot && node)
            [_arrows addObject: @[ [NSValue valueWithPoint: position],
                                   [NSValue valueWithPoint: nextPos] ]];
        position = nextPos;
        atRoot = NO;
    }
}

- (RevView*) addViewForRevision: (NSTreeNode*)node atPoint: (CGPoint)position {
    if (node == _rootNode)
        return nil; // root node is invisible
    CBLSavedRevision* rev = node.representedObject;
    RevView* view = [[RevView alloc] initWithRevision: rev isLeaf: node.childNodes.count==0];
    NSRect frame = view.frame;
    frame.origin.x = round(position.x - frame.size.width/2.0);
    frame.origin.y = round(position.y - frame.size.height/2.0);
    view.frame = frame;
    view.selected = (rev == _selectedRev);

    [self addSubview: view];
    return view;
}


- (RevView*) viewForRevision: (CBLRevision*)rev {
    for (RevView* view in self.subviews) {
        if ([view isKindOfClass: [RevView class]] && view.revision == rev)
            return view;
    }
    return nil;
}


#pragma mark - ACTIONS:


- (void) mouseDown:(NSEvent *)event {
    RevView* hit = [self hitTestRevView: event];
    self.selectedRev = hit.revision;
}


- (RevView*) hitTestRevView: (NSEvent*)event {
    NSPoint where = [self convertPoint: event.locationInWindow fromView: nil];
    for (RevView* view in self.subviews) {
        if (NSPointInRect(where, view.frame) && [view isKindOfClass: [RevView class]])
            return view;
    }
    return nil;
}


@end
