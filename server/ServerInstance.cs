using Constants;
using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using System.Text.Json;
static class serverInstance
{
    public static Dictionary<Guid, Player> players = new Dictionary<Guid, Player>();
    public static IXbox360Controller[] controllers = new IXbox360Controller[4];

    public static int PlayerCount
    {
        get
        {
            return players.Count;
        }
    }

    public static byte[] PlayersPerController
    {
        get
        {
            byte[] counts = [0, 0, 0, 0];

            if (players.Count == 0)
                return counts;

            try
            {
                foreach (Player p in players.Values)
                {
                    /* This if, is for a race condition happening in C#
                    when multiple controllers are being added around the same time, the Count can be 1
                    and the value is null (The value is still being inserted!)
                    Therefore, we only handle the variable if it's been fully inserted into the players dictionary.*/
                    if (p != null)
                    {
                        counts[p.playerNumber]++;
                    }
                }
            }
            catch (InvalidOperationException)
            {
                // We'll try this again
                Console.WriteLine("Whoah; that's a lot of players connecting at once! It was a little too fast - so let's re-count players-per-controller");
                return PlayersPerController;
            }

            return counts;
        }
    }

    public static void InitControllers()
    {
        for (int i = 0; i < controllers.Length; i++)
        {
            controllers[i] = new ViGEmClient().CreateXbox360Controller();

            // If we receive feedback, cycle through all players using the controller & send that feedback
            controllers[i].FeedbackReceived += (controller, motorActivity) =>
            {
                byte[] rumble = { 0, motorActivity.SmallMotor, motorActivity.LargeMotor };

                foreach (Player player in players.Values)
                {
                    if (player.playerNumber == i)
                    {
                        player.SendRumble(rumble);
                    }
                }

                Console.WriteLine("M " + i + " " + motorActivity.SmallMotor + " " + motorActivity.LargeMotor);
            };
        }
    }

    // Given a new player, when they are added to the server, allow them to use a controller not in-use (including ones not turned on yet)
    public static void AddPlayerToServer(Player newPlayer)
    {
        // Loop through all quantities of controllers. If we find that all of them are being used, increment up
        int smallestIndex = controllers.Length;
        byte smallestCount = byte.MaxValue;
        for (byte i = 0; i < PlayersPerController.Length; i++)
        {
            if (PlayersPerController[i] == 0)
            {
                smallestIndex = i;
                break;
            }

            if (PlayersPerController[i] < smallestCount)
            {
                smallestIndex = i;
                smallestCount = PlayersPerController[i];
            }
            else if (PlayersPerController[i] == smallestCount && i < smallestIndex)
            {
                smallestIndex = i;
            }
        }

        try
        {
            players.Add(newPlayer.id, newPlayer);
        }
        catch (IndexOutOfRangeException)
        {
            // try to run again, we're adding many players at once
            Console.WriteLine("Players were added too fast! Retrying...");
            players.Add(newPlayer.id, newPlayer);
        }

        newPlayer.playerNumber = (byte)smallestIndex;
        // Connect the controller if it wasn't already connected
        if (PlayersPerController[smallestIndex] == 1)
            controllers[smallestIndex].Connect();
        Console.WriteLine("New player connected to controller " + (smallestIndex + 1) + "!");
    }

    public static void RemovePlayerFromServer(Player player)
    {
        try
        {
            players.Remove(player.id);
        }
        catch (InvalidOperationException)
        {
            // try to run again, we're removing many players at once
            Console.WriteLine("Players were removed too fast! Retrying...");
            players.Remove(player.id);
        }

        DisconnectControllerAt(player.playerNumber);
        player.CloseSocket();
        removeAllNullPlayers();
    }

    // If players disconnect too fast, the dictionary will have null entries in place of player ojbects.
    // Remove any that are found
    private static void removeAllNullPlayers()
    {
#pragma warning disable CS8625 // Cannot convert null literal to non-nullable reference type.
        if (!players.ContainsValue(null)) return;

        Console.WriteLine("Removing players went a little quick, clearing accidental null players...");
        players = players
            .Where(kv => kv.Value != null)
            .ToDictionary(kv => kv.Key, kv => kv.Value);
    }

    // Go through the routine of disonnecting a controller, only if the index *after* lacks a player count
    public static void DisconnectControllerAt(byte index)
    {
        byte[] ppc = PlayersPerController;
        bool onlyPlayerLeft = ppc[index] == 1;
        bool atMaxPlayerCount = index == ppc.Length;
        bool nextIndexEmpty = index + 1 == ppc.Length ? false : ppc[index + 1] == 0;

        // Given a disconnected player, if there is no one playing the controller number above, OR we're at max players, diconnect the controller if that was the last person using it.
        if (
            (atMaxPlayerCount && onlyPlayerLeft) ||
            nextIndexEmpty && onlyPlayerLeft
        )
        {
            controllers[index].Disconnect();
        }
    }

    public static void stringMsg(string message, Player player)
    {
        //So far the only thing we're using this for is for joystick movement, there's no way to send the joystick strength in bytes without heavily compressing information.
        var resObj = JsonDocument.Parse(message);
        Console.WriteLine("JS " + message);

        if (resObj.RootElement.ValueKind == JsonValueKind.Array)
        {
            //Joystick X
            controllers[player.playerNumber]?.SetAxisValue((Xbox360Axis)Mappings.ANALOG_MAP[(byte)resObj.RootElement[0].GetInt16()],
            resObj.RootElement[1].GetInt16());

            //Joystick Y
            controllers[player.playerNumber]?.SetAxisValue((Xbox360Axis)Mappings.ANALOG_MAP[(byte)(resObj.RootElement[0].GetInt16() + 1)],
            resObj.RootElement[2].GetInt16());
        }
        else if (resObj.RootElement.ValueKind == JsonValueKind.Object)
        {
            // Switch player to another controller!
            try
            {
                byte controllerIndex = resObj.RootElement.GetProperty("controller").GetByte();

                Console.WriteLine("Switching player " + player.id + " to controller " + controllerIndex);
                SwitchPlayerToController(player, controllerIndex);
            }
            catch (KeyNotFoundException)
            {
                Console.WriteLine("Received invalid controller switch request from player " + player.id);
            }
        }
    }

    //Non-strings go here, most inputs will come down this way
    public static void binMsg(byte[] message, Player player)
    {
        Console.WriteLine(message[0].ToString() + ' ' + message[1].ToString() + ' ' + message[2].ToString());
        if (message[1] < 18)
            controllers[player.playerNumber]?.SetButtonState(message[1], message[2] == 255);

        else if (message[1] == 19 || message[1] == 20)
        {
            controllers[player.playerNumber]?.SetSliderValue(
                (Xbox360Slider)Mappings.ANALOG_MAP[message[1]],
                message[2]
            );
        }
    }

    public static void SwitchPlayerToController(Player player, byte newControllerIndex)
    {
        // Disconnect from the old controller if needed
        DisconnectControllerAt(player.playerNumber);

        // Switch the player to the new controller
        player.playerNumber = newControllerIndex;

        // Connect the new controller if needed
        if (PlayersPerController[newControllerIndex] == 1)
            controllers[newControllerIndex].Connect();
    }
}