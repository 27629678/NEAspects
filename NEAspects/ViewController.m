//
//  ViewController.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "ViewController.h"

#import "NEAspects.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self aspect_hookSelector:@selector(viewWillAppear:) withOption:NEAspectPositionAfter usingBlock:^{
        NSLog(@"aspect did execute block.");
    } error:nil];
    
    [self aspect_hookSelector:@selector(viewDidAppear:) withOption:NEAspectPositionBefore usingBlock:^ {
        NSLog(@"aspect view did appear excute.");
    } error:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSLog(@"view did appear.");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
