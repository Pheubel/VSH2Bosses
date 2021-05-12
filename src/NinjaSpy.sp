#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <vsh2>
#include "include/VSH2Utils.inc"
#include "include/ItemAttributes.inc"
#include "include/ItemDefinitions.inc"

#define SELECTOR_TIMESCALE "boss data.timescale"
#define SELECTOR_SLOWMOTION_DURATION "boss data.slomo duration"

#define SLOMO_TIMESCALE 0.1
#define INVERSE_SLOMO (1.0/SLOMO_TIMESCALE)
#define DEFAULT_SLOWMOTION_DURATION 6.0

#define CVAR_NAME_HOST_TIMESCALE "host_timescale"
#define CVAR_NAME_PHYSICS_TIMESCALE "phys_timescale"
#define SOUND_SLOWMOTION_START "replay/enterperformancemode.wav"

#define PLAYER_PROPERTY_MAX_SPEED "m_flMaxspeed"

int BossId;
VSH2CVars VSH_CVars;
ConfigMap BossConfig;
VSH2GameMode vsh2_gm;
ConVar cvar_TimeScale;
bool isSlomoActive;

// Set up the Ninja Spy add-on after the VSH2 library has been added.
public void OnLibraryAdded(const char[] name) {
    if( StrEqual(name, "VSH2") ) {
        VSH_GET_CVARS(VSH_CVars);
        cvar_TimeScale = FindConVar(CVAR_NAME_HOST_TIMESCALE);
        int flags = GetConVarFlags(cvar_TimeScale);
        SetConVarFlags(cvar_TimeScale, (flags & ~(FCVAR_CHEAT)));

        BossConfig = new ConfigMap("configs/saxton_hale/boss_cfgs/NinjaSpy.cfg");
        bool isDisabled;
        if(BossConfig == null  || (BossConfig.GetBool(VSH_DEFAULT_SELECTOR_DISABLE, isDisabled) == 0) || isDisabled) {
            return;
        }

        BossId = VSH2_RegisterPlugin("VSH_Ninja_Spy");
        LoadHooks();
    }
}

// TODO: drop slomo when done

