//
//  FSQRouteContentGenerator.h
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class FSQRouteContent;
@class FSQRouteUrlData;

/**
 This block type takes in a url data object and returns a new route content object for that data (if any).
 
 @param urlData Incoming url data to generate the content from.
 
 @return A new FSQRouteContent object for the given url data.
 */
typedef FSQRouteContent *_Nullable(^FSQRoutesContentGeneratorBlock)(FSQRouteUrlData *urlData);

/**
 The Route Content Generator class takes a url data object and generates a new route content object from it.
 
 Generally each of these is paired to one or more route strings in a route map on FSQUrlRouter. When a url
 matching the string is routed, the paired generator is used to create the content.
 
 The main functionality of the class is contained in its generatorBlock property. The class is mainlly a wrapper
 to allow for subclassing/category methods by users of this framework.
 */
@interface FSQRouteContentGenerator : NSObject

/**
 This block contains all the logic for generating new content objects from url data.
 
 Returning nil from this block will cancel the routing.
 */
@property (nonatomic, copy) FSQRoutesContentGeneratorBlock generatorBlock;

/**
 This is the designated initializer for the class. You must provide a generatorBlock for all
 FSQRouteContentGenerator instances.
 
 @param generatorBlock The generator block for this instance.
 
 @return An initialized generator object with the passed in block.
 */
- (instancetype)initWithBlock:(FSQRoutesContentGeneratorBlock)generatorBlock NS_DESIGNATED_INITIALIZER; 

/**
 This method is used to actually create content objects and should be used instead of directly
 calling the block property.
 
 @param urlData The url data for which you wish to generate a new content object.
 
 @return A new FSQRouteContent object.
 */
- (nullable FSQRouteContent *)generateRouteContentFromUrlData:(FSQRouteUrlData *)urlData;

@end

NS_ASSUME_NONNULL_END