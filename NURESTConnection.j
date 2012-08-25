/*
****************************************************************************
*
*   Filename:         NURESTConnection.j
*
*   Created:          Mon Apr  2 11:23:45 PST 2012
*
*   Description:      Cappuccino UI
*
*   Project:          Cloud Network Automation - Nuage - Data Center Service Delivery - IPD
*
*
***************************************************************************
*
*                 Source Control System Information
*
*   $Id: something $
*
*
*
****************************************************************************
*
* Copyright (c) 2011-2012 Alcatel, Alcatel-Lucent, Inc. All Rights Reserved.
*
* This source code contains confidential information which is proprietary to Alcatel.
* No part of its contents may be used, copied, disclosed or conveyed to any party
* in any manner whatsoever without prior written permission from Alcatel.
*
* Alcatel-Lucent is a trademark of Alcatel-Lucent, Inc.
*
*
*****************************************************************************
*/

@import <Foundation/CPURLConnection.j>

NURESTConnectionResponseCodeZero = 0;
NURESTConnectionResponseCodeSuccess = 200;
NURESTConnectionResponseCodeEmpty = 204;
NURESTConnectionResponseCodeNotFound = 404;
NURESTConnectionResponseCodeInternalServerError = 500;
NURESTConnectionResponseCodeServiceUnavailable = 503;
NURESTConnectionResponseCodeUnauthorized = 401;
NURESTConnectionResponseCodePermissionDenied = 403;
NURESTConnectionResponseCodeMoved = 300;

/*! Enhanced version of CPURLConnection
*/
@implementation NURESTConnection : CPObject
{
    CPData          _responseData           @accessors(getter=responseData);
    CPURLRequest    _request                @accessors(property=request);
    id              _target                 @accessors(property=target);
    id              _userInfo               @accessors(property=userInfo);
    id              _internalUserInfo       @accessors(property=internalUserInfo);
    int             _responseCode           @accessors(getter=responseCode);
    SEL             _selector               @accessors(property=selector);
    CPString        _errorMessage           @accessors(property=errorMessage);
    BOOL            _usesAuthentication     @accessors(property=usesAuthentication);

    BOOL            _isCanceled;
    HTTPRequest     _HTTPRequest;
}


#pragma mark -
#pragma mark Class Methods

/*! Initialize a new NURESTConnection
    @param aRequest the CPURLRequest to send
    @param anObject a random object that is the target of the result events
    @param aSuccessSelector the selector to send to anObject in case of success
    @param anErrorSelector the selector to send to anObject in case of error
    @return NURESTConnection fully ready NURESTConnection
*/
+ (NURESTConnection)connectionWithRequest:(CPURLRequest)aRequest
                                  target:(CPObject)anObject
                                selector:(SEL)aSelector
{
    var connection = [[NURESTConnection alloc] initWithRequest:aRequest];
    [connection setTarget:anObject];
    [connection setSelector:aSelector];

    return connection;
}


#pragma mark -
#pragma mark Initialization

/*! Initialize a NURESTConnection with a CPURLRequest
    @param aRequest the request to user
*/
- (void)initWithRequest:aRequest
{
    if (self = [super init])
    {
        _request = aRequest;
        _isCanceled = NO;
        _usesAuthentication = YES;
        _HTTPRequest = new CFHTTPRequest();
    }

    return self;
}

/*! Start the connection
*/
- (void)start
{
    _isCanceled = NO;

    try
    {

        _HTTPRequest.open([_request HTTPMethod], [[_request URL] absoluteString], YES);

        _HTTPRequest.onreadystatechange = function() { [self _readyStateDidChange]; }

        var fields = [_request allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];

        while (key = [keys nextObject])
            _HTTPRequest.setRequestHeader(key, [fields objectForKey:key]);

        if (_usesAuthentication)
            _HTTPRequest.setRequestHeader("Authorization", [[NURESTLoginController defaultController] authString]);

        _HTTPRequest.send([_request HTTPBody]);
    }
    catch (anException)
    {
        _errorMessage = anException;
        if (_target && _selector)
            [_target performSelector:_selector withObject:self];
    }
}

/*! Abort the connection
*/
- (void)cancel
{
    _isCanceled = YES;

    try { _HTTPRequest.abort(); } catch (anException) {}
}

- (void)reset
{
    _HTTPRequest = new CFHTTPRequest();
    _responseData = nil;
    _responseCode = nil;
    _errorMessage = nil;
}

/*! @ignore
*/
- (void)_readyStateDidChange
{
    if (_HTTPRequest.readyState() === CFHTTPRequest.CompleteState)
    {
        _responseCode = _HTTPRequest.status();
        _responseData = [CPData dataWithRawString:_HTTPRequest.responseText()];

        if (_target && _selector)
            [_target performSelector:_selector withObject:self];

        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
    }
}

@end