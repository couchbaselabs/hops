//
//  QueryController.m
//  Hops
//
//  Created by Jens Alfke on 6/1/11.
//  Copyright (c) 2011-2015 Couchbase, Inc, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
//  except in compliance with the License. You may obtain a copy of the License at
//    http://www.apache.org/licenses/LICENSE-2.0
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.

#import "QueryController.h"
#import <CouchbaseLite/CouchbaseLite.h>


@implementation QueryController
{
    CBLLiveQuery* _query;
    NSMutableArray* _rows;
    Class _modelClass;
}


- (instancetype) initWithQuery: (CBLQuery*)query modelClass: (Class)modelClass {
    NSParameterAssert(query);
    self = [super init];
    if (self != nil) {
        _modelClass = modelClass;
        _query = [query asLiveQuery];
        [_query addObserver: self forKeyPath: @"rows"
                    options: NSKeyValueObservingOptionInitial context: NULL];
    }
    return self;
}


- (void) dealloc {
    [_query removeObserver: self forKeyPath: @"rows"];
}


- (void) loadEntries {
    NSArray* allRows = _query.rows.allObjects ?: @[];
    NSMutableArray* newRows = [allRows mutableCopy];
    NSLog(@"Reloading %lu rows from sequence #%lu...",
          (unsigned long)allRows.count, (unsigned long)_query.rows.sequenceNumber);

    // Preserve new/unsaved model objects from the previous row set:
    for (id item in _rows) {
        if ([item isKindOfClass: [CBLModel class]] && ((CBLModel*)item).isNew)
            [newRows addObject: item];
    }

    [self willChangeValueForKey: @"entries"];
    _rows = newRows;
    [self didChangeValueForKey: @"entries"];
}


- (void)observeValueForKeyPath: (NSString*)keyPath ofObject: (id)object
                        change: (NSDictionary*)change context: (void*)context
{
    if (object == _query)
        [self loadEntries];
}


#pragma mark -
#pragma mark ENTRIES PROPERTY:


// These are the key-value coding (KVC) methods to implement an array-valued "entry" property.
// Doing it this way allows us to lazily instantiate the model objects from the query rows.


@dynamic entries;


- (NSUInteger) countOfEntries {
    return _rows.count;
}


- (CBLModel*)objectInEntriesAtIndex: (NSUInteger)index {
    id entry = _rows[index];
    if ([entry isKindOfClass: [CBLModel class]]) {
        return entry;
    } else {
        CBLQueryRow* row = entry;
        CBLModel* model = [_modelClass modelForDocument: row.document];
        return model;
    }
}


- (void) insertObject: (CBLModel*)object inEntriesAtIndex: (NSUInteger)index {
    NSParameterAssert([object isKindOfClass: [CBLModel class]]);
    [_rows insertObject: object atIndex: index];
    object.autosaves = YES;
    object.database = _query.database;
}


- (void) removeObjectFromEntriesAtIndex: (NSUInteger)index {
    id entry = _rows[index];
    if ([entry isKindOfClass: [CBLModel class]])
        ((CBLModel*)entry).database = nil;
    [_rows removeObjectAtIndex: index];
}


@end
