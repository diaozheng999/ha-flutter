# Run from this directory in an x64 Visual Studio developer command prompt:
#   nmake /f Makefile test
# Fixtures are existing Broadlink records; this test does not access any device.
CXX=cl
OUT=..\.esphome\decoder-test

test: $(OUT)\mistral_decoder_test.exe $(OUT)\broadlink_markers_test.exe $(OUT)\broadlink_markers.exe
	$(OUT)\mistral_decoder_test.exe
	$(OUT)\broadlink_markers_test.exe

$(OUT)\decoder.inc: ..\lilygo-lora32-t3-v161.yaml Makefile
	powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path '$(OUT)' | Out-Null; $$source = Get-Content -LiteralPath '..\lilygo-lora32-t3-v161.yaml' -Raw; $$body = [regex]::Match($$source, '(?s)  on_raw:.*?      - lambda: \|-\r?\n(.*?)\r?\nfont:').Groups[1].Value; if ([string]::IsNullOrWhiteSpace($$body)) { throw 'Firmware decoder lambda not found' }; Set-Content -LiteralPath '$(OUT)\decoder.inc' -Value $$body -Encoding utf8"

$(OUT)\publication_tick.inc: ..\lilygo-lora32-t3-v161.yaml Makefile
	powershell -NoProfile -Command "$$source = Get-Content -LiteralPath '..\lilygo-lora32-t3-v161.yaml' -Raw; $$body = [regex]::Match($$source, '(?s)// RF_PUBLICATION_TICK_BEGIN\r?\n(.*?)\s*// RF_PUBLICATION_TICK_END').Groups[1].Value; if ([string]::IsNullOrWhiteSpace($$body)) { throw 'Publication tick not found' }; Set-Content -LiteralPath '$(OUT)\publication_tick.inc' -Value $$body -Encoding utf8"

$(OUT)\mistral_decoder_test.exe: mistral_decoder_test.cpp mistral_existing_frames.h mistral_existing_packets.h ..\tools\broadlink_markers.h ..\rf_event_publication.h $(OUT)\decoder.inc $(OUT)\publication_tick.inc
	$(CXX) /nologo /EHsc /std:c++17 /W4 /Fe:$(OUT)\mistral_decoder_test.exe /Fo:$(OUT)\mistral_decoder_test.obj mistral_decoder_test.cpp

$(OUT)\broadlink_markers_test.exe: broadlink_markers_test.cpp ..\tools\broadlink_markers.h mistral_existing_packets.h $(OUT)\decoder.inc
	$(CXX) /nologo /EHsc /std:c++17 /W4 /Fe:$(OUT)\broadlink_markers_test.exe /Fo:$(OUT)\broadlink_markers_test.obj broadlink_markers_test.cpp

$(OUT)\broadlink_markers.exe: ..\tools\broadlink_markers.cpp ..\tools\broadlink_markers.h $(OUT)\decoder.inc
	$(CXX) /nologo /EHsc /std:c++17 /W4 /Fe:$(OUT)\broadlink_markers.exe /Fo:$(OUT)\broadlink_markers.obj ..\tools\broadlink_markers.cpp
