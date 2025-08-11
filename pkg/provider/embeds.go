// Copyright 2022-2023 LiveKit, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package provider

import (
	"embed"
	"fmt"
	"math"
	"strconv"
	"strings"

	"go.uber.org/atomic"

	"github.com/livekit/protocol/livekit"
)

const (
	h264Codec = "h264"
	vp8Codec  = "vp8"
)

type videoSpec struct {
	codec  string
	prefix string
	height int
	width  int
	kbps   int
	fps    int
}

func (v *videoSpec) Name() string {
	ext := "h264"
	if v.codec == vp8Codec {
		ext = "ivf"
	}
	
	size := strconv.Itoa(v.height)
	if v.height > v.width {
		size = fmt.Sprintf("p%d", v.width)
	}
	
	filename := fmt.Sprintf("resources/%s_%s_%d.%s", v.prefix, size, v.kbps, ext)
	
	// Check if the 1080p file exists, if not fall back to 720p
	if v.height == 1080 {
		if _, err := res.Open(filename); err != nil {
			// 1080p file doesn't exist, use 720p file instead
			size = "720"
			// Use appropriate bitrate file based on codec and prefix
			kbps := 2000
			if v.codec == h264Codec {
				if v.prefix == "cartoon" {
					kbps = 1500
				}
			}
			fallbackFile := fmt.Sprintf("resources/%s_%s_%d.%s", v.prefix, size, kbps, ext)
			fmt.Printf("INFO: 1080p file not found (%s), falling back to 720p file (%s)\n", filename, fallbackFile)
			return fallbackFile
		}
		fmt.Printf("INFO: Using actual 1080p file: %s\n", filename)
	}
	
	return filename
}

func (v *videoSpec) ToVideoLayer(quality livekit.VideoQuality) *livekit.VideoLayer {
	return &livekit.VideoLayer{
		Quality: quality,
		Height:  uint32(v.height),
		Width:   uint32(v.width),
		Bitrate: v.bitrate(),
	}
}

func (v *videoSpec) bitrate() uint32 {
	return uint32(v.kbps * 1000)
}

func circlesSpec(width, kbps, fps int) *videoSpec {
	return &videoSpec{
		codec:  h264Codec,
		prefix: "circles",
		height: width * 4 / 3,
		width:  width,
		kbps:   kbps,
		fps:    fps,
	}
}

func createSpecs(prefix string, codec string, bitrates ...int) []*videoSpec {
	var specs []*videoSpec
	videoFps := []int{
		15, 20, 30,
	}
	for i, b := range bitrates {
		dimMultiple := int(math.Pow(2, float64(i)))
		specs = append(specs, &videoSpec{
			prefix: prefix,
			codec:  codec,
			kbps:   b,
			fps:    videoFps[i],
			height: 180 * dimMultiple,
			width:  180 * dimMultiple * 16 / 9,
		})
	}
	return specs
}

// createSpecsWithHD creates specs including 1080p resolution
func createSpecsWithHD(prefix string, codec string, bitrate180, bitrate360, bitrate720, bitrate1080 int) []*videoSpec {
	return []*videoSpec{
		{
			prefix: prefix,
			codec:  codec,
			kbps:   bitrate180,
			fps:    15,
			height: 180,
			width:  320,
		},
		{
			prefix: prefix,
			codec:  codec,
			kbps:   bitrate360,
			fps:    20,
			height: 360,
			width:  640,
		},
		{
			prefix: prefix,
			codec:  codec,
			kbps:   bitrate720,
			fps:    30,
			height: 720,
			width:  1280,
		},
		{
			prefix: prefix,
			codec:  codec,
			kbps:   bitrate1080,
			fps:    30,
			height: 1080,
			width:  1920,
		},
	}
}

var (
	//go:embed resources
	res embed.FS

	videoSpecs [][]*videoSpec
	videoIndex atomic.Int64
	audioNames []string
	audioIndex atomic.Int64
)

func init() {
	videoSpecs = [][]*videoSpec{
		createSpecsWithHD("butterfly", h264Codec, 150, 400, 2000, 4000),
		createSpecsWithHD("cartoon", h264Codec, 120, 400, 1500, 3500),
		createSpecsWithHD("crescent", vp8Codec, 150, 600, 2000, 4000),
		createSpecsWithHD("neon", vp8Codec, 150, 600, 2000, 4000),
		createSpecsWithHD("tunnel", vp8Codec, 150, 600, 2000, 4000),
		{
			circlesSpec(180, 200, 15),
			circlesSpec(360, 700, 20),
			circlesSpec(540, 2000, 30),
			circlesSpec(1080, 4000, 30), // Add 1080p circles
		},
	}
	audioNames = []string{
		"change-amelia",
		"change-benjamin",
		"change-elena",
		"change-clint",
		"change-emma",
		"change-ken",
		"change-sophie",
	}
}

func randomVideoSpecsForCodec(videoCodec string) []*videoSpec {
	filtered := make([][]*videoSpec, 0)
	for _, specs := range videoSpecs {
		if videoCodec == "" || specs[0].codec == videoCodec {
			filtered = append(filtered, specs)
		}
	}
	chosen := int(videoIndex.Inc()) % len(filtered)
	return filtered[chosen]
}

