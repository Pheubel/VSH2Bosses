#pragma semicolon 1

#include "include/VSH2Utils.inc"
#include <vsh2>
#include <files>
#include <console>

#define CHARACTER_CONFIG_FILE_PATH "configs/saxton_hale/boss_cfgs/configCharacters.cfg"

#define MINIMAL_STREAK_FOR_SPREE 3
#define DEFAULT_SPEED 100.0
#define DEFAULT_MAX_SPEED 340.0
#define DEFAULT_RAGE_RADIUS 300.0

#define IS_CONFIG_BOSS(%1) (%1 >= bossIdOffset || %1 < (bossIdOffset + bossCount))
#define GET_BOSS_CONFIG(%1) view_as<ConfigMap>(bossConfigs.Get(%1 - bossIdOffset))

VSH2GameMode vsh2_gm;
VSH2CVars vsh_cVars;
ArrayList bossConfigs;
int bossIdOffset = -1;
int bossCount = 0;

#define BUFFER_INCREMENT 32

public void OnLibraryAdded(const char[] name) {
    if( StrEqual(name, "VSH2") ) {
        VSH_GET_CVARS(vsh_cVars);

        char pathBuffer[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, pathBuffer,PLATFORM_MAX_PATH, CHARACTER_CONFIG_FILE_PATH);

        // TODO: make sure if "a+" is the right mode, should be read or create
        File file = OpenFile(pathBuffer, "a+");
        if(file == null) {
            LogError("Could not open %s", pathBuffer);
            return;
        }

        int capacity = BUFFER_INCREMENT;
        bossConfigs = CreateArray(sizeof(ConfigMap), capacity);

        char pluginNameBuffer[64];
        char configPathBuffer[PLATFORM_MAX_PATH];
        while(file.ReadLine(pathBuffer, PLATFORM_MAX_PATH))
        {
            BuildPath(Path_SM, configPathBuffer, PLATFORM_MAX_PATH, "configs/saxton_hale/boss_cfgs/CharacterConfigs/%s", pathBuffer);
            ConfigMap cfg = new ConfigMap(configPathBuffer);
            if(cfg == null) {
                LogMessage("Cannot load config file: %s",pathBuffer);
                continue;
            }

            bool isDisabled = false;
            if(cfg.GetBool(VSH_DEFAULT_SELECTOR_DISABLE, isDisabled) == 0 || isDisabled) {
                delete cfg;
            }

            bossCount += 1;
            if(bossCount > capacity) {
                capacity += BUFFER_INCREMENT;
                bossConfigs.Resize(capacity);
            }

            FormatEx(pluginNameBuffer, sizeof(pluginNameBuffer), "vsh_config_boss_%i", bossCount);
            int bossId = VSH2_RegisterPlugin(pluginNameBuffer);

            if(bossIdOffset == -1) {
                bossIdOffset = bossId;
            }

            bossConfigs.Push(cfg);
        }

        file.Close();

        if(bossCount != 0) {
            bossConfigs.Resize(bossCount);
            LoadHooks();
        }
    }
}

