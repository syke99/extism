package extism

import "core:c"
import "core:fmt"
import "core:strings"

/*
    Private procs:
        these procs are only used within the internals of this Host SDK
        and are not exposed
*/

@(private)
makePointer :: proc(data: []u8) -> rawptr {
    ptr: ^u8
    if len(data) > 0 {
        return rawptr(&data[0])
    }
    return nil
}

@(private)
register :: proc(ctx: Ctx, data: []u8, wasi: bool) -> (Plugin, Err) {
    ptr := c.uchar(transmute(int)(uintptr(makePointer(data))))
    plugin := extism_plugin_new(ctx.ptr, &ptr, c.uint64_t(len(data)), c.bool(wasi))

    p: Plugin = {}

    if plugin < 0 {
        errMsg := extism_error(ctx.ptr, c.int32_t(-1))
        msg := "Unknown"
        if errMsg != "" {
            msg = strings.clone_from_cstring(errMsg, context.temp_allocator)
        }

        p.ctx = nil
        p.id = -1

        fmt.eprintf("error occured: %s", msg)

        return p, .Register
    }

    p.id = i32(plugin)

    ctx := ctx

    p.ctx = &ctx

    return p, .Empty
}

@(private)
update :: proc(ctx: ^ExtismContext, plg: i32, data: []u8, wasi: bool) -> Err {
    ptr := c.uchar(transmute(int)(uintptr(makePointer(data))))
    b := bool(extism_plugin_update(ctx, c.int32_t(plg), &ptr, c.uint64_t(len(data)), c.bool(wasi)))

    if b {
        return .Empty
    }

    errMsg := extism_error(ctx, c.int32_t(-1))
    msg := "Unknown"
    if errMsg != "" {
        msg = strings.clone_from_cstring(errMsg, context.temp_allocator)
    }
    
    fmt.eprintf("error occured: %s", msg)
    
    return .Update
}
