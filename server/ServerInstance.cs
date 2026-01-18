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

            foreach (Player p in players.Values)
            {
                counts[p.playerNumber - 1]++;
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
        bool connected = false;
        for (byte i = 0; !connected; i++)
        {
            foreach (byte count in PlayersPerController)
            {
                if (count != i) continue;
                if (count == 0) controllers[count].Connect();

                players.Add(newPlayer.id, newPlayer);
                newPlayer.playerNumber = count;
                connected = true;
                Console.WriteLine("New player connected to controller " + (count + 1) + "!");
                break;
            }
        }
    }

    public static void RemovePlayerFromServer(Player player)
    {
        players.Remove(player.id);
        DisconnectControllerAt(player.playerNumber);
        player.CloseSocket();
    }

    // Go through the routine of disonnecting a controller, only if the index *after* lacks a player count
    public static void DisconnectControllerAt(byte index)
    {
        byte[] ppc = PlayersPerController;
        bool noMorePlayers = ppc[index] == 0;
        bool nextIndexEmpty = ppc[index + 1] == 0;
        bool atMaxPlayerCount = index == ppc.Length;

        // Given a disconnected player, if there is no one playing the controller number above, OR we're at max players, diconnect the controller if that was the last person using it.
        if (
            (atMaxPlayerCount && noMorePlayers) ||
            nextIndexEmpty && noMorePlayers
        )
        {
            controllers[index - 1].Disconnect();
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