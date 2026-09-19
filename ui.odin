package hosynth

import "core:math"
import rl "vendor:raylib"

Slider :: struct {
    rect: rl.Rectangle,
    val: f32, // 0 to 1
    default: f32,
    active: bool,
}

slider_draw_h :: proc(slider: Slider) {
    rect := slider.rect
    rect.width = rect.width * slider.val
    rl.DrawRectangleRec(rect, rl.WHITE)
    rl.DrawRectangleLinesEx(slider.rect, 3, rl.LIGHTGRAY)
}

slider_draw_v :: proc(slider: Slider) {
    rect := slider.rect

    rect.height = rect.height * slider.val
    rect.y += slider.rect.height - rect.height

    rl.DrawRectangleRec(rect, rl.WHITE)
    rl.DrawRectangleLinesEx(slider.rect, 3, rl.LIGHTGRAY)
}

slider_update_h :: proc(slider: ^Slider, mouse: rl.Vector2) {
    rect := slider.rect
    if rl.CheckCollisionPointRec(mouse, rect) && rl.IsMouseButtonPressed(.LEFT) {
        slider.active = true
    } else if rl.IsMouseButtonReleased(.LEFT) {
        slider.active = false
    }

    if slider.active {
        pos := math.clamp(mouse.x, f32(rect.x), f32(rect.x + rect.width)) - rect.x
        slider.val = pos / f32(rect.width)
    }

    if rl.CheckCollisionPointRec(mouse, rect) && rl.IsMouseButtonPressed(.RIGHT) {
        slider.val = slider.default
    }
}

slider_update_v :: proc(slider: ^Slider, mouse: rl.Vector2) {
    rect := slider.rect
    if rl.CheckCollisionPointRec(mouse, rect) && rl.IsMouseButtonPressed(.LEFT) {
        slider.active = true
    } else if rl.IsMouseButtonReleased(.LEFT) {
        slider.active = false
    }

    if slider.active {
        pos := math.clamp(mouse.y, f32(rect.y), f32(rect.y + rect.height)) - rect.y
        slider.val = 1 - (pos / f32(rect.height))
    }

    if rl.CheckCollisionPointRec(mouse, rect) && rl.IsMouseButtonPressed(.RIGHT) {
        slider.val = slider.default
    }
}

slider_float :: proc(slider: Slider, min, max: f32) -> f32 {
    return min + slider.val * (max - min)
}

slider_int :: proc(slider: Slider, min, max: int) -> int {
    return min + int(math.round(slider.val * f32(max-min)))
}

slider_steps :: proc(slider: Slider, values: []f32) -> f32 {
    index := int(math.round(slider.val * f32(len(values) - 1)))

    return values[index]
}

slider_exp :: proc(slider: Slider, min, max, exp: f32) -> f32 {
    return (max - min) * math.pow(slider.val, exp) + min
}

slider_inv_exp :: proc(val, min, max, exp: f32) -> f32 {
    return math.pow((val - min) / (max - min), 1.0 / exp)
}

sin_rect := rl.Rectangle{10, 115, 50, 30}
square_rect := rl.Rectangle{10+50, 115, 50, 30}
triangle_rect := rl.Rectangle{10+100, 115, 50, 30}
saw_rect := rl.Rectangle{10+150, 115, 50, 30}

basic_wave_rects := [4]rl.Rectangle{sin_rect, square_rect, triangle_rect, saw_rect}

unison_slider := Slider{
    rect = {10, 190, 200, 20},
    val = 0.2,
    default = 0,
}

detune_slider := Slider{
    rect = {10, 250, 200, 20},
    val = 0.2,
    default = 0,
}

octave_slider := Slider{
    rect = {10, 310, 200, 20},
    val = 0.5,
    default = 0.5,
}

semitone_slider := Slider{
    rect = {10, 370, 200, 20},
    val = 0.5,
    default = 0.5,
}

phase_slider := Slider{
    rect = {10, 430, 200, 20},
    val = 0.0,
    default = 0.0,
}

level_slider := Slider{
    rect = {10, 490, 200, 20},
    val = 1.0,
    default = 1.0,
}

h_sliders := [?]^Slider{
    &unison_slider,
    &detune_slider,
    &octave_slider,
    &semitone_slider,
    &phase_slider,
    &level_slider,
}

osc1_level_slider := Slider{
    rect = {230, 45, 30, 100},
    val = 1.0,
    default = 1.0,
}

osc2_level_slider := Slider{
    rect = {270, 45, 30, 100},
    val = 1.0,
    default = 1.0,
}

osc3_level_slider := Slider{
    rect = {310, 45, 30, 100},
    val = 1.0,
    default = 1.0,
}

osc_level_sliders := [3]^Slider{
    &osc1_level_slider,
    &osc2_level_slider,
    &osc3_level_slider,
}

