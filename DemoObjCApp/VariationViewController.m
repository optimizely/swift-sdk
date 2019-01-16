//
//  VariationViewController.m
//  DemoObjcApp
//
//  Created by Jae Kim on 1/14/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

#import "VariationViewController.h"
@import OptimizelySwiftSDK;

@interface VariationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *variationLetterLabel;
@property (weak, nonatomic) IBOutlet UILabel *variationSubheaderLabel;
@property (weak, nonatomic) IBOutlet UIImageView *variationBackgroundImage;
@end

@implementation VariationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    if ([self.variationKey isEqualToString:@"variation_a"]) {
        self.variationLetterLabel.text = @"A";
        self.variationLetterLabel.textColor = [UIColor blackColor];
        self.variationSubheaderLabel.textColor = [UIColor blackColor];
        self.variationBackgroundImage.image = [UIImage imageNamed:@"background_variA"];
    } else {
        self.variationLetterLabel.text = @"B";
        self.variationLetterLabel.textColor = [UIColor whiteColor];
        self.variationSubheaderLabel.textColor = [UIColor whiteColor];
        self.variationBackgroundImage.image = [UIImage imageNamed:@"background_variB-marina"];
    }
}

- (IBAction)unwindToVariationAction:(UIStoryboardSegue *)segue {
    
}

- (IBAction)attemptTrackAndShowSuccessOrFailure:(id)sender {
    NSError *error;
    BOOL status = [self.optimizelyManager trackWithEventKey:self.eventKey
                                                     userId:self.userId
                                                 attributes:nil eventTags:nil
                                                      error:&error];
    
    if (status) {
        [self performSegueWithIdentifier:@"ConversionSuccessSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"ConversionFailureSegue" sender:self];
    }
}


@end
