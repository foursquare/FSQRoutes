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

- (instancetype)initWithDelegate:(id<FSQUrlRouterDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void)registerNativeSchemes:(NSArray<NSString *> *)schemes 
                  forRouteMap:(NSArray<NSArray *> *)map;
- (void)registerUniversalLinkHosts:(NSArray<NSString *> *)hosts 
                       forRouteMap:(NSArray<NSArray *> *)map;

/**
 Check if a url matches any of the currently registered route map schemes/hosts.
 
 @param url The url to check.
 
 @return YES if the scheme (for native links) or host (for universal links) of the url matches any registered
 route map. 
 
 @note This does not tell you if the url will actually match to a route, just whether or not its scheme/host 
 is registered.
 */
- (BOOL)urlSchemeOrDomainIsRegistered:(NSURL *)url;

/**
 Matches the given url against the registered route maps. If there is a match, the url will be routed using
 the matching route content generator.
 
 This is a convenience method for calling `routeUrl:notificationUserInfo:` with the notification dictionary set to nil. 
 
 @param url The url to route.
 */
- (void)routeUrl:(NSURL *)url;

/**
 Matches the given url against the registered route maps. If there is a match, the url will be routed using
 the matching route content generator.
 
 @param url                  The url to route
 @param notificationUserInfo The userInfo dictionary of the notification (if the route was triggered by a local or 
 remote notification). This userInfo is passed through to the route content and content generator.
 */
- (void)routeUrl:(NSURL *)url notificationUserInfo:(nullable NSDictionary *)notificationUserInfo;

/**
 Similar to `routeUrl:notificationUserInfo:` except instead of matching the url against the registered route maps,
 it is just immediately routed using the supplied generator.
 
 @param url                  The url to route.
 @param notificationUserInfo The userInfo dictionary of the triggering notification (if any).
 @param generator            The generator to use to route the URL (instead of matching the url against the registered
 route maps).
 */
- (void)routeUrl:(NSURL *)url 
notificationUserInfo:(nullable NSDictionary *)notificationUserInfo 
  usingGenerator:(FSQRouteContentGenerator *)generator;

/**
 Used to check if the router currently is holding on to a deferred route.
 
 Routing can be deferred by the `urlRouter:shouldGenerateRouteContent:withUrlData:` and/or 
 `urlRouter:shouldPresentRoute:` delegate methods. See those methods for more information on deferring.
 
 The router can only hold on to one deferred route at a time. If a second route is deferred, the first is dropped.
 
 @return YES if the router currently has a deferred route, NO otherwise.
 */
- (BOOL)hasDeferredRoute;

/**
 If your delegate ever defers routes, it should call this method whenever it wants the router to try routing its
 deferred route again. This will cause a re-attempt of the deferred route, with the same delegate callbacks.
 
 The router can only hold on to one deferred route at a time. If a second route is deferred, the first is dropped.
 
 @note The route can immediately be re-deferred by the delegate.
 */
- (void)handleDeferredRoute;

/**
 This removes the deferred route currently being held by the router (if any).
 */
- (void)clearDeferredRoute;

/**
 This generates a route content object by matching the given url against the registered route map.
 
 Generating a route content using this method will not actually "route" the object, meaning no delegate callbacks
 are sent, the default routed url presentation is not set, and the content object is not presented.
 
 This is a convenience method for calling `generateRouteContentFromUrl:notificationUserInfo:` with the notification 
 dictionary set to nil. 
 
 @param url The url for which you want to generate a route content object from.
 
 @return A new FSQRouteContent object if the url matched a registered route map.
 */
- (nullable FSQRouteContent *)generateRouteContentFromUrl:(NSURL *)url;

/**
 This generates a route content object by matching the given url against the registered route map.
 
 Generating a route content using this method will not actually "route" the object, meaning no delegate callbacks
 are sent and the content object is not presented.
 
 @param url                  The url for which you want to generate a route content object from.
 @param notificationUserInfo The notification userInfo dictionary to attach to the content/generators url data.
 
 @return A new FSQRouteContent object if the url matched a registered route map.
 */
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

- (UIViewController *)urlRouter:(FSQUrlRouter *)urlRouter viewControllerToPresentRoutedUrlFrom:(FSQRouteContent *)routeContent;

/**
 This delegate method will get called whenever a routed url is about to go on screen.
 
 !! You MUST call the completion handler or your route will get dropped !!
 
 You can use this callback to do any setup that is needed before the route is presented (eg dismiss existing modals)
 
 @param urlRouter         The router about to present the route
 @param routeContent      The route content that is going to be presented
 @param completionHandler A completion handler that you must call when any work you need to do is finished. 
 Execution of this block does the actual presentation asynchronously on the main thread.

 */
- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlWillBePresented:(FSQRouteContent *)routeContent completionHandler:(void (^)())completionHandler;
- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlDidGetPresented:(FSQRouteContent *)routeContent;

- (void)urlRouter:(FSQUrlRouter *)urlRouter failedToRouteUrl:(NSURL *)url notificationUserInfo:(nullable NSDictionary *)notificationUserInfo;
- (void)urlRouter:(FSQUrlRouter *)urlRouter failedToGenerateContent:(FSQRouteContentGenerator *)routeContentGenerator urlData:(FSQRouteUrlData *)urlData;

@end


NS_ASSUME_NONNULL_END