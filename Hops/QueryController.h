//
//  QueryController.h
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

#import <Foundation/Foundation.h>
@class CBLQuery;


/** Simple controller for Couchbase Lite demo apps.
    This class acts as glue between a CBLQuery (a CouchbaseLite view) and an NSArrayController.
    The app can then bind its UI controls to the NSArrayController and get basic CRUD operations
    without needing any code. */
@interface QueryController : NSObject

- (instancetype) initWithQuery: (CBLQuery*)query
                    modelClass: (Class)modelClass;

/** The documents returned by the query, wrapped in model objects.
    An NSArrayController's "content" property can be bound to this property.
    If the array controller will be creating new objects, its object class should be set to
    the same modelClass used by the QueryController. */
@property (readonly) NSMutableArray* entries;

@end
