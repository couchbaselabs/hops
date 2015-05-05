//
//  Beer.h
//  Hops
//
//  Created by Jens Alfke on 5/4/15.
//  Copyright (c) 2015 Couchbase. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>

@interface Beer : CBLModel

@property NSString *name, *brewery, *category, *style;
@property NSDate* updated;
@property float abv;

@property NSString* blurb;

@end
