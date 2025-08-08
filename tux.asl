state("ONAT") {
    byte currentScreen : 0x0127E160;
}

init {
    vars.NeedSetGSPointer = false;
    vars.GameStatePointer = -1;

    vars.SetupGameStatePointer = (Action)(()=> {
        vars.GameStatePointer = 0;
        var mainModule = modules.First();

        print("module name: "+mainModule.ModuleName);

        var scanner = new SignatureScanner(game, mainModule.BaseAddress, mainModule.ModuleMemorySize);

        // This signature closely matches the Audio struct at the beginning of ONAT's State variable. We look for this, then use this for the offset of any other variables we need.
        var target = new SigScanTarget(0, "00 00 00 00 00 00 00 00 00 00 ?? ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ?? DC ?? ?? ?? ?? ?? ?? ??");

        // returns all addresses which matched the target
        var results = scanner.ScanAll(target);

        // scans all of the game's memory pages to search for a successful scan
        foreach (var page in game.MemoryPages(false))
        {
            var _scanner = new SignatureScanner(game, page.BaseAddress, (int)(page.RegionSize));
            IntPtr result = _scanner.Scan(target);
            if (result != IntPtr.Zero){
                vars.GameStatePointer = result;
                break;
            }
        }
        print(vars.GameStatePointer.ToString("X"));
    });
}
update {
    if(!vars.NeedSetGSPointer) {
        vars.SetupGameStatePointer();
        vars.NeedSetGSPointer = true;
    }
    vars.currentScreen = memory.ReadValue<byte>((IntPtr)(vars.GameStatePointer + 0x36E));
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