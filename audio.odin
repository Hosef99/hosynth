package hosynth

import rl "vendor:raylib"
import "core:math"

Audio :: struct {
    stream: rl.AudioStream
}

soft_clip :: proc(vol: f32) -> f32 {
    return vol / (1 + math.abs(vol))
}

process_audio :: proc(audio: Audio, synth: ^Synth) {
    buffer: [BUFFER_SIZE]f32
    for note, i in synth.notes {
        set_note(&synth.notes[i], synth, &buffer)
    }

    for &it, i in buffer {
        it = soft_clip(it * synth.gain)
        // it = clamp(it, -1, 1)
    }
    rl.UpdateAudioStream(audio.stream, &buffer[0], BUFFER_SIZE)
}
