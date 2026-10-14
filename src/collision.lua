local Collision = {}

function Collision.circleRect(rect, x, y, radius)
    local dx = x - math.max(rect.x, math.min(x, rect.x + rect.width))
    local dy = y - math.max(rect.y, math.min(y, rect.y + rect.height))
    return dx * dx + dy * dy <= radius * radius
end

function Collision.overlaps(a, b, inset)
    inset = inset or 0
    return a.x + a.width > b.x + inset and a.x < b.x + b.width - inset
        and a.y + a.height > b.y + inset and a.y < b.y + b.height - inset
end

return Collision
