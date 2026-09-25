# Compile llama.cpp avec le backend Vulkan (RADV) et installe les binaires.
#
# Sources : $SRC_DIR/llama.cpp       (clone partagé entre backends)
# Binaires : $OPT_DIR/llama.cpp-vulkan/bin
# Liens    : $BIN_DIR/llama-*  si DEFAULT_BACKEND=vulkan

src="$SRC_DIR/llama.cpp"
build="$src/build-vulkan"
prefix="$OPT_DIR/llama.cpp-vulkan"

mkdir -p "$SRC_DIR" "$OPT_DIR" "$BIN_DIR"

if [[ -d $src/.git ]]; then
  log "mise à jour de $src"
  git -C "$src" fetch --tags --prune origin
else
  log "clone de $LLAMA_CPP_REPO"
  git clone "$LLAMA_CPP_REPO" "$src"
fi
git -C "$src" checkout --quiet "$LLAMA_CPP_REF"
# Avance la branche si la ref est une branche suivie (sans effet sur un tag/commit)
git -C "$src" symbolic-ref -q HEAD >/dev/null && git -C "$src" pull --quiet --ff-only
commit="$(git -C "$src" describe --tags --always)"
log "llama.cpp @ $commit"

cmake -S "$src" -B "$build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_VULKAN=ON \
  -DGGML_NATIVE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLAMA_CURL=ON \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
cmake --build "$build" -j "$(nproc)"

rm -rf "$prefix/bin"
mkdir -p "$prefix/bin"
cp "$build"/bin/llama-* "$prefix/bin/"
echo "$commit" > "$prefix/VERSION"
ok "binaires installés dans $prefix/bin ($commit)"

if [[ $DEFAULT_BACKEND == vulkan ]]; then
  for b in "$prefix"/bin/llama-*; do ln -sfn "$b" "$BIN_DIR/$(basename "$b")"; done
  ok "liens llama-* créés dans $BIN_DIR"
fi
