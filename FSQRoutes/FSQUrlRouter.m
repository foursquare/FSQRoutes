//
//  FSQUrlRouter.m
//  FSQRoutes
//
//  Created by Brian Dorfman on 10/29/15.
//  Copyright © 2015 Foursquare. All rights reserved.
//

#import "FSQUrlRouter.h"

#import "FSQRouteContent.h"
#import "FSQRouteContentGenerator.h"
#import "FSQRouteUrlData.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSQUrlRouter ()
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSArray<NSArray *> *> *nativeSchemeRouteMaps;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSArray<NSArray *> *> *httpHostRouteMaps;
@property (nonatomic, copy, nullable) NSString *defaultNativeScheme;

@property (nonatomic, copy, nullable) void (^deferredRoute)(FSQUrlRouter *router);
@end

typedef NS_ENUM(NSInteger, FSQRouteUrlTokenType) {
    FSQRouteUrlTokenTypeString,
    FSQRouteUrlTokenTypeParameter,
    FSQRouteUrlTokenTypeSingleComponentWildcard,
    FSQRouteUrlTokenTypeUnlimitedComponentWildcard
};

@interface FSQRouteUrlToken : NSObject 
@property (nonatomic, assign, readonly) FSQRouteUrlTokenType type;
@property (nonatomic, copy, nullable, readonly) NSString *stringOrParameterName;

+ (instancetype)withString:(NSString *)string;
+ (instancetype)withParameterName:(NSString *)parameterName;
+ (instancetype)singleComponentWildCard;
+ (instancetype)unlimitedComponentWildCard;
@end

@implementation FSQUrlRouter

#pragma mark - Registering Route Maps -

- (void)registerNativeSchemes:(NSArray<NSString *> *)schemes 
                  forRouteMap:(NSArray<NSArray *> *)map {

    if (!self.nativeSchemeRouteMaps) {
        self.nativeSchemeRouteMaps = [NSMutableDictionary dictionary];
    }
    
    map = [self tokenizeRouteMap:map];
    
    for (NSString *scheme in schemes) {
        self.nativeSchemeRouteMaps[scheme] = map;
    }
}

- (void)registerUniversalLinkHosts:(NSArray<NSString *> *)hosts 
                       forRouteMap:(NSArray<NSArray *> *)map {

    if (!self.httpHostRouteMaps) {
        self.httpHostRouteMaps = [NSMutableDictionary dictionary];
    }
    
    for (NSString *host in hosts) {
        self.httpHostRouteMaps[host] = map;
    }
}

- (NSArray<NSString *> *)normalizePathComponents:(NSArray<NSString *> *)pathComponents {
    NSMutableArray<NSString *> *normalizedComponents = [NSMutableArray new];
    for (NSString *component in pathComponents) {
        if (component.length > 0
            && ![component isEqualToString:@"/"]) {
            [normalizedComponents addObject:component];
        }
    }
    return normalizedComponents.copy;
}

