using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
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
        bool noMorePlayers = ppc[index] == 0;
        bool atMaxPlayerCount = index == ppc.Length;
        bool nextIndexEmpty = index + 1 == ppc.Length ? false : ppc[index + 1] == 0;

        // Given a disconnected player, if there is no one playing the controller number above, OR we're at max players, diconnect the controller if that was the last person using it.
        if (
            (atMaxPlayerCount && noMorePlayers) ||
            nextIndexEmpty && noMorePlayers
        )
        {
            controllers[index].Disconnect();
        }
    }

    public static void SwitchPlayerToController(Player player, byte newControllerIndex)
    {
        // Switch the player to the new controller
        player.playerNumber = newControllerIndex;

        // Connect the new controller if needed
        if (PlayersPerController[newControllerIndex] == 0)
            controllers[newControllerIndex - 1].Connect();

        // Disconnect from the old controller if needed
        DisconnectControllerAt(player.playerNumber);
    }
}