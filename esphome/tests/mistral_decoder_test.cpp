// Native regression test for the actual ESPHome on_raw lambda.
// Reference data comes from existing learned RF codes; no device access.
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <map>
#include <stdexcept>
#include <string>
#include <vector>
#include "../tools/broadlink_markers.h"
#include "../rf_event_publication.h"

struct Fixture {
  const char *room;
  const char *command;
  std::array<int32_t, 59> ticks;
};
#include "mistral_existing_frames.h"
struct PacketFixture {
  const char *room;
  const char *command;
  std::vector<uint8_t> bytes;
  std::vector<int32_t> ticks;
};
#include "mistral_existing_packets.h"

uint64_t raw_capture_count = 0, last_capture_ms = 0;
uint64_t matched_frame_count = 0, last_match_ms = 0;
uint32_t best_decoded_bits = 0, last_decoded_word = 0, last_input_size = 0;
const char *received_room = "NONE", *received_button = "NONE";
const char *decode_status = "WAITING";
uint64_t mock_now = 12345;
uint64_t millis_64() { return mock_now; }
std::array<uint32_t, 8> event_words{}, event_ids{}, event_bursts{};
std::array<const char *, 8> event_buttons{};
std::array<uint8_t, 8> event_sources{};
std::array<uint64_t, 8> event_times{};
uint32_t event_count = 0, marker_generation = 0, marker_first_word = 0;
std::array<uint32_t, 26> key_last_event{}, key_last_burst{};
std::array<uint64_t, 26> key_last_seen{};
std::array<uint32_t, 2> room_last_word{};
bool marker_open = false, marker_mixed = false;
uint64_t marker_last_command_ms = 0;
uint32_t marker_footer_count = 0;
uint32_t marker_sync_count = 0, marker_best_bits = 0;
rf_gateway::EventPublication rf_publication;
struct ApiStub {
  bool connected{true};
  bool is_connected() const { return connected; }
} native_api;
std::vector<std::pair<uint32_t, std::string>> published;
struct EventStub {
  uint32_t unit;
  void trigger(const std::string &type) { published.emplace_back(unit, type); }
};
EventStub study_rf_command{0x21}, bedroom_rf_command{0xCB};
#define id(name) name
void decode(const std::vector<int32_t> &x) {
#include "../.esphome/decoder-test/decoder.inc"
}
void publication_tick() {
#include "../.esphome/decoder-test/publication_tick.inc"
}
#undef id

unsigned checks = 0;
void check(const std::string &name, const std::vector<int32_t> &pulses,
           const char *room = "UNKNOWN", const char *button = "UNKNOWN", bool retain_match = false) {
  if (!retain_match) {
    matched_frame_count = 0;
    last_match_ms = 0;
    received_room = received_button = "NONE";
  }
  const auto before = raw_capture_count;
  decode(pulses);
  if (std::strcmp(received_room, room) || std::strcmp(received_button, button) ||
      raw_capture_count != before + 1 || last_capture_ms != 12345 || last_input_size != pulses.size()) {
    std::cerr << name << ": " << received_room << " / " << received_button << '\n';
    throw std::runtime_error("decoder mismatch");
  }
  checks++;
}

std::vector<int32_t> pulses_for(const Fixture &frame, double scale = 1.0) {
  std::vector<int32_t> pulses;
  for (size_t i = 0; i < frame.ticks.size(); i++) {
    const auto duration = static_cast<int32_t>(std::lround(frame.ticks[i] * 8192.0 / 269 * scale));
    pulses.push_back(i % 2 == 0 ? duration : -duration);
  }
  pulses.push_back(-4000);
  return pulses;
}

void reset_events() {
  event_words.fill(0); event_ids.fill(0); event_bursts.fill(0);
  event_buttons.fill(nullptr); event_sources.fill(0); event_times.fill(0);
  key_last_event.fill(0); key_last_burst.fill(0); key_last_seen.fill(0); room_last_word.fill(0);
  event_count = marker_generation = marker_first_word = 0;
  marker_open = marker_mixed = false;
  marker_last_command_ms = 0;
  marker_footer_count = marker_sync_count = marker_best_bits = 0;
  rf_publication = rf_gateway::EventPublication{};
  native_api.connected = true;
  published.clear();
  mock_now = 12345;
}

