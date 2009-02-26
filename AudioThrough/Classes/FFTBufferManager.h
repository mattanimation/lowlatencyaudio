/*
 
 File: FFTBufferManager.h
 
 Abstract: This class manages buffering and computation for FFT analysis
 on input audio data. The methods provided are used to grab the audio, 
 buffer it, and perform the FFT when sufficient data is available
 
*/

#include <AudioToolbox/AudioToolbox.h>
#include <libkern/OSAtomic.h>

#include "SpectrumAnalysis.h"

#define kDefaultFFTBufferSize 512

class FFTBufferManager
{
public:
	FFTBufferManager();
	~FFTBufferManager();
	
	volatile int32_t HasNewAudioData()	{ return mHasAudioData; }
	volatile int32_t NeedsNewAudioData() { return mNeedsAudioData; }

	void			GrabAudioData(AudioBufferList *inBL);
	Boolean			ComputeFFT(int32_t *outFFTData);
	
private:
	volatile int32_t mNeedsAudioData;
	volatile int32_t mHasAudioData;
	
	H_SPECTRUM_ANALYSIS mSpectrumAnalysis;
	
	int32_t	*mAudioBuffer;
	UInt32	mAudioBufferSize;
	int32_t	mAudioBufferCurrentIndex;
};