gain_level_slider := Slider{
    rect = {350, 15, 60, 130},
    val = 0.3,
    default = 0.3,
}

/*
A: 10 - 3000 ms
D: 10 - 3000 ms
S: 0 - 1
R: 10 - 10000 ms

A, D, and R sliders should be exponential
*/

a_slider := Slider{
    rect = {440, 45, 30, 100},
    val = 0.3,
    default = 0.3
}

d_slider := Slider{
    rect = {480, 45, 30, 100},
    val = 0.3,
    default = 0.3
}

s_slider := Slider{
    rect = {520, 45, 30, 100},
    val = 0.3,
    default = 0.3
}

r_slider := Slider{
    rect = {560, 45, 30, 100},
    val = 0.3,
    default = 0.3
}

adsr_sliders := [4]^Slider{&a_slider, &d_slider, &s_slider, &r_slider}

osc1_rect := rl.Rectangle{10, 550, 67, 30}
osc2_rect := rl.Rectangle{10 + 67, 550, 66, 30}
osc3_rect := rl.Rectangle{10 + 67 + 66, 550, 67, 30}
osc_rects := [3]rl.Rectangle{osc1_rect, osc2_rect, osc3_rect}

osc1_mute_rect := rl.Rectangle{230, 15, 30, 20}
osc2_mute_rect := rl.Rectangle{270, 15, 30, 20}
osc3_mute_rect := rl.Rectangle{310, 15, 30, 20}

osc_mute_rects := [3]rl.Rectangle{
    osc1_mute_rect,
    osc2_mute_rect,
    osc3_mute_rect,
}

set_ui_to_osc :: proc(synth: Synth, index: int) {
    unison_slider.val = f32(synth.oscs[index].unison.voices - 1) / 10.0
    detune_slider.val = synth.oscs[index].unison.detune / 50.0
    octave_slider.val = (synth.oscs[index].octave + 2) / 4.0
    semitone_slider.val = (synth.oscs[index].semitone + 12) / 24.0
    phase_slider.val = synth.oscs[index].phase / 360.0
    level_slider.val = synth.oscs[index].level
    adsr_sliders[0].val = slider_inv_exp(synth.oscs[index].env.attack_time, 10, 3000, 3)
    adsr_sliders[1].val = slider_inv_exp(synth.oscs[index].env.decay_time, 10, 3000, 3)
    adsr_sliders[2].val = synth.oscs[index].env.sustain_level
    adsr_sliders[3].val = slider_inv_exp(synth.oscs[index].env.release_time, 10, 10000, 3)
}

handle_input :: proc(synth: ^Synth) {
    for key, i in KEYBOARD {
        note := &synth.notes[i]
        if rl.IsKeyPressed(key) {
            note.playing = true
            note.release_samples = 0
        } else if rl.IsKeyReleased(key) {
            note.release_start_amp = calc_note_amp(note^, synth.current_osc.env)
            note.playing = false
            note.press_samples = 0
        }
    }
}

handle_ui_input :: proc(synth: ^Synth, mouse_pos: rl.Vector2) {
    for h_slider, index in h_sliders {
        slider_update_h(h_slider, mouse_pos)
    }

    for osc_slider, index in osc_level_sliders {
        slider_update_v(osc_slider, mouse_pos)
    }

    slider_update_v(&gain_level_slider, mouse_pos)

    for slider, index in adsr_sliders {
        slider_update_v(slider, mouse_pos)
    }

    for osc_mute_rect, index in osc_mute_rects {
        if rl.CheckCollisionPointRec(mouse_pos, osc_mute_rect) && rl.IsMouseButtonPressed(.LEFT) {

        }
    }

    for wave in 0..<len(basic_wave_rects) {
        if rl.CheckCollisionPointRec(mouse_pos, basic_wave_rects[wave]) && rl.IsMouseButtonPressed(.LEFT) {
            synth.current_osc.base = Waveform(wave)
        }
    }

    for osc_rect, index in osc_rects {
        if rl.CheckCollisionPointRec(mouse_pos, osc_rect) && rl.IsMouseButtonPressed(.LEFT) {
            synth.current_osc = &synth.oscs[index]
            synth.current_osc_index = index
            set_ui_to_osc(synth^, index)
        }
    }

    for osc_mute_rect, index in osc_mute_rects {
        if rl.CheckCollisionPointRec(mouse_pos, osc_mute_rect) && rl.IsMouseButtonPressed(.LEFT) {
            synth.oscs[index].muted = !synth.oscs[index].muted
        }
    }
}

