//
//  RevTreeView.m
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "RevTreeView.h"
#import "DocHistory.h"
#import <CouchbaseLite/CouchbaseLite.h>
@import QuartzCore;


#define kNodeWidth 100
#define kNodeHeight 75

#define kNodeGapX 50
#define kNodeGapY 20


@implementation RevTreeView
{
    CBLDocument* _cblDocument;
    NSTreeNode* _rootNode;
    NSMutableArray* _arrows;
    CALayer* _selectedLayer;
}


static CGColorRef kBGColor, kDeletedBGColor, kAncestorBGColor, kBorderColor;
static NSFont* kRevIDFont;

+ (void)initialize {
    if (self == [RevTreeView class]) {
        kBGColor = CGColorCreateGenericRGB(0.667, 1.000, 0.656, 1.000);
        kDeletedBGColor = CGColorCreateGenericRGB(0.667, 1.000, 0.656, 1.000);
        kAncestorBGColor = CGColorCreateGenericRGB(0.884, 0.936, 0.882, 1.000);
        kBorderColor = CGColorRetain([NSColor darkGrayColor].CGColor);
        kRevIDFont = [NSFont fontWithName: @"Monaco" size: 1];
    }
}


- (CBLDocument*) cblDocument {
    return _cblDocument;
}

- (void) setCblDocument:(CBLDocument *)cblDocument {
    if (cblDocument == _cblDocument)
        return;
    _cblDocument = cblDocument;
    _rootNode = GetDocRevisionTree(_cblDocument);
    [self rebuild];
}


- (void) drawRect:(NSRect)dirtyRect {
    NSBezierPath* path = [NSBezierPath new];
    for (NSArray* arrow in _arrows) {
        NSPoint p0 = [arrow[0] pointValue];
        NSPoint p1 = [arrow[1] pointValue];
        [path moveToPoint: p0];
        [path lineToPoint: p1];
    }
    path.lineWidth = 2;
    [[NSColor blackColor] set];
    [path stroke];
}


- (void) rebuild {
    self.autoresizingMask = NSViewNotSizable;
    _selectedLayer = nil;
    CALayer* root = self.layer;
    for (CALayer* layer in root.sublayers.copy)
        [layer removeFromSuperlayer];
    root.backgroundColor = [NSColor whiteColor].CGColor;

    _arrows = [NSMutableArray array];
    CGPoint origin = {kNodeGapX + kNodeWidth/2,
                      (DepthOfTree(_rootNode)-1) * (kNodeHeight + kNodeGapY) + kNodeGapY + kNodeHeight/2};
    [self addBranch: _rootNode atPoint: origin];

    CGRect frame = NSZeroRect;
    for (CALayer* layer in root.sublayers)
        frame = CGRectUnion(frame, layer.frame);
    [self setFrame: NSInsetRect(frame, -kNodeGapX, -kNodeGapY)];
    [self setNeedsDisplay: YES];
}

- (void) resizeWithOldSuperviewSize:(NSSize)oldSize {
    // ignore this call; for some reason the NSView implementation resizes me to (0,0)
}

- (void) addBranch: (NSTreeNode*)node atPoint: (CGPoint)position {
    BOOL atRoot = (node == _rootNode);
    while (node) {
        [self addLayerForRevision: node atPoint: position];
        NSArray* children = node.childNodes;
        CGPoint nextPos = {position.x, position.y - kNodeHeight - kNodeGapY};
        CGPoint childPos = nextPos;
        for (int i = 1; i < children.count; i++) {
            childPos.x += kNodeWidth + kNodeGapX;
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

- (CALayer*) addLayerForRevision: (NSTreeNode*)node atPoint: (CGPoint)position {
    if (node == _rootNode)
        return nil; // root node is invisible
    CBLSavedRevision* rev = node.representedObject;
    NSLog(@"Adding rev layer for %@ at (%g, %g)", rev.revisionID, position.x, position.y);
    CALayer* layer = [[CALayer alloc] init];
    layer.bounds = CGRectMake(0, 0, kNodeWidth, kNodeHeight);
    layer.position = position;
    if (node.childNodes.count > 0)
        layer.backgroundColor = kAncestorBGColor;
    else
        layer.backgroundColor = rev.isDeletion ? kDeletedBGColor : kBGColor;
    layer.borderColor = kBorderColor;
    layer.borderWidth = (node.childNodes.count == 0) ? 2 : 1;
    layer.cornerRadius = 8.0;
    layer.delegate = self;
    [layer setValue: node forKey: @"treeNode"];

    CATextLayer* label = [[CATextLayer alloc] init];
    label.font = (__bridge CFTypeRef)(kRevIDFont);
    label.fontSize = 16.0;
    label.foregroundColor = [NSColor blackColor].CGColor;
    label.string = rev.revisionID;
    label.frame = NSInsetRect(layer.bounds, 6, 6);
    [layer addSublayer: label];

    [self.layer addSublayer: layer];
    return layer;
}


#pragma mark - ACTIONS:


- (void) mouseDown:(NSEvent *)event {
    CALayer* hit = [self hitTestNode: event];
    if (hit != _selectedLayer) {
        _selectedLayer.shadowOpacity = 0.0;
        _selectedLayer = hit;
        _selectedLayer.shadowOpacity = 1.0;
        _selectedLayer.shadowOffset = CGSizeMake(0, 0);
        _selectedLayer.shadowColor = [NSColor orangeColor].CGColor;
        _selectedLayer.shadowRadius = 6.0;
    }
}


- (CALayer*) hitTestNode: (NSEvent*)event {
    NSPoint where = [self convertPoint: event.locationInWindow fromView: nil];
    for (CALayer* layer in self.layer.sublayers) {
        if (NSPointInRect(where, layer.frame))
            return layer;
    }
    return nil;
}


@end