- (NSArray<FSQRouteUrlToken *> *)tokenizedRouteString:(NSString *)urlString {
    NSMutableArray<FSQRouteUrlToken *> *tokenizedURL = [NSMutableArray new];
    
    FSQRouteUrlToken *lastAddedToken = nil;
    
    NSArray *pathComponents = [self normalizePathComponents:[urlString pathComponents]];
    for (NSString *string in pathComponents) {
        FSQRouteUrlToken *token = nil;
        if ([string isEqualToString:@"*"]) {
            token = [FSQRouteUrlToken singleComponentWildCard];
        }
        else if ([string isEqualToString:@"**"]) {
            if (lastAddedToken.type == FSQRouteUrlTokenTypeUnlimitedComponentWildcard) {
                /**
                 Don't add a multiple unlimited wildcards in a row because it is redundant
                 */
            }
            else if (lastAddedToken.type == FSQRouteUrlTokenTypeParameter) {
                /**
                 We shouldn't completely wrap a parameter token with unlimited wildcard tokens, because parsing
                 that is ambigious. eg matching against @"/ ** / :aParameter / ** /" can't work because we
                 won't know which path component the parameter should match to.
                 
                 If we think we might be in this case, do some checking to see if we are surrounding a 
                 parameter token and if we are, assert and skip adding this route.
                 
                 There are other ambiguous cases, but we won't bother trying to catch them all.
                 */
                
                NSUInteger possibleOtherWildcardIndex = tokenizedURL.count - 2;
                if (possibleOtherWildcardIndex > 0) {
                    if (tokenizedURL[possibleOtherWildcardIndex].type == FSQRouteUrlTokenTypeUnlimitedComponentWildcard) {
                        NSAssert(0, @"Tried to add a route where a parameter component was surrounded by "
                                 @"unlimited wildcard components. path = %@", urlString);
                        continue;
                    }
                }
                
                /**
                 If we made it through the above check without continue'ing, then we are fine.
                 */
                token = [FSQRouteUrlToken unlimitedComponentWildCard];
            }
            else {
                token = [FSQRouteUrlToken unlimitedComponentWildCard];
            }
        }
        else if ([string hasPrefix:@":"]
                 && string.length > 1) {
            token = [FSQRouteUrlToken withParameterName:[string substringFromIndex:1]];
        }
        else if (string.length > 0) {
            token = [FSQRouteUrlToken withString:string];
        }
        
        if (token != nil) {
            lastAddedToken = token;
            [tokenizedURL addObject:token];                
        }
    }
    
    return [tokenizedURL copy];
    
}

- (NSArray<NSArray *> *)tokenizeRouteMap:(NSArray<NSArray *> *)map {
    
    NSMutableArray<NSArray *> *tokenizedRouteMap = [NSMutableArray new];
    
    for (NSArray *pair in map) {
        NSString *urlString = [pair firstObject];
        FSQRouteContentGenerator *contentGenerator = [pair lastObject];
        
        NSAssert(urlString.length > 0, @"Empty url string registered for route map");
        NSAssert(contentGenerator != nil, @"Nil contentGenerator registered for route map. url string = %@", urlString);
        
        if (urlString.length == 0
            || contentGenerator == nil) {
            continue;
        }
        
        [tokenizedRouteMap addObject:@[[self tokenizedRouteString:urlString], contentGenerator]];
    }
         
    return [tokenizedRouteMap copy];
}

#pragma mark - Matching urls against registered routes -

- (NSArray<NSArray *> *)routeMapForUrl:(NSURL *)url isNativeScheme:(nullable BOOL *)isNativeScheme {
    NSArray<NSArray *> *routeMap = nil;
    
    if ([[url scheme] isEqualToString:@"https"]) {
        routeMap = self.httpHostRouteMaps[url.host];
        
        if (isNativeScheme != NULL) {
            *isNativeScheme = NO;
        }
    }
    else {
        routeMap = self.nativeSchemeRouteMaps[url.scheme];
        
        if (isNativeScheme != NULL) {
            *isNativeScheme = YES;
        }
    }
    
    return routeMap;
}

- (BOOL)urlSchemeOrDomainIsRegistered:(NSURL *)url {
    return !![self routeMapForUrl:url isNativeScheme:NULL];
}

- (nullable NSDictionary<NSString *, NSString *> *)parametersForUrl:(NSURL *)url
                                                     ifMatchingPath:(NSArray<FSQRouteUrlToken *> *)tokens {

    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:YES];;
    NSArray *urlPathComponents = [urlComponents.path pathComponents];

    if (![urlComponents.scheme isEqualToString:@"https"]
        && urlComponents.host.length > 0) {
        urlPathComponents = [@[urlComponents.host] arrayByAddingObjectsFromArray:urlPathComponents];
    }
    
    urlPathComponents = [self normalizePathComponents:urlPathComponents];
    
    NSDictionary<NSString *, NSString *> *matchResult;
    matchResult = [self parametersForUrlPathComponents:urlPathComponents 
                                                tokens:tokens 
                                     startingPathIndex:0 
                                    startingTokenIndex:0 
                                       targetPathIndex:urlPathComponents.count - 1
                                      targetTokenIndex:tokens.count - 1];
    
    if (matchResult == nil) {
        return nil;
    }
    else {
        NSMutableDictionary<NSString *, NSString *> *mutableParameters = matchResult.mutableCopy;
        
        for (NSURLQueryItem *item in urlComponents.queryItems) {
            mutableParameters[item.name] = item.value;
        }
        
        return mutableParameters.copy;
    }
}


