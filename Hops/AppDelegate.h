//
//  AppDelegate.h
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CBLDatabase, QueryController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly) CBLDatabase* db;

@property (readonly) QueryController* beerListController;

@end

