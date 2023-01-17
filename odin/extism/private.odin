package extism

import "core:c"
import "core:fmt"
import "core:runtime"
import "core:slice"
import "core:strings"

/*
    Private procs:
        these procs are only used within the internals of this Host SDK
        and are not exposed
*/

@(private)
makePointer :: proc(data: []byte) -> rawptr {
    if len(data) > 0 {
        return rawptr(&data[0])
    }
    return nil
}

@(private)
makeProcPtrs :: proc(procs: []HostProc) -> [^]ExtismFunction {
    ptr_slice := make([]ExtismFunction, len(procs))
    
    ptrs: [^]ExtismFunction

    if len(procs) == 0 {
        return ptrs
    }

    for host_proc, i in procs {
        ptr_slice[i] = host_proc.pointer^
    }

    ptrs = slice.as_ptr(ptr_slice)

    return ptrs
}

@(private)
register :: proc(ctx: Ctx, data: []byte, procs: []HostProc, wasi: bool) -> (Plugin, Err) {
    ptr := c.uchar(transmute(int)(uintptr(makePointer(data))))

    proc_ptrs := makeProcPtrs(procs)

    plugin: ExtismPlugin

    if len(procs) == 0 {
        plugin = extism_plugin_new(ctx.ptr, &ptr, c.uint64_t(len(data)), nil, 0, c.bool(wasi))
    } else {
        plugin = extism_plugin_new(ctx.ptr, &ptr, c.uint64_t(len(data)), proc_ptrs, c.uint64_t(len(procs)), c.bool(wasi))
    }

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
update :: proc(ctx: ^ExtismContext, plg: i32, data: []u8, procs: []HostProc, wasi: bool) -> Err {
    ptr := c.uchar(transmute(int)(uintptr(makePointer(data))))

    proc_ptrs := makeProcPtrs(procs)

    if len(procs) == 0 {
        b := bool(extism_plugin_update(ctx, c.int32_t(plg), &ptr, c.uint64_t(len(data)), proc_ptrs, c.uint64_t(len(procs)), c.bool(wasi)))

        if b {
            return .Empty
        }
    } else {
        b := bool(extism_plugin_update(ctx, c.int32_t(plg), &ptr, c.uint64_t(len(data)), proc_ptrs, c.uint64_t(len(procs)), c.bool(wasi)))

        if b {
            return .Empty
        }
    }

    errMsg := extism_error(ctx, c.int32_t(-1))
    msg := "Unknown"
    if errMsg != "" {
        msg = strings.clone_from_cstring(errMsg, context.temp_allocator)
    }
    
    fmt.eprintf("error occured: %s", msg)
    
    return .Update
}
