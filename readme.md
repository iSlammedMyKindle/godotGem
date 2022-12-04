# godotGem

**godotGem** is a project designed to help you connect a controller over the network to your Windows gaming PC. It makes use of ViGEm, Godot, and webSockets to bridge the gap between a wired controller and send those inputs to a virtual controller that's being run on Windows!

This program was designed with the **Steam Deck** in mind. It features a "blinder" button that fades the screen to black, so that your deck doesn't have burn-in while sending it's inputs over to the other machine.

# Use cases!

* You have a wired controller that you want to effectivlye make wireless
* Valve's steam link is being rough on bandwidth - testing has shown that feeds from steam link can go up to 300kbps (because of both a video feed and controller inputs). This project at maximum only takes up a fraction of that. (100-140kbps when using joysticks!) (TODO: measure without buttons)
* You need a spare controller on hand and your only option is a steamdeck
* You need a glorified extension cable because your wired controller is too far away from your machine
* Your PC is out of USB ports
* Bluetooth bandwith stinks for some reason

# Install

## Flathub

If you are on linux, `godotGem` should be available as a flatpak on flathub. If you are using the Steam Deck, this is going to be your easiest option to install it.

## Manual

* Please download the latest version in the [releases]() page.
* On the computer you will be playing games on (host), download the `server.exe`. You can place this anywhere and execute it. Windows will ask to verify what networks this should work on. Select "Private Networks".
* On the machine you're sharing the controller with (guest), download the `client`.
    * If you are on **windows**, you are basically good, just run the exe and slect "private networks" on your first run
    * If you are on **linux**, you will need to ensure the binary has `execute` permissions. In the terminal, you can do this by running `chmod +x /path/to/godotGemClient.x86_64`. Alternatvely, linx file managers also support changing the file to executable as well. You can then start the program by double-clicking on it in the file mananger, or by running it in the terminal.

# How to start godotGem

1. On your windows PC needing a controller, double-click `server.exe`
1. launch command prompt or powershell, run `ipconfig`
    * Look for the connection you're using right now. under that you should see something like `IPV4 Address`, alongside a ip that may look like `10.235.1.XXX` or `192.168.1.XX` (these vary). Take note of this ip address
1. Open the client on the machine you're sharing the controller with. Type in the ip address you found in the command prompt. Click `Connect!`

You're done! Enjoy your fancy new ~~wired~~ wireless controller / Steam deck controller interface!

# License

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.