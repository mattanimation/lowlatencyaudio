//
//  AudioThroughAppDelegate.m
//  AudioThrough
//
//  Created by Pat O'Keefe on 2/18/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "AudioThroughAppDelegate.h"
#import "AudioThroughViewController.h"
#import "AudioUnit/AudioUnit.h"
#import "CAXException.h"


@implementation AudioThroughAppDelegate

// FYI: The file extension is .mm
// Why is that? Because the compiler recognizes .mm for a C++ file that uses Objective-C...brilliant


@synthesize window;
@synthesize viewController;
@synthesize rioUnit;
@synthesize unitIsRunning;
@synthesize fftBufferManager;
@synthesize mute;
@synthesize inputProc;
@synthesize write;
@synthesize fftArray;





void propListener(	void *                  inClientData,
				  AudioSessionPropertyID	inID,
				  UInt32                  inDataSize,
				  const void *            inData)
{
	NSLog(@"propListener");
	AudioThroughAppDelegate *THIS = (AudioThroughAppDelegate*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		try {
			// if there was a route change, we need to dispose the current rio unit and create a new one
			XThrowIfError(AudioComponentInstanceDispose(THIS->rioUnit), "couldn't dispose remote i/o unit");		
			
			SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat);
			
			UInt32 size = sizeof(THIS->hwSampleRate);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &THIS->hwSampleRate), "couldn't get new sample rate");
			
			XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
			
			// we need to rescale the sonogram view's color thresholds for different input
			CFStringRef newRoute;
			size = sizeof(CFStringRef);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute), "couldn't get new audio route");
			if (newRoute)
			{	
				CFShow(newRoute);
				if (CFStringCompare(newRoute, CFSTR("Headset"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					//Do something if you'd like
					
					
				}
				else if (CFStringCompare(newRoute, CFSTR("Receiver"), NULL) == kCFCompareEqualTo) // headset plugged in
				{
					//Do something if you'd like
					
					
				}			
				else		//Something else must be plugged in...Third party?
				{
					
					//Do something if you'd like
					
				}
			}
		} catch (CAXException e) {
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
		
	}
}






static OSStatus	PerformThru(
							void						*inRefCon, 
							AudioUnitRenderActionFlags 	*ioActionFlags, 
							const AudioTimeStamp 		*inTimeStamp, 
							UInt32 						inBusNumber, 
							UInt32 						inNumberFrames, 
							AudioBufferList 			*ioData)
{
	
	AudioThroughAppDelegate *THIS = (AudioThroughAppDelegate *)inRefCon;
	

	
	
	OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { printf("THIS IS HORRIBLE NEWS...PerformThru: error %d\n", (int)err); return err; }
	
	// Remove DC component
	for(UInt32 i = 0; i < ioData->mNumberBuffers; ++i)
		THIS->dcFilter[i].InplaceFilter((SInt32*)(ioData->mBuffers[i].mData), inNumberFrames, 1);
	
	
	int i;
	
	if (THIS->write) {
		SInt32 *data_ptr = (SInt32 *)(ioData->mBuffers[0].mData);
		
		
		for (i=0; i<inNumberFrames; i++)
		{
			printf("%d, ",data_ptr[i]);
			
		}
		
		
		THIS->write = NO;
	}
	

	if (THIS->fftBufferManager == NULL) return noErr;
	
	if (THIS->fftBufferManager->NeedsNewAudioData())
	{
		THIS->fftBufferManager->GrabAudioData(ioData); 
	}
	
	
	if (THIS->mute == YES) { SilenceData(ioData); }
	
	return err;
}



- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
	
	// Setting this to YES keeps the iPhone/iPod Touch from locking (screen turning off)
	// There's no reason to do it here, but I thought I'd comment on what it does because it show up in aurioTouch
	application.idleTimerDisabled = YES;
	
	
	NSLog(@"Attempting to Initialize RemoteIO...");
	
	
	
	// mute should NOT be on at launch
	self.mute = NO;
	
	// Initialize our remote i/o unit
	
	inputProc.inputProc = PerformThru;
	inputProc.inputProcRefCon = self;
	
	fftBufferManager = new FFTBufferManager();
	CFURLRef url = NULL;
	try {	
		
		// Initialize and configure the audio session
		XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, self), "couldn't initialize audio session");
		XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
		
		
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
		
		// The entire purpose of the propListener is to detect a change in signal flow (headphones w/ mic or even third party device)
		XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self), "couldn't set property listener");
		
		
		// This value is in seconds!
		Float32 preferredBufferSize = .005; //.005
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");
		
		
		// Related to our propListener. When the signal flow changes, sometimes the hardware sample rate can change. You'll notice in the propListener it checks for a new one.
		UInt32 size = sizeof(hwSampleRate);
		XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
		NSLog(@"Hardware sample rate is: %f", hwSampleRate);
		
		
			//Hello
		
		
		//Describe audio format
		AudioStreamBasicDescription audioFormat;
		audioFormat.mSampleRate = 44100.0;
		audioFormat.mFormatID = kAudioFormatLinearPCM;
		audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		audioFormat.mFramesPerPacket = 1;
		audioFormat.mChannelsPerFrame = 1;
		audioFormat.mBitsPerChannel = 16;
		audioFormat.mBytesPerPacket = 2;
		audioFormat.mBytesPerFrame = 2;

		
		
		
		// Most important call in the entire try. SetupRemoteIO is defined in aurio_helper.h
		XThrowIfError(SetupRemoteIO(rioUnit, inputProc, audioFormat), "couldn't setup remote i/o unit");

		
		dcFilter = new DCRejectionFilter[thruFormat.NumberChannels()];
		
		XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
		unitIsRunning = 1;
	}
	catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		unitIsRunning = 0;
		if (dcFilter) delete[] dcFilter;
		if (url) CFRelease(url);
	}
	catch (...) {
		fprintf(stderr, "OHHHH NOOOOOO...An unknown error occurred!\n");
		unitIsRunning = 0;
		if (dcFilter) delete[] dcFilter;
		if (url) CFRelease(url);
	}
	
	
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
	//Start Initialization Timer that calls our FFT Stuff
	sweetTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(doSomething) userInfo:nil repeats:YES];
	self.fftArray = [[NSMutableArray alloc] initWithCapacity:kNumDrawBuffers];

}


// Is this method accomplishing anything? Most likely not. You can see the printf statement commented out below. It just kept printing 0 for the value...
// Somehow this gets our FFT data in a usable form. You guys are probably much better than I am with this stuff so please let me know if you figure something out.
- (void)doSomething {
		

			
		if (fftBufferManager->HasNewAudioData())
		{
			if (fftBufferManager->ComputeFFT(l_fftData))
				[self setFFTData:l_fftData length:kDefaultFFTBufferSize / 2];
			else
				hasNewFFTData = NO;
		}
		
		if (hasNewFFTData)
		{
			
			[fftArray removeAllObjects];
			
			int y, maxY;
			maxY = drawBufferLen;
			for (y=0; y<maxY; y++)
			{
				CGFloat yFract = (CGFloat)y / (CGFloat)(maxY - 1);
				CGFloat fftIdx = yFract * ((CGFloat)fftLength);
				
				double fftIdx_i, fftIdx_f;
				fftIdx_f = modf(fftIdx, &fftIdx_i);
				
				SInt8 fft_l, fft_r;//8
				CGFloat fft_l_fl, fft_r_fl;
				CGFloat interpVal;
				
				fft_l = (fftData[(int)fftIdx_i] & 0xFF000000) >> 24;
				fft_r = (fftData[(int)fftIdx_i + 1] & 0xFF000000) >> 24;
				fft_l_fl = (CGFloat)(fft_l + 80) / 64.;
				fft_r_fl = (CGFloat)(fft_r + 80) / 64.;
				interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
				
				interpVal = CLAMP(0., interpVal, 1.);

								
				[fftArray addObject:[NSNumber numberWithFloat:(interpVal*120)]];
			
			}
			
			
			//if (self.write) {
				
				int index = 0, maxIndex = 0;
				NSNumber *max = [NSNumber numberWithFloat:0.0];
				
				for (NSNumber *element in fftArray) {
					
					if ([max compare:element] == NSOrderedAscending && (index < 500)){
						maxIndex = index; 
						max = element;
					}
					index++;
				}
				
				//NSLog(@"The hwSampleRate is %f, and the number of buffers is %d", hwSampleRate,kDefaultFFTBufferSize);
				
				[viewController changeLabel:(int)(maxIndex*(hwSampleRate/2)/kDefaultFFTBufferSize)];
				
			//	self.write = NO;
			//}
		}
		
	
}


- (void)setFFTData:(int32_t *)FFTDATA length:(NSUInteger)LENGTH
{
	if (LENGTH != fftLength)
	{
		fftLength = LENGTH;
		fftData = (SInt32 *)(realloc(fftData, LENGTH * sizeof(SInt32)));
	}
	memmove(fftData, FFTDATA, fftLength * sizeof(Float32));
	hasNewFFTData = YES;
}


- (void)dealloc {
	delete[] dcFilter;
	delete fftBufferManager;
	
    [viewController release];
    [window release];
    [super dealloc];
}


@end