void require(bool condition, const char *description) {
  if (!condition) throw std::runtime_error(description);
  ++checks;
}

std::vector<int32_t> marker_input(uint8_t byte, int polarity = 1, double scale = 1.0) {
  const auto ticks = broadlink_markers::marker(byte);
  std::vector<int32_t> out;
  for (size_t i = 0; i < ticks.size(); ++i)
    out.push_back(static_cast<int32_t>(std::lround(ticks[i] * 8192.0 / 269 * scale)) * (i % 2 ? -polarity : polarity));
  out.push_back(-4000 * polarity);
  return out;
}

int main() {
  if (std::strcmp(received_room, "NONE") || std::strcmp(received_button, "NONE"))
    return 2;
  const std::map<std::string, const char *> labels = {
      {"fan_off", "FAN OFF"}, {"fan_fr", "DIRECTION"},
      {"speed_1", "SPEED 1"}, {"speed_2", "SPEED 2"}, {"speed_3", "SPEED 3"},
      {"speed_4", "SPEED 4"}, {"speed_5", "SPEED 5"},
      {"light_off", "LIGHT OFF"}, {"light_warm", "LIGHT WARM"},
      {"light_neutral", "LIGHT NEUTRAL"}, {"light_cool", "LIGHT COOL"},
      {"light_brightness_up", "BRIGHTNESS UP"}, {"light_brightness_down", "BRIGHTNESS DOWN"}};
  for (const auto &frame : existing_frames) {
    for (double scale : {0.9, 1.0, 1.1}) {
      for (int polarity : {1, -1}) {
        auto pulses = pulses_for(frame, scale);
        for (auto &pulse : pulses) pulse *= polarity;
        check(std::string(frame.room) + " " + frame.command + " scale " + std::to_string(scale),
              pulses, frame.room, labels.at(frame.command));
      }
    }
  }

  for (const auto &packet : existing_packets) {
    for (double scale : {0.9, 1.0, 1.1}) {
      std::vector<int32_t> pulses;
      for (size_t i = 0; i < packet.ticks.size(); i++) {
        const auto duration = static_cast<int32_t>(std::lround(packet.ticks[i] * 8192.0 / 269 * scale));
        pulses.push_back(i % 2 == 0 ? duration : -duration);
      }
      check(std::string("complete packet ") + packet.room + " " + packet.command + " scale " + std::to_string(scale),
            pulses, packet.room, labels.at(packet.command));

      // Feed complete stored transmissions through the configured 4 ms idle
      // delimiter, including partial preamble batches and later unmatched data.
      for (int polarity : {1, -1}) {
        matched_frame_count = 0;
        received_room = received_button = "NONE";
        std::vector<int32_t> batch;
        for (auto pulse : pulses) {
          const bool idle = std::abs(pulse) >= 4000;
          batch.push_back(polarity * (idle ? (pulse > 0 ? 4000 : -4000) : pulse));
          if (idle) {
            if (batch.size() > 384) throw std::runtime_error("RMT batch exceeds configured capacity");
            decode(batch);
            batch.clear();
          }
        }
        if (!batch.empty()) decode(batch);
        if (matched_frame_count == 0 || std::strcmp(received_room, packet.room) ||
            std::strcmp(received_button, labels.at(packet.command)))
          throw std::runtime_error(std::string("RMT-delimited packet mismatch: ") + packet.command);
        checks++;
      }
    }
  }

  const auto first = pulses_for(existing_frames[0]);
  const auto room = existing_frames[0].room;
  const auto button = labels.at(existing_frames[0].command);
  auto changed = first;
  changed.pop_back();
  check("input end boundary", changed, room, button);
  changed = first;
  changed.insert(changed.begin(), -10000);
  check("leading gap", changed, room, button);
  changed = {200, -700, 300, -10000};
  changed.insert(changed.end(), first.begin(), first.end());
  check("noise then boundary", changed, room, button);
  changed = first;
  changed.insert(changed.end(), first.begin(), first.end());
  changed.insert(changed.end(), first.begin(), first.end());
  check("repeated frames", changed, room, button);
  changed = first;
  changed.back() = -3000;
  changed.insert(changed.end(), first.begin(), first.end());
  check("short boundary", changed, room, button);

  for (size_t length = 0; length < 59; length++)
    check("truncated " + std::to_string(length), {first.begin(), first.begin() + length});
  check("idle only", {-10000});
  changed = first;
  for (auto &pulse : changed) pulse = -pulse;
  check("opposite input polarity", changed, room, button);
  changed = {350, -1000};
  changed.insert(changed.end(), first.begin(), first.end());
  check("missing start boundary", changed);
  changed = first;
  changed.back() = -1000;
  changed.insert(changed.end(), {350, -10000});
  check("missing end boundary", changed);
  for (size_t i = 0; i < 59; i++) {
    changed = first;
    changed[i] = i % 2 == 0 ? 700 : -700;
    check("invalid timing " + std::to_string(i), changed);
  }
  for (int32_t terminal : {0, -350, 700, 2000}) {
    changed = first;
    changed[58] = terminal;
    check("invalid terminal", changed);
  }
  for (size_t bit : {0, 8}) {
    changed = first;
    changed[bit * 2] = -first[bit * 2 + 1];
    changed[bit * 2 + 1] = -first[bit * 2];
    check(bit == 0 ? "unknown unit" : "unknown payload", changed);
  }
  changed = first;
  changed[2] *= -1;
  check("bad mark polarity", changed);

  // A valid frame followed by a fragment before the one-second redraw must
  // retain the real name while reporting that the latest input was short.
  check("match before fragment", first, room, button);
  const auto matches_before_fragment = matched_frame_count;
  check("fragment cannot erase match", {200, -4000}, room, button, true);
  if (std::strcmp(decode_status, "SHORT") || best_decoded_bits != 0 ||
      matched_frame_count != matches_before_fragment || last_match_ms != 12345)
    throw std::runtime_error("short-input status or retained match timestamp incorrect");
  changed = first;
  changed[0] = -first[1];
  changed[1] = -first[0];
  check("unknown full code", changed);
  if (std::strcmp(decode_status, "CODE") || best_decoded_bits != 29 || last_decoded_word == 0)
    throw std::runtime_error("unknown-code diagnostics missing");
  std::vector<const Fixture *> distinct;
  for (const auto &frame : existing_frames) {
    if ((std::string(frame.room) == "STUDY" && std::string(frame.command) == "fan_off") ||
        (std::string(frame.room) == "BEDROOM" && std::string(frame.command) == "fan_off") ||
        (std::string(frame.room) == "STUDY" && std::string(frame.command) == "speed_1")) {
      bool seen = false;
      for (const auto *known : distinct)
        seen |= std::string(known->room) == frame.room && std::string(known->command) == frame.command;
      if (!seen) distinct.push_back(&frame);
    }
  }
  const Fixture *study = nullptr, *bedroom = nullptr, *speed = nullptr;
  for (const auto *f : distinct) {
    if (std::string(f->room) == "BEDROOM") bedroom = f;
    else if (std::string(f->command) == "fan_off") study = f;
    else speed = f;
  }
  require(study && bedroom && speed, "Required existing fixtures missing");
  const auto a = pulses_for(*study), b = pulses_for(*bedroom), c = pulses_for(*speed);
  reset_events();
  auto two = a; two.insert(two.end(), b.begin(), b.end()); decode(two);
  require(event_count == 2 && event_words[0] != event_words[1], "Two frames in one callback lost");
  decode(a); decode(b);
  require(event_count == 2, "Interleaved repeated frames became extra events");
  decode(c); decode(a);
  require(event_count == 4, "Different-button transition in one room was suppressed");
  mock_now += 300; decode(a);
  require(event_count == 5, "Later identical unmarked event suppressed");
  // Model simultaneous OOK marks as a wired OR of two aligned waveforms.
  // This is synthetic corruption, not a claim about actual RF capture effect.
  std::vector<int64_t> edges{0};
  for (const auto *signal : {&a, &b}) {
    int64_t t = 0;
    for (auto pulse : *signal) { t += std::abs(pulse); edges.push_back(t); }
  }
  std::sort(edges.begin(), edges.end());
  edges.erase(std::unique(edges.begin(), edges.end()), edges.end());
  const auto high_at = [](const std::vector<int32_t> &signal, int64_t when) {
    int64_t t = 0;
    for (auto pulse : signal) { t += std::abs(pulse); if (when < t) return pulse > 0; }
    return false;
  };
  std::vector<int32_t> collided;
  for (size_t i = 1; i < edges.size(); ++i) {
    const bool high = high_at(a, edges[i-1]) || high_at(b, edges[i-1]);
    const auto duration = static_cast<int32_t>(edges[i] - edges[i-1]) * (high ? 1 : -1);
    if (!collided.empty() && (collided.back() > 0) == high) collided.back() += duration;
    else collided.push_back(duration);
  }
  reset_events(); decode(collided);
  require(event_count == 0, "Synthetic corrupted overlap invented a known event");
  for (int polarity : {1, -1}) for (double scale : {0.9, 1.0, 1.1}) {
    reset_events();
    const auto tail = marker_input(0x5A, polarity, scale);
    decode(tail);
    require(event_count == 0 && !marker_open, "Orphan footer invented an event");
    decode(a); decode(a); decode(tail);
    require(event_count == 1 && event_sources[0] == 2 && !marker_open,
            "Footer did not mark preceding repeated command");
    require(marker_footer_count == 2 && marker_sync_count == 2 && marker_best_bits == 8,
            "Footer diagnostics lost boundaries");
    decode(a); decode(tail);
    require(event_count == 2 && event_sources[1] == 2, "Identical footered send suppressed");
    decode(a); decode(b); decode(a); decode(b); decode(tail);
    require(event_count == 4 && event_sources[2] == 3 && event_sources[3] == 3,
            "Mixed footer group misattributed or lost commands");
    decode(a); mock_now += 300; decode(tail);
    require(event_sources[4] == 0 && !marker_open, "Late footer marked stale command");
    decode(c); decode(tail);
    require(event_count == 6 && event_sources[5] == 2, "Fresh group failed after stale footer");
  }
  const auto footer = marker_input(0x5A);
  for (size_t length = 2; length < footer.size(); ++length) {
    reset_events(); decode(a);
    decode(std::vector<int32_t>(footer.begin(), footer.begin() + length));
    require(marker_footer_count == 0 && event_sources[0] != 2,
            "Truncated footer assigned source");
  }
  for (size_t missing = 0; missing < footer.size(); ++missing) {
    reset_events(); decode(a);
    auto damaged = footer; damaged.erase(damaged.begin() + missing); decode(damaged);
    require(marker_footer_count == 0 && event_sources[0] != 2,
            "Footer accepted missing pulse or guard");
  }
  reset_events(); decode(a); decode(marker_input(0xA5));
  require(event_sources[0] != 2 && marker_footer_count == 0, "Retired header marked a command");
  auto corrupt = footer; corrupt[4] = 700; decode(corrupt);
  require(event_sources[0] != 2, "Corrupt footer marked command");
  mock_now += 301; decode({100, -4000});
  require(event_sources[0] == 0 && !marker_open, "No-footer group remained attributable");
  // Two footered transmissions in one callback must stay separate before OLED redraw.
  reset_events();
  auto combined = a; combined.insert(combined.end(), footer.begin(), footer.end());
  combined.insert(combined.end(), a.begin(), a.end());
  combined.insert(combined.end(), footer.begin(), footer.end());
  decode(combined);
  require(event_count == 2 && event_sources[0] == 2 && event_sources[1] == 2,
          "Consecutive footered commands in one callback merged");
  for (unsigned i = 0; i < 20; ++i) { mock_now += 301; decode(i % 2 ? a : b); }
  require(event_count == 22 && event_ids[(event_count - 1) % 8] == 22,
          "Bounded event history lost sequence or indexing");

  for (const auto &packet : existing_packets) for (int polarity : {1, -1}) for (double scale : {0.9, 1.0, 1.1}) {
    reset_events();
    const auto marked = broadlink_markers::add(packet.ticks);
    std::vector<int32_t> batch;
    double time_us = mock_now * 1000.0;
    for (size_t i = 0; i < marked.size(); ++i) {
      const auto duration = static_cast<int32_t>(std::lround(marked[i] * 8192.0 / 269 * scale));
      const bool idle = duration >= 4000;
      batch.push_back((i % 2 ? -polarity : polarity) * (idle ? 4000 : duration));
      mock_now = static_cast<uint64_t>((time_us + (idle ? 4000 : duration)) / 1000);
      if (idle) {
        require(batch.size() <= 384, "Marked RMT batch exceeds capacity");
        decode(batch); batch.clear();
      }
      time_us += duration;
    }
    if (!batch.empty()) decode(batch);
    require(event_count == 1 && event_sources[0] == 2 && !marker_open,
            "Original marked packet did not become one complete event");
    require(marker_footer_count == 1 && marker_best_bits == 8,
            "Packet marker diagnostics disagree with complete envelope");
    require(std::strcmp(event_buttons[0], labels.at(packet.command)) == 0,
            "Marked packet changed command identity");
    require(published.size() == 1 && published[0].second == std::string(packet.command) + "_broadlink",
            "Real packet did not publish its command/source atomically once");
    require(published[0].first == (std::string(packet.room) == "STUDY" ? 0x21u : 0xCBu),
            "Real packet published to the wrong room");
  }
  reset_events(); publication_tick();
  require(published.empty(), "Boot emitted an invented command");
  decode(a); decode(a);
  require(published.empty(), "Pending command published before footer decision");
  mock_now += 299; publication_tick();
  require(published.empty(), "Unmarked command published too early");
  mock_now += 1; publication_tick();
  require(published.size() == 1 && published[0].second == "fan_off_unmarked",
          "Idle tick did not finalize and publish a single unmarked event");
  publication_tick(); decode({100, -4000});
  require(published.size() == 1, "Published event was replayed");
  decode(a); decode(footer); decode(a); decode(footer);
  require(published.size() == 3 && published[1].second == "fan_off_broadlink" &&
          published[2].second == "fan_off_broadlink", "Identical marked occurrences lost in publication");
  reset_events(); decode(a); decode(b); decode(footer);
  require(published.size() == 2 && published[0].first == 0x21 && published[1].first == 0xCB &&
          published[0].second == "fan_off_mixed" && published[1].second == "fan_off_mixed",
          "Mixed group publication lost order, room or source");
  reset_events(); native_api.connected = false; decode(a);
  native_api.connected = true; mock_now += 300; publication_tick();
  require(published.empty(), "Offline observation replayed on reconnect");
  reset_events(); decode(a); native_api.connected = false; publication_tick();
  native_api.connected = true; decode(footer);
  require(published.empty(), "Pending observation survived a disconnect");
  decode(c); decode(footer);
  require(published.size() == 1 && published[0].second == "speed_1_broadlink",
          "Fresh event after reconnect was lost");
  reset_events();
  for (int i = 0; i < 10; ++i) decode(i % 2 ? c : a);
  decode(footer);
  require(rf_publication.overflow_count == 2 && published.size() == 8,
          "Bounded publication overflow was hidden or corrupted");
  require(published.front().second == "fan_off_mixed" && published.back().second == "speed_1_mixed",
          "Overflow changed retained publication order");
  std::cout << "PASS: " << checks << " decoder/event checks; existing commands, markers, interleaving, "
               "identical sends, malformed boundaries, both polarities and exact RMT batches\n";
}
