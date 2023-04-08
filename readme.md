# godotGem

**godotGem** is a project designed to help you connect a controller over the network to your Windows gaming PC. It makes use of [ViGEm.NET](https://github.com/ViGEm/ViGEm.NET), [Godot](https://godotengine.org/), and [webSockets](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) to bridge the gap between a wired controller and send those inputs to a virtual controller that's being run on Windows!

This program was designed with the **Steam Deck** in mind. It features a "blinder" button that fades the screen to black, so that your deck doesn't have burn-in while sending it's inputs over to the other machine.

## [Watch the youtube tutorial video!](https://www.youtube.com/watch?v=VS80voWUoS8)

![Watch The Youtube video!](https://i.imgur.com/SIypDNE.png)


## [Stop by the discord support server!](https://discord.gg/xSqWsARMMH)

# Use cases!

* You have a wired controller that you want to effectivlye make wireless
* Valve's steam link is being rough on bandwidth - testing has shown that feeds from steam link can go up to 300kbps (because of both a video feed and controller inputs). This project at maximum only takes up a fraction of that. (100-140kbps when using joysticks!) (TODO: measure without buttons)
* You need a spare controller on hand and your only option is a steamdeck
* You need a glorified extension cable because your wired controller is too far away from your machine
* Your PC is out of USB ports
* Bluetooth bandwith stinks for some reason

# Install

## Flathub

If you are on Linux, `godotGem` should be available as a flatpak on flathub. If you are using the Steam Deck, this is going to be your easiest option to install it.

```bash
# Install
flatpak install io.github.iSlammedMyKindle.godotGem

# run
io.github.iSlammedMyKindle.godotGem
```

<a href='https://flathub.org/apps/details/io.github.iSlammedMyKindle.godotGem'><img width='240' alt='Download on Flathub' src='https://flathub.org/assets/badges/flathub-badge-en.png'/></a>

## Manual Install

* Please download the latest version in the [releases](https://github.com/iSlammedMyKindle/godotGem/releases) page.
* On the computer you will be playing games on (host):
    * [You will need the ViGEm controller driver](https://github.com/ViGEm/ViGEmBus/releases/). Install that and move on to the next step
    * download the `serverWindows.zip`. You can extract this anywhere and execute `server.exe`. Windows will ask to verify what networks this should work on. Select "Private Networks".
* On the machine you're sharing the controller with (guest), download the `client`.
    * If you are on **Windows** (`godotGemClientWindow.zip`), you are basically good, just run the exe and slect "private networks" on your first run
    * If you are on **Linux** (`godotGemClient.zip`), you should be fine as well; the binary can be launched by double clicking it on the file manager or running it via termianl.
        * If for some reason the binary doesn't run the first time, you will need to ensure it has `execute` permissions. In the terminal, you can do this by running `chmod +x /path/to/godotGemClient.x86_64`.
        * Alternatvely, **Linux** file managers also support changing the file to executable as well. (Right click -> properties -> permissions -> Make the file executable)
    * On **Linux**, you can also add the program's directory directly to your `$PATH` environment varible so you can execute it without callind the path each time.

## How to start godotGem

1. On your Windows PC needing a controller, double-click `server.exe`
1. Launch command prompt or powershell, run `ipconfig`
    * Look for the connection you're using right now. under that you should see something like `IPV4 Address`, alongside a ip that may look like `10.235.1.XXX` or `192.168.1.XX` (these vary). Take note of this ip address
1. Open the client on the machine you're sharing the controller with. Type in the ip address you found in the command prompt. Click `Connect!`

You're done! Enjoy your fancy new ~~wired~~ wireless controller / Steam deck controller interface!

## Extras!

* [How to use the godotGem bridge - a way to send controller inputs outside the LAN](./extras/bridgeHowTo.md)
* [How to use advanced haptics from the DualSense controller through the weird quirks of Linux](./extras/usingAdvancedDualsenseVibration.md)

# License

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
