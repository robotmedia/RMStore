//
//  RMTestObserver.m
//  RMStore
//
//  Created by Hermes on 10/9/13.
//  Copyright (c) 2013 Robot Media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SenTestingKit/SenTestingKit.h>


/**
 Xcode 5 stopped generating .gcda files so we need to force them with __gcov_flush when the test suite stops.
 See: http://stackoverflow.com/questions/18394655/xcode5-code-coverage-from-cmd-line-for-ci-builds
 */
@interface RMTestObserver : SenTestLog

@end

static id mainSuite = nil;

@implementation RMTestObserver

// __gcov_flush might be undefined in Release configurations (e.g., Travis CI)
#ifdef DEBUG
+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] setValue:NSStringFromClass(self) forKey:SenTestObserverClassKey];

    [super initialize];
}

+ (void)testSuiteDidStart:(NSNotification*)notification
{
    [super testSuiteDidStart:notification];

    SenTestSuiteRun* suite = notification.object;

    if (!mainSuite)
    {
        mainSuite = suite;
    }
}

extern void __gcov_flush(void);

+ (void)testSuiteDidStop:(NSNotification*)notification
{
    [super testSuiteDidStop:notification];
    
    SenTestSuiteRun* suite = notification.object;
    
    if (mainSuite == suite)
    {
        __gcov_flush();
    }
}
#endif

@end
