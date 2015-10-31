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

typedef FSQRouteContent *_Nullable(^FSQRoutesContentGeneratorBlock)(FSQRouteUrlData *urlData);

@interface FSQRouteContentGenerator : NSObject

@property (nonatomic, copy) FSQRoutesContentGeneratorBlock generatorBlock;

- (instancetype)initWithBlock:(FSQRoutesContentGeneratorBlock)generatorBlock NS_DESIGNATED_INITIALIZER; 

- (nullable FSQRouteContent *)generateRouteContentFromUrlData:(FSQRouteUrlData *)urlData;

@end

NS_ASSUME_NONNULL_END