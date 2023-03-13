.ifndef VERSION_MAJOR
.define VERSION_MAJOR 0
.endif

.ifndef VERSION_MINOR
.define VERSION_MINOR 1
.endif

.ifndef VERSION_STEP
.define VERSION_STEP  0
.endif

.define VERSION_STRING .sprintf ("%d.%d.%d", VERSION_MAJOR, VERSION_MINOR, VERSION_STEP)
