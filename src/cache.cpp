#include <iostream>
#include "cache.hpp"

Cache::Cache(int32_t* memory, int32_t num_sets, int32_t associativity)
    : memory_(memory), num_sets_(num_sets), associativity_(associativity) {
    sets_.reserve(num_sets_);
    for (int i = 0; i < num_sets_; ++i) {
        sets_.emplace_back(CacheSet(associativity_));
    }
}

uint32_t Cache::get_set_index(uint32_t addr) const {
    return addr % num_sets_; // assuming 4-byte words
}

uint32_t Cache::get_tag(uint32_t addr) const {
    return addr >> __builtin_ctz(num_sets_); // skip offset + set index bits
}

Cache::CacheLine* Cache::find_line(CacheSet& set, uint32_t tag) {
    for (auto& line : set.ways) {
        if (line.valid && line.tag == tag) {
            return &line;
        }
    }
    return nullptr;
}

Cache::CacheLine* Cache::find_victim(CacheSet& set) {
    // find invalid
    for (auto& line : set.ways) {
        if (!line.valid) return &line;
    }

    // use LRU
    CacheLine* lru = &set.ways[0];
    for (auto& line : set.ways) {
        if (line.last_used < lru->last_used) {
            lru = &line;
        }
    }
    printf("EVICTED\n");
    return lru;
}

int Cache::load(uint32_t addr, int32_t& out) {
    ++cycle_counter_;

    uint32_t set_index = get_set_index(addr);
    uint32_t tag = get_tag(addr);
    CacheSet& set = sets_[set_index];
    CacheLine* line = find_line(set, tag);
    printf("Address: %x. Tag: %x, Set %d \n", addr, tag, set_index);

    if (line) {
        printf("Load HIT\n");
        // HIT
        hits_++;
        out = line->data;
        line->last_used = cycle_counter_;
        return HIT_LATENCY;
    }
    printf("Load MISS\n");  
    // MISS
    misses_++;
    out = memory_[addr]; // assume 1 word per block
    CacheLine* victim = find_victim(set);
    victim->valid = true;
    victim->tag = tag;
    victim->data = out;
    victim->last_used = cycle_counter_;
    return MISS_LATENCY; 
}

int Cache::store(uint32_t addr, int32_t val) {
    ++cycle_counter_;

    uint32_t set_index = get_set_index(addr);
    uint32_t tag = get_tag(addr);
    CacheSet& set = sets_[set_index];

    CacheLine* line = find_line(set, tag);
    memory_[addr] = val; // write-through always writes to memory

    if (line) {

        printf("Store HIT\n");
        hits_++;
        line->data = val;
        line->last_used = cycle_counter_;
        return HIT_LATENCY;
    }
    printf("Store MISS\n"); 
    misses_++;
    CacheLine* victim = find_victim(set);
    victim->valid = true;
    victim->tag = tag;
    victim->data = val;
    victim->last_used = cycle_counter_;
    return MISS_LATENCY;
}

void Cache::print_stats() const {
    std::cout << "== Cache Stats ==\n";
    std::cout << "Hits:   " << hits_ << "\n";
    std::cout << "Misses: " << misses_ << "\n";
    double rate = 100.0 * hits_ / (hits_ + misses_);
    std::cout << "Hit rate: " << rate << "%\n";
}



