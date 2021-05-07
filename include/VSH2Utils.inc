#pragma semicolon 1

#include <vsh2>

#define MAX_ATTRIBUTE_STRING_SIZE 128

enum struct VSH2CVars {
    ConVar scout_rage_gen;
    ConVar airblast_rage;
    ConVar jarate_rage;
}

enum struct ItemAttribute {
    int attributeId;
    char value[20];
}

/**
 * Converts the attribute data to a string and outputs it to the buffer.
 *
 * @param attributes         Attributes present on an item.
 * @param attributeCount     Ammount of attributes passed in.
 * @param buffer             The output character buffer.
 * @param bufferSize         The size of the character buffer.
 * @return                   The amount of bytes written to the buffer.
 */
stock int AttributesToString(ItemAttribute[] attributes, int attributeCount, char[] buffer, int bufferSize) {
    int bytesWritten = 0;
    char idString[4];
    for(int i = 0; i < attributeCount; i++)
    {
        IntToString(attributes[i].attributeId, idString, sizeof(idString));
        bytesWritten += StrCat(buffer, bufferSize, idString);
        bytesWritten += StrCat(buffer, bufferSize, ";");
        bytesWritten += StrCat(buffer, bufferSize, attributes[i].value);
        
        if(i != attributeCount) {
            bytesWritten += StrCat(buffer, bufferSize, ";");
        }
    }

    return bytesWritten;
} 

/**
* Finds the ConVars commonly used in VSH2 bosses.
*
* @param target    The array in which the convars will be loaded into.
*/
stock void GetVSHCVars(VSH2CVars target) {
    target.scout_rage_gen = FindConVar("vsh2_scout_rage_gen");
    target.airblast_rage = FindConVar("vsh2_airblast_rage");
    target.jarate_rage = FindConVar("vsh2_jarate_rage");
}


/**
* Checks if the player's boss id is set to the given id.
*
* @param player     The player to check.
* @param bossId     The boss id to check for.
* @return           Returns true if the player's boss type is set to bossId.
*/
stock bool IsBossType(const VSH2Player player, int bossId) {
    return player.GetPropInt("iBossType") == bossId;
}

/**
* Adds a boss to the selection menu.
*
* @param menu       The selection menu.
* @param bossId     The Id of the boss to be put in the menu.
* @param name       The name to appear in the selection menu.
*/
stock void AddBossToMenu(Menu& menu, int bossId, const char[] name) {
    char tostr[10]; 
    IntToString(bossId, tostr, sizeof(tostr));

    menu.AddItem(tostr, name);
}

/**
* Adds a boss to the selection menu with data from the configuration map.
*
* @param menu       The selection menu.
* @param bossId     The Id of the boss to be put in the menu.
* @param config     The configuration map containing the boss' menu name.
* @remarks          The boss' menu name is retrieved from "boss data.menu name".
*/
stock void AddBossToMenuFromConfig(Menu& menu, int bossId, ConfigMap config) {
    char tostr[10]; 
    IntToString(bossId, tostr, sizeof(tostr));
    
    /// ConfigMap can be used to store the boss name.
    int name_len = config.GetSize("boss data.menu name");
    char[] name = new char[name_len];
    config.Get("boss data.menu name", name, name_len);
    menu.AddItem(tostr, name);
}

/**
* Creates a panel with the message and shows it to the player.
*
* @param player      The recipient of the panel.
* @param message     The message toput in the panel.
*/
stock void SetPanelMessage(const VSH2Player player, const char[] message){
    Panel panel = new Panel();
    panel.SetTitle(message);
    panel.DrawItem("Exit");
    panel.Send(player.index, _EmptyPanelHint, 999);
    delete panel;
}

/**
* Creates a panel with a message from the config map and shows it to the player.
*
* @param player     The recipient of the panel.
* @param config     The configuration map containing the boss' panel message.
* @remarks          The boss' panel message is retrieved from "boss data.panel msg".
*/
stock void SetPanelMessageFromConfig(const VSH2Player player, ConfigMap config){
    Panel panel = new Panel();
    int messageLength = config.GetSize("boss data.panel msg");
    char[] panel_info = new char[messageLength];
    config.Get("boss data.panel msg", panel_info, messageLength);
    panel.SetTitle(panel_info);
    panel.DrawItem("Exit");
    panel.Send(player.index, _EmptyPanelHint, 999);
    delete panel;
}

/**
 * Sets the player name to the name of the boss.
 *
 * @param player       The boss player.
 * @param bossName     The name of the boss.
 */
stock void SetPlayerNameToBoss(const VSH2Player player, const char[] bossName) {
    char name[MAX_BOSS_NAME_SIZE];
    strcopy(name, sizeof name, bossName);
    player.SetName(name);
}

/**
 * Sets the player name to the name of the boss from the config map.
 *
 * @param player       The boss player.
 * @param config       The configuration map containing the boss' name.
 * @remarks            The boss' panel message is retrieved from "boss data.name".
 */
stock void SetPlayerNameToBossFromConfig(const VSH2Player player, ConfigMap config) {
    int nameLength = config.GetSize("boss data.name");
    char[] bossName = new char[nameLength];
    config.Get("boss data.name", bossName, nameLength);

    char name[MAX_BOSS_NAME_SIZE];
    strcopy(name, sizeof name, bossName);
    player.SetName(name);
}

// An empty panel hint used internally when sending panels.
int _EmptyPanelHint(Menu menu, MenuAction action, int param1, int param2) {
    return 0;
}