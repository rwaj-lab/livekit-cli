package main

import (
	"fmt"
	"github.com/livekit/livekit-cli/v2/pkg/provider"
)

func main() {
	fmt.Println("Testing VP9 codec with very-high resolution...")
	
	// Test VP9 codec
	loopers, err := provider.CreateVideoLoopers("very-high", "vp9", false)
	if err != nil {
		fmt.Printf("Error creating VP9 loopers: %v\n", err)
		return
	}
	
	fmt.Printf("Successfully created %d VP9 looper(s)\n", len(loopers))
	for i, looper := range loopers {
		codec := looper.Codec()
		fmt.Printf("Looper %d: MimeType=%s, ClockRate=%d\n", i, codec.MimeType, codec.ClockRate)
	}
	
	// Test H264 codec for comparison
	fmt.Println("\nTesting H264 codec with very-high resolution...")
	loopers2, err := provider.CreateVideoLoopers("very-high", "h264", false)
	if err != nil {
		fmt.Printf("Error creating H264 loopers: %v\n", err)
		return
	}
	
	fmt.Printf("Successfully created %d H264 looper(s)\n", len(loopers2))
	for i, looper := range loopers2 {
		codec := looper.Codec()
		fmt.Printf("Looper %d: MimeType=%s, ClockRate=%d\n", i, codec.MimeType, codec.ClockRate)
	}
}