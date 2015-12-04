//
//  RevView.m
//  Hops
//
//  Created by Jens Alfke on 5/7/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "RevView.h"
#import <CouchbaseLite/CouchbaseLite.h>


#define kCornerRadius 8.0

#define kBorderWidth 1.0
#define kLeafBorderWidth 2.0
#define kHighlightWidth 5.0
#define kLabelHeight 16


@implementation RevView
{
    BOOL _selected;
}


static NSColor *kLeafBGColor, *kDeletedBGColor, *kBGColor, *kMissingBGColor, *kBorderColor, *kShadowColor, *kHighlightColor;
static NSDictionary *kRevIDTextAttrs, *kUnsavedTextAttrs;
static NSFont* kRevIDFont;


+ (void)initialize
{
    if (self == [RevView class]) {
        kLeafBGColor = [NSColor lightGrayColor];
        kDeletedBGColor = kLeafBGColor;
        kBGColor = [NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0];
        kMissingBGColor = [NSColor colorWithCalibratedWhite: 0.9 alpha: 1.0];

        kBorderColor = [NSColor grayColor];
        kShadowColor = [[NSColor blackColor] colorWithAlphaComponent: 0.5];
        kHighlightColor = [NSColor orangeColor];

        kRevIDTextAttrs = @{NSFontAttributeName: [NSFont fontWithName: @"Monaco" size: 14],
                            NSForegroundColorAttributeName: [NSColor darkGrayColor]};
        kUnsavedTextAttrs = @{NSFontAttributeName: [NSFont fontWithName: @"Georgia-Italic" size: 14],
                              NSForegroundColorAttributeName: [NSColor grayColor]};
    }
}


- (instancetype) initWithRevision: (CBLRevision*)revision isLeaf: (BOOL)isLeaf {
    self = [super initWithFrame: NSMakeRect(0, 0, kRevWidth, kRevHeight)];
    if (self) {
        _revision = revision;
        _isLeaf = isLeaf;
    }
    return self;
}


- (void)drawRect: (NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    CGFloat borderWidth = 0;
    NSColor* bgColor;
    if (_revision.isDeletion) {
        // Tombstone:
        bgColor = kDeletedBGColor;
    } else if (_isLeaf) {
        // Leaf:
        bgColor = kLeafBGColor;
        if (![_revision isKindOfClass: [CBLUnsavedRevision class]])
            borderWidth = kLeafBorderWidth; // Draft
    } else if (_revision.properties != nil) {
        // Ancestor, still has properties:
        bgColor = kBGColor;
    } else {
        // Ancestor, compacted away:
        bgColor = kMissingBGColor;
        borderWidth = 1;
    }

    CGFloat pathInset = kHighlightWidth + borderWidth/2.0;
    NSRect bounds = NSInsetRect(self.bounds, pathInset, pathInset);
    NSBezierPath *path;
    path = [NSBezierPath bezierPathWithRoundedRect: bounds
                                           xRadius: kCornerRadius yRadius: kCornerRadius];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    if (_selected) {
        NSShadow* shadow = [[NSShadow alloc] init];
        shadow.shadowColor = _selected ? kHighlightColor : kShadowColor;
        shadow.shadowBlurRadius = kHighlightWidth;
        [shadow set];
    }
    if (_selected) {
        [path setLineWidth: borderWidth+2];
        [kHighlightColor setStroke];
        if (_revision.properties)
            [path stroke]; // just draws the shadow
    }

    [bgColor set];
    [path fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];

    // Draw deletion indicator:
    if (_revision.isDeletion) {
        NSBezierPath* line = [NSBezierPath new];
        [line moveToPoint: bounds.origin];
        [line lineToPoint: (NSPoint){NSMaxX(bounds), NSMaxY(bounds)}];
        [[NSColor whiteColor] set];
        line.lineWidth = 3.0;
        [line stroke];
    }

    // Draw text:
    NSRect labelRect, bodyRect;
    NSDivideRect(NSInsetRect(bounds, borderWidth/2.0, borderWidth/2.0),
                 &labelRect, &bodyRect, kLabelHeight, NSMaxYEdge);
    NSString* revID = _revision.revisionID;
    NSDictionary* textAttrs = kRevIDTextAttrs;
    if (!revID) {
        revID = @"unsaved";
        textAttrs = kUnsavedTextAttrs;
    }
    labelRect.origin.x += 4;
    labelRect.size.width -= 4;
    [revID drawWithRect: labelRect
                options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
             attributes: textAttrs];

    // Draw border:
    if (borderWidth > 0.0) {
        [kBorderColor setStroke];
        [path setLineWidth: borderWidth];
        if (!_revision.properties) {
            CGFloat dash[2] = {10.0, 10.0};
            [path setLineDash: dash count: 2 phase: 0];
            //[[NSColor grayColor] setStroke];
        }
        [path stroke];
    }
}


- (BOOL) selected {
    return _selected;
}

- (void) setSelected:(BOOL)selected {
    if (selected != _selected)
        [self setNeedsDisplay: YES];
    _selected = selected;
}


@end
