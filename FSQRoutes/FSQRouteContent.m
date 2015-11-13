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

- (void)presentFromViewController:(UIViewController *)presentingViewController {
    [self presentFromViewController:presentingViewController 
                   withPresentation:self.defaultPresentation];
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

@end

NS_ASSUME_NONNULL_END