void LoadHooks() {
    if( !VSH2_HookEx(OnCallDownloads, Template_OnCallDownloads)) {
		LogError("Error loading OnCallDownloads forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossMenu, HandleOnBossMenu) ) {
        LogError("Error loading OnBossMenu forwards for Config Boss subplugin.");
    }

    if ( !VSH2_HookEx(OnBossSelected, HandleOnBossSelected)) {
        LogError("Error loading OnBossSelected forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossInitialized, HandleOnBossInitialized)) {
        LogError("Error loading OnBossInitialized forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossEquipped, HandleOnBossEquipped)) {
        LogError("Error loading OnBossEquipped forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossPlayIntro, HandleOnBossPlayIntro)) {
        LogError("Error loading OnBossPlayIntro forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerKilled, HandleOnPlayerKilled)) {
        LogError("Error loading OnPlayerKilled forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerHurt, HandleOnPayerHurt)) {
        LogError("Error loading OnPlayerKilled forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerAirblasted, HandleOnPlayerAirblasted)) {
        LogError("Error loading OnPlayerKilled forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossJarated, HandleOnBossJarated)) {
        LogError("Error loading OnPlayerKilled forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossThink, HandleOnBossThink)) {
        LogError("Error loading OnBossThink forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossMedicCall, HandleOnBossMedicCall)) {
        LogError("Error loading OnBossMedicCall forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossDeath, HandleOnBossDeath)) {
        LogError("Error loading OnBossDeath forwards for Config Boss subplugin.");
    }

    // TODO: do stuff here when lives are working
    // if( !VSH2_HookEx(OnBossDeath, HandleOnBossRealDeath)) {
    //     LogError("Error loading OnBossDeath (real death) forwards for Config Boss subplugin.");
    // }

    if( !VSH2_HookEx(OnRoundEndInfo, HandleOnRoundEnd)) {
        LogError("Error loading OnRoundEndInfo forwards for Config Boss subplugin.");
    }

    if(!VSH2_HookEx(OnSoundHook,HandleOnSoundHook)) {
        LogError("Error loading OnSoundHook forwards for Config Boss subplugin.");
    }
}



void HandleOnBossMenu(Menu& menu) {
    ConfigMap bossConfig;
    for(int i = 0; i <= bossCount; i++)
    {
        bossConfig = view_as<ConfigMap>(bossConfigs.Get(i));
        AddBossToMenuFromConfig(menu, bossIdOffset + i, bossConfig);
    }
}

void HandleOnBossSelected(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);
    SetPanelMessageFromConfig(player, bossConfig);
}

void HandleOnBossInitialized(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);

    int value;
    if(bossConfig.GetInt(VSH_DEFAULT_SELECTOR_CLASS, value)) {
        value = view_as<int>(TFClass_Scout);
        LogMessage("Could not load value from \"%s\". Defaulting to Scout (%i)", VSH_DEFAULT_SELECTOR_CLASS, value);
    }
    SetEntProp(player.index, Prop_Send, "m_iClass", value);

    if(bossConfig.GetInt(VSH_DEFAULT_SELECTOR_LIVES, value) != 0) {
        LogMessage("Lives are currently not supported.");
        // TODO: implement lives
        // player.SetPropInt("iLives", value);
    }

    LoadPlugins(bossConfig);
}

void HandleOnBossEquipped(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);

    SetPlayerNameToBossFromConfig(player, bossConfig, VSH_DEFAULT_SELECTOR_NAME);

    bool parsedWeapon = true;

    int weaponClassLength = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_WEAPON_CLASS);
    char[] weaponClassString = new char[weaponClassLength];
    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_WEAPON_CLASS, weaponClassString, weaponClassLength)) {
        int name_len = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_MENU_NAME);
        char[] name = new char[name_len];
        bossConfig.Get(VSH_DEFAULT_SELECTOR_MENU_NAME, name, name_len);
        LogMessage("(%s) Could not get weapon class under \"%s\"", name, VSH_DEFAULT_SELECTOR_WEAPON_CLASS);
        parsedWeapon = false;
    }

    int weaponId;
    if(bossConfig.GetInt(VSH_DEFAULT_SELECTOR_WEAPON_ID, weaponId)) {
        int name_len = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_MENU_NAME);
        char[] name = new char[name_len];
        bossConfig.Get(VSH_DEFAULT_SELECTOR_MENU_NAME, name, name_len);
        LogMessage("(%s) Could not get weapon ID under \"%s\"", name, VSH_DEFAULT_SELECTOR_WEAPON_ID);

        parsedWeapon = false;
    }

    if(!parsedWeapon) {
        return;
    }

    player.RemoveAllItems();

    int attributeLength = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_WEAPON_ATTRIBUTES);
    char[] attributeString = new char[attributeLength];
    bossConfig.Get(VSH_DEFAULT_SELECTOR_WEAPON_ATTRIBUTES, attributeString, attributeLength);

    int wep = player.SpawnWeapon(weaponClassString, weaponId, 100, 5, attributeString);
    SetEntPropEnt(player.index, Prop_Send, "m_hActiveWeapon", wep);
}

void HandleOnBossPlayIntro(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);

    PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_INTROS, VSH2_VOICE_INTRO);
}

