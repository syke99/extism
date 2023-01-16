package extism

import "core:c"
import "core:encoding/json"

WasmData :: struct {
    data: []u8   `json:"data"`,
    hash: string `json:"hash,omitempty"`,
    name: string `json:"name,omitempty"`,
}

WasmFile :: struct {
    path: string `json:"path"`,
    hast: string `json:"hash,omitempty"`,
    name: string `json:"name,omitempty"`,
}

WasmUrl :: struct {
    url:     string            `json:"url"`,
    hash:    string            `json:"hash,omitempty"`,
    headers: map[string]string `json:"headers,omitempty"`,
    name:    string            `json:"name,omitempty"`,
    method:  string            `json:"method,omitempty"`,
}

Wasm :: union {
    WasmData,
    WasmFile,
    WasmUrl,
}

Memory :: struct {
    maxPages: u32 `json:"max_pages,omitempty"`,
}

Manifest :: struct {
    wasm:         []Wasm            `json:"wasm"`,
    memory:       Memory            `json:"memory,omitempty"`,
    config:       map[string]string `json:"config,omitempty"`,
    allowedHosts: []string          `json:"allowed_hosts,omitempty"`,
	allowedPaths: map[string]string `json:"allowed_paths,omitempty"`,
	timeout:      uint              `json:"timeout_ms,omitempty"`,
}

newPluginFromManifest :: proc(ctx: Ctx, manifest: Manifest, procs: []HostProc, wasi: bool) -> (Plugin, Err) {
    
    p: Plugin = {}

    data, err := json.marshal(manifest)
	if err != .Empty {

        p.ctx = nil
        p.id = -1

		return p, .MarshalManifest
	}

    plg, e := register(ctx, data, procs, wasi)
    if e != .Empty {

        p.ctx = nil
        p.id = -1

        return p, .RegisterManifest
    }

	return plg, .Empty
}

updateManifest :: proc(plg: Plugin, manifest: Manifest, procs: []HostProc, wasi: bool) -> Err {
	data, err := json.marshal(manifest)
	if err != nil {
		return .MarshalManifest
	}

    e := update(plg.ctx.ptr, plg.id, data, procs, wasi)
    if e != .Empty {
        plg := plg
        plg.id = c.int32_t(-1)
        return .UpdateManifest
    }

	return .Empty
}
