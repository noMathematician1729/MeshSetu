MeshSetu does not bundle speech-to-text model assets.

English, Hindi, Marathi, and Gujarati download their own Sherpa-ONNX-compatible
model after the user selects a language. Downloads run without blocking profile
creation, are verified with pinned SHA-256 checksums, and are stored in the
app's private support directory. Voice input becomes available as soon as the
selected model is ready.
