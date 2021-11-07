#ifndef __MEDIA_EDEN_CORE__UTILS_FFMPEG_H__
#define __MEDIA_EDEN_CORE__UTILS_FFMPEG_H__

#include <mutex>

#include <EdenCore/Utils/Logger/Logger.h>  // get log level type
#include <EdenCore/Utils/Pattern/Singleton.h> // get singletone pattern

extern "C" {
#include <libavutil/log.h>
}

namespace MediaEden::EdenCore::Utils {

class FFmpegConfig : public Singleton<FFmpegConfig> {
public:
	void setLogRedirect(bool bRedirect);
  bool getLogRedirect();
	
  void setLogLevel(int level);
  int getLogLevel();
	
	/**
   * @brief: get log from ffmpeg
   */
	static void RedirectAvLog(void* ptr, int log_level, const char* log, va_list);


private:
	explicit FFmpegConfig();
	FFmpegConfig(const FFmpegConfig&) = delete;
	FFmpegConfig(FFmpegConfig&&) = delete;
	FFmpegConfig& operator=(const FFmpegConfig&) = delete;
	FFmpegConfig& operator=(FFmpegConfig&&) = delete;

	std::shared_ptr<Logger> logger_;
	int av_log_level_;
	bool av_log_redirect_;

	std::mutex AvConfigMtx_;
};

} /* namespace MediaEden::EdenCore::Utils */

#endif

