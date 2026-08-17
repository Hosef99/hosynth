package hosynth

import "core:fmt"
import rl "vendor:raylib"
import "core:math"

WIDTH :: 900
HEIGHT :: 600

SAMPLE_RATE :: 48000
BUFFER_SIZE :: 2048

C3 :: 130.8

Envelope :: struct { // all time-related values are in ms
    attack_time, decay_time, sustain_level, release_time: f32,
}

Unison_Voice :: struct {
    phase: f32,
}

Note :: struct {
    playing: bool,
    freq: f32,

    unison: []Unison_Voice,
    
    press_samples, release_samples: int,
    release_start_amp: f32,
}

calc_note_amp :: proc(note: Note, env: Envelope) -> f32 {
    attack_samples := int(env.attack_time * SAMPLE_RATE / 1000)
    decay_samples := int(env.decay_time * SAMPLE_RATE / 1000)
    release_samples := int(env.release_time * SAMPLE_RATE / 1000)

    if note.playing {
        decay_cutoff := attack_samples + decay_samples
        if note.press_samples < attack_samples { // Attack section
            ratio := f32(note.press_samples) / f32(attack_samples)
            return ratio
        } else if note.press_samples < decay_cutoff { // Decay section
            // Lerp between attack level and sustain level
            ratio := f32(note.press_samples - attack_samples) / f32(decay_samples)
            return ratio * env.sustain_level + (1 - ratio)
        } else { // Sustain section
            return env.sustain_level
        }
    } else { // release
        if note.release_samples < release_samples {
            ratio := f32(note.release_samples) / f32(release_samples)
            return (1 - ratio) * note.release_start_amp
        } else {
            return f32(0.0)
        }
    }
}

get_freq :: proc(semitones: int) -> f32 {
    semitone_diff := math.pow(f32(2.0), 1.0 / 12.0)
    return C3 * math.pow(semitone_diff, f32(semitones))
}

