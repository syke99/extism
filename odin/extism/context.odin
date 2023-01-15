package extism

import "core:c"

Ctx :: struct {
    ptr: ^ExtismContext,
}

newContex :: proc() -> Ctx {
    ctx: Ctx = {}
    ctx.ptr = extism_context_new()
    return ctx
}

freeContex :: proc(ctx: ^Ctx) {
    extism_context_free(ctx.ptr)
    ctx := ctx
    ctx.ptr = nil
}

resetContext :: proc(ctx: Ctx) {
    extism_context_reset(ctx.ptr)
}
