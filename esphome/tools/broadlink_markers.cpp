// Each input/output line is one hexadecimal packet. JSON/base64 stays in PowerShell.
#include "broadlink_markers.h"
#include <iomanip>
#include <iostream>
#include <string>

int main(int argc, char **argv) {
  try {
    if (argc != 2 || (std::string(argv[1]) != "add" && std::string(argv[1]) != "remove"))
      throw std::runtime_error("Usage: broadlink_markers add|remove < packets.hex");
    for (std::string line; std::getline(std::cin, line);) {
      if (!line.empty() && line.back() == '\r') line.pop_back();
      if (line.empty() || line.size() % 2 != 0 || line.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos)
        throw std::runtime_error("Expected an even-length hexadecimal packet");
      std::vector<uint8_t> bytes;
      for (size_t i = 0; i < line.size(); i += 2)
        bytes.push_back(static_cast<uint8_t>(std::stoul(line.substr(i, 2), nullptr, 16)));
      const auto out = broadlink_markers::transform(bytes, std::string(argv[1]) == "remove");
      for (auto byte : out) std::cout << std::hex << std::setw(2) << std::setfill('0') << unsigned(byte);
      std::cout << '\n';
    }
  } catch (const std::exception &error) {
    std::cerr << error.what() << '\n';
    return 1;
  }
}
