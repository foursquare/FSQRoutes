FSQRoutes
=========

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

An easy to use and flexible URL routing framework for iOS.

Overview
========

FSQRoutes gives you an easy way to have your app take certain actions when opened by URLs, either using native schemes or universal links. It was designed to be extremely flexible while also being simple to use for the most common cases. It also uses standard built-in Apple frameworks and classes to do the URL parsing (such as NSURL and NSURLComponents) instead of complicated regular expressions or substring matching.

Setup
=====

## Carthage

Carthage is the recommended way to integrate FSQRoutes with your app.
Add `github "foursquare/FSQRoutes"` to your Cartfile and follow the instructions from [Carthage's README](https://github.com/Carthage/Carthage) for adding Carthage-built frameworks to your project.

## Cocoapods

If you use Cocoapods, you can add `pod 'FSQRoutes', '~> [desired version here]'` to your Podfile. Further instructions on setting up and using Cocoapods can be found on [their website](https://cocoapods.org)


Using FSQRoutes
===============

To use FSQRoutes, create and retain an instance of FSQUrlRouter somewhere early on in your application life cycle (generally in your app delegate). Also register your url route mapping as described in the next section.

Then, in any method where your app receives URL (such as `application:openURL:sourceApplication:annotation:` or `application:didReceiveRemoteNotification:`) pass the URL you wish to route through to the router via the `routeUrl:` or `routeUrl:notificationUserInfo:` methods.

There are many more customization options available, many of which are described below, but this will get you up and run with the basics.

Main Classes
============

There are four main classes in FSQRoutes that you will use.

### FSQUrlRouter

You use this class to set up route mappings when your app starts (see below). Then later when you want to open URLs, you pass them to the router and it matches the url to an action.

### FSQRouteContent

This class encompasses an action that is to be taken from a routed url. In the most common case, it just wraps a view controller that is presented on screen. However it can be any action at all. It also splits up the action to be taken or view controller to be shown from the actual presentation style (eg pushed onto nav stack, or presented, or any custom presentation style you wish to use).

### FSQRouteContentGenerator

This takes URL information and creates a new FSQRouteContent object from it. These are generally paired with url strings in a route map so the router knows how to create content from the urls it matches (see Creating a Route Mapping below).

### FSQUrlData

This class wraps all relevant URL information into a single object. It includes the actual NSURL and also the userInfo dictionary from a local or remote notification if applicable. If created from a FSQUrlRouter match, the router also parses out all the URL's into a parameter dictionary.


Creating a Route Mapping
========================

In order for URLs to be routed, you will have to set up a route mapping. This tells the router what actions you want to take when certain urls come in. 

The mapping is an array of 2-Item arrays. Each inner array has a url string as the first object, and a route content generator as the second item.

Here is a simple example:

```objc
@[ @[@"/home" , [self createHomeScreenGenerator],
   @[@"/profile", [self createProfileScreenGenerator],
   @[@"/profile/user/:userId/", [self createUserProfileScreenGenerator]],
   @[@"/settings/**", [self createSettingsScreenGenerator]],
   ];
```
The actual methods that create the generators are not included in this example (see the next section for this), but it gives you an idea of how a mapping might look. In this example, the `/home` url might take you to the main screen of your app, while `/profile` might take you to the logged in user's own profile and `/profile/user/:userId/` takes you to a specific user's profile screen.

The url route does strict case-sensitive matching on all path components. There are a few special symbols you can insert though to get extra functionality.

If a path component starts with a colon `:`, that component will match to ANY path component in the URL, and the text of that component will be added to a parameter dictionary passed to you with the key name you chose (in this example, `userId`).

If a path component is a single asterisk `*`, that component also matches to any path component like a parameter match, except that the value is not saved and returned to you.

If a path component is a double asterisk `**`, that component matches any number of path components in the url. In the above example, as long as the first component of the url is `settings` it will be routed to the settings screen, no matter what the rest of the url is.

Creating a Route Generator
==========================

Here is a simple example of what one of the route content generator creation methods from the previous section's example might look like:

```objc
+ (FSQRouteContentGenerator *)createUserProfileScreenGenerator {
    return [[FSQRouteContentGenerator alloc] initWithBlock:^(FSQRouteUrlData *urlData) {
        return [[FSQRouteContent alloc] initWithViewController:[[UserProfileViewController alloc] initWithUserId:urlData.parameters[@"userId"]]]];
    }];
}
```
When you set up the route map in the previous generator, this method is called and the generator it makes is added to the array. If you look at the previous example, this generator is paired with the @"/profile/user/:userId/" string. Whenever the router receives a URL that matches to this string, it will then this generator. The generator reads the `userId` parameter that was parsed out of the url, and creates a new route content object that wraps a profile view controller with that userId. Note that in this example, no custom presentation style is set, so a default presentation style must be set on FSQUrlRouter for this content to actually be presentable.

Route Presentations
===================

FSQRouteContent objects separate the actual content itself (either the view controller to show, or the actions to take) from the logic of how to actually present that content. A simple presentation might just push a new view controller onto the stack. A more complicated one might first switch what tab is showing in the app, or pop a nav controller to root first, and then present the new view controller with a custom transition.

Here is an example of a very simple presentation:

```objc
presentation = ^(UIViewController *controllerToPresent, UIViewController *presentingController, FSQRouteUrlData *_Nullable urlData) {
	[presentingController.navigationController pushViewController:controllerToPresent animated:YES];
};
```

All route content objects must have a presentation in order to be shown on screen. You should provide your FSQUrlRouter with a default presentation style to use for any route content generator which does not specify its own presentation style.

Router Delegate
===============

In order to properly function, you _must_ provide a delegate to FSQUrlRouter. Here is a summary of important functionality you must provide to the router:

`- (UIViewController *)urlRouter:(FSQUrlRouter *)urlRouter viewControllerToPresentRoutedUrlFrom:(FSQRouteContent *)routeContent;`

This method will be called whenever a route needs to be presented. Your delegate must provide the source view controller for the presentation (generally whatever is currently on top of your nav stack).

`- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlWillBePresented:(FSQRouteContent *)routeContent completionHandler:(void (^)())completionHandler;`

This method will be called just _before_ a view needs to be presented. It gives you a chance to change any state you need to change before the view is presented (such as dismissing previously shown modal views, or popping view controllers to root). Note that you _MUST_ call the completionHandler block in this method at some point or the routing will not happen as this block tells the router it can continue routing operations. It is provided as a block instead of just happening immediately after the delegate callback returns so that you may wait for asynchronous operations to complete (such as dismissing views animated).

`- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
       shouldGenerateRouteContent:(FSQRouteContentGenerator *)routeContentGenerator 
                      withUrlData:(FSQRouteUrlData *)urlData;`
`- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
               shouldPresentRoute:(FSQRouteContent *)routeContent;`

These methods allow you to cancel or defer routing at certain points during the routing process. If a route is deferred, its information is saved in the router but it is not routed immediately. If you ever defer any routes, you should later call `handleDeferredRoute` on the router when you want it to attempt routing that URL again. Deferring should be used to temporarily delay routing during points at which your application is in a state where the route cannot be showed (such as during initial creation of your apps root views, or while the user is logged out).

Contributors
============

FSQRoutes was initially developed by Foursquare Labs for internal use. It was originally written by Brian Dorfman ([@bdorfman](https://twitter.com/bdorfman)) and is currently maintained by Sam Grossberg ([@samgro](https://github.com/samgro)).
