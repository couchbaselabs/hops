//
//  Beer.h
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>

/** Trivial CBLModel for the beer database. */
@interface Beer : CBLModel

@property NSString *name, *brewery, *category, *style;
@property NSDate* updated;
@property float abv;

/** This is the "description" property in the docs, renamed here to avoid conflicting with the
    inherited NSObject.description property. */
@property NSString* blurb;

@end
