//
//  AppDelegate.m
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import "AppDelegate.h"
#import "QueryController.h"
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
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSError* error;
    _db = [[CBLManager sharedInstance] databaseNamed: @"beer" error: &error];
    NSAssert(_db, @"Failed to create/open database: %@", error);

    NSURL* url = [NSURL URLWithString: kSyncDBURL];
    _pull = [_db createPullReplication: url];
    [_pull start];

    CBLView* nameView = [_db viewNamed: @"byName"];
    [nameView setMapBlock: MAPBLOCK({
        NSString* name = doc[@"name"];
        if (name)
            emit(name, nil);
    }) version: @"1"];

    self.beerListController = [[QueryController alloc] initWithQuery: [nameView createQuery]
                                                      modelClass: [Beer class]];
}


@end
