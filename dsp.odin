package hosynth

import "core:math"

sin :: proc(angle: f32) -> f32 {
    return math.sin(angle)
}

square :: proc(angle: f32) -> f32 {
    angle := math.mod(angle, 2.0*math.PI)
    if angle < math.PI {
        return 1
    }
    return -1
}

triangle :: proc(angle: f32) -> f32 {
    angle := math.mod(angle, 2.0*math.PI)
    if angle < math.PI / 2.0 {
        return angle / (math.PI / 2.0)
    } else if angle < math.PI {
        return 1 - (angle - math.PI / 2.0) / (math.PI / 2.0)
    } else if angle < 3.0 * math.PI / 2.0 {
        return -(angle - math.PI) / (math.PI / 2.0)
    } else {
        return -(1 - (angle - 3.0 * math.PI / 2.0) / (math.PI / 2.0))
    }
}

saw :: proc(angle: f32) -> f32 {
    angle := math.mod(angle, 2.0*math.PI)
    if angle < math.PI {
        return angle / math.PI
    }
    return (angle - math.PI) / (math.PI) - 1
}

basic_waves := [4](proc(angle: f32) -> f32){sin, square, triangle, saw}
