# The godotGem bridge

The godotGem bridge is a middle man between a client and server. It's purpose is to connect two machines together in the event that port forwarding isn't possible or if said machines are miles away from eachother.

Right now the bridge is only designed to take in one godotGem server and any amount of clients. Mulitple servers aren't in the picture right now, but it would be a good nice-to-have if people wanted to build hosting services around godotGem.

# How to use the bridge

The bridge is designed to be self-hosted. This can be done through either a home server or through a service like google cloud or linode. Once the files for the bridge are on the server, all you need to do is start the server, and make sure port `9090` is forwarded.

## On the client

Connect to your bridge's ip address or domain name. If you want a domain that doesn't track your ip, you can get one on https://noip.com

That should be it! If you haven't connected the server yet, the bridge will ping back some cool vibrations when pressing a buton or pulling the triggers.

## On the server

You can't double-click the server like you normally would to start the bridge connection. You instead need to run this in the command line:

```bash
/path/to/server.exe -b my.amazing.bridge.com
```

Once connected, you should now be able to connect as many clients as humanly possible (via the bridge) for both your internet connection and cpu usage.