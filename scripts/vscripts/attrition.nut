//-----------------------------------------------------
Msg("Activating Attrition mutation\n");

if ( !IsModelPrecached( "models/infected/hulk_dlc3.mdl" ) )
    PrecacheModel( "models/infected/hulk_dlc3.mdl" );

if ( !IsModelPrecached( "models/infected/witch_bride.mdl" ) )
    PrecacheModel( "models/infected/witch_bride.mdl" );

function OnGameEvent_player_first_spawn(params)
{
    local player = GetPlayerFromUserID(params["userid"])

    if (player == null || !player.IsPlayer() || player.GetZombieType() == 9)
        return

    switch(player.GetZombieType())
    {
        case 8: SpawnTankItems(player); break;
        case 7: break; // witch (not really called by this event but w/e)
        case 11: break; // bride witch (not really called by this event but w/e)
        default: SpawnSpecialItems(player);
    }
}

function SpawnTankItems(infected)
{
    if(SessionState.PillSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pain_pills", infected)
        SessionState.PillSpawns = SessionState.PillSpawns - 1
    }

    if(RandomInt(1, 10) > 9) { // spawn nothing
        // Msg("------------------------------\n")
        // Msg("ATTRITION STATE\n")
        // Msg("------------------------------\n")
        // Msg("MolotovsSpawns: " + SessionState.MolotovsSpawns + "\n")
        // Msg("MedkitSpawns: " + SessionState.MedkitSpawns + "\n")
        // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
        // Msg("------------------------------\n")
        return
    }


    if(RandomInt(0, 3) <= 1 && SessionState.MolotovsSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_molotov", infected)
        SessionState.MolotovsSpawns = SessionState.MolotovsSpawns - 1
    } else if(SessionState.MedkitSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_first_aid_kit", infected)
        SessionState.MedkitSpawns = SessionState.MedkitSpawns - 1
    }

    // Msg("------------------------------\n")
    // Msg("ATTRITION STATE\n")
    // Msg("------------------------------\n")
    // Msg("MolotovsSpawns: " + SessionState.MolotovsSpawns + "\n")
    // Msg("MedkitSpawns: " + SessionState.MedkitSpawns + "\n")
    // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
    // Msg("------------------------------\n")
}

function SpawnWitchItems(infected)
{
    if(SessionState.PillSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pain_pills", infected)
        SessionState.PillSpawns = SessionState.PillSpawns - 1
    }

    // Msg("------------------------------\n")
    // Msg("ATTRITION STATE\n")
    // Msg("------------------------------\n")
    // Msg("MedkitSpawns: " + SessionState.MedkitSpawns + "\n")
    // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
    // Msg("------------------------------\n")
}

function SpawnOnPointOrInfected(classname, infected)
{
    local container
    switch(classname)
    {
        case "weapon_pain_pills": container = ValidSpawns.pills; break;
        case "weapon_first_aid_kit": container = ValidSpawns.medkits; break;
        case "weapon_pipe_bomb": container = ValidSpawns.pipes; break;
        case "weapon_molotov": container = ValidSpawns.molotovs; break;
        default:
            Msg("[ATTRITION] Error cannot spawn " + classname + "\n")
            return;
    }

    // Msg("[ATTRITION] Spawning reward: " + classname + "\n")

    if(!SpawnOnPoint(container, classname)) {
        local spawnTable = {
            origin = infected.GetOrigin(),
            angles = infected.GetAngles().ToKVString()
        }

        SpawnEntityFromTable(classname, spawnTable)
        // Msg("[ATTRITION] No more free spawnpoints left '" + classname + "' spawned on infected instead.\n")
    }
}

function SpawnSpecialItems(infected)
{
    if(RandomInt(0, 2) <= 1) { // spawn nothing
        // Msg("------------------------------\n")
        // Msg("ATTRITION STATE\n")
        // Msg("------------------------------\n")
        // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
        // Msg("PipeSpawns: " + SessionState.PipeSpawns + "\n")
        // Msg("------------------------------\n")
        return
    }

    if(RandomInt(0, 2) <= 1 && SessionState.PipeSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pipe_bomb", infected)
        SessionState.PipeSpawns = SessionState.PipeSpawns - 1
    } else if(SessionState.PillSpawns >= 1) {
        SpawnOnPointOrInfected("weapon_pain_pills", infected)
        SessionState.PillSpawns = SessionState.PillSpawns - 1
    }

    // Msg("------------------------------\n")
    // Msg("ATTRITION STATE\n")
    // Msg("------------------------------\n")
    // Msg("PillSpawns: " + SessionState.PillSpawns + "\n")
    // Msg("PipeSpawns: " + SessionState.PipeSpawns + "\n")
    // Msg("------------------------------\n")
}

function OnGameEvent_finale_start( params )
{
    SessionState.IsFinale = true
}

function OnGameEvent_gauntlet_finale_start( params )
{
    SessionState.IsFinale = true
}

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