- (nullable NSDictionary<NSString *, NSString *> *)parametersForUrlPathComponents:(NSArray *)urlPathComponents
                                                                           tokens:(NSArray<FSQRouteUrlToken *> *)tokens
                                                                startingPathIndex:(NSInteger)urlPathComponentIndex
                                                               startingTokenIndex:(NSInteger)tokenIndex
                                                                  targetPathIndex:(NSInteger)targetUrlPathComponentIndex
                                                                 targetTokenIndex:(NSInteger)targetTokenIndex {
 
    NSInteger numberOfUrlPathComponents = urlPathComponents.count;
    NSInteger numberOfTokens = tokens.count;
    
    NSMutableDictionary<NSString *, NSString *> *parameterDictionary = [NSMutableDictionary new];
    
    if (numberOfUrlPathComponents == 0
        || numberOfTokens == 0) {
        if (numberOfUrlPathComponents == 0
             && (numberOfTokens == 0
                 || (numberOfTokens == 1 && tokens[0].type == FSQRouteUrlTokenTypeUnlimitedComponentWildcard))
            ) {
            return parameterDictionary.copy;
        }
        else {
            return nil;
        }
    }
    
    NSInteger(^advancePathIndex)(NSInteger) = nil;
    NSInteger(^advanceTokenIndex)(NSInteger) = nil;
    NSInteger(^reversePathIndex)(NSInteger) = nil;
    NSInteger(^reverseTokenIndex)(NSInteger) = nil;
    
    NSInteger(^forwardAdvancer)(NSInteger) = ^(NSInteger index) {
        return index + 1;
    };

    NSInteger(^backwardAdvancer)(NSInteger) = ^(NSInteger index) {
        return index - 1;
    };
    
    NSInteger pathIndexUpperBound;
    NSInteger pathIndexLowerBound;
    NSInteger tokenIndexUpperBound;
    NSInteger tokenIndexLowerBound;
    
    if (targetUrlPathComponentIndex >= urlPathComponentIndex) {
        pathIndexUpperBound = targetUrlPathComponentIndex;
        pathIndexLowerBound = 0;
        advancePathIndex = forwardAdvancer;
        reversePathIndex = backwardAdvancer;
    }
    else {
        pathIndexUpperBound = numberOfUrlPathComponents;
        pathIndexLowerBound = targetUrlPathComponentIndex;
        advancePathIndex = backwardAdvancer;
        reversePathIndex = forwardAdvancer;
    }
    
    if (targetTokenIndex >= tokenIndex) {
        tokenIndexUpperBound = targetTokenIndex;
        tokenIndexLowerBound = 0;
        advanceTokenIndex = forwardAdvancer;
        reverseTokenIndex = backwardAdvancer;
    }
    else {
        tokenIndexUpperBound = numberOfTokens;
        tokenIndexLowerBound = targetTokenIndex;
        advanceTokenIndex = backwardAdvancer;
        reverseTokenIndex = forwardAdvancer;
    }
    
    BOOL successfulMatchShortCircuit = NO;
    
    while (!successfulMatchShortCircuit
           && urlPathComponentIndex <= pathIndexUpperBound
           && urlPathComponentIndex >= pathIndexLowerBound
           && tokenIndex <= tokenIndexUpperBound
           && tokenIndex >= tokenIndexLowerBound) {

        NSString *pathComponent = urlPathComponents[urlPathComponentIndex];
        FSQRouteUrlToken *token = tokens[tokenIndex];
        
        switch (token.type) {
            case FSQRouteUrlTokenTypeString: {
                if ([token.stringOrParameterName isEqualToString:pathComponent]) {
                    /**
                     Token string matches the path component. Proceed to the next of each.
                     */
                    tokenIndex = advanceTokenIndex(tokenIndex);
                    urlPathComponentIndex = advancePathIndex(urlPathComponentIndex);
                }
                else {
                    /**
                     The string of the token should match the current path component, but does not.
                     This url is not a match
                     */
                    return nil;
                }
            }
                break;
                
            case FSQRouteUrlTokenTypeParameter: {
                /**
                 Set this components string value for the given parameter in the result dictionary
                 and then proceed to the next component and token
                 */
                parameterDictionary[token.stringOrParameterName] = pathComponent;
                tokenIndex = advanceTokenIndex(tokenIndex);
                urlPathComponentIndex = advancePathIndex(urlPathComponentIndex);
            }
                break;
                
            case FSQRouteUrlTokenTypeSingleComponentWildcard: {
                /**
                 This component can be anything and we just ignore it.
                 */
                tokenIndex = advanceTokenIndex(tokenIndex);
                urlPathComponentIndex = advancePathIndex(urlPathComponentIndex);
            }
                break;
                
            case FSQRouteUrlTokenTypeUnlimitedComponentWildcard: {
                /**
                 If we are the last token, then at this point we can just say
                 that the url matches
                 */
                if (tokenIndex == targetTokenIndex) {
                    successfulMatchShortCircuit = YES;
                    continue;
                }
                
                /**
                 Ok now we are at the complicated part.
                 */
                
                NSInteger nextTokenIndex = advanceTokenIndex(tokenIndex);
                FSQRouteUrlToken *nextToken = tokens[nextTokenIndex];
                
                switch (nextToken.type) {
                        
                        /**
                         1. The next token is a static string.
                         
                         Find every current or future path component that matches that string and start parsing from there.
                         Use the first least greedy result that matches in case of any ambiguity.
                         If the string doesn't appear in our path any more, we didn't match.
                         
                         Examples:
                         
                         "/ ** / b" should match all of the following 
                         "urlscheme://a/b" 
                         "urlscheme://a/b/b".
                         
                         "/ ** / b / :param / ** /" will match several ways to the url 
                         "urlscheme://b/a/b/c"
                         and param could end up as either "a" or "c" but we should write it so that is is 
                         left-weighted (each wildcard as we go along prefers to be as small as possible) and so
                         param will end up as "a" 
                         */
                        
                    case FSQRouteUrlTokenTypeString:
                    {
                        NSDictionary *parameterResult = nil;
                        
                        for (; 
                             urlPathComponentIndex <= pathIndexUpperBound 
                             && urlPathComponentIndex >= pathIndexLowerBound
                             && parameterResult == nil; 
                             urlPathComponentIndex = advancePathIndex(urlPathComponentIndex)) {
                            if ([urlPathComponents[urlPathComponentIndex] isEqualToString:nextToken.stringOrParameterName]) {
                                parameterResult = [self parametersForUrlPathComponents:urlPathComponents 
                                                                                tokens:tokens 
                                                                     startingPathIndex:urlPathComponentIndex 
                                                                    startingTokenIndex:nextTokenIndex 
                                                                       targetPathIndex:targetUrlPathComponentIndex 
                                                                      targetTokenIndex:targetTokenIndex];
                            }
                        }
                        
                        if (parameterResult != nil) {
                            /**
                             We successfully matched. Add the other parameters to our own and return
                             */
                            [parameterDictionary addEntriesFromDictionary:parameterResult];
                            successfulMatchShortCircuit = YES;
                        }
                        else {
                            /**
                             This url is not a match for these tokens.
                             */
                            return nil;
                        }
                    }
                        break;
                        
                        /**
                         2. The next token is a parameter string
                         
                         If there are any more static strings in the rest of tokens, we have to go to the next one,
                         or to the end of the whole set of tokens, then match back from there to see if it matches
                         to us, and if it does we need to also match forwards from there to see if the rest of the 
                         url matches.
                         Examples:
                         
                         "/ ** / :param / a / **" should match all of the following
                         "urlscheme://b/a" (param = b)
                         "urlscheme://b/a/c/a" (param = b, left-weighted)
                         
                         "/ ** / :param / a / b / **" should match all of the following
                         "urlscheme://c/a/a/b" (param = a)
                         "urlscheme://d/c/a/b/a/b" (param = c, left-weighted)
                         "urlscheme:///c/a/d/a/b" (param = d)
                         
                         If there are no more static strings, we have to go to the end of the url and token list
                         then match backwards from there to here
                         
                         Examples:
                         
                         "/ ** / :param /" should match
                         "urlscheme://a/b/c/d" (param = d)
                         "urlscheme://a" (param = a)
                         
                         */
                        
                    case FSQRouteUrlTokenTypeParameter:
                        // intentionally fall through here
                        
                        /**
                         3. The next token is a single match wildcard
                         
                         Since the ** symbol can be any number 0+, it might might sense to put it next to
                         some single wildcards to ensure that a certain number of components exist
                         e.g. "/ * / ** /" is any path with at least one component
                         
                         This case is identical to case 2. except we don't store the parameter value
                         */
                        
                    case FSQRouteUrlTokenTypeSingleComponentWildcard:
                    {
                        // Find next static string token
                        NSInteger nextStaticStringTokenIndex = advanceTokenIndex(nextTokenIndex);
                        NSString *foundString = nil;
                        for (; 
                             nextStaticStringTokenIndex <= tokenIndexUpperBound
                             && nextStaticStringTokenIndex >= tokenIndexLowerBound; 
                             nextStaticStringTokenIndex = advanceTokenIndex(nextStaticStringTokenIndex)) {
                            FSQRouteUrlToken *nextToken = tokens[nextStaticStringTokenIndex];
                            if (nextToken.type == FSQRouteUrlTokenTypeString) {
                                // success
                                foundString = nextToken.stringOrParameterName;
                                break;
                            }
                        }
                        /**
                         At this point we are either at our next static string, or past the bounds
                         of our token search range.
                         
                         Step 1. If we're a static string, search from every future instance of that static
                         string back to us.
                         */
                        if (foundString) {
                            
                            NSInteger testedUrlPathComponentIndex = advancePathIndex(urlPathComponentIndex);
                            
                            for (; 
                                 testedUrlPathComponentIndex <= pathIndexUpperBound 
                                 && testedUrlPathComponentIndex >= pathIndexLowerBound
                                 && successfulMatchShortCircuit == NO; 
                                 testedUrlPathComponentIndex = advancePathIndex(testedUrlPathComponentIndex)) {
                                if ([urlPathComponents[testedUrlPathComponentIndex] isEqualToString:foundString]) {
                                    NSDictionary *backToUsResult = nil;
                                    backToUsResult = [self parametersForUrlPathComponents:urlPathComponents 
                                                                                   tokens:tokens 
                                                                        startingPathIndex:testedUrlPathComponentIndex 
                                                                       startingTokenIndex:nextStaticStringTokenIndex 
                                                                          targetPathIndex:urlPathComponentIndex 
                                                                         targetTokenIndex:tokenIndex];
                                    
                                    if (backToUsResult != nil) {
                                        /**
                                         We matched from there to here successfully. Now try matching
                                         forward from the static string to the rest of the string.
                                         */
                                        NSDictionary *forwardResult = [self parametersForUrlPathComponents:urlPathComponents 
                                                                                                    tokens:tokens 
                                                                                         startingPathIndex:testedUrlPathComponentIndex 
                                                                                        startingTokenIndex:nextStaticStringTokenIndex 
                                                                                           targetPathIndex:targetUrlPathComponentIndex 
                                                                                          targetTokenIndex:targetTokenIndex];
                                        if (forwardResult) {
                                            /**
                                             We successfully matched. Add the other parameters to our own and return
                                             */
                                            [parameterDictionary addEntriesFromDictionary:backToUsResult];
                                            [parameterDictionary addEntriesFromDictionary:forwardResult];
                                            successfulMatchShortCircuit = YES;
                                        }
                                    }
                                }
                            } // end static string searching for loop

                            if (!successfulMatchShortCircuit) {
                                /**
                                 If we got to here, that means the next static string doesn't appear in the rest
                                 of our path at all or all the cases that do don't match to us, so we are not a match.
                                 */
                                return nil;
                            }
                        }  // end foundString if statement
                        else {
                            /**
                             There are no more static strings in the rest of the tokens array so just try
                             matching from the bounds. nextStaticStringTokenIndex should be just pass the correct bounds
                             now if we are in this else statement so backtrack once.
                             */
                            NSDictionary *backToUsResult = [self parametersForUrlPathComponents:urlPathComponents 
                                                                                         tokens:tokens 
                                                                              startingPathIndex:targetUrlPathComponentIndex 
                                                                             startingTokenIndex:reverseTokenIndex(nextStaticStringTokenIndex)
                                                                                targetPathIndex:urlPathComponentIndex
                                                                               targetTokenIndex:tokenIndex];
                            if (backToUsResult) {
                                [parameterDictionary addEntriesFromDictionary:backToUsResult];
                                successfulMatchShortCircuit = YES;
                            }
                            
                        }
                    }
                        break;
                        
                        /**
                         4. This next token is an unlimited wildcard
                         
                         This shouldn't happen because we reduce them when tokenizing, but if for some
                         reason it does just skip ahead to it.
                         */
                        
                    case FSQRouteUrlTokenTypeUnlimitedComponentWildcard:
                    {
                        tokenIndex = advanceTokenIndex(tokenIndex);
                        NSAssert(0, @"There should not be two unlimited wildcard tokens in a row");
                    }
                        break;
                        
                }
                
            }
                break;
        }
    }
    
    /**
     The while loop has ended. 
     
     If both indexes reached their target values, then we matched successfully.
     If there are more tokens or path components to go then we did not match.
     */
    
    BOOL successfulMatch = NO;
    NSInteger finalParsedPathComponentIndex = reversePathIndex(urlPathComponentIndex);
    NSInteger finalParsedTokenIndex = reversePathIndex(tokenIndex);
    if (finalParsedPathComponentIndex == targetUrlPathComponentIndex
        && finalParsedTokenIndex == targetTokenIndex) {
        /**
         Both indexes made it to their target
         */
        successfulMatch = YES;
    }
    else if (finalParsedPathComponentIndex == targetUrlPathComponentIndex
             && tokenIndex == targetTokenIndex
             && tokens[tokenIndex].type == FSQRouteUrlTokenTypeUnlimitedComponentWildcard) {
        /**
         The path finished parsing, and there is one remaining token and it is an unlimited wildcard
         (which is allowed to match zero components, so this matches)
         */
        successfulMatch = YES;
    }
    
    if (successfulMatchShortCircuit || successfulMatch) {
            return parameterDictionary;
        }
    else {
        return nil;
    }
}


