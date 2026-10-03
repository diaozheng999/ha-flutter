#pragma once

#include <array>
#include <cstdint>
#include <string>

namespace rf_gateway {

inline const char *command_name(uint32_t word) {
  switch (word & 0x1FFFFF) {
    case 0x16E50B: return "fan_off";
    case 0x16E5A9: return "speed_1";
    case 0x16E589: return "speed_2";
    case 0x16E56A: return "speed_3";
    case 0x16E54A: return "speed_4";
    case 0x16E5E8: return "speed_5";
    case 0x16E5C8: return "fan_fr";
    case 0x16E591: return "light_off";
    case 0x16E572: return "light_warm";
    case 0x16E5B1: return "light_neutral";
    case 0x16E5D0: return "light_cool";
    case 0x16E533: return "light_brightness_up";
    case 0x16E4F4: return "light_brightness_down";
    default: return nullptr;
  }
}

inline void finalize(bool &open, uint32_t generation,
                     const std::array<uint32_t, 8> &bursts,
                     std::array<uint8_t, 8> &sources, uint8_t source) {
  for (size_t i = 0; i < sources.size(); ++i)
    if (bursts[i] == generation && sources[i] == 1) sources[i] = source;
  open = false;
}

class EventPublication {
 public:
  void begin(size_t slot, uint32_t event_id, bool connected) {
    if (pending_[slot]) ++overflow_count;
    ids_[slot] = event_id;
    pending_[slot] = connected;
  }

  template<typename Emit>
  void flush(uint32_t count, const std::array<uint32_t, 8> &ids,
             const std::array<uint32_t, 8> &words,
             const std::array<uint8_t, 8> &sources, bool connected, Emit emit) {
    if (!connected) {
      pending_.fill(false);
      return;
    }
    const uint32_t retained = count < 8 ? count : 8;
    for (uint32_t offset = 0; offset < retained; ++offset) {
      const uint32_t sequence = count - retained + 1 + offset;
      const size_t slot = (sequence - 1) % 8;
      if (!pending_[slot] || ids_[slot] != ids[slot] || ids[slot] != sequence) continue;
      if (sources[slot] == 1) break;  // Preserve order until source is final.
      pending_[slot] = false;
      const uint32_t unit = words[slot] >> 21;
      const char *command = command_name(words[slot]);
      if (command == nullptr || (unit != 0x21 && unit != 0xCB) || sources[slot] > 3) continue;
      const char *source = sources[slot] == 2 ? "broadlink" : (sources[slot] == 3 ? "mixed" : "unmarked");
      emit(unit, std::string(command) + "_" + source);
    }
  }

  uint32_t overflow_count{0};

 private:
  std::array<uint32_t, 8> ids_{};
  std::array<bool, 8> pending_{};
};

}  // namespace rf_gateway
