# /// script
# requires-python = ">=3.12,<3.13"
# dependencies = [
#     "huggingface_hub",
#     "moshi_mlx==0.2.12",
#     "numpy",
#     "sphn",
# ]
# ///
"""Kyutai TTS (MLX) with chunked long-form generation.

Why chunking: kyutai/tts-1.6b-en_fr attends over a 500-step (40 s) window and
every backend degrades past ~5 min of continuous generation
(kyutai-labs/delayed-streams-modeling#106). Each chunk here runs a fresh
generation well inside the window, so the model can never drift off the rails.

Why non-streaming decode: Mimi.decode_step carries stale StreamingAdd buffers
across resets (kyutai-labs/moshi#407), distorting every generation after the
first. Mimi.decode resets itself and uses the plain residual-add path.

The ring KV-cache workaround (max_seq_len = context) mirrors
delayed-streams-modeling#108 / scripts/tts_mlx.py for moshi_mlx <= 0.3.0.
"""

import argparse
import json
import re
import sys
import time
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Text normalization: markdown -> plain spoken English words.
# Numbers are expanded to words so the model never sees ambiguous digit
# strings; the sentencepiece vocab is 8k pieces trained on speech transcripts.
# Keep in sync with the copy in the ASR verification harness.
# ---------------------------------------------------------------------------

ONES = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
    "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
    "sixteen", "seventeen", "eighteen", "nineteen",
]
TENS = [
    "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
    "eighty", "ninety",
]
SCALES = [(10**9, "billion"), (10**6, "million"), (10**3, "thousand")]

ORDINAL_ONES = {
    "one": "first", "two": "second", "three": "third", "five": "fifth",
    "eight": "eighth", "nine": "ninth", "twelve": "twelfth",
}


def int_to_words(n: int) -> str:
    if n < 0:
        return "minus " + int_to_words(-n)
    if n < 20:
        return ONES[n]
    if n < 100:
        tens, rem = divmod(n, 10)
        return TENS[tens] + (" " + ONES[rem] if rem else "")
    if n < 1000:
        hundreds, rem = divmod(n, 100)
        out = ONES[hundreds] + " hundred"
        return out + (" " + int_to_words(rem) if rem else "")
    for scale, name in SCALES:
        if n >= scale:
            major, rem = divmod(n, scale)
            out = int_to_words(major) + " " + name
            return out + (" " + int_to_words(rem) if rem else "")
    return str(n)


def ordinal_to_words(n: int) -> str:
    words = int_to_words(n)
    head, _, last = words.rpartition(" ")
    if last in ORDINAL_ONES:
        last = ORDINAL_ONES[last]
    elif last.endswith("y"):
        last = last[:-1] + "ieth"
    else:
        last = last + "th"
    return (head + " " + last).strip()


def digits_to_words(digits: str) -> str:
    return " ".join(ONES[int(d)] for d in digits)


def number_to_words(num: str) -> str:
    """Expand a plain numeric literal: 12  4,096  3.5  2398.56"""
    num = num.replace(",", "")
    if "." in num:
        whole, frac = num.split(".", 1)
        out = int_to_words(int(whole)) if whole else "zero"
        if frac:
            out += " point " + digits_to_words(frac)
        return out
    return int_to_words(int(num))


NUM = r"\d+(?:,\d{3})*(?:\.\d+)?"


def _currency(m: re.Match) -> str:
    amount = number_to_words(m.group(1))
    unit = "dollar" if m.group(1).replace(",", "") in ("1", "1.0") else "dollars"
    suffix = (m.group(2) or "").lower()
    if suffix:
        scale = {"k": "thousand", "m": "million", "b": "billion"}.get(suffix, suffix)
        return f"{amount} {scale} dollars"
    return f"{amount} {unit}"


def _time_of_day(m: re.Match) -> str:
    hours, minutes = int(m.group(1)), m.group(2)
    out = int_to_words(hours)
    if minutes == "00":
        return out + " o'clock"
    if minutes.startswith("0"):
        return out + " oh " + int_to_words(int(minutes))
    return out + " " + int_to_words(int(minutes))