- (void)matchRouteForUrl:(NSURL *)url completionBlock:(void (^)(BOOL matched, 
                                                                BOOL isNativeScheme,
                                                                FSQRouteContentGenerator *_Nullable contentGenerator, 
                                                                FSQRouteUrlData *_Nullable urlData))completionBlock {
    if (url != nil) {
        BOOL isNativeScheme = NO;
        NSArray<NSArray *> *routeMap = [self routeMapForUrl:url isNativeScheme:&isNativeScheme];
        
        FSQRouteUrlData *urlData = [FSQRouteUrlData new];
        urlData.url = url;
        
        if (routeMap.count > 0) {
            __block BOOL foundMatch = NO;
            
            [routeMap enumerateObjectsUsingBlock:^(NSArray *pair, NSUInteger idx, BOOL *stop) {
                NSArray<FSQRouteUrlToken *> *tokenizedPath = [pair firstObject];
                FSQRouteContentGenerator *contentGenerator = [pair lastObject];
                
                if (tokenizedPath.count == 0
                    || contentGenerator == nil) {
                    return;
                }
                
                NSDictionary<NSString *, NSString *> *parameters = [self parametersForUrl:url
                                                                           ifMatchingPath:tokenizedPath];
                
                if (parameters != nil) {
                    *stop = YES;
                    urlData.parameters = parameters;

                    foundMatch = YES;
                    completionBlock(YES, isNativeScheme, contentGenerator, urlData);
                }
            }];
            
            if (!foundMatch) {
                // Need to ensure completion block is called
                completionBlock(NO, isNativeScheme, nil, urlData);
            }
        }
        else {
            completionBlock(NO, isNativeScheme, nil, urlData);
        }
    }
    else {
        completionBlock(NO, NO, nil, nil);
    }
}

