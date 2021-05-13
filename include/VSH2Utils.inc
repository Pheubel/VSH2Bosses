#pragma semicolon 1

#include <vsh2>

#define MAX_ATTRIBUTE_STRING_SIZE 128

#define VSH_DEFAULT_SELECTOR_DISABLE "boss data.disable"
#define VSH_DEFAULT_SELECTOR_CLASS "boss data.class"
#define VSH_DEFAULT_SELECTOR_LIVES "boss data.lives"
#define VSH_DEFAULT_SELECTOR_SOUNDS_INTROS "boss data.sounds.intros"
#define VSH_DEFAULT_SELECTOR_SOUNDS_SUPER_JUMP "boss data.sounds.super jump"
#define VSH_DEFAULT_SELECTOR_SOUNDS_CHARGE_ABILITY "boss data.sounds.charge ability"
#define VSH_DEFAULT_SELECTOR_SOUNDS_BACKSTAB "boss data.sounds.backstab"
#define VSH_DEFAULT_SELECTOR_SOUNDS_RAGE "boss data.sounds.rage"
#define VSH_DEFAULT_SELECTOR_SOUNDS_KILL_CLASS "boss data.sounds.kill class"
#define VSH_DEFAULT_SELECTOR_SOUNDS_SPREE "boss data.sounds.spree"
#define VSH_DEFAULT_SELECTOR_SOUNDS_LAST_GUY "boss data.sounds.last guy"
#define VSH_DEFAULT_SELECTOR_SOUNDS_WIN "boss data.sounds.win"
#define VSH_DEFAULT_SELECTOR_SOUNDS_LIFE_LOST "boss data.sounds.life lost"
#define VSH_DEFAULT_SELECTOR_SOUNDS_DEATH "boss data.sounds.death"
#define VSH_DEFAULT_SELECTOR_SOUNDS_MUSIC "boss data.sounds.music"
#define VSH_DEFAULT_SELECTOR_MENU_NAME "boss data.menu name"
#define VSH_DEFAULT_SELECTOR_NAME "boss data.name"
#define VSH_DEFAULT_SELECTOR_PANEL_MESSAGE "boss data.panel msg"
#define VSH_DEFAULT_SELECTOR_MODELS "boss data.models"
#define VSH_DEFAULT_SELECTOR_SKINS "boss data.skins"
#define VSH_DEFAULT_SELECTOR_RAGE_DISTANCE "boss data.rage dist"
#define VSH_DEFAULT_SELECTOR_MOVE_SPEED "boss data.move speed"
// #define VSH_DEFAULT_SELECTOR_MAX_SPEED "boss data.max speed"  //TODO: check if speed think actually ramps up to this
#define VSH_DEFAULT_SELECTOR_WEAPON_ATTRIBUTES "boss data.attribs"
#define VSH_DEFAULT_SELECTOR_WEAPON_CLASS "boss data.weapon class"
#define VSH_DEFAULT_SELECTOR_WEAPON_ID "boss data.weapon id"
#define VSH_DEFAULT_SELECTOR_CHARGE_ABILITY "boss data.charge ability"
#define VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_NAME "boss data.charge ability.name"
#define VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_PLUGIN "boss data.charge ability.plugin"
#define VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_ARGUMENTS "boss data.charge ability.arguments"
#define VSH_DEFAULT_SELECTOR_RAGE_ABILITY "boss data.rage ability"
#define VSH_DEFAULT_SELECTOR_RAGE_ABILITY_PLUGIN "boss data.rage ability.plugin"
#define VSH_DEFAULT_SELECTOR_RAGE_ABILITY_ARGUMENTS "boss data.rage ability.arguments"
#define VSH_DEFAULT_SELECTOR_LIFE_LOST_ABILITY "boss data.life ability"
#define VSH_DEFAULT_SELECTOR_LIFE_LOST_ABILITY_PLUGIN "boss data.life ability.plugin"
#define VSH_DEFAULT_SELECTOR_LIFE_LOST_ABILITY_ARGUMENTS "boss data.life ability.arguments"

#define ERROR_BUFFER_SIZE 256

#define GET_PLAYER_BOSS_ID(%1) %1.GetPropInt("iBossType")

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
* @param 1    The enum struct in which the convars will be loaded into.
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
* @return           True if the boss was succesfully added to the menu.
*/
stock bool AddBossToMenuFromConfig(Menu& menu, int bossId, ConfigMap config, char selector[PLATFORM_MAX_PATH] = VSH_DEFAULT_SELECTOR_MENU_NAME, char fallbackSelector[PLATFORM_MAX_PATH] = VSH_DEFAULT_SELECTOR_NAME) {
    char tostr[10];
    IntToString(bossId, tostr, sizeof(tostr));

    /// ConfigMap can be used to store the boss name.
    int menuNameLength = config.GetSize(selector);
    char[] menuName = new char[menuNameLength];
    if(config.Get(selector, menuName, menuNameLength) != 0) {
        menu.AddItem(tostr, menuName);
        return true;
    }

    // if no menu name was found, fall back to name
    int nameLength = config.GetSize(fallbackSelector);
    char[] name = new char[nameLength];
    if(config.Get(fallbackSelector, name, nameLength) != 0) {
        menu.AddItem(tostr, name);
        return true;
    }

    return false;
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
        LogMessage("Could not find selection under selector: %s", selector);
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
    }
    else {
        LogMessage("Could not find selection under selector: %s", selector);
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

// TODO: document this
/**
* Description
*
* @param team     Param description
* @return         True if only scouts are left alive.
*/
stock bool OnlyScoutsLeft(const int team)
{
    for( int i=MaxClients; i; --i ) {
        if( !IsValidClient(i) || !IsPlayerAlive(i) )
            continue;
        else if( GetClientTeam(i) == team && TF2_GetPlayerClass(i) != TFClass_Scout )
            return false;
    }
    return true;
}

/**
* Description
*
* @param client     Param description
* @param false      Param description
* @return           Return description
*/
stock bool IsValidClient(const int client, bool nobots=false)
{
    if( client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)) )
        return false;
    return IsClientInGame(client);
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
if( !IsBossType(%1, %2) || !%1.bIsBoss) return;     \
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

/**
* Reduces the boss' rage when jarated.
*
* @param 1     The boss player.
* @param 2     The boss Id.
* @param 3     The ConVars containing rage values.
*/
#define VSH_DEFAULT_CODE_ON_BOSS_JARATED(%1,%2,%3)              \
if( !IsBossType(%1, %2)) return;                                \
float rage = %1.GetPropFloat("flRAGE");                         \
%1.SetPropFloat("flRAGE", rage - %3.jarate_rage.FloatValue);

/**
* Blocks voice lines when spoken by the boss.
*
* @param 1     The boss player.
* @param 2     The boss Id.
* @param 3     The sample.
*/
#define VSH_DEFAULT_CODE_ON_SOUND_HOOK(%1,%2,%3) \
((!IsBossType(%1, %2) || !IsVoiceLine(%3)) ? Plugin_Continue : Plugin_Handled)

