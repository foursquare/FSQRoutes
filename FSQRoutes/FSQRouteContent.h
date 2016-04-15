//
//  FSQRouteContent.h
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class FSQRouteContent;
@class FSQRouteUrlData;

/**
 This block type takes in a view controller that should be presented in some way, along with the view controller
 that is doing the presentation, and associated url data that was used to generate the presented view controller.
 It then does the actual presentation logic.
 
 E.g. A presentation block which just pushes the new view controller onto the stack might do
 ```[presentingController.navigationController pushViewController:controllerToPresent animated:YES];```
 
 @param controllerToPresent  The new controller that is to be shown on screen.
 @param presentingController The view controller doing the presentation.
 @param urlData              The url data used to generate the view controller (if any).
 */
typedef void (^FSQRoutePresentation)(UIViewController *controllerToPresent, 
                                     UIViewController *presentingController, 
                                     FSQRouteUrlData *_Nullable urlData);

/**
 For content objects that want to take actions other than presenting view controllers, this block type can
 be used instead. It takes in the view controller that is attempting to push the route content, the content
 object itself, and the presentation block that the presenter would like to use. The block can then take
 any actions it wishes to.
 
 @param pushingController The view controlling doing the presentation.
 @param routesContent     The content object that should be presented.
 @param presentation      The presentation block that should be used to present any new view controllers.
 */
typedef void (^FSQRouteContentBlock)(UIViewController *pushingController, 
                                     FSQRouteContent *routesContent,
                                     FSQRoutePresentation presentation);

/**
 The Route Content class is effectively a description of the actions that should be taken when a routed url is
 actually "pushed" on screen. At its most basic this is just pushing a new view controller on the stack. 
 However when pushed or presented on screen, it can actually take any action. It also separates out the actions
 or view controllers to be generated from the logic on how to actually present them on screen.
 
 There are several different initializers based on what behavior you want to take when content is pushed:
 * `initWithViewController:` This makes a content object which wraps an already created view controller to present.
 * `initWithViewControllerClass:` This tells the content object to lazily instantiate a new VC of the given class
                                  when the content is presented.
 * `initWithBlock` This lets you specify a block which will get called when the content is presented, allowing you to
                   take any actions you wish.
 
 */
@interface FSQRouteContent : NSObject

/**
 If set and contentBlock is nil, this view controller will be the one presented when the content object is presented.
 */
@property (nonatomic, strong, nullable) UIViewController *viewController;

/**
 If set and both contentBlock and viewController are nil, a new instance of this class will be created and presented
 when the content object is presented.
 
 The class must be UIViewController or a subclass of it.
 
 If the class responds to the `viewControllerForFSQRouteUrlData:` method, that method will be used to create the
 new view controller. Otherwise just `init` will be used. See `FSQRouteContentViewControllerProtocol` for more info.
 */
@property (nonatomic, strong, nullable) Class viewControllerClass;

/**
 This is the url date used to generate this content object, if any.
 */
@property (nonatomic, strong, nullable) FSQRouteUrlData *urlData;

/**
 If not nil, this block will be executed when the content object is presented instead of presenting a 
 view controller.
 */
@property (nonatomic, copy, nullable) FSQRouteContentBlock contentBlock;

/**
 When presenting a content object, you must give it a presentation block that determines how it is presented.
 You can set a default value here if you want there to be standard presentation type for this content.
 
 This must be set to use the `presentFromViewController:` method which does not pass in a custom presentation.
 
 If this content object is being created by FSQUrlRouter and the content's defaultPresentation is nil, the router
 will set its value to its own defaultRoutedUrlPresentation property.
 */
@property (nonatomic, copy, nullable) FSQRoutePresentation defaultPresentation;

/**
 This makes a content object with its `viewController` set to the passed in object. 
 See that property or this class's description for more info.
 */
- (instancetype)initWithViewController:(UIViewController *)viewController;

/**
 This makes a content object with its `viewControllerClass` set to the passed in class. 
 See that property or this class's description for more info.
 */
- (instancetype)initWithViewControllerClass:(Class)viewControllerClass;

/**
 This makes a content object with its `viewController` set to the passed in object and its `defaultPresentation`
 set to the passed in presentation block.
 See those properties or this class's description for more info.
 */
- (instancetype)initWithViewController:(UIViewController *)viewController presentation:(FSQRoutePresentation)presentation;

/**
 This makes a content object with its `viewControllerClass` set to the passed in class and its `defaultPresentation`
 set to the passed in presentation block.
 See those properties or this class's description for more info.
 */
- (instancetype)initWithViewControllerClass:(Class)viewControllerClass presentation:(FSQRoutePresentation)presentation;

/**
 This makes a content object with its `contentBlock` set to the passed in block.
 See that property or this class's description for more info.
 */
- (instancetype)initWithBlock:(FSQRouteContentBlock)routesBlock;

/**
 This presents the content object on screen from the given source view controller.
 
 The `defaultPresentation` must be set or this method will do nothing.
 
 This is the method that is used by FSQUrlRouter to presented routed urls.
 
 @param presentingViewController The view controller from which to present this content.
 */
- (void)presentFromViewController:(UIViewController *)presentingViewController;

/**
 This presents the content object on screen from the given source view controller with the given presentation.

 @param presentingViewController The view controller from which to present this content.
 @param presentation             The presentation block to use to present the content.
 */
- (void)presentFromViewController:(UIViewController *)presentingViewController
                 withPresentation:(FSQRoutePresentation)presentation;

@end


@protocol  FSQRouteContentViewControllerProtocol<NSObject>

/**
 If implemented, this method is used to create new view controller instances when using the `viewControllerClass`
 property on FSQRouteContent. You can use this to do additional initialization on view controllers 
 created from routed urls in the vc classes themselves.
 
 @param urlData The url data used to create the route content object which is creating this view controller.
 
 @return A new UIViewController that the content object will retain and present on screen.
 */
+ (UIViewController *)viewControllerForFSQRouteUrlData:(nullable FSQRouteUrlData *)urlData;

@end

NS_ASSUME_NONNULL_END