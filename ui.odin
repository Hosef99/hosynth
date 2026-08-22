package hosynth

import "core:math"
import rl "vendor:raylib"

Slider :: struct {
    rect: rl.Rectangle,
    val: f32, // 0 to 1
    default: f32,
    active: bool,
}

slider_draw :: proc(slider: Slider) {
    rect := slider.rect
    rect.width = rect.width * slider.val
    rl.DrawRectangleRec(rect, rl.WHITE)
    rl.DrawRectangleLinesEx(slider.rect, 3, rl.LIGHTGRAY)
}

slider_update :: proc(slider: ^Slider, mouse: rl.Vector2) {
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

osc1_rect := rl.Rectangle{10, 550, 67, 30}
osc2_rect := rl.Rectangle{10 + 67, 550, 66, 30}
osc3_rect := rl.Rectangle{10 + 67 + 66, 550, 67, 30}
osc_rects := [3]rl.Rectangle{osc1_rect, osc2_rect, osc3_rect}

set_ui_to_osc :: proc(synth: Synth, index: int) {
    unison_slider.val = f32(synth.oscs[index].unison.voices - 1) / 10.0
    detune_slider.val = synth.oscs[index].unison.detune / 50.0
    octave_slider.val = (synth.oscs[index].octave + 2) / 4.0
    semitone_slider.val = (synth.oscs[index].semitone + 12) / 24.0
    phase_slider.val = synth.oscs[index].phase / 360.0
    level_slider.val = synth.oscs[index].level
}

handle_input :: proc(synth: ^Synth) {
    for key, i in KEYBOARD {
        note := &synth.notes[i]
        if rl.IsKeyPressed(key) {
            note.playing = true
            note.release_samples = 0
        } else if rl.IsKeyReleased(key) {
            note.release_start_amp = calc_note_amp(note^, synth.env)
            note.playing = false
            note.press_samples = 0
        }
    }
}

handle_ui_input :: proc(synth: ^Synth, mouse_pos: rl.Vector2) {
    slider_update(&unison_slider, mouse_pos)
    slider_update(&detune_slider, mouse_pos)
    slider_update(&octave_slider, mouse_pos)
    slider_update(&semitone_slider, mouse_pos)
    slider_update(&phase_slider, mouse_pos)
    slider_update(&level_slider, mouse_pos)
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
    rl.DrawLineStrip(raw_data(display_lines[:]), len(display_lines), {255, 0, 0, 255})

    rl.DrawRectangleLines(5, 5, 210, HEIGHT-10, {255, 255, 255, 255})

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

    // Draw unison and detune sliders
    rl.DrawText("Unison:", 60, 160, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%d", synth.current_osc.unison.voices), 140, 160, 20, rl.WHITE)

    slider_draw(unison_slider)

    rl.DrawText("Detune:", 50, 220, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.unison.detune), 130, 220, 20, rl.WHITE)

    slider_draw(detune_slider)

    rl.DrawText("Octave:", 50, 280, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.octave), 130, 280, 20, rl.WHITE)

    slider_draw(octave_slider)

    rl.DrawText("Semitone:", 40, 340, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.semitone), 135, 340, 20, rl.WHITE)

    slider_draw(semitone_slider)

    rl.DrawText("Phase:", 50, 400, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.phase), 120, 400, 20, rl.WHITE)

    slider_draw(phase_slider)

    rl.DrawText("Level:", 50, 460, 20, rl.WHITE)
    rl.DrawText(rl.TextFormat("%.2f", synth.current_osc.level), 120, 460, 20, rl.WHITE)

    slider_draw(level_slider)

    rl.DrawText("Oscillators", 50, 520, 20, rl.WHITE)

    text_positions := [3]i32{10 + 31, 10 + 67 + 28, 10 + 67 + 66 + 28}
    for osc_rect, index in osc_rects {
        selected := synth.current_osc_index == index

        color := rl.RED if selected else rl.WHITE
        border := rl.GREEN if selected else rl.WHITE

        rl.DrawRectangleLinesEx(osc_rect, 2.0, border)
        rl.DrawText(rl.TextFormat("%d", index), text_positions[index], 550 + 5, 20, color)
    }
}
