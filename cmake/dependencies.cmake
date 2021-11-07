#
# Dependency handling
#

# ---- pkg-config ----
find_package(PkgConfig REQUIRED)

# ---- ffmpeg ----
pkg_check_modules(
  FFMPEG_LIBS
  REQUIRED
  IMPORTED_TARGET
  libavdevice
  libavfilter
  libavformat
  libavcodec
  libswresample
  libswscale
  libavutil)
