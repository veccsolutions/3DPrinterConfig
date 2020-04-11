FROM debian:10.2 AS build

ARG MARLIN_BRANCH=2.0.x

RUN apt update && \
    apt install -y git

WORKDIR /arduino-cli
COPY temp/arduino-cli.tar.gz  arduino-cli.tar.gz
RUN tar -xvf arduino-cli.tar.gz
RUN ls -la

RUN ./arduino-cli \
    core \
    --additional-urls https://raw.githubusercontent.com/ultimachine/ArduinoAddons/master/package_ultimachine_index.json \
    update-index

RUN ./arduino-cli \
    core \
    --additional-urls https://raw.githubusercontent.com/ultimachine/ArduinoAddons/master/package_ultimachine_index.json \
    install ultimachine:sam

RUN ./arduino-cli \
    lib \
    install TMCStepper

# cache busting with run.ps1 only when the latest release changes
COPY temp/marlinlatest /marlinlatest
RUN git clone https://github.com/MarlinFirmware/Marlin.git /marlin
WORKDIR /marlin
RUN git checkout $MARLIN_BRANCH

RUN mkdir /build && \
    cp /marlin/Marlin/Configuration.h /build/Configuration.original.h && \
    cp /marlin/Marlin/Configuration_adv.h /build/Configuration_adv.original.h

COPY Configuration.h Marlin/Configuration.h
COPY Configuration_adv.h Marlin/Configuration_adv.h

COPY Configuration.h /build/Configuration.h
COPY Configuration_adv.h /build/Configuration_adv.h

RUN /arduino-cli/arduino-cli \
    compile \
    --fqbn ultimachine:sam:archim \
    --build-path /build/temp \
    --build-cache-path /build/cache \
    -v \
    /marlin/Marlin/Marlin.ino

FROM scratch
COPY --from=build /build/temp/Marlin.ino.bin /marlin/marlin.bin
COPY --from=build /build/Configuration.h /marlin/Configuration.h
COPY --from=build /build/Configuration_adv.h /marlin/Configuration_adv.h
COPY --from=build /build/Configuration.original.h /marlin/Configuration.original.h
COPY --from=build /build/Configuration_adv.original.h /marlin/Configuration_adv.original.h
