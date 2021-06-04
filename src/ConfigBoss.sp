#pragma semicolon 1

#include "include/VSH2Utils.inc"
#include "include/ConfigBoss.inc"
#include "include/VSH2Stocks.inc"
#include "formula_parser.sp"
#include <vsh2>
#include <files>
#include <console>
#include <sdkhooks>
#include <helpers>
#include <functions>

#define SELECTOR_HEALTH_FORMULA "boss data.health formula"

#define FORWARDED_ABILITIES_COUNT 3
#define BUFFER_INCREMENT 32
#define MAX_FORMULA_SIZE 64

#define IS_CONFIG_BOSS(%1) (%1 >= bossIdOffset && %1 < (bossIdOffset + bossCount))
#define GET_BOSS_CONFIG(%1) view_as<ConfigMap>(bossConfigs.Get(%1 - bossIdOffset))

enum EventForwardFlag {
    CB_OnChargeAbility = 1,
    CB_OnRageAbility = 2,
    CB_OnLifeLostAbility = 4
};

PrivateForward onChargeAbility;
PrivateForward onRageAbility;
PrivateForward onLifeLost;

VSH2GameMode vsh2_gm;
VSH2CVars vsh_cVars;
ArrayList bossConfigs;
ArrayList loadedPlugins;
int bossIdOffset = -1;
int bossCount = 0;
ConfigMap currentBossConfig;
EventForwardFlag activeForwards;

// TODO: low priority, replace all 'bossConfig' instances with 'currentBossConfig' and remove the assignment

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    CreateNative("ConfigBossHookAbility", Native_ConfigBossHookAbility);
    CreateNative("IsConfigBoss", Native_IsConfigBoss);
    CreateNative("CloneBossConfigMap", Native_CloneBossConfigMap);
}

public void OnPluginStart() {
    onChargeAbility = CreateForward(ET_Hook, Param_Cell, Param_Cell);
    onRageAbility = CreateForward(ET_Hook, Param_Cell, Param_Cell);
    onLifeLost = CreateForward(ET_Event, Param_Cell, Param_Cell, Param_Cell);

    loadedPlugins = CreateArray(MAX_ABILITY_PLUGIN_NAME);
}

public void OnLibraryAdded(const char[] name) {
    if( StrEqual(name, "VSH2") ) {
        VSH_GET_CVARS(vsh_cVars);

        char pathBuffer[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, pathBuffer,PLATFORM_MAX_PATH, "configs/saxton_hale/boss_cfgs/configCharacters");
        CreateDirectory(pathBuffer, FPERM_U_READ | FPERM_U_WRITE | FPERM_U_EXEC);
        LogMessage("config bosses are in: %s", pathBuffer);

        DirectoryListing directory = OpenDirectory(pathBuffer);

        int capacity = BUFFER_INCREMENT;
        bossConfigs = CreateArray(sizeof(ConfigMap), capacity);

        char pluginNameBuffer[64];
        char configPathBuffer[PLATFORM_MAX_PATH];
        FileType fileType;
        while(directory.GetNext(pathBuffer, PLATFORM_MAX_PATH, fileType))
        {
            if(fileType != FileType_File) {
                continue;
            }

            FormatEx(configPathBuffer, PLATFORM_MAX_PATH, "configs/saxton_hale/boss_cfgs/configCharacters/%s", pathBuffer);

            //BuildPath(Path_SM, configPathBuffer, PLATFORM_MAX_PATH, "configs/saxton_hale/boss_cfgs/CharacterConfigs/%s", pathBuffer);
            ConfigMap cfg = new ConfigMap(configPathBuffer);
            if(cfg == null) {
                LogMessage("Cannot load config file: %s",pathBuffer);
                continue;
            }

            LogMessage("loaded config file \"%s\" (handle:%i)",pathBuffer, cfg);

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
                LogMessage("Setting the bossId offset: %i", bossId);
                bossIdOffset = bossId;
            }

            bossConfigs.Set(bossCount - 1,cfg);
        }

        directory.Close();

        LogMessage("config boss count: %i", bossCount);

        if(bossCount != 0) {
            bossConfigs.Resize(bossCount);
            LoadHooks();
        }
    }
}

