extends Node
class_name StoreDownloadJob

const Cache := preload("res://app/runtime/store/store_download_cache.gd")
const Errors := preload("res://app/runtime/store/store_download_errors.gd")

signal state_changed(snapshot: Dictionary)
signal finished(result: Dictionary)

const MAX_FILE_SIZE := 64 * 1024 * 1024
const ALLOWED_HOSTS: Array[String] = [
	"github.com",
	"objects.githubusercontent.com",
	"release-assets.githubusercontent.com",
]

var item: Dictionary = {}
var state := "queued"
var downloaded_bytes := 0
var total_bytes := 0
var _paths: Dictionary = {}
var _request: HTTPRequest
var _cancelled := false


func start(next_item: Dictionary) -> Dictionary:
	item = next_item.duplicate(true)
	var release := Dictionary(item.get("release", {}))
	var url := String(release.get("download_url", ""))
	if not _is_allowed_url(url):
		return _fail(Errors.INVALID_URL)
	var expected := String(release.get("sha256", "")).to_lower()
	if expected.length() != 64:
		return _fail(Errors.CHECKSUM)
	_paths = Cache.paths_for(item)
	Cache.cleanup(String(_paths["part"]))
	_request = HTTPRequest.new()
	_request.timeout = 20.0
	_request.max_redirects = 5
	_request.download_file = String(_paths["part"])
	_request.request_completed.connect(_on_completed)
	add_child(_request)
	_set_state("connecting")
	var error := _request.request(url, PackedStringArray(["Accept: application/octet-stream", "User-Agent: " + BrandConfig.USER_AGENT]), HTTPClient.METHOD_GET)
	if error != OK:
		return _fail(Errors.NETWORK)
	set_process(true)
	return {"ok": true, "pending": true, "error": "pending"}


func cancel() -> void:
	if state in ["completed", "failed", "cancelled"]:
		return
	_cancelled = true
	if _request != null:
		_request.cancel_request()
	Cache.cleanup(String(_paths.get("part", "")))
	_set_state("cancelled")
	finished.emit(_result(false, Errors.CANCELLED))


func snapshot() -> Dictionary:
	return {
		"state": state,
		"downloaded_bytes": downloaded_bytes,
		"total_bytes": total_bytes,
		"progress": float(downloaded_bytes) / float(total_bytes) if total_bytes > 0 else 0.0,
		"item": item.duplicate(true),
	}


func _process(_delta: float) -> void:
	if _request == null or state in ["completed", "failed", "cancelled"]:
		set_process(false)
		return
	downloaded_bytes = _request.get_downloaded_bytes()
	total_bytes = _request.get_body_size()
	if downloaded_bytes > MAX_FILE_SIZE or total_bytes > MAX_FILE_SIZE:
		_request.cancel_request()
		Cache.cleanup(String(_paths.get("part", "")))
		_fail(Errors.TOO_LARGE)
		return
	if downloaded_bytes > 0 and state != "downloading":
		_set_state("downloading")
	else:
		state_changed.emit(snapshot())


func _on_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	set_process(false)
	if _cancelled:
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail(Errors.NETWORK)
		return
	if response_code < 200 or response_code >= 300:
		_fail(Errors.HTTP)
		return
	var part_path := String(_paths["part"])
	if not FileAccess.file_exists(part_path):
		_fail(Errors.IO)
		return
	var file := FileAccess.open(part_path, FileAccess.READ)
	if file == null or file.get_length() > MAX_FILE_SIZE:
		_fail(Errors.TOO_LARGE)
		return
	_set_state("verifying")
	var expected := String(Dictionary(item.get("release", {})).get("sha256", "")).to_lower()
	if FileAccess.get_sha256(part_path).to_lower() != expected:
		_fail(Errors.CHECKSUM)
		return
	var final_path := String(_paths["final"])
	if not Cache.commit(part_path, final_path):
		_fail(Errors.IO)
		return
	_set_state("ready")
	finished.emit({"ok": true, "error": Errors.OK, "path": final_path, "item": item.duplicate(true)})


func _is_allowed_url(url: String) -> bool:
	if not url.begins_with("https://") or "@" in url:
		return false
	var host := url.trim_prefix("https://").get_slice("/", 0).get_slice(":", 0).to_lower()
	return host in ALLOWED_HOSTS


func _set_state(next_state: String) -> void:
	state = next_state
	state_changed.emit(snapshot())


func _fail(code: String) -> Dictionary:
	Cache.cleanup(String(_paths.get("part", "")))
	_set_state("failed")
	var result := _result(false, code)
	finished.emit(result)
	return result


func _result(ok: bool, error: String) -> Dictionary:
	return {"ok": ok, "error": error, "path": "", "item": item.duplicate(true)}
