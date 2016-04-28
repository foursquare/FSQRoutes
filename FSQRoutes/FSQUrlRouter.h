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

/**
 The Url Router class takes in url objects that are sent to your app, matches them against a preset mapping that
 you configure at launch time, and then takes the relevant action that corresponds to that url in the map
 (usually pushing a new view controller).
 
 Your app delegate should instantiate a url router, maintain a reference to it, and register the necessary url 
 routing maps,  at startup. Then it can call `routeUrl:` for any url the app delegate receives to have it routed.
 
 Url routing has four main classes:
 * FSQUrlRouter - Does url to route string matching and delegate callbacks.
 * FSQRouteContentGenerator - Generates a route content object based on url data input.
 * FSQRouteContent - Represents an action to take for a route. Usually a view controller to be
                     presented or pushed, but can be any action at all.
 * FSQRouteUrlData - Wraps url, url parameters, and remote/local notification info into a single object.
 
 */
@interface FSQUrlRouter : NSObject

/**
 This delegate will get callbacks during routing and can be used to change behavior or update UI.
 
 A delegate is required for proper routing. See the delegate protocol definition below for more information.
 */
@property (nonatomic, weak, nullable) id<FSQUrlRouterDelegate> delegate;

/**
 Routes can define custom presentation blocks to control how the view controllers they show are presented.
 If they do not set one, this default presentation block is used.
 
 All routes must have a presentation block in order to be presented. If you do not set a default one, all routes
 in your route map must set one themselves. Any which do not will not be able to be presented if you do not set
 this property.
 */
@property (nonatomic, copy, nullable) FSQRoutePresentation defaultRoutedUrlPresentation;

/**
 This is the designated initializer for the class.
 
 @param delegate The url router delegate. A delegate is required for proper routing functionality.
 
 @return A new instance of FSQUrlRouter.
 */
- (instancetype)initWithDelegate:(id<FSQUrlRouterDelegate>)delegate NS_DESIGNATED_INITIALIZER;

/**
 This method lets you register a route map for a specific set of scheme names for native urls.
 
 Native urls are urls which are _not_ Universal Links (eg `yourappname://foo`).
 
 The route maps are an array of arrays. The inner arrays are shoudl be two elements, the first of which is the 
 url string to match against and the second should be a FSQRouteContentGenerator object.
 
 E.g.
 
 routeMap = @[ @[ @"/route/to/match" , [MyRoutingDelegate routeGeneratorForThisRoute] ] ,
               @[ @"/another/route"  , [MyRoutingDelegate aDifferentGenerator] ],
             ];
 
 The route map has significant ordering. If more than one route string matches a given url, the one earlier in the
 array is the one that will be the match.
 
 See README.md for a description of valid route strings.
 
 @param schemes The schemes you want to use this route map.
 @param map     The route map to be used when receiving urls with the specified schemes.
 
 @note Only one route map can be set for any one scheme. Setting a new one for the same scheme will remove the old one.
 */
- (void)registerNativeSchemes:(NSArray<NSString *> *)schemes 
                  forRouteMap:(NSArray<NSArray *> *)map;

/**
 This method lets you register a route map for a specific set of universal link hosts
 
 Univeral Links are urls which are https schemes. The host part of the url is eg `example.com`
 
 See `registerNativeSchemes:forRouteMap:` method description for a discussion of route maps.
 
 @param hosts The hosts you want to use this route map.
 @param map   The route map to be used when receiving universal link urls with the specified hosts.
 */
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

/**
 This enum has the control options for delegate callbakcs about a routing-in-progress.
 */
typedef NS_ENUM(NSInteger, FSQUrlRoutingControl) {
    /**
     Cancel the specified routing and do nothing.
     */
    FSQUrlRouterCancelRouting,
    /**
     Allow the specified routing to go through.
     */
    FSQUrlRouterAllowRouting,
    /**
     Defer the specified routing. The router will attempt to route it again the next time `handleDeferredRoute`.
     Only one route can be deferred at a time.
     */
    FSQUrlRouterDeferRouting,
};

@protocol FSQUrlRouterDelegate <NSObject>

/**
 This method is called just before the router generates route content from a url.
 
 You can return a control enum value here to change whether or not the route content is generated and the 
 routing is performed.
 
 @param urlRouter             The url router about to generate route content.
 @param routeContentGenerator The generator that is going to be used to generate the content.
 @param urlData               The url data being used to generate the content.
 
 @return Control value that determines whether the routing is allowed, cancelled, or deferred.
 */
- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
       shouldGenerateRouteContent:(FSQRouteContentGenerator *)routeContentGenerator 
                      withUrlData:(FSQRouteUrlData *)urlData;

/**
 This method is called after the routed content has been generated, but before it has been presented.
 
 You can return a control enum value here to change whether or not the route content is presented.
 
 @param urlRouter    The url router about to present route content.
 @param routeContent The content object being presented.
 
 @return Control value that determines whether the routing is allowed, cancelled, or deferred. 
 */
- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
               shouldPresentRoute:(FSQRouteContent *)routeContent;

/**
 This method is called when routed content is being presented. 
 
 FSQRouteContent objects must have a view controller that they are presented from (so that they can push views 
 onto the stack, etc.).
 
 !! When urlRouter:shouldPresentRoute: returns FSQUrlRouterAllowRouting, this must NOT return nil.
 
 @param urlRouter    The url router presenting route content.
 @param routeContent The content object being presented.
 
 @return The view controller the route content object should be presented from.
 */
- (nullable UIViewController *)urlRouter:(FSQUrlRouter *)urlRouter viewControllerToPresentRoutedUrlFrom:(FSQRouteContent *)routeContent;

/**
 This method is called whenever a routed url is about to be presented.
 
 !! You MUST call the completion handler or your route will get dropped !!
 
 You can use this callback to do any setup that is needed before the route is presented (eg dismiss existing modals)
 
 @param urlRouter         The router about to present the route
 @param routeContent      The route content that is going to be presented
 @param completionHandler A completion handler that you must call when any work you need to do is finished. 
 Execution of this block does the actual presentation asynchronously on the main thread.

 */
- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlWillBePresented:(FSQRouteContent *)routeContent completionHandler:(void (^)())completionHandler;

/**
 This method is called after a routed url was presented.
 
 @param urlRouter    The router that just prestented the route.
 @param routeContent The content object that was presented.
 */
- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlDidGetPresented:(FSQRouteContent *)routeContent;

/**
 This method is called if a url was not able to be routed because it did not match to any registered route map.
 
 @param urlRouter            The router that attempted to route the url.
 @param url                  The url that could not be routed.
 @param notificationUserInfo The notification user info dictionary that could not be routed (if any).
 */
- (void)urlRouter:(FSQUrlRouter *)urlRouter failedToRouteUrl:(NSURL *)url notificationUserInfo:(nullable NSDictionary *)notificationUserInfo;

/**
 This method is called if a url was not able to be routed because the generator used returned a nil content object.
 
 @param urlRouter             The router that attempted to route the url.
 @param routeContentGenerator The generator object used.
 @param urlData               The url data object that was passed to the generator.
 */
- (void)urlRouter:(FSQUrlRouter *)urlRouter failedToGenerateContent:(FSQRouteContentGenerator *)routeContentGenerator urlData:(FSQRouteUrlData *)urlData;

@end


NS_ASSUME_NONNULL_END