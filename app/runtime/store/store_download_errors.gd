extends RefCounted
class_name StoreDownloadErrors

const OK := "ok"
const BUSY := "busy"
const CANCELLED := "cancelled"
const NETWORK := "network_error"
const HTTP := "http_error"
const INVALID_URL := "download_unavailable"
const TOO_LARGE := "download_too_large"
const CHECKSUM := "archive_checksum_mismatch"
const IO := "download_io_error"


static func user_message(code: String) -> String:
	return {
		NETWORK: "CHECK CONNECTION AND TRY AGAIN.",
		HTTP: "DOWNLOAD SERVER RETURNED AN ERROR.",
		INVALID_URL: "DOWNLOAD IS NOT AVAILABLE.",
		TOO_LARGE: "CARTRIDGE FILE IS TOO LARGE.",
		CHECKSUM: "THE FILE WAS NOT INSTALLED.",
		IO: "DOWNLOAD COULD NOT BE SAVED.",
		CANCELLED: "DOWNLOAD CANCELLED.",
	}.get(code, "DOWNLOAD FAILED.")
