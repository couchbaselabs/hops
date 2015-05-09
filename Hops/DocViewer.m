//
//  DocViewer.m
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "DocViewer.h"
#import "RevTreeView.h"
#import <CouchbaseLite/CouchbaseLite.h>


@interface DocViewer ()
@end


@implementation DocViewer
{
    CBLDocument* _cblDocument;
    NSAttributedString* _draftJSON;

    IBOutlet NSSplitView* _splitView;
    IBOutlet NSTextView* _jsonView;
    IBOutlet NSButton *_editButton, *_saveButton, *_cancelButton;
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
    [_revTreeView addObserver: self forKeyPath: @"selectedRev" options: 0 context: NULL];

    _jsonView.font = [NSFont fontWithName: @"Menlo" size: 16.0];
    _jsonView.automaticQuoteSubstitutionEnabled = NO;
    [_jsonView.enclosingScrollView addSubview: _editButton];
    [_jsonView.enclosingScrollView addSubview: _saveButton];
    [_jsonView.enclosingScrollView addSubview: _cancelButton];
    _editButton.hidden = _saveButton.hidden = _cancelButton.hidden = YES;
    [self repositionSaveButton];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(repositionSaveButton)
                                                 name: NSViewFrameDidChangeNotification
                                               object: _saveButton.superview];
    [self updateJSON];
}


- (void) repositionSaveButton {
    NSView* parent = _saveButton.superview;
    NSRect parentBounds = parent.bounds;
    NSRect frame  = _saveButton.frame;
    frame.origin.x = NSMaxX(parentBounds) - frame.size.width - 16;
    frame.origin.y = NSMaxY(parentBounds) - frame.size.height - 16;
    _saveButton.frame = frame;
    _cancelButton.frame = NSOffsetRect(frame, -frame.size.width - 0, 0);

    frame.origin.x = 16;
    frame.size.width = _editButton.frame.size.width;
    _editButton.frame = frame;
}


- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview: (NSView *)view {
    return [splitView.subviews indexOfObject: view] != 0;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition
         ofSubviewAt:(NSInteger)dividerIndex
{
    return MAX(proposedMinimumPosition, 125.0);
}


- (CBLDocument*) cblDocument {
    return _cblDocument;
}


- (void) setCblDocument:(CBLDocument *)cblDocument {
    _draftJSON = nil;
    _revTreeView.cblDocument = cblDocument;
    _cblDocument = cblDocument;
}


- (void) updateJSON {
    CBLRevision* rev = _revTreeView.selectedRev;
    BOOL isDraft = [rev isKindOfClass: [CBLUnsavedRevision class]];
    NSLog(@"updateJSON -- rev = %@", rev);

    NSAttributedString* json = nil;
    if (rev) {
        if ([rev isKindOfClass: [CBLUnsavedRevision class]] && _draftJSON != nil) {
            json = _draftJSON;
        } else {
            NSDictionary* props = rev.properties;
            if (props)
                json = [self prettyPrintJSON: props
                                  previously: rev.parentRevision.properties];
        }
    }
    if (!json)
        json = [NSAttributedString new];
    [_jsonView.textStorage setAttributedString: json];
    _jsonView.editable = isDraft;
    _saveButton.hidden = _cancelButton.hidden = !isDraft;
    _editButton.hidden = (rev == nil || isDraft);
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == _revTreeView) {
        [self updateJSON];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}



- (NSAttributedString*) prettyPrintJSON: (NSDictionary*)properties
                             previously: (NSDictionary*)oldProperties
{
    NSMutableArray* keys = [properties.allKeys mutableCopy];
    if (oldProperties) {
        [keys addObjectsFromArray: oldProperties.allKeys];
        keys = [[[NSSet setWithArray: keys] allObjects] mutableCopy];
    }
//    [keys removeObject: @"_id"];
//    [keys removeObject: @"_rev"];
    [keys sortUsingComparator: ^NSComparisonResult(NSString* s1, NSString* s2) {
        int n = [s2 hasPrefix: @"_"] - [s1 hasPrefix: @"_"];
        if (n != 0)
            return n; // underscored properties come first
        return [s1 compare: s2 options: NSLiteralSearch];
    }];
    NSUInteger maxKeyLen = 0;
    for (NSString* key in keys)
        maxKeyLen = MAX(maxKeyLen, key.length);
    NSMutableAttributedString* output = [[NSMutableAttributedString alloc] initWithString: @"{\n"];
    NSUInteger i = 0;
    for (NSString* key in keys) {
        NSUInteger lineStart = output.length;
        [output.mutableString appendFormat: @"    \"%@\":  ", key];
        [output addAttribute: NSForegroundColorAttributeName
                       value: [NSColor grayColor]
                       range: NSMakeRange(lineStart, output.length-2-lineStart)];

        for (NSUInteger i=key.length; i<maxKeyLen; i++)
            [output.mutableString appendString: @" "];
        id value = properties[key] ?: oldProperties[key];
        NSData* data = [CBLJSON dataWithJSONObject: value
                                           options: CBLJSONWritingAllowFragments
                                             error: NULL];
        NSString* json = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        NSRange valueRange = {output.length, 0};
        [output.mutableString appendString: json];
        valueRange.length = output.length - valueRange.location;

        if (++i < keys.count)
            [output.mutableString appendString: @",\n"];
        else
            [output.mutableString appendString: @"\n"];

        if (oldProperties && ![key isEqualToString: @"_rev"]
                          && ![properties[key] isEqual: oldProperties[key]]) {
            NSRange lineRange = NSMakeRange(lineStart, output.length-1-lineStart);
            if (!properties[key]) {
                [output addAttribute: NSStrikethroughStyleAttributeName
                               value: @(NSUnderlineStyleSingle)
                               range: lineRange];
                [output addAttribute: NSForegroundColorAttributeName
                               value: [NSColor redColor]
                               range: lineRange];
            } else if (!oldProperties[key]) {
                [output addAttribute: NSUnderlineStyleAttributeName
                               value: @(NSUnderlineStyleSingle)
                               range: lineRange];
                [output addAttribute: NSForegroundColorAttributeName
                               value: [NSColor greenColor]
                               range: lineRange];
            } else {
                [output addAttribute: NSBackgroundColorAttributeName
                               value: [NSColor yellowColor]
                               range: valueRange];
            }
        }
    }
    [output.mutableString appendString: @"}"];

    NSMutableParagraphStyle* paraStyle = [NSMutableParagraphStyle new];
    paraStyle.headIndent = 72.0;
    paraStyle.firstLineHeadIndent = 0.0;
    paraStyle.tailIndent = -0.25;

    [output addAttribute: NSFontAttributeName
                   value: _jsonView.font
                   range: NSMakeRange(0, output.length)];
    [output addAttribute: NSParagraphStyleAttributeName
                   value: paraStyle
                   range: NSMakeRange(0, output.length)];
    return output;
}


- (void)textDidChange: (NSNotification*)n {
    _draftJSON = [_jsonView.textStorage copy];
}


- (IBAction) createDraftRevision: (id)sender {
    [_revTreeView createDraftRevision];
    _draftJSON = [_jsonView.textStorage copy];
    _saveButton.hidden = _cancelButton.hidden = NO;
    _editButton.hidden = YES;
    _editButton.enabled = NO;
}


- (IBAction) saveChanges:(id)sender {
    CBLUnsavedRevision* draft = (CBLUnsavedRevision*) _revTreeView.selectedRev;
    if (![draft isKindOfClass: [CBLUnsavedRevision class]]) {
        NSBeep();
        return;
    }
    // Parse JSON:
    NSDictionary* oldProps = draft.parentRevision.properties;
    NSMutableDictionary* props;
    NSData* text = [_jsonView.string dataUsingEncoding: NSUTF8StringEncoding];
    if (text.length > 0) {
        NSError* error;
        props = [CBLJSON JSONObjectWithData: text
                                    options: NSJSONReadingMutableContainers
                                      error: &error];
        if (!props) {
            NSAlert* alert = [NSAlert new];
            alert.messageText = @"Sorry, that's not valid JSON :(";
            alert.informativeText = error.userInfo[@"NSDebugDescription"];
            [alert beginSheetModalForWindow: self.window completionHandler: nil];
            return;
        }
    } else {
        props = [@{@"_id": oldProps[@"_id"],
                   @"_rev": oldProps[@"_rev"],
                   @"_deleted":@YES} mutableCopy];
    }

    // Update revision:
    if ([props isEqual: oldProps]) {
        [self cancelChanges: self];
        return;
    }
    NSLog(@"Saving: %@", props);
    draft.properties = props;

    // Save:
    NSError* error;
    CBLSavedRevision* saved = [draft saveAllowingConflict: &error];
    if (!saved) {
        NSAlert* alert = [NSAlert new];
        alert.messageText = @"Couldn’t save revision";
        alert.informativeText = error.localizedDescription;
        [alert beginSheetModalForWindow: self.window completionHandler: nil];
        return;
    }
    _draftJSON = nil;
    _editButton.enabled = YES;
    _revTreeView.selectedRev = saved;
}


- (IBAction) cancelChanges:(id)sender {
    _draftJSON = nil;
    _editButton.enabled = YES;
    [_revTreeView removeDraftRevision];
}


@end