#pragma mark - URL routing methods -

- (void)routeUrl:(NSURL *)url {
    [self routeUrl:url notificationUserInfo:nil];
}

- (void)routeUrl:(NSURL *)url notificationUserInfo:(nullable NSDictionary *)notificationUserInfo {
    [self clearDeferredRoute];
    
    [self matchRouteForUrl:url 
           completionBlock:^(BOOL matched, 
                             BOOL isNativeScheme, 
                             FSQRouteContentGenerator * _Nullable contentGenerator, 
                             FSQRouteUrlData * _Nullable urlData) {
               if (matched && contentGenerator != nil) {
                   urlData.notificationUserInfo = notificationUserInfo;
                   
                   [self routeOrDeferContentGenerator:contentGenerator urlData:urlData];                  
               }
               else {
                   [self.delegate urlRouter:self failedToRouteUrl:url notificationUserInfo:notificationUserInfo];
               }
           }];
}

- (void)routeUrl:(NSURL *)url notificationUserInfo:(nullable NSDictionary *)notificationUserInfo usingGenerator:(FSQRouteContentGenerator *)generator {
    FSQRouteUrlData *urlData = [FSQRouteUrlData new];
    urlData.url = url;
    urlData.notificationUserInfo = notificationUserInfo;
    
    NSMutableDictionary *mutableParameters = [NSMutableDictionary new];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:YES];
    
    for (NSURLQueryItem *item in urlComponents.queryItems) {
        mutableParameters[item.name] = item.value;
    }
    
    urlData.parameters = mutableParameters.copy;
    
    [self routeOrDeferContentGenerator:generator urlData:urlData];
}

