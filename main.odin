package hosynth

import "core:fmt"
import rl "vendor:raylib"
import "core:math"

WIDTH :: 900
HEIGHT :: 600

SAMPLE_RATE :: 48000
BUFFER_SIZE :: 2048

C4 :: 261.6

offset: f32 = 1.0

Envelope :: struct { // all time-related values are in ms
    attack_time, decay_time, sustain_level, release_time: f32,
}

Note :: struct {
    playing: bool,
    freq: f32,
    phase: f32,
    
    press_samples, release_samples: int,
    release_start_amp: f32,
    env: Envelope,
}

calc_note_amp :: proc(note: Note) -> f32 {
    attack_samples := int(note.env.attack_time * SAMPLE_RATE / 1000)
    decay_samples := int(note.env.decay_time * SAMPLE_RATE / 1000)
    release_samples := int(note.env.release_time * SAMPLE_RATE / 1000)

    if note.playing {
        decay_cutoff := attack_samples + decay_samples
        if note.press_samples < attack_samples { // Attack section
            ratio := f32(note.press_samples) / f32(attack_samples)
            return ratio
        } else if note.press_samples < decay_cutoff { // Decay section
            // Lerp between attack level and sustain level
            ratio := f32(note.press_samples - attack_samples) / f32(decay_samples)
            return ratio * note.env.sustain_level + (1 - ratio)
        } else { // Sustain section
            return note.env.sustain_level
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
    return C4 * math.pow(semitone_diff, f32(semitones))
}

set_note :: proc(note: ^Note, buffer: ^[BUFFER_SIZE]f32) {

    phase_inc := note.freq / f32(SAMPLE_RATE)

    for i in 0..<BUFFER_SIZE {
        amp := calc_note_amp(note^)

        buffer^[i] += math.sin(2.0 * math.PI * note.phase) * 0.25 * amp

        note.phase += phase_inc

        if note.phase >= 1.0 {
            note.phase -= 1.0
        }

        if note.playing {
            note.press_samples += 1
        } else {
            note.release_samples += 1
        }
    }
}

KEYBOARD :: [?]rl.KeyboardKey{.Z, .S, .X, .D, .C, .V, .G, .B, .H, .N, .J, .M, .COMMA}

notes: [len(KEYBOARD)]Note

last_time: f32 = 0.0
dt: f32

e_piano := Envelope{20, 500, 0.70, 20}

main :: proc() {
    t := f32(rl.GetTime())

    for note, i in notes {
        notes[i].freq = get_freq(i)
        notes[i].env = e_piano
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

        for note, i in notes {
            if rl.IsKeyPressed(keyboard[i]) {
                notes[i].playing = true
                notes[i].release_samples = 0
            } else if rl.IsKeyReleased(keyboard[i]) {
                notes[i].release_start_amp = calc_note_amp(notes[i])
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
                buffer[i] = clamp(it, -1, 1)
            }
            rl.UpdateAudioStream(stream, &buffer[0], BUFFER_SIZE)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.GetColor(0x181818FF))

        points := [BUFFER_SIZE]rl.Vector2{}

        for value, i in buffer {
            points[i] = {f32(i)/f32(BUFFER_SIZE)*f32(WIDTH), buffer[i]*f32(HEIGHT)/3.0+f32(HEIGHT)/2.0}
        }

	    rl.DrawLineStrip(raw_data(points[:]), BUFFER_SIZE, rl.Color{255,0,0,255})

        rl.EndDrawing()
    }
}
