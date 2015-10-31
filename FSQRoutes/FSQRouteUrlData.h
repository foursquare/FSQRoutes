//
//  FSQRouteUrlData.h
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface FSQRouteUrlData : NSObject
@property (nonatomic, nullable) NSURL *url;
@property (nonatomic, nullable) NSDictionary<NSString *, NSString *>*parameters;
@property (nonatomic, nullable) NSDictionary *notificationUserInfo;
@end

NS_ASSUME_NONNULL_END