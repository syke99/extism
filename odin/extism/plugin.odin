package extism

import "core:bufio"
import "core:bytes"
import "core:c"
import "core:fmt"
import json "core:encoding/json"
import "core:mem"
import "core:os"
import "core:strings"

Plugin :: struct {
    ctx: ^Ctx,
    id: c.int32_t,
}

newPlugin :: proc (ctx: Ctx, module: os.Handle, wasi: bool) -> (Plugin, Err) {
    buf := make([dynamic]u8)
    defer delete(buf)

    er: Err = Err.Empty

    _, err := os.read_full(module, buf[:])
    if err != os.ERROR_NONE {
        p: Plugin = {}
        p.id = -1

        er = Err.ReadWasm

        return p, er
    }

    plg, e := register(ctx, buf[:], wasi)
    if e != .Empty {
        p: Plugin = {}
        p.id = -1

        er = e

        return p, er
    }

    return plg, er
}

updatePlugin :: proc (plg: ^Plugin, module: os.Handle, wasi: bool) -> (Plugin, Err) {
    buf := make([dynamic]u8)
    defer delete(buf)
    
    plg := plg
    er: Err

    _, err := os.read_full(module, buf[:])
    if err != os.ERROR_NONE {

        p: ^Plugin = {}
        p.id = -1

        plg = p

        return plg^, er
    }

    e := update(plg.ctx.ptr, ExtismPlugin(plg.id), buf[:], wasi)
    if e != .Empty {
    
        p: Plugin = {}
        p.id = -1

        er = e
        
        return plg^, er
    }

    return plg^, er
}

setPluginConfig :: proc(plg: ^Plugin, data: map[string][]u8) -> Err { 

    er: Err = Err.Empty

    dt, err := json.marshal(data)
	if err != nil {
    
        plg := plg

        p: ^Plugin = {}
        p.id = -1

        plg = p

        er = Err.Marshal

		return er
	}

    ptr := c.uchar(transmute(int)(uintptr(makePointer(dt))))

    extism_plugin_config(plg.ctx.ptr, ExtismPlugin(plg.id), &ptr, c.uint64_t(len(dt)))

    return er
}

pluginProcExists :: proc(plg: Plugin, procName: string) -> bool {
    name := strings.clone_to_cstring(procName, context.temp_allocator)
    b := extism_plugin_function_exists(plg.ctx.ptr, name)
    return bool(b)
}

/*TODO: implement body*/
callPluginProc :: proc(plg: ^Plugin, procName: string, input: []u8) -> ([]u8, Err) {
    ptr := c.uchar(transmute(int)(uintptr(makePointer(input))))
    name := strings.clone_to_cstring(procName, context.temp_allocator)

    rc := extism_plugin_call(plg.id, name, &ptr, c.uint64_t(len(input)))

    if rc != 0 {
        errMsg := extism_error(plg.ctx.ptr, c.int32_t(-1))
        msg := "Unknown"
        if errMsg != "" {
            msg = strings.clone_from_cstring(errMsg, context.temp_allocator)
        }

        plg := plg

        fmt.eprintf("error occured: %s", msg)
        
        p: ^Plugin = {}
        p.id = -1

        plg = p

        return []u8{}, Err.CallPlugin
    }

    length := extism_plugin_output_length(plg.ctx.ptr, ExtismPlugin(plg.id))

    if length > 0 {
        x := extism_plugin_output_data(plg.ctx.ptr, ExtismPlugin(plg.id))

        return mem.any_to_bytes(x), .Empty
    }

    return []u8{}, Err.Empty
}

freePlugin :: proc(plg: Plugin) {
    if plg.ctx.ptr == nil {
        return
    }
    extism_plugin_free(plg.ctx.ptr, plg.id)
    plg := plg
    plg.id = -1
}
