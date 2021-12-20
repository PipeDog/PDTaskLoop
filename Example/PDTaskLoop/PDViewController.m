//
//  PDViewController.m
//  PDTaskLoop
//
//  Created by liang on 12/17/2021.
//  Copyright (c) 2021 liang. All rights reserved.
//

#import "PDViewController.h"
#import <PDTaskLoop.h>

@interface PDViewController ()

@end

@implementation PDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    [self addTasks];
}

- (void)addTasks {
    NSLog(@"=====================\n\n");
    
    PDTaskLoop *taskLoop = [PDTaskLoop taskLoopForName:@"TestTaskLoop"];
    
    for (int i = 0; i < 10; i++) {
        [taskLoop addTask:^{
            NSLog(@">>>>> i = %d", i);
        }];
    }
        
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addTasks];
    });
}

- (IBAction)didClickRunButton:(id)sender {
    PDTaskLoop *taskLoop = [PDTaskLoop taskLoopForName:@"TestTaskLoop"];
    [taskLoop run];
}

- (IBAction)didClickShutdownButton:(id)sender {
    PDTaskLoop *taskLoop = [PDTaskLoop taskLoopForName:@"TestTaskLoop"];
    [taskLoop shutdown];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
