package extism

import "core:c"
import "core:strings"

when ODIN_OS == .Windows do foreign import extism "../extism.lib"
when ODIN_OS == .Linux  || ODIN_OS == .Darwin  do foreign import extism "../extism.a"

foreign extism {
    extism_context_new :: proc() -> ^ExtismContext ---
    extism_context_free :: proc(ctx: ^ExtismContext) ---
    extism_context_reset :: proc(ctx: ^ExtismContext) ---
    extism_current_plugin_memory :: proc(plg: ^ExtismCurrentPlugin) -> c.uint8_t ---
    extism_current_plugin_memory_alloc :: proc(plg: ^ExtismCurrentPlugin, n: ExtismSize) -> c.uint64_t ---
    extism_current_plugin_memory_length :: proc(plg: ^ExtismCurrentPlugin, n: ExtismSize) -> ExtismSize ---
    extism_current_plugin_memory_free :: proc(plg: ^ExtismCurrentPlugin, ptr: c.uint64_t) ---
    extism_function_new :: proc(name: cstring, inputs: ^ExtismValType, n_inputs: ExtismSize, outputs: ^ExtismValType, n_ouputs: ExtismSize, function: ExtismFunctionType, user_date: rawptr, free_user_data: Free_User_Data) -> ^ExtismFunction ---
    extism_function_free :: proc(ptr: ^ExtismFunction) ---
    extism_error :: proc(ctx: ^ExtismContext, plugin: ExtismPlugin) -> cstring ---
    extism_log_file :: proc(filename, level: cstring) -> c.bool ---
    extism_plugin_config :: proc(ctx: ^ExtismContext, plugin: ExtismPlugin, json: ^c.uint8_t, json_size: ExtismSize) -> c.bool ---
    extism_plugin_call :: proc(plg_id: ExtismPlugin, funcName: cstring, input: ^c.uint8_t, data_len: ExtismSize) -> c.int32_t ---
    extism_plugin_free :: proc(ctx: ^ExtismContext, index: ExtismPlugin) ---
    extism_plugin_function_exists :: proc(ctx: ^ExtismContext, plugin: ExtismPlugin, funcName: cstring) -> c.bool ---
    extism_plugin_new :: proc(ctx: ^ExtismContext, wasm: ^c.uint8_t, wasmSize: ExtismSize, functions: [^]ExtismFunction, n_functions: ExtismSize, with_wasi: bool) -> ExtismPlugin ---
    extism_plugin_output_length :: proc(ctx: ^ExtismContext, plugin: ExtismPlugin) -> ExtismSize ---
    extism_plugin_output_data :: proc(ctx: ^ExtismContext, plugin: ExtismPlugin) -> c.uint8_t ---
    extism_plugin_update :: proc(ctx: ^ExtismContext, plg_id: ExtismPlugin, wasm: ^c.uint8_t, wasmSize: ExtismSize, functions: [^]ExtismFunction, nfunctions: ExtismSize, with_wasi: bool) -> c.bool ---
    extism_version :: proc() -> cstring ---
}

ExtismPlugin :: c.int32_t;
ExtismSize :: c.uint64_t;

ExtismContext :: struct {}
ExtismFunction :: struct {}
ExtismCurrentPlugin :: struct {}

ExtismValUnion :: struct #raw_union {
    i32: c.int32_t,
    i64: c.int64_t,
    f32: c.float,
    f64: c.double,
}

ExtismVal :: struct {
    t: ExtismValType,
    v: ExtismValUnion,
}

ExtismValType :: enum i32 {
    // Signed 32 bit integer.
    I32 = 0,
    // Signed 64 bit integer.
    I64,
    // Floating point 32 bit integer.
    F32,
    // Floating point 64 bit integer.
    F64,
    // A 128 bit number.
    V128,
    // A reference to a Wasm function.
    FuncRef,
    // A reference to opaque data in the Wasm instance.
    ExternRef,
}

ExtismFunctionType :: #type proc(plg: ^ExtismCurrentPlugin, inputs: ^ExtismVal, n_inputs: ExtismSize, outputs: ^ExtismVal, n_outputs: ExtismSize, data: rawptr)
Free_User_Data :: #type proc(rawptr)

HostProc :: struct {
    pointer: ^ExtismFunction,
    user_data: any,
}

Err :: enum i32 {
    // an error occured reading the WASM module
    ReadWasm = 0,
    // generic marshaling error
    Marshal,
    // an error occured marshaling the config to JSON
    MarshalConfig,
    // an error occured marshaling the manifest to JSON
    MarshalManifest,
    // generic registering error
    Register,
    // an error occured registering plugin
    RegisterPlugin,
    // an error occured registering plugin from manifest
    RegisterManifest,
    // generic update error
    Update,
    // an error occured updating plugin
    UpdatePlugin,
    // an error occured updating manifest
    UpdateManifest,
    // an error occured calling plugin proc
    CallPlugin,
    Empty = -1,
}

extismVersion :: proc () -> string {
    return string(extism_version())
}

setLogFile :: proc(filename, level: string) -> bool {
    name := strings.clone_to_cstring(filename, context.temp_allocator)
    lvl := strings.clone_to_cstring(level, context.temp_allocator)
    r := extism_log_file(name, lvl)
    return bool(r)
}
