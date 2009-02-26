//
//  AudioThroughAppDelegate.h
//  AudioThrough
//
//  Created by Pat O'Keefe on 2/18/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <CoreFoundation/CFURL.h>


#import "FFTBufferManager.h"
#import "aurio_helper.h"
#import "CAStreamBasicDescription.h"
#include <libkern/OSAtomic.h>

#ifndef CLAMP
#define CLAMP(min,x,max) (x < min ? min : (x > max ? max : x))
#endif

#define kOurBufferCount 1


@class AudioThroughViewController;

inline double linearInterp(double valA, double valB, double fract)
{
	return valA + ((valB - valA) * fract);
}

@interface AudioThroughAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    AudioThroughViewController *viewController;
	
	SInt32						*fftData;
	NSUInteger					fftLength;
	BOOL						hasNewFFTData, mute;
	AudioUnit					rioUnit;
	int							unitIsRunning;
	FFTBufferManager			*fftBufferManager;
	DCRejectionFilter			*dcFilter;
	CAStreamBasicDescription	thruFormat;
	Float64						hwSampleRate;
	
	AURenderCallbackStruct		inputProc;
	
	int32_t						l_fftData[kDefaultFFTBufferSize/2];
	NSTimer						*sweetTimer;

	BOOL						write;
	NSMutableArray				*fftArray;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet AudioThroughViewController *viewController;



@property							FFTBufferManager *fftBufferManager;

@property AudioUnit					rioUnit;
@property int						unitIsRunning;
@property BOOL						mute, write;
@property AURenderCallbackStruct	inputProc;

@property (nonatomic, retain)	NSMutableArray				*fftArray;




- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH;
- (void)doSomething;

@end

