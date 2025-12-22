#pragma once
#include <vector>
#include <cstdint>

class Cache {
public:

    Cache(int32_t* memory, int num_sets = 32, int associativity = 2);

    int load(uint32_t addr, int32_t& out);
    int store(uint32_t addr, int32_t val);

    int hits() const { return hits_; }
    int misses() const { return misses_; }

    void print_stats() const;
private:
    static constexpr int HIT_LATENCY = 1;
    static constexpr int MISS_LATENCY = 10;

    struct CacheLine {
        bool valid = false;
        uint32_t tag = 0;
        int32_t data = 0;
        uint64_t last_used = 0; // for LRU
    };

    struct CacheSet {
        std::vector<CacheLine> ways;
        CacheSet(int associativity) {
            ways.resize(associativity);
        }
    };

    std::vector<CacheSet> sets_;
    int32_t* memory_;
    int num_sets_;
    int associativity_;
    uint64_t cycle_counter_ = 0;

    uint32_t get_set_index(uint32_t addr) const;
    uint32_t get_tag(uint32_t addr) const;
    CacheLine* find_line(CacheSet& set, uint32_t tag);
    CacheLine* find_victim(CacheSet& set); // LRU

    int hits_ = 0;
    int misses_ = 0;
};

