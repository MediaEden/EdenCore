#include <EdenCore/Utils/FFmpeg/FFmpeg.h>

#include <mutex>
#include <string>

namespace MediaEden::EdenCore::Utils {

  FFmpegConfig::FFmpegConfig() : av_log_level_(0) {}

  void FFmpegConfig::setLogRedirect(bool bRedirect) {
    std::lock_guard<std::mutex> lock_guard(AvConfigMtx_);

    if (!av_log_redirect_ && bRedirect) {
      av_log_set_callback(&FFmpegConfig::RedirectAvLog);
      av_log_redirect_ = true;
    } else if (av_log_redirect_ && !bRedirect) {
      av_log_set_callback(av_log_default_callback);
      av_log_redirect_ = false;
    }
  }

  bool FFmpegConfig::getLogRedirect() {
    std::lock_guard<std::mutex> lock_guard(AvConfigMtx_);
    return av_log_redirect_;
  };

  void FFmpegConfig::setLogLevel(int level) {
    std::lock_guard<std::mutex> lock_guard(AvConfigMtx_);

    if (av_log_level_ != level) {
      av_log_level_ = level;
      av_log_set_level(level);
    }
  }

  int FFmpegConfig::getLogLevel() {
    std::lock_guard<std::mutex> lock_guard(AvConfigMtx_);

    return av_log_get_level();
  };

  void FFmpegConfig::RedirectAvLog(void* ptr, int log_level, const char* log, va_list) {
    std::string log_str = "";
  }

} /* namespace MediaEden::EdenCore::Utils */