- (void)routeOrDeferContentGenerator:(FSQRouteContentGenerator *)contentGenerator urlData:(FSQRouteUrlData *)urlData {
    [self clearDeferredRoute];
    
    FSQUrlRoutingControl routingControl = FSQUrlRouterAllowRouting;
    
    if (self.delegate) {
        routingControl = [self.delegate urlRouter:self shouldGenerateRouteContent:contentGenerator withUrlData:urlData];
    }
    
    switch (routingControl) {
        case FSQUrlRouterAllowRouting: {
            FSQRouteContent *routeContent = [contentGenerator generateRouteContentFromUrlData:urlData];
            if (routeContent == nil) {
                [self.delegate urlRouter:self failedToGenerateContent:contentGenerator urlData:urlData];
            }
            else {
                if (routeContent.defaultPresentation == nil) {
                    routeContent.defaultPresentation = self.defaultRoutedUrlPresentation;
                }
                [self routeOrDeferContent:routeContent];                
            }
        }
            break;
        case FSQUrlRouterCancelRouting: {
            // Do nothing
        }
            break;
        case FSQUrlRouterDeferRouting: {
            self.deferredRoute = ^(FSQUrlRouter *router) {
                [router routeOrDeferContentGenerator:contentGenerator urlData:urlData];
            };
        }
            break;
    } 
}

