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

typedef void (^FSQRoutePresentation)(UIViewController *controllerToPresent, 
                                     UIViewController *presentingController, 
                                     FSQRouteUrlData *urlData);

typedef void (^FSQRouteContentBlock)(UIViewController *pushingController, 
                                     FSQRouteContent *routesContent,
                                     FSQRoutePresentation presentation);

@interface FSQRouteContent : NSObject

@property (nonatomic, strong, nullable) UIViewController *viewController;
@property (nonatomic, strong, nullable) Class viewControllerClass;
@property (nonatomic, strong, nullable) FSQRouteUrlData *urlData;
@property (nonatomic, copy, nullable) FSQRouteContentBlock contentBlock;
@property (nonatomic, copy, nullable) FSQRoutePresentation defaultPresentation;

- (instancetype)initWithViewController:(UIViewController *)viewController;
- (instancetype)initWithViewControllerClass:(Class)viewControllerClass;

- (instancetype)initWithViewController:(UIViewController *)viewController presentation:(FSQRoutePresentation)presentation;
- (instancetype)initWithViewControllerClass:(Class)viewControllerClass presentation:(FSQRoutePresentation)presentation;

- (instancetype)initWithBlock:(FSQRouteContentBlock)routesBlock;

- (void)present;
- (void)presentWithPresentation:(FSQRoutePresentation)presentation;
- (void)presentFromViewController:(UIViewController *)presentingViewController 
                 withPresentation:(FSQRoutePresentation)presentation;

@end


@protocol  FSQRouteContentViewControllerProtocol<NSObject>

+ (UIViewController *)viewControllerForFSQRouteUrlData:(FSQRouteUrlData *)urlData;

@end

NS_ASSUME_NONNULL_END