def expand_numbers(text: str) -> str:
    # Letter->digit boundaries are always safe to split early: v3.4.7, Q3.
    text = re.sub(r"(?<=[A-Za-z])(?=\d)", " ", text)
    # Versions like 3.4.7 or v3.4.7 -> spoken digit groups joined by "point".
    text = re.sub(
        r"(?<![\d.])(\d+(?:\.\d+){2,})(?![\d.])",
        lambda m: " point ".join(number_to_words(p) for p in m.group(1).split(".")),
        text,
    )
    text = re.sub(
        rf"\$({NUM})\s+(thousand|million|billion|trillion)\b",
        lambda m: f"{number_to_words(m.group(1))} {m.group(2)} dollars",
        text,
    )
    text = re.sub(rf"\$({NUM})([kKmMbB])?\b", _currency, text)
    text = re.sub(rf"({NUM})\s*%", lambda m: number_to_words(m.group(1)) + " percent", text)
    text = re.sub(r"\b(\d{1,2}):([0-5]\d)\b", _time_of_day, text)
    text = re.sub(r"\b(\d+)(st|nd|rd|th)\b", lambda m: ordinal_to_words(int(m.group(1))), text)
    # Decades like 1990s -> nineteen nineties.
    def _decade(m: re.Match) -> str:
        words = int_to_words(int(m.group(1)[:2])) + " " + int_to_words(int(m.group(1)[2:]))
        return words[:-1] + "ies" if words.endswith("y") else words + "s"

    text = re.sub(r"\b(\d{4})s\b", _decade, text)
    # Split letter<->digit boundaries: Q3 -> Q 3, e3672af -> e 3672 af.
    text = re.sub(r"(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])", " ", text)
    # Ranges: 3-5 -> three to five.
    text = re.sub(
        r"\b(\d+)\s*-\s*(\d+)\b",
        lambda m: int_to_words(int(m.group(1))) + " to " + int_to_words(int(m.group(2))),
        text,
    )
    # Years 1900-2099 read as pairs; other numbers read plainly.
    def _plain(m: re.Match) -> str:
        raw = m.group(0)
        bare = raw.replace(",", "")
        if "," not in raw and "." not in raw and len(bare) == 4 and bare.isdigit():
            year = int(bare)
            if 1900 <= year <= 2099:
                if bare == "2000":
                    return "two thousand"
                if bare[2:] == "00":
                    return int_to_words(int(bare[:2])) + " hundred"
                return int_to_words(int(bare[:2])) + " " + (
                    "oh " + ONES[int(bare[3])] if bare[2] == "0" else int_to_words(int(bare[2:]))
                )
        return number_to_words(raw)

    text = re.sub(NUM, _plain, text)
    return text


MD_TABLE_SEP = re.compile(r"^\s*\|?[\s:|-]+\|?\s*$")


