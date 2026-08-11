package hosynth

import rl "vendor:raylib"
import "core:math"

SAMPLE_RATE :: 44100
BUFFER_SIZE :: 1024

A4 :: 440.0

Note :: struct {
    playing: bool,
    freq: f32,
    frame_count: int
}

get_freq :: proc(semitones: int) -> f32 {
    semitone_diff := math.pow(f32(2.0), 1.0 / 12.0)
    return A4 * math.pow(semitone_diff, f32(semitones))
}

set_note :: proc(note: ^Note, buffer: ^[BUFFER_SIZE]f32) {
    if !note.playing {
        return
    }
    for i in 0..<BUFFER_SIZE {
        time := f32(note.frame_count)/f32(SAMPLE_RATE)
        buffer^[i] += math.sin(2.0*math.PI*time*note.freq) * 0.25
        note.frame_count += 1
    }
}

KEYBOARD :: [?]rl.KeyboardKey{.Z, .S, .X, .D, .C, .V, .G, .B, .H, .N, .J, .M, .COMMA}

notes: [len(KEYBOARD)]Note

main :: proc() {
    for note, i in notes {
        notes[i].freq = get_freq(i)
    }
    keyboard := KEYBOARD

    rl.InitWindow(800, 600, "Hosynth")

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
        for note, i in notes {
            notes[i].playing = rl.IsKeyDown(keyboard[i])
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
        rl.EndDrawing()
    }
}
