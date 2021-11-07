#ifndef __MEDIA_EDEN_CORE__UTILS_HASH_H__
#define __MEDIA_EDEN_CORE__UTILS_HASH_H__

#include <cstdint>

namespace MediaEden::EdenCore::Utils {

/**
 * @brief   Google's Jump Consistent Hash Algorithm
 * @details	bucket balance enhanced Consistent Hash algorithm
 * @param   uint64_t key key for hash function
 * @param   int32_t  num_buckets n of nodes  
 * @return 
 * [reference](https://docs.google.com/viewerng/viewer?url=http://www.smallake.kr/wp-content/uploads/2014/08/1406.2294.pdf&hl=ko)
 */
int32_t JumpConsistentHash(uint64_t key, int32_t num_buckets);

} /* namespace MediaEden::EdenCore::Utils */

#endif

