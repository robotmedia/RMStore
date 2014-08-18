//
//  RMTestObserver.m
//  RMStore
//
//  Created by Hermes on 10/9/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


/**
 Xcode 5 stopped generating .gcda files so we need to force them with __gcov_flush when the test suite stops.
 See: http://stackoverflow.com/questions/18394655/xcode5-code-coverage-from-cmd-line-for-ci-builds
 */
@interface RMTestObserver : XCTestLog

@end

static id mainSuite = nil;

@implementation RMTestObserver

// __gcov_flush might be undefined in Release configurations (e.g., Travis CI)
#ifdef DEBUG
+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] setValue:NSStringFromClass(self) forKey:XCTestObserverClassKey];

    [super initialize];
}

- (void)testSuiteDidStart:(XCTestRun *)testRun
{
    [super testSuiteDidStart:testRun];

    XCTestSuiteRun* suite = [[XCTestSuiteRun alloc] init];
    [suite addTestRun:testRun];

    if (!mainSuite) {
        mainSuite = suite;
    }
}

extern void __gcov_flush(void);

- (void) testSuiteDidStop:(XCTestRun *) testRun
{
    [super testSuiteDidStop:testRun];
    XCTestSuiteRun *suite = [[XCTestSuiteRun alloc] init];
    [suite addTestRun:testRun];
        
    if (mainSuite == suite)
    {
        __gcov_flush();
    }
}

#endif
@end