detune_freq :: proc(freq, cents: f32) -> f32 {
    return freq * math.pow(2.0, cents / 1200.0)
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

basic_waves := [4](proc(angle: f32) -> f32){sin, square, triangle, saw}

Unison :: struct {
    voices: int,
    detune: f32,
}

Wave :: struct {
    base: int,
    pitch: f32,
    unison: Unison,
}

waveform :: proc(wave: Wave, angle: f32) -> f32 {
    return basic_waves[wave.base](angle)
}

Synth :: struct {
    wave: Wave,
    env: Envelope,
}

e_piano := Envelope{20, 500, 0.70, 20}

synth := Synth{{2, 0, {3, 10}}, e_piano}

master_gain: f32 = 0.2

set_note :: proc(note: ^Note, buffer: ^[BUFFER_SIZE]f32) {
    pitch_mult := math.pow(2.0, synth.wave.pitch)

    voices := synth.wave.unison.voices
    unison_gain := 1.0 / math.sqrt(f32(voices))

    for i in 0..<BUFFER_SIZE {
        amp := calc_note_amp(note^, synth.env)

        for j in 0..<voices {
            offset := j - (voices - 1) / 2

            freq := detune_freq(note.freq, f32(offset) * synth.wave.unison.detune)

            phase_inc := freq * pitch_mult / f32(SAMPLE_RATE)

            sample := waveform(synth.wave, 2.0 * math.PI * note.unison[j].phase)

            buffer^[i] += sample * unison_gain * amp

            note.unison[j].phase += phase_inc

            if note.unison[j].phase >= 1.0 {
                note.unison[j].phase -= 1.0
            }
        }

        if note.playing {
            note.press_samples += 1
        } else {
            note.release_samples += 1
        }
    }
}

KEYBOARD :: [?]rl.KeyboardKey{.Q, .TWO, .W, .THREE, .E, .R, .FIVE, .T, .SIX, .Y, .SEVEN, .U, .Z, .S, .X, .D, .C, .V, .G, .B, .H, .N, .J, .M, .COMMA}

notes: [len(KEYBOARD)]Note

last_time: f32 = 0.0
dt: f32

sin_rect := rl.Rectangle{10, 115, 50, 30}
square_rect := rl.Rectangle{10+50, 115, 50, 30}
triangle_rect := rl.Rectangle{10+100, 115, 50, 30}
saw_rect := rl.Rectangle{10+150, 115, 50, 30}

basic_wave_rects := [4]rl.Rectangle{sin_rect, square_rect, triangle_rect, saw_rect}

main :: proc() {
    t := f32(rl.GetTime())

    for note, i in notes {
        notes[i].freq = get_freq(i)
        notes[i].unison = make([]Unison_Voice, 3)
    }
    keyboard := KEYBOARD

    rl.InitWindow(WIDTH, HEIGHT, "Hosynth")

    defer rl.CloseWindow()

    rl.InitAudioDevice()

    defer rl.CloseAudioDevice()

    rl.SetAudioStreamBufferSizeDefault(BUFFER_SIZE)

    buffer: [BUFFER_SIZE]f32

    stream := rl.LoadAudioStream(SAMPLE_RATE, 32, 1)

    defer rl.UnloadAudioStream(stream)

    rl.PlayAudioStream(stream)

    rl.SetTargetFPS(60)
    for !rl.WindowShouldClose() {
        t = f32(rl.GetTime())
        dt = t - last_time
        last_time = t

        mouse_pos := rl.GetMousePosition()

        for note, i in notes {
            if rl.IsKeyPressed(keyboard[i]) {
                notes[i].playing = true
                notes[i].release_samples = 0
            } else if rl.IsKeyReleased(keyboard[i]) {
                notes[i].release_start_amp = calc_note_amp(notes[i], synth.env)
                notes[i].playing = false
                notes[i].press_samples = 0
            }
        }

        if rl.IsAudioStreamProcessed(stream) {
            buffer = {}
            for note, i in notes {
                set_note(&notes[i], &buffer)
            }

            for it, i in buffer {
                buffer[i] *= master_gain
                buffer[i] = clamp(buffer[i], -1, 1)
            }
            rl.UpdateAudioStream(stream, &buffer[0], BUFFER_SIZE)
        }

        // Drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.GetColor(0x181818FF))

        // draw wave shape
        rl.DrawRectangleLines(10, 10, 200, 100, {255, 255, 255, 255})

        SEGMENT_SIZE :: 300
        display_lines: [SEGMENT_SIZE][2]f32
        for i in 0..<SEGMENT_SIZE {
            angle := f32(i)/f32(SEGMENT_SIZE)*4.0*math.PI
            value := waveform(synth.wave, angle)
            display_lines[i] = {15.0 + f32(i)/f32(SEGMENT_SIZE) * 190.0, 10.0 + 50.0 - value * 45.0}
        }
        rl.DrawLineStrip(raw_data(display_lines[:]), len(display_lines), {255, 0, 0, 255})

        rl.DrawRectangleLines(5, 5, 210, HEIGHT-10, {255, 255, 255, 255})

        // Handle event
        for wave in 0..<len(basic_wave_rects) {
            if rl.CheckCollisionPointRec(mouse_pos, basic_wave_rects[wave]) && rl.IsMouseButtonPressed(.LEFT) {
                synth.wave.base = wave
            }
        }
        
        // Draw Waveform UIs
        SEGMENT :: 50
        waveform_lines: [SEGMENT][2]f32
        for wave in 0..<len(basic_waves) {
            for i in 0..<SEGMENT {
                angle := f32(i)/f32(SEGMENT)*2.0*math.PI
                value := basic_waves[wave](angle)
                waveform_lines[i] = {10.0 + 50.0 * f32(wave) + f32(i)/f32(SEGMENT) * 50.0, 115.0 + 15.0 - value * 10.0}
            }

            selected := synth.wave.base == wave

            color := rl.RED if selected else rl.WHITE
            border := rl.GREEN if selected else rl.WHITE

            rl.DrawLineStrip(raw_data(waveform_lines[:]), len(waveform_lines), color)
            rl.DrawRectangleLinesEx(basic_wave_rects[wave], 1.0, border)
        }

        rl.EndDrawing()
    }
}
