//
//  IM_TestAppDelegate.m
//  IM_Test
//
//  Created by Claudio Marforio on 7/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "IM_TestAppDelegate.h"
#import "IM_TestViewController.h"

@implementation IM_TestAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
