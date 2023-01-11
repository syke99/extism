package extism

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
register :: proc(ctx: ^ExtismContext, data: []u8, wasi: bool) -> (Plugin, Error) {
    ptr: makePointer(data)
    plugin: extism_plugin_new(ctx.pointer, ^c.uchar(ptr), c.uint64_t(len(data)), c.bool(wasi))

    if plugin < 0 {
        errMsg := extism_error(ctx, c.int32_t(-1))
        msg: "Unknown"
        if errMsg != "" {
            msg = strings.clone_to_cstring(errMsg, context.temp_allocator)
        }
        // TODO: print errMsg to os.stderr
        return Plugin{id: -1}, .Register
    }

    return Plugin{
        id: i32(plugin)
        ctx: ctx
    }, .Empty
}

@(private)
update :: proc(ctx: ^ExtismContext, plg: i32, data: []u8, wasi: bool) -> Error {
    ptr: makePointer(data)
    b: bool(extism_plugin_update(ctx, c.int32_t(plg), ^c.uchar(ptr), c.uint64_t(len(data), c.bool(wasi))))

    if b {
        return .Empty
    }

    errMsg := extism_error(ctx, c.int32_t(-1))
    msg: "Unknown"
    if errMsg != "" {
        msg = strings.clone_to_cstring(errMsg, context.temp_allocator)
    }
    // TODO: print errMsg to os.stderr
    return .Update
}

@(private)
Value :: union {
    i64,
    f64,
    bool,
    string,
    []Value,
    map[string]Value,
}

@(private)
marshal :: proc(data: any, allocator := context.allocator) -> (Value, bool) {
    type_info := runtime.type_info_base(type_info_of(data.id));

    switch v in type_info.variant {
    case runtime.Type_Info_Integer:
        value: i64;

        switch type_info.size {
        case 8: value = (i64)((^i64)(data.data)^);
        case 4: value = (i64)((^i32)(data.data)^);
        case 2: value = (i64)((^i16)(data.data)^);
        case 1: value = (i64)((^i8) (data.data)^);
        }

        return value, true;

    case runtime.Type_Info_Float:
        value: f64;

        switch type_info.size {
        case 8: value = (f64)((^f64)(data.data)^);
        case 4: value = (f64)((^f32)(data.data)^);
        }

        return value, true;

    case runtime.Type_Info_String:
        return strings.clone(data.(string)), true;

    case runtime.Type_Info_Boolean:
        return data.(bool), true;

    case runtime.Type_Info_Enum:
        for val, i in v.values {
            #complete switch vv in val {
            case rune:    if vv == (^rune)   (data.data)^ do return strings.clone(v.names[i]), true;
            case i8:      if vv == (^i8)     (data.data)^ do return strings.clone(v.names[i]), true;
            case i16:     if vv == (^i16)    (data.data)^ do return strings.clone(v.names[i]), true;
            case i32:     if vv == (^i32)    (data.data)^ do return strings.clone(v.names[i]), true;
            case i64:     if vv == (^i64)    (data.data)^ do return strings.clone(v.names[i]), true;
            case int:     if vv == (^int)    (data.data)^ do return strings.clone(v.names[i]), true;
            case u8:      if vv == (^u8)     (data.data)^ do return strings.clone(v.names[i]), true;
            case u16:     if vv == (^u16)    (data.data)^ do return strings.clone(v.names[i]), true;
            case u32:     if vv == (^u32)    (data.data)^ do return strings.clone(v.names[i]), true;
            case u64:     if vv == (^u64)    (data.data)^ do return strings.clone(v.names[i]), true;
            case uint:    if vv == (^uint)   (data.data)^ do return strings.clone(v.names[i]), true;
            case uintptr: if vv == (^uintptr)(data.data)^ do return strings.clone(v.names[i]), true;
            }
        }

    case runtime.Type_Info_Array:
        array := make([dynamic]Value, 0, v.count, allocator);

        for i in 0..<v.count {
            if tmp, ok := marshal(any{rawptr(uintptr(data.data) + uintptr(v.elem_size*i)), v.elem.id}, allocator); ok {
                append(&array, tmp);
            } else {
                // @todo(bp): error
                return nil, false;
            }
        }
        
        return array[:], true;

    case runtime.Type_Info_Slice:
        a := cast(^mem.Raw_Slice) data.data;

        array := make([dynamic]Value, 0, a.len, allocator);

        for i in 0..<a.len {
            if tmp, ok := marshal(any{rawptr(uintptr(a.data) + uintptr(v.elem_size*i)), v.elem.id}, allocator); ok {
                append(&array, tmp);
            } else {
                // @todo(bp): error
                return nil, false;
            }
        }

        return array[:], true;

    case runtime.Type_Info_Dynamic_Array:
        a := cast(^mem.Raw_Dynamic_Array) data.data;

        array := make([dynamic]Value, 0, a.len, allocator);

        for i in 0..<a.len {
            if tmp, ok := marshal(transmute(any) any{rawptr(uintptr(a.data) + uintptr(v.elem_size*i)), v.elem.id}, allocator); ok {
                append(&array, tmp);
            } else {
                // @todo(bp): error
                return nil, false;
            }
        }

        return array[:], true;

    case runtime.Type_Info_Struct:
        object := make(map[string]Value, 16, allocator);

        for ti, i in v.types {
            if tmp, ok := marshal(any{rawptr(uintptr(data.data) + uintptr(v.offsets[i])), ti.id}, allocator); ok {
                object[strings.clone(v.names[i])] = tmp;
            } else {
                // @todo(bp): error
                return nil, false;
            }
        }

        return object, true;

    case runtime.Type_Info_Map:
        // @todo: implement. ask bill about this, maps are fucky
        return nil, false;
    }

    return nil, false;
}