def strip_markdown(text: str) -> str:
    lines = []
    in_code = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if MD_TABLE_SEP.match(stripped) and "|" in stripped:
            continue
        if re.fullmatch(r"\s*(?:[-*_]\s*){3,}", line):
            lines.append("")
            continue
        if "|" in line and stripped.startswith("|"):
            cells = [c.strip() for c in stripped.strip("|").split("|")]
            cells = [c for c in cells if c]
            line = ". ".join(cells) + "."
        line = re.sub(r"^\s{0,3}#{1,6}\s+", "", line)
        line = re.sub(r"^\s*>\s?", "", line)
        line = re.sub(r"^\s*[-*+]\s+", "", line)
        lines.append(line)
    text = "\n".join(lines)
    text = re.sub(r"!\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"__([^_]+)__", r"\1", text)
    text = re.sub(r"(?<!\w)\*([^*\n]+)\*(?!\w)", r"\1", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = text.replace("*", " ").replace("#", " ")
    return text


def normalize_text(text: str) -> str:
    text = text.replace("\u2019", "'").replace("\u2018", "'")
    text = text.replace("\u201c", '"').replace("\u201d", '"')
    text = text.replace("\u2026", "...")
    text = strip_markdown(text)
    text = text.replace("\u2014", ", ").replace("\u2013", " to ")
    text = text.replace("&", " and ")
    text = re.sub(r"(\w)/(\w)", r"\1 \2", text)
    text = text.replace("=", " equals ")
    text = expand_numbers(text)
    # Drop characters the tokenizer has no useful mapping for.
    text = re.sub(r"[^\w\s.,;:!?'\"()-]", " ", text)
    text = re.sub(r"_", " ", text)
    return text


SENTENCE_END = re.compile(r"(?<=[.!?])[\"')\]]*\s+")


def split_sentences(paragraph: str) -> list[str]:
    parts = [p.strip() for p in SENTENCE_END.split(paragraph)]
    return [p for p in parts if p]


def split_long_sentence(sentence: str, max_words: int) -> list[str]:
    words = sentence.split()
    if len(words) <= max_words:
        return [sentence]
    clauses = re.split(r"(?<=[,;:])\s+", sentence)
    pieces: list[str] = []
    current: list[str] = []
    count = 0
    for clause in clauses:
        clause_words = clause.split()
        if count and count + len(clause_words) > max_words:
            pieces.append(" ".join(current))
            current, count = [], 0
        while len(clause_words) > max_words:
            pieces.append(" ".join(clause_words[:max_words]))
            clause_words = clause_words[max_words:]
        current.extend(clause_words)
        count += len(clause_words)
    if current:
        pieces.append(" ".join(current))
    return pieces


@dataclass
class Chunk:
    text: str
    paragraph_start: bool
    words: int = 0

    def __post_init__(self):
        self.words = len(self.text.split())


def chunk_text(text: str, max_words: int) -> list[Chunk]:
    chunks: list[Chunk] = []
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text)]
    for paragraph in paragraphs:
        if not paragraph:
            continue
        paragraph = re.sub(r"\s+", " ", paragraph)
        sentences: list[str] = []
        for sentence in split_sentences(paragraph):
            sentences.extend(split_long_sentence(sentence, max_words))
        first = True
        current: list[str] = []
        count = 0
        for sentence in sentences:
            n = len(sentence.split())
            if count and count + n > max_words:
                chunks.append(Chunk(" ".join(current), first))
                first = False
                current, count = [], 0
            current.append(sentence)
            count += n
        if current:
            chunks.append(Chunk(" ".join(current), first))
    return chunks


# ---------------------------------------------------------------------------
# Generation.
# ---------------------------------------------------------------------------

FRAME_RATE = 12.5
# Trained attention window is 500 steps; stay inside it with headroom.
MAX_CHUNK_STEPS = 480
# Speaking-rate acceptance window (words per second of generated audio).
MIN_WPS = 0.8
MAX_WPS = 5.0
MAX_ATTEMPTS = 3


@dataclass
class ChunkResult:
    index: int
    text: str
    words: int
    seconds: float = 0.0
    rms: float = 0.0
    attempts: int = 0
    wps: float = 0.0
    paragraph_start: bool = False
    failures: list[str] = field(default_factory=list)


def load_tts(args):
    import mlx.core as mx
    import mlx.nn as nn
    import sentencepiece
    from moshi_mlx import models
    from moshi_mlx.models.tts import TTSModel
    from moshi_mlx.utils.loaders import hf_get

    raw_config = hf_get("config.json", args.hf_repo)
    with open(hf_get(raw_config), "r") as fobj:
        raw_config = json.load(fobj)

    mimi_weights = hf_get(raw_config["mimi_name"], args.hf_repo)
    moshi_name = raw_config.get("moshi_name", "model.safetensors")
    moshi_weights = hf_get(moshi_name, args.hf_repo)
    tokenizer = hf_get(raw_config["tokenizer_name"], args.hf_repo)

    lm_config = models.LmConfig.from_config_dict(raw_config)
    # Ring KV-cache bug workaround for moshi_mlx <= 0.3.0 (DSM #108).
    lm_config.transformer.max_seq_len = lm_config.transformer.context

    model = models.Lm(lm_config)
    model.set_dtype(mx.bfloat16)
    model.load_pytorch_weights(str(moshi_weights), lm_config, strict=True)

    if args.quantize is not None:
        nn.quantize(model.depformer, bits=args.quantize)
        for layer in model.transformer.layers:
            nn.quantize(layer.self_attn, bits=args.quantize)
            nn.quantize(layer.gating, bits=args.quantize)

    text_tokenizer = sentencepiece.SentencePieceProcessor(str(tokenizer))

    generated_codebooks = lm_config.generated_codebooks
    audio_tokenizer = models.mimi.Mimi(models.mimi_202407(generated_codebooks))
    audio_tokenizer.load_pytorch_weights(str(mimi_weights), strict=True)

    tts_model = TTSModel(
        model,
        audio_tokenizer,
        text_tokenizer,
        voice_repo=args.voice_repo,
        n_q=args.nq,
        temp=args.temp,
        cfg_coef=args.cfg_coef,
        max_padding=8,
        initial_padding=2,
        final_padding=4,
        padding_bonus=0,
        raw_config=raw_config,
    )
    return tts_model


