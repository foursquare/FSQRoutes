//
//  FSQRouteUrlData.h
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 The Url Data class wraps a url, parsed out parameters from that url, and remote/local notification info 
 into a single object to make them easier to pass around.
 */
@interface FSQRouteUrlData : NSObject
@property (nonatomic, strong, nullable) NSURL *url;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *>*parameters;
@property (nonatomic, strong, nullable) NSDictionary *notificationUserInfo;
@end

NS_ASSUME_NONNULL_END