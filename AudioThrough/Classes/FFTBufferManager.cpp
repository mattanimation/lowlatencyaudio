/*
 
 File: FFTBufferManager.cpp
 
 Abstract: This class manages buffering and computation for FFT analysis
 on input audio data. The methods provided are used to grab the audio, 
 buffer it, and perform the FFT when sufficient data is available
 
*/

#include "FFTBufferManager.h"

#define min(x,y) (x < y) ? x : y

FFTBufferManager::FFTBufferManager() :
	mNeedsAudioData(0),
	mHasAudioData(0),
	mAudioBufferSize(kDefaultFFTBufferSize * sizeof(int32_t))
{
	mAudioBuffer = (int32_t*)malloc(mAudioBufferSize);	
	mSpectrumAnalysis = SpectrumAnalysisCreate(kDefaultFFTBufferSize);
	OSAtomicIncrement32Barrier(&mNeedsAudioData);
}

FFTBufferManager::~FFTBufferManager()
{
	free(mAudioBuffer);
	SpectrumAnalysisDestroy(mSpectrumAnalysis);
}

void FFTBufferManager::GrabAudioData(AudioBufferList *inBL)
{
	if (mAudioBufferSize < inBL->mBuffers[0].mDataByteSize)	return;
	
	UInt32 bytesToCopy = min(inBL->mBuffers[0].mDataByteSize, mAudioBufferSize - mAudioBufferCurrentIndex);
	memcpy(mAudioBuffer+mAudioBufferCurrentIndex, inBL->mBuffers[0].mData, bytesToCopy);
	
	mAudioBufferCurrentIndex += bytesToCopy / sizeof(int32_t);
	if (mAudioBufferCurrentIndex >= mAudioBufferSize / sizeof(int32_t))
	{
		OSAtomicIncrement32Barrier(&mHasAudioData);
		OSAtomicDecrement32Barrier(&mNeedsAudioData);
	}
}

Boolean	FFTBufferManager::ComputeFFT(int32_t *outFFTData)
{
	if (HasNewAudioData())
	{
		SpectrumAnalysisProcess(mSpectrumAnalysis, mAudioBuffer, outFFTData, true);		
		OSAtomicDecrement32Barrier(&mHasAudioData);
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
		mAudioBufferCurrentIndex = 0;
		return true;
	}
	else if (mNeedsAudioData == 0)
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
	
	return false;
}
