# Advanced Dualsense Vibration

The Sony Dualsense controller (for PS5) has some really impressive haptics. According to Wikipedia, has "vibrotactile haptics". That's fancy speak for "vibration from audio"; one plays a sound and *presto*! You have vibration that feels like the thing you're listening to. Examples include walking in the snow, cat claws (stray), bubbles, or even lazers.

On most platforms, this cool feature isn't available. The only exceptions to this are the PS5 itself, and Linux whenever you plug the controller in directly via USB.

When connected to Linux, the DualSense shows up as a sound device. This means you can basically route anything that's running at the moment, from firefox, to vlc to non-steam games.

Now, how would one route this audio/haptics from windows to the DualSense controller? That's what this tutorial is all about!

## How to route Windows audio to Linux

### Prerequisites (Linux):

* bluedevil and/or blueman programs for linux (if you don't have any bluetooth management yet)
* pavucontrol-qt for audio management

### Prerequisites (Windows):

* OBS (optional, for sending the output to your speakers)

### Bluetooth (Recommended)

This method is currently the simplest and most efficient method. It involves using Linux as a bluetooth speaker for Windows.

1. Make sure on windows your machine is discoverable
1. On linux, start the process for adding a bluetooth device (bluedevil or blueman are good for this)

### WiFi (Slow)

The current methods I'm aware of all have latency issues on WiFi. Sound latency can go up to 1200ms. One thing I want to check is how something like steam link or parsec handles audio.

The tutorial being shown here is using a UDP protocol called `RTP`. It is the fastest latency I could find when testing out VLC and audio streaming.

This requires additional pre-req for linux:

* VLC (Windows)
* [VB-Cable](https://vb-audio.com/Cable/index.htm) - For piping desktop audio to VLC
* ffmpeg (Linux)

**On windows**

--------------
1. start a stream on VLC (CTRL+S), Select the Caputre Device tab
    * Video Device name: off
    * Audio Device name: `CABLE Output` (Rememeber to set *your* audio source to `CABLE Input`)
1. Click "Stream" -> "Next"
1. Set the new destination to `RTP / MPEG Transport`
    * This shouldn't be confused with RTP `Audio / Video Profile` or `RTSP`
    * The address will be the ip address to your linux machine (e.g `rtp://10.235.1.12`)
    * Start the stream!

**On Linux**

------------

* Open the terminal and run this, replace it with your windows machine's ip: `ffplay rtp://10.235.1.11:5004`
    * If you changed the port before streaming, reflect that numebr in the URL

### On the godotGem Client

Enable the "Ignore vibration" toggle. This will let the DualSense take in the audio vibration. If this is not enabled, the DualSense will fallback into a "legacy" mode, where the firmware will emulate traditional vibrations. When this happens the controller permanently is stuck in this state and you'll need to re-connect the controller.

## You're done!

Sounds from windows should now be coming into the speakers of the linux machine by default. Linux sees this as a microphone input, and loops this to the speakers

With the DualSense controller connected to Linux, set the loop output in pulseAudio to re-direct to the Dualsense instead of the main speakers. Alternatively you can set all audio on linux to re-direct to the DualSense controller. You can then put on a pair of headphones through the controller's headphone jack and listen to the audio.

Optionally, if you don't want any audio latency from windows, you could instead have windows audio *monitor* to another audio device, so that audio comes out of two devices at the same time. This can be done through OBS, or another program.