function OnTankDeath(infected)
{
    SessionState.MolotovsSpawns = SessionState.MolotovsSpawns + 0.5
    SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.5
    SessionState.PillSpawns = SessionState.PillSpawns + 1

    local spawnTable = { origin = infected.GetOrigin(), angles = infected.GetAngles().ToKVString() }

    if(!SessionState.IsFinale && RandomInt(1, 10) <= 5)
        ZSpawn({ type = 11 })

    SpawnTankItems(infected) // tank lets you double dip
}

function OnWitchDeath(infected)
{
    SessionState.MedkitSpawns = SessionState.MedkitSpawns + 0.5
    SessionState.PillSpawns = SessionState.PillSpawns + 1

    SpawnWitchItems(infected)
}

function OnSpecialDeath(infected)
{
    SessionState.PillSpawns = SessionState.PillSpawns + 0.25
    SessionState.PipeSpawns = SessionState.PipeSpawns + 0.5
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
        if (victim.GetClassname() == "witch" || victim.GetZombieType() != 9 && attacker != null && attacker.IsPlayer())
        {
            if (attacker != null && attacker.GetZombieType() == 9)
            {
                if(victim.GetClassname() == "witch")
                    OnWitchDeath(victim)
                else {
                    switch (victim.GetZombieType()) {
                        case 8: // tank
                            OnTankDeath(victim)
                            break;
                        case 7: break
                        case 11: break
                        default: // si
                            OnSpecialDeath(victim)
                            break;
                    }
                }
            }
        }
    }
}

// function OnGameEvent_witch_spawn(params)
// {
//     local witch = EntIndexToHScript(params.witchid)
//     local health = 0

//     switch (Convars.GetStr("z_difficulty").tolower())
//     {
//         case "easy": health = 1000; break;
//         case "normal": health = 1500; break;
//         case "hard": health = 2000; break;
//         case "impossible": health = 2500; break;
//     }
//     witch.SetMaxHealth(health)
//     witch.SetHealth(health)
// }

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

ValidSpawns <-
{
    molotovs = [],
    pipes = [],
    pills = [],
    medkits = [],
    tanks = []
}

function AddSpawn(container, ent)
{
    local flow = GetFlowDistanceForPosition(ent.GetOrigin())
    local spawnpoint = {
        flow = flow,
        used = false,
        spawnTable = {
            origin = ent.GetOrigin(),
            angles = ent.GetAngles().ToKVString()
        }
    }

    container.append(spawnpoint)
}

function SpawnOnPoint(container, classname)
{
    local validFlows = []
    local minFlow = Director.GetFurthestSurvivorFlow()

    foreach(sp in container)
    {
        if(sp.used || sp.flow < minFlow) continue

        validFlows.append(sp)
    }

    local validSpawnsLen = validFlows.len()

    if(validSpawnsLen == 0) return false

    local spawnpoint = validFlows[RandomInt(0, validSpawnsLen - 1)]

    SpawnEntityFromTable(classname, spawnpoint.spawnTable)
    spawnpoint.used = true

    return true
}

MobSpawns <-
{
    tanks = []
}

function FillTankSpawns()
{
    local tankSpawns = 2

    if(RandomInt(1, 3) > 3)
        tankSpawns = 3  # chance for three tanks

    for (local i = 0; i < tankSpawns; i = i + 1)
        MobSpawns.tanks.append({ flow = 25 * (i + 1) + RandomInt(-10, 10), used = false })
}

function TickTankSupport()
{
    if(Director.IsTankInPlay())
    {
        DirectorOptions.CommonLimit = 20
        DirectorOptions.MobMinSize = 10
        DirectorOptions.MobMaxSize = 20
        // Msg("[ATTRITION] Reducing number of commons\n")
    }
    else
    {
        DirectorOptions.CommonLimit = 50
        DirectorOptions.MobMinSize = 25
        DirectorOptions.MobMaxSize = 50
        // Msg("[ATTRITION] Restoring number of commons\n")
    }
}

function TickTankFlow()
{
    if(SessionState.IsFinale) // no extra tanks during finale
        return

    local flow = (Director.GetFurthestSurvivorFlow() / GetMaxFlowDistance()) * 100

    // Msg("[ATTRITION] Current flow " + flow + "\n")
    foreach(sp in MobSpawns.tanks)
    {
        // Msg("[ATTRITION] Tank spawn @ " + sp.flow + " | used: " + sp.used + "\n")
        if(sp.used || sp.flow > flow) continue

        ZSpawn({ type = 8 })
        sp.used = true
    }
}

function Update()
{
    TickTankSupport()
    TickTankFlow()


}

