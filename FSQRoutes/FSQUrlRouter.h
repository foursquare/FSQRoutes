//
//  FSQUrlRouter.h
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

@import Foundation;

#import "FSQRouteContent.h"

NS_ASSUME_NONNULL_BEGIN

@class FSQRouteContentGenerator;
@class FSQRouteUrlData;
@protocol FSQUrlRouterDelegate;

@interface FSQUrlRouter : NSObject

@property (nonatomic, weak, nullable) id<FSQUrlRouterDelegate> delegate;
@property (nonatomic, copy, nullable) FSQRoutePresentation defaultRoutedUrlPresentation;

- (void)registerNativeSchemes:(NSArray<NSString *> *)schemes 
                  forRouteMap:(NSArray<NSArray *> *)map;
- (void)registerUniversalLinkHosts:(NSArray<NSString *> *)hosts 
                       forRouteMap:(NSArray<NSArray *> *)map;

- (BOOL)urlSchemeOrDomainIsRegistered:(NSURL *)url;

- (void)routeUrl:(NSURL *)url;
- (void)routeUrl:(NSURL *)url notificationUserInfo:(nullable NSDictionary *)notificationUserInfo;

- (void)handleDeferredRoute;
- (BOOL)hasDeferredRoute;
- (void)clearDeferredRoute;

- (nullable FSQRouteContent *)generateRouteContentFromUrl:(NSURL *)url;
- (nullable FSQRouteContent *)generateRouteContentFromUrl:(NSURL *)url 
                                     notificationUserInfo:(nullable NSDictionary *)notificationUserInfo;
@end

typedef NS_ENUM(NSInteger, FSQUrlRoutingControl) {
    FSQUrlRouterCancelRouting,
    FSQUrlRouterAllowRouting,
    FSQUrlRouterDeferRouting,
};

@protocol FSQUrlRouterDelegate <NSObject>

- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
       shouldGenerateRouteContent:(FSQRouteContentGenerator *)routeContentGenerator 
                      withUrlData:(FSQRouteUrlData *)urlData;

- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
               shouldPresentRoute:(FSQRouteContent *)routeContent;

- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlWillBePresented:(FSQRouteContent *)routeContent;
- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlDidGetPresented:(FSQRouteContent *)routeContent;

- (void)urlRouter:(FSQUrlRouter *)urlRouter failedToRouteUrl:(NSURL *)url notificationUserInfo:(nullable NSDictionary *)notificationUserInfo;
- (void)urlRouter:(FSQUrlRouter *)urlRouter failedToGenerateContent:(FSQRouteContentGenerator *)routeContentGenerator urlData:(FSQRouteUrlData *)urlData;

@end


NS_ASSUME_NONNULL_END