local text = {}

text["ReTarget"] = [[ReTarget is not a command, but activates whenever you undock from a station or a capship. It will automatically target the last thing you had selected before you docked.

It is enabled by default.]]


text["GuildTarget"] = [[This command will send info about your current target to Guild or Group chat.


Format:  "Targeting a SuperBus (100%), "a1k0n", at 2023m"]]
text["GroupTarget"] = text["GuildTarget"]


text["GuildReady"] = [[This command is meant to indicate that you are ready (ready for what is up to you) at a steady distance from your target.
It will send text to Guild or Group chat.


Format:  "Ready at 1234m from "a1k0n""]]
text["GroupReady"] = text["GuildReady"]


text["GuildAttacked"] = [[This command is meant to indicate that you are under attack. It will send info about the last ship which hit you to your group or guild.


Format:  "Under attack by a SuperBus, "a1k0n" !"]]
text["GroupAttacked"] = text["GuildAttacked"]


text["TargetParent"] = [[This command is meant to be used when you are either targeting a Capship turret or another player's mine. It will target the owner of that object (the Capship or player).]]


text["TargetNextTurret"] = [[This command will either target the next/previous turret of a capship, or target the next/previous mine or missile of a player (missiles and rockets cannot be damaged currently).


It is usually used in two situations:


The first is when you have a Capship or a Capship turret selected. These commands will target the previous or next turret of the Capship.

The second is when you have a player or a player's mine targeted. If the player has any mines or rockets in space, it will target the previous or next mine or rocket.]]
text["TargetPrevTurret"] = text["TargetNextTurret"]


text["TargetFront"] = [[This command will target any object directly in front of you, even if it is normally unselectable, such as station parts or mines.


Note that since this scans a small portion of the screen in small increments, it does not work very well when the object is very small on the screen.]]


text["TargetShip"] = [[This command will target the nearest character whose ship name matches the specified text.


Format: /TargetShip rag -- will target the closest Ragnarok (any variant).


Note:  "/TargetShip" will target the closest ship, ignoring the type.


To set a bind for a specific ship name, enter the name (or the partial name) into the Modifier field in the Configuration dialog.]]


text["TargetPlayer"] = [[This command will target the nearest real player whose name matches the specified text.


Format:  /TargetPlayer a1 -- if a1k0n is in the sector and in radar range, this will target him.


Note:  "/TargetPlayer" will target the closest player, ignoring the name.


To set a bind for a specific player name, enter the name (or the partial name) into the Modifier field in the Configuration dialog.]]


text["TargetCargo"] = [[This command will scan through all cargo in radar range and select the first crate whose name matches the specified text.


Format:  /TargetCargo samo -- if a crate of Samoflange is in your radar range, this will target it.


To set a bind for a specific cargo type, enter the name (or the partial name) into the Modifier field in the Configuration dialog.]]


TargetTools.helptext = text