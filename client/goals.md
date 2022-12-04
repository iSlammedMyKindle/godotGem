# Goals

## Client

* Build a client that takes in an ip address / url which goes to the server
* show a diagram of the user's controller and what buttons are being pressed
* accept either gamepad inputs or keyboard inputs
    * ...should a mouse be treated as a joystick? (that would be weird)

## Server

* Build a c# server that connects to ViGEm, a controller emulator
* should be able to take in multiple connections (for more players in the game)
    * Probably will focus on one connection for now

## Both

* Client should really only focus on it's own controllers sending inputs
* Server should focus on organizing those inputs based on connection and each controller

### Publishing

* Get started working on the flatpak so this application can be installed easily
* create a glorious icon in inkscape!
* create some documentation to tell how to install and run