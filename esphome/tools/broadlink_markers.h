#pragma once
// D57: preserve the eight-byte B1 C0 transport header. No device access.
#include <algorithm>
#include <array>
#include <cstdint>
#include <numeric>
#include <stdexcept>
#include <vector>

namespace broadlink_markers {
using Pulses = std::vector<int32_t>;
constexpr int32_t guard = 160;
constexpr int32_t marker_ticks = 172;
constexpr size_t marker_pulses = 19;
struct Packet {
  std::array<uint8_t, 8> header;
  Pulses pulses;
};

inline Pulses marker(uint8_t value) {
  Pulses out{20, 20};
  for (int bit = 7; bit >= 0; --bit) {
    const bool one = (value & (1U << bit)) != 0;
    out.push_back(one ? 12 : 4);
    out.push_back(one ? 4 : 12);
  }
  out.push_back(4);
  return out;
}

inline int marker_at(const Pulses &p, size_t pos) {
  if (pos + marker_pulses > p.size() || p[pos] != 20 || p[pos + 1] != 20 ||
      p[pos + 18] != 4) return -1;
  int value = 0;
  for (size_t bit = 0; bit < 8; ++bit) {
    const auto mark = p[pos + 2 + bit * 2], space = p[pos + 3 + bit * 2];
    if (!((mark == 4 && space == 12) || (mark == 12 && space == 4))) return -1;
    value = (value << 1) | (mark == 12);
  }
  return value;
}

inline void replace_space(Pulses &p, size_t index, uint8_t value) {
  if (index % 2 != 1 || p.at(index) < guard * 2 + marker_ticks)
    throw std::runtime_error("Insufficient original idle space");
  const auto remaining = p[index] - guard - marker_ticks;
  Pulses replacement{guard};
  const auto code = marker(value);
  replacement.insert(replacement.end(), code.begin(), code.end());
  replacement.push_back(remaining);
  p.erase(p.begin() + index);
  p.insert(p.begin() + index, replacement.begin(), replacement.end());
}

inline Pulses add(const Pulses &original) {
  if (original.size() < 60 || original.size() % 2 != 0)
    throw std::runtime_error("Expected complete alternating command packet");
  for (size_t i = 0; i < original.size(); i += 2) {
    if (marker_at(original, i) >= 0) throw std::runtime_error("Packet already has a marker");
  }
  Pulses result = original;
  replace_space(result, result.size() - 1, 0x5A);
  return result;
}

inline Pulses remove(const Pulses &tagged) {
  std::vector<size_t> positions;
  for (size_t i = 0; i < tagged.size(); i += 2) {
    const int value = marker_at(tagged, i);
    if (value == 0xA5 || value == 0x5A) positions.push_back(i);
  }
  if (positions.size() != 1 || marker_at(tagged, positions[0]) != 0x5A ||
      positions[0] == 0 || positions[0] + marker_pulses + 1 != tagged.size())
    throw std::runtime_error("Expected exactly one final footer");
  Pulses result = tagged;
  {
    const size_t pos = positions[0];
    if (result[pos - 1] != guard || result[pos + marker_pulses] < guard)
      throw std::runtime_error("Invalid marker guard");
    const int64_t restored = int64_t(guard) + marker_ticks + result[pos + marker_pulses];
    if (restored > 65535) throw std::runtime_error("Restored space too long");
    result.erase(result.begin() + pos - 1, result.begin() + pos + marker_pulses + 1);
    result.insert(result.begin() + pos - 1, static_cast<int32_t>(restored));
  }
  if (add(result) != tagged) throw std::runtime_error("Non-canonical marked packet");
  return result;
}

inline Packet unpack(const std::vector<uint8_t> &bytes) {
  if (bytes.size() < 8 || bytes[0] != 0xB1 || bytes[1] != 0xC0 ||
      bytes.size() - 4 != size_t(bytes[2]) + 256U * bytes[3])
    throw std::runtime_error("Unsupported packet or invalid declared length");
  Packet packet{};
  std::copy_n(bytes.begin(), 8, packet.header.begin());
  // Retained originals identify this 433 MHz subformat. Preserve all four
  // metadata bytes verbatim; they are not an initial mark/space or a repeat.
  const uint32_t metadata = uint32_t(bytes[4]) | (uint32_t(bytes[5]) << 8) |
                            (uint32_t(bytes[6]) << 16) | (uint32_t(bytes[7]) << 24);
  if (metadata < 433000 || metadata > 435000)
    throw std::runtime_error("Unsupported or damaged B1 C0 transport metadata");
  for (size_t i = 8; i < bytes.size();) {
    int32_t ticks = bytes[i++];
    if (ticks == 0) {
      if (i + 1 >= bytes.size()) throw std::runtime_error("Truncated extended duration");
      ticks = int32_t(bytes[i]) * 256 + bytes[i + 1];
      i += 2;
    }
    if (ticks == 0) throw std::runtime_error("Zero duration");
    packet.pulses.push_back(ticks);
  }
  if (packet.pulses.size() < 60 || packet.pulses.size() % 2 != 0)
    throw std::runtime_error("Incomplete B1 C0 waveform");
  return packet;
}

inline std::vector<uint8_t> pack(const Packet &packet) {
  std::vector<uint8_t> bytes(packet.header.begin(), packet.header.end());
  for (auto ticks : packet.pulses) {
    if (ticks <= 0 || ticks > 65535) throw std::runtime_error("Duration outside packet range");
    if (ticks > 255) {
      bytes.push_back(0);
      bytes.push_back(static_cast<uint8_t>(ticks >> 8));
    }
    bytes.push_back(static_cast<uint8_t>(ticks));
  }
  if (bytes.size() - 4 > 65535) throw std::runtime_error("Packet too long");
  bytes[2] = static_cast<uint8_t>(bytes.size() - 4);
  bytes[3] = static_cast<uint8_t>((bytes.size() - 4) >> 8);
  return bytes;
}

inline std::vector<uint8_t> transform(const std::vector<uint8_t> &bytes, bool restore = false) {
  auto original = unpack(bytes);
  if (pack(original) != bytes) throw std::runtime_error("Non-canonical original encoding");
  original.pulses = restore ? remove(original.pulses) : add(original.pulses);
  return pack(original);
}
}  // namespace broadlink_markers
