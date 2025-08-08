state("ONAT") {
}

init {
    vars.NeedSetGSPointer = false;
    vars.GameStatePointer = 0;

    // For some reason, we can't do any of this when the game starts up.
    // Something about an object being null? IDC, lets just make this function to do it oncei n the update function.
    vars.SetupGameStatePointer = (Action)(()=> {
        vars.GameStatePointer = 0;
        var mainModule = modules.First();

        var scanner = new SignatureScanner(game, mainModule.BaseAddress, mainModule.ModuleMemorySize);

        // This signature closely matches the Audio struct at the beginning of ONAT's State variable. We look for this, then use this for the offset of any other variables we need.
        var target = new SigScanTarget(0, "00 00 ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ??");

        // returns all addresses which matched the target
        var results = scanner.ScanAll(target);

        // scans all of the game's memory pages to search for a successful scan
        foreach (var page in game.MemoryPages(false))
        {
            var _scanner = new SignatureScanner(game, page.BaseAddress, (int)(page.RegionSize));
            IntPtr result = _scanner.Scan(target);
            if (result != IntPtr.Zero){
                vars.GameStatePointer = result;
                vars.NeedSetGSPointer = true;
                break;
            }
        }
        print("State Pointer: 0x"+vars.GameStatePointer.ToString("X"));
    });
    vars.completedSplits = new HashSet<string>();

    vars.hour_values = new Dictionary<string, long>()
    {
        {"Hour1",116444736000000000},
        {"Hour2",116444738000000000},
        {"Hour3",116444740000000000},
        {"Hour4",116444760000000000},
        {"Hour5",116444780000000000}, 
        {"Hour6",116444800000000000},
        {"Hour7",116444820000000000},
    };
}

startup {
    settings.Add("Hour1", true, "12AM");
    settings.Add("Hour2", true, "1AM");
    settings.Add("Hour3", true, "2AM");
    settings.Add("Hour4", true, "3AM");
    settings.Add("Hour5", true, "4AM");
    settings.Add("Hour6", true, "5AM");
    settings.Add("Hour7", true, "6AM");
}
update {
    if(!vars.NeedSetGSPointer) {
        vars.SetupGameStatePointer();
        vars.NeedSetGSPointer = true;
    }
    vars.currentScreen = memory.ReadValue<byte>((IntPtr)(vars.GameStatePointer + 0x36E));
    vars.currentTime = memory.ReadValue<long>((IntPtr)(vars.GameStatePointer + 0x1F0));
    // print(vars.currentTime.ToString());
}

start {
    if(vars.currentScreen == 2) {
        return true;
    }
}

reset {
    if(vars.currentScreen == 0) {
        return true;
    }
}

split {
    foreach(var split in vars.hour_values) {
        if(!settings[split.Key] || 
           vars.completedSplits.Contains(split.Key) ){
            continue;
           }

        if(vars.currentTime >= split.Value) {
            vars.tempVar = 0;
            vars.completedSplits.Add(split.Key);
            print("[ONAT] Split triggered (" + split.Key + ")");
            return true;
        } else {
            return false;
        }
    }
    return false;
}