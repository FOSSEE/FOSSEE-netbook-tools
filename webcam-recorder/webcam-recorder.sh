#!/bin/bash

vlc v4l2:///dev/video0 --v4l2-width 640 --v4l2-height 480 --v4l2-chroma NV21 --v4l2-fps 15 --v4l2-brightness 0 --v4l2-contrast 0 --v4l2-saturation 0 --v4l2-hue 0 --v4l2-auto-white-balance 0