void LoadHooks() {
    if( !VSH2_HookEx(OnCallDownloads, HandleOnCallDownloads)) {
        LogError("Error loading OnCallDownloads forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossMenu, HandleOnBossMenu) ) {
        LogError("Error loading OnBossMenu forwards for Config Boss subplugin.");
    }

    if ( !VSH2_HookEx(OnBossSelected, HandleOnBossSelected)) {
        LogError("Error loading OnBossSelected forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossCalcHealth, HandleOnBossCalculateHealth)) {
        LogError("Error loading OnBossSelected forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnBossInitialized, HandleOnBossInitialized)) {
        LogError("Error loading OnBossCalcHealth forwards for Config Boss subplugin.");
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

    if( !VSH2_HookEx(OnRoundEndInfo, HandleOnRoundEnd)) {
        LogError("Error loading OnRoundEndInfo forwards for Config Boss subplugin.");
    }

    if(!VSH2_HookEx(OnSoundHook,HandleOnSoundHook)) {
        LogError("Error loading OnSoundHook forwards for Config Boss subplugin.");
    }

    if( !VSH2_HookEx(OnMessageIntro, HandleOnMessageIntro)) {
        LogError("Error loading OnMessageIntro forwards for Config Boss subplugin.");
    }
}

void HandleOnCallDownloads() {
    ConfigMap bossConfig;
    char path[PLATFORM_MAX_PATH];
    for(int i = 0; i < bossCount; i++)
    {
        bossConfig = view_as<ConfigMap>(bossConfigs.Get(i));

        // prepare models
        ConfigMap modelSection = bossConfig.GetSection(VSH_DEFAULT_SELECTOR_MODELS);
        if(modelSection != null) {
            for(int m = 0; m < modelSection.Size; m++) {
                if(modelSection.GetIntKey(m, path, PLATFORM_MAX_PATH)) {
                    PrepareModel(path);
                }
            }
        }

        // prepare materials
        ConfigMap materialSection = bossConfig.GetSection(VSH_DEFAULT_SELECTOR_MATERIALS);
        if(materialSection != null) {
            for(int m = 0; m < materialSection.Size; m++) {
                if(materialSection.GetIntKey(m, path, PLATFORM_MAX_PATH)) {
                    PrepareMaterial(path);
                }
            }
        }

        // prepare sounds
        ConfigMap soundSection = bossConfig.GetSection(VSH_DEFAULT_SELECTOR_SOUNDS);
        if(soundSection != null) {
            for(int ss = 0; ss <= soundSection.Size; ss++) {
                ConfigMap soundCategorySection = soundSection.GetIntSection(ss);
                if(soundCategorySection != null) {
                    for(int s = 0; s < soundCategorySection.Size; s++) {
                        if(soundCategorySection.GetIntKey(s, path, PLATFORM_MAX_PATH)) {
                            PrepareMaterial(path);
                        }
                    }
                }
            }
        }
    }
}

void HandleOnBossMenu(Menu& menu) {
    ConfigMap bossConfig;
    for(int i = 0; i < bossCount; i++)
    {
        bossConfig = view_as<ConfigMap>(bossConfigs.Get(i));
        if(!AddBossToMenuFromConfig(menu, bossIdOffset + i, bossConfig)) {
            LogMessage("Config boss %i could not set a menu name, missing \"menu name\"/\"name\" field", i );
        }
    }
}

void HandleOnBossSelected(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    LogMessage("on boss selected executed");

    ConfigMap bossConfig = GET_BOSS_CONFIG(bossId);
    currentBossConfig = bossConfig;
    SetPanelMessageFromConfig(player, bossConfig);
}

void HandleOnBossCalculateHealth(const VSH2Player player, int& max_health, const int boss_count, const int red_players) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    char formula[MAX_FORMULA_SIZE];
    if(currentBossConfig.Get(SELECTOR_HEALTH_FORMULA,formula, MAX_FORMULA_SIZE)) {
        max_health = RoundToFloor(ParseFormula(formula, boss_count + red_players));
    }

    int lives;
    if(currentBossConfig.GetInt(VSH_DEFAULT_SELECTOR_LIVES, lives)) {
        player.SetPropInt("iLives", lives);
        player.SetPropInt("iMaxLives", lives);
    }
}

void HandleOnBossInitialized(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    if(!SDKHookEx(player.index,SDKHook_OnTakeDamageAlive, HandleOnBossTakeDamage)) {
        LogError("Error loading OnBossTakeDamage forwards for Config Boss subplugin.");
    }

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

    int classId;
    if(bossConfig.GetInt(VSH_DEFAULT_SELECTOR_CLASS, classId) == 0) {
        classId = view_as<int>(TFClass_Scout);
        LogMessage("Could not load value from \"%s\". Defaulting to Scout (%i)", VSH_DEFAULT_SELECTOR_CLASS, classId);
    }
    SetEntProp(player.index, Prop_Send, "m_iClass", classId);

    LoadPlugins(bossConfig);
}

void HandleOnBossEquipped(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

    SetPlayerNameToBossFromConfig(player, bossConfig, VSH_DEFAULT_SELECTOR_NAME);

    bool parsedWeapon = true;

    int weaponClassLength = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_WEAPON_CLASS);
    char[] weaponClassString = new char[weaponClassLength];
    if(bossConfig.Get(VSH_DEFAULT_SELECTOR_WEAPON_CLASS, weaponClassString, weaponClassLength) == 0) {
        int name_len = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_MENU_NAME);
        char[] name = new char[name_len];
        bossConfig.Get(VSH_DEFAULT_SELECTOR_MENU_NAME, name, name_len);
        LogMessage("(%s) Could not get weapon class under \"%s\"", name, VSH_DEFAULT_SELECTOR_WEAPON_CLASS);
        parsedWeapon = false;
    }

    int weaponId;
    if(bossConfig.GetInt(VSH_DEFAULT_SELECTOR_WEAPON_ID, weaponId) == 0) {
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

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

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

// TODO: mess around with the speed think
void HandleOnBossThink(const VSH2Player player)
{
    int bossId = player.GetPropInt("iBossType");
    int client = player.index;

    if(!IS_CONFIG_BOSS(bossId) || !IsPlayerAlive(client)) {
        return;
    }

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

    float defaultSpeed, maxSpeed;
    //if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_MOVE_SPEED, defaultSpeed) == 0){
    defaultSpeed = DEFAULT_SPEED;
    //}

    if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_MOVE_SPEED, defaultSpeed) == 0){
        maxSpeed = DEFAULT_MAX_SPEED;
    }

    player.SpeedThink(maxSpeed,defaultSpeed);
    player.GlowThink(0.1);

    if( OnlyScoutsLeft(VSH2Team_Red) ) {
        player.SetPropFloat("flRAGE", player.GetPropFloat("flRAGE") + vsh_cVars.scout_rage_gen.FloatValue);
    }

    /// hud code
    SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
    Handle hud = vsh2_gm.hHUD;
    float rage = player.GetPropFloat("flRAGE");

    char abilityName[MAX_ABILITY_NAME_SIZE];
    if(activeForwards & CB_OnChargeAbility) {
        float charge = player.GetPropFloat("flCharge");

        float chargeTime;
        if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_ARGUMENTS_CHARGE_TIME, chargeTime) == 0) {
            chargeTime = DEFAULT_CHARGE_TIME;
        }

        if(player.SuperJumpThink(CHARGE/chargeTime, FULL_CHARGE)) {

            bool requireFullCharge;
            if(bossConfig.GetBool(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_REQUIRE_FULL_CHARGE, requireFullCharge)) {
                requireFullCharge = false;
            }

            if(!requireFullCharge || charge >= FULL_CHARGE){
                Call_StartForward(onChargeAbility);
                Call_PushCell(player);
                Call_Finish();

                float cooldown;
                if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_ARGUMENTS_COOLDOWN, cooldown) == 0) {
                    cooldown = DEFAULT_CHARGE_COOLDOWN;
                }

                player.SetPropFloat("flCharge", cooldown);
            }
        }

        if(bossConfig.Get(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_NAME, abilityName, MAX_ABILITY_NAME_SIZE) == 0) {
            abilityName = "Ability";
        }

        if( rage >= 100.0 ) {
            ShowSyncHudText(client, hud, "%s: %i%% | Rage: FULL - Call Medic (default: E) to activate",abilityName, player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(charge) * 4);
        }
        else {
            ShowSyncHudText(client, hud, "%s: %i%% | Rage: %0.1f",abilityName, player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(charge) * 4, rage);
        }
    }
    else {
        if( rage >= 100.0 ) {
            ShowSyncHudText(client, hud, "Rage: FULL - Call Medic (default: E) to activate");
        }
        else {
            ShowSyncHudText(client, hud, "Rage: %0.1f", rage);
        }
    }
}

