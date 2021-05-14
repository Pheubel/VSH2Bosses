#pragma semicolon 1

#include "include/ConfigBoss.inc"
#include "include/VSH2Utils.inc"

#define DEFAULT_CHARGE_TIME 3.0
#define DEFAULT_CHARGE_COOLDOWN -200.0

#define VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_ARGUMENTS_CHARGE_TIME "boss data.charge ability.charge time"
#define VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_ARGUMENTS_COOLDOWN "boss data.charge ability.cooldown"

ConfigMap bossConfig;

public void OnPluginStart() {
    if(!ConfigBossHookAbility(OnChargeAbility, Teleport)) {
        LogMessage("Could not hook on charge teleport ability");
    }

    bossConfig = CloneBossConfigMap();
}

void Teleport(const VSH2Player bossPlayer) {
    float chargeTime;
    if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_ARGUMENTS_CHARGE_TIME, chargeTime) == 0) {
        chargeTime = DEFAULT_CHARGE_TIME;
    }

    if(bossPlayer.SuperJumpThink(2.5/chargeTime, 25.0) && bossPlayer.GetPropFloat("flCharge") >= 25.0) {
        int target = GetRandomClient(_, VSH2Team_Red);

        if( target == -1 ) {
            return;
        }

        float currtime = GetGameTime();
        int flags = GetEntityFlags(bossPlayer.index);

        /// Chdata's HHH teleport rework
        if( TF2_GetPlayerClass(target) != TFClass_Scout && TF2_GetPlayerClass(target) != TFClass_Soldier ) {
            /// Makes HHH clipping go away for player and some projectiles
            SetEntProp(bossPlayer.index, Prop_Send, "m_CollisionGroup", 2);
            any args[1];
            args[0] = bossPlayer.index;
            MakePawnTimer(ResetCollission, 2.0, args, 1);
        }

        CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(bossPlayer.index, "ghost_appearation", _, false)));
        float pos[3]; GetClientAbsOrigin(target, pos);
        SetEntPropFloat(bossPlayer.index, Prop_Send, "m_flNextAttack", currtime+2);
        if( GetEntProp(target, Prop_Send, "m_bDucked") ) {
            float collisionvec[3] = {24.0, 24.0, 62.0};
            SetEntPropVector(bossPlayer.index, Prop_Send, "m_vecMaxs", collisionvec);
            SetEntProp(bossPlayer.index, Prop_Send, "m_bDucked", 1);
            SetEntityFlags(bossPlayer.index, flags|FL_DUCKING);

            any args[2];
            args[0] = bossPlayer.index;
            args[1] = target;
            MakePawnTimer(StunBoss, 0.2, args, 2);
        }
        else {
            TF2_StunPlayer(bossPlayer.index, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
        }

        TeleportEntity(bossPlayer.index, pos, NULL_VECTOR, NULL_VECTOR);
        SetEntProp(bossPlayer.index, Prop_Send, "m_bGlowEnabled", 0);
        CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(bossPlayer.index, "ghost_appearation")));
        CreateTimer(3.0, RemoveEnt, EntIndexToEntRef(AttachParticle(bossPlayer.index, "ghost_appearation", _, false)));

        /// Chdata's HHH teleport rework
        float vPos[3];
        GetEntPropVector(target, Prop_Send, "m_vecOrigin", vPos);

        EmitSoundToClient(bossPlayer.index, "misc/halloween/spell_teleport.wav");
        EmitSoundToClient(target, "misc/halloween/spell_teleport.wav");
        PrintCenterText(target, "You've been teleported!"); // doesnt seem to work

        float cooldown;
        if(bossConfig.GetFloat(VSH_DEFAULT_SELECTOR_CHARGE_ABILITY_ARGUMENTS_COOLDOWN, cooldown) == 0) {
            cooldown = DEFAULT_CHARGE_COOLDOWN;
        }

        bossPlayer.SetPropFloat("flCharge", cooldown);
    }
}

void StunBoss(const int user, int target)
{
    if( !IsValidClient(user) || !IsPlayerAlive(user) )
        return;
    if( !IsValidClient(target) || !IsPlayerAlive(target) )
        target = 0;
    TF2_StunPlayer(user, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, target);
}

void ResetCollission(int client) {
    SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
}

Action RemoveEnt(Handle timer, any entid)
{
	int ent = EntRefToEntIndex(entid);
	if( ent > 0 && IsValidEntity(ent) )
		AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}