- (void)routeOrDeferContent:(FSQRouteContent *)routeContent {
     [self clearDeferredRoute];
    
    FSQUrlRoutingControl routingControl = FSQUrlRouterAllowRouting;
    
    if (self.delegate) {
        routingControl = [self.delegate urlRouter:self shouldPresentRoute:routeContent];
    }
    
    switch (routingControl) {
        case FSQUrlRouterAllowRouting: {
            [self.delegate urlRouter:self routedUrlWillBePresented:routeContent];
            [routeContent present];
            [self.delegate urlRouter:self routedUrlDidGetPresented:routeContent];
        }
            break;
        case FSQUrlRouterCancelRouting: {
            // Do nothing
        }
            break;
        case FSQUrlRouterDeferRouting: {
            self.deferredRoute = ^(FSQUrlRouter *router) {
                [router routeOrDeferContent:routeContent];
            };
        }
            break;
    } 
}


#pragma mark - Route deferral -

- (void)handleDeferredRoute {
    if (self.deferredRoute) {
        self.deferredRoute(self);
    }
}

- (BOOL)hasDeferredRoute {
    return !!self.deferredRoute;
}

- (void)clearDeferredRoute {
    self.deferredRoute = nil;
}

#pragma mark - Public manual route generation - 

- (nullable FSQRouteContent *)generateRouteContentFromUrl:(NSURL *)url {
    return [self generateRouteContentFromUrl:url notificationUserInfo:nil];
}

