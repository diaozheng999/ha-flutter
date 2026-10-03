#include "../tools/broadlink_markers.h"
#include <iostream>
#include <functional>
#include <string>
struct PacketFixture { const char *room; const char *command; std::vector<uint8_t> bytes; std::vector<int32_t> ticks; };
#include "mistral_existing_packets.h"
using namespace broadlink_markers;
unsigned checks = 0;
void require(bool value) { if (!value) throw std::runtime_error("Marker assertion failed"); ++checks; }
void rejects(const std::function<void()> &fn) {
  bool rejected = false;
  try { fn(); } catch (const std::runtime_error &) { rejected = true; }
  require(rejected);
}
int main() {
  try {
    for (const auto &fixture : existing_packets) {
      const auto packet = transform(fixture.bytes);
      if (!std::equal(fixture.bytes.begin() + 4, fixture.bytes.begin() + 8, packet.begin() + 4))
        throw std::runtime_error("Broadlink transport bytes 4..7 were corrupted");
      require(packet[0] == fixture.bytes[0] && packet[1] == fixture.bytes[1]);
      require(unpack(fixture.bytes).pulses == fixture.ticks);
      require(pack(unpack(fixture.bytes)) == fixture.bytes);
      require(transform(packet, true) == fixture.bytes);
      require(unpack(packet).pulses == add(fixture.ticks));
      const auto tagged = add(fixture.ticks);
      require(remove(tagged) == fixture.ticks);
      require(std::accumulate(tagged.begin(), tagged.end(), int64_t(0)) ==
              std::accumulate(fixture.ticks.begin(), fixture.ticks.end(), int64_t(0)));
      require(tagged.size() == fixture.ticks.size() + 20);
      // Only final idle content changes. Every native timing and absolute
      // start position remains identical; footer adds no transmission time.
      int64_t original_time = 0;
      for (size_t i = 0; i < fixture.ticks.size(); ++i) {
        if (i != fixture.ticks.size() - 1) {
          const size_t new_index = i;
          require(tagged[new_index] == fixture.ticks[i]);
          require(std::accumulate(tagged.begin(), tagged.begin() + new_index, int64_t(0)) == original_time);
        }
        original_time += fixture.ticks[i];
      }
      rejects([&] { add(tagged); });
      auto broken = tagged;
      broken[fixture.ticks.size() + 2] = 5;
      rejects([&] { remove(broken); });
      // The failed canary changed metadata byte 7 to A0, while round trips
      // through its own erroneous pulse parser still passed.
      auto damaged_metadata = fixture.bytes;
      damaged_metadata[7] = 0xA0;
      rejects([&] { transform(damaged_metadata); });
      auto truncated = fixture.bytes;
      truncated.pop_back();
      rejects([&] { transform(truncated); });
      auto short_end = fixture.ticks;
      short_end.back() = 100;
      rejects([&] { add(short_end); });
    }
    rejects([] { unpack({0xB1, 0xC0, 1, 0, 0}); });
    rejects([] { unpack({0xB1, 0xC0, 3, 0, 0, 0, 0}); });
    rejects([] { unpack({0xB1, 0xC0, 0, 0, 4}); });
    rejects([] { unpack({0xB2, 0, 1, 0, 4}); });
    std::cout << "PASS: " << checks << " marker checks; all 26 packets, exact restoration, "
                 "transport metadata preserved, zero added delay, original frame timing preserved\n";
  } catch (const std::exception &error) { std::cerr << error.what() << '\n'; return 1; }
}