void HandleOnBossMedicCall(const VSH2Player player)
{
    int bossId = player.GetPropInt("iBossType");

    if( !IS_CONFIG_BOSS(bossId) || player.GetPropFloat("flRAGE") < 100.0) {
        return;
    }

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

    PrintCfg(bossConfig);

    LogMessage("Config Boss config handle: %i", bossConfig);

    if(activeForwards & CB_OnRageAbility) {
        LogMessage("Doing custom rage");

        Call_StartForward(onRageAbility);
        Call_PushCell(player);
        Call_Finish();
    }
    else {
        // use ConfigMap to set how large the rage radius is
        float radius;
        if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_RAGE_DISTANCE, radius) == 0 ) {
            radius = DEFAULT_RAGE_RADIUS;
        }

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

Action HandleOnBossTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
    VSH2Player player = VSH2Player(victim);

    if((float(player.iHealth) - damage) > 0.0) {
        return Plugin_Continue;
    }

    int lives = player.GetPropInt("iLives") - 1;

    // check if boss lost last life
    if(lives <= 0) {
        return Plugin_Continue;
    }

    damage = 0.0;
    player.SetPropInt("iLives", lives);
    player.iHealth = player.GetPropInt("iMaxHealth");

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

    PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_LIFE_LOST, VSH2_VOICE_RAGE);

    Call_StartForward(onLifeLost);
    Call_PushCell(player);
    Call_PushCell(attacker);
    Call_Finish();

    return Plugin_Handled;
}

