#ifndef __MEDIA_EDEN_CORE__UTILS_SINGLETON_H__
#define __MEDIA_EDEN_CORE__UTILS_SINGLETON_H__

#include <memory>

namespace MediaEden::EdenCore::Utils {

/**
 * @brief   Singletone Design Pattern
 */
template<class T>
class Singleton {
public:
	virtual ~Singleton() = default;

	static std::unique_ptr<T>& GetInstance() {
		std::call_once(T::flag_, []() { T::instance_.reset(new T()); });
		return T::instance_;
	}

protected:
	Singleton() = default;

private:
	static std::unique_ptr<T> instance_;
	static std::once_flag flag_;
};

} /* namespace MediaEden::EdenCore::Utils */

#endif

