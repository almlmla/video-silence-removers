# video-silence-removers
Remove silent parts of videos.

Bash scripts to remove silent parts of videos.  Requires ffmpeg in executable path.
Idea and main logic for determining segments of interest from https://github.com/bambax/Remsi.
A lot of help and code refinement from the current favorite generative pre-trained transformer.

**ss-video-silence-remover** processes files **s**lowly and will generate **s**maller files
since the files are re-encoded.  Theoretically also a better option for avoiding problems
with keyframes.

**fb-video-silence-remover** processes files **f**aster but will generate **b**igger files.
The original videos are only copied and not re-encoded.  Temporary files named cut*x*.mp4
will be generated and cleaned up after concatenation.  Theoretically may have problems with
keyframes but should leave video quality otherwise unchanged.

Both scripts function the same way: place the script in the same directory of mp4 files to
be processed.  Run the script without arguments.  A subdirectory named "trimmed" will be
created to contain all the processed files before all mp4 files are processed. A default
noise tolerance of -50dB and silence duration of 3 seconds are hard-coded in the scripts.
Change these according to your needs.
