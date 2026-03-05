# PLACEHOLDER-BEGIN #
MESSAGE("-- ai lib.cmake")

INSTALL(DIRECTORY "${LIBRARY_OUTPUT_PATH}/profiles/ai"          DESTINATION lib/profiles)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/ai-profiles.sh"           DESTINATION lib)
INSTALL(FILES "${LIBRARY_OUTPUT_PATH}/ai-profile-render.groovy" DESTINATION lib)

# PLACEHOLDER-END #