draw_ui :: proc(synth: Synth) {
    rl.ClearBackground(rl.GetColor(0x181818FF))

    // draw wave shape
    rl.DrawRectangleLines(10, 10, 200, 100, {255, 255, 255, 255})

    SEGMENT_SIZE :: 300
    display_lines: [SEGMENT_SIZE][2]f32
    for i in 0..<SEGMENT_SIZE {
        angle := f32(i)/f32(SEGMENT_SIZE)*4.0*math.PI
        value := basic_waveform_display(synth.current_osc.base, angle)
        display_lines[i] = {15.0 + f32(i)/f32(SEGMENT_SIZE) * 190.0, 10.0 + 50.0 - value * 45.0}
    }
    rl.DrawLineStrip(raw_data(display_lines[:]), len(display_lines), rl.RED)

    rl.DrawRectangleLinesEx({5, 5, 210, HEIGHT - 10}, 2.0, rl.WHITE)

    // Draw Waveform UIs
    SEGMENT :: 50
    waveform_lines: [SEGMENT][2]f32
    for wave, index in Waveform {
        for i in 0..<SEGMENT {
            angle := f32(i)/f32(SEGMENT)*2.0*math.PI
            value := basic_waveform_display(wave, angle)
            waveform_lines[i] = {10.0 + 50.0 * f32(wave) + f32(i)/f32(SEGMENT) * 50.0, 115.0 + 15.0 - value * 10.0}
        }

        selected := synth.current_osc.base == wave

        color := rl.RED if selected else rl.WHITE
        border := rl.GREEN if selected else rl.WHITE

        rl.DrawLineStrip(raw_data(waveform_lines[:]), len(waveform_lines), color)
        rl.DrawRectangleLinesEx(basic_wave_rects[wave], 1.0, border)
    }

    for h_slider, index in h_sliders {
        slider_draw_h(h_slider^)
    }

    // Draw unison and detune sliders
    rl.DrawText("Unison:", 60, 160, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%d", synth.current_osc.unison.voices), 140, 160, 20, rl.WHITE)

    rl.DrawText("Detune:", 50, 220, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.unison.detune), 130, 220, 20, rl.WHITE)

    rl.DrawText("Octave:", 50, 280, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.octave), 130, 280, 20, rl.WHITE)

    rl.DrawText("Semitone:", 40, 340, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.semitone), 135, 340, 20, rl.WHITE)

    rl.DrawText("Phase:", 50, 400, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.phase), 120, 400, 20, rl.WHITE)

    rl.DrawText("Level:", 50, 460, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.level), 120, 460, 20, rl.WHITE)

    rl.DrawText("Oscillators", 50, 520, 20, rl.WHITE)

    text_positions := [3]i32{10 + 31, 10 + 67 + 28, 10 + 67 + 66 + 28}
    for osc_rect, index in osc_rects {
        selected := synth.current_osc_index == index

        color := rl.RED if selected else rl.WHITE
        border := rl.GREEN if selected else rl.WHITE

        rl.DrawRectangleLinesEx(osc_rect, 2.0, border)
        rl.DrawText(rl.TextFormat("%d", index + 1), text_positions[index], 550 + 5, 20, color)
    }

    rl.DrawRectangleLinesEx({220, 5, 200, 180}, 2.0, rl.WHITE)

    for osc_mute_rect, index in osc_mute_rects {
        if synth.oscs[index].muted {
            rl.DrawRectangleRec(osc_mute_rect, rl.BLUE)
        }

        rl.DrawRectangleLinesEx(osc_mute_rect, 1.0, rl.WHITE)
        rl.DrawText("M", i32(osc_mute_rect.x) + 11, 20, 10, rl.WHITE)
    }

    for osc_slider in osc_level_sliders {
        slider_draw_v(osc_slider^)
    }

    slider_draw_v(gain_level_slider)

    rl.DrawText("1", 243, 155, 20, rl.WHITE)
    rl.DrawText("2", 279, 155, 20, rl.WHITE)
    rl.DrawText("3", 319, 155, 20, rl.WHITE)
    rl.DrawText("GAIN", 356, 155, 20, rl.WHITE)

    rl.DrawRectangleLinesEx({430, 5, 170, 180}, 2.0, rl.WHITE)

    rl.DrawText("A", 440 + 9, 15, 20, rl.WHITE)
    rl.DrawText("D", 480 + 9, 15, 20, rl.WHITE)
    rl.DrawText("S", 520 + 9, 15, 20, rl.WHITE)
    rl.DrawText("R", 560 + 9, 15, 20, rl.WHITE)

    for slider, index in adsr_sliders {
        slider_draw_v(slider^)
    }

    rl.DrawText(rl.TextFormat("%.0f", synth.current_osc.env.attack_time), 445, 155, 10, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.0f", synth.current_osc.env.decay_time), 485, 155, 10, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.env.sustain_level), 525, 155, 10, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.0f", synth.current_osc.env.release_time), 565, 155, 10, rl.WHITE)


}
