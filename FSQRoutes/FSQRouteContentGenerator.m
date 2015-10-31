//
//  FSQRouteContentGenerator.m
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

#import "FSQRouteContentGenerator.h"

#import "FSQRouteContent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FSQRouteContentGenerator

- (instancetype)init {
    return [self initWithBlock:^FSQRouteContent *_Nullable(FSQRouteUrlData *urlData) {
        return nil;
    }];
}

- (instancetype)initWithBlock:(FSQRoutesContentGeneratorBlock)generatorBlock {
    self = [super init];
    if (self) {
        self.generatorBlock = generatorBlock;
    }
    return self;
}

- (nullable FSQRouteContent *)generateRouteContentFromUrlData:(FSQRouteUrlData *)urlData {
    if (self.generatorBlock) {
        FSQRouteContent *routeContent = self.generatorBlock(urlData);
        routeContent.urlData = urlData;
        return routeContent;
    }
    return nil;
}

@end

NS_ASSUME_NONNULL_END