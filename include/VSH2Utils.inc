#pragma semicolon 1

#include <vsh2>

#define MAX_ATTRIBUTE_STRING_SIZE 128

#define VSH_DEFAULT_SELECTOR_SOUNDS_INTROS "boss data.sounds.intros"
#define VSH_DEFAULT_SELECTOR_SOUNDS_SUPER_JUMP "boss data.sounds.super jump"
#define VSH_DEFAULT_SELECTOR_SOUNDS_BACKSTAB "boss data.sounds.backstab"
#define VSH_DEFAULT_SELECTOR_SOUNDS_RAGE "boss data.sounds.rage"
#define VSH_DEFAULT_SELECTOR_SOUNDS_KILL_CLASS "boss data.sounds.kill class"
#define VSH_DEFAULT_SELECTOR_SOUNDS_SPREE "boss data.sounds.spree"
#define VSH_DEFAULT_SELECTOR_SOUNDS_LAST_GUY "boss data.sounds.last guy"
#define VSH_DEFAULT_SELECTOR_SOUNDS_WIN "boss data.sounds.win"
#define VSH_DEFAULT_SELECTOR_SOUNDS_LOSE "boss data.sounds.lose"
#define VSH_DEFAULT_SELECTOR_SOUNDS_MUSIC "boss data.sounds.music"
#define VSH_DEFAULT_SELECTOR_MENU_NAME "boss data.menu name"
#define VSH_DEFAULT_SELECTOR_NAME "boss data.name"
#define VSH_DEFAULT_SELECTOR_PANEL_MESSAGE "boss data.panel msg"
#define VSH_DEFAULT_SELECTOR_MODELS "boss data.models"
#define VSH_DEFAULT_SELECTOR_SKINS "boss data.skins"


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
 * @param target    The enum struct in which the convars will be loaded into.
 */
#define VSH_GET_CVARS(%1)                               \
%1.scout_rage_gen = FindConVar("vsh2_scout_rage_gen");  \
%1.airblast_rage = FindConVar("vsh2_airblast_rage");    \
%1.jarate_rage = FindConVar("vsh2_jarate_rage")