void HandleOnPlayerKilled(const VSH2Player attacker, const VSH2Player victim, Event event) {
    int bossId = attacker.GetPropInt("iBossType");

    if(!attacker.bIsBoss ||!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);
    int streak = HandleKillingSpree(attacker);

    if (vsh2_gm.iLivingReds != 1) {
        if(streak == MINIMAL_STREAK_FOR_SPREE) {
            PlayRandomSoundFromConfigSelector(attacker, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_SPREE, VSH2_VOICE_SPREE);
        }
        else {
            PlayRandomClassSoundFromConfigSelector(attacker, victim.GetTFClass(), bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_KILL_CLASS, VSH2_VOICE_SPREE);
        }
    }
}

void HandleOnPayerHurt(const VSH2Player attacker, const VSH2Player victim, Event event) {
    int bossId = victim.GetPropInt("iBossType");

    if(!victim.bIsBoss || !IS_CONFIG_BOSS(bossId)) {
        return;
    }

    int damage = event.GetInt("damageamount");
    victim.GiveRage(damage);
}

void HandleOnPlayerAirblasted(const VSH2Player airblaster, const VSH2Player airblasted, Event event) {
    int bossId = airblasted.GetPropInt("iBossType");

    if(!airblasted.bIsBoss || !IS_CONFIG_BOSS(bossId)) {
        return;
    }

    float rage = airblasted.GetPropFloat("flRAGE");
    airblasted.SetPropFloat("flRAGE", rage + vsh_cVars.airblast_rage.FloatValue);
}

void HandleOnBossJarated(const VSH2Player victim, const VSH2Player thrower) {
    int bossId = victim.GetPropInt("iBossType");

    if(!victim.bIsBoss || !IS_CONFIG_BOSS(bossId)) {
        return;
    }

    float rage = victim.GetPropFloat("flRAGE");
    victim.SetPropFloat("flRAGE", rage - vsh_cVars.jarate_rage.FloatValue);
}

void HandleOnBossThink(const VSH2Player player)
{
    int bossId = player.GetPropInt("iBossType");
    int client = player.index;

    if(!IS_CONFIG_BOSS(bossId) || !IsPlayerAlive(client)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);

    float defaultSpeed, maxSpeed;
    if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_MOVE_SPEED, defaultSpeed) == 0){
        defaultSpeed = DEFAULT_SPEED;
    }

    if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_MAX_SPEED, defaultSpeed) == 0){
        maxSpeed = DEFAULT_MAX_SPEED;
    }

    player.SpeedThink(maxSpeed,defaultSpeed);
    player.GlowThink(0.1);

    char abilityPluginName[64];
    char abilityName[32] = "Ability";
    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_PLUGIN, abilityPluginName, sizeof(abilityPluginName)) == 0) {
        //TODO: call forward function to execute ability in child plugin
    }
    else {
        abilityName = "Jump";
        if( player.SuperJumpThink(2.5, 25.0) ) {
            PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_CHARGE_ABILITY, VSH2_VOICE_ABILITY);
            player.SuperJump(player.GetPropFloat("flCharge"), -100.0);
        }

        player.WeighDownThink(2.0, 0.1);
    }

    if( OnlyScoutsLeft(VSH2Team_Red) ) {
        player.SetPropFloat("flRAGE", player.GetPropFloat("flRAGE") + vsh_cVars.scout_rage_gen.FloatValue);
    }

    /// hud code
    SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
    Handle hud = vsh2_gm.hHUD;
    float charge = player.GetPropFloat("flCharge");
    float rage = player.GetPropFloat("flRAGE");
    if( rage >= 100.0 ) {
        ShowSyncHudText(client, hud, "%s: %i%% | Rage: FULL - Call Medic (default: E) to activate",abilityName, player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(charge) * 4);
    }
    else {
        ShowSyncHudText(client, hud, "%s: %i%% | Rage: %0.1f",abilityName, player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(charge) * 4, rage);
    }
}