function OnGameEvent_round_start_post_nav(params) {
    SessionState.MolotovsSpawns = SessionState.MolotovsSpawns
    SessionState.Tier2Spawns = SessionState.Tier2Spawns
    SessionState.MedkitSpawns = SessionState.MedkitSpawns
    SessionState.PillSpawns = SessionState.PillSpawns
    SessionState.PipeSpawns = SessionState.PipeSpawns

    local ent = null

    FillTankSpawns()

    foreach(classname in ["weapon_molotov", "weapon_molotov_spawn"])
        while (ent = Entities.FindByClassname(ent, classname))
        {
            if (SessionState.MolotovsSpawns < 1) {
                AddSpawn(ValidSpawns.molotovs, ent)
                ent.Kill()
                continue
            }

            // Msg("[ATTRITION] MolotovsSpawns: " + SessionState.MolotovsSpawns + "\n")
            SessionState.MolotovsSpawns = SessionState.MolotovsSpawns - 1;
        }

    foreach(classname in ["weapon_pipe_bomb", "weapon_pipe_bomb_spawn"])
        while (ent = Entities.FindByClassname(ent, classname))
        {
            if (SessionState.PipeSpawns < 1) {
                AddSpawn(ValidSpawns.pipes, ent)
                ent.Kill()
                continue
            }

            // Msg("[ATTRITION] PipeSpawns: " + SessionState.PipeSpawns + "\n")
            SessionState.PipeSpawns = SessionState.PipeSpawns - 1;
        }

    foreach(classname in ["weapon_pain_pills", "weapon_pain_pills_spawn"])
        while (ent = Entities.FindByClassname(ent, classname))
            {
                if (SessionState.PillSpawns < 1) {
                    AddSpawn(ValidSpawns.pills, ent)
                    ent.Kill()
                    continue
                }

                // Msg("[ATTRITION] PillSpawns: " + SessionState.PillSpawns + "\n")
                SessionState.PillSpawns = SessionState.PillSpawns - 1;
            }

    foreach(classname in DirectorOptions.weaponsTier2)
        while (ent = Entities.FindByClassname(ent, classname))
        {
            if (SessionState.Tier2Spawns < 1) {
                ent.Kill()
                continue
            }

            // Msg("[ATTRITION] Tier2Spawns: " + SessionState.Tier2Spawns + "\n")
            SessionState.Tier2Spawns = SessionState.Tier2Spawns - 1
        }

    while (ent = Entities.FindByClassname(ent, "weapon_spawn"))
    {
       if (!DirectorOptions.weaponsTier2.find(NetProps.GetPropString( ent, "m_iszWeaponToSpawn" )))
            continue;

        if (SessionState.Tier2Spawns < 1) {
            ent.Kill()
            continue
        }

        // Msg("[ATTRITION] Tier2Spawns: " + SessionState.Tier2Spawns + "\n")
        SessionState.Tier2Spawns = SessionState.Tier2Spawns - 1
    }

    foreach(classname in ["weapon_first_aid_kit", "weapon_first_aid_kit_spawn"])
        while (ent = Entities.FindByClassname(ent, classname))
        {
            if (SessionState.MedkitSpawns < 1) {
                AddSpawn(ValidSpawns.medkits, ent)
                ent.Kill()
                continue
            }

            // Msg("[ATTRITION] MedkitSpawns: " + SessionState.MedkitSpawns + "\n")
            SessionState.MedkitSpawns = SessionState.MedkitSpawns - 1
        }
}

DirectorOptions <-
{
    ActiveChallenge = 1

    SpecialRespawnInterval = 10
    SpecialInitialSpawnDelayMin = 10
    SpecialInitialSpawnDelayMax = 15
    ShouldAllowSpecialsWithTank = true

    DisallowThreatType = ZOMBIE_TANK

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
    MobMinSize = 25
    MobMaxSize = 50

    weaponsTier2 = [
        "weapon_rifle",
        "weapon_hunting_rifle",
        "weapon_autoshotgun",
        "weapon_sniper_military",
        "weapon_shotgun_spas",
        "weapon_rifle_ak47",
        "weapon_rifle_desert",
        "tier2_any",
        "tier2_shotgun",
        "any_rifle",
        "any_sniper_rifle"
    ]

    // convert items that aren't useful
    weaponsToConvert =
    {
        weapon_vomitjar = "weapon_pipe_bomb"
        weapon_defibrillator = "weapon_first_aid_kit"
        weapon_pistol_magnum = "weapon_pistol"
        weapon_upgradepack_incendiary = "weapon_pain_pills"
        weapon_upgradepack_explosive = "weapon_pain_pills"
        weapon_adrenaline = "weapon_pain_pills"
        // weapon_rifle_ak47 = "weapon_rifle"
        // weapon_smg_silenced = "weapon_smg"
        // weapon_shotgun_chrome = "weapon_pumpshotgun"
        // weapon_rifle_desert = "weapon_rifle"
        // weapon_sniper_military = "weapon_hunting_rifle"
        // weapon_shotgun_spas = "weapon_autoshotgun"
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
        // weapon_smg_silenced = 0
        // weapon_shotgun_chrome = 0
        weapon_vomitjar = 0
        // weapon_rifle_ak47 = 0
        // weapon_shotgun_spas = 0
        // weapon_sniper_military = 0
        // weapon_rifle_desert = 0
        // weapon_upgradepack_explosive = 0
        // weapon_upgradepack_incendiary = 0
    }

    function AllowWeaponSpawn(classname)
    {
        if (classname in weaponsToRemove)
            return false;

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
