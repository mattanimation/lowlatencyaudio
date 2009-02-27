//
//  AudioThroughViewController.h
//  AudioThrough
//
//  Created by Pat O'Keefe on 2/18/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

//Necessary for right now. Not ideal...
#import "AudioThroughAppDelegate.h"



@interface AudioThroughViewController : UIViewController {
	IBOutlet UISwitch *ourSwitch;
	IBOutlet UISlider *slider;
	AudioThroughAppDelegate *appDelegateReference;	
	
	IBOutlet UILabel *freqLabel;
	
}

@property (nonatomic, retain) IBOutlet UISwitch *ourSwitch;
@property (nonatomic, retain) IBOutlet UILabel *freqLabel;
@property (nonatomic, retain) AudioThroughAppDelegate *appDelegateReference;	
@property (nonatomic, retain) IBOutlet UISlider *slider;

- (IBAction)saveSomeData:(id)sender;
- (IBAction)toggleMute:(id)sender;
- (IBAction)sliderChanged:(id)sender;
- (void)changeLabel:(int)newFrequency;

@end

