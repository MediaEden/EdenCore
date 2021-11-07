#include <EdenCore/Utils/Hash/Hash.h>

#include <cstdint>

namespace MediaEden::EdenCore::Utils {

  int32_t GoogleConsistentHash(uint64_t key, int32_t num_buckets) {
    int64_t b = 1, j = 0;
    while (j < num_buckets) {
      b = j;
      key = key * 2862933555777941757ULL + 1;
      j = (b + 1) * (double(1LL << 31) / double((key >> 33) + 1));
    }
    return b;
  }

} /* namespace MediaEden::EdenCore::Utils */
