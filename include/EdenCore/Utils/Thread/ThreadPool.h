#ifndef __MEDIA_EDEN_CORE__UTILS_THREAD_POOL_H__
#define __MEDIA_EDEN_CORE__UTILS_THREAD_POOL_H__

#include <thread>

auto nProcessor = std::thread::hardware_concurrency();

namespace MediaEden::EdenCore::Utils {

/**
 * @brief   Thread Pool for I/O task
 * @details	...
 */
class ThreadPool {
public:
	ThreadPool(unsigned int n);

private:
	const unsigned int nproc_;
};

} /* namespace MediaEden::EdenCore::Utils */


#endif

