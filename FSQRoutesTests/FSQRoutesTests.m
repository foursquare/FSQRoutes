//
//  FSQRoutesTests.m
//  FSQRoutesTests
//
//  Created by Brian Dorfman on 10/30/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "FSQRoutes.h"

@interface FSQRoutesTests : XCTestCase <FSQUrlRouterDelegate>
@property (nonatomic, strong) FSQUrlRouter *urlRouter;
@end

@interface FSQUrlRouter (SecretTestMethods)
- (NSDictionary<NSString *, NSString *> *)parametersForUrlString:(NSString *)urlString matchingAgainstRoute:(NSString *)routeString;
@end

#define TEST_URLS_MATCH(testName, urlString, routeString) \
- (void)test##testName { \
XCTAssertNotNil([self.urlRouter parametersForUrlString:urlString matchingAgainstRoute:routeString], \
@"Match %@ to %@", urlString, routeString);\
}


#define TEST_URLS_DONT_MATCH(testName, urlString, routeString) \
- (void)test##testName { \
XCTAssertNil([self.urlRouter parametersForUrlString:urlString matchingAgainstRoute:routeString], \
@"Don't match %@ to %@", urlString, routeString); \
}

#define TEST_URLS_MATCH_AND_PARAMS_MATCH(testName, urlString, routeString, validationDict) \
- (void)test##testName { \
NSDictionary<NSString *, NSString *> *result = [self.urlRouter parametersForUrlString:urlString matchingAgainstRoute:routeString]; \
XCTAssertNotNil(result, @"Match %@ to %@", urlString, routeString); \
for (NSString *validateKey in validationDict) { \
    XCTAssertTrue([result[validateKey] isEqualToString:validationDict[validateKey]], @"Param \'%@\' should equal to \'%@\' (actual value: \'%@\')", validateKey, validationDict[validateKey], result[validateKey]); \
} \
}\


@implementation FSQRoutesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.urlRouter = [[FSQUrlRouter alloc] initWithDelegate:self]; 
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

TEST_URLS_MATCH(StringMatching1, @"test://foo/bar",  @"/foo/bar")
TEST_URLS_MATCH(StringMatching2, @"test://foo/bar", @"/foo/bar/")
TEST_URLS_MATCH(StringMatching3, @"test://", @"/")
TEST_URLS_DONT_MATCH(StringMatching4, @"test://foo/bar", @"/foo")

TEST_URLS_MATCH_AND_PARAMS_MATCH(ParameterMatching1, @"test://foo/bar", @"/foo/:param", @{@"param" : @"bar"})
TEST_URLS_MATCH_AND_PARAMS_MATCH(ParameterMatching2, @"test://foo/bar", @"/:param1/:param2", (@{@"param1" : @"foo",
                                                                                                @"param2" : @"bar"}))
TEST_URLS_DONT_MATCH(ParameterMatching3, @"test://foo/bar", @"/foo/:param/bar")
TEST_URLS_MATCH_AND_PARAMS_MATCH(ParameterMatching4, @"test://foo/bar?param2=a&param3=b", @"/foo/:param1", (@{@"param1" : @"bar",
                                                                                                              @"param2" : @"a",
                                                                                                              @"param3" : @"b",}))
TEST_URLS_MATCH_AND_PARAMS_MATCH(ParameterMatching5, @"test://?param1=a&param2=b", @"/", (@{@"param1" : @"a",
                                                                                            @"param2" : @"b"}))

TEST_URLS_MATCH(SingleWildcardMatch1, @"test://foo/bar/baz", @"/*/*/baz")
TEST_URLS_MATCH(SingleWildcardMatch2, @"test://foo/bar/baz", @"/foo/*/baz")
TEST_URLS_DONT_MATCH(SingleWildcardMatch3, @"test://foo/bar/baz", @"/foo/*")
TEST_URLS_DONT_MATCH(SingleWildcardMatch4, @"test://foo/bar", @"/*")
TEST_URLS_DONT_MATCH(SingleWildcardMatch5, @"test://", @"/*")

TEST_URLS_MATCH(UnlimitedWildcardMatch1, @"test://a/b/", @"/**/b")
TEST_URLS_MATCH(UnlimitedWildcardMatch2, @"test://a/b/b/", @"/**/b")
TEST_URLS_MATCH(UnlimitedWildcardMatch3, @"test://foo/bar/baz", @"/**/baz")
TEST_URLS_MATCH(UnlimitedWildcardMatch4, @"test://foo/bar/baz", @"/foo/**/baz")
TEST_URLS_MATCH(UnlimitedWildcardMatch5, @"test://", @"/**")
TEST_URLS_DONT_MATCH(UnlimitedWildcardMatch6, @"test://foo/bar", @"/bar/**")
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch7, @"test://b/a", @"/**/b/:param/**", @{@"param" : @"a"})
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch8, @"test://b/a/b/c", @"/**/b/:param/**", @{@"param" : @"a"})
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch9, @"test://b/a", @"/**/:param/a/**", @{@"param" : @"b"})
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch10, @"test://b/a/c/a", @"/**/:param/a/**", @{@"param" : @"b"})
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch11, @"test://c/a/a/b", @"/**/:param/a/b/**", @{@"param" : @"a"});
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch12, @"test://d/c/a/b/a/b", @"/**/:param/a/b/**", @{@"param" : @"c"});
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch14, @"test://a/b/c/d", @"/**/:param", @{@"param" : @"d"});
TEST_URLS_MATCH_AND_PARAMS_MATCH(UnlimitedWildcardMatch15, @"test://a", @"/**/:param", @{@"param" : @"a"});

/**
 Mandatory delegate callbacks that we don't actually use in tests
 */

- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
       shouldGenerateRouteContent:(FSQRouteContentGenerator *)routeContentGenerator 
                      withUrlData:(FSQRouteUrlData *)urlData {
    return FSQUrlRouterAllowRouting;
}

- (FSQUrlRoutingControl)urlRouter:(FSQUrlRouter *)urlRouter 
               shouldPresentRoute:(FSQRouteContent *)routeContent {
    return FSQUrlRouterAllowRouting;
}

- (UIViewController *)urlRouter:(FSQUrlRouter *)urlRouter viewControllerToPresentRoutedUrlFrom:(FSQRouteContent *)routeContent {
    return nil;
}

- (void)urlRouter:(FSQUrlRouter *)urlRouter 
routedUrlWillBePresented:(FSQRouteContent *)routeContent 
completionHandler:(void (^)())completionHandler {
    completionHandler();
}

- (void)urlRouter:(FSQUrlRouter *)urlRouter routedUrlDidGetPresented:(FSQRouteContent *)routeContent {
    
}

- (void)urlRouter:(FSQUrlRouter *)urlRouter
 failedToRouteUrl:(NSURL *)url 
notificationUserInfo:(nullable NSDictionary *)notificationUserInfo {
    
}

- (void)urlRouter:(FSQUrlRouter *)urlRouter
failedToGenerateContent:(FSQRouteContentGenerator *)routeContentGenerator 
          urlData:(FSQRouteUrlData *)urlData {
    
}


@end