void HandleOnBossMedicCall(const VSH2Player player)
{
    int bossId = player.GetPropInt("iBossType");

    if( !IS_CONFIG_BOSS(bossId) || player.GetPropFloat("flRAGE") < 100.0) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);

    char ragePluginName[64];
    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_PLUGIN, ragePluginName, sizeof(ragePluginName)) == 0) {
        //TODO: call forward function to execute ability in child plugin
    }
    else {
        // use ConfigMap to set how large the rage radius is
        float radius = DEFAULT_RAGE_RADIUS;
        bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_RAGE_DISTANCE, radius);

        player.DoGenericStun(radius);
        VSH2Player[] players = new VSH2Player[MaxClients];
        int in_range = player.GetPlayersInRange(players, radius);
        for( int i; i < in_range; i++ ) {
            if( players[i].bIsBoss || players[i].bIsMinion ) {
                continue;
            }
        }
    }

    PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_RAGE, VSH2_VOICE_RAGE);
    player.SetPropFloat("flRAGE", 0.0);
}

void HandleOnBossDeath(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);

    PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_DEATH, VSH2_VOICE_LOSE);
}

void HandleOnRoundEnd(const VSH2Player player, bool bossBool, char message[MAXMESSAGE]) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);

    if(bossBool) {
        PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_WIN, VSH2_VOICE_LOSE);
    }

    UnloadPlugins(bossConfig);
}

Action HandleOnSoundHook(const VSH2Player player, char sample[PLATFORM_MAX_PATH], int& channel, float& volume, int& level, int& pitch, int& flags) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId) || !IsVoiceLine(sample)) {
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

void LoadPlugins(ConfigMap bossConfig) {
    char chargeAbilityPluginName[64];
    char rageAbilityPluginName[64];
    int abilityToLoad = 0;

    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_PLUGIN, chargeAbilityPluginName, sizeof(chargeAbilityPluginName)) != 0) {
        abilityToLoad |= 1;
    }
    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_RAGE_ABILITY_PLUGIN, rageAbilityPluginName, sizeof(rageAbilityPluginName)) != 0) {
        abilityToLoad |= 2;
    }

    switch(abilityToLoad) {
        case 0: {
            return;
        }
        case 1: {
            ServerCommand("sm plugins load vsh2bosses/Abilities/%s.smx", chargeAbilityPluginName);
        }
        case 2: {
            ServerCommand("sm plugins load vsh2bosses/Abilities/%s.smx", rageAbilityPluginName);
        }
        case 3: {
            if(StrEqual(chargeAbilityPluginName, rageAbilityPluginName, true)) {
                ServerCommand("sm plugins load vsh2bosses/Abilities/%s.smx", chargeAbilityPluginName);
            }
            else {
                ServerCommand("sm plugins load vsh2bosses/Abilities/%s.smx", chargeAbilityPluginName);
                ServerCommand("sm plugins load vsh2bosses/Abilities/%s.smx", rageAbilityPluginName);
            }
        }
    }
}

void UnloadPlugins(ConfigMap bossConfig) {
    char chargeAbilityPluginName[64];
    char rageAbilityPluginName[64];
    int abilityToLoad = 0;

    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_PLUGIN, chargeAbilityPluginName, sizeof(chargeAbilityPluginName)) != 0) {
        abilityToLoad |= 1;
    }
    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_RAGE_ABILITY_PLUGIN, rageAbilityPluginName, sizeof(rageAbilityPluginName)) != 0) {
        abilityToLoad |= 2;
    }

    switch(abilityToLoad) {
        case 0: {
            return;
        }
        case 1: {
            ServerCommand("sm plugins unload vsh2bosses/Abilities/%s.smx", chargeAbilityPluginName);
        }
        case 2: {
            ServerCommand("sm plugins unload vsh2bosses/Abilities/%s.smx", rageAbilityPluginName);
        }
        case 3: {
            if(StrEqual(chargeAbilityPluginName, rageAbilityPluginName, true)) {
                ServerCommand("sm plugins unload vsh2bosses/Abilities/%s.smx", chargeAbilityPluginName);
            }
            else {
                ServerCommand("sm plugins unload vsh2bosses/Abilities/%s.smx", chargeAbilityPluginName);
                ServerCommand("sm plugins unload vsh2bosses/Abilities/%s.smx", rageAbilityPluginName);
            }
        }
    }
}