def generate_chunk(tts_model, attributes, chunk: Chunk, seed: int, args):
    """Generate one chunk with a completely fresh model state.

    Returns (pcm, seconds, rms, error). error is None on success.
    """
    import mlx.core as mx
    import numpy as np

    mx.random.seed(seed)
    for cache in tts_model.lm.transformer_cache:
        cache.reset()

    entries = tts_model.prepare_script([chunk.text], padding_between=1)
    # Budget: generous speech-rate lower bound, capped inside the 500-step
    # attention window. A generation that misses its budget failed (no end).
    budget = int(FRAME_RATE * (chunk.words / 1.0 + 5.0))
    total_budget = min(budget + tts_model.delay_steps + tts_model.final_padding, MAX_CHUNK_STEPS)
    tts_model.max_gen_length = total_budget

    cfg_is_no_text = not tts_model.valid_cfg_conditionings
    result = tts_model.generate(
        [entries], [attributes],
        cfg_is_no_prefix=not tts_model.valid_cfg_conditionings,
        cfg_is_no_text=cfg_is_no_text,
    )
    end_step = result.end_steps[0]
    if end_step is None:
        return None, 0.0, 0.0, f"no end step within {total_budget} steps"
    if not result.frames:
        return None, 0.0, 0.0, "no frames generated"

    frames = mx.concat(result.frames, axis=-1)  # [1, K, T]
    pcm = tts_model.mimi.decode(frames)  # non-streaming decode: moshi#407-safe
    pcm = np.array(mx.clip(pcm[0, 0], -1, 1)).astype(np.float32)

    sample_rate = int(tts_model.mimi.sample_rate)
    wav_length = int(sample_rate * (end_step + tts_model.final_padding) / FRAME_RATE)
    pcm = pcm[: min(wav_length, pcm.shape[-1])]

    seconds = pcm.shape[-1] / sample_rate
    rms = float(np.sqrt(np.mean(pcm**2))) if pcm.size else 0.0
    if seconds <= 0.05:
        return None, seconds, rms, "empty audio"
    wps = chunk.words / seconds
    if chunk.words >= 6 and not (MIN_WPS <= wps <= MAX_WPS):
        return None, seconds, rms, f"speech rate {wps:.2f} wps outside [{MIN_WPS}, {MAX_WPS}]"
    if rms < 1e-4:
        return None, seconds, rms, f"silent audio (rms {rms:.2e})"
    return pcm, seconds, rms, None


