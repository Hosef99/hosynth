package hosynth

import "core:math"

Waveform :: enum {
    Sine     = 0,
    Square   = 1,
    Triangle = 2,
    Saw      = 3,
}

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

basic_waveform_display :: proc(waveform: Waveform, angle: f32) -> f32 {
    switch waveform {
    case .Sine:
        return sin(angle)
    case .Square:
        return square(angle)
    case .Triangle:
        return triangle(angle)
    case .Saw:
        return saw(angle)
    }
    return 0.0
}

basic_waveform :: proc(waveform: Waveform, angle: f32) -> f32 {
    switch waveform {
    case .Sine:
        return sin(angle)
    case .Square:
        return square(angle) * 0.25
    case .Triangle:
        return triangle(angle)
    case .Saw:
        return saw(angle) * 0.25
    }
    return 0.0
}
