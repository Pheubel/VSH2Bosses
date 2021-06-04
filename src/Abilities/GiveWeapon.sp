#pragma semicolon 1

#include "include/ConfigBoss.inc"
#include "include/VSH2Utils.inc"
#include "include/VSH2Stocks.inc"

#define DEFAULT_MAX_AMMO 9

ConfigMap bossConfig;
ConfigMap chargeSection;
ConfigMap rageSection;
ConfigMap lifeLostSection;

public void OnPluginStart() {
    bossConfig = CloneBossConfigMap();
}

Register_Charge_Ability {
    if(!ConfigBossHookAbility(OnChargeAbility, GiveWeaponOnCharge)) {
        LogMessage("Could not hook on charge give weapon ability");
    }

    chargeSection = GetChargeAbilitySection(bossConfig);
}

Register_Rage_Ability {
    if(!ConfigBossHookAbility(OnRageAbility, GiveWeaponOnRage)) {
        LogMessage("Could not hook on rage give weapon ability");
    }

    rageSection = GetRageAbilitySection(bossConfig);

    PrintCfg(bossConfig);
    char nameBuffer[128];
    bossConfig.Get("name",nameBuffer,128);
    LogMessage("name of boss of boss config: %s",nameBuffer);
}

Register_On_Life_Lost_Ability {
    if(!ConfigBossHookAbility(OnRageAbility, GiveWeaponOnLifeLost)) {
        LogMessage("Could not hook on life lost give weapon ability");
    }

    lifeLostSection = GetOnLifeLostAbilitySection(bossConfig);
}

void GiveWeaponOnCharge(const VSH2Player bossPlayer) {
    GiveWeapon(bossPlayer, chargeSection);
}

void GiveWeaponOnRage(const VSH2Player bossPlayer) {
    GiveWeapon(bossPlayer, rageSection);
}

void GiveWeaponOnLifeLost(const VSH2Player bossPlayer) {
    GiveWeapon(bossPlayer, lifeLostSection);
}

void GiveWeapon(const VSH2Player bossPlayer, ConfigMap abilitySection) {
    bool parsedWeapon = true;

    int weaponClassLength = abilitySection.GetSize("weapon class");
    char[] weaponClassString = new char[weaponClassLength];
    if(abilitySection.Get("weapon class", weaponClassString, weaponClassLength) == 0) {
        int name_len = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_MENU_NAME);
        char[] name = new char[name_len];
        bossConfig.Get(VSH_DEFAULT_SELECTOR_MENU_NAME, name, name_len);
        LogMessage("(%s) Could not get weapon class from ability's \"weapon class\"", name);
        parsedWeapon = false;
    }

    int weaponId;
    if(abilitySection.GetInt("weapon id", weaponId) == 0) {
        int name_len = bossConfig.GetSize(VSH_DEFAULT_SELECTOR_MENU_NAME);
        char[] name = new char[name_len];
        bossConfig.Get(VSH_DEFAULT_SELECTOR_MENU_NAME, name, name_len);
        LogMessage("(%s) Could not get weapon ID from ability's \"weapon id\"", name);

        parsedWeapon = false;
    }

    if(!parsedWeapon) {
        return;
    }

    int attributeLength = abilitySection.GetSize("attribs");
    char[] attributeString = new char[attributeLength];
    abilitySection.Get("attribs", attributeString, attributeLength);

    int wep = bossPlayer.SpawnWeapon(weaponClassString, weaponId, 100, 5, attributeString);
    SetEntPropEnt(bossPlayer.index, Prop_Send, "m_hActiveWeapon", wep);

    int maxAmmo;
    if(abilitySection.GetInt("max ammo", maxAmmo)) {
        maxAmmo = DEFAULT_MAX_AMMO;
    }

    int living = GetLivingPlayers(VSH2Team_Red);
    SetWeaponClip(wep, 0);
    SetWeaponAmmo(wep, ((living >= maxAmmo) ? maxAmmo : living));
}