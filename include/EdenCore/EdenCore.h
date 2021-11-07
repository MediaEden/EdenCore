#ifndef __MEDIA_EDEN_CORE__EDEN_CORE_H__
#define __MEDIA_EDEN_CORE__EDEN_CORE_H__

#include <string>

namespace MediaEden::EdenCore {

class EdenCoreConfig {
public:	    
	explicit EdenCoreConfig(std::string name);

private:
	std::string _name;
};

}  /* namespace MediaEden::EdenCore */

#endif