func CreateVideoLoopers(resolution string, codecFilter string, simulcast bool) ([]VideoLooper, error) {
	var specs []*videoSpec
	
	// Check if resolution contains comma for custom resolutions
	if strings.Contains(resolution, ",") {
		fmt.Printf("INFO: Creating custom resolution looper for: %s\n", resolution)
		specs = createCustomSpecs(resolution, codecFilter)
	} else {
		// Use predefined resolution sets
		fmt.Printf("INFO: Creating %s resolution looper\n", resolution)
		specs = getSpecsForResolution(resolution, codecFilter)
	}
	
	if !simulcast && len(specs) > 0 {
		// For non-simulcast, use only the highest resolution
		specs = specs[len(specs)-1:]
		fmt.Printf("INFO: Non-simulcast mode - using single layer at %dx%d\n", specs[0].width, specs[0].height)
	} else if simulcast {
		resolutions := make([]string, 0, len(specs))
		for _, s := range specs {
			resolutions = append(resolutions, fmt.Sprintf("%dx%d", s.width, s.height))
		}
		fmt.Printf("INFO: Simulcast mode - using %d layers: %s\n", len(specs), strings.Join(resolutions, ", "))
	}
	
	loopers := make([]VideoLooper, 0)
	for _, spec := range specs {
		f, err := res.Open(spec.Name())
		if err != nil {
			return nil, err
		}
		defer f.Close()
		if spec.codec == h264Codec {
			looper, err := NewH264VideoLooper(f, spec)
			if err != nil {
				return nil, err
			}
			loopers = append(loopers, looper)
		} else if spec.codec == vp8Codec {
			looper, err := NewVP8VideoLooper(f, spec)
			if err != nil {
				return nil, err
			}
			loopers = append(loopers, looper)
		}
	}
	return loopers, nil
}

// getSpecsForResolution returns specs for predefined resolution sets
func getSpecsForResolution(resolution string, codecFilter string) []*videoSpec {
	baseSpecs := randomVideoSpecsForCodec(codecFilter)
	
	switch resolution {
	case "very-high":
		// For very-high, we need 1080p + 720p + 360p
		specs := make([]*videoSpec, 0, 3)
		if len(baseSpecs) >= 4 {
			// Now we have 4 specs: 180p, 360p, 720p, 1080p
			specs = append(specs, baseSpecs[1]) // 360p
			specs = append(specs, baseSpecs[2]) // 720p
			specs = append(specs, baseSpecs[3]) // 1080p
		} else if len(baseSpecs) >= 3 {
			// Fallback for specs without 1080p
			specs = append(specs, baseSpecs[1]) // 360p
			specs = append(specs, baseSpecs[2]) // 720p
			// Create 1080p spec that will fallback to 720p file
			spec1080 := &videoSpec{
				codec:  baseSpecs[2].codec,
				prefix: baseSpecs[2].prefix,
				height: 1080,
				width:  1920,
				kbps:   4000,
				fps:    30,
			}
			specs = append(specs, spec1080)
		}
		return specs
	case "high":
		// Original high: 720p + 360p + 180p
		if len(baseSpecs) >= 3 {
			return baseSpecs[:3]
		}
		return baseSpecs
	case "medium":
		// Original medium: 360p + 180p
		if len(baseSpecs) >= 2 {
			return baseSpecs[:2]
		}
		return baseSpecs
	case "low":
		// Original low: 180p only
		if len(baseSpecs) >= 1 {
			return baseSpecs[:1]
		}
		return baseSpecs
	default:
		// Default to high
		if len(baseSpecs) >= 3 {
			return baseSpecs[:3]
		}
		return baseSpecs
	}
}

// createCustomSpecs creates specs for custom resolution combinations
func createCustomSpecs(resolutionStr string, codecFilter string) []*videoSpec {
	baseSpecs := randomVideoSpecsForCodec(codecFilter)
	resolutions := strings.Split(resolutionStr, ",")
	specs := make([]*videoSpec, 0, len(resolutions))
	
	for _, res := range resolutions {
		res = strings.TrimSpace(res)
		switch res {
		case "1080", "1080p":
			if len(baseSpecs) >= 4 {
				// Use existing 1080p spec
				specs = append(specs, baseSpecs[3])
			} else if len(baseSpecs) >= 3 {
				// Create 1080p spec that will fallback to 720p file
				spec := &videoSpec{
					codec:  baseSpecs[2].codec,
					prefix: baseSpecs[2].prefix,
					height: 1080,
					width:  1920,
					kbps:   4000,
					fps:    30,
				}
				specs = append(specs, spec)
			}
		case "720", "720p":
			// Use existing 720p spec
			if len(baseSpecs) >= 3 {
				specs = append(specs, baseSpecs[2])
			}
		case "360", "360p":
			// Use existing 360p spec
			if len(baseSpecs) >= 2 {
				specs = append(specs, baseSpecs[1])
			}
		case "180", "180p":
			// Use existing 180p spec
			if len(baseSpecs) >= 1 {
				specs = append(specs, baseSpecs[0])
			}
		}
	}
	
	// If no valid resolutions found, default to high
	if len(specs) == 0 && len(baseSpecs) >= 3 {
		return baseSpecs[:3]
	}
	
	return specs
}

func CreateAudioLooper() (*OpusAudioLooper, error) {
	chosenName := audioNames[int(audioIndex.Load())%len(audioNames)]
	audioIndex.Inc()
	f, err := res.Open(fmt.Sprintf("resources/%s.ogg", chosenName))
	if err != nil {
		return nil, err
	}
	defer f.Close()
	return NewOpusAudioLooper(f)
}
