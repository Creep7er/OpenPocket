extends Node

signal logical_size_changed(size: Vector2i)

const LOGICAL_SIZE := Vector2i(400, 320)

var _viewport: SubViewport


func bind_viewport(viewport: SubViewport) -> void:
	_viewport = viewport
	if _viewport.size != LOGICAL_SIZE and not (_viewport.get_parent() is SubViewportContainer and (_viewport.get_parent() as SubViewportContainer).stretch):
		_viewport.size = LOGICAL_SIZE
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	logical_size_changed.emit(LOGICAL_SIZE)


func logical_size() -> Vector2i:
	return LOGICAL_SIZE


func viewport() -> SubViewport:
	return _viewport