/**
* Finds the ConVars commonly used in VSH2 bosses.
*
* @param target    The enum struct in which the convars will be loaded into.
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
* @param selector   The path to the menu name inside the configuration map (defaults to "boss data.name").
*/
stock void AddBossToMenuFromConfig(Menu& menu, int bossId, ConfigMap config, char[] selector = VSH_DEFAULT_SELECTOR_MENU_NAME) {
    char tostr[10]; 
    IntToString(bossId, tostr, sizeof(tostr));
    
    /// ConfigMap can be used to store the boss name.
    int name_len = config.GetSize(selector);
    char[] name = new char[name_len];
    config.Get(selector, name, name_len);
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
* @param selector   The path to the panel message inside the configuration map (defaults to "boss data.panel message").
*/
stock void SetPanelMessageFromConfig(const VSH2Player player, ConfigMap config, char[] selector = VSH_DEFAULT_SELECTOR_PANEL_MESSAGE){
    Panel panel = new Panel();
    int messageLength = config.GetSize(selector);
    char[] panel_info = new char[messageLength];
    config.Get(selector, panel_info, messageLength);
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
 * @param selector     The path to the name of the boss inside the configuration map (defaults to "boss data.name").
 */
stock void SetPlayerNameToBossFromConfig(const VSH2Player player, ConfigMap config, char[] selector = VSH_DEFAULT_SELECTOR_NAME) {
    int nameLength = config.GetSize(selector);
    char[] bossName = new char[nameLength];
    config.Get(selector, bossName, nameLength);

    char name[MAX_BOSS_NAME_SIZE];
    strcopy(name, sizeof name, bossName);
    player.SetName(name);
}

/**
 * Plays a random sound from the config listed under the selector.
 *
 * @param player        The player being the source of the sound.
 * @param config        The configuration map containing the sounds.
 * @param selector      The path inside the config map to the sounds.
 * @param soundFlag     The flags used while playing the sound.
 */
stock void PlayRandomSoundFromConfigSelector(const VSH2Player player, ConfigMap config, char[] selector, int soundFlag) {
    ConfigMap sounds = config.GetSection(selector);
    if(sounds != null) {
        PlayRandomSoundFromConfigSection(player, sounds, soundFlag);
    }
    else {
        LogError("Could not find selection under selector.");
    }
}

/**
 * Plays a random sound from the config listed under the selector of a specific class.
 *
 * @param player            The player being the source of the sound.
 * @param class             The mercenary class determining the soundclip.
 * @param config            The configuration map containing the sounds.
 * @param selector          The path inside the config map to the sounds.
 * @param soundFlag         The flags used while playing the sound.
 * @param includeUnknown    Determines if the enumeration should start with an unknown class.
 */
stock void PlayRandomClassSoundFromConfigSelector(const VSH2Player player, TFClassType class, ConfigMap config, char[] selector, int soundFlag, bool includeUnknown = false) {
    ConfigMap classesSection = config.GetSection(selector);
    if(classesSection != null) {
        int key;
        if(includeUnknown) {
            key = view_as<int>(class);
        }
        else {
            key = view_as<int>(class) - 1;
        }
        ConfigMap classSection = classSection.GetIntSection(key);
        if(classSection != null){
            PlayRandomSoundFromConfigSection(player, classSection, soundFlag);
        }
        else {
            LogError("Could not find selection under class.");
        }
    }
    else {
        LogError("Could not find selection under selector.");
    }
}

/**
 * Plays a random sound listed in the current section.
 *
 * @param player        The player being the source of the sound.
 * @param sounds        The configuration map containing the sounds.
 * @param soundFlag     The flags used while playing the sound.
 */
stock void PlayRandomSoundFromConfigSection(const VSH2Player player, ConfigMap sounds, int soundFlag) {
    int soundsCount = sounds.Size;
    if(soundsCount > 0) {
        int i = GetRandomInt(0, soundsCount - 1);
        int pathSize = sounds.GetIntKeySize(i);
        char[] soundPath = new char[pathSize];
        if( sounds.GetIntKey(i, soundPath, pathSize) > 0 ) {
            player.PlayVoiceClip(soundPath, soundFlag);
        }
    }
}

/**
 * Handles the player's killing streak after a kill.
 *
 * @param player     The player that killed another player.
 * @return           The number of players previously killed within 5 seconds of eachother
 */
stock int HandleKillingSpree(const VSH2Player player) {
    float currentTime = GetGameTime();
    if(currentTime <= player.GetPropFloat("flKillSpree")) {
        player.SetPropInt("iKills", player.GetPropInt("iKills") + 1);
    }
    else {
        player.SetPropInt("iKills", 0);
    }

    // reset the kill spree time
    player.SetPropFloat("flKillSpree", currentTime+5.0);

    return player.GetPropInt("iKills") + 1;
}

// An empty panel hint used internally when sending panels.
stock int _EmptyPanelHint(Menu menu, MenuAction action, int param1, int param2) {
    return 0;
}

/**
 * Gives the boss rage when hurt.
 *
 * @param 1     The boss player.
 * @param 2     The boss Id.
 * @param 3     The damage event.
 */
#define VSH_DEFAULT_CODE_ON_PLAYER_HURT(%1,%2,%3)   \
if( !IsBossType(%1, %2) || %1.bIsBoss) return;      \
int damage = %3.GetInt("damageamount");             \
%1.GiveRage(damage)

/**
 * Gives the boss rage when airblasted.
 *
 * @param 1     The boss player.
 * @param 2     The boss Id.
 * @param 3     The ConVars containing rage values.
 */
#define VSH_DEFAULT_CODE_ON_PLAYER_AIRBLASTED(%1,%2,%3)         \
if( !IsBossType(%1, %2)) return;                                \
float rage = %1.GetPropFloat("flRAGE");                         \
%1.SetPropFloat("flRAGE", rage + %3.airblast_rage.FloatValue)