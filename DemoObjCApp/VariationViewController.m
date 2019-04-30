/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

#import "VariationViewController.h"
@import Optimizely;

@interface VariationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *variationLetterLabel;
@property (weak, nonatomic) IBOutlet UILabel *variationSubheaderLabel;
@property (weak, nonatomic) IBOutlet UIImageView *variationBackgroundImage;
@end

@implementation VariationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
    
    BOOL status = [self.optimizely trackWithEventKey:self.eventKey userId:self.userId attributes:nil eventTags:nil error:&error];
    
    if (status) {
        [self performSegueWithIdentifier:@"ConversionSuccessSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"ConversionFailureSegue" sender:self];
    }
}


@end
