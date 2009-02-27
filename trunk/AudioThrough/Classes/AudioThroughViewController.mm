//
//  AudioThroughViewController.m
//  AudioThrough
//
//  Created by Pat O'Keefe on 2/18/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "AudioThroughViewController.h"



@implementation AudioThroughViewController

@synthesize ourSwitch;
@synthesize appDelegateReference;
@synthesize freqLabel;
@synthesize slider;



- (void)viewDidLoad {
    
	
	//Create a reference to the app Delegate so we can control all of the audio stuff going on in there...
	self.appDelegateReference = (AudioThroughAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[super viewDidLoad];
}

- (IBAction)saveSomeData:(id)sender {
	NSLog(@"saveSomeData was called");
	
	//This will eventually write some of our arrays to a text file so we can look at them
	//off of the iPhone. Shouldn't be too hard to implement.
	
	self.appDelegateReference.write = YES;
	
	
}

- (IBAction)sliderChanged:(id)sender {
	NSLog(@"sliderChanged");
	self.appDelegateReference.gain = [slider value];
	
}

- (IBAction)toggleMute:(id)sender {
	NSLog(@"toggleMute was called");
	self.appDelegateReference.mute = (self.appDelegateReference.mute) ? NO : YES;
	
}

- (void)changeLabel:(int)newFrequency {
	
	self.freqLabel.text = [NSString stringWithFormat:@"%d Hz",newFrequency,nil];
	
	
	
}



- (void)dealloc
{	
	
	[super dealloc];
}



/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


@end