// Load all hooks used by the Ninja Spy boss.
void LoadHooks() {
    if( !VSH2_HookEx(OnBossMenu, HandleOnBossMenu) ) {
        LogError("Error loading OnBossMenu forwards for Ninja Spy subplugin.");
    }

    if ( !VSH2_HookEx(OnBossSelected, HandleOnBossSelected)) {
        LogError("Error loading OnBossSelected forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossInitialized, HandleOnBossInitialized)) {
        LogError("Error loading OnBossInitialized forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossEquipped, HandleOnBossEquipped)) {
        LogError("Error loading OnBossEquipped forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossPlayIntro, HandleOnBossPlayIntro)) {
        LogError("Error loading OnBossPlayIntro forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerKilled, HandleOnPlayerKilled)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerHurt, HandleOnPayerHurt)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnPlayerAirblasted, HandleOnPlayerAirblasted)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossJarated, HandleOnBossJarated)) {
        LogError("Error loading OnPlayerKilled forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossThink, HandleOnBossThink)) {
        LogError("Error loading OnBossThink forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossMedicCall, HandleOnBossMedicCall)) {
        LogError("Error loading OnBossMedicCall forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossDeath, HandleOnBossDeath)) {
        LogError("Error loading OnBossDeath forwards for Ninja Spy subplugin.");
    }

    if( !VSH2_HookEx(OnBossDeath, HandleOnBossRealDeath)) {
        LogError("Error loading OnBossDeath (real death) forwards for Ninja Spy subplugin.");
    }

    if(!VSH2_HookEx(OnSoundHook,HandleOnSoundHook)) {
        LogError("Error loading OnSoundHook forwards for Ninja Spy subplugin.");
    }
}

void HandleOnBossMenu(Menu& menu) {
    AddBossToMenuFromConfig(menu, BossId, BossConfig);
}

void HandleOnBossSelected(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    SetPanelMessageFromConfig(player, BossConfig);
}

void HandleOnBossInitialized(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    SetEntProp(player.index, Prop_Send, "m_iClass", view_as<int>(TFClass_Spy));
    player.SetPropInt("iLives", 3);
}

void HandleOnBossEquipped(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    SetPlayerNameToBossFromConfig(player, BossConfig, VSH_DEFAULT_SELECTOR_NAME);
    player.RemoveAllItems();

    int attributeLength = BossConfig.GetSize(VSH_DEFAULT_SELECTOR_WEAPON_ATTRIBUTES);
    char[] attributeString = new char[attributeLength];
    BossConfig.Get(VSH_DEFAULT_SELECTOR_WEAPON_ATTRIBUTES, attributeString, attributeLength);

    int wep = player.SpawnWeapon(TF_WEAPON_CLASS_SNIPER_MELEE_THE_SHAHANSHAH, TF_WEAPON_ID_SNIPER_MELEE_THE_SHAHANSHAH, 100, 5, attributeString);
    SetEntPropEnt(player.index, Prop_Send, "m_hActiveWeapon", wep);
}

void HandleOnBossPlayIntro(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    PlayRandomSoundFromConfigSelector(player, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_INTROS, VSH2_VOICE_INTRO);
}

void HandleOnPlayerKilled(const VSH2Player attacker, const VSH2Player victim, Event event) {
    if( !IsBossType(attacker, BossId)) {
        return;
    }

    int streak = HandleKillingSpree(attacker);

    if (vsh2_gm.iLivingReds != 1) {
        if(streak == 3) {
            PlayRandomSoundFromConfigSelector(attacker, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_SPREE, VSH2_VOICE_SPREE);
        }
        else {
            PlayRandomClassSoundFromConfigSelector(attacker, victim.GetTFClass(), BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_KILL_CLASS, VSH2_VOICE_SPREE);
        }
    }
}

void HandleOnPayerHurt(const VSH2Player attacker, const VSH2Player victim, Event event) {
    VSH_DEFAULT_CODE_ON_PLAYER_HURT(victim, BossId, event);
}

void HandleOnPlayerAirblasted(const VSH2Player airblaster, const VSH2Player airblasted, Event event) {
    VSH_DEFAULT_CODE_ON_PLAYER_AIRBLASTED(airblasted, BossId, VSH_CVars);
}

void HandleOnBossJarated(const VSH2Player victim, const VSH2Player thrower) {
    VSH_DEFAULT_CODE_ON_BOSS_JARATED(victim, BossId, VSH_CVars)
}

void HandleOnBossThink(const VSH2Player player)
{
    int client = player.index;
    if( !IsBossType(player, BossId) || !IsPlayerAlive(client)) {
        return;
    }

    player.SpeedThink(340.0);
    player.GlowThink(0.1);
    if( player.SuperJumpThink(2.5, 25.0) ) {
        PlayRandomSoundFromConfigSelector(player, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_SUPER_JUMP, VSH2_VOICE_ABILITY);
        player.SuperJump(player.GetPropFloat("flCharge"), -100.0);
    }

    if( OnlyScoutsLeft(VSH2Team_Red) ) {
        player.SetPropFloat("flRAGE", player.GetPropFloat("flRAGE") + VSH_CVars.scout_rage_gen.FloatValue);
    }

    player.WeighDownThink(2.0, 0.1);

    /// hud code
    SetHudTextParams(-1.0, 0.77, 0.35, 255, 255, 255, 255);
    Handle hud = vsh2_gm.hHUD;
    float jmp = player.GetPropFloat("flCharge");
    float rage = player.GetPropFloat("flRAGE");
    if( rage >= 100.0 ) {
        ShowSyncHudText(client, hud, "Jump: %i%% | Rage: FULL - Call Medic (default: E) to activate", player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(jmp) * 4);
    }
    else {
        ShowSyncHudText(client, hud, "Jump: %i%% | Rage: %0.1f", player.GetPropInt("bSuperCharge") ? 1000 : RoundFloat(jmp) * 4, rage);
    }
}

void HandleOnBossMedicCall(const VSH2Player player)
{
    if( !IsBossType(player, BossId) || player.GetPropFloat("flRAGE") < 100.0) {
        return;
    }

    /// use ConfigMap to set how large the rage radius is!
    float radius = 300.0; /// in case of failure, default value!
    BossConfig.GetFloat(VSH_DEFAULT_SELECTOR_RAGE_DISTANCE, radius);

    player.DoGenericStun(radius);
    VSH2Player[] players = new VSH2Player[MaxClients];
    int in_range = player.GetPlayersInRange(players, radius);
    for( int i; i < in_range; i++ ) {
        if( players[i].bIsBoss || players[i].bIsMinion ) {
            continue;
        }

        /// do a distance based thing here.
    }

    PlayRandomSoundFromConfigSelector(player, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_RAGE, VSH2_VOICE_RAGE);
    player.SetPropFloat("flRAGE", 0.0);
}

Action HandleOnBossDeath(const VSH2Player player) {
    int lives = player.GetPropInt("iLives") - 1;

    if(lives > 0){
        player.SetPropInt("iLives", lives);
        player.iHealth = player.GetPropInt("iMaxHealth");
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

void HandleOnBossRealDeath(const VSH2Player player) {
    if( !IsBossType(player, BossId)) {
        return;
    }

    PlayRandomSoundFromConfigSelector(player, BossConfig, VSH_DEFAULT_SELECTOR_SOUNDS_DEATH, VSH2_VOICE_LOSE);
}

Action HandleOnSoundHook(const VSH2Player player, char sample[PLATFORM_MAX_PATH], int& channel, float& volume, int& level, int& pitch, int& flags) {
    return VSH_DEFAULT_CODE_ON_SOUND_HOOK(player, BossId, sample);
}

// FIXME: make slowmotion feel good, it is very jittery for the client.
void EnableSlowMotion(const VSH2Player player) {
    if(isSlomoActive){
        return;
    }

    isSlomoActive = true;

    float timescale, slowmotionDuration;
    timescale = SLOMO_TIMESCALE;
    if(BossConfig.GetFloat(SELECTOR_SLOWMOTION_DURATION, slowmotionDuration) != 0) {
        LogMessage("used 0 characters for slowmotion duration get float, using default instead.");
        slowmotionDuration = DEFAULT_SLOWMOTION_DURATION;
    }

    player.PlayVoiceClip(SOUND_SLOWMOTION_START, VSH2_VOICE_RAGE);

    SetConVarFloat(cvar_TimeScale, timescale);

    // char sTimeScale[20];

    // cvar_TimeScale.GetString(sTimeScale, sizeof(sTimeScale));

    // for( int i=MaxClients; i; --i ) {
    //     if( !IsValidClient(i) ) {
    //         SetEntPropFloat(i, Prop_Send, PLAYER_PROPERTY_MAX_SPEED, GetEntPropFloat(i, Prop_Send,PLAYER_PROPERTY_MAX_SPEED) * SLOMO_TIMESCALE);
    //     }
    // }

    any args[1];
    args[0] = player;
    MakePawnTimer(DisableSlowMotion, timescale * slowmotionDuration, args, sizeof(args));
}

void DisableSlowMotion(const VSH2Player player) {
    if(!isSlomoActive){
        return;
    }

    isSlomoActive = false;

    ResetConVar(cvar_TimeScale, true, true);

    // // char sTimeScale[20];

    // // cvar_TimeScale.GetString(sTimeScale, sizeof(sTimeScale));

    // for( int i=MaxClients; i; --i ) {
    //     if( !IsValidClient(i) ) {
    //         SetEntPropFloat(i, Prop_Send, PLAYER_PROPERTY_MAX_SPEED, GetEntPropFloat(i, Prop_Send,PLAYER_PROPERTY_MAX_SPEED) * INVERSE_SLOMO);
    //     }
    // }
}

// public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
// {
//     if(!isSlomoActive) {
//         return Plugin_Continue;
//     }

//     char message[128];
//     FormatEx(message, sizeof(message), "original velocity for client %i is (%f, %f, %f)",client, velocity[0],velocity[1],velocity[2]);
//     LogMessage(message);

//     VSH2Player player =  VSH2Player(client);
//     float position[3];

//     GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
//     ScaleVector(velocity, SLOMO_TIMESCALE);

//     FormatEx(message, sizeof(message), "new velocity for client %i is (%f, %f, %f)",client, velocity[0],velocity[1],velocity[2]);
//     LogMessage(message);

//     TeleportEntity(client,NULL_VECTOR,NULL_VECTOR,velocity);

//     // if( !IsBossType(player, BossId)) {
//     //     return Plugin_Continue;
//     // }

//     // if(buttons & IN_ATTACK)
//     // {
//     //     FF2Flags[client]&=~FLAG_SLOWMOREADYCHANGE;
//     //     CreateTimer(FF2_GetArgF(boss, this_plugin_name, "rage_matrix_attack", "hidden1", 3, 0.2), Timer_SlowMoChange, boss, TIMER_FLAG_NO_MAPCHANGE);

//     //     float bossPosition[3], endPosition[3], eyeAngles[3];
//     //     GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
//     //     bossPosition[2]+=65;
//     //     GetClientEyeAngles(client, eyeAngles);

//     //     Handle trace=TR_TraceRayFilterEx(bossPosition, eyeAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf);
//     //     TR_GetEndPosition(endPosition, trace);
//     //     endPosition[2]+=100;
//     //     SubtractVectors(endPosition, bossPosition, velocity);
//     //     NormalizeVector(velocity, velocity);
//     //     ScaleVector(velocity, 2012.0);
//     //     TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
//     //     int target=TR_GetEntityIndex(trace);
//     //     if(target && target<=MaxClients)
//     //     {
//     //         Handle data;
//     //         CreateDataTimer(0.15, Timer_Rage_SlowMo_Attack, data);
//     //         WritePackCell(data, GetClientUserId(client));
//     //         WritePackCell(data, GetClientUserId(target));
//     //         ResetPack(data);
//     //     }
//     //     CloseHandle(trace);
//     // }
//     return Plugin_Continue;
// }