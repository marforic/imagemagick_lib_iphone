//
//  IM_TestAppDelegate.h
//  IM_Test
//
//  Created by Claudio Marforio on 7/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IM_TestViewController;

@interface IM_TestAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    IM_TestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet IM_TestViewController *viewController;

@end

