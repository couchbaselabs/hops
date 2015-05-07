//
//  AppDelegate.m
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "AppDelegate.h"
#import "QueryController.h"
#import "DocViewer.h"
#import "Beer.h"
@import CouchbaseLite;


#define kSyncDBURL @"http://localhost:4984/beer"


@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (readwrite) QueryController* beerListController;
@end


@implementation AppDelegate
{
    CBLReplication *_push, *_pull;
    DocViewer* _docViewer;

    IBOutlet NSArrayController* _beerListArrayController;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSError* error;
    _db = [[CBLManager sharedInstance] databaseNamed: @"beer" error: &error];
    NSAssert(_db, @"Failed to create/open database: %@", error);

//    NSURL* url = [NSURL URLWithString: kSyncDBURL];
//    _pull = [_db createPullReplication: url];
//    [_pull start];
//    _push = [_db createPushReplication: url];
//    [_push start];

    //[self fixDocs: self];

    CBLView* nameView = [_db viewNamed: @"byName"];
    [nameView setMapBlock: MAPBLOCK({
        NSString* name = doc[@"name"];
        if (name)
            emit(name, nil);
    }) version: @"1"];

    _docViewer = [[DocViewer alloc] init];
    [_docViewer showWindow: self];

    self.beerListController = [[QueryController alloc] initWithQuery: [nameView createQuery]
                                                          modelClass: [Beer class]];
    [_beerListArrayController addObserver: self forKeyPath: @"selection" options: 0 context: NULL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _beerListArrayController) {
        _docViewer.cblDocument = [_beerListArrayController.selectedObjects.firstObject document];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (BOOL) online {
    return _pull != nil;
}

- (void) setOnline: (BOOL)online {
    if (!online && _pull) {
        NSLog(@"Stopping replications");
        [_pull stop];
        _pull = nil;
        [_push stop];
        _push = nil;
    } else if (online && !_pull) {
        NSLog(@"Starting replications");
        NSURL* url = [NSURL URLWithString: kSyncDBURL];
        _pull = [_db createPullReplication: url];
        [_pull start];
        _push = [_db createPushReplication: url];
        [_push start];
    }
}


- (IBAction) toggleOnline: (id)sender {
    self.online = !self.online;
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = menuItem.action;
    if (action == @selector(toggleOnline:)) {
        menuItem.title = self.online ? @"Go Offline" : @"Go Online";
        return YES;
    } else {
        return YES;
    }
}


#if 0
static void fixEncoding(NSMutableDictionary* doc, NSString* key) {
    NSString* value = doc[key];
    if (!value)
        return;
    NSString* newValue = [value stringByReplacingOccurrencesOfString: @"â" withString: @"’"];
#if 0
    NSData* raw = [value dataUsingEncoding: NSWindowsCP1252StringEncoding];
    if (!raw)
        return;
    NSString* newValue = [[NSString alloc] initWithData: raw encoding: NSUTF8StringEncoding];
#endif
    if (!newValue)
        return;
    if (![newValue isEqualToString: value]) {
        NSLog(@"%@  -->  %@", value, newValue);
        doc[key] = newValue;
    }
}


- (IBAction) fixDocs: (id)sender {
    CBLQuery* q = [_db createAllDocumentsQuery];
    for (CBLQueryRow* row in [q run: NULL]) {
        CBLDocument*doc = row.document;
        NSMutableDictionary* mdoc = [doc.properties mutableCopy];
        id abv = mdoc[@"abv"];
        // Convert "abv" prop from string to number:
        if ([abv isKindOfClass: [NSString class]]) {
            double n = [abv doubleValue];
            if (n > 0.0)
                mdoc[@"abv"] = @(n);
        }
        if (![mdoc isEqual: doc.properties]) {
            NSError* error;
            NSAssert([row.document putProperties: mdoc error: &error], @"couldn't save: %@", error);
            NSLog(@"Fixed %@", mdoc[@"name"]);
        }
    }
}
#endif

@end
