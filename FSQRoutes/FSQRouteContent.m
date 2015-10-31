//
//  FSQRouteContent.m
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

#import "FSQRouteContent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FSQRouteContent

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [self init];
    if (self) {
        self.viewController = viewController;
    }
    return self;
}

- (instancetype)initWithViewController:(UIViewController *)viewController 
                          presentation:(FSQRoutePresentation)presentation {
    self = [self initWithViewController:viewController];
    if (self) {
        self.defaultPresentation = presentation;
    }
    return self;
}

- (instancetype)initWithViewControllerClass:(Class)viewControllerClass {
    self = [self init];
    if (self) {
        NSAssert([viewControllerClass isSubclassOfClass:[UIViewController class]], 
                 @"FSQRouteContent: Tried to set a view controller class that is not a subclass of UIViewController");
        self.viewControllerClass = viewControllerClass;
    }
    return self;
}

- (instancetype)initWithViewControllerClass:(Class)viewControllerClass 
                               presentation:(FSQRoutePresentation)presentation {
    self = [self initWithViewControllerClass:viewControllerClass];
    if (self) {
        self.defaultPresentation = presentation;
    }
    return self;
}

- (instancetype)initWithBlock:(FSQRouteContentBlock)routesBlock {
    self = [self init];
    if (self) {
        self.contentBlock = routesBlock;
    }
    return self;
}

- (void)setViewController:(nullable UIViewController *)viewController {
    _viewController = viewController;
    self.viewControllerClass = viewController.class;
}

- (nullable UIViewController *)viewControllerToPresent {
    if (self.viewController == nil
        && self.viewControllerClass != Nil) {
        if ([self.viewControllerClass respondsToSelector:@selector(viewControllerForFSQRouteUrlData:)]) {
            self.viewController = [self.viewControllerClass viewControllerForFSQRouteUrlData:self.urlData];
        }
        else {
            self.viewController = [self.viewControllerClass new];
        }
    }
    
    return self.viewController;
}

#pragma mark - Presentation -

- (void)present {
    [self presentWithPresentation:self.defaultPresentation];
}

- (void)presentWithPresentation:(FSQRoutePresentation)presentation {
    [self presentFromViewController:[self topmostViewController] 
                   withPresentation:presentation];
}

- (void)presentFromViewController:(UIViewController *)presentingViewController 
                 withPresentation:(FSQRoutePresentation)presentation {
    if (presentingViewController == nil
        || presentation == nil) {
        return;
    }

    if (self.contentBlock) {
        self.contentBlock(presentingViewController, self, presentation);
    }
    else {
        UIViewController *viewController = [self viewControllerToPresent];
        if (viewController != nil) {
            presentation(viewController, presentingViewController, self.urlData);
        }
    }
}

- (UIViewController *)topmostViewController {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    UIViewController *newVC = rootViewController;
    UIViewController *oldVC;
    
    while (YES) {
        do {
            oldVC = newVC;
            if ([newVC isKindOfClass:[UITabBarController class]]) {
                newVC = [(UITabBarController *)newVC selectedViewController];
            }
            else if ([newVC isKindOfClass:[UINavigationController class]]) {
                newVC = [(UINavigationController *)newVC topViewController];
            }
        } while (newVC != oldVC);
        
        if (newVC.presentedViewController != nil) {
            newVC = newVC.presentedViewController;
        }
        else {
            break;
        }
    }

    return newVC;
}

@end

NS_ASSUME_NONNULL_END