- (nullable FSQRouteContent *)generateRouteContentFromUrl:(NSURL *)url 
                                     notificationUserInfo:(nullable NSDictionary *)notificationUserInfo {
    
    __block FSQRouteContent *content = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self matchRouteForUrl:url 
           completionBlock:^(BOOL matched, 
                             BOOL isNativeScheme, 
                             FSQRouteContentGenerator * _Nullable contentGenerator, 
                             FSQRouteUrlData * _Nullable urlData) {
               if (matched && contentGenerator != nil) {
                   urlData.notificationUserInfo = notificationUserInfo;
                   content = [contentGenerator generateRouteContentFromUrlData:urlData];
                   if (content.defaultPresentation == nil) {
                       content.defaultPresentation = self.defaultRoutedUrlPresentation;
                   }
               }
               dispatch_semaphore_signal(semaphore);
           }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);   
    return content;
}

#pragma mark - Test-only methods - 

- (NSDictionary<NSString *, NSString *> *)parametersForUrlString:(NSString *)urlString matchingAgainstRoute:(NSString *)routeString {
    NSArray<FSQRouteUrlToken *> *tokens = [self tokenizedRouteString:routeString];
    
    return [self parametersForUrl:[NSURL URLWithString:urlString] ifMatchingPath:tokens];
}

@end


@implementation FSQRouteUrlToken

+ (instancetype)withString:(NSString *)string {
    FSQRouteUrlToken *token = [self new];
    token->_type = FSQRouteUrlTokenTypeString;
    token->_stringOrParameterName = [string copy];
    return token;
}

+ (instancetype)withParameterName:(NSString *)parameterName {
    FSQRouteUrlToken *token = [self new];
    token->_type = FSQRouteUrlTokenTypeParameter;
    token->_stringOrParameterName = [parameterName copy];
    return token;
}

+ (instancetype)singleComponentWildCard {
    static FSQRouteUrlToken *token;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        token = [self new];
        token->_type = FSQRouteUrlTokenTypeSingleComponentWildcard;
    });
    
    return token;
}

+ (instancetype)unlimitedComponentWildCard {
    static FSQRouteUrlToken *token;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        token = [self new];
        token->_type = FSQRouteUrlTokenTypeUnlimitedComponentWildcard;
    });
    
    return token;
}

- (NSString *)stringForType:(FSQRouteUrlTokenType)type {
    switch (type) {
        case FSQRouteUrlTokenTypeString:
            return @"string";
        case FSQRouteUrlTokenTypeParameter:
            return @"parameter";
        case FSQRouteUrlTokenTypeSingleComponentWildcard:
            return @"*";
        case FSQRouteUrlTokenTypeUnlimitedComponentWildcard:
            return  @"**";
    }
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@, (%@)", [self stringForType:self.type], self.stringOrParameterName];
}

@end

NS_ASSUME_NONNULL_END