void HandleOnBossDeath(const VSH2Player player) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

    PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_DEATH, VSH2_VOICE_LOSE);
}

void HandleOnRoundEnd(const VSH2Player player, bool bossBool, char message[MAXMESSAGE]) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return;
    }

    SDKUnhook(player.index,SDKHook_OnTakeDamageAlive, HandleOnBossTakeDamage);

    ConfigMap bossConfig = currentBossConfig; // GET_BOSS_CONFIG(bossId);

    if(bossBool) {
        PlayRandomSoundFromConfigSelector(player, bossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_WIN, VSH2_VOICE_LOSE);
    }

    UnloadPlugins();

    currentBossConfig = view_as<ConfigMap>(INVALID_HANDLE);
}

Action HandleOnSoundHook(const VSH2Player player, char sample[PLATFORM_MAX_PATH], int& channel, float& volume, int& level, int& pitch, int& flags) {
    int bossId = player.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId) || !IsVoiceLine(sample)) {
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

Action HandleOnMessageIntro(const VSH2Player boss, char message[MAXMESSAGE]) {
    int bossId = boss.GetPropInt("iBossType");

    if(!IS_CONFIG_BOSS(bossId)) {
        return Plugin_Continue;
    }

    int lives = boss.GetPropInt("iLives");
    if(lives > 1) {
        char newMessage[MAXMESSAGE];
        FormatEx(newMessage, MAXMESSAGE, "%s x%i",message, lives);
        message = newMessage;
    }

    return Plugin_Continue;
}

void LoadPlugins(ConfigMap bossConfig) {
    int abilityToLoad = 0;

    ConfigMap chargeAbilitySection = bossConfig.GetSection(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY);
    int chargeAbilityCount = 0;
    if(chargeAbilitySection != null) {
        chargeAbilityCount = chargeAbilitySection.Size;
    }
    int[] chargeAbilityPluginIndices = new int[chargeAbilityCount];
    if(chargeAbilityCount != 0) {
        abilityToLoad |= view_as<int>(CB_OnChargeAbility);

        for(int i = 0; i < chargeAbilityCount; ++i)
        {
            ConfigMap pluginSection = chargeAbilitySection.GetIntSection(i);
            chargeAbilityPluginIndices[i] = LoadPlugin(pluginSection, i);
        }
    }

    ConfigMap rageAbilitySection = bossConfig.GetSection(VSH_DEFAULT_SELECTOR_RAGE_ABILITY);
    int rageAbilityCount = 0;
    if(rageAbilitySection != null) {
        rageAbilityCount = rageAbilitySection.Size;
    }
    int[] rageAbilityPluginIndices = new int[rageAbilityCount];
    if(rageAbilityCount != 0) {
        abilityToLoad |= view_as<int>(CB_OnRageAbility);

        for(int i = 0; i < rageAbilityCount; ++i)
        {
            ConfigMap pluginSection = rageAbilitySection.GetIntSection(i);
            rageAbilityPluginIndices[i] = LoadPlugin(pluginSection, i);
        }
    }

    ConfigMap onLifeLostAbilitySection = bossConfig.GetSection(VSH_DEFAULT_SELECTOR_LIFE_LOST_ABILITY);
    int onLifeLostAbilityCount = 0;
    if(onLifeLostAbilitySection != null) {
        onLifeLostAbilityCount = onLifeLostAbilitySection.Size;
    }
    int[] OnLifeLostPluginIndices = new int[onLifeLostAbilityCount];
    if(onLifeLostAbilityCount != 0) {
        abilityToLoad |= view_as<int>(CB_OnLifeLostAbility);

        for(int i = 0; i < onLifeLostAbilityCount; ++i)
        {
            ConfigMap pluginSection = onLifeLostAbilitySection.GetIntSection(i);
            OnLifeLostPluginIndices[i] = LoadPlugin(pluginSection, i);
        }
    }

    ServerExecute();

    // load plugin handles
    Handle[] pluginHandles = new Handle[loadedPlugins.Length];
    char pluginFileBuffer[PLATFORM_MAX_PATH];
    for(int i = 0; i < loadedPlugins.Length; i++)
    {
        char pluginNameBuffer[MAX_ABILITY_PLUGIN_NAME];
        loadedPlugins.GetString(i, pluginNameBuffer, MAX_ABILITY_PLUGIN_NAME);
        Format(pluginFileBuffer, PLATFORM_MAX_PATH, "vsh2bosses/Abilities/%s.smx", pluginNameBuffer);
        Handle pluginHandle = FindPluginByFile(pluginFileBuffer);

        if(pluginHandle == INVALID_HANDLE) {
            LogMessage("Could not get handle from plugin: \"%s\"", pluginFileBuffer);
        }

        pluginHandles[i] = pluginHandle;
    }

    RegisterAbilityPlugins(pluginHandles, chargeAbilityPluginIndices, chargeAbilityCount, "RegisterChargeAbility");
    RegisterAbilityPlugins(pluginHandles, rageAbilityPluginIndices, rageAbilityCount, "RegisterRageAbility");
    RegisterAbilityPlugins(pluginHandles, OnLifeLostPluginIndices, onLifeLostAbilityCount, "RegisterOnLifeLostAbility");

    activeForwards = view_as<EventForwardFlag>(abilityToLoad);
}

int LoadPlugin(ConfigMap pluginSection, int sectionIndex) {
    char pluginNameBuffer[MAX_ABILITY_PLUGIN_NAME];
    if(pluginSection.Get("plugin", pluginNameBuffer, MAX_ABILITY_PLUGIN_NAME) == 0) {
        LogMessage("Could not read \"plugin\" field of charge ability %i", sectionIndex);
        return -1;
    }

    int pluginIndex = loadedPlugins.FindString(pluginNameBuffer);
    if(pluginIndex != -1) {
        return pluginIndex;
    }
    else {
        ServerCommand("sm plugins load vsh2bosses/Abilities/%s.smx", pluginNameBuffer);
        return loadedPlugins.PushString(pluginNameBuffer);
    }
}

void RegisterAbilityPlugins(Handle[] pluginHandles, int[] abilityPluginIndices, int abilityCount, char[] abilityFunctionName) {
    for(int i = 0; i < abilityCount; i++)
    {
        if(abilityPluginIndices[i] == -1) {
            continue;
        }

        Handle pluginHandle = pluginHandles[abilityPluginIndices[i]];

        Function registerAbilityFunction = GetFunctionByName(pluginHandle, abilityFunctionName);
        if(registerAbilityFunction == INVALID_FUNCTION) {
            char pluginNameBuffer[MAX_ABILITY_PLUGIN_NAME];
            loadedPlugins.GetString(abilityPluginIndices[i], pluginNameBuffer, MAX_ABILITY_PLUGIN_NAME);
            LogMessage("%s ability plugin does not support registering specified ability (missing \"%s(int)\" function)", pluginNameBuffer, abilityFunctionName);
            continue;
        }

        Call_StartFunction(pluginHandle, registerAbilityFunction);
        Call_PushCell(i);
        Call_Finish();
    }
}

void UnloadPlugins() {
    char pluginNameBuffer[MAX_ABILITY_PLUGIN_NAME];

    activeForwards = view_as<EventForwardFlag>(0);

    for(int i = 0; i < loadedPlugins.Length; ++i) {
        loadedPlugins.GetString(i, pluginNameBuffer, MAX_ABILITY_PLUGIN_NAME);

        ServerCommand("sm plugins unload vsh2bosses/Abilities/%s.smx", pluginNameBuffer);
    }
}

Native_ConfigBossHookAbility(Handle plugin, int numParams) {
    CallbackType hook = GetNativeCell(1);
    Function func = GetNativeFunction(2);
    switch (hook) {
        case OnChargeAbility: {
            return onChargeAbility.AddFunction(plugin, func);
        }
        case OnRageAbility: {
            return onRageAbility.AddFunction(plugin, func);
        }
    }

    return 0;
}

Native_IsConfigBoss(Handle plugin, int numParams) {
    VSH2Player bossPlayer = GetNativeCell(1);
    int bossId = bossPlayer.GetPropInt("iBossType");

    return IS_CONFIG_BOSS(bossId);
}

Native_CloneBossConfigMap(Handle plugin, int numParams) {
    return view_as<int>(currentBossConfig.Clone(plugin));
}