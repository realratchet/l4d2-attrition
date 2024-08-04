//-----------------------------------------------------
Msg("Activating Attrition mutation\n");

if ( !IsModelPrecached( "models/infected/hulk_dlc3.mdl" ) )
    PrecacheModel( "models/infected/hulk_dlc3.mdl" );

MutationState <-
{
    MolotovsSpawns = 2
    Tier2Spawns = 2
    MedkitSpawns = 2
    PillSpawns = 5
    PipeSpawns = 3
    IsFinale = false
    TankSpawnDelay = 0
    NextTankIsSpecial = false
}

function OnGameEvent_finale_start( params )
{
    SessionState.IsFinale = true
}

function OnGameEvent_gauntlet_finale_start( params )
{
    SessionState.IsFinale = true
}



//function OnGameEvent_tank_killed( params )
//{
//    MutationState.MolotovsSpawns = MutationState.MolotovsSpawns + 0.5;
//    MutationState.MedkitSpawns = MutationState.MedkitSpawns + 0.5;
//    Msg("ATTRITION: Tank spawned, bonus spawns.\n");
//}
//
//function OnGameEvent_witch_killed( params )
//{
//    MutationState.MolotovsSpawns = MutationState.MolotovsSpawns + 0.5;
//    MutationState.MedkitSpawns = MutationState.MedkitSpawns + 0.5;
//    Msg("ATTRITION: Tank spawned, bonus spawns.\n");
//}

if (!Director.IsSessionStartMap())
{
    function PlayerSpawnDeadAfterTransition(userid)
    {
        local player = GetPlayerFromUserID(userid);
        if (!player)
            return;

        player.SetHealth(10);
        player.SetHealthBuffer(40);
    }

    function OnGameEvent_player_transitioned(params)
    {
        local player = GetPlayerFromUserID(params["userid"]);
        if (!player || !player.IsSurvivor())
            return;

        if (NetProps.GetPropInt(player, "m_lifeState") == 2)
            EntFire("worldspawn", "RunScriptCode", "g_ModeScript.PlayerSpawnDeadAfterTransition(" + params["userid"] + ")", 0.03);
    }
}

function OnGameEvent_defibrillator_used(params)
{
    local player = GetPlayerFromUserID(params["subject"]);
    if (!player)
        return;

    player.SetHealth(1);
    player.SetHealthBuffer(49);
}

function OnGameEvent_survivor_rescued(params)
{
    local player = GetPlayerFromUserID(params["victim"]);
    if (!player)
        return;

    player.SetHealth(1);
    player.SetHealthBuffer(49);
}

function OnGameEvent_player_death(params)
{
    local victim = null
    local attacker = null
    local victimClass = null

    if ("userid" in params) victim = GetPlayerFromUserID(params["userid"]);
    else if ("entityid" in params) victim = EntIndexToHScript(params["entityid"]);

    if ("attacker" in params) attacker = GetPlayerFromUserID(params["attacker"]);
    else if ("attackerentid" in params) attacker = EntIndexToHScript(params["attackerentid"]);

    if (victim.GetClassname() != "infected")
    {
        if (victim.GetZombieType() != 9 && attacker != null && attacker.IsPlayer())
        {
            if (attacker != null && attacker.IsPlayer() && attacker.GetZombieType() == 9)
            {
                switch (victim.GetZombieType()) {
                    case 7: // witch
                        SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.5;
                        SessionState.PillSpawns = SessionState.PillSpawns + 1;
                        break;
                    case 8: // tank
                        SessionState.MolotovsSpawns = SessionState.MolotovsSpawns + 0.5;
                        SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.5;
                        SessionState.PillSpawns = SessionState.PillSpawns + 1;
                        break;
                    default: // si
                        SessionState.PillSpawns = SessionState.PillSpawns + 0.25;
                        SessionState.PipeSpawns = SessionState.PillSpawns + 0.5;
                        break;
                }
            }
        }
    }
}

function OnGameEvent_witch_spawn(params)
{
    local witch = EntIndexToHScript(params.witchid)
    local health = 0

    switch (Convars.GetStr("z_difficulty").tolower())
    {
        case "easy": health = 1000; break;
        case "normal": health = 1500; break;
        case "hard": health = 2000; break;
        case "impossible": health = 2500; break;
    }
    witch.SetMaxHealth(health)
    witch.SetHealth(health)
}

function OnGameEvent_tank_spawn(params)
{
    local tank = EntIndexToHScript(params.tankid)
    local health = 0
    switch (Convars.GetStr("z_difficulty").tolower())
    {
        case "easy": health = 10000; break;
        case "normal": health = 15000; break;
        case "hard": health = 20000; break;
        case "impossible": health = 30000;  break;
    }

    if(SessionState.NextTankIsSpecial) {
        SessionState.NextTankIsSpecial = false

        switch (Convars.GetStr("z_difficulty").tolower())
        {
            case "easy": health = 5000; break;
            case "normal": health = 10000; break;
            case "hard": health = 15000; break;
            case "impossible": health = 20000;  break;
        }

        tank.SetModel("models/infected/hulk_dlc3.mdl")
    }

    tank.SetMaxHealth(health)
    tank.SetHealth(health)

    if(SessionState.IsFinale && Time() > SessionState.TankSpawnDelay) {
        SessionState.NextTankIsSpecial = true
        SessionState.TankSpawnDelay = Time() + 2 // prevent filling server with tanks
        ZSpawn({ type = 8 })
    }
}

function OnGameEvent_spawner_give_item(params)
{
    local ent = EntIndexToHScript(params.spawner)
    // Msg(ent.GetClassname() + "\n");
    // Msg(CNetPropManager + "\n");
    // Msg(NetProps + "\n");
    // Msg(NetProps.HasProp(ent, "m_weaponID") + "\n");
    ent.Kill();
}

function OnGameEvent_triggered_car_alarm( params )
{
    ZSpawn({ type = 8 })
}

DirectorOptions <-
{
    ActiveChallenge = 1

    cm_SpecialRespawnInterval = 10
    SpecialInitialSpawnDelayMin = 10
    SpecialInitialSpawnDelayMax = 15
    ShouldAllowSpecialsWithTank = true

    HunterLimit = 4
    SmokerLimit = 3
    ChargerLimit = 1
    JockeyLimit = 1
    SpitterLimit = 1
    BoomerLimit = 1
    TankLimit = 3
    WitchLimit = 5
    WanderingZombieDensityModifier = 0.1
    CommonLimit = 50

    tier2weapons =
    {
        weapon_rifle = 1
        weapon_hunting_rifle = 1
        weapon_autoshotgun = 1
        weapon_rifle_spawn = 1
        weapon_hunting_rifle_spawn = 1
        weapon_autoshotgun_spawn = 1
    }

    // convert items that aren't useful
    weaponsToConvert =
    {
        weapon_vomitjar = "weapon_pipe_bomb"
        weapon_defibrillator = "weapon_first_aid_kit"
        weapon_pistol_magnum = "weapon_pistol"
        weapon_upgradepack_incendiary = "weapon_pain_pills"
        weapon_upgradepack_explosive = "weapon_pain_pills"
        weapon_adrenaline = "weapon_pain_pills"
        weapon_rifle_ak47 = "weapon_rifle"
        weapon_smg_silenced = "weapon_smg"
        weapon_shotgun_chrome = "weapon_pumpshotgun"
        weapon_rifle_desert = "weapon_rifle"
        weapon_sniper_military = "weapon_hunting_rifle"
        weapon_shotgun_spas = "weapon_autoshotgun"
    }

    function ConvertWeaponSpawn(classname)
    {
        if (classname in weaponsToConvert)
            return weaponsToConvert[classname];

        return 0;
    }

    weaponsToRemove =
    {
        weapon_grenade_launcher = 0
        weapon_smg_mp5 = 0
        weapon_rifle_sg552 = 0
        weapon_sniper_awp = 0
        weapon_sniper_scout = 0
        weapon_rifle_m60 = 0
        weapon_melee = 0
        weapon_chainsaw = 0
        weapon_pistol_magnum = 0
        weapon_smg_silenced = 0
        weapon_shotgun_chrome = 0
        weapon_vomitjar = 0
        weapon_rifle_ak47 = 0
        weapon_shotgun_spas = 0
        weapon_sniper_military = 0
        weapon_rifle_desert = 0
        weapon_upgradepack_explosive = 0
        weapon_upgradepack_incendiary = 0
    }

    function AllowWeaponSpawn(classname)
    {
        if (classname in weaponsToRemove)
            return false;

        if (classname.find("weapon_molotov") != null)
        {
            if (SessionState.MolotovsSpawns < 1)
                return false;

            SessionState.MolotovsSpawns = SessionState.MolotovsSpawns - 1;
        }

        if (classname.find("weapon_pipe_bomb") != null)
        {
            if (SessionState.PipeSpawns < 1)
                return false;

            SessionState.PipeSpawns = SessionState.PipeSpawns - 1;
        }

        if (classname.find("weapon_pain_pills") != null)
        {
            if (SessionState.PillSpawns < 1)
                return false;

            SessionState.PillSpawns = SessionState.PillSpawns - 1;
        }

        if (classname in tier2weapons)
        {
            if (SessionState.Tier2Spawns < 1)
                return false;

            SessionState.Tier2Spawns = SessionState.Tier2Spawns - 1;
        }

        if (classname.find("weapon_first_aid_kit") != null)
        {
            if (SessionState.MedkitSpawns < 1)
                return false;

            SessionState.MedkitSpawns = SessionState.MedkitSpawns - 1;
        }

        return true;
    }

    DefaultItems =
    [
        "pistol",
    ]

    function GetDefaultItem(idx)
    {
        if (idx < DefaultItems.len())
            return DefaultItems[idx];

        return 0;
    }
}
