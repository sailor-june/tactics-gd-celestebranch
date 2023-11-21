extends Node2D

@export var move_highlight = Color(0, 1.0, 0, 0.4)

var moving_player = null

# Called when the node enters the scene tree for the first time.
func _ready():
    print($Map.get_surrounding_cells(Vector2i(0, 0)))
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    pass

func _input(event):
    if event.is_action_pressed("exit"):
        get_tree().quit()

func highlight(coord: Vector2i, color: Color):
    var rect = ColorRect.new()
    rect.color = color
    rect.position.x = coord.x * 64
    rect.position.y = coord.y * 64
    rect.size = Vector2(64, 64)
    rect.gui_input.connect(self._on_highlight_input.bind(rect))
    $Highlights.add_child(rect)

func clear_highlight():
    for child in $Highlights.get_children():
        child.queue_free()

func highlight_move(mover: Node2D):
    clear_highlight()

    # BFS through neighboring cells, up to move cost
    var visited = {to_coord(mover.position): true}
    var q = [{coord = to_coord(mover.position), cost = 0}]
    while q.size() > 0:
        var cell = q.pop_front()
        highlight(cell.coord, move_highlight)
        for neigh in $Map.get_surrounding_cells(cell.coord):
            if neigh in visited:
                continue
            visited[neigh] = true
            var data = $Map.get_cell_tile_data(0, neigh)
            if data == null:
                # i.e. off the map
                continue
            # Bug: this isn't necessarily the min cost because the queue isn't
            # cost-sorted, and it won't be re-visited
            var cost = cell.cost + data.get_custom_data("travel_cost")
            if cost > mover.max_travel_cost:
                continue
            q.append({coord = neigh, cost = cost})

func to_coord(pixel: Vector2i):
    @warning_ignore("integer_division")
    return Vector2i(pixel.x / 64, pixel.y / 64)

func _on_player_clicked(player: Node2D):
    print("clicked player " + player.name)
    if player.has_moved:
        return
    moving_player = player
    highlight_move(player)

func _on_tank_clicked(tank: Node2D):
    print("clicked tank " + tank.name)

func _on_color_rect_gui_input(event):
    print("clicked highlight "+str(event))

func _on_highlight_input(event: InputEvent, rect: ColorRect):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT and moving_player:
            $UI/EndTurn.disabled = false
            moving_player.position = rect.position + Vector2(32, 32)
            moving_player.has_moved = true
        clear_highlight()

func _on_end_turn_pressed():
    print("End Turn")
    for child in self.get_children():
        if child is Player:
            child.has_moved = false
    $UI/EndTurn.disabled = true