def cmd_generate(args) -> int:
    import numpy as np
    import sphn

    if args.inp == "-":
        text = sys.stdin.read()
    else:
        with open(args.inp, "r", encoding="utf-8") as fobj:
            text = fobj.read()

    normalized = normalize_text(text)
    chunks = chunk_text(normalized, args.max_chunk_words)
    if not chunks:
        print("no speakable text found", file=sys.stderr)
        return 64

    total_words = sum(c.words for c in chunks)
    print(f"chunks: {len(chunks)}, words: {total_words}", file=sys.stderr)

    load_begin = time.time()
    tts_model = load_tts(args)
    sample_rate = int(tts_model.mimi.sample_rate)
    print(f"model loaded in {time.time() - load_begin:.1f}s", file=sys.stderr)

    cfg_coef_conditioning = None
    if tts_model.valid_cfg_conditionings:
        cfg_coef_conditioning = tts_model.cfg_coef
        tts_model.cfg_coef = 1.0
    voices = [tts_model.get_voice_path(args.voice)] if tts_model.multi_speaker else []
    attributes = tts_model.make_condition_attributes(voices, cfg_coef_conditioning)

    pieces: list[np.ndarray] = []
    results: list[ChunkResult] = []
    gap = np.zeros(int(sample_rate * args.gap), dtype=np.float32)
    paragraph_gap = np.zeros(int(sample_rate * args.paragraph_gap), dtype=np.float32)
    begin = time.time()

    for index, chunk in enumerate(chunks):
        report = ChunkResult(
            index=index, text=chunk.text, words=chunk.words,
            paragraph_start=chunk.paragraph_start,
        )
        pcm = None
        for attempt in range(MAX_ATTEMPTS):
            report.attempts = attempt + 1
            seed = args.seed + index * 17 + attempt * 1009
            pcm, seconds, rms, error = generate_chunk(tts_model, attributes, chunk, seed, args)
            if error is None:
                report.seconds, report.rms = seconds, rms
                report.wps = chunk.words / seconds if seconds else 0.0
                break
            report.failures.append(error)
            print(f"chunk {index} attempt {attempt + 1} failed: {error}", file=sys.stderr)
        if pcm is None:
            print(f"chunk {index} failed after {MAX_ATTEMPTS} attempts: {chunk.text[:80]}", file=sys.stderr)
            return 65
        if pieces:
            pieces.append(paragraph_gap if chunk.paragraph_start else gap)
        pieces.append(pcm)
        results.append(report)
        done = index + 1
        elapsed = time.time() - begin
        audio_secs = sum(r.seconds for r in results)
        print(
            f"[{done}/{len(chunks)}] {audio_secs:8.1f}s audio, {elapsed:7.1f}s wall, rtf {audio_secs / elapsed:4.2f}",
            file=sys.stderr,
        )

    wav = np.concatenate(pieces)
    sphn.write_wav(args.out, wav, sample_rate)

    if args.report:
        report = {
            "input_words": total_words,
            "chunks": [vars(r) for r in results],
            "audio_seconds": float(wav.shape[-1] / sample_rate),
            "sample_rate": sample_rate,
            "voice": args.voice,
            "temp": args.temp,
            "cfg_coef": args.cfg_coef,
            "quantize": args.quantize,
            "seed": args.seed,
            "normalized_text": " ".join(c.text for c in chunks),
        }
        with open(args.report, "w", encoding="utf-8") as fobj:
            json.dump(report, fobj, indent=1)
    return 0


def cmd_normalize(args) -> int:
    if args.inp == "-":
        text = sys.stdin.read()
    else:
        with open(args.inp, "r", encoding="utf-8") as fobj:
            text = fobj.read()
    chunks = chunk_text(normalize_text(text), args.max_chunk_words)
    for chunk in chunks:
        marker = "P" if chunk.paragraph_start else " "
        print(f"{marker} [{chunk.words:3d}] {chunk.text}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Kyutai TTS on MLX with chunked long-form generation")
    parser.add_argument("inp", help="input text file, - for stdin")
    parser.add_argument("out", help="output wav path")
    parser.add_argument("--voice", default="expresso/ex03-ex01_happy_001_channel1_334s.wav")
    parser.add_argument("--hf-repo", default="kyutai/tts-1.6b-en_fr")
    parser.add_argument("--voice-repo", default="kyutai/tts-voices")
    parser.add_argument("--temp", type=float, default=0.6)
    parser.add_argument("--cfg-coef", type=float, default=2.0)
    parser.add_argument("--quantize", type=int, choices=(4, 8))
    parser.add_argument("--nq", type=int, default=32)
    parser.add_argument("--seed", type=int, default=299792458)
    parser.add_argument("--max-chunk-words", type=int, default=50)
    parser.add_argument("--gap", type=float, default=0.22, help="silence between chunks, seconds")
    parser.add_argument("--paragraph-gap", type=float, default=0.6)
    parser.add_argument("--report", help="write a JSON generation report here")
    parser.add_argument("--normalize-only", action="store_true", help="print normalized chunks and exit")
    args = parser.parse_args()

    if args.normalize_only:
        return cmd_normalize(args)
    return cmd_generate(args)


if __name__ == "__main__":
    sys